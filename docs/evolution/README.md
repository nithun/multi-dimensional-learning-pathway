# docs/evolution/

The framework's audit trail — how it has learned and changed over time. Everything here is written by the meta-agents (`scout`, `retrospective`, the smiths), not by hand.

## What lands here

- `RR-YYYY-MM-DD.md` — **retrospective run reports.** One per `retrospective` run: what it read, what patterns it found, what it applied, what it deferred, and its self-audit of past edits.
- `proposal-YYYY-MM-DD-<slug>.md` — **deferred or gated changes.** Medium-confidence ideas, or any edit blocked by a paused/closed circuit-breaker lane. These are "effective rules" once written — the read-first protocol treats them as pending guidance until applied or dismissed.
- `scout-proposals-YYYY-MM-DD.md` — **scout's recommendations** for the first skills/agents a project should grow, with the trigger that justifies each.

## How to read the trail

- Want to know *why* a skill or agent exists? Find its `EV-NNN` in `.claude/memory/evolution-log.jsonl`, then the run report that created it here.
- Want to know if the framework's self-edits are actually helping? Read the "Self-audit findings" section of recent `RR-*.md` files and the `recent_outcomes` in `.claude/memory/circuit-breaker.json`.
- Want to undo a self-edit? It's a git commit (`evolve: ...`) — `git revert` it. The next retrospective run notices the revert and won't re-apply it.
