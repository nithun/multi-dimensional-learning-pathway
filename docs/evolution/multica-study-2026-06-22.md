# Study: Multica AI → what the Cowork framework adopts

_Date: 2026-06-22. Source: https://github.com/multica-ai/multica (open-source "managed agents platform", Apache-2.0, ~37k★, Go + Next.js + Postgres/pgvector)._

## What Multica is

Infrastructure that turns coding agents into **teammates**: you assign an agent an issue like a colleague, it picks up the work, executes the full lifecycle autonomously (enqueue → run → completion/failure), reports blockers, and **every completed solution becomes a reusable skill**. Larger teams use **Squads** — a group led by an agent that delegates to members. **Autopilots** schedule recurring work (cron / webhook / manual). **Runtimes** are compute environments that report which agent CLIs they have, so work routes intelligently. Multi-provider (Claude Code, Codex, Copilot, Gemini, Cursor, …).

## Feature-by-feature mapping to our framework

| Multica feature | Our equivalent / gap | Decision |
|---|---|---|
| **Skill reuse / compounding** (agentskills.io `SKILL.md` standard) | We have `skills/` + `skill-smith`. Format already matches the standard. | **Adopt the standard explicitly** so skills are portable across agents/providers. |
| **Task queue + lifecycle + per-agent audit log** | We have `interactions.jsonl` (audit) + `evolution-log.jsonl`, but no *queue* of pending framework work. | **Build `docs/evolution/backlog.md`** — a lifecycle ledger (queued → in-progress → done/dropped). |
| **Squads** (leader delegates to members) | `curator` already orchestrates `scout`/`retrospective`/smiths. | Already have it; formalize curator-as-leader in docs. No new code. |
| **Autopilots** (recurring scheduled routines) | launchd daemon = the "continuous" autopilot. | Document the cadence; add periodic plugin-research as a routine. MVP — no new scheduler. |
| **Capability / plugin linking** (shared skill+tool library) | We had no mechanism to discover external tools (MCP connectors/plugins) and grant them to agents. | **Build `plugin-researcher`** — research online + the MCP registry, then wire connectors to the right agents during evolve. |
| **Blocker / status reporting** | curator writes a digest + "Heads-up". | Strengthen: backlog surfaces blockers explicitly. |
| **Runtimes / multi-provider routing, web+mobile+Go platform** | N/A — we are a single-project, file-based Claude Code layer. | **Out of scope.** Cloning platform infra would violate MVP-for-tooling. |

## What we build now (this session)

1. `plugin-researcher` agent — the explicit ask: find needed plugins/MCP connectors/skills online, link them to the respective agents, runs during evolve.
2. `docs/evolution/backlog.md` — Multica-style task/lifecycle ledger for framework work.
3. Skill-standard alignment in `skill-smith` + `skills/README.md`.
4. Wire `plugin-researcher` into the curator/retrospective evolve cycle.

## What we deliberately defer (in the backlog, evidence-gated)

- Formal "squad" routing config (curator-as-leader already covers it).
- Extra autopilots beyond the daemon + periodic plugin-research.
- Anything platform-shaped (web dashboard, multi-provider runtimes, mobile) — wrong shape for this framework.
