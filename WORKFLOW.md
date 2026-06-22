# Cowork — Workflow map

One-screen reference for how work flows and how the framework evolves. Agent definitions live in `.claude/agents/`. Project context is in `CLAUDE.md`. Accumulated rules are in `.claude/memory/lessons.md`.

## Who does what

**The user builds the project. The `curator` runs the framework.** The user never triggers profiling, reflection, or evolution — it's automatic. Their one steering lever is saying *"we're going in the wrong direction."*

## The loop, every task

```
1. ORIENT   read project-profile.md → lessons.md → patterns.md → matching skill (if any)
2. WORK     do the task; apply the lessons as a checklist
3. REFLECT  silently append one line to interactions.jsonl  (scripts/capture.sh ...)
4. EVOLVE   the curator digests sessions + evolves — in the background (daemon),
            at session end, or in-session via main Claude when the daemon is off
```

Steps 1–3 happen every meaningful task (the user isn't involved). Step 4 is the curator's job, evidence-gated. The user is kept informed by the SessionStart banner and `EVOLUTION-LOG.md`.

## Paths per task type

### The project is new / unprofiled
Spawn **`scout`** → it writes `.claude/memory/project-profile.md`, a starter `glossary.md`, and proposes the first skills/agents (as proposals, not auto-built). You review the proposals; build the ones that pay off now.

### A normal task in a known project
Direct work by main Claude, after the ORIENT step. Reflect after. No agent needed for most tasks — the meta-agents are for *evolving the system*, not for doing every task.

### A recurring technical concern surfaces (e.g. "every GCP IAM change needs the same 4 checks")
Spawn **`skill-smith`** → it writes `skills/<topic>/SKILL.md` capturing the playbook. From then on, the ORIENT step loads it automatically.

### A recurring *task type* surfaces (e.g. "we keep doing cost-audit passes")
Spawn **`agent-smith`** → it writes `.claude/agents/<name>.md`, a specialist subagent with its own INVARIANTS fence. From then on you can dispatch that task to its specialist.

### Time to learn from accumulated work
Spawn **`retrospective`** ("run retrospective" / "evolve") → it reads memory + `interactions.jsonl` + `evolution-log.jsonl`, audits its past edits, extracts new lessons/patterns, and — when justified — spawns `skill-smith` / `agent-smith`. Writes a run report to `docs/evolution/RR-YYYY-MM-DD.md`.

## Evolve triggers (when to spawn `retrospective`)

- Same friction/mistake appears **≥3 times**, OR a **single high-consequence** mistake, AND
- it reduces to a **one-line rule** or a **clearly-scoped capability**, AND
- it's **not already** in lessons / patterns / skills.

Manual triggers: the user says "evolve", "retrospect", "learn from this", "what should we improve". Run a light sweep roughly weekly or after any intense work session.

## What evolves vs. what is human-only

| Self-editable by the framework | Human authority (framework proposes, never auto-edits) |
|---|---|
| `skills/*/SKILL.md` | Source code / app files |
| `.claude/agents/*.md` (outside INVARIANTS fences) | Anything inside an `## INVARIANTS` fence |
| `.claude/memory/lessons.md`, `patterns.md`, `glossary.md` | `CLAUDE.md` procedural sections (updated inline by main Claude, with notice) |
| `.claude/memory/project-profile.md` | The decision to reopen a closed circuit-breaker lane |

## Safety net

- Every self-edit is an atomic git commit (`evolve: <what> — <why>`) → fully revertible.
- `circuit-breaker.json` pauses a lane after repeated reverts; only the user reopens it.
- `retrospective` audits its own past edits each run — a rule that didn't reduce its target gets flagged, and repeated reverts close the lane automatically.
- No agent edits inside any INVARIANTS fence.

## You usually type nothing — it's automatic

The framework profiles, reflects, and evolves on its own. The phrases below still work if you ever want to nudge it manually, but day to day you just build:

- *"we're going in the wrong direction"* / "this is off" / "we drifted" → `course-corrector` (your main lever)
- "profile this project" → `scout` (otherwise the curator runs it automatically)
- "evolve" / "run retrospective" / "learn from this session" → `retrospective` / `curator`
- "write a skill for X" → `skill-smith` · "make an agent for X" → `agent-smith`
- "what plugins/tools do we need" / "find a connector for X" → `plugin-researcher`
- "add a task" / `scripts/task.sh add "…" [assignee]` · "work the board" / "dispatch" → `dispatcher`
- see the project work queue: `tasks/BOARD.md` · the framework work queue: `docs/evolution/backlog.md`
- pause everything: `touch .claude/daemon/DISABLED` · enable always-on: see `ACTIVATING-THE-DAEMON.md`

## Project work via the board (agents as teammates)

For real project work, assign tasks instead of one-off prompts:
1. `scripts/task.sh add "Build the X exporter" feature-builder` (or say it in chat) → lands in `tasks/BOARD.md` Backlog.
2. "work the board" → `dispatcher` routes each task to the right specialist (per `.claude/squads.md`), spawns it, tracks the lifecycle, surfaces blockers.
3. On `Done`, a reusable solution is harvested into a skill (`skill-smith`), so the team compounds capability. Completed work is logged to `.claude/memory/audit.jsonl`.
