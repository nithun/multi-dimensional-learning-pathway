# 360 Review: A5-warmstart — 2026-06-26

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` §"A5 · Warm-start from 'learners like you'" (lines 62–107) |
| Proposed change | Add warm-start initialization of the competence prior from a vector-similar learner cohort, replacing the fixed `Beta(α0,β0)` cold-start with an empirical-Bayes prior derived from k-nearest neighbours. |
| Reviewer | review-360 |
| Date | 2026-06-26 |
| Round | **6 (final re-review)** — supersedes Rounds 1–5 below |

---

## Round-1 scores (for traceability — superseded)

| # | Dimension | R1 Score | R1 Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 72 | weak |
| 2 | Design faithfulness | 82 | pass |
| 3 | Red-team resistance (CRITICAL) | 58 | blocking |
| 4 | Implementability | 60 | weak |
| 5 | Safety / integrity (CRITICAL) | 72 | weak |
| 6 | Efficiency / cost | 75 | pass |
| 7 | Completeness | 55 | blocking |
| 8 | Consistency | 80 | pass |
| 9 | Calibration / honesty | 68 | weak |

**Round-1 overall: 58 / 100 — needs-revision**

Round-1 blocking issues: (1) embedding-level filter-bubble (RC-7); (2) degenerate `Beta(0,n)` when `μ_knn ∈ {0,1}`; (3) influence-decay undefined.

---

## Round-2 scores (for traceability — superseded)

| # | Dimension | R2 Score | R2 Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 82 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 72 | pass |
| 4 | Implementability | 68 | weak |
| 5 | Safety / integrity (CRITICAL) | 78 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 70 | pass |
| 8 | Consistency | 78 | pass |
| 9 | Calibration / honesty | 74 | pass |

**Round-2 overall: 72 / 100 — needs-revision**

Round-2 blocking issues: (1) diversity-filter algorithm not specified — "enforce spread" named but no algorithm given; (2) `test_divergent_learner_not_imprisoned` lacked a numeric bound.

---

## Round-3 scores (for traceability — superseded)

| # | Dimension | R3 Score | R3 Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 68 | blocking |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 76 | pass |
| 4 | Implementability | 72 | pass |
| 5 | Safety / integrity (CRITICAL) | 78 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 71 | pass |
| 8 | Consistency | 72 | pass |
| 9 | Calibration / honesty | 68 | blocking |

**Round-3 overall: 68 / 100 — needs-revision**

Round-3 blocking issues: (1) convergence bound "within 0.10 after 27 obs" was arithmetically wrong — actual error at n_own=27 is 4/32=0.125, requiring n_own=35 for the 0.10 threshold; (2) homogeneous-cohort down-weighting formula unspecified ("scaled by neighbour-set diversity" named but not defined); (3) internal inconsistency between floor-free and floor-inclusive weight formulas in adjacent tests.

---

## Round-4 scores (for traceability — superseded)

| # | Dimension | R4 Score | R4 Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 76 | pass |
| 5 | Safety / integrity (CRITICAL) | 78 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 74 | pass |
| 8 | Consistency | 80 | pass |
| 9 | Calibration / honesty | 76 | pass |

**Round-4 overall: 78 / 100 — needs-revision**

Round-4 targeted gaps (the two required changes to clear 80):
1. Safety: "never gate-keep" was an intent statement without enforcement — no mechanism or invariant prevented a system integrator from using warm prior as a gate-keep condition.
2. Completeness: `test_mmr_diversity_filter` was absent — the primary RC-7 mitigation surface had no direct regression test.

---

## Round-5 scores (for traceability — superseded)

| # | Dimension | R5 Score | R5 Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 76 | pass |
| 5 | Safety / integrity (CRITICAL) | 83 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 80 | pass |
| 8 | Consistency | 80 | pass |
| 9 | Calibration / honesty | 77 | pass |

**Round-5 overall: 80 / 100 — ready-for-approval**

Round-5 adversarial objection (the item to resolve in Round 6): `test_warmstart_never_gatekeeps` used a "byte-identical" requirement for candidate-set and reachability values, but the warm prior legitimately shifts `(α,β)`, which feeds into `reach_weight()` — making byte-identical weights impossible in any correct implementation. The test as stated was unpassable. The resolution required narrowing the claim to set membership (which skills appear) rather than value identity (what weights they carry).

---

## Round-6 dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 87 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 77 | pass |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 77 | pass |
| 7 | Completeness | 83 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 79 | pass |

---

## Round-6 findings by dimension

### 1. Correctness (CRITICAL)

**Score: 87 — pass (raised from 85)**

The Round-5 adversarial objection on `test_warmstart_never_gatekeeps` is resolved correctly and the correction adds one new arithmetic consistency. All prior arithmetic remains verified correct.

**Round-6 primary item: the byte-identical correction (BUILD-SPECS.md line 99)**

The corrected test now reads: "`WarmStart` affects only `cell()`'s prior; the **candidate set and admission decisions** (which skills are reachable/admitted) are identical with and without it. *(Soft `reach_weight` values legitimately shift because the prior shifts `(α,β)` — only set membership must be invariant: it seeds, never blocks.)*"

This correction is arithmetically correct and mechanically consistent. Verified numerically: at `θ=0.5` and defaults `(α0,β0)=(1,1)`, `n_eff_warm=3`:
- Cold prior `Beta(1,1)`: `P(mastery ≥ θ) ≈ 0.500`
- Warm prior at `μ_knn=0.2`, `Beta(1.6,3.4)`: `P(mastery ≥ θ) ≈ 0.187`
- Warm prior at `μ_knn=0.8`, `Beta(3.4,1.6)`: `P(mastery ≥ θ) ≈ 0.813`

All three values are in `(0,1)`. Under soft reachability (`reach_weight = ∏ P(prereq mastered)`), `reach_weight` is never exactly 0 for any admitted skill; all admitted skills remain in the candidate set regardless of warm prior. The set membership invariant holds mechanically, not just by intent. The old byte-identical claim was unpassable; the new set membership claim is passable under the soft-reachability architecture.

**All prior arithmetic re-verified (unchanged):**
- Convergence error `= 4/(5+n_own)`: `4/32 = 0.125` at `n_own=27`; `4/40 = 0.10` at `n_own=35`. Both match spec lines 101. Verified derivation: worst case `μ_knn=0`, warm prior `Beta(1,4)`, after `n_own` own successes: posterior mean `= (1+n_own)/(5+n_own)`, error `= 1 − (1+n_own)/(5+n_own) = 4/(5+n_own)`.
- Warm-prior weight `3/(5+n_own)`: at `n_own=9`: `3/14 ≈ 21.4%`; at `n_own=27`: `3/32 ≈ 9.4%`. Matches spec line 95. Denominator `5 = α0+β0+n_eff_warm = 1+1+3` confirmed.
- Error vs. weight distinction (line 101): `β0+n_eff_warm = 4 ≠ n_eff_warm = 3`. Correct and explicit.
- MMR formula (line 67): `sim(new,query) − λ_div · max_sim(new, already-selected)`. This is a valid parametrization where relevance weight is implicitly 1.0 and `λ_div` scales the diversity penalty independently. Non-standard but mathematically sound; the standard form `λ·sim − (1−λ)·max_sim` is a special case with a sum-to-one constraint the spec does not impose. This is a legitimate design choice, not an error.
- `n_eff_warm_eff = n_eff_warm · max(div, div_floor)` at `div→0`: `3 × 0.2 = 0.6` effective pseudo-counts. Confirmed weak prior.

**Residual minor (non-blocking, carried from Round 5):** At `n_own=35`, error is exactly `= 0.10` (not strictly less). "Within 0.10" covers `≤`. If a strict `< 0.10` bound is ever required, `n_own ≥ 36` is the threshold.

---

### 2. Design faithfulness

**Score: 84 — pass (unchanged from Rounds 2–5)**

The warm-start seeding at `ProbabilisticState.cell()` initialization remains consistent with §3's cold-start invariant: "every new `(s,d)` cell born `Beta(α0,β0)`; never undefined" (ALGORITHM-v0.2 line 67). A5 extends this, it does not replace it — the `(α0,β0)` floor is present in every warm-prior formula.

The `test_warmstart_never_gatekeeps` correction strengthens design faithfulness: the test now explicitly acknowledges that `reach_weight` values shift (consistent with §5.2's soft-reachability formula, which reads live cell posteriors) while asserting only set membership invariance (consistent with the soft-reachability property that `reach_weight > 0` for all admitted skills). No divergence from §§2–15 layering or naming conventions.

---

### 3. Red-team resistance (CRITICAL)

**Score: 82 — pass (raised from 80)**

The correction to `test_warmstart_never_gatekeeps` removes a potential adversarial path that was latent in the Round-5 spec: if a developer implemented the byte-identical test literally, discovered it was impossible to pass, and then weakened or removed the test rather than understanding why, the gatekeep invariant's enforcement would have silently degraded. The corrected test is passable, so it will actually be implemented and will run in CI.

**RC-7 coverage (unchanged and complete):**
- Filter-bubble via trajectory embedding: defused by policy-invariant anchor-set item-response embedding (line 67).
- Population-level homogeneous-cohort bubble: addressed by `n_eff_warm_eff = n_eff_warm · max(div, div_floor)` (line 67). At `div→0`: effective warm strength = 0.6 pseudo-counts vs. 3 at full strength. A 5× reduction.
- Gate-keep via warm prior: the three-layer enforcement (architectural invariant at line 80, static-check acceptance criterion at line 80, behavioral test at line 99) prevents conversion of the warm prior into a reachability gate. The behavioral test is now passable, making the enforcement real rather than nominal.

**Residual RC-7 risk (acknowledged, non-blocking):** The anchor-item set itself could exhibit demographic skew. Named in honest-risks (line 87). Requires human audit; not a structural gap.

**No new root causes introduced.** RC-1 through RC-8 residual coverage is unchanged.

---

### 4. Implementability

**Score: 77 — pass (raised from 76 by one point for test passability)**

The correction to `test_warmstart_never_gatekeeps` is a direct implementability improvement: the previous byte-identical requirement would have caused an implementation team to write a test, watch it fail, and either report a spec bug or silently weaken the test. The corrected test provides clear, achievable guidance: verify same skill IDs (set membership), allow weight differences.

**Remaining non-blocking gaps (carried from Rounds 4–5):**

- **4.1 — `k` default missing (line 83).** `k` is listed as a parameter without a default value. Combined with `λ_div=0.5` and mean-pairwise diversity computation, a developer cannot determine a starting `k` without tuning.
- **4.2 — Anchor-set administration protocol unspecified.** When the anchor set is administered, its size, and how item responses are vectorized remain unspecified.
- **4.3 — `WarmStart` component interface signature not defined.** The fallback to `(α0,β0)` (line 78) is stated but the call signature is not given.

The static-check acceptance criterion (line 80) adds one concrete CI requirement: a reference-graph check that `WarmStart` is called only from `cell()`. This remains a positive.

---

### 5. Safety / integrity (CRITICAL)

**Score: 85 — pass (raised from 83)**

The Round-5 three-layer enforcement of the gatekeep invariant remains fully intact:
- **Layer 1 (Structural):** Architectural invariant at line 80 — `WarmStart` has no path to `reachable`/`admit`/the candidate set in `choose`.
- **Layer 2 (Build-time):** Static-check acceptance criterion at line 80 — build fails if `WarmStart` referenced outside `cell()`'s prior.
- **Layer 3 (Runtime):** `test_warmstart_never_gatekeeps` at line 99 — behavioral verification.

The correction to Layer 3 strengthens it by making the test passable. A test that cannot be passed is not enforced — it would either be marked `xfail`, removed, or worked around. The corrected test ("candidate set and admission decisions are identical — soft `reach_weight` values may legitimately shift") is achievable under the soft-reachability architecture and will actually run as a regression. This removes a subtle erosion path from the Round-5 spec.

**One additional observation (non-blocking):** The spec now explicitly states that `reach_weight` values legitimately shift with warm-start (line 99 parenthetical). This is an honest acknowledgment that the warm prior has a downstream effect on action scoring magnitude (U(a) in A1 is reach-weight-sensitive). The effect is bounded: at cold-start, with default `n_eff_warm=3`, the warm prior contributes at most 3/5 of the initial posterior. After 9 own observations it is below 22% of the posterior weight and decaying. The downstream scoring effect is real but bounded and self-correcting — no new safety concern.

No existing gates are weakened. The `(α0,β0)` floor, §14 calibration, held-out verifier, Bayesian dilution, and cumulative gate are all unchanged.

---

### 6. Efficiency / cost

**Score: 77 — pass (raised from 76 by one point)**

The Round-6 change is text-only (no new computational steps). The correction to the test description adds no runtime cost. The one-point increase reflects that the test is now implementable without requiring an impossible bit-exact comparison; simpler set-membership checks (e.g., `set(candidates_with_warmstart) == set(candidates_without)`) are cheaper than any byte-comparison that would require suppressing all floating-point updates.

MMR (O(k²)) and mean-pairwise diversity (O(k²)) remain the only non-trivial cost additions, both at cold-start initialization. For expected `k` in range 5–20, these are negligible relative to the vector query cost.

---

### 7. Completeness

**Score: 83 — pass (raised from 80)**

The corrected `test_warmstart_never_gatekeeps` (line 99) now tests a precisely specified and achievable claim. The test suite (10 tests total) is internally complete:

1. `test_warmstart_tightens_cold_start` — posterior SD reduction from confident cohort.
2. `test_warmstart_overridden_by_own_data` — own observations override cohort.
3. `test_warm_prior_never_degenerate` — boundary guard at `μ_knn ∈ {0,1}`.
4. `test_influence_dilutes_as_specified` — Bayesian weight dilution formula.
5. `test_homogeneous_cohort_downweights` — `div→0` → weak prior via `div_floor`.
6. `test_embedding_is_policy_invariant` — anchor-set embedding unchanged under different selection policy.
7. `test_mmr_diversity_filter` — MMR returns more diverse set than plain top-k.
8. `test_warmstart_never_gatekeeps` — set membership (not weights) invariant.
9. `test_warmstart_falls_back_to_flat` — no neighbours → exact `(α0,β0)`.
10. `test_divergent_learner_not_imprisoned` — quantitative convergence bound.

The correction to test 8 makes its intended scope internally consistent with test 4 (`test_influence_dilutes_as_specified`) and test 10 (`test_divergent_learner_not_imprisoned`): both of those tests implicitly allow weight shifts as the warm prior dilutes — and now the gatekeep test no longer contradicts them by asserting byte-identical weights.

**Remaining non-blocking gaps (carried from Rounds 4–5):** `k` default missing (Implementability 4.1); anchor-set administration protocol (Implementability 4.2); `WarmStart` call signature (Implementability 4.3).

---

### 8. Consistency

**Score: 84 — pass (raised from 80)**

The correction to `test_warmstart_never_gatekeeps` adds internal consistency that was missing in Round 5. The Round-5 spec had a tension: it explicitly said the warm prior "shifts `(α,β)`" (mechanism section, line 67), but the test claimed byte-identical state — these two claims were contradictory. Round 6 resolves this by explicitly acknowledging in the test itself that "soft `reach_weight` values legitimately shift."

The corrected test is now consistent with:
- §5.2 of ALGORITHM-v0.2: `reach_weight(s, n) = ∏ P(mastery[p] ≥ θ)` reads live cell posteriors — shifting `(α,β)` does shift this value.
- §3 of ALGORITHM-v0.2: the Beta posterior is updated from observations — the initial prior is part of the cell state.
- Line 74 of BUILD-SPECS.md: "the warm prior's relative weight is `n_eff_warm/(α0+β0+n_eff_warm+n_own)`" — explicitly allows weight shifts.
- The architectural invariant at line 80: "`WarmStart` writes only the cell's initial `(α,β)` prior" — the cell IS read by `reach_weight`, and this is now acknowledged rather than suppressed.

No contradiction between any pairs of claims found in the Round-6 spec.

---

### 9. Calibration / honesty

**Score: 79 — pass (raised from 77)**

The correction to `test_warmstart_never_gatekeeps` is an act of honest calibration: the spec previously overclaimed (byte-identical) and Round 6 corrects to the accurate achievable claim (set membership). This is precisely the kind of correction this dimension rewards — adjusting a claim to match what the mechanism can actually guarantee.

The explicit parenthetical at line 99 — "*(Soft `reach_weight` values legitimately shift because the prior shifts `(α,β)` — only set membership must be invariant: it seeds, never blocks.)*" — is a clear, honest statement of what the invariant guarantees and what it does not. This is stronger calibration than any silence or vague qualification would be.

**Remaining non-blocking gap (carried from Rounds 4–5):** `div_floor=0.2` still lacks a design rationale. A practitioner deploying in a highly homogeneous cohort (e.g., single-institution deployment) cannot determine whether 0.2 is conservative enough without empirical guidance. The "lean on monitoring + §14 calibration" note is honest but incomplete. One sentence of rationale remains recommended.

The "highest-ROI human-ed speed win" claim (line 106) remains without empirical grounding, partially mitigated by the explicit "Validate, don't assume" caveat (line 89).

---

## Strongest adversarial objection

**The warm prior affects `reach_weight` at cold-start by a large magnitude — potentially 3× or more — and this effect is now explicitly acknowledged in the spec rather than suppressed. This creates a new honest admission that deserves scrutiny: the warm prior's effect on soft reachability is not cosmetic.**

Numerically verified above: at `θ=0.5`, the shift from `Beta(1,1)` to `Beta(1.6,3.4)` (low-cohort warm prior) moves `P(mastery ≥ θ)` from ~0.50 to ~0.19 — a 2.6× reduction. At `Beta(3.4,1.6)` (high-cohort warm prior) it rises to ~0.81 — a 1.6× increase. These shifts compound multiplicatively across prereq chains: a cell with three prereqs could see its `reach_weight` change by a factor of `(0.19/0.50)³ ≈ 0.055` under a uniformly pessimistic warm prior. This means that at cold-start, a learner whose cohort was uniformly low-performing could see a three-prereq skill's initial reachability weight drop by ~95% — which, while not removing the skill from the candidate set, effectively de-prioritizes it in the A1 utility scoring (`U(a) = ... + reach_weight(cell) * EIG_cell`).

The invariant ("seeds, never blocks") is technically satisfied: the skill remains in the candidate set with nonzero weight. But the practical effect at cold-start, before any own observations, is significant suppression of reachability for skills with long prereq chains when the warm prior is pessimistic. This is not a structural failure — it is the correct behavior of a probabilistic system — but it is a stronger effect than the spec's framing ("a tighter, better-located starting belief") fully conveys. A cold-start learner from a weak cohort will initially be steered away from skills requiring multiple mastered prereqs, not merely "started at a better location."

This is not new behavior (the warm prior has always shifted `(α,β)` and `reach_weight` has always consumed it), but the Round-6 explicit acknowledgment of the shift makes this the right round to name it. The spec's mitigation is correct: the Bayesian dilution (`3/(5+n_own)`) means that after 9 own observations the warm prior contributes below 22% and the effect is self-correcting. No revision is required — but the "cold-start steering effect" is the honest framing of the mechanism's action, and it would benefit from an explicit note in the mechanism section.

No objection was found that rises to blocking level. The above is the strongest remaining concern not already surfaced in the nine dimensions.

---

## Aggregate confidence

```
critical_floor  = min(score_Correctness, score_RedTeam, score_Safety)
                = min(87, 82, 85)
                = 82

weighted_mean   = (score_Correctness * 2 + score_DesignFaithfulness + score_RedTeam * 2
                   + score_Implementability + score_Safety * 2 + score_Efficiency
                   + score_Completeness + score_Consistency + score_Calibration) / 11
                = (87*2 + 84 + 82*2 + 77 + 85*2 + 77 + 83 + 84 + 79) / 11
                = (174 + 84 + 164 + 77 + 170 + 77 + 83 + 84 + 79) / 11
                = 992 / 11
                = 90.18

overall         = min(82, 90.18) = 82
```

**Overall confidence: 82 / 100**

---

## Verdict

**ready-for-approval**

Round 6 resolves the single remaining non-blocking item from Round 5: the `test_warmstart_never_gatekeeps` "byte-identical" claim was too strong (the warm prior legitimately shifts `(α,β)`, so `reach_weight` values shift). The test is corrected to require only that the **candidate set and admission decisions** (set membership) are identical with and without WarmStart — the soft `reach_weight` values may shift, since WarmStart seeds, never blocks.

The correction is mechanically sound: under soft reachability (`reach_weight = ∏ P(prereq mastered) > 0` for all admitted skills), no skill is removed from the candidate set by a warm prior shift. Set membership invariance holds by construction from the soft-reachability architecture. The corrected test is passable and will function as a genuine regression.

All three CRITICAL dimensions exceed 70 (Correctness 87, Red-team resistance 82, Safety 85). The overall score rises from 80 to 82 — the critical floor now sits at 82, two points above the threshold, providing a small buffer against implementation-phase scoring adjustments.

The adversarial objection identifies a "cold-start steering effect" from warm prior shifts on multi-prereq reachability chains, which is not a structural flaw but warrants honest documentation in the implementation. This is a note for the implementation phase, not a spec blocker.
