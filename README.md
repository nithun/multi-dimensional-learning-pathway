# Multi-Dimensional Learning Pathway (MDLP)

[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**A probabilistic, verifier-grounded, open-ended framework for self-improving learners — software agents *and* humans — that selects every next learning action to maximize expected learning gain, measured on held-out evidence the learner never optimized against.**

> **Status (2026-07-02):** the algorithm is **spec-complete and gate-approved** (v0.2, §1–§19), and the first pre-registered milestone has been **executed and passed**: Milestone-0 returned **GO** with a live model in the loop — held-out competence **0.495 vs 0.025** no-learning baseline (**+0.47**), memorization probes failing as designed (2026-07-01). Milestone-1 mechanisms (growth, spacing, warm-start, prerequisite-gap diagnosis, revisit triggers) are live-confirmed (2026-07-02). Honest framing: an **existence result** — one skill, one run, a verifier-friendly domain — not yet a generality claim. See the [paper §5.9](docs/research/PAPER.md) and the [project site](https://nithun.github.io/multi-dimensional-learning-pathway/).

---

## The idea

Personalized-learning systems and self-improving agents face the same control problem: *from the learner's current state, which next learning action most improves it?* MDLP answers it probabilistically and openly:

- **A real state model.** Competence is a dual Beta posterior per *skill × difficulty* (slow-decay mastery, fast-decay drift) — not a deterministic label.
- **The corrected objective.** Greedy `argmax P(success)` picks the already-mastered action and learns nothing. MDLP maximizes `E[Δ competence]` — the learning-progress frontier.
- **Verifier-grounded.** Every reward comes from a real verifier on **held-out** items (code execution, schema checks, task success). Skills without a reliable verifier stay out of the autonomous loop — stated as the framework's binding precondition, not hidden.
- **Two load-bearing principles.** **P1 — measurement independence:** every quantity that drives a decision is estimated on data the learner's optimization never touched. **P2 — reversible openness:** the schema grows from data, but every `add` has an inverse (merge, prune, decay, rollback).

One decision core serves both learner types through a `LearnerAdapter`: an agent's oracle is execution; a human's is held-out assessment (IRT-3PL + behavioural signals — designed, roadmap-stage).

## The research corpus (`docs/research/`)

| Document | What it is |
|---|---|
| [`ALGORITHM-v0.2-pathway-learner.md`](docs/research/ALGORITHM-v0.2-pathway-learner.md) | **The spec of record** — §1–§19: state model, statistical gates, eval harness, growth/validity/frontier meta-functions, Tutor, calibration, re-visiting, unified retrieval, self-modification (SOLVE/JUDGE), multi-agent fleets, self-calibrating gate. All additions additive, all gate-approved. |
| [`BUILD-SPECS.md`](docs/research/BUILD-SPECS.md) | Six implementable capability specs, each formally approved (82–85/100): info-gain selection (A1), warm-start (A5), misconception clustering (B1), prereq-gap diagnosis (B2), fleet transfer (B3), forgetting-aware spacing (B4). |
| [`PAPER.md`](docs/research/PAPER.md) | The paper: method, related work, a **pre-registered evaluation protocol**, and the first executed milestone (M0: GO) in §5.9. |
| [`ALGORITHM-v0.1-redteam.md`](docs/research/ALGORITHM-v0.1-redteam.md) | The adversarial pressure-test that shaped v0.2 — ~40 findings, 8 root causes, 3 pilot-killers found *before* anything ran. |
| [`DATA-LAYER.md`](docs/research/DATA-LAYER.md) | The 5-store substrate (truth / state / vector / graph / cache, + artifacts) — embedded zero-infra default, pluggable full tier. |
| [`HUMAN-LEARNING-VERIFIER.md`](docs/research/HUMAN-LEARNING-VERIFIER.md) + [M0 protocol](docs/research/HUMAN-LEARNING-M0-PROTOCOL.md) | The human-side go/no-go (C1): design-complete, pre-registered, awaiting a cohort. Roadmap, not a current deliverable. |
| [`reviews/`](docs/research/reviews/) | The full audit trail: every capability and spec section passed a two-stage **review-360 → change-approver** gate; these are the review and decision records. |
| [`RELEASE-PLAN-v2.md`](docs/RELEASE-PLAN-v2.md) + [`HANDOVER-v2.md`](docs/research/HANDOVER-v2.md) | The v2 release plan (maturity tiers, the M0 hard gate — now cleared) and the implementation handover with dated status. |

## Results so far

- **M0 (does it learn at all?): GO** — live model in the loop, 920 calls, zero runner errors, n_held=15 × 10 ticks, paired-gated at z=2; selection ran through the learning-gain policy (Thompson-sampled learning progress + coverage floor), not a fixed rotation. Two earlier runs invalidated by an infrastructure fault were discarded, not counted.
- **M1 (mechanisms live):** growth provisioning, spacing (full SRS curve), warm-start (exact spec formulas, measurable head-start), prerequisite-gap diagnosis (correctly naming the weak *root* skill), and both revisit triggers — all confirmed operating end-to-end live. Wiring validation at small n, deliberately not reported as powered margins.
- **Process result:** a pre-spend adversarial review caught two defects that would have silently nulled two components — fixed before the live runs. The review-before-spend discipline is part of the method.

**Next protocol runs:** a representative coding + held-out-pytest corpus (the generality test), powered M1 hypotheses, then M2 (the weight/fine-tuning axis) and M3 (self-modification, fleets) — both gate-approved as designs.

The reference implementation lives in a separate research build maintained by the project owner; this repository is the home of the research — spec, specs, paper, protocol, and audit trail.

## Built on Turing Agents

The working substrate of this repo is **Turing Agents** — a self-evolving Claude agent scaffold (Claude Cowork + Claude Code) that grows the agents, skills, and memory the project needs from real work. It reviewed this project's own specs: the two-stage approval gate above is run by agents the framework evolved for the purpose. Start with [`CLAUDE.md`](CLAUDE.md) for the operating loop, and [`EVOLUTION-LOG.md`](EVOLUTION-LOG.md) for what the framework has learned. The framework is MIT-licensed and generalized from Turing's own proven in-production setup and the managed-agents model of [Multica AI](https://github.com/multica-ai/multica).

## Repository layout

```
docs/research/                the research corpus (spec · build-specs · paper · reviews · handover)
docs/RELEASE-PLAN-v2.md       the v2 release plan (tiers, gates, cut line)
docs/index.html               the project site (GitHub Pages)
CLAUDE.md                     the agent operating loop + protocols
.claude/agents|memory/        the self-evolving agent squad + its memory
tasks/BOARD.md                the team kanban board
scripts/                      framework tooling (capture · orient · evolve · task · …)
EVOLUTION-LOG.md              plain-language digest of what the framework learned
```

## License

MIT — see [LICENSE](LICENSE).
