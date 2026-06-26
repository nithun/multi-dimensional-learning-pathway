# Decision: APPROVED — A5-warmstart

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/A5-warmstart-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 87 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 85 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1: the Round-6 overall confidence of 82 clears the > 80 threshold (critical floor min(87, 82, 85) = 82; weighted mean 90.18; overall = min of the two = 82). G2: all three critical-dimension floors exceed 70 by a comfortable margin — Correctness 87, Red-team resistance 82, Safety 85. G3: the six rounds of review resolved every blocking item from prior rounds; the Round-6 report carries zero unresolved blocking or must-fix findings. The check-on-the-checker scan found no buried critical finding contradicting the headline: the "cold-start steering effect" (warm prior multiplicatively suppresses multi-prereq reachability weights at cold-start, potentially by ~95% under a uniformly pessimistic cohort prior) is named in the strongest adversarial objection but is explicitly classified non-blocking by the reviewer, is self-correcting via Bayesian dilution after ~9 own observations, and is architecturally correct behavior of the soft-reachability system. The headline score of 82 is therefore not miscalibrated.

The following advisory (non-blocking) items are carried forward for the implementer's attention:

1. **`k` default value missing (Implementability 4.1):** The `k` parameter for the KNN cohort query has no stated default. Implementation teams should define and document a starting default (the reviewer notes `λ_div=0.5` and mean-pairwise diversity are given; `k` in the range 5–20 is suggested by cost analysis).
2. **Anchor-set administration protocol unspecified (Implementability 4.2):** When, how large, and how item responses are vectorized for the anchor set remain unspecified implementation decisions.
3. **`WarmStart` component interface signature not defined (Implementability 4.3):** The fallback to `(α0,β0)` is stated but the call signature is not given.
4. **`div_floor=0.2` lacks design rationale (Calibration 9):** A sentence of rationale is recommended, particularly for single-institution (highly homogeneous cohort) deployments.
5. **"Highest-ROI human-ed speed win" claim ungrounded (Calibration 9):** Partially mitigated by the explicit "Validate, don't assume" caveat in the spec; empirical grounding remains recommended before any public claim.
6. **Cold-start steering effect (Adversarial objection):** The warm prior's effect on `reach_weight` at cold-start is a 2.6–1.6x per-prereq magnitude shift, compounding multiplicatively. A learner from a weak cohort with a three-prereq skill chain could see initial reachability weight drop ~95%. This is correct probabilistic behavior and is self-correcting, but warrants an explicit note in the mechanism section of the implementation documentation.
7. **`n_own=35` boundary (Correctness residual):** "Within 0.10" covers `<= 0.10`; if a strict `< 0.10` bound is ever required, `n_own >= 36` is the correct threshold.

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`A5-warmstart-review.md` to be committed. The change-approver does not apply the
edit; the committing agent or user must reference this record when creating the commit.
