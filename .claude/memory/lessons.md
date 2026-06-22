# Lessons learned

Project-specific rules accumulated across sessions. Every agent reads this at the start of any non-trivial task and applies the relevant rules as a checklist.

## Editing rules — APPEND-AND-SUPERSEDE ONLY

- **Never reword or delete a lesson body.** Past lessons are historical record.
- **Supersede** via a new entry whose last line is `Supersedes: L-NNN`. Both entries stay; the newer one wins by precedence.
- **Maintained by the `retrospective` agent.** Direct edits should be rare; non-trivial changes land as proposals in `docs/evolution/` first.
- Format: each lesson is a one-liner (≤3 sentences) with an `L-NNN` id and a source citation. Supporting detail belongs in a skill file the lesson links to, not inline here.

---

## Framework operation (seeded with the install; supersede as the project teaches better)

- L-001 — Read `project-profile.md` → `lessons.md` → `patterns.md` → matching skill BEFORE doing real work. Skipping orientation is how the same mistake recurs. *Source: framework design.*
- L-002 — Reflect AFTER every meaningful task: append one line to `interactions.jsonl` (`scripts/capture.sh`). Unreflected work teaches the framework nothing. *Source: framework design.*
- L-003 — Expand the framework on **evidence, not momentum**: a pattern recurred ≥3× or one mistake was costly. Building tooling because it feels productive is the failure mode this rule prevents. *Source: framework design.*
- L-004 — Every self-edit is one atomic git commit (`evolve: <what> — <why>`). This is the revert safety net; a self-modifying system without it is unsafe. *Source: framework design.*
- L-005 — No agent edits inside any `## INVARIANTS` fence — not even `retrospective` on itself. To change an invariant, file a task for the user. *Source: framework design.*
- L-006 — When memory conflicts with the user's request, surface the conflict before acting. Stale memory followed silently is worse than no memory. *Source: framework design.*

## Project lessons (extracted from real work)

- L-007 — **Profile continuously, every interaction — never wait for session end.** Project understanding is built as a small inline delta after each meaningful turn (new tech/convention/goal/vocab/correction → update `project-profile.md` then), NOT batched. The heavy `scout` agent is for the initial deep scan and major changes only; don't spawn it per turn. A project must never sit `UNPROFILED` after the first real interaction. *Source: the project sat UNPROFILED across 8 evolutions because profiling was designed as a deferred "first activity" event (2026-06-22 evolution analysis).*

- L-008 — **Verify the artifact before closing the session.** When a new capability is built (agent, script, CLI, MCP tool), run or test it in the same session — never mark it done unverified. Unverified work is technical debt that compounds silently. *Source: 4 of 5 major builds in IX-005 through IX-009 explicitly verified in-session; the ones that didn't shipped blind (2026-06-22 retrospective).*

- L-009 — **Park heavy bets; ship the lean version; never silently drop scope.** When a feature proves too heavy (platform, Docker, Go stack), move it to a branch (`platform-alpha`) rather than dropping it, and record the reason in `backlog.md` with a `dropped`/`deferred` status. Lean version ships on `main`. *Source: pattern recurred 3× — Docker/Postgres dropped for local MCP (IX-005), Go platform parked on platform-alpha (IX-004), heavyweight autopilots deferred (IX-003) — all handled identically (2026-06-22 retrospective).*

<!-- Further project lessons (L-010+) get appended by retrospective as work reveals them. -->
