# Multi-Dimensional Learning Pathway

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**An AI/agent research project exploring multi-dimensional learning pathways — built on a self-evolving agent framework.**

> **Status: early-stage / bootstrapping.** The research direction below is the framing, not a finished result. Specifics (methods, models, findings) firm up as the work happens, and this README grows with them. The repo currently holds the agent scaffold the research runs on — project-specific code and write-ups land here as they're produced.

---

## What this is

A research project investigating **multi-dimensional learning pathways** — how learning can be modeled, navigated, and adapted across several dimensions at once (rather than a single linear track) — using AI agents as both the subject and the tooling.

It's deliberately exploratory. Rather than committing up front to one architecture, the project uses a **self-evolving agent layer** that profiles the work, records what's learned, and grows its own specialist agents and playbooks as the research takes shape. The substrate is meant to compound: every experiment leaves the toolchain a little sharper for the next one.

## Research focus

Open questions this project is organized around (these will be refined as the work proceeds):

- **Dimensions** — what are the meaningful axes of a learning pathway (e.g. skill, depth, modality, prerequisite structure, time), and how do they interact?
- **Navigation** — how does an agent (or a learner) move through a multi-dimensional space without collapsing it back into a single line?
- **Adaptation** — how does a pathway re-shape itself in response to progress, gaps, and feedback?
- **Agents as method** — where do autonomous agents help (mapping the space, proposing routes, evaluating progress), and where do they get in the way?

Findings, experiments, and design notes will be written up under `docs/` as they're produced.

## Built on Turing Agents

The agent layer in this repo is the **Turing Agents** framework (v0.2.0) — a generic, self-evolving Claude agent scaffold for Claude Cowork + Claude Code. It starts almost empty and grows the specific agents, skills, and memory this project needs from real work.

In short:

- **It learns the project.** A `curator` watches every working session, profiles the repo, and records lessons — you don't trigger profiling or evolution by hand.
- **It runs agents as a team.** Agents are teammates you assign work to via a task board (`tasks/BOARD.md`), with a squad leader (`dispatcher`) that routes work to specialists.
- **Every self-edit is a git commit** (`evolve: …`), so anything the framework changes about itself can be reverted.

If you're here to understand *how the agents work* rather than the research, start with:

- [`CLAUDE.md`](CLAUDE.md) — the operating loop and protocols (read first).
- [`WORKFLOW.md`](WORKFLOW.md) — task-type → path map.
- [`EVOLUTION-LOG.md`](EVOLUTION-LOG.md) — plain-language log of everything the framework has learned.

The framework is MIT-licensed and generalized from a proven in-production setup (TAP LMS) and the managed-agents model of [Multica AI](https://github.com/multica-ai/multica).

## Repository layout

```
CLAUDE.md                     the agent operating loop + protocols (read first)
WORKFLOW.md                   task-type → path map
.claude/
  agents/*.md                 the self-evolving agent squad
  memory/                     project profile, lessons, patterns, glossary, logs
  squads.md                   squad registry (task type → teammate)
  settings.json               SessionStart hook → loads framework state each session
tasks/BOARD.md                the team kanban board (assign work to agents)
autopilots/                   recurring routines (weekly retrospective, …)
skills/                       on-demand playbooks (grown as needed)
docs/                         research notes, design studies, evolution reports
scripts/                      framework tooling (capture · orient · evolve · task · …)
EVOLUTION-LOG.md              plain-language digest of what the framework learned
```

## Getting started

This repo is already initialized — no template reset needed. To work on it:

```bash
# clone
git clone https://github.com/nithun/multi-dimensional-learning-pathway.git
cd multi-dimensional-learning-pathway

# open a Claude Code / Cowork session in this folder and start working.
# the framework auto-profiles on first real work and learns as you go.

# (optional) always-on background evolution, even while you're away:
scripts/install.sh --daemon
```

Requirements: macOS (for the launchd daemon; the rest is portable), `git`, and the `claude` CLI (Claude Cowork / Claude Code). The framework itself is just Markdown + Bash — no other dependencies.

## License

MIT — see [LICENSE](LICENSE).
