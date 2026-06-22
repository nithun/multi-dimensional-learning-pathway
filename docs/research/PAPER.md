# Multi-Dimensional Learning Pathways for Self-Improving Agents: A Probabilistic, Verifier-Grounded Framework with an Open Pathway Graph

*Full draft. Authors: TBD. Status: framework + pre-registered evaluation protocol — no empirical results are claimed here; empirical validation follows the protocol in §5 and the staged build in the companion implementation guide. This draft supersedes an earlier conceptual version whose headline figures were not reproducibly methodized; we replace anecdotal evaluation with a pre-registered design.*

*Companion artifacts: detailed algorithm spec (`ALGORITHM-v0.2-pathway-learner.md`), adversarial analysis (`ALGORITHM-v0.1-redteam.md`), feasibility/positioning report (`REPORT-self-learning-agents.md`), implementation guide (`turing-agents/docs/mdlp/IMPLEMENTATION.md`).*

---

## Abstract

Personalized-learning and self-improving-agent systems both face the same control problem: from a learner's current state, which next learning action most improves it? Prior personalized-learning systems answer this deterministically and greedily; prior managed-agent platforms orchestrate agents but do not learn at all. We present a probabilistic, **verifier-grounded**, **open-ended** framework for inferring and evolving multi-dimensional learning pathways. A learner — a human student or a software agent — is modeled as a posterior over a growing competence field; learning is a traversal of an open graph of competence states; and each next action is selected to maximize **expected learning gain** under a measured success signal, not immediate success probability. Two principles govern the design: *measurement independence* (every quantity that drives a decision is estimated on data the learner's optimization never touched) and *reversible openness* (the schema grows with data, but every growth operation has an inverse). For agents, the framework instantiates two learning axes — a memory/context axis and a parameter (fine-tuning) axis — that share one state model and one evaluation signal and form a producer/consumer pair. We give a complete method, derive it from and position it against knowledge tracing, automatic curriculum learning, agent fine-tuning, and self-improvement work, and contribute a **pre-registered evaluation protocol** (baselines, component ablations, metric definitions, and per-milestone go/no-go criteria) designed to test each claim — including adversarial probes for the failure modes the design is built to resist. We make explicit the framework's binding precondition: it is valid only where a reliable verifier exists for the skills admitted to autonomous learning.

---

## 1. Introduction

Adaptive learning systems aim to choose, for each learner, the next activity that best advances them. The same problem reappears, almost verbatim, in self-improving software agents: given an agent's current competence, which skill, lesson, or fine-tuning step should it acquire next? Yet the two literatures answer it from opposite deficiencies. Personalized-learning systems model the learner with deterministic state assignments and select the next action greedily by predicted success; managed-agent platforms (e.g., orchestration control planes) manage agents as teammates but ship **no learning loop** at all.

This paper unifies the two under one framework and corrects four deficiencies of the deterministic-greedy formulation:

1. **A real probabilistic model.** We replace an unspecified state distribution with a posterior over a multi-dimensional competence field, estimated by a concrete, decay-aware update (§3.2), grounded in knowledge tracing and item response theory and extended to an *open, growing* set of skills.
2. **A corrected objective.** We show that selecting the action of highest immediate success is *degenerate for learning* — it selects the already-mastered action — and replace it with an objective on **expected learning gain** (§3.6), the formal stance of teacher–student curriculum learning.
3. **A measured reward.** The success probability that drives every decision is *measured* by an evaluation engine with explicit, gameable-resistant verifiers (§3.5), not assumed. We make the framework's precondition explicit: it is valid only where a reliable verifier exists.
4. **An open, self-provisioning schema.** The state space, dimensions, and graph grow with data; every growth operation is paired with an inverse, and no skill enters the live system until it can be scored (§3.4).

Two principles run through every component. **Measurement independence (P1):** decisions are gated on held-out data, counterfactual credit, audit-anchored verifier reliability, and cumulative baselines, so a learner cannot move a metric without moving the latent quantity the metric estimates. **Reversible openness (P2):** the schema is held open at the object level (skills, dimensions, edges grow) while three meta-functions are committed — a growth rule, a soft reachability/affinity function, and a frontier policy — and every additive operation has an inverse.

The framework is learner-agnostic but sharpest where competence is *directly measurable*, as for agents evaluated against task suites. For agents it instantiates two learning axes (memory and parameters) that share one state model, one evaluation signal, and one decision objective.

**Contributions.** (i) A probabilistic, verifier-grounded, open-ended pathway framework that unifies human-learner and agent settings (§3); (ii) the two design principles and the corrected learning-gain objective, with a proof sketch that the greedy objective is degenerate; (iii) a two-axis agent instantiation with a measurement-independent promotion procedure; (iv) a pre-registered evaluation protocol with baselines, component ablations, metric definitions, and adversarial failure-mode probes (§5); and (v) an honest demarcation of where the framework is tractable and where it is not. We claim no empirical results; we contribute the framework and the protocol to test it.

---

## 2. Related Work

**Learner-state modeling and knowledge tracing.** Modeling a learner's latent competence has a long lineage: item response theory (IRT) models the probability of a correct response as a function of learner ability and item difficulty (Lord, 1980; Rasch, 1960); Bayesian Knowledge Tracing (BKT) tracks per-skill mastery as a hidden Markov state with learn/forget/guess/slip parameters (Corbett & Anderson, 1995); and Deep Knowledge Tracing (DKT) fits the same task with recurrent networks (Piech et al., 2015). The original conceptual version of this framework posited a "probabilistic state" without committing to any such model; we ground the state in a Beta–Bernoulli (optionally IRT) posterior (§3.2) and extend it in two ways the tracing literature does not: a **dual slow/fast posterior** to separate mastery from drift, and an **open, nonparametric** skill set that grows with data.

**Automatic curriculum and teacher–student learning.** Our decision engine is, formally, a curriculum controller. Automatic curriculum learning shapes the training-task distribution to maximize a learning signal (Portelas et al., 2020); Teacher–Student Curriculum Learning selects the next task to maximize the student's *learning progress* — the slope of its learning curve (Matiisen et al., 2017) — which is precisely the objective we adopt in place of greedy success-maximization. Regret-based unsupervised environment design (PAIRED; Dennis et al., 2020), open-ended environment/agent co-evolution (POET; Wang et al., 2019), and curriculum-by-replay (Prioritized Level Replay; Jiang et al., 2021) generalize the controller to *generating* and *scheduling* tasks. We import the learning-progress objective and the open-ended stance, and contribute the missing pieces for a measured, verifier-gated setting: soft probabilistic reachability and a coverage floor.

**Memory-level learning for agents (weights frozen).** A growing body of work improves agents without changing weights. Voyager maintains an ever-growing library of executable skills, retrieved by embedding (Wang et al., 2023a); Reflexion stores verbal self-reflections in episodic memory (Shinn et al., 2023); Generative Agents introduce a recency–importance–relevance memory stream (Park et al., 2023); MemGPT/Letta manage tiered virtual context (Packer et al., 2023); DSPy compiles and optimizes LM programs against a metric (Khattab et al., 2023); TextGrad backpropagates textual "gradients" (Yuksekgonul et al., 2024); APE, OPRO, and PromptBreeder optimize prompts as programs (Zhou et al., 2022; Yang et al., 2023; Fernando et al., 2023); and Agent Workflow Memory induces reusable workflows from experience (Wang et al., 2024). These instantiate a common loop — propose, validate, store, retrieve, retire — but their validation gate ranges from execution checks to held-out metrics. Our memory axis (§3.8) is this loop with a uniformly **metric-gated, held-out** validation and counterfactual retrieval credit; it subsumes the skill-library and reflection variants as the validate gate's choice.

**Agent fine-tuning and small models as agents.** Small (≈1–8B) models can be fine-tuned into competent narrow tool-using agents: FireAct (Chen et al., 2023), AgentTuning/AgentLM (Zeng et al., 2023), Lumos (Yin et al., 2023), ToolLLM (Qin et al., 2023), Gorilla (Patil et al., 2023), Toolformer (Schick et al., 2023), and xLAM/APIGen (Liu et al., 2024) report matching or exceeding frontier models *on the scoped skill* — e.g., a 7B action model surpassing GPT-4-class systems on the Berkeley Function-Calling Leaderboard (Liu et al., 2024) — while not matching frontier general reasoning. The dominant data recipe is distillation plus **rejection sampling** on verified-successful trajectories (Zelikman et al., 2022; Yuan et al., 2023), scaled by execution-verified synthesis (Liu et al., 2024). Our parameter axis (§3.8) consumes exactly the verified trajectories the memory axis produces, and promotes behaviors only through a measurement-independent, two-stage reversible procedure.

**Reward signals and self-improvement.** Self-improvement loops are bounded by their verifier. Where a reliable automatic check exists — code execution, math answer-checking, step-level process reward (Lightman et al., 2023) — bootstrapping compounds (STaR; Zelikman et al., 2022). Where the only signal is a model's own judgment, loops saturate and are gamed: self-rewarding improves then plateaus (Yuan et al., 2024a) and required a meta-judge to continue (Wu et al., 2024); RL-from-AI-feedback matches human feedback in some settings (Lee et al., 2023); and reward-model overoptimization is a general law — optimizing a proxy too hard diverges from true reward, and larger reward models do not remove it (Gao et al., 2022). This literature motivates our central precondition (§3.5) and the anti-Goodhart mechanisms (held-out reward, trajectory-shape and counterfactual verification, audit-anchored reliability).

**Self-evolving agents and managed-agent platforms.** Meta-agents that design agents (ADAS; Hu et al., 2024) and surveys of self-evolving agents (e.g., Fang et al., 2025) establish the mechanisms but as research artifacts, not platforms. Conversely, managed-agent control planes orchestrate agents as teammates without a persistent learning loop. The white space — a generic learning loop, spanning both memory and parameter improvement and sharing one evaluation signal, attached to a live agent fleet — is, to our knowledge, unoccupied; this framework targets it.

---

## 3. Method

The method is summarized here; full pseudocode and store-level detail are in the companion algorithm spec. We model an adaptive learner as a probabilistic process traversing an open graph of competence states, selecting each next learning action to maximize expected learning gain under a measured success signal. We develop it learner-agnostically and mark the **agent instantiation** where it specializes. The original engine names — Validation, Inference, Decision, Evolution — are preserved and mapped to the formal components.

### 3.1 Design principles

> **P1 (measurement independence).** Every quantity that drives a decision is estimated on data the learner's optimization never touched: held-out evaluation items, counterfactual credit, audit-anchored verifier reliability, cumulative baselines.
>
> **P2 (reversible openness).** The state set, graph, and parameters grow with data, but every growth operation is paired with an inverse, and gates compare to a fixed baseline, not only the previous step.

### 3.2 Probabilistic learner state (Inference Engine, I)

Let $\mathcal{S}_t$ be the growing set of skills and $d\in\mathcal{D}$ difficulty levels. For each cell $(s,d)$, competence $c_{s,d}\in[0,1]$ is the success probability on an item of skill $s$ at difficulty $d$; the learner state $S_t$ is the joint posterior over $\mathbf{c}=\{c_{s,d}\}$. We maintain a Beta posterior per cell with point estimate $\hat c=\alpha/(\alpha+\beta)$ and uncertainty $u=\mathrm{Var}[c]$, updated from evaluation outcomes with a forgetting/drift decay $\gamma$:
$$\alpha\leftarrow\mathrm{floor}(\gamma\alpha)+k^{+},\qquad \beta\leftarrow\mathrm{floor}(\gamma\beta)+k^{-},\tag{1}$$
where $\mathrm{floor}(\cdot)$ enforces a minimum effective sample size $n_{\min}$ so a single evaluation cannot move $\hat c$ by more than the regression tolerance $\varepsilon$. Because a single decay constant is over-determined (it would set retention, exploration, and rollback sensitivity at once), we keep **two posteriors per cell**: a slow-decay **mastery** posterior (drives selection, exploration floor, promotion) and a fast-decay **drift** posterior (drives rollback only), each with per-skill decay. Cold-start cells are born $\mathrm{Beta}(\alpha_0,\beta_0)$, never undefined. Competence dimensions are **not** assumed independent — dependencies are carried by the prerequisite graph (§3.3) and an optional hierarchical prior. A 2-PL IRT model is a drop-in upgrade behind the same interface.

*Agent instantiation.* $\hat c$ is obtained by executing held-out evaluation items; the inference problem reduces from latent-trait estimation to sampling-error control. Checkpointing makes each state a restorable node, enabling counterfactual evaluation impossible for human learners.

### 3.3 The open pathway graph (Inference Engine, II)

Trajectories live on a directed graph whose nodes are skills/competence states and whose edges are prerequisite and transition relations. We replace a hard prerequisite conjunction with **soft, probabilistic reachability**,
$$\rho(s\mid S_t)=\prod_{p\in\mathrm{pre}(s)}\Pr(c^{m}_p\ge\theta),\tag{2}$$
which enters the decision objective as a multiplier, so one mis-estimated prerequisite *dampens* but never *deletes* a skill from the frontier. The structure is compositional: as more skills are mastered, $\rho$ opens *more* successors — the reachable frontier widens with accumulated competence.

### 3.4 An open, self-provisioning schema (the growth rule)

The schema is nonparametric. A growth operator $g$ spawns a new skill when a cluster of failed trajectories is sufficiently dissimilar from every existing skill (a Chinese-Restaurant-Process "new table" with a region-adaptive threshold). By **P2**, $g$ also **merges** near-duplicate skills, **prunes** orphans, and **decays** prerequisite-edge confidence unless renewed by intervention-like evidence. Crucially, scorability is an **invariant of graph membership**: on creation $g$ must provision an evaluation suite and an admitted verifier — by inheriting the nearest admitted parent's, or synthesizing items from the failure cluster gated by an existing reliable verifier; otherwise the skill is quarantined and excluded from reachability, retrieval, and clustering. This is the precise sense in which the framework is open at the object level (the schema) but committed at the meta level (the rules $g$, $\rho$, and $\pi$).

### 3.5 The evaluation engine: success, measured (Validation Engine)

The decision rule depends on a measured $P(\text{success}\mid S,A)$. For a learner in state $n$ and skill $s$, success is measured by a **verifier** $v$ on evaluation items. Verifiers form a registry ordered by reliability (execution/tests $\succ$ schema validation $\succ$ simulated task success $\succ$ model-as-judge). By **P1**, each skill's items split into a **public** set (visible to act-time context) and a **held-out** set (the only split that drives rewards, gates, and calibration); a commit or promotion additionally requires a generalization condition
$$\Delta\hat c_{\text{held-out}}\ge\rho_{\text{gen}}\cdot\Delta\hat c_{\text{public}},\tag{3}$$
rejecting improvement on memorized public items without held-out gain. Two hardenings make "a verifier exists" mean "the loop is safe": verifiers assert on **trajectory shape** (intended tools/arguments derived from the query, not hard-coded) and on **counterfactual variants**; and verifier reliability is *defined* as precision/recall against a human audit set the verifier never trains on, estimated per difficulty band with a confidence interval. A skill is **admitted** to autonomous learning only if a covering verifier clears the bar on its lower confidence bound. This makes explicit the framework's precondition: it is valid only where a reliable verifier exists; where the only signal is subjective judgment, those skills are held out of autonomous learning.

### 3.6 The decision engine, corrected (Decision Engine)

The greedy objective $A^{\*}=\arg\max_A P(\text{success}\mid S,A)$ is **degenerate for learning**: the highest-success action is the already-mastered one, with $\mathbb{E}[\Delta c]\approx0$ — maximizing immediate success minimizes learning. We replace it with expected learning gain,
$$A^{\*}=\arg\max_A\mathbb{E}\big[\Delta U(S)\mid S,A\big],\qquad U(S)=\sum_{s,d}\hat c_{s,d},\tag{4}$$
equivalently the learning-progress slope or regret to a reference. Selection normalizes incommensurable terms,
$$\pi(S)=\arg\max_{A\in\mathcal{A}}\Big[z\big(\tilde Q(S,A)\big)+\lambda\,z\big(\mathrm{infogain}_{\text{reach}}(A)\big)\Big]\ \text{s.t. } \text{cost}(A)\le\text{budget},\tag{5}$$
where $\tilde Q$ is a Thompson-sampled estimate of $\mathbb{E}[\Delta U\mid S,A]$ (posterior sampling supplies exploration), $z(\cdot)$ is a candidate-set z-score, $\mathrm{infogain}_{\text{reach}}$ rewards actions that unlock unreachable regions, and cost is a hard budget constraint. The learning-gain term enters (5) only when **statistically significant** ($\Delta U>z\cdot\mathrm{SE}$ on paired held-out items); a **coverage floor** guarantees every admitted skill is practiced at rate $\ge f_{\min}$, so the curriculum cannot abandon hard skills.

### 3.7 The evolution loop (Pathway Evolution)

After an action $A$ from $S_t$ yields a held-out outcome $r$, the framework updates competence (both posteriors via (1)), transition probabilities (visit count + recency-discounted value), and search values (backed up with a discounted/sliding-window estimator so superseded-policy returns age out). The transition is **accepted** only under a composite gate embodying **P1/P2**:
$$\underbrace{\Delta\hat c_{\text{held-out}}>\varepsilon+z\,\mathrm{SE}}_{\text{real}}\ \wedge\ \underbrace{\hat c_{\text{held-out}}\ge\hat c_{\text{baseline}}-\varepsilon_{\text{cum}}}_{\text{no cumulative drift}}\ \wedge\ (3)\ \wedge\ \underbrace{\text{safe}}_{\text{held-out safety}}\ \wedge\ \text{affordable},\tag{6}$$
otherwise the learner rolls back. The cumulative term (vs. a fixed ancestor, not the previous step) defeats sub-tolerance slow drift; rollback is rate-limited and retains no fine-grained information from safety-failed branches. On any change of the underlying model, estimates and search values keyed to the old model are invalidated and re-anchored.

### 3.8 Agent instantiation: two axes and promotion

For an agent, the action set spans a **memory axis** (propose a skill, record a lesson, optimize a prompt; weights frozen — cheap, reversible) and a **parameter axis** (curate verified trajectories, take a fine-tuning step — costly, durable), sharing the state model, evaluation signal, and objective. They form a **producer/consumer pair**: the memory axis's verified successful trajectories are the rejection-sampled training data the parameter axis consumes. A behavior is **promoted** by a two-stage, mostly-reversible procedure: a scored promotion index (frequency, held-out-measured behavioral stability, context pressure, data sufficiency, held-out-proven reliability) gates training of a *detachable adapter*; only after sustained held-out performance, a human spot-check of the kept trajectories, and a no-regression check over an explicit monitored set does the adapter merge into base parameters. A cheap pre-training interference estimate skips promotions likely to regress others before the training cost is paid.

### 3.9 System architecture: the act/learn split

The store roles follow a separation of timescales. The learner must **act** in milliseconds (read competence, find reachable actions, retrieve context) and **learn** over seconds to hours. A hot **act path** (an in-memory cache of the materialized frontier and state vector, a graph read-model, a vector index) is separated from a cold **learn path** (a relational store of record with full lineage, an object store and model registry, a schemaless document store for the growing competence field). The relational store is the single source of truth; hot read-models are disposable projections rebuilt from it, which is what makes aggressive caching safe and the learning layer an optional, rebuildable add-on.

---

## 4. The principles as the conceptual core

Most of the framework's safeguards reduce to **P1**: phantom-progress ratchets, suite memorization, weak-skill calcification, and slow safety drift are all instances of a learner optimizing its own scoreboard, cured by estimating each decision quantity on data the learner never touched. Most of its structural soundness reduces to **P2**: an open schema with no inverse operations and hard gates ratchets toward an ever-more-constrained, ever-more-wrong state, cured by pairing every add (skill, edge, tree node) with a merge/prune/decay/GC and by comparing gates to fixed baselines. These two principles, rather than any single mechanism, are the transferable contribution; the specific estimators and gates are their instantiation.

---

## 5. Evaluation protocol (pre-registered; design only)

We present the protocol that will test the framework. No results are reported; success criteria and analyses are fixed in advance to prevent the measurement-dependence (P1) the framework itself warns against. The protocol is staged to the implementation milestones (M0→M2).

### 5.1 Research questions and hypotheses

- **H1 (the framework learns).** Held-out competence rises significantly above a no-learning baseline.
- **H2 (the objective matters).** The learning-gain objective (4) yields faster held-out competence growth than the greedy $\arg\max P(\text{success})$ objective.
- **H3 (each principle/component contributes).** Removing any one mechanism (held-out reward, counterfactual credit, soft reachability, dual decay, coverage floor, growth provisioning, two-stage promotion) degrades a targeted metric and/or reactivates a named failure mode.
- **H4 (the axes compose).** Promoting stable memory skills to parameters improves competence-per-unit-cost over memory-only at fixed budget.
- **H5 (the schema grows usefully).** With growth on, the live skill set expands while remaining fully scorable, with bounded orphan and duplicate rates.
- **H6 (safety holds).** No monitored skill regresses beyond tolerance across a long run; adversarial probes are caught.

### 5.2 Domains and data

Primary domain: **code generation verified by execution** (the agent produces a patch; held-out unit tests score it), chosen because it has a cheap, reliable verifier — the framework's precondition. A task corpus of self-contained, locally runnable items spanning a fixed set of skills, each with a **public** and a **held-out** test split and a calibrated difficulty. Difficulty is calibrated from fleet-wide pass rates (IRT $b$-parameter) on a held-out cohort that the learner never trains on. Cross-domain generalization (e.g., tool/function-calling, structured extraction) is named as future work, not claimed.

### 5.3 Baselines

| Baseline | Tests |
|---|---|
| **No-learning (frozen)** | H1 — the floor |
| **Greedy objective** $\arg\max P(\text{success})$ | H2 — the corrected vs. original decision rule |
| **Random curriculum** | the value of *any* informed selection |
| **Fixed/hand-authored curriculum** | the value of *learned* over *authored* ordering |
| **Memory-only** and **parameter-only** | H4 — the contribution of each axis and their composition |
| **Strong static RAG/prompting** (retrieval, no learning loop) | the value of the loop over retrieval alone |
| **Published comparators on the shared domain** (e.g., a skill-library agent; a rejection-sampling fine-tune) | external calibration where the domain overlaps |

### 5.4 Ablations (each maps to a principle and a guarded failure mode)

| Ablation | Principle | Failure it should reactivate |
|---|---|---|
| Reward on public (not held-out) split | P1 | suite memorization / Goodhart |
| Point-estimate gates (drop `significant()`) | P1 | phantom-progress commit ratchet |
| Shared-delta retrieval credit | P1 | spurious-correlate lock-in |
| Single global decay $\gamma$ | — | decay/rollback oscillation; blocked promotion |
| Hard reachability (AND of prereqs) | P2 | frontier starvation |
| No growth provisioning | P2 | unscorable dead nodes |
| No merge/prune/edge-decay | P2 | orphan sprawl; wrong-way prereq ratchet |
| No coverage floor | — | weak-skill calcification |
| One-stage (irreversible) promotion | P1 | overfit baked into weights |

### 5.5 Metrics (definitions)

- **Held-out competence** (primary): mean $\hat c$ over held-out items per skill×difficulty, over training time. Reported on **held-out only**; public is reported separately for the generalization gap.
- **Generalization gap:** $\hat c_{\text{public}}-\hat c_{\text{held-out}}$ (a memorization detector).
- **Learning efficiency:** $\Delta$ held-out competence per episode and per unit cost (\$).
- **Sample efficiency:** episodes to reach a fixed competence threshold.
- **Regression/forgetting rate:** fraction of committed steps that later require rollback; max monitored-skill drop from its peak.
- **Schema health:** % of live nodes that are scorable (target 100%), orphan rate, duplicate rate, growth rate vs. mastery rate.
- **Promotion precision/recall:** fraction of promotions that improve held-out competence without monitored regression.
- **Verifier reliability:** precision/recall of each verifier vs. the human audit set, per band.
- **Safety incidents:** count of monitored regressions and caught adversarial probes (memorization, hard-coded-constant, fence-probing).
- **Reproducibility:** variance of all primary metrics across $\ge k$ seeds.

### 5.6 Statistical methodology

All competence deltas use **paired held-out** items (shared before/after items) to cancel item variance; significance is a test against the delta's standard error at $z$; every comparison reports confidence intervals over $\ge k$ seeds. The hypotheses, baselines, ablations, metrics, and success thresholds in this section are **fixed before any run** (pre-registration), and primary results are read only from held-out splits.

### 5.7 Per-milestone go/no-go

- **M0 (memory axis, growth off):** H1 must hold — held-out competence beats no-learning beyond $z\cdot\mathrm{SE}$, and the memorization/hard-coding probes fail as designed — *before* any further build. H2 measured here.
- **M1 (open schema):** H5 must hold — schema grows, all live nodes scorable, bounded orphan/duplicate/oscillation — and an adversarial re-test of the implementation precedes it.
- **M2 (parameter axis):** H4 and H6 — a promotion improves held-out competence without monitored regression, under the two-stage reversible procedure.

### 5.8 Threats to validity

Verifier incompleteness (mitigated by trajectory-shape and counterfactual checks, but not eliminated); single-domain results (code) may not transfer (named as future work); the train/deploy gap (eval-suite competence ≠ in-the-wild safety; partly mitigated by sampling real trajectories into the held-out suite); and compute limits on the parameter axis. We report negative and null results; failure of H1 at M0 is a publishable outcome that bounds where the approach applies.

---

## 6. Discussion

**Where it is tractable, and where it is not.** The framework compounds exactly where a cheap, reliable verifier exists — code execution, formal/schema validation, simulated task success — and is, by its own admission gate, inapplicable to skills whose only signal is subjective judgment, where the self-improvement literature shows loops saturate and are gamed. We treat this not as a limitation to hide but as the design's central precondition.

**Positioning.** Personalized-learning systems supply the pathway intuition but model it deterministically; curriculum learning supplies the corrected objective but assumes a simulator reward; memory- and parameter-level agent-learning supply the mechanisms but as isolated research artifacts; and managed-agent platforms supply the substrate but no learning loop. The contribution is their unification under one measured signal and one open pathway graph, with the two principles as the load-bearing idea.

**Layer vs. replace.** As an engineering matter, the framework is best realized as an *optional, derived* learning layer over an existing managed-agent control plane — owning its own learning state while treating the control plane as a swappable execution backend — rather than as a replacement, because the learning loop needs control over evaluation and model deployment that an orchestration plane need not cede, while the canonical record can remain the plane's own logs.

---

## 7. Limitations

This is a framework and protocol, not an empirically validated system: we report no results. The design has been adversarially analyzed but not adversarially *re-*validated after hardening; several components (counterfactual credit assignment, trajectory-shape verification, pre-training interference prediction) are themselves open problems. The primary domain is narrow by construction (it is chosen for verifier reliability), and the parameter axis requires non-trivial compute. The framework offers no path for skills lacking a reliable verifier.

---

## 8. Conclusion and future work

We have presented a probabilistic, verifier-grounded, open-ended framework for inferring and evolving multi-dimensional learning pathways, unifying human-learner and self-improving-agent settings, correcting the deterministic-greedy formulation along four axes, and organizing every safeguard under two principles — measurement independence and reversible openness. We contribute a pre-registered evaluation protocol designed to test each claim, including adversarial probes for the failure modes the design resists. Immediate future work is the staged empirical validation (M0→M2) on the code-execution domain, beginning with the H1 go/no-go; subsequent work extends to additional verifier-bearing domains, studies the promotion economics between axes at scale, and investigates curricula for skills at the boundary of reliable verification.

---

## References

*(Primary sources; arXiv identifiers given where applicable. Classic knowledge-tracing references are foundational and should be confirmed to house style at submission.)*

- Bai, Y., et al. (2022). Constitutional AI: Harmlessness from AI Feedback. arXiv:2212.08073.
- Chen, B., et al. (2023). FireAct: Toward Language Agent Fine-tuning. arXiv:2310.05915.
- Corbett, A. T., & Anderson, J. R. (1995). Knowledge Tracing: Modeling the Acquisition of Procedural Knowledge. *User Modeling and User-Adapted Interaction*.
- Dennis, M., et al. (2020). Emergent Complexity and Zero-shot Transfer via Unsupervised Environment Design (PAIRED). arXiv:2012.02096.
- Fang, (et al.) (2025). A Survey of Self-Evolving Agents. arXiv:2507.21046.
- Fernando, C., et al. (2023). Promptbreeder: Self-Referential Self-Improvement via Prompt Evolution. arXiv:2309.16797.
- Gao, L., Schulman, J., & Hilton, J. (2022). Scaling Laws for Reward Model Overoptimization. arXiv:2210.10760.
- Hu, S., Lu, C., & Clune, J. (2024). Automated Design of Agentic Systems (ADAS). arXiv:2408.08435.
- Jiang, M., et al. (2021). Prioritized Level Replay. arXiv:2010.03934; Replay-Guided Adversarial Environment Design. arXiv:2110.02439.
- Khattab, O., et al. (2023). DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines. arXiv:2310.03714.
- Lee, H., et al. (2023). RLAIF: Scaling RL from Human Feedback with AI Feedback. arXiv:2309.00267.
- Lightman, H., et al. (2023). Let's Verify Step by Step. arXiv:2305.20050.
- Liu, Z., et al. (2024). APIGen / xLAM: Automated Pipeline for Verifiable Function-Calling Datasets and Large Action Models. arXiv:2406.18518; arXiv:2409.03215.
- Lord, F. M. (1980). *Applications of Item Response Theory to Practical Testing Problems.*
- Matiisen, T., et al. (2017). Teacher–Student Curriculum Learning. arXiv:1707.00183.
- Opsahl-Ong, K., et al. (2024). Optimizing Instructions and Demonstrations for Multi-Stage LM Programs (MIPRO). arXiv:2406.11695.
- Packer, C., et al. (2023). MemGPT: Towards LLMs as Operating Systems. arXiv:2310.08560.
- Park, J. S., et al. (2023). Generative Agents: Interactive Simulacra of Human Behavior. arXiv:2304.03442.
- Patil, S., et al. (2023). Gorilla: Large Language Model Connected with Massive APIs. arXiv:2305.15334.
- Piech, C., et al. (2015). Deep Knowledge Tracing. *NeurIPS.* arXiv:1506.05908.
- Portelas, R., et al. (2020). Automatic Curriculum Learning For Deep RL: A Short Survey. arXiv:2003.04664.
- Qin, Y., et al. (2023). ToolLLM: Facilitating LLMs to Master 16000+ Real-World APIs. arXiv:2307.16789.
- Schick, T., et al. (2023). Toolformer: Language Models Can Teach Themselves to Use Tools. arXiv:2302.04761.
- Shinn, N., et al. (2023). Reflexion: Language Agents with Verbal Reinforcement Learning. arXiv:2303.11366.
- Wang, G., et al. (2023a). Voyager: An Open-Ended Embodied Agent with Large Language Models. arXiv:2305.16291.
- Wang, R., et al. (2019). Paired Open-Ended Trailblazer (POET). arXiv:1901.01753.
- Wang, Z., et al. (2024). Agent Workflow Memory. arXiv:2409.07429.
- Wu, T., et al. (2024). Meta-Rewarding Language Models. arXiv:2407.19594.
- Yang, C., et al. (2023). Large Language Models as Optimizers (OPRO). arXiv:2309.03409.
- Yin, D., et al. (2023). Lumos: Unified and Modular Training for Open-Source Language Agents. arXiv:2311.05657.
- Yuan, W., et al. (2024a). Self-Rewarding Language Models. arXiv:2401.10020.
- Yuan, Z., et al. (2023). Scaling Relationship on Learning Mathematical Reasoning with Large Language Models (rejection-sampling fine-tuning). arXiv:2308.01825.
- Yuksekgonul, M., et al. (2024). TextGrad: Automatic "Differentiation" via Text. arXiv:2406.07496.
- Zelikman, E., et al. (2022). STaR: Bootstrapping Reasoning With Reasoning. arXiv:2203.14465.
- Zeng, A., et al. (2023). AgentTuning: Enabling Generalized Agent Abilities for LLMs. arXiv:2310.12823.
- Zhou, Y., et al. (2022). Large Language Models Are Human-Level Prompt Engineers (APE). arXiv:2211.01910.
