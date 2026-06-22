#!/usr/bin/env bash
# capture.sh — append one interaction to .claude/memory/interactions.jsonl
#
# This is the "reflect-after" step of the Cowork loop. Run it after a meaningful
# task so the framework has raw material to learn from. Skip for trivial one-liners
# and pure questions.
#
# Usage:
#   scripts/capture.sh "<intent>" "<what was done>" "<friction/lesson or '->"
#
# Schema (one JSON object per line):
#   {"id","date","intent","did","learned","actor"}
#
# Example:
#   scripts/capture.sh "add billing export" "wrote exporter + test" "GCP billing API needs a retry on 429"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$ROOT/.claude/memory/interactions.jsonl"

if [ "$#" -lt 2 ]; then
  echo "usage: capture.sh \"<intent>\" \"<did>\" [\"<learned>\"]" >&2
  exit 2
fi

INTENT="$1"
DID="$2"
LEARNED="${3:--}"
ACTOR="${4:-main}"

mkdir -p "$(dirname "$LOG")"
touch "$LOG"

# next id: IX-NNN, zero-padded to 3
COUNT="$(grep -c '' "$LOG" 2>/dev/null || echo 0)"
NEXT=$((COUNT + 1))
ID="$(printf 'IX-%03d' "$NEXT")"
DATE="$(date +%Y-%m-%d)"

# minimal JSON string escaping: backslash and double-quote
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

printf '{"id":"%s","date":"%s","intent":"%s","did":"%s","learned":"%s","actor":"%s"}\n' \
  "$ID" "$DATE" "$(esc "$INTENT")" "$(esc "$DID")" "$(esc "$LEARNED")" "$(esc "$ACTOR")" \
  >> "$LOG"

echo "captured $ID -> $LOG"
