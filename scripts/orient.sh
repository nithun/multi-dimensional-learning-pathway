#!/usr/bin/env bash
# orient.sh — print the framework's current evolution state.
#
# Wired to the SessionStart hook (.claude/settings.json) so every new session
# auto-loads where the framework stands: profiled or not, how many lessons,
# pending proposals, circuit-breaker lanes, and the last thing that happened.
# Also runnable by hand any time to get your bearings.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEM="$ROOT/.claude/memory"

echo "=== Turing Agents — orientation ==="

# Profile status
if grep -q "UNPROFILED" "$MEM/project-profile.md" 2>/dev/null; then
  echo "Project: UNPROFILED — run the 'scout' agent to profile this project."
else
  WHAT="$(awk '/^## What this project is/{f=1;next} /^## /{f=0} f && NF {print; exit}' "$MEM/project-profile.md" 2>/dev/null)"
  echo "Project: ${WHAT:-profiled (see project-profile.md)}"
fi

# Lesson count (lines starting with "- L-")
LESSONS="$(grep -c '^- L-' "$MEM/lessons.md" 2>/dev/null || echo 0)"
echo "Lessons: $LESSONS"

# Pending proposals
PROPS="$(ls "$ROOT/docs/evolution/"proposal-*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "Pending proposals: ${PROPS:-0}"

# Backlog: queued framework work
if [ -f "$ROOT/docs/evolution/backlog.md" ]; then
  QUEUED="$(grep -c '| queued |' "$ROOT/docs/evolution/backlog.md" 2>/dev/null || echo 0)"
  echo "Backlog: ${QUEUED:-0} queued (docs/evolution/backlog.md)"
fi

# Task board: open project work (rows that aren't Done/Dropped, minus the placeholder)
if [ -f "$ROOT/tasks/BOARD.md" ]; then
  OPEN="$(awk '/^## (Backlog|Assigned|In Progress|Blocked|Review)/{s=1;next} /^## (Done|Dropped|---)/{s=0} s && /^\| T-/{c++} END{print c+0}' "$ROOT/tasks/BOARD.md" 2>/dev/null)"
  echo "Task board: ${OPEN:-0} open (tasks/BOARD.md)"
fi

# Triage: is a re-profile (scout) or retrospective due? (refreshed every interaction by the Stop hook)
if [ -f "$ROOT/.claude/memory/triage.json" ]; then
  grep -q '"retrospective_due": true' "$ROOT/.claude/memory/triage.json" 2>/dev/null && echo "⚠ retrospective DUE — run it (or let the curator)"
  grep -q '"reprofile_due": true' "$ROOT/.claude/memory/triage.json" 2>/dev/null && echo "⚠ re-profile DUE — spawn scout for a deep pass"
fi

# Circuit-breaker lane statuses (no jq dependency)
if [ -f "$MEM/circuit-breaker.json" ]; then
  lane_status() { grep -A2 "\"$1\"" "$MEM/circuit-breaker.json" | grep -m1 '"status"' | sed -E 's/.*"status"[[:space:]]*:[[:space:]]*"([a-z-]+)".*/\1/'; }
  SK="$(lane_status skills)"; AG="$(lane_status agents)"; ME="$(lane_status memory)"
  echo "Circuit breaker — skills:${SK:-?} agents:${AG:-?} memory:${ME:-?}"
fi

# Curator daemon status (accurate: distinguishes always-on vs in-session vs paused)
if [ -f "$ROOT/.claude/daemon/DISABLED" ]; then
  echo "Curator: PAUSED (.claude/daemon/DISABLED present — delete it to resume)"
elif launchctl list 2>/dev/null | grep -q "com.cowork.curator"; then
  echo "Curator: always-on daemon LOADED (evolves even while you're away)"
elif grep -q '"SessionEnd"' "$ROOT/.claude/settings.json" 2>/dev/null; then
  echo "Curator: evolves at session end (background daemon not loaded)"
else
  echo "Curator: in-session only (always-on daemon not enabled — see ACTIVATING-THE-DAEMON.md)"
fi

# Latest evolution digest (what the curator did while you were away)
if [ -f "$ROOT/EVOLUTION-LOG.md" ]; then
  DIGEST="$(awk '/^## /{c++} c==1{print} c==2{exit}' "$ROOT/EVOLUTION-LOG.md" 2>/dev/null)"
  if [ -n "$DIGEST" ]; then
    echo "--- latest evolution update ---"
    echo "$DIGEST"
    echo "-------------------------------"
  fi
fi

echo "You drive the project; the curator drives the framework. You never trigger scout/evolve — it's automatic."
echo "If something feels off, just say: \"we're going in the wrong direction\" → course-corrector kicks in."
