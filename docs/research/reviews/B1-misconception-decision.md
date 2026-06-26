# Decision: APPROVED — B1-misconception

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/B1-misconception-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 87 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 86 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1: overall confidence is 82, clearing the >80 threshold. G2: all three critical dimensions clear their floors — Correctness 87, Red-team resistance 82, Safety 86, all well above 70. G3: the review explicitly confirms all three round-2 blocking items are resolved (arm-size floor >= 20 per side, lift estimated on the §4 held-out split, retirement window defaulted to 50 evals), and no finding in the body carries a blocking, must-fix, or HIGH-severity tag. Check-on-the-checker: the single structural adversarial objection (low-prevalence admission latency — the 4–10× delay for base error rates < 15%) is affirmatively characterized by the reviewer as "not a correctness error" and "does not block approval at this stage." There is no critical finding buried under a passing headline. The implementer should treat the seven non-blocking items below as a prioritized pre-implementation checklist, particularly items 1, 2, 3, and 5, which address the most consequential spec gaps (τ_merge scope, below-floor behavior, low-prevalence latency acknowledgment, and §14 deployment dependency).

## Next step

**Authorized for commit.** This decision record authorizes the B1 misconception clustering → graph-linked remediation change described in `B1-misconception-review.md` (round 3, targeting `docs/research/BUILD-SPECS.md` §"B1 · Misconception clustering → graph-linked remediation") to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

**Advisory items (non-blocking — address before or during implementation):**

1. State whether `τ_merge` in step 6 is the §5.1 global parameter or a B1-specific one (one sentence; e.g., "B1-specific `τ_merge_M`, default 0.9").
2. Specify below-floor behavior: what happens to a candidate misconception with >= N_min cluster traces but < 20 M-flagged learners (recommend: "accumulate until arm-size floor is met; misconception remains candidate-pending, not active").
3. Add the low-prevalence admission latency to "Honest risks": at base error rates < 15%, the arm-size floor delays admission 4–10× relative to cluster formation; consider a provisional remediation flag for high-coherence pre-statistical clusters.
4. Default `τ_coh` explicitly (e.g., mean pairwise cosine >= 0.75).
5. Note §14 calibration as a stated deployment dependency of the z=1.0 relaxation.
6. Extend `DATA-LAYER.md` §5 Graph schema to include a `misconception{prereq_ref, admitted_ts, lift, n_m_flagged}` edge type.
7. Add `test_lift_gate_marginal_high_se_rejected` — verify that a cluster with nominal lift >= ρ_M but SE_lift > (lift − ρ_M) fails admission.
