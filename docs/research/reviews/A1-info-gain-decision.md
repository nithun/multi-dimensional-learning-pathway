# Decision: REJECTED — A1-info-gain

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/A1-info-gain-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 78 | > 80 | FAIL |
| G2: Correctness floor | Correctness score | 78 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 85 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 6 | 0 | FAIL |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: REJECTED

**Rationale:**
Two independent gates fail. **G1** fails because review-360's overall confidence is **78**, below the **> 80** threshold; the aggregate is pulled down by the critical Correctness floor (`overall = min(critical_floor 78, weighted_mean 89) = 78`). **G3** fails because the review enumerates **six unresolved blocking changes** required "to clear 80," none of which are resolved: (1) the digamma "6-term series" is numerically wrong in the operating regime (err ≈ 1.6e-2 at α=1, ≈ 80 at α=0.5) and is not implementable as written without the recurrence-then-asymptotic shift; (2) the peak/zero claim and `test_eig_zero_at_mastery` are mis-specified — EIG → 0 is driven by n_eff concentration, not by ĉ, so the test fails as written; (3) the `w` schedule is under-specified and un-gated — `u_ref` has no default/bound, `mean_frontier_uncertainty`'s estimator is unspecified, and there is no degraded-mode fallback when §14 calibration is stale; (4) the §3.3/§3.6 cross-references point to non-existent subsections (correct homes are §5.2/§5.3); (5) the multi-cell additivity caveat is unaddressed — summing marginal per-cell EIGs over prereq-/hierarchically-tied cells over-values broad sweeps; (6) the uncertainty-chaser dynamic is unacknowledged — `argmax EIG` preferentially picks least-evidenced cells, not true-frontier cells, when candidate n_eff differs. G2's three critical floors all pass (≥ 70), and the check-on-the-checker finds no contradiction — the headline 78 with a "needs-revision" verdict is internally consistent, so no miscalibration override is triggered. The core math (closed-form Beta entropy and one-step EIG, verified to ~1e-10) is sound and the design respects RC-1 and dissolves the λ/μ knife-edge; this is a revision, not a rejection of the approach.

## Next step

**Return for revision.** Required changes before re-review:
1. Fix the digamma specification (`BUILD-SPECS.md:31`): state the recurrence-then-asymptotic recipe (`ψ(x)=ψ(x+1)−1/x` until x≳6, then the 6-term tail) or point to a vetted lgamma-derivative implementation; add `test_digamma_accuracy` over α ∈ {0.5,1,2,5}. *(G3 blocker 1 — Correctness/Implementability/Completeness)*
2. Restate the peak/zero claim and its test in terms of n_eff/SE, not ĉ (`BUILD-SPECS.md:29,33,49`); rewrite `test_eig_zero_at_mastery` to sweep n_eff. *(G3 blocker 2 — Correctness/Calibration)*
3. Fully specify and gate the `w` schedule (`BUILD-SPECS.md:37–39`): give `u_ref` a default and bound (natural range (0, ~0.35]); define the `mean_frontier_uncertainty` estimator (cell set, weighting, §3 `u=Beta_sd`); state degraded-mode behaviour when §14 calibration is stale; add a `w`-stability test. *(G3 blocker 3 — Implementability/Safety/Completeness)*
4. Fix the cross-references (`BUILD-SPECS.md:19,31`): cite §5.3 for z-score normalization and §5.2 `reach_weight(s,n)` for reachability. *(G3 blocker 4 — Design faithfulness/Consistency)*
5. Address the multi-cell additivity caveat (`BUILD-SPECS.md:31`): justify summing marginal per-cell EIGs given §3's prereq/hierarchical ties, or down-weight the sum; add `test_eig_multicell_aggregation`. *(G3 blocker 5 — Correctness/Completeness)*
6. Acknowledge and guard the uncertainty-chaser dynamic: constrain pure-EIG selection to comparable-n_eff candidates, or document/guard that the coverage floor does not bound EIG's pull toward thin cells. *(G3 blocker 6 — Red-team resistance/Completeness)*

Re-submit to review-360 once all required changes are addressed, then re-spawn change-approver with the updated review report.
