# Algorithm v0.1 — Open-Ended Probabilistic Pathway Learning for Self-Learning Agents

**Codename:** Pathway Learner (`PL-v0.1`) · **Date:** 2026-06-22 · **Status:** design spec, no implementation
**Lineage:** generalizes the concept paper (*Multi-Dimensional Learning Pathway…*) from human learners to agents, and fixes its gaps.
**Companion docs:** `REPORT-self-learning-agents.md` (go/no-go + evidence), this file (the algorithm), `ALGORITHM-v0.1-redteam.md` (adversarial pressure-test).

> ⚠️ **Superseded by `ALGORITHM-v0.2-pathway-learner.md`.** A three-adversary red-team (`ALGORITHM-v0.1-redteam.md`) found three independent pilot-killers (verifier gaming, the eval-suite bootstrap gap, decay/no-regression oscillation), two of which fire in the §10 memory-only pilot. The **architecture holds; the mechanisms needed the v0.2 patch set** — which now exists. **Build from v0.2, not this file.** This v0.1 is retained for lineage (concept paper → v0.1 → red-team → v0.2).

> **What this is.** A single algorithm that makes a managed agent improve over time along two axes (memory-level and weight-level) by walking an **open, ever-branching graph of competence states**, expanding the frontier where *learning gain* is highest, and committing a move only when an *eval verifier* confirms it helped. It keeps the schema **open** (states, dimensions, edges grow from data) but commits at the **meta level** to three functions — a growth rule, a validity/affinity function, and a frontier policy. Tractability comes from Monte-Carlo frontier expansion; speed comes from an act/learn data split.

---

## 1. Gap → fix traceability (this is the "fix the gaps first" part)

Every gap surfaced in the analysis is closed by a named mechanism below.

| # | Gap identified | Fix in `PL-v0.1` | Section |
|---|---|---|---|
| T1.1 | No probabilistic model (only `P(S)={p1,p2,p3}`) | Beta-Bernoulli (optionally IRT) competence posterior per `(skill × difficulty)`, **growing** | §3 |
| T1.2 | Decision rule degenerate: `argmax P(success)` picks the mastered action | `π` maximizes **expected learning gain + novelty − cost**, Thompson-sampled | §4.3 |
| T1.3 | "Evolution loop" has no update rule | Discounted Bayesian posterior update + transition-value backup | §7 |
| T2.4 | Evaluation not reproducible (+18%/+23% unmethodized) | **Versioned eval suites + verifier registry** as the reward signal | §5 |
| T3.6 | Validation engine = word list | Defined as the eval harness + no-regression + safety gates | §5 |
| T3.7 | State conflates skill/mastery; assumes dims "independent" | Competence **tensor** over `(skill × difficulty × context)`; dependencies carried by the graph + hierarchical prior (no independence assumed) | §3 |
| T3.8 | 5-store architecture asserted, unjustified | Justified **per loop-step**; act/learn (hot/cold) split | §8 |
| T4.9 | No cold-start / sparsity handling | Nonparametric growth + Beta priors seed every new skill | §3, §4.1 |
| T4.10 | No forgetting / non-stationarity | Evidence **decay γ** + re-anchor after weight moves + rollback gate | §9 |
| T5.11 | Silent on reward/verifier (the real bottleneck) | **Verifier availability is the admission GO-condition** for a skill | §5 |
| T5.12 | Engagement dimension is dead weight for agents | Dropped; reused only as the **exploration term** | §4.3 |
| T5.13 | No cost / efficiency notion | Cost-aware `π`; **efficiency** is a tracked competence dimension | §3, §4.3 |
| O.1 | Schema fixed | **Growth rule `g`** adds states / dims / edges from data (CRP-style) | §4.1 |
| O.2 | Infinite branching intractable | **MCTS** frontier expansion — never enumerate, sample the promising tip | §4.3, §6 |
| D.1 | No home for checkpoints / datasets | **Object store + model registry** added to the data layer | §8 |
| D.2 | No cache invalidation under drift | Version-stamp by checkpoint id; **invalidate hot caches on promote** | §8, §9 |
| R.1 | Retrieval static (similarity only) | **State-conditioned** recall→rerank, outcome-learned | §4.2 |
| R.2 | State-conditioned retrieval → filter bubble | Exploration slice in retrieval shares `π`'s exploration budget | §4.2 |

---

## 2. Objects & notation

- **Agent-state node** `n = (c, K, L, Θ, z)` — checkpoint id `c` (weights), skill library `K`, lesson set `L`, competence posterior `Θ`, cached state embedding `z`. A node is a **checkpoint you can return to** (the agent's rewind advantage).
- **Learning action / edge** `a` — one of:
  - *memory axis (cheap):* `propose_skill`, `write_lesson`, `optimize_prompt`, `tune_retrieval`
  - *weight axis (expensive):* `curate_data`, `train_step{SFT|DPO|GRPO}`
  - *data gathering:* `explore_task` (run the agent on a task to harvest trajectories / surface a missing skill)
- **Open graph** `G = (N, E)` — nodes `N` (agent-states), edges `E` (actions), plus a **skill graph** of `(skill, prereq, transition)` relations. `G` **grows**.
- **Competence** `Θ = { C[s,d] }` — a posterior per `(skill s, difficulty d)` (and context bucket). `ĉ[s,d] = E[C[s,d]]`, with uncertainty `u[s,d]`.
- **Eval harness** `Eval` with a **verifier registry** `R`. `Eval.score(n, s) → SuccessEstimate`.
- **Stores** — hot read-models `{Redis, Graph, Vector}`; cold truth `{SQL, ObjectStore+Registry, Document}` (§8).

---

## 3. The probabilistic state model — fixes T1.1, T3.7, T4.9, T5.13

Replace the paper's undefined `P(S)` with a concrete, **growing** model.

**Per-cell competence (Beta-Bernoulli — the pragmatic default):**
```
C[s,d] ~ Beta(α[s,d], β[s,d])
ĉ[s,d] = α / (α + β)                      # point competence
u[s,d] = Beta_variance(α, β)              # uncertainty (drives exploration)
```
Update on eval outcomes with **decay γ ∈ (0,1]** (γ<1 ⇒ forgetting / drift tracking, the fix for T4.10):
```
α[s,d] ← γ·α[s,d] + successes
β[s,d] ← γ·β[s,d] + failures
```
- **Cold-start (T4.9):** every new `(s,d)` cell is born with a weak prior `Beta(α0, β0)` — the model is never undefined, even with zero history.
- **No independence assumption (T3.7):** cells are tied through (a) the **prerequisite graph** (mastery of `s` informs reachability of its successors) and (b) an optional **hierarchical prior** sharing strength across difficulties of the same skill. The paper's "independent dimensions" claim is dropped.
- **Efficiency dimension (T5.13):** alongside success, track `Eff[s] =` running cost-to-success (tokens/steps/$). It is a first-class competence target, not an afterthought.
- **Richer option:** swap Beta cells for **2-PL IRT** `P(success | θ_s, item_i) = σ(a_i(θ_s − b_i))` when you want item-level difficulty calibration. Interface (`ĉ`, `u`, `update`) is identical, so the rest of the algorithm is unchanged.

**Openness (the nonparametric core).** The index set `{s}` is **not fixed**. New skills are added by the growth rule `g` (§4.1). This is the CRP "new table": data can always demand a new state dimension.

---

## 4. The three meta-functions (commit here; stay empty elsewhere)

### 4.1 Growth rule `g` — the open schema (fixes O.1, supports T4.9)
```
maintain F = buffer of failed / low-reward trajectories
on each failure:  F.add(embed(trajectory))
periodically:
    for cluster in cluster(F):
        s* = nearest_existing_skill(cluster.centroid)
        if similarity(cluster.centroid, s*) < τ_new:        # CRP "new table" — dissimilar enough
            s_new = new_skill(prior = Beta(α0, β0))
            G.add_node(s_new)
            G.add_prereq_edges(s_new, inferred_from = co_mastered_skills(cluster))
            invalidate_caches(skills_touched = {s_new})
```
`τ_new` controls how readily the schema grows. This is how `S`, `P`, nodes, edges all expand from data.

### 4.2 Validity `v` + state-conditioned retrieval — fixes R.1, R.2; the SELECT context
`v(future | accumulated context)` is **compositional** (more mastered skills ⇒ more reachable), and the context fed to a decision is **conditioned on the current learning state**, retrieved fast by recall→rerank.
```
reachable(n):                                     # validity v — compositional widening
    return { s ∈ G : prereqs(s) all have ĉ ≥ θ } ∪ action_templates

retrieve(n, task):                                # state-conditioned, hot-path (~10–15 ms)
    cand = Vector.ann(query = task ⊕ n.z, k = topK)        # 1) recall: fast, static (~10 ms)
    scored = rerank(cand, by = score(·|n))                 # 2) rerank: small set, state-aware (~3 ms)
    return top_m(scored) ⊕ exploration_slice(novelty)      # R.2: keep the future open

score(ctx | n) = w · [ similarity,            # relevance to task
                       prereq_satisfied,      # reachable from current competence
                       learning_progress,     # would using it move competence most?
                       competence_gap,        # prefer near-frontier skills (almost-mastered)
                       recency / novelty,
                       past_success_in_state ] # R.1: learned from outcomes (cold path updates w)
```
The state vector `n.z` lives in `Redis`, so state-conditioning is **one cache read**. The weights `w` are updated asynchronously by attributing each eval delta to the context that was in play (retrieval is itself a memory-axis learnable artifact, gated by keep-iff-it-helps).

### 4.3 Frontier policy `π` — the corrected decision core (fixes T1.2, T5.12, T5.13, O.2)
```
π(n):
    A = reachable(n)
    for a in A:
        Q̃ = thompson_sample( value_posterior(n, a) )   # exploration via sampling (replaces engagement)
        U[a] = Q̃ + λ·novelty(a) − μ·cost(a)            # learning gain + novelty − cost
    return argmax_a U[a]
```
- **Not** `argmax P(success)`. `Q̃` estimates **expected learning gain** `E[Δcompetence | n, a]` (learning progress / regret), so the agent targets the **near-frontier**, not mastered or unreachable actions.
- `μ·cost(a)` makes the agent try **cheap memory moves before expensive weight moves** — the two axes fall out of one policy (T5.13).
- `λ·novelty(a)` is the open-endedness / anti-stall term (the repurposed "engagement", T5.12).

---

## 5. Eval harness & gates — fixes T2.4, T3.6, T5.11, H2

The reward signal is the whole ballgame; make it explicit and reproducible.
```
R = verifier registry, ordered by reliability:
    code_exec/tests  >  schema_validation  >  sim_task_success  >  llm_judge(weight=low, caveated)

admit(skill s):                       # T5.11 — the GO-condition
    return ∃ v ∈ R : v covers s and reliability(v) ≥ ρ_min
    #   no reliable verifier ⇒ s is NOT admitted to the autonomous loop (human-gated instead)

Eval.score(n, s):                     # T2.4 — versioned, reproducible
    suite = eval_suite[s] @ pinned_version            # items = the IRT/BKT "items"
    return aggregate( verifier.run(n, item) for item in suite )

gates(n', n):                         # T3.6 / H2 — the "validation engine", made real
    no_regression = ∀ monitored s: ĉ'[s] ≥ ĉ[s] − ε
    safe          = safety_eval(n') ≥ pass
    affordable    = spent ≤ budget
    return no_regression ∧ safe ∧ affordable
```

---

## 6. The main loop (the algorithm)

```
node ← root agent: {checkpoint, skill_library, lessons, competence_posterior, state_embedding}
G    ← open graph (nodes = agent-states, edges = actions, plus the skill graph)

loop forever:                                       # empty & unattached — no terminal goal
    # ── 1. SELECT ───────────────────────────────  (hot path; reads Redis/Graph/Vector)
    a   ← π(node)                                    # frontier policy: max learning-gain + novelty − cost
    ctx ← retrieve(node, a.task)                     # state-conditioned recall → rerank

    # ── 2. EXPAND ───────────────────────────────  (memory cheap; weight runs on a CLONED checkpoint)
    child ← apply(a, node, ctx)                      # propose-skill | write-lesson | train-step | explore-task

    # ── 3. EVALUATE ─────────────────────────────  (the verifier IS the reward; admit-gated)
    r ← Eval.score(child, a.target_skills)           # only trustworthy where a real verifier exists (§5)

    # ── 4. GROW ─────────────────────────────────  (nonparametric: schema expands from data)
    g.maybe_add_skill(child, F)                      # CRP new-table on a novel failure cluster

    # ── 5. BACKUP ───────────────────────────────  (the evolution loop, made concrete)
    child.Θ ← bayes_update(node.Θ, a, r, decay = γ)  # re-estimate competence (handles drift)
    G.update_transition(node, a, child, r)           # visit counts + running value
    backprop_value(node, r)                          # MCTS-style: every point is a root

    # ── 6. COMMIT or ROLLBACK ───────────────────  (keep iff it helped AND is safe)
    if r.improves and gates(child, node):
        node ← child                                 # advance: git-commit (memory) / promote ckpt (weight)
        maybe_promote_to_weights(node)               # §7 — D1 economics
        invalidate_caches(node)                      # D.2 — refresh hot read-models
    else:
        rollback(node.checkpoint)                    # the rewind advantage; log the dead branch
        F.add(child.failures)                        # feed the growth rule
```

---

## 7. Sub-procedures (definitions)

- **`apply(a, n, ctx)`** — memory actions mutate `K`/`L` and re-embed `z`; weight actions **clone** `n.checkpoint`, run `curate_data` (rejection-sample successful trajectories) → `train_step`, register a new checkpoint `c'`.
- **`bayes_update`** — the §3 decay update on the affected `(s,d)` cells. After a **weight** action, also **re-anchor**: re-run a small sentinel suite to reset stale competence (§9).
- **`backprop_value(n, r)`** — `n.visits++ ; n.value += (r − n.value)/n.visits`, propagated to ancestors (UCT).
- **`maybe_promote_to_weights(n)`** — promote a memory skill into a fine-tune when **all** of D1 hold: high **frequency** of use, **stability** (low recent edit rate), **context pressure** (library exceeds retrieval budget), **data sufficiency** (enough verified trajectories), **eval-proven** reliability. One-way ratchet; chosen conservatively.
- **`invalidate_caches(n)`** — version-stamp `Θ`, `z`, and rerank caches by `n.checkpoint`; drop hot entries keyed to the old checkpoint (D.2).

---

## 8. Data-architecture binding — fixes T3.8, D.1, D.2

The hybrid stores are justified by **which loop-step they serve** and split into an **act path (hot, ms)** and a **learn path (cold, async)** — the source of "act fast."

| Store | Serves | Path |
|---|---|---|
| `Redis` (in-mem) | SELECT — materialized **frontier** + cached `z`, `Θ` | 🔥 hot |
| `Graph` read-model | SELECT — `reachable`, transition probs, MCTS tree | 🔥 hot |
| `Vector` index | SELECT/EXPAND/GROW — retrieval recall, novelty, failure clustering | 🔥 hot |
| `Document` store | BACKUP/SELECT — **growing** competence posteriors `Θ` (schemaless = open schema) | 🌗 warm |
| `SQL` | BACKUP/COMMIT — canonical event log, eval results, **data lineage** | 🧊 cold |
| `ObjectStore + Registry` | EXPAND(weight)/COMMIT — **checkpoints + trajectory datasets** (D.1) | 🧊 cold |

**Discipline:** `SQL` is the single source of truth; `Redis`/`Graph`/`Vector`/`Document` are **disposable projections rebuildable from it** — which is what makes aggressive caching safe. On every `COMMIT`, project truth → read-models; on a **new checkpoint**, invalidate (D.2).

---

## 9. Non-stationarity & safety — fixes T4.10, H2, H4

- **Drift / forgetting:** decay `γ` continuously ages evidence; the near-frontier focus naturally re-practices regressing skills.
- **After a weight move (fast drift):** competence keyed to the old checkpoint is stale ⇒ **re-anchor** (sentinel re-eval) before trusting `Θ`; invalidate caches.
- **No-regression gate:** any monitored `ĉ[s]` dropping below `ĉ_prev[s] − ε` ⇒ **rollback** to the parent checkpoint (catastrophic-forgetting guard).
- **Reversibility:** memory commit = git; weight commit = registry promote with a parent pointer — both revertible.
- **Circuit-breaker:** `K` consecutive rollbacks, or eval-variance spike, ⇒ **halt the autonomous loop and flag a human** (extends the framework's existing circuit-breaker lanes to the weight axis).

---

## 10. `v0.1` runnable subset (build this first) + what's deferred

**Smallest instance that exercises the whole ideology, cheaply:**
- **One axis:** memory only (weights frozen). **Actions:** `explore_task`, `propose_skill`, `write_lesson`.
- **One domain with a real verifier:** tool / function-calling — `schema_validation` + `code_exec` (reliability high ⇒ admit-gate passes; this is the BFCL/xLAM setting).
- **State:** Beta cells per `(skill × difficulty)`. **`π`:** learning-progress + novelty − cost. **Growth:** on. **Retrieval:** recall→rerank with the cached state vector.
- **Stores:** Postgres (truth) + pgvector (embeddings) + `networkx` (graph) + dict/Redis (cache). ≈ Voyager + corrected `π` + growth rule. Cost ≈ $0.

**Deferred (drop in later as the same loop, no architecture change):** the weight controller (`curate_data`/`train_step`), object store + model registry, the document store (until `Θ` outgrows JSON columns), Neo4j/dedicated Redis (until scale demands), IRT upgrade.

The promise of the design: the weight axis is **just another (expensive) action type** in the loop above. Nothing in §6 changes when you add it.

---

## 11. Open parameters to calibrate

`γ` evidence decay · `τ_new` growth threshold · `ρ_min` verifier-reliability bar · `λ` novelty weight · `μ` cost weight · `θ` prereq-mastery bar · `ε` regression tolerance · `K` circuit-breaker count · `k` learning-progress window · `topK`/`m` retrieval recall/keep · `(α0,β0)` cold-start prior · D1 promotion thresholds.

These are the dials a first empirical pass (the §11 experiments in the report) would tune.
