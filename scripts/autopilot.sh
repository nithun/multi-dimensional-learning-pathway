#!/usr/bin/env bash
# autopilot.sh — run recurring routines defined in autopilots/*.md
#
#   scripts/autopilot.sh --list      list autopilots + whether each is due
#   scripts/autopilot.sh --due       run every enabled autopilot whose cadence elapsed
#   scripts/autopilot.sh <name>      run one autopilot now
#
# Like the curator daemon, autopilot runs are headless (claude -p) and therefore opt-in:
# they honor .claude/daemon/DISABLED and need the daemon enabled, or you invoke them by hand.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AP_DIR="$ROOT/autopilots"
STATE_DIR="$ROOT/.claude/daemon/autopilots"
DISABLED="$ROOT/.claude/daemon/DISABLED"
SENTINEL="[[turing-autopilot-run]]"
mkdir -p "$STATE_DIR"

now() { date +%s; }
field() { sed -n "s/^$2:[[:space:]]*//p" "$1" | head -1; }
cadence_secs() {
  local c="$1" n unit
  n="$(printf '%s' "$c" | sed 's/[^0-9]//g')"; unit="$(printf '%s' "$c" | sed 's/[0-9]//g')"
  case "$unit" in m) echo $((n*60));; h) echo $((n*3600));; d) echo $((n*86400));; *) echo 0;; esac
}
is_due() { # autopilot-file -> 0 if due
  local f="$1" name secs last
  name="$(basename "$f" .md)"; secs="$(cadence_secs "$(field "$f" cadence)")"
  last="$STATE_DIR/$name.last"
  [ ! -f "$last" ] && return 0
  [ $(( $(now) - $(date -r "$last" +%s 2>/dev/null || echo 0) )) -ge "$secs" ] && return 0 || return 1
}

list() {
  printf '%-24s %-8s %-8s %s\n' NAME ENABLED CADENCE DUE
  for f in "$AP_DIR"/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    local name en cad due; name="$(basename "$f" .md)"
    en="$(field "$f" enabled)"; cad="$(field "$f" cadence)"
    if [ "$en" = "true" ] && is_due "$f"; then due="yes"; else due="no"; fi
    printf '%-24s %-8s %-8s %s\n' "$name" "${en:-?}" "${cad:-?}" "$due"
  done
}

run_one() { # autopilot-file
  local f="$1" name; name="$(basename "$f" .md)"
  [ -f "$DISABLED" ] && { echo "DISABLED — skipping $name"; return 0; }
  [ -n "${COWORK_DAEMON:-}" ] && { echo "recursion guard — skipping $name"; return 0; }
  local CLAUDE_BIN; CLAUDE_BIN="$(command -v claude || echo "$HOME/.local/bin/claude")"
  [ -x "$CLAUDE_BIN" ] || { echo "claude not found — cannot run $name"; return 0; }
  local body; body="$(awk 'f{print} /^---[[:space:]]*$/{f=1}' "$f")"
  # scoped permission sandbox (B-014); fall back to skip-permissions if missing
  local DSET="$ROOT/.claude/daemon/daemon-settings.json"; local PERM
  if [ -f "$DSET" ]; then PERM=(--settings "$DSET" --permission-mode acceptEdits); else PERM=(--dangerously-skip-permissions); fi
  echo "running autopilot: $name"
  ( cd "$ROOT" && COWORK_DAEMON=1 timeout 900 "$CLAUDE_BIN" -p "$body
$SENTINEL" --model sonnet "${PERM[@]}" \
    >>"$STATE_DIR/$name.log" 2>&1 )
  touch "$STATE_DIR/$name.last"
  echo "done: $name"
}

case "${1:---list}" in
  --list) list ;;
  --due)
    for f in "$AP_DIR"/*.md; do
      [ "$(basename "$f")" = "README.md" ] && continue
      [ "$(field "$f" enabled)" = "true" ] && is_due "$f" && run_one "$f"
    done ;;
  *)
    f="$AP_DIR/$1.md"; [ -f "$f" ] || { echo "no autopilot '$1' (see scripts/autopilot.sh --list)"; exit 1; }
    run_one "$f" ;;
esac
