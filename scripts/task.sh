#!/usr/bin/env bash
# task.sh — minimal helpers for the team task board (tasks/BOARD.md)
#
#   scripts/task.sh add "Title here" [assignee]   append a task to Backlog (auto-IDs T-NNN)
#   scripts/task.sh list                           show the board
#   scripts/task.sh next-id                        print the next task id
#
# Status changes (moving a task between columns) are done by editing tasks/BOARD.md
# directly — the dispatcher and specialists do this as work progresses.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOARD="$ROOT/tasks/BOARD.md"
[ -f "$BOARD" ] || { echo "no board at $BOARD"; exit 1; }

next_id() {
  local max
  max="$(grep -oE 'T-[0-9]+' "$BOARD" 2>/dev/null | sed 's/T-//' | sort -n | tail -1)"
  printf 'T-%03d' $(( ${max:-0} + 1 ))
}

case "${1:-list}" in
  next-id) next_id ;;
  list)    cat "$BOARD" ;;
  add)
    TITLE="${2:?usage: task.sh add \"title\" [assignee]}"
    ASSIGNEE="${3:-Backlog}"
    ID="$(next_id)"
    # insert a row under the "## Backlog" table (after its separator), drop the placeholder
    TMP="$(mktemp)"
    awk -v id="$ID" -v t="$TITLE" -v a="$ASSIGNEE" '
      /^## [A-Z]/ { inb = ($0 ~ /^## Backlog/) }
      inb && !ins && /^\|---/ { print; print "| " id " | " t " | " a " |  |"; ins=1; next }
      inb && /_none yet_/ { next }
      { print }
    ' "$BOARD" > "$TMP" && mv "$TMP" "$BOARD"
    echo "added $ID — $TITLE (assignee: $ASSIGNEE)"
    ;;
  *) echo "usage: task.sh {add|list|next-id}"; exit 2 ;;
esac
