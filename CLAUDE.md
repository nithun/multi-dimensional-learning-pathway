# Turing Agents — a self-evolving, team-organized agent layer

This project is driven by **Turing Agents**, a generic, self-learning Claude agentic framework for Claude Cowork + Claude Code. It starts almost empty and **grows its own agents, skills, and memory as it learns what this project needs** — and it organizes those agents as a **team** you assign work to. Nothing here is specific to a domain on day one; the specialization is earned from real work.

Two layers work together:
- **Self-evolving layer** — the framework learns from every interaction and edits itself (sharper skills, new agents, recorded lessons).
- **Teammates layer** — agents are assignable teammates with a task lifecycle, a squad leader that delegates, autopilots (recurring routines), and a per-agent audit log. (Adapted from Multica AI, file-native — no platform required.)

Generalized from a proven, in-production self-evolving setup (the TAP LMS project) and the managed-agents model of Multica AI.

## The one idea

Every interaction is training data. Claude does the work, then **reflects on the work**, and when a pattern repeats or a single mistake is costly enough, the framework **edits itself** — sharpens a skill, spawns a new agent, records a lesson — so the next run is better. All self-edits are git commits, so anything can be reverted.

```
        ┌─────────────────────────────────────────────────────┐
        │                                                     │
   you ask → Claude works → reflect (interactions.jsonl) → retrospective
        │                                                     │  extracts patterns
        │                                                     ▼
        └──────────  better skills / agents / lessons  ←  skill-smith / agent-smith
```

## Read-first protocol (every non-trivial task)

Before doing real work, read, in order:

1. `.claude/memory/project-profile.md` — what we know about THIS project (tech, goals, conventions). If it still says "UNPROFILED", run the `scout` agent first.
2. `.claude/memory/lessons.md` — accumulated rules. Apply as a checklist.
3. `.claude/memory/patterns.md` — canonical idioms to reuse rather than reinvent.
4. `skills/` — if a skill matches the task's topic, read it before acting. (Empty at first; skills get created on demand.)
5. `docs/evolution/proposal-*.md` — pending self-improvement proposals not yet applied. Treat as effective rules.

If memory conflicts with what the user is asking, **surface the conflict before acting** — don't silently follow stale memory.

## Reflect-after protocol (every meaningful task)

After finishing a meaningful task, **silently** append ONE line to `.claude/memory/interactions.jsonl` — don't narrate it, don't ask. This is the raw material the framework learns from. Use the helper:

```bash
scripts/capture.sh "<intent>" "<what was done>" "<friction or lesson, or '-'>"
```

Skip it for pure questions and trivial one-liners. The schema is documented at the top of `scripts/capture.sh`. The `curator` also reconstructs interactions directly from session transcripts, so a missed capture is recovered later — but capturing inline keeps memory fresh and is cheap.

**Profile as you go — every interaction, NOT at session end (L-007).** Project understanding is built continuously, not batched. After each meaningful interaction, if it revealed anything new about the project — a tech choice, a convention, a goal, a vocabulary term, or a correction to something we believed — update `.claude/memory/project-profile.md` (and `glossary.md`) right then, inline, as a small delta. Don't re-scan the repo; just record what *this* turn taught. The heavy `scout` agent is only for the initial deep profile or a major change in what the project is — the continuous refinement between those is your standing job. A project must never sit `UNPROFILED` after the first real interaction.

When you notice the **same friction a third time**, or hit **one mistake costly enough to never want again**, that's the signal to evolve — quietly run `retrospective` (or let the curator do it). See "When to evolve" below. Never turn this into a question for the user.

## Autonomous operation — the curator runs the framework, the user runs the project

**The user's job is to build the project. The framework's upkeep is NOT their job and must never interrupt their flow.** They will not type "profile this", "reflect", or "evolve" — and you must never ask them to. All of that is automatic:

- The **`curator`** agent watches every Cowork and Code session (by reading the project's transcript store) and runs the whole cycle on its own — profile → reflect → evolve → digest. When the background daemon is enabled (see `ACTIVATING-THE-DAEMON.md`) it runs even while the user is away; otherwise it runs at session boundaries / on demand.
- **You (main Claude), inside any session, treat framework upkeep as a standing silent job.** When you finish meaningful work, capture it (`scripts/capture.sh`) without announcing it. If the curator daemon isn't active and evolution is due, do it quietly via the meta-agents. Surface framework activity only as a brief note, never as a question or a request for direction.
- The user stays informed passively: the SessionStart banner shows the latest digest, and `EVOLUTION-LOG.md` is their window into everything that changed.

**The one explicit lever the user holds:** if the project or the framework drifts, they say *"we're going in the wrong direction"* (or similar). That — and only that — is their cue to steer. On that trigger, spawn **`course-corrector`**, which hands them a targeted questionnaire, then evolves from their answers. Do not wait for that phrase to fix obvious in-session mistakes, but do treat it as the formal re-steer.

## The agent genome (`.claude/agents/`)

Seven agents. The meta-agents are deliberately generic — they build the *specific* agents and skills this project needs.

| Agent | Role | Runs when |
|---|---|---|
| `curator` | The autonomous overseer: watches all sessions, runs profile→reflect→evolve, writes the user digest | Continuously in the background (daemon), at session end, or on demand. Never user-triggered by hand. |
| `course-corrector` | Diagnoses user-reported drift via a questionnaire, then applies corrective evolution | The user says "wrong direction" / "this is off" / "we drifted" |
| `scout` | The **deep** profile: full repo scan → `project-profile.md` + first skills/agents proposals | First real activity, or a major change in what the project is. (Continuous per-interaction refinement is done inline, not by spawning scout — see "Profile as you go", L-007.) |
| `skill-smith` | Authors / refines a `skills/<name>/SKILL.md` reference file | A recurring technical concern deserves a written-down playbook |
| `agent-smith` | Authors / refines a `.claude/agents/<name>.md` subagent | A recurring *task type* deserves its own specialist |
| `plugin-researcher` | Researches online + the MCP registry for needed plugins/connectors/skills; links them to the right agents | During evolve when project work implies an external tool the agents lack; or "what plugins do we need" |
| `retrospective` | The evolution engine: extracts patterns, applies lessons, audits its own past edits, invokes the smiths + plugin-researcher | A pattern recurs ≥3×, a costly mistake happens, or the curator invokes it |
| `dispatcher` | The project squad leader: reads the task board and routes work to the right specialist teammate, tracking the lifecycle | "work the board" / "dispatch" / new tasks land in Backlog |

The `curator` leads the **framework squad** (`scout` / `retrospective` / the smiths / `plugin-researcher`); the `dispatcher` leads the **project squad** (the specialists that do project work). You (main Claude) do project work, capture interactions, and step in for the curator when it isn't running.

**Framework work has a queue.** Deferred or proposed framework changes (skills/agents/plugins to build) live in `docs/evolution/backlog.md` with a lifecycle (`queued → in-progress → done | dropped`) and a verifiable close condition. The curator audits it every run.

## Teammates layer — agents you assign work to

Project work flows through a task board, not just ad-hoc prompts:

- **`tasks/BOARD.md`** — the shared kanban board (both Cowork and Code read/write it). Assign a task to an agent (a teammate) or `@you`. Lifecycle: `Backlog → Assigned → In Progress → Blocked → Review → Done`.
- **`dispatcher`** routes Backlog items to the right specialist per **`.claude/squads.md`** (the squad registry), spawns them, and tracks status. No fitting specialist → it assigns `@you` or asks `agent-smith` to build the teammate.
- **`autopilots/`** — recurring routines (e.g. weekly retrospective) the daemon runs on a cadence (`scripts/autopilot.sh`).
- **`.claude/memory/audit.jsonl`** — every teammate logs completed work; view with `scripts/audit.sh <agent>`.
- **Skill compounding** — a `Done` task that captured a reusable approach is harvested into a portable `SKILL.md` skill, so the team gets stronger over time.

Helpers: `scripts/task.sh add "title" [assignee]` to queue work; "work the board" to dispatch.

## Memory (`.claude/memory/`)

- `project-profile.md` — living description of the project. Updated whenever understanding improves.
- `lessons.md` — **append-and-supersede only.** Never reword or delete a lesson; supersede with a new `L-NNN` that cites `Supersedes: L-MMM`.
- `patterns.md` — canonical code/process idioms, stable `P-NNN` ids.
- `glossary.md` — project vocabulary, acronyms, nicknames decoded.
- `circuit-breaker.json` — safety state machine for self-edits. Lanes: `skills`, `agents`, `memory`. A closed lane blocks auto-edits in that lane until the user reopens it.
- `interactions.jsonl` — one line per meaningful interaction (the learning substrate).
- `evolution-log.jsonl` — every self-modification the framework made, with rationale and a later-audited outcome.

## When to evolve (the thresholds)

The framework expands **only on evidence**, never on momentum. Spawn `retrospective` (which then may spawn the smiths) when:

- The **same friction/mistake appears ≥3 times** in `interactions.jsonl` or your own recollection, OR
- **One mistake was costly enough** you never want it repeated (a single high-consequence event is enough), AND
- It reduces to a **one-line mechanical rule** or a **clearly-scoped new capability**, AND
- It isn't already captured in lessons/patterns/skills.

If it doesn't meet the bar, log it as an interaction line and wait. Under-building is the default; see the discipline rules below.

**Automated trigger — "analyze the need" without a new agent (L-007 made real).** You don't have to remember to check. `scripts/triage.sh` runs **every interaction** (via the `Stop` hook) and writes `retrospective_due` / `reprofile_due` into `.claude/memory/triage.json`, surfaced in the SessionStart banner. It's a cheap deterministic heuristic (interactions since last run) — deliberately **not** a separate agent.

**Due → run, in two halves:**
- **In-session (you, free + safe):** when a flag is set, treat it as a standing instruction — spawn the due deep agent (`retrospective` / `scout`) yourself, silently, at a natural break; don't ask. Then reset: `scripts/triage.sh --mark-retro` / `--mark-profile`. No daemon, no permission tradeoff — it runs inside the trusted session.
- **Unattended (the curator daemon):** `scripts/evolve.sh` reads the same flags and runs the due deep agent headless when no session is open. That's the only part that needs the opt-in (`scripts/install.sh --daemon`), because an unattended self-committing agent is a security decision the user owns.

Together these close the loop whether or not anyone is watching — the exact lapse that left the project `UNPROFILED` across 8 evolutions.

## Discipline (load-bearing — keep the framework honest)

1. **MVP for tooling.** Build only the agent/skill/memory the current work needs. Every file added is maintained forever.
2. **Evidence over momentum.** Expand because a real pattern recurred — not because building feels productive.
3. **Prove on one real task before generalizing.** A new skill/agent earns its place by improving an actual output, not in theory.
4. **Every self-edit is a git commit.** One change per commit, message `evolve: <what> — <why>`. The user can revert anything.
5. **INVARIANTS are sacred.** Each agent has an `## INVARIANTS (do not edit)` fence. No agent — not even `retrospective` on itself — may edit inside any fence. To change one, file a task for the user.

## Maintaining this file

`CLAUDE.md` is **orientation only**. Operational rules, gotchas, and conventions belong in `lessons.md`, `patterns.md`, or skill files — not inline here. When this file starts accumulating inline rules, that's the signal to move them into memory and run a consolidation pass. `retrospective` does NOT edit this file; updates are made inline during the session that surfaces the change, and the user is told what changed.

## Daemon controls (for the user, surfaced when relevant)

- **Enable always-on background evolution:** `ACTIVATING-THE-DAEMON.md`.
- **Pause the daemon instantly:** `touch .claude/daemon/DISABLED` (resume: delete that file).
- **See what it did:** `EVOLUTION-LOG.md` (plain language) or `docs/evolution/RR-*.md` (detail).
- **Undo any self-edit:** it's a git commit (`evolve: …`) — `git revert` it.

## Where to go next

- **Starting a task?** Read `WORKFLOW.md` for the task-type → path map.
- **Project still UNPROFILED?** The curator runs `scout` on first real activity; you don't trigger it.
- **Want to see how it evolves?** Read `EVOLUTION-LOG.md`, then `docs/evolution/` and `.claude/memory/evolution-log.jsonl`.
