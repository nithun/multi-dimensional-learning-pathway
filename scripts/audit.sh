#!/usr/bin/env bash
# audit.sh — view the per-agent audit log (.claude/memory/audit.jsonl)
#
#   scripts/audit.sh                 last 20 entries across all teammates
#   scripts/audit.sh <agent>         this teammate's history
#   scripts/audit.sh --agents        roll-up: completed count per teammate
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$ROOT/.claude/memory/audit.jsonl"
[ -f "$LOG" ] || { echo "no audit log yet ($LOG)"; exit 0; }

case "${1:-}" in
  "")        tail -n 20 "$LOG" ;;
  --agents)  grep -o '"agent":"[^"]*"' "$LOG" | sed 's/"agent":"//;s/"//' | sort | uniq -c | sort -rn ;;
  *)         grep "\"agent\":\"$1\"" "$LOG" || echo "no entries for teammate '$1'" ;;
esac
