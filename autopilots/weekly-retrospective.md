# Autopilot: weekly-retrospective
enabled: true
cadence: 7d
agent: retrospective
---
Run a full weekly retrospective sweep for this project. Read .claude/agents/retrospective.md and follow it exactly:
- Self-audit the last ~5 evolution-log edits (classify effective/neutral/ineffective/reverted) and update circuit-breaker.json if a lane tripped.
- Read the last 7 days of interactions.jsonl, the task board (tasks/BOARD.md), and the backlog (docs/evolution/backlog.md).
- Extract patterns that clear the threshold (≥3 recurrences or one high-consequence event); apply lessons/patterns; spawn skill-smith / agent-smith / plugin-researcher only on real evidence.
- Audit the backlog: flip met close conditions to done, surface stale rows.
- Write a run report to docs/evolution/RR-YYYY-MM-DD.md and prepend a short digest entry to EVOLUTION-LOG.md.
Honor the circuit-breaker and every INVARIANTS fence. Never touch source code. Commit framework files only, atomically.
