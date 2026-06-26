# Next steps — backlog distilled from the brainstorm (2026-06-26)

Tracked threads from the "5-store for learning pathways" brainstorm and the bias-free-action / Tutor-layer discussion. The **full map** of every learning → integration point is [`ALGORITHM-INTEGRATIONS.md`](ALGORITHM-INTEGRATIONS.md); this file is the prioritized do-next subset. Status: **▶ done · ◐ in progress · ○ open**.

## A · Core algorithm refinements (small, high-leverage)
- ▶ **A0 — Tutor layer integrated into v0.2** (`ALGORITHM-v0.2-pathway-learner.md` §13): generic embedded Tutor + pluggable Teachers (selected by held-out gain) + `LearnerAdapter`.
- ◐ **A1 — Info-gain mode (§13.1) deepened.** The expected-information-gain math (`argmax E[ΔH]`) + how *advance* vs *diagnose* blend by uncertainty. The bias-free principle made rigorous. *(Seeded in §13.1; full treatment open.)*
- ○ **A2 — `LearnerAdapter` spec.** Concrete `HumanLearnerAdapter` (behavioural signals → posterior) vs `AgentLearnerAdapter`.
- ▶ **A3 — Calibration layer integrated into v0.2** (§14): per-band ECE/Brier monitor + isotonic point-recalibration + `n_eff` deflation (the mirror of the `n_min` floor) → honest SE that every existing gate inherits for free; miscalibration as a 5th breaker trigger.
- ▶ **A4 — Re-visiting / surprise loop integrated into v0.2** (§15): `revisit(D)` as a first-class action; insight = prediction error; info-gain trigger + surprise-decay/budget stop; within-episode MCTS (deterministic domains); negative-evidence-as-gain; generative path storage. Bundles the learning-loop + *Source Code* learnings.

## B · New capability designs (the high-impact scenarios — design only)
- ○ **B1 — Misconception clustering → graph-linked remediation** (vector + graph + state). *Highest differentiation — name the bug, not just "wrong."* Gated on C1.
- ○ **B2 — Prerequisite-gap diagnosis** (backward graph walk + posterior → the real gap).
- ○ **B3 — Cross-agent skill transfer / fleet learning** (agent-side high-impact).
- ○ **B4 — "Learners like you" collaborative pathways** (vector over competence trajectories + graph + truth).

## C · The gating hard problem
- ◐ **C1 — The human-learning verifier.** Design (`HUMAN-LEARNING-VERIFIER.md`) + the pre-registered go/no-go experiment (`HUMAN-LEARNING-M0-PROTOCOL.md`): IRT-3PL + behavioural-signal likelihood → the dual posterior; H1–H5, decision rule, MVP (~30 learners, one sub-skill). Gates **all** of B1/B2/B4. *Remaining (owner-supplied): a domain + a learner cohort to run it.*

## D · Strategy
- ○ **D1 — The flagship decision (owner's call):** human-ed app vs deepen the agent engine vs the unified "every learner is a learner" platform.
- ○ **D2 — Positioning note** vs Self-Evolving Curriculum + Bayesian active learning / optimal experiment design (the formal lineage of the info-gain Tutor).

## Recommended sequence
1. **C1** (human-learning verifier) — go/no-go for the whole human-ed direction; same discipline as the agent side (solve the signal before building on it). *(started)*
2. **B1** (misconception clustering) — highest-impact app, **iff** C1 says the signal exists.
3. **A1** (info-gain mode) — small; sharpens the bias-free principle.
4. **D1** — owner's strategic call; reshapes everything downstream.

*Cross-refs:* design — `ALGORITHM-v0.2-pathway-learner.md` (§13 Tutor layer); landscape/gaps — `LANDSCAPE-self-learning-agents.md` (§7); the agent-side proof gate — `IMPROVEMENT-NOTE-turing-agents.md` (P0).
