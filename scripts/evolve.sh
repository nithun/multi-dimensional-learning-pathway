#!/usr/bin/env bash
# evolve.sh — the Cowork curator daemon runner.
#
# Runs a headless Claude as the `curator` agent: it watches this project's session
# transcripts (all Cowork + Code sessions), digests new activity, and evolves the
# framework (profile / lessons / skills / agents) — committing each change. It edits
# ONLY the framework's own files, never your project source code.
#
# Invoked by: launchd (every ~20 min), the SessionEnd hook (flush after each session),
# and by hand (`scripts/evolve.sh`). Safe to over-invoke: it locks, watermarks, and
# no-ops when there's no new session activity.
#
# Controls:
#   touch  .claude/daemon/DISABLED   → pause the daemon (it exits immediately)
#   rm     .claude/daemon/DISABLED   → resume
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DAEMON_DIR="$ROOT/.claude/daemon"
LOCK="$DAEMON_DIR/.lock"
WM="$DAEMON_DIR/watermark"
RUNLOG_DIR="$DAEMON_DIR/runs"
DISABLED="$DAEMON_DIR/DISABLED"
SENTINEL="[[cowork-curator-run]]"

mkdir -p "$DAEMON_DIR" "$RUNLOG_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# --- guards -----------------------------------------------------------------
[ -f "$DISABLED" ] && { log "DISABLED present — exiting."; exit 0; }
[ -n "${COWORK_DAEMON:-}" ] && { log "recursion guard (COWORK_DAEMON set) — exiting."; exit 0; }

CLAUDE_BIN="$(command -v claude || true)"
[ -z "$CLAUDE_BIN" ] && [ -x "$HOME/.local/bin/claude" ] && CLAUDE_BIN="$HOME/.local/bin/claude"
[ -z "$CLAUDE_BIN" ] && { log "claude CLI not found — cannot run curator. Capture-only."; exit 0; }

# --- lock (atomic mkdir; clear if stale > 2h) -------------------------------
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -d "$LOCK" ] && [ -n "$(find "$LOCK" -prune -mmin +120 2>/dev/null)" ]; then
    log "stale lock — clearing."; rmdir "$LOCK" 2>/dev/null || rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || { log "could not acquire lock — exiting."; exit 0; }
  else
    log "another run holds the lock — exiting."; exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null || rm -rf "$LOCK"' EXIT

# --- locate the transcript store for this project ---------------------------
ENC="$(printf '%s' "$ROOT" | sed 's#[/ ]#-#g')"
TDIR="$HOME/.claude/projects/$ENC"
if [ ! -d "$TDIR" ]; then
  log "transcript dir not found ($TDIR) — nothing to watch yet."; exit 0
fi

# --- refresh the triage flags (the deterministic "what's due" analyzer) ------
bash "$ROOT/scripts/triage.sh" >/dev/null 2>&1 || true
RETRO_DUE=0; REPROFILE_DUE=0
grep -q '"retrospective_due": true' "$ROOT/.claude/memory/triage.json" 2>/dev/null && RETRO_DUE=1
grep -q '"reprofile_due": true'    "$ROOT/.claude/memory/triage.json" 2>/dev/null && REPROFILE_DUE=1

# --- throttle: run if there's NEW session activity OR something is DUE -------
if [ -f "$WM" ]; then
  NEW="$(find "$TDIR" -name '*.jsonl' -newer "$WM" 2>/dev/null | head -1)"
  if [ -z "$NEW" ] && [ "$RETRO_DUE" = 0 ] && [ "$REPROFILE_DUE" = 0 ]; then
    log "no new activity and nothing due — no-op."; exit 0
  fi
  SINCE="$(date -r "$WM" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'last run')"
else
  SINCE="(start of watching)"
fi

# --- run the curator headless -----------------------------------------------
TS="$(date '+%Y%m%d-%H%M%S')"
RUNLOG="$RUNLOG_DIR/$TS.log"
HEAD_BEFORE="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"

PROMPT="You are the Cowork CURATOR running as an autonomous background process.
First read .claude/agents/curator.md and CLAUDE.md, then act exactly per those rules.

- Session transcripts for this project are in: $TDIR
- Process only sessions with activity SINCE: $SINCE
- IGNORE any transcript containing the text '$SENTINEL' — those are your own past runs, not user work.
- Run the cycle: ingest new interactions into .claude/memory/interactions.jsonl → if project-profile.md says UNPROFILED spawn scout → spawn retrospective to evolve (it may build skills/agents via the smiths) — all evidence-gated and honoring the circuit-breaker and every INVARIANTS fence.
- TRIAGE says: retrospective_due=$RETRO_DUE, reprofile_due=$REPROFILE_DUE. If retrospective_due=1, spawn the retrospective agent for a FULL run (classify pending outcomes, extract lessons), then run: bash scripts/triage.sh --mark-retro. If reprofile_due=1, spawn scout for a DEEP re-profile, then run: bash scripts/triage.sh --mark-profile.
- NEVER touch the project's source code. Stage only framework files by path; atomic 'evolve: …' commits.
- Finish by prepending a short, plain-language entry to EVOLUTION-LOG.md describing what you digested, learned, and built (or 'no changes'). Commit framework files only.
- If .claude/daemon/DISABLED exists, exit immediately.
$SENTINEL"

# Scoped permission sandbox (B-014) instead of bypassing all checks: the daemon may
# edit framework files + use git, but is hard-denied source edits, network, push, and
# destructive shell. Falls back to skip-permissions only if the settings file is missing.
DSET="$DAEMON_DIR/daemon-settings.json"
if [ -f "$DSET" ]; then
  PERM_ARGS=(--settings "$DSET" --permission-mode acceptEdits)
else
  log "WARN: daemon-settings.json missing — falling back to skip-permissions."
  PERM_ARGS=(--dangerously-skip-permissions)
fi

# Optional timeout wrapper — `timeout` is absent on stock macOS; use it (or gtimeout)
# only if present, else run unbounded (the 2h stale-lock is the backstop).
TO_ARGS=(); TO_BIN="$(command -v timeout || command -v gtimeout || true)"
[ -n "$TO_BIN" ] && TO_ARGS=("$TO_BIN" 900)

log "running curator (since: $SINCE; retro_due=$RETRO_DUE reprofile_due=$REPROFILE_DUE) → $RUNLOG"
( cd "$ROOT" && COWORK_DAEMON=1 ${TO_ARGS[@]+"${TO_ARGS[@]}"} "$CLAUDE_BIN" -p "$PROMPT" \
    --model sonnet "${PERM_ARGS[@]}" \
    >>"$RUNLOG" 2>&1 )
RC=$?
[ $RC -ne 0 ] && log "curator run exited rc=$RC (see $RUNLOG)"

# --- advance watermark (so the daemon's own transcript isn't re-ingested) ----
touch "$WM"

# --- SAFETY BACKSTOP (B-014): the daemon must touch ONLY framework files -----
# Deterministic check independent of the permission layer. If the run committed any
# path under app/ platform/ tests/ ci/, PAUSE the daemon and alert — never auto-reset
# (that could destroy the user's uncommitted work); the user reviews + git-reverts.
HEAD_AFTER="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"
if [ "$HEAD_BEFORE" != "$HEAD_AFTER" ]; then
  BAD="$(git -C "$ROOT" diff --name-only "$HEAD_BEFORE" "$HEAD_AFTER" 2>/dev/null | grep -E '^(app/|platform/|tests/|ci/)' || true)"
  if [ -n "$BAD" ]; then
    log "SAFETY VIOLATION: daemon committed disallowed (source) paths — pausing daemon:"
    log "$BAD"
    touch "$DISABLED"
    command -v osascript >/dev/null 2>&1 && osascript -e "display notification \"daemon touched source files — paused. Review git log.\" with title \"Turing Agents SAFETY\"" 2>/dev/null || true
  fi
  N="$(git -C "$ROOT" rev-list --count "$HEAD_BEFORE..$HEAD_AFTER" 2>/dev/null || echo '?')"
  log "framework evolved: $N new commit(s)."
  if [ -z "$BAD" ] && command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$N change(s) — see EVOLUTION-LOG.md\" with title \"Turing curator learned something\"" 2>/dev/null || true
  fi
else
  log "no changes this run."
fi

# --- prune old run logs (keep last 50) --------------------------------------
ls -1t "$RUNLOG_DIR"/*.log 2>/dev/null | tail -n +51 | xargs -I{} rm -f {} 2>/dev/null || true
log "done."
