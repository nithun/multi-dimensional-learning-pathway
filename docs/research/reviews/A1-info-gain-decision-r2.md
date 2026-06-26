# Decision: APPROVED — A1-info-gain

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/A1-info-gain-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 85 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 85 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 85 | >= 70 | PASS |
| G2: Safety floor | Safety score | 85 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass and the check-on-the-checker finds no miscalibration. G1: the round-2 overall confidence of 85 clears the > 80 threshold (computed as min(critical_floor 85, weighted_mean 93.7) = 85). G2: all three critical-dimension floors — Correctness 85, Red-team resistance 85, Safety 85 — clear the >= 70 floor. G3: all six round-1 blockers carry explicit "Status: RESOLVED" verdicts in the review body, and the five remaining items are each explicitly labeled non-blocking by review-360. Check-on-the-checker: a full scan of the findings body found no item tagged critical, blocking, or must-fix; the strongest adversarial objection (w-schedule degradation under calibration failure) is explicitly concluded "does not by itself prevent approval"; no critical finding contradicts the 85 headline score. The review is not miscalibrated.

**Advisory items for the implementer (non-blocking — no re-review required):**

1. Add `test_digamma_accuracy`: pin ψ accuracy at α ∈ {0.5, 1, 2, 5} against NIST references. Correct the spec's "~1e-12" accuracy claim to "~1e-9" (recurrence-to-6 + 6-term series), or shift the recurrence threshold to x≥8 to genuinely achieve ~1e-12 if that precision is needed. A developer writing a unit test against the stated tolerance will get a spurious failure at ~1e-9. *(Correctness minor / Completeness)*
2. Add `test_eig_multicell_aggregation`: verify the chosen aggregation (max or correlation-discounted sum) is sub-additive for a pair of prereq-linked cells and is consistent with §5.2 reach_weight. *(Completeness)*
3. Add `test_w_schedule_monotone`: verify w rises monotonically with mean_frontier_uncertainty and clips correctly at 0 and 1. *(Completeness)*
4. Document degraded-mode behavior for `w` when §14 calibration is stale — e.g., "fall back to w=0.5 or pure advance-only until the calibration breaker resets." The current spec names the §14 breaker as the guard but does not bound the window of risk before the breaker trips. *(Safety residual — bounded, not permanent)*
5. If the correlation-discounted sum path is chosen over max for multi-cell aggregation, specify the discount formula before implementation. Max is fully defined and safe as a default. *(Implementability residual)*

## Next step

**Authorized for commit.** This decision record authorizes the change described in `A1-info-gain-review.md` (round-2) to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record (`docs/research/reviews/A1-info-gain-decision-r2.md`) when creating the commit.
