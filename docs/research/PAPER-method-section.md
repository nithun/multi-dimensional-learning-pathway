# Method (rewritten core for the paper)

*Drop-in replacement for the original paper's §§2–8 (Conceptual Framework → Pathway Evolution). Written learner-agnostically — the "learner" may be a human student or a software agent — with the agent as the primary instantiation. Engine names from the original (Validation, Inference, Decision, Evolution) are preserved and mapped to the formal components below. Companion design specs: `ALGORITHM-v0.2-pathway-learner.md`; evidence base: `REPORT-self-learning-agents.md`.*

---

## 3. Method

### 3.1 Overview and design principles

We model an adaptive learner as a probabilistic process that traverses an **open, growing graph of competence states**, and we select each next learning action to **maximize expected learning gain** under an **explicit, verifier-grounded measurement of success**. This reframes the original deterministic, greedy formulation along four axes, each of which is a contribution of this revision:

1. **Deterministic state → a probabilistic competence field with a concrete estimator** (§3.2), replacing the unspecified $P(S)=\{p_1,p_2,p_3\}$.
2. **Greedy success-maximization → learning-gain maximization** (§3.6): we show the original objective $A^\* = \arg\max_A P(\text{success}\mid S,A)$ is *degenerate for learning* and replace it.
3. **Asserted reward → a measured one** (§3.5): the success probability that drives every decision is *measured* by an evaluation engine with explicit verifiers, not assumed.
4. **Fixed schema → an open, self-provisioning one** (§3.4): the state space, dimensions, and graph grow with data.

Two principles govern every component:

> **P1 (measurement independence).** Every quantity that drives a decision is estimated on data the learner's optimization never touched — held-out evaluation items, counterfactual credit, audit-anchored verifier reliability, cumulative baselines. The learner must not be able to move a metric without moving the latent quantity the metric estimates.
>
> **P2 (reversible openness).** The state set, graph, and parameters grow with data, but every growth operation is paired with an inverse (merge, prune, edge-decay, garbage-collection), and every gate compares against a fixed baseline rather than only the previous step. Open-ended growth without inverses is a ratchet toward an ever-more-constrained, ever-more-wrong state.

The framework is learner-agnostic, but it is sharpest where competence is *directly measurable*. For a human student, competence is latent and must be inferred; for a software agent it is observable (up to sampling noise) by executing an evaluation suite. We therefore develop the general framework and mark its **agent instantiation** at each step.

### 3.2 Probabilistic learner state (Inference Engine, part I)

Let $\mathcal{S}_t$ be the (time-varying, growing; §3.4) set of skills, and $d \in \mathcal{D}$ difficulty levels. For each cell $(s,d)$ we model latent competence $c_{s,d}\in[0,1]$ as the probability of success on an item of skill $s$ at difficulty $d$. The **learner state** $S_t$ is the joint posterior over the competence field $\mathbf{c}=\{c_{s,d}\}$.

We maintain a Beta–Bernoulli posterior per cell,
$$c_{s,d}\sim \mathrm{Beta}(\alpha_{s,d},\,\beta_{s,d}),\qquad \hat c_{s,d}=\frac{\alpha_{s,d}}{\alpha_{s,d}+\beta_{s,d}},\qquad u_{s,d}=\mathrm{Var}[c_{s,d}],$$
updated from evaluation outcomes (§3.5) with a **forgetting/drift decay** $\gamma\in(0,1]$:
$$\alpha_{s,d}\leftarrow \mathrm{floor}\!\big(\gamma\,\alpha_{s,d}\big)+k^{+},\qquad \beta_{s,d}\leftarrow \mathrm{floor}\!\big(\gamma\,\beta_{s,d}\big)+k^{-},\tag{1}$$
where $k^{+},k^{-}$ are observed successes/failures and $\mathrm{floor}(\cdot)$ enforces a minimum effective sample size $n_{\min}$ so that a single evaluation can never move $\hat c$ by more than the regression tolerance $\varepsilon$.

A single decay constant is over-determined — it would have to set the retention horizon, the exploration floor, and the rollback sensitivity simultaneously. We therefore maintain **two posteriors per cell**: a slow-decay **mastery** posterior $c^{m}_{s,d}$ (decay $\gamma_{\text{slow}}\!\to\!1$ as the cell stabilizes; drives selection, the exploration floor, and promotion) and a fast-decay **drift** posterior $c^{d}_{s,d}$ (decay $\gamma_{\text{fast}}$; drives only regression/rollback). Decays are per-skill.

The uncertainty $u_{s,d}$ is first-class: it drives exploration as optimism-under-uncertainty (§3.6). Competence dimensions are **not** assumed independent — dependencies are carried by the prerequisite graph (§3.3) and an optional hierarchical prior tying difficulties of a skill. A 2-parameter IRT model, $P(\text{success}\mid \theta_s, i)=\sigma\!\big(a_i(\theta_s-b_i)\big)$ with item difficulty $b_i$, is a drop-in upgrade exposing the same $(\hat c, u, \text{update})$ interface.

*Agent instantiation.* $\hat c_{s,d}$ is obtained by executing the held-out evaluation items for $(s,d)$; the inference problem reduces from latent-trait estimation to sampling-error control. Checkpointing the agent makes each state $S_t$ a restorable node, enabling counterfactual evaluation of a learning action — impossible for a human learner.

### 3.3 The open pathway graph (Inference Engine, part II)

Learning trajectories live on a directed graph $G_t=(V_t,E_t)$ whose vertices are skills/competence states and whose edges are of two kinds: **prerequisite** edges and **transition** edges. The original formulation gated reachability by a hard conjunction over prerequisites; we replace it with a **soft, probabilistic** reachability that is robust to a single mis-estimated or stale prerequisite:
$$\rho(s\mid S_t)=\prod_{p\in \mathrm{pre}(s)} \Pr\!\big(c^{m}_{p}\ge \theta\big),\tag{2}$$
the probability that all prerequisites of $s$ are mastered to level $\theta$, computed from the mastery posteriors. $\rho$ enters the decision objective as a multiplier rather than a binary gate, so one wrong edge *dampens* but never *deletes* a skill from the frontier. Transition edges carry online-updated probabilities (§3.7).

Crucially, the **prerequisite structure is compositional**: as more skills are mastered, $\rho$ opens *more* successor skills, so the reachable frontier *widens* with accumulated competence rather than narrowing. This formalizes the intuition that more context yields more reachable futures.

### 3.4 An open, self-provisioning schema (the growth rule)

The schema is nonparametric: $\mathcal{S}_t$, the dimensions of $\mathbf{c}$, and $E_t$ all grow with data. A growth operator $g$ inspects a buffer $F$ of failed/novel trajectories; when a cluster of failures is sufficiently dissimilar from every existing skill (a Chinese-Restaurant-Process "new table" with region-adaptive threshold $\tau_{\text{new}}$), it spawns a new skill. By **P2**, $g$ also runs the inverse operations: it **merges** near-duplicate skills (hysteresis $\tau_{\text{merge}}>\tau_{\text{new}}$, unioning their evidence), **prunes** orphan skills that make no progress, and **decays** prerequisite-edge confidence unless renewed by intervention-like evidence (mastering the prerequisite actually unlocked the dependent).

A grown skill is unusable until it can be *scored*. We therefore make scorability an **invariant of graph membership** (the contribution that makes open-endedness operational rather than vacuous): on creation, $g$ must **provision** an evaluation suite and an admitted verifier for the new skill — by inheriting them from the nearest admitted parent skill, or by synthesizing items from the failure cluster gated by an existing reliable verifier. If neither is possible, the skill is placed in a `pending_human` state and **excluded** from reachability, retrieval, and clustering until a human attaches a verifier. No unscorable node ever enters the live graph.

This is the precise sense in which the framework is "empty and unattached at the object level but committed at the meta level": the schema ($\mathcal{S}_t, \mathbf{c}, E_t$) is held open, while three meta-functions are fixed — the growth rule $g$, the reachability/affinity $\rho$ (§3.3), and the decision policy $\pi$ (§3.6).

### 3.5 The evaluation engine: success, measured (Validation Engine)

The original framework's decision rule depends on $P(\text{success}\mid S,A)$ but never says how it is obtained. Supplying this measurement is the linchpin of the revision, because the entire system is an optimizer pointed at it.

For a learner in state $n$ and skill $s$, success is measured by a **verifier** $v$ applied to the learner's behavior on evaluation items. Verifiers form a registry $R$ ordered by reliability — execution/unit-tests $\succ$ schema/format validation $\succ$ simulated task success $\succ$ (last resort) model-as-judge. By **P1**, each skill's items are split into a **public** set, which the learner's act-time context may see, and a **held-out** set, which never enters context and is the *only* split that drives rewards, gates, and calibration. A commit or promotion additionally requires a **generalization condition**
$$\Delta \hat c_{\text{held-out}} \;\ge\; \rho_{\text{gen}}\cdot \Delta \hat c_{\text{public}},\tag{3}$$
so that improvement on memorized public items without held-out improvement (the memorization signature) is rejected.

Two further hardenings make "a verifier exists" mean "the loop is safe": verifiers assert on **trajectory shape** (the intended tools/arguments were used, derived from the query rather than hard-coded) and on **counterfactual variants** (a freshly injected item defeats a memorized constant), not merely on terminal output; and verifier reliability is *defined*, not assumed —
$$\mathrm{reliability}(v\mid \text{band})=\text{precision/recall of } v \text{ against a human audit set } v \text{ never trains on},$$
estimated per difficulty band with a confidence interval. A skill is **admitted** to autonomous learning only if some covering verifier clears the bar on its *lower* confidence bound, and admission is re-checked as the learner enters new difficulty bands.

This makes explicit a precondition the original framework left implicit: **the method is valid only where a reliable verifier exists.** Where success can be cheaply and reliably checked (execution, formal/schema validation, simulated task completion) the loop compounds; where the only available signal is a model's subjective judgment, the loop saturates or is gamed, and such skills are held out of autonomous learning by the admission gate.

### 3.6 The decision engine, corrected (Decision Engine)

The original objective selects the action of highest immediate success,
$$A^\*=\arg\max_{A}\,P(\text{success}\mid S,A).\tag{old}$$
This is **degenerate for learning**: the action of highest success probability is the one the learner has already mastered, for which the expected competence change is $\approx 0$. Maximizing immediate success therefore minimizes learning. We replace it with an objective on **expected learning gain**,
$$A^\*=\arg\max_{A}\;\mathbb{E}\big[\Delta U(S)\mid S,A\big],\qquad U(S)=\textstyle\sum_{s,d} \hat c_{s,d},\tag{4}$$
i.e. the action expected to most increase competence — equivalently the *learning progress* (the slope of the competence curve) or *regret* to a reference. The selection over candidate actions $\mathcal{A}$ uses the soft-reachability weight (2) and posterior optimism, with terms placed on comparable scales:
$$\pi(S)=\arg\max_{A\in\mathcal{A}}\;\Big[\, z\big(\tilde Q(S,A)\big)\;+\;\lambda\, z\big(\mathrm{infogain}_{\text{reach}}(A)\big)\,\Big]\quad\text{s.t.}\ \text{cost}(A)\le \text{budget},\tag{5}$$
where $\tilde Q$ is a Thompson-sampled estimate of $\mathbb{E}[\Delta U\mid S,A]$ (sampling from the posterior supplies exploration), $z(\cdot)$ is a z-score over the candidate set, $\mathrm{infogain}_{\text{reach}}$ rewards actions that unlock currently-unreachable regions (so foundational-but-unfamiliar prerequisites are not hidden by a pure novelty term), and cost enters as a hard budget constraint rather than a soft penalty on an incommensurable scale.

Two safeguards follow **P1/P2**. The learning-gain term enters (5) only when it is **statistically significant** — $\Delta U$ must exceed $z\cdot \mathrm{SE}$ on paired held-out items — otherwise the policy falls back to explicit exploration rather than chasing sampling noise. And a **coverage floor** guarantees every admitted skill is practiced at rate $\ge f_{\min}$ regardless of its learning-progress estimate, so the curriculum cannot permanently abandon a hard skill.

### 3.7 The evolution loop (Pathway Evolution)

After an action $A$ from state $S_t$ yields a held-out outcome $r$, the framework updates three structures, supplying the concrete update rule the original "continuous loop updating transition probabilities" lacked:

1. **Competence** — both posteriors via the decayed Bayesian update (1).
2. **Transition probabilities** — the edge $(S_t,A,S_{t+1})$ accrues a visit count and a recency-discounted value estimate.
3. **Search value** — value is backed up to ancestor states with a discounted/sliding-window estimator so that, under non-stationarity, returns generated by superseded policies age out.

The transition $S_t\!\to\!S_{t+1}$ is then **accepted** only if it passes a composite gate that embodies **P1/P2**:
$$
\underbrace{\Delta\hat c_{\text{held-out}}>\varepsilon+z\,\mathrm{SE}}_{\text{statistically real}}\;\wedge\;
\underbrace{\hat c_{\text{held-out}}\ge \hat c_{\text{baseline}}-\varepsilon_{\text{cum}}}_{\text{no cumulative drift}}\;\wedge\;
\text{(3)}\;\wedge\;\underbrace{\text{safe}}_{\text{held-out safety items}}\;\wedge\;\text{affordable},
\tag{6}
$$
otherwise the learner **rolls back** to the prior state. The cumulative term — comparing to a *fixed ancestor* baseline, not merely the previous step — closes the "death by a thousand within-tolerance commits" failure. Rollback is rate-limited, and information from safety-failed branches is not retained, so reversibility cannot be abused to map the safety boundary.

*Non-stationarity.* The learner changes under the controller — slowly for context-level learning, rapidly for parameter-level learning (§3.8). On any change of the underlying model, competence estimates and search values keyed to the old model are **invalidated and re-anchored** (a sentinel re-evaluation), and any monitored regression triggers rollback.

### 3.8 Agent instantiation: two learning axes and promotion

For an agent learner the action set spans two axes that **share** the state model (§3.2), the evaluation signal (§3.5), and the decision objective (§3.6), and differ only in action space, cost, and timescale:

- a **memory/context axis** (propose a skill, record a lesson, optimize a prompt; weights frozen) — cheap, fast, reversible; and
- a **parameter axis** (curate verified trajectories, take a fine-tuning step) — costly, slow, durable.

The two axes form a **producer/consumer pair**: the verified successful trajectories accumulated by the memory axis are exactly the rejection-sampled training data the parameter axis consumes. A behavior is **promoted** from memory to parameters by a **two-stage, mostly-reversible** procedure (an alternative to an irreversible one-way merge): a scored promotion index (frequency, behavioral stability measured on held-out items, context pressure, data sufficiency, held-out-proven reliability) gates training of a *detachable adapter* (stage 1, reversible); only after sustained held-out performance, a human spot-check of the kept trajectories, and a no-regression check over an explicit monitored set does the adapter merge into the base parameters (stage 2). A cheap pre-training interference estimate skips promotions likely to regress other skills before the training cost is paid.

### 3.9 System architecture: the act/learn split (revising the hybrid store)

The original hybrid multi-store is justified here by an explicit separation of timescales. The learner must **act** — read its competence, find reachable actions, retrieve context — in milliseconds, while it **learns** — re-estimate state, fine-tune, rebuild the graph — over seconds to hours. The store roles follow this split: an in-memory cache (materialized frontier and state vector), a graph read-model (reachability and search tree), and a vector index (retrieval and failure clustering) form the **hot act path**; a relational store of record (events, evaluation results, data lineage), an object store and model registry (checkpoints and datasets), and a schemaless document store (the *growing* competence field) form the **cold learn path**. The relational store is the single source of truth; the hot read-models are disposable projections rebuilt from it, which is what makes aggressive caching safe. On any model change, both the state caches and the search-tree statistics are invalidated.

### 3.10 Summary of the algorithm

Each iteration: **(select)** an action maximizing significant expected learning gain over the soft-reachable, coverage-floored candidate set under a budget constraint, with state-conditioned context retrieved from the held-out-clean memory; **(act)** execute it (on a cloned checkpoint for parameter actions); **(evaluate)** score it on held-out, trajectory-shape, counterfactual verifiers; **(grow)** provision/merge/prune the schema; **(update)** the two competence posteriors, transition probabilities, and discounted search values; **(commit or roll back)** under the composite statistical–cumulative–generalization–safety gate; and, on a cadence, **(promote)** stable, held-out-proven memory skills into parameters by the two-stage reversible procedure. The loop has no terminal state: it continually expands the frontier where measured learning gain is largest, subject to the precondition that a reliable verifier exists for any skill admitted to autonomous learning.

---

*Note on the remaining paper sections.* This Method replaces the original §§2–8. To meet the bar for a research contribution the paper still needs (i) a **Related Work** section situating the framework against knowledge tracing (BKT/DKT), item response theory, intelligent tutoring, automatic curriculum and teacher–student learning, and agent fine-tuning; and (ii) an **Evaluation** section with defined baselines, metric definitions, ablations isolating each component's contribution, and held-out (not pinned-suite) reporting — the original's headline figures are not reproducible as stated. Both are scoped but not written here.
