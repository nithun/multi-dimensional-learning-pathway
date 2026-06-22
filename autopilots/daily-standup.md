# Autopilot: daily-standup
enabled: false
cadence: 12h
agent: dispatcher
---
Produce a short standup from the task board for this project. Read tasks/BOARD.md and .claude/memory/audit.jsonl:
- What moved to Done since the last standup (per teammate).
- What's In Progress and who owns it.
- What's Blocked and on what — surface these first.
- What's sitting in Backlog unassigned that the dispatcher should route.
Prepend a dated "Standup" entry to EVOLUTION-LOG.md (a few lines, plain language). Do not change task state — this is read-only reporting. Never touch source code.
