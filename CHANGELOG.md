# Changelog

All notable changes to Turing Agents. Versioned with git tags; pull a tag to start a new project from that release.

## [0.2.0] — 2026-06-22

Framework-only release: the generic self-evolving agent layer + the fixes and automation since v0.1.0. The `app/` control plane (the cross-project manager) is **in-progress product dev and intentionally excluded** from this tag — it lives on `main`.

### Fixed
- **Daemon `timeout` bug** — `scripts/evolve.sh` / `autopilot.sh` invoked `timeout`, which is absent on stock macOS, so the daemon would have failed every tick. Now uses `timeout`/`gtimeout` only if present, else runs unbounded (2h stale-lock backstop).
- `.gitignore` now excludes Python `__pycache__`/`*.pyc` and the derived `triage.json`.

### Added — reflective automation
- **Continuous profiling (L-007):** profiling runs every interaction as an inline delta, not at session end; `scout` is reserved for the deep/initial pass. Closes the "stuck UNPROFILED" failure mode.
- **Triage trigger** (`scripts/triage.sh`) — a deterministic "what's due" heuristic (re-profile / retrospective) run **every interaction** via a new `Stop` hook (`scripts/reflect-hook.sh`); surfaced in the SessionStart banner; wired into the daemon so due→run is precise.

### Added — daemon hardening (B-014)
- **Scoped permission sandbox** (`.claude/daemon/daemon-settings.json`, via `--settings`) replacing `--dangerously-skip-permissions`: framework edits + git allowed; source paths, network, `git push`, and destructive shell **hard-denied**.
- **Deterministic backstop**: if a run commits any source path, the daemon pauses + alerts (non-destructive).

### Added — first real self-audit
- `retrospective` ran for the first time: classified the bootstrap outcomes `effective`, produced `docs/evolution/RR-2026-06-22.md`, and extracted the first project lessons — **L-008** (verify-before-done) and **L-009** (park-heavy-bets / never silently drop scope).

## [0.1.0] — 2026-06-22

First public release. A self-evolving, team-organized agent framework for Claude Cowork + Claude Code.

### Self-evolving layer
- Read-first / reflect-after / evolve loop driven by `CLAUDE.md`.
- Memory: `project-profile`, append-and-supersede `lessons`, `patterns`, `glossary`, `circuit-breaker`, `interactions.jsonl`, `evolution-log.jsonl`.
- Meta-agents: `scout` (profile), `skill-smith`, `agent-smith`, `retrospective` (evolution engine with self-audit), `plugin-researcher` (online + MCP-registry tool discovery), `course-corrector` (drift diagnosis).
- Autonomous `curator` that watches all session transcripts and evolves the framework; optional always-on background daemon (launchd) — opt-in.
- Safety: every self-edit is a revertible git commit; circuit-breaker lanes; protected INVARIANTS fences.

### Teammates layer (agents as teammates — adapted from Multica AI, file-native)
- Task board with lifecycle (`tasks/BOARD.md`) — assign work to agents like colleagues.
- `dispatcher` (squad leader) routes tasks to specialists per `.claude/squads.md`.
- Autopilots (`autopilots/`) — recurring routines run by the daemon (`scripts/autopilot.sh`).
- Per-agent audit log (`.claude/memory/audit.jsonl`, `scripts/audit.sh`).
- Skill compounding — completed reusable solutions harvested into portable `SKILL.md` skills.

### Tooling
- `scripts/`: `capture`, `orient`, `evolve`, `autopilot`, `audit`, `task`, `install`, `init-project`.
- Portable: `install.sh` generates the daemon for any path; `init-project.sh` resets state for a fresh project.
- MIT licensed.
