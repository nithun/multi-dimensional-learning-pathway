# Build specs — the integration register, made implementable

Implementation-ready specifications for the 🆕 items in [`ALGORITHM-INTEGRATIONS.md`](ALGORITHM-INTEGRATIONS.md), built **one at a time** (each reviewed before the next). These are specs — the math, interfaces, plug-points, and tests — not code; the code lands in the turing-agents `mdlp` package. Each spec references the v0.2 section it extends and reuses §§2–15 unchanged.

Status: **▣ specced** · **▢ pending**.

---

## A1 · Information-gain selection — the Tutor's core objective  ▣ APPROVED (review-360 85/100 · change-approver APPROVED)

*Extends §13.1 (which named the objective) to a computable one. This is the through-line: bias-free = fastest = exploration are the same action.*

### The objective
The Tutor scores each candidate action `a` by a blend of **advance** (expected competence gain) and **diagnose** (expected uncertainty reduction), normalized over the candidate set, under the hard cost constraint:

```
U(a) = (1 − w)·z( E[Δcompetence | a] )  +  w·z( EIG(a) )        s.t. cost(a) ≤ budget
```
- `z(·)` = candidate-set z-score (the §5.3 frontier-policy normalization — keeps the two terms commensurable).
- `w ∈ [0,1]` = the **advance↔diagnose** weight, driven by current uncertainty: unsure about the learner → diagnose (high `w`); confident → advance (low `w`).
- the **advance** term `E[Δcompetence|a]` is the learning-progress estimate (the §3 regression slope), and enters only if `significant(LP, SE)`; else it falls back to pure EIG (don't act on noisy LP, RC-1).

### EIG in closed form (the key — cheap and exact for Beta)
For a cell `c ~ Beta(α,β)`, the expected information gain of one observation is exact:
```
H(α,β)   = ln B(α,β) − (α−1)ψ(α) − (β−1)ψ(β) + (α+β−2)ψ(α+β)     # differential entropy
p        = α/(α+β)
E[H']    = p·H(α+1, β) + (1−p)·H(α, β+1)                          # expected posterior entropy
EIG_cell = H(α,β) − E[H']                                         # ≥ 0; FALLS as n_eff grows (NOT a peak at ĉ=0.5)
```
`B` = Beta function (`math.lgamma`); `ψ` = digamma via the **recurrence** `ψ(x)=ψ(x+1)−1/x` to shift the argument to `x≥6`, then the standard asymptotic series — accurate to ~1e-12. *(A naive small-`x` series is off by ~1e-2 at `α=1` and far worse at `α=0.5` — the order of EIG itself — so the small `α,β` these posteriors carry require the recurrence step.)* For an action touching one cell, `EIG(a)=reach_weight(cell)·EIG_cell`. Cells linked by the prereq graph (§5.2) are statistically **dependent**, so a raw `Σ EIG_cell` over multiple cells **over-counts** the joint information — use a sub-additive aggregate (the max, or a correlation-discounted sum), never the plain sum.

> **What EIG actually does (precise).** `EIG_cell` measures *uncertainty* about a cell and **falls as effective sample size `n_eff` grows** (the posterior sharpens); it is *not* a function of `ĉ` peaking at 0.5 — at fixed `n_eff` it is near-flat across mid-mastery. So **EIG alone goes where you know least**, which at unequal `n_eff` is the *thinnest* cell, not necessarily the learnable frontier. The frontier is targeted by the **blend**, not EIG in isolation: `EIG` (diagnose the least-certain *reachable* cell) × `reach_weight` (soft reachability §5.2, damps the unreachable) **+** the **advance** term (learning-progress §3 — where competence is actually rising) **+** the coverage floor; the `n_min` floor (§3) bounds how thin a cell can look. *Bias-free + informative + fast emerge from the blend* — this corrects the earlier over-claim.

### The `w` schedule (advance↔diagnose) — fully specified
```
Var[Beta]                 = αβ / ((α+β)² (α+β+1))
mean_frontier_uncertainty = mean over the reachable candidate cells of  sqrt(Var[Beta])   # posterior SD
w = clip( mean_frontier_uncertainty / u_ref , 0, 1 )                                       # u_ref default 0.15
```
The estimator is the **mean posterior SD over the reachable candidate set** (the cells `choose` already scores — no extra cost). `u_ref` is the SD at which the crossover sits — default **0.15** (≈ the SD of a lightly-populated cell): `w≈0.5` at typical uncertainty, `w→1` when broadly unsure (diagnose first), `w→0` as posteriors sharpen (advance). §14 calibration keeps the SD honest, so `w` can't be driven by over-confident variance.

### Plug-point
`mdlp/decision.py :: DecisionEngine.choose` — replace the current `q = thompson(lp)·reach` scoring with `U(a)` above; add `expected_info_gain(cell)` to `mdlp/state.py` (closed form). Coverage floor, hard cost, and `significant()` are unchanged. (`decision.py` is in turing-agents; this is the spec.)

### Parameters
`w` schedule `u_ref` · advance-term significance `z` (existing) · `μ` cost weight (existing).

### Tests (red-team-style regressions)
- `test_eig_closed_form_matches_numeric` — closed-form EIG = numeric entropy difference (grid integration) within tol.
- `test_eig_falls_with_n_eff` — `EIG_cell` decreases monotonically as `n_eff` grows at fixed `ĉ` (NOT a peak at `ĉ=0.5`; near-flat across mid-mastery at fixed `n_eff`).
- `test_blend_beats_pure_eig_on_frontier` — a very thin off-frontier cell (high EIG, low reach × advance) loses to a near-frontier cell under the blended `U(a)` — the blend, not EIG, picks the frontier.
- `test_diagnose_when_uncertain` — with a wide posterior, the Tutor selects the high-EIG cell over a high-but-certain one.
- `test_advance_when_confident` — with sharp posteriors, selection tracks learning-progress, not EIG.
- `test_insignificant_lp_falls_back_to_eig` — noisy LP ⇒ EIG drives the choice (no acting on noise).

### Review notes (revised after review-360 round 1: 78 → re-gating)
Round-1 review (`reviews/A1-info-gain-review.md`) found 6 blockers; all addressed above: (1) digamma → recurrence-then-asymptotic (the 6-term series was wrong at small α,β); (2) the "peaks at ĉ≈0.5" over-claim corrected — EIG falls with `n_eff`, and **EIG alone chases the thinnest cell**, so the *blend* targets the frontier; (3) `w`/`u_ref`/estimator fully defined with defaults; (4) citations fixed to §5.2/§5.3; (5) multi-cell aggregation made sub-additive (raw Σ over prereq-linked cells over-counts); (6) tests updated. The closed-form Beta EIG itself was verified correct (matches numeric to ~1e-10). The remaining genuine judgment call is `u_ref` (the diagnose↔advance crossover) — tune on the pilot. This makes §13.1 real and is the foundation the other selection items (warm-start, spacing) build on.

---

## A5 · Warm-start from "learners like you"  ▣ APPROVED (review-360 82/100 over 6 rounds · change-approver APPROVED)

*A new learner must not begin at a flat `Beta(α0,β0)`. Initialize the competence posterior from the cohort of *similar* learners → a tighter, better-located starting belief → fewer diagnostic items to converge (the cold-start killer). Extends §3 (the prior) and §5.2 (vector retrieval).*

### Mechanism
1. **Find similar learners** (vector store): embed each learner by their **item-response pattern on a fixed anchor diagnostic set** — NOT the policy-chosen trajectory. A trajectory embedding encodes the system's own past selection policy, so it would *propagate that policy's filter bubble* to every new learner (RC-7); the anchor set is policy-invariant. Retrieve the `k` nearest cohort members **diversity-filtered by MMR** — greedily pick each next neighbour to maximize `similarity(new, query) − λ_div·max_sim(new, already-selected)` (`λ_div` default 0.5) so the set spans the neighbourhood instead of clustering. If even MMR finds no diversity (a **homogeneous cohort** — same curriculum), the population-level bubble can't be filtered away, so **down-weight the warm prior**: measure neighbour diversity `div = mean pairwise (1 − cosine similarity) among the k selected ∈ [0,1]` and use `n_eff_warm_eff = n_eff_warm · max(div, div_floor)` (`div_floor` default 0.2) — a homogeneous cohort (`div→0`) keeps only a weak prior; lean on monitoring (step 4) + §14 calibration to catch a consensus that's actually a bubble.
2. **Form a per-cell warm prior** from the neighbours' posteriors on that `(skill, difficulty)` cell:
```
μ_knn      = clip( similarity-weighted mean competence of the k nearest learners on the cell , ε, 1−ε )
warm_prior = Beta( α0 + n_eff_warm·μ_knn , β0 + n_eff_warm·(1 − μ_knn) )     # n_eff_warm small (default 3)
```
The flat cold prior `(α0,β0)` is **always present as a floor**, so `warm_prior` is **never degenerate** even when the cohort is all-fail/all-pass (`μ_knn → 0 or 1`). Empirical-Bayes view: the cohort shifts the prior *on top of* the flat floor; `n_eff_warm` is how strongly you trust it.
3. **Keep it WEAK, and let it dilute itself.** The warm prior is a **one-time cold-start seed** (`n_own = 0`); thereafter the learner's own Bayesian updates take over and the warm prior's relative weight is **`n_eff_warm / (α0 + β0 + n_eff_warm + n_own) = 3/(5+n_own)`** with defaults — decaying automatically as the learner's own held-out observations `n_own` accumulate: ~21% after 9 own obs, ~9% after 27. *No separate decay mechanism and no re-injection* (re-injecting would double-count). **Warm-start is a prior, not a belief** — a better starting point, never a prison: the learner's own data overrides the cohort by construction.
4. **Monitor for bubbles.** Flag a learner whose outcomes track the warm prior *too* closely; §14 calibration catches over-confident warm priors. The embedding may be re-used for "learners-like-you" recommendations (B4), but the *prior* is seeded once.

### Plug-point
`mdlp/state.py :: ProbabilisticState.cell()` — replace the fixed `(α0,β0)` cold-start prior with `WarmStart.prior(skill, difficulty, learner)`; a `WarmStart` component reads the `VectorStore` (neighbour retrieval) + the cohort `StateStore`. Falls back to `(α0,β0)` when no cohort/neighbours exist.

**Invariant (enforced):** `WarmStart` writes *only* the cell's initial `(α,β)` prior — it has **no path** to `reachable`/`admit`/the candidate set in `choose`. So it can **seed but never gate-keep, filter, or block** a learner from any skill. (Acceptance: a static check that `WarmStart` is referenced only by `cell()`'s prior, nowhere in selection/reachability/admission.)

### Parameters
`k` neighbours · `n_eff_warm` warm-prior strength (default 3, **scaled down by neighbour-set diversity**) · `λ_div` MMR diversity weight (default 0.5) · `div_floor` min diversity factor (default 0.2) · `ε` boundary clamp (default 0.02) · similarity threshold · anchor-set size.

### Honest risks
- **Warm-start bias / stereotyping** (the big one): a too-strong prior or a wrong similarity metric biases the learner toward the cohort → a filter-bubble. Mitigation: **weak prior** (low `n_eff_warm`), the held-out verifier + the learner's own data override it, and §14 calibration checks the warm-started posteriors aren't miscalibrated.
- **Cohort bias/fairness:** a biased cohort propagates (e.g. demographic). Flag for audit; never let warm-start gate-keep — it only seeds.
- **Embedding-level bubble (RC-7):** a *trajectory* embedding would encode the selection policy's bubble and propagate it. Defused by the **policy-invariant anchor-set item-response embedding** + the **diversity filter** + monitoring (mechanism 1, 4) — *not* by demographic features (which only move the bias to fairness).
- **Validate, don't assume:** warm-start must be shown to beat the flat prior on held-out convergence — not presumed.

### Tests
- `test_warmstart_tightens_cold_start` — warm-started from a confident cohort, initial posterior SD < flat-prior SD.
- `test_warmstart_overridden_by_own_data` — after a few own held-out outcomes the posterior tracks the learner, not the cohort.
- `test_warm_prior_never_degenerate` — at `μ_knn ∈ {0, 1}` (and after the ε-clamp) the prior is a valid `Beta(α≥α0, β≥β0)`, no boundary error.
- `test_influence_dilutes_as_specified` — the warm prior's weight = `n_eff_warm/(α0+β0+n_eff_warm+n_own) = 3/(5+n_own)`; ~21% by 9 own obs, <10% by 27 (defaults).
- `test_homogeneous_cohort_downweights` — a near-identical neighbour set (`div→0`) yields `n_eff_warm_eff = n_eff_warm·div_floor` (a weak prior), not full strength.
- `test_embedding_is_policy_invariant` — the anchor-set embedding is unchanged under a different selection policy (no bubble propagation).
- `test_mmr_diversity_filter` — given a dense cluster + outliers in the candidate pool, MMR returns a spread set whose `div` exceeds plain top-k's (not k near-duplicates).
- `test_warmstart_never_gatekeeps` — `WarmStart` affects only `cell()`'s prior; the **candidate set and admission decisions** (which skills are reachable/admitted) are identical with and without it. *(Soft `reach_weight` values legitimately shift because the prior shifts `(α,β)` — only set membership must be invariant: it seeds, never blocks.)*
- `test_warmstart_falls_back_to_flat` — no neighbours → exact `(α0,β0)` prior.
- `test_divergent_learner_not_imprisoned` — a learner whose true rate is opposite the warm prior converges. Worst case (`μ_knn=0`, true rate 1): posterior mean `= (1+n_own)/(5+n_own)`, so **convergence error `= (β0+n_eff_warm)/(5+n_own) = 4/(5+n_own)`** — within **0.125 after 27** own obs, within **0.10 after 35**. *(The error `4/total` exceeds the warm-prior weight `3/total` — distinct quantities.)*

### Review notes (review-360 round 1: 58 → round 2: 72 → round 3 re-gating)
Round-2 also resolved: the **MMR diversity filter** is now specified (`λ_div=0.5`) and **scales `n_eff_warm` down for a homogeneous cohort** — the population-level bubble the anchor-set embedding alone can't fix; and the divergent-learner test carries the derived bound (within 0.10 after 27 own obs).

Round-1 (`reviews/A5-warmstart-review.md`) found the embedding-level filter-bubble (RC-7) as the blocking critical, plus a degenerate `Beta(0,n)` boundary and an undefined influence-decay. All addressed: (1) embed by a **policy-invariant anchor-set item-response pattern** + a **diversity filter** + bubble monitoring; (2) the **`(α0,β0)` floor + ε-clamp** make the prior never degenerate; (3) influence-decay is now the natural Bayesian dilution `n_eff_warm/(n_eff_warm+n_own)` (no ad-hoc mechanism, one-time seed). Main tunable: `n_eff_warm`. This is the cold-start half of the speed story (A1 is steady-state) and the highest-ROI human-ed speed win; depends only on A1 + the vector store.

---

## B4 · Forgetting-aware spacing  ▣ APPROVED (review-360 82/100 · change-approver APPROVED)

*Schedule each cell's review at the moment competence is about to decay below a retention target → maximal retention per review (durable competence per unit effort). Uses the drift posterior + decay (§3) + the Redis scheduler (§10).*

### Mechanism
1. **Retention model.** Per cell, model retention `R(t) = exp(−t/S)` where `S` is a **stability** that grows with each successful spaced review: `S ← S·(1+a)` on a held-out pass (default `a=1.0`, i.e. doubling), `S ← S·b` on a fail (default `b=0.5`). Initial `S0 = max(S_unit · ĉ_m, S_min)` where `ĉ_m = ProbabilisticState.estimate().mastery_mean` (the slow-decay, §14-calibrated posterior mean — *not* the `drift` one) (`S_unit` default 1, `S_min` floor 0.1) — the floor stops `ĉ_m→0` from forcing `t_next→0` and flooding the due-heap.
2. **Next-review time.** Due when retention hits the target `r*` (default 0.85): `t_next = −S·ln(r*)` — the interval **expands** as mastery solidifies (S grows) and **contracts** after a lapse. Over-optimistic `S` is corrected at the **next due review** — a crammed/over-estimated cell fails it → the lapse rule `S←S·b` fires. The drift posterior is *decayed toward the prior across a long interval*, so it is **not** relied on to catch mid-interval forgetting; the scheduled held-out review is the retention check.
3. **Scheduling.** A min-heap in Redis keyed by `t_next`; the Tutor pulls **due** cells into the candidate set with a due-boost in the coverage floor (§5.3). **Interleave** — consecutive due reviews must not be the same skill (a desirable difficulty).

### Plug-point
A `Scheduler` over `ProbabilisticState` (drift/decay) + `CacheStore` (the due-heap) + a per-cell `S`; the Tutor's `choose` merges due reviews. (`mdlp/` — spec only.)

### Parameters
`r*` (0.85) · `a` (1.0) · `b` (0.5) · `S_unit` (1) · `S_min` (0.1) · `p_probe` (0.1) · interleave window (no same-skill within 3 due items) · due-boost (+0.5 to the candidate score) · `ρ_rev` review-budget cap (0.5).

### Honest risks
- **Over-scheduling** (too many reviews → cost): a high-retention cell has **low EIG** (A1), so the info-gain Tutor deprioritizes it; the budget caps total reviews.
- **Exponential model is an approximation** — `S` must be **calibrated empirically** (§14): does a cell at predicted `R=r*` actually pass at `r*`? Recalibrate `a,b` if not.
- **Cramming / over-estimated `S`** is caught by the **next due review** (a crammed cell fails it → `S` contracts), *not* by the drift posterior during the gap (it ages out across long intervals). A high-stakes cell adds an **unscheduled probe** firing with prob `p_probe` (default 0.1) **per due-interval**, *indistinguishable from a scheduled review* (cramming can't time around it), bounding worst-case undetected over-inflation to ~`1/p_probe` intervals.
- **Single-event `S` volatility** is the standard SRS design tradeoff; `§14` calibration of `a,b` corrects systematic over-inflation, and a full `S` step optionally requires **≥2 consecutive** consistent outcomes.
- **Reviews can't starve new learning:** due reviews are capped at `≤ ρ_rev` of the per-tick budget (default 0.5), so the §5.3 coverage floor `f_min` for non-due weak skills is preserved.

### Tests
- `test_interval_expands_after_success` — `t_next` grows by `(1+a)` per consecutive held-out pass; shrinks by `b` after a fail.
- `test_due_before_decay_below_target` — a cell becomes due at `t = −S·ln(r*)`, i.e. *before* predicted retention drops under `r*`.
- `test_interleaving` — no two consecutive due reviews share a skill.
- `test_high_retention_cell_low_priority` — a freshly-reviewed cell (high `R`) is deprioritized vs. a due one (EIG-driven).
- `test_s_min_floor_prevents_flood` — at `ĉ_mastery=0`, `S0=S_min>0` so `t_next>0`; the cell does not flood the due-heap.
- `test_crammed_cell_caught_at_next_review` — an over-estimated-`S` cell fails its next due review and `S` contracts via the lapse rule.
- `test_reviews_dont_starve_coverage_floor` — with many due reviews, the §5.3 `f_min` coverage of a non-due weak skill is preserved (review budget capped at `ρ_rev`).
- `test_probe_bounds_inflation` — the unscheduled probe is indistinguishable from a scheduled review; worst-case over-inflation is bounded ~`1/p_probe`.

### Review notes (review-360 round 1: 68 → round 2: 72 → re-gating)
Round-2 fixed: `p_probe` made precise (per-interval, indistinguishable, `~1/p_probe` inflation bound); the single-event `S` volatility acknowledged as the standard SRS tradeoff (§14-calibrated, optional ≥2-consecutive step); `ĉ_mastery` pinned to `mastery_mean` (slow posterior, not drift); interleave/due-boost defaults; and a **review-budget cap `ρ_rev`** so spaced reviews can't starve the §5.3 coverage floor. The one genuine model risk is that exponential-retention `S` is an assumption; §14 calibration is the safeguard. Depends on §3 + the cache; composes with A1 (EIG deprioritizes well-retained cells).

---

## B1 · Misconception clustering → graph-linked remediation  ▣ APPROVED (review-360 82/100 · change-approver APPROVED)

*Cluster *wrong-answer traces* (not just "wrong") → discover named misconceptions → link to the corrupted prerequisite (graph) → the Tutor selects the remediation Teacher; the held-out gate confirms the fix. The highest-differentiation human-ed app.*

### Mechanism
1. **Embed error traces.** Each incorrect attempt's *error pattern* (the produced answer/working, not just the boolean) is embedded into the `VectorStore`.
2. **Cluster** (reuse §5.1 clustering): a dense, **coherent** cluster of similar errors (≥ `N_min` traces, default 30; intra-cluster cosine ≥ `τ_coh`) is a *candidate* misconception.
3. **Validate — don't reify noise.** A candidate is **admitted as a misconception** only if "learner holds M" **predicts future errors** on M-sensitive held-out items, gated by **`significant(lift − ρ_M, SE_lift)`** where `lift = P(err|M-flagged) − P(err|¬)` on the **§4 held-out split** (`ρ_M` default 0.2), with a **minimum arm size ≥ 20 per side** and the lift-gate `z` relaxed to **1.0** (a small-cohort moderate misconception shouldn't need `lift>0.5`; `§14` calibrates). A bare `lift ≥ ρ_M` would reintroduce RC-1; requiring the lift to clear its own standard error fixes it. A noise cluster fails and is discarded.
4. **Link to graph.** An admitted M attaches to the prerequisite concept it corrupts (a `misconception→prereq` edge in `GraphStore`).
5. **Remediate.** When a learner's error matches M (vector similarity), the Tutor selects the **remediation Teacher** for M (§13 Teacher selection); kept only if the **held-out** error rate on M-items drops (the commit gate §8).
6. **Retire / merge (the inverse — RC-4).** A misconception is **pruned** when its predictive lift decays below `ρ_M` *significantly* over a window (it stopped predicting errors → it's no longer real), and **merged** with a near-duplicate (cosine ≥ `τ_merge`). Same add-with-inverse discipline as §5.1 skills — no add-only ratchet routing learners to a stale remediation forever.

### Plug-point
A `Misconception` component over `VectorStore` (cluster) + `GraphStore` (link) + the Tutor (remediation Teacher) + `EvalHarness` (validate M *and* the remediation). (`mdlp/` — spec only.)

### Parameters
`N_min` cluster size (30) · `τ_coh` coherence · `ρ_M` predictive-lift bar (0.2) · min arm size (20) · lift-gate `z` (1.0) · `τ_merge` duplicate-merge cosine · retirement window (50 evals) · remediation held-out threshold.

### Honest risks
- **Spurious misconceptions** (clustering noise into a "misconception"): gated by `N_min` + coherence + the **predictive-validity bar** — a misconception must forecast future errors, or it isn't one (same discipline as the verifier).
- **Confabulated remediation** (a "fix" that doesn't generalize): gated by the **held-out** error-rate drop — never kept because it *seemed* to help.
- **Over-labeling** (every slip a misconception): `ρ_M` + `N_min` prevent it; one-off errors don't cluster.

### Tests
- `test_recurring_error_clustered_and_named` — a genuine repeated error pattern (≥`N_min`) forms an admitted misconception.
- `test_noise_errors_rejected` — a random/incoherent error set produces **no** admitted misconception (`lift` fails `significant(lift−ρ_M, SE)`).
- `test_stale_misconception_retired` — a misconception whose lift decays below `ρ_M` is pruned; a near-duplicate is merged (no add-only ratchet).
- `test_remediation_kept_only_if_heldout_drops` — a remediation Teacher is committed iff held-out M-item error rate falls past the gate.
- `test_misconception_linked_to_prereq` — an admitted M attaches to the correct prerequisite node.

### Review notes (review-360 round 1: 65 → re-gating)
Round-1 fixed: (1) the lift gate is now **`significant(lift−ρ_M, SE)`** (RC-1, not a bare compare); (2) misconceptions now **retire/merge** (RC-4 inverse — no add-only ratchet). The make-or-break remains **distinguishing a real misconception from clustered noise** — the significance-gated predictive-validity bar, the human analog of verifier admission. Depends on vector + graph + Tutor; gated end-to-end by held-out. Highest user-visible impact; gated on C1's signal existing.

---

## B2 · Prerequisite-gap diagnosis (backward graph walk)  ▣ APPROVED (review-360 83/100 · change-approver APPROVED)

*On repeated failure at skill `S`, walk the prerequisite graph **backward**, use the posterior to find the deepest unmastered prereq — the **root** gap — confirm it, and redirect the Tutor there. Fix the cause, not the symptom.*

### Mechanism
1. **Trigger.** `n_trigger ≥ 3` held-out failures at `S` **or** `significant(θ − ĉ[S], SE)`, with the failures *not* explained by an existing misconception (the §B1 `Misconception` lookup; if B1 is absent, skip that filter).
2. **Backward walk.** BFS over `prereqs(S)` in `GraphStore`; descend a branch while the gap is **significant** — `significant(θ − ĉ_mastery[P], SE[P])` (a *point* `ĉ[P] < θ` reinstates RC-1: thin cold-start posteriors fall below `θ` from sparsity alone). Stop **per branch** at the first significantly-mastered prereq (not a global "layer" — DAG branches have mixed mastery). The deepest significant-gap prereqs on a failing path are the **candidate root gaps**. (Acyclicity + depth-cap `d_max`, §5.1/§5.2.)
3. **Confirm — posterior is not proof.** A significant low `ĉ[P]` is a *candidate*, not the cause; **confirm with targeted held-out items on `P`** before redirecting. But confirmation shows the learner is weak at `P` — it **cannot fully separate a causal gap from a confounded co-weakness** (a latent like general fluency under both `S` and `P`). So treat redirect as a **hypothesis** validated downstream: the **post-redirect outcome check** — did remediating `P` actually raise `ĉ[S]`? — feeds `g.decay_edges()` (§5.1): a `P→S` edge whose remediation didn't help `S`, **measured over `n_post`≥5 held-out attempts on `S` *after* `P` is mastered** (so a valid edge isn't decayed before transfer can manifest), loses confidence and stops being diagnosed. *Confirmation + this feedback loop reduce, but don't eliminate, confounding.*
4. **Redirect.** Add the confirmed root prereq to the Tutor's candidate set; the coverage floor + info-gain (A1) then prioritize it.

### Plug-point
A `Diagnose` component over `GraphStore` (backward walk) + `ProbabilisticState` (posterior) + `EvalHarness` (confirm). (`mdlp/` — spec only.)

### Parameters
`θ` mastery bar (existing §5.2) · `d_max` depth cap (4) · `n_trigger` failures (3) · confirmation items (≥5, power-noted) · `n_post` post-redirect window (5) · `z` (existing).

### Honest risks
- **Wrong-prereq attribution** (correlational / confounded): the **confirmation step** + the **post-redirect outcome feedback** (`g.decay_edges` when remediating `P` doesn't lift `S`) gate it — honestly *reduce*, not eliminate (a hidden common cause can't be ruled out from observation alone).
- **Cycles / dense prereq graphs**: handled by §5.1 acyclicity invariant + `d_max`.
- **Unobservable gap** (no item bank for `P`): fall back to flag for human/Teacher, don't fabricate a diagnosis.

### Tests
- `test_buried_gap_diagnosed` — failing `S` with a deep unmastered `fractions` prereq diagnoses to `fractions`, not `S`.
- `test_no_gap_not_misdiagnosed` — a learner with all prereqs mastered yields **no** gap (the issue is `S` itself, not a prereq).
- `test_confirmation_rejects_spurious_prereq` — a low-`ĉ` prereq that passes its targeted confirmation items is **not** redirected to.
- `test_failed_redirect_decays_edge` — remediating a confirmed prereq that does **not** raise `ĉ[S]` decays the `P→S` edge (so it stops being diagnosed) — the confounding feedback loop.
- `test_depth_cap_and_acyclicity` — the walk terminates under `d_max` and never loops.

### Review notes (review-360 round 1: 68 → re-gating)
Round-1 fixed: (1) descent is **branch-local + `significant(θ−ĉ, SE)`** (not a global layer, not a point compare — RC-1); (2) added the **post-redirect outcome-feedback loop** (`g.decay_edges`) + the honest admission that confirmation *reduces but can't eliminate* causal confounding. The integrity hinge is **confirm before redirect + verify the redirect helped**. Depends on graph + posterior + eval; composes with B1.

---

## B3 · Cross-agent skill transfer / fleet learning (agent-side)  ▣ APPROVED (review-360 82/100 · change-approver APPROVED)

*A skill verified on one agent propagates to others at its frontier. Vector finds the transfer, the recipient's **own held-out verifier** validates it (no blind trust), truth records which transfers stick.*

### Mechanism
1. **Embed skills.** Each agent's skill-library entries are embedded in the `VectorStore`.
2. **Find a transfer.** When agent `B` is genuinely cold on `s` (`B.n_eff[s] < n_transfer`, default 5), retrieve agents with a **verified** skill ≈ `s` (cosine ≥ `sim_bar`, default 0.8). If agent `A` has one, propose copying the skill artifact (+ its verified trajectory data).
3. **Validate on the recipient — inherit zero trust.** **Invariant (enforced):** `Transfer` has **no read path** to `A`'s `StateStore`; it copies only the artifact and re-scores from scratch on `B`. Because `A` and `B` may share an item bank (the common case), validate on **isomorphic variants** — same task structure with freshly sampled operands / context-IDs / surface params, verified by the §4.2 trajectory-shape + counterfactual check — (or `B`-partitioned / rotated held-out items) so `B`'s validation is genuinely *independent* of `A`. Keep iff the **full §8 commit gate** passes on `B` — `significant(Δĉ_secret, SE, margin=ε) ∧ generalize ∧ cumulative ∧ safe` — not merely "competence rises" (a safety-degrading transfer is rejected even if competence rises).
4. **Quarantine + record.** The transferred skill enters `B`'s graph as a **`pending_human`/quarantined** node (§5.1 `provision_suite`) until `B`'s held-out admits it. A `transfer(A.s→B.s)` edge + the outcome go to truth → the fleet learns which transfers generalize (a transfer-success prior, **diversity-weighted MMR-style like A5** so the fleet doesn't converge to a monoculture).

### Plug-point
A `Transfer` component: `propose(B, s) → [Candidate(A, s_A, sim)]` (VectorStore); `apply(candidate) → quarantined skill in B.SkillLibrary`; `validate(B, skill) → §8 gate on isomorphic-variant held-out` (EvalHarness); record to `GraphStore`/`TruthStore`. **No `A.StateStore` read path** (the zero-trust invariant). **Agent-side only** (skills are transferable artifacts; human transfer is out of scope).

### Parameters
`sim_bar` similarity (0.8) · `n_transfer` cold-start trigger (5) · `ε` §8 margin (existing) · MMR `λ_div` (0.5) · transfer-validation held-out threshold.

### Honest risks
- **Negative / safety-degrading transfer:** gated by the **full §8 gate** on `B` (incl. `safe` + cumulative) — keep iff it genuinely *and safely* helps, else discard.
- **Over-transfer** (copying everything): only candidates at `B`'s cold frontier (`n_eff < n_transfer`); cost-bounded.
- **Echo chamber** (the fleet converges to a monoculture): the transfer-success prior is **diversity-weighted** (MMR, as A5).
- **Provenance/safety** (a transferred skill carries `A`'s latent flaws): **re-verify on `B`** with isomorphic variants; the transfer inherits **zero trust** from `A` (enforced — no `A.StateStore` read).

### Tests
- `test_helpful_transfer_kept` — a verified similar-agent skill that passes the full §8 gate on `B` is committed.
- `test_negative_or_unsafe_transfer_rejected` — a transfer failing any §8 clause (incl. `safe`/cumulative) on `B` is discarded.
- `test_transfer_only_when_recipient_cold` — fires only at `B.n_eff[s] < n_transfer`.
- `test_no_source_statestore_read` — `Transfer` never reads `A`'s `StateStore` (zero-trust invariant; static check).
- `test_shared_bank_uses_variants` — when `A,B` share a bank, validation uses isomorphic variants (independence preserved).

### Review notes (review-360 round 1: 65 → re-gating)
Round-1 fixed all six: zero-trust is now an **enforced invariant** (no `A.StateStore` read) + **isomorphic-variant validation** for shared banks; the **full §8 gate** (not just "competence rises"); a **fleet-homogeneity / echo-chamber guard** (MMR-weighted transfer prior); defaults + a precise cold-start trigger; the `Transfer` interface; and **quarantine** of the transferred skill (§5.1). The safety hinge: *re-verify on the recipient, inherit zero trust*. Agent-side; the truth-recorded outcomes make the fleet compound.

---

## E · Store-native levers — disposition (not separately gated)  ▣ COVERED

The register's E levers are realized by the already-approved/specced items; E adds no separate build:
- **Vector — misconception/failure clustering, similar-learner retrieval** → **B1** + **A5**.
- **Graph — prereq-aware skipping / backward gap-walk / realized-path branches** → **B2** + §5.2 + §15.6.
- **State decay + Redis — forgetting-aware spacing** → **B4**.
- **Truth + versioned state — replayable paths, branching** → §15.6.
- The one *distinct* lever, **computerized adaptive testing (CAT)** — pin competence in ~`log N` items by serving the item whose difficulty ≈ current ability — is a **thin specialization of A1**: under IRT, the EIG-maximal item *is* the adaptive-test item, so CAT = A1's info-gain in a high-`w` diagnose phase (§13.1), no new mechanism. *(If a standalone CAT module is later wanted, gate it as an A1 sub-spec.)*

## 🔭 G · Frontier directions — scope decisions (design sketches, not build-gated)

These are **decide-or-defer**, not committed builds, so they are not run through the build-gate; each needs an explicit go decision first.
- **G1 self-modification axis + multi-agent populations** — ▶ **owner go-decision 2026-06-27.** Designed as ALGORITHM-v0.2 **§17** (self-modification behind the SOLVE/JUDGE partition + code two-stage promotion) and **§18** (multi-agent co-evolution on the shared substrate), targeting milestone **M3**. In the review→approve gate. *(Original sketch: `self_modify` as a §6 action gated by held-out commit + reversibility; safety dominates because it edits code — realised as the SOLVE/JUDGE immutability partition.)*
- **G2 task/curriculum generator** (Absolute-Zero / R-Zero style — generate own problems from zero data). Sketch: a Challenger that proposes items at the learner's frontier, gated by the verifier (only verifiable generated items enter). **Decision needed:** is the domain one where novel items can be auto-verified?
- **G3 learned (meta-RL) Tutor policy** — make `π` itself *learned* rather than hand-designed (the survey's named frontier). Sketch: meta-RL over the Tutor's action-selection, rewarded by long-horizon held-out gain. **Decision needed:** this is a research program, not a milestone — defer until A1–B3 are validated.

---

*Done: A1, A5, B4, B1, B2, B3 ▣ all approved (review-360 >80 → change-approver APPROVED) · E ▣ covered · §16 unified retrieval ▣ approved · **G1 self-mod + multi-agent: owner go-decision 2026-06-27 → designed as §17/§18 (M3), in the gate**. Every build cleared the two-stage gate: 360° review → approval.*
