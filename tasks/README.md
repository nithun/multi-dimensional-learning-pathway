# tasks/ — agents as teammates

This is the team-ops layer. You assign work to agents the way you'd assign an issue to a colleague; they pick it up, move it through a lifecycle, report blockers, and on completion the solution can compound into a reusable skill. (Adapted from Multica's managed-agents model — file-native, no platform required.)

## Files

- `BOARD.md` — the kanban board: the queue + lifecycle, one row per task. Both Cowork and Code read/write it.
- `T-NNN-<slug>.md` — optional detail file for a task that needs more than a row (spec, acceptance criteria, links). Use `T-template.md` as the starting point.

## The lifecycle

```
Backlog → Assigned → In Progress → Blocked ⇄ In Progress → Review → Done
                                                                   ↘ Dropped
```

- **Backlog** — captured, not yet assigned.
- **Assigned** — has a teammate (agent) or `@you`. The `dispatcher` moves Backlog → Assigned by routing to the right squad member.
- **In Progress** — the assignee is actively working it.
- **Blocked** — waiting on something; the blocker is named in the row, and the curator surfaces stale blocks in the digest.
- **Review** — done by the agent, awaiting your check.
- **Done / Dropped** — closed. A `Done` task that captured a reusable approach gets harvested into a skill.

## Assigning work

- `scripts/task.sh add "Write the billing exporter" feature-builder` — append a task (auto-IDs `T-NNN`).
- Or just say it in chat: *"add a task to do X and assign it to <agent>"* — the dispatcher / main Claude updates the board.
- *"work the board"* / *"dispatch"* → spawns `dispatcher`, which routes everything in Backlog to the right specialist (see `.claude/squads.md`) and starts it.

## Who does the work

Tasks route to **specialist agents** (your squad). Early on the squad is small (the meta-agents); as recurring *project* task-types appear, `agent-smith` builds new specialists and the `dispatcher` starts routing to them. A task with no fitting specialist is either assigned to `@you` or flagged for `agent-smith` to create the right teammate.

## Audit

Every agent logs what it completed to `.claude/memory/audit.jsonl`. See a teammate's history: `scripts/audit.sh <agent-name>`.
