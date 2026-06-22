# Turing Agents

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**A self-evolving, team-organized agent framework for Claude Cowork + Claude Code.**

Drop it into a project and it does two things at once:

1. **Self-evolves** — it learns your project, builds its own agents and skills as the work demands them, and gets better from every interaction. It starts almost empty and specializes itself.
2. **Runs agents as a team** — agents are teammates you assign work to, with a task lifecycle, a squad leader that delegates, autopilots (recurring routines), and a per-agent audit log.

You stay focused on building. A background **curator** watches every session and tends the framework; you never trigger profiling, reflection, or evolution by hand. MIT-licensed. Generalized from a proven in-production setup (TAP LMS) and the managed-agents model of [Multica AI](https://github.com/multica-ai/multica).

---

## Quick start

```bash
# 1. pull a release into a new project folder
git clone <this-repo> my-project && cd my-project
git checkout v0.2.0

# 2. reset to a clean slate for YOUR project
scripts/init-project.sh --yes

# 3. start building in a Claude Code / Cowork session here.
#    The framework auto-profiles on first real work and learns as you go.

# 4. (optional) always-on background evolution, even while you're away:
scripts/install.sh --daemon
```

That's it. Open a session and work — `scout` profiles the project on first activity, the curator digests every session, and `EVOLUTION-LOG.md` + the SessionStart banner keep you posted.

## How it works

```
   you build → every session is watched → curator digests + evolves the framework
        ▲                                                         │
        └─────────  sharper skills / new agents / lessons  ←──────┘
                    (built by skill-smith / agent-smith / plugin-researcher)

   project work → task board → dispatcher routes to the right teammate → done → skill harvested
```

## The agents (8)

**Framework squad** (self-evolution) — led by `curator`:

| Agent | Role |
|---|---|
| `curator` | Autonomous overseer: watches all sessions, runs profile→reflect→evolve, writes your digest |
| `scout` | Profiles the project into `project-profile.md`; proposes first skills/agents |
| `skill-smith` | Authors/refines `skills/<topic>/SKILL.md` playbooks |
| `agent-smith` | Authors/refines `.claude/agents/<name>.md` specialists |
| `plugin-researcher` | Finds needed plugins/MCP connectors online + in the registry; links them to agents |
| `retrospective` | Evolution engine: extracts lessons, audits its own past edits |
| `course-corrector` | On "we're going in the wrong direction" → questionnaire → corrective evolution |

**Project squad** (the work) — led by `dispatcher`, which routes board tasks to specialists that `agent-smith` builds as your project's recurring task-types appear.

## Layout

```
CLAUDE.md                     the loop + protocols (read first)
WORKFLOW.md                   task-type → path map
.claude/
  settings.json               SessionStart hook → auto-loads evolution state each session
  squads.md                   squad registry (task type → teammate)
  agents/*.md                 the 8 agents (each with a protected INVARIANTS fence)
  memory/
    project-profile.md        what we know about THIS project (living)
    lessons.md                append-and-supersede rules
    patterns.md · glossary.md canonical idioms · project vocabulary
    circuit-breaker.json      safety state machine (skills/agents/memory lanes)
    interactions.jsonl        one line per meaningful interaction (learning substrate)
    evolution-log.jsonl       every self-modification + audited outcome
    audit.jsonl               per-teammate completed-work log
  daemon/                     curator runtime: watermark, lock, logs (git-ignored)
tasks/
  BOARD.md                    the team kanban board (assign work to agents)
  T-template.md               detailed-task template
autopilots/                   recurring routines (weekly retrospective, …)
skills/                       on-demand playbooks (empty until earned)
docs/evolution/               run reports, proposals, backlog, design studies
scripts/
  capture · orient · evolve   reflect · banner · curator daemon runner
  task · audit · autopilot     board · audit log · recurring routines
  install · init-project       portable setup · fresh-project reset
EVOLUTION-LOG.md              plain-language digest of everything the framework learned
ACTIVATING-THE-DAEMON.md      how to turn on always-on background evolution
```

## Safety model

- **Every self-edit is an atomic git commit** (`evolve: …`) → revert anything with `git revert`.
- **Circuit-breaker** pauses a lane (skills/agents/memory) after repeated bad edits; only you reopen it. Set `"mode": "proposal-only"` in `circuit-breaker.json` to gate every change.
- **INVARIANTS fences** in each agent are off-limits to all agents — `retrospective` can't even edit its own.
- **The framework never edits your source code** — only its own files (`.claude/`, `skills/`, `docs/`, memory, the framework docs).
- **The always-on daemon is opt-in** — it runs Claude headless with relaxed permissions, so you enable it explicitly (`scripts/install.sh --daemon`); pause anytime with `touch .claude/daemon/DISABLED`.

## Steering it

You usually type nothing — it's automatic. Your one lever: if the project or framework drifts, say **"we're going in the wrong direction"** → `course-corrector` hands you a questionnaire and fixes the framework from your answers.

## Managing many projects

A cross-project **control plane** (a `turing` CLI + an MCP extension + an autonomous fleet conductor) is in active development on the `main` branch — it lets you register and manage many Turing Agents projects from one place, as a Claude Cowork extension. It's intentionally **not** part of this framework tag (which is the per-project template you pull). Track it on `main`.

## Requirements

macOS (for the launchd daemon; the rest is portable), `git`, and the `claude` CLI (Claude Cowork / Claude Code). The always-on daemon needs `claude` on PATH. The framework itself is just Markdown + Bash; no other dependencies.

## License

MIT — see [LICENSE](LICENSE).
