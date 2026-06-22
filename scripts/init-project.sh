#!/usr/bin/env bash
# init-project.sh — start a FRESH project from a pulled Turing Agents release.
#
# Run this once, right after you pull a release tag into a new project folder.
# It resets the learned/project-specific state to clean stubs (keeping the framework
# itself — agents, skills scaffold, scripts, the seed lessons) so the framework starts
# learning YOUR project from zero.
#
#   scripts/init-project.sh            interactive (asks before resetting)
#   scripts/init-project.sh --yes      no prompt
#   scripts/init-project.sh --yes --fresh-git   also re-init git history
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEM="$ROOT/.claude/memory"
YES=0; FRESH_GIT=0
for a in "$@"; do case "$a" in --yes) YES=1;; --fresh-git) FRESH_GIT=1;; esac; done

echo "Turing Agents — initialize a fresh project at:"
echo "  $ROOT"
echo "This RESETS project memory (profile, interactions, evolution log, audit, board,"
echo "backlog, glossary) to empty stubs. The framework (agents, skills, scripts, seed"
echo "lessons) is kept. Your project source code is NOT touched."
if [ "$YES" != "1" ]; then
  printf "Proceed? [y/N] "; read -r ans; case "$ans" in y|Y) ;; *) echo "aborted."; exit 0;; esac
fi

# --- reset memory stubs -----------------------------------------------------
cat > "$MEM/project-profile.md" <<'EOF'
# Project profile

_Status: **UNPROFILED**. Spawn the `scout` agent ("profile this project") to fill this in from the repository. Until then, the framework is running blind._

## What this project is
- unknown — needs a real task or `scout` run to reveal it.

## Tech stack
- unknown.

## Layout
- (to be discovered)

## Conventions in use
- unknown — will firm up after the first real task.

## Goals / what success looks like
- unknown — needs the user or a real task to reveal it.

## Open questions for the user
- What is this project, in one sentence?
- What language/stack?
- Greenfield, or importing an existing repo?
EOF

cat > "$MEM/glossary.md" <<'EOF'
# Glossary

Project vocabulary, acronyms, codenames — each with a one-line decode. Maintained by `scout` (seed) and `retrospective` (additions). Empty until real terms appear.

| Term | Means | Source |
|---|---|---|

<!-- rows get appended as the project's real vocabulary surfaces. -->
EOF

: > "$MEM/interactions.jsonl"
: > "$MEM/evolution-log.jsonl"
: > "$MEM/audit.jsonl"

cat > "$MEM/circuit-breaker.json" <<'EOF'
{
  "_doc": "Safety state machine for self-edits. A non-open lane makes edits in that lane proposals, not direct writes. Only the user reopens a closed lane.",
  "mode": "aggressive",
  "thresholds": { "revert_or_ineffective_pause_after_n": 2, "rolling_window_edits": 5 },
  "skills": { "status": "open", "recent_outcomes": [] },
  "agents": { "status": "open", "recent_outcomes": [] },
  "memory": { "status": "open", "recent_outcomes": [] },
  "last_run": null,
  "last_updated": "unset"
}
EOF

cat > "$ROOT/EVOLUTION-LOG.md" <<'EOF'
# Evolution log — what the framework learned while you built

Plain-language digest of every self-improvement the curator makes, newest first. Your window into the framework — glance at it when curious. Empty until the framework learns something.

---
EOF

cat > "$ROOT/docs/evolution/backlog.md" <<'EOF'
# Evolution backlog

The framework's own task queue. Lifecycle: `queued → in-progress → done | dropped`. Append-and-amend; never delete a row.

| ID | Item | Type | Status | Evidence | Opened | Close condition |
|---|---|---|---|---|---|---|
| B-001 | Profile the project (run `scout`) | profile | queued | project UNPROFILED | unset | project-profile.md no longer says UNPROFILED |
EOF

# clean board
cat > "$ROOT/tasks/BOARD.md" <<'EOF'
# Task board

The team's shared work queue. Lifecycle: `Backlog → Assigned → In Progress → Blocked → Review → Done` (or `Dropped`). Assignee = an agent (teammate) or `@you`.

> Add: `scripts/task.sh add "title" [assignee]` · move: edit the row's Status.

## Backlog
| ID | Title | Assignee | Notes |
|---|---|---|---|
| _none yet_ | | | |

## Assigned
| ID | Title | Assignee | Opened |
|---|---|---|---|

## In Progress
| ID | Title | Assignee | Since |
|---|---|---|---|

## Blocked
| ID | Title | Assignee | Blocker |
|---|---|---|---|

## Review
| ID | Title | Assignee | Needs |
|---|---|---|---|

## Done
| ID | Title | Assignee | Closed | Skill harvested? |
|---|---|---|---|---|
EOF

# remove project-run evolution artifacts (keep design docs + READMEs)
rm -f "$ROOT/docs/evolution/"RR-*.md "$ROOT/docs/evolution/"proposal-*.md "$ROOT/docs/evolution/"scout-proposals-*.md 2>/dev/null || true
rm -rf "$ROOT/.claude/daemon/runs" "$ROOT/.claude/daemon/autopilots" 2>/dev/null || true
rm -f "$ROOT/.claude/daemon/watermark" "$ROOT/.claude/daemon/"*.log "$ROOT/.claude/daemon/DISABLED" 2>/dev/null || true

echo "  ✓ memory + board + backlog reset to clean stubs"

# --- daemon state + plist for the new path ----------------------------------
bash "$ROOT/scripts/install.sh" >/dev/null 2>&1 || true
echo "  ✓ daemon state initialized for this path"

# --- optional fresh git -----------------------------------------------------
if [ "$FRESH_GIT" = "1" ]; then
  rm -rf "$ROOT/.git"
  git -C "$ROOT" init -q
  echo "  ✓ fresh git history"
fi

echo ""
echo "Done. Next:"
echo "  1. Start building your project in a Claude Code / Cowork session here."
echo "  2. The framework auto-profiles on first real work and learns as you go."
echo "  3. (Optional) always-on background evolution:  scripts/install.sh --daemon"
