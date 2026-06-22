# Project profile

_Status: **PROFILED (lightweight, in-session)**. Seeded 2026-06-22 from the first real design conversations. A deep `scout` pass can still enrich this; treat as the working profile until then._

## What this project is
- An **open-source algorithm + Python libraries** that generalize a probabilistic, multi-dimensional **learning-pathway framework** from human students to **self-learning agents**.
- Concept origin: the attached paper *"A Multi-Dimensional Learning Pathway Inference and Evolution Framework Using Hybrid Data Architecture and Probabilistic State Modeling."*
- Near-term goal: a **generic, Python-first "self-learning agents" layer** improving agents along two axes — **memory/context-level** (skills/lessons/memory, weights frozen) and **weight-level** (fine-tuning / RL) — intended to sit **on top of Multica** (github.com/multica-ai/multica), with layer-vs-replace still an open question.

## Tech stack
- **Python-first** for the algorithm/library and ML (HF Transformers, PEFT, TRL, vLLM expected).
- Data substrate from the paper: SQL (truth), MongoDB (inferred states), Vector DB (embeddings), GraphDB (pathways), Redis (real-time context).
- Hosting framework in this repo (Turing Agents) is Markdown + Bash.

## Layout
- This repo = Turing Agents v0.2.0 self-evolving framework (the working memory-level substrate).
- `RESEARCH-HANDOVER.md` (root) = the Claude Code research brief for the self-learning layer.

## Conventions in use
- Reframe rule: the paper's "learner" = an **agent**; one shared decision **core + eval signal**, but **two controllers** (memory vs weight axis) — not one controller for both.
- **Corrected decision objective (verified):** the paper's literal `A* = argmax P(success | S, A)` is degenerate for a curriculum (picks the already-mastered action → no learning). Use `A* = argmax E[Δ competence | S, A]` (learning-progress / regret, per Teacher–Student Curriculum Learning). `P(success)` is retained only as the measurement primitive.
- Memory-level learning maps onto Turing Agents' `reflect -> evolve` loop (= the paper's "pathway evolution loop"); its missing piece vs SOTA (Voyager/DSPy) is a **metric-gated "keep iff it helps" validation** step.
- "Small teacher for bigger student" only works for pedagogical/verification/routing signal, not backward knowledge distillation.
- **Multica license correction (verified 2026-06-22):** it is a **modified Apache-2.0 with commercial-use restrictions (GitHub "NOASSERTION")**, NOT MIT and NOT plain Apache-2.0 — corrects both RESEARCH-HANDOVER.md and `docs/evolution/multica-study-2026-06-22.md`. Real but young (created 2026-01-13, v0.3.x, ~37.5k★).

## Goals / what success looks like
- A reusable `LearnerAdapter`-based core (`HumanLearnerAdapter`, `AgentLearnerAdapter`) so one algorithm serves both education and agent use-cases.
- A go/no-go + reference architecture for the generic self-learning layer (pending the research brief).

## Open questions for the user
- ~~Layer vs replace vs hybrid~~ **RESOLVED by the report (`docs/research/REPORT-self-learning-agents.md`, §6): HYBRID — build a control-plane-agnostic Python learning core that owns its own state and treats Multica as one swappable `ControlPlaneAdapter`. Don't replace, don't deeply fork.**
- **Pilot domain + its verifier** (drives everything; recommend tool/function-calling where schema+execution give a cheap reliable verifier) — still the user's to choose.
- Compute budget envelope for the weight-level path (memory axis ≈ free; weight SFT ≈ $-tens, RL ≈ $100s–1000s).
- Open-source vs commercial product (decides how much Multica's commercial-restricted license binds).

## Research deliverables (`docs/research/`, 2026-06-22)
- `REPORT-self-learning-agents.md` — go/no-go report executing RESEARCH-HANDOVER.md. Verdict: **GO** — memory axis (low risk, ship first), weight axis (**conditional** on verifier availability), unified core with the corrected objective. All prior-art claims primary-source verified via 5 subagents.
- `ALGORITHM-v0.1-pathway-learner.md` — first algorithm (MCTS over a growing competence graph; the three meta-functions). **Superseded.**
- `ALGORITHM-v0.1-redteam.md` — 3-adversary pressure-test; ~40 findings → 8 root causes; found 3 independent pilot-killers.
- `ALGORITHM-v0.2-pathway-learner.md` — **current** hardened spec. Two principles: *measurement independent of optimization*; *every add has an inverse*. Re-scoped 0/1/2 pilot (milestone 0 = growth OFF + held-out eval to prove true competence moves).
- `PAPER-method-section.md` — academic Method (replaces original paper §§2–8) built on v0.2; learner-agnostic + agent instantiation; formal equations; corrected objective; preserves original engine names.
- `PAPER.md` — **full assembled paper draft**: Abstract, Intro, Related Work (6 themes, verified cites), integrated Method, design-only **pre-registered Evaluation protocol** (baselines/ablations/metrics/go-no-go), Discussion, Limitations, Conclusion, References. Honest framing: framework + protocol, **no results**; drops the original's unmethodized figures.
- Implementation lives in the turing-agents repo: `docs/mdlp/IMPLEMENTATION.md` + board tasks T-001..T-012 (opt-in Layer 3, pytest verifier, M0→M2).
- Lineage: concept paper → v0.1 → red-team → v0.2 → method section. Architecture never changed; the mechanisms (estimators, gates, provisioning) did.
