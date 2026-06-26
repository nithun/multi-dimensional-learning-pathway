# Decision: APPROVED — B4-spacing

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/B4-spacing-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 85 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 82 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1: the aggregate confidence of 82 (computed as `min(critical_floor=82, weighted_mean=89.73)`) clears the 80 threshold. G2: all three critical-dimension floors clear 70 comfortably — Correctness 85, Red-team resistance 82, Safety 82. G3: all five round-2 blockers (`p_probe` scope, S-volatility acknowledgment, `ĉ_mastery` pinning, interleave/due-boost defaults, `ρ_rev` budget cap) are verified resolved; the four items carried forward in the review verdict are explicitly classified as non-blocking implementation-phase recommendations. Check-on-the-checker: the single strongest adversarial objection (S-update persistence through a §8 commit rollback) is examined at length in the "Strongest adversarial objection" section and in Safety dimension findings, but the review explicitly classifies it as a non-blocking correctness-under-rollback issue requiring a one-line clarification at the plug-point — not a blocker. No item in the findings body is tagged blocking, must-fix, or severity HIGH in a way that contradicts the 82 headline score. The review is well-calibrated.

The implementer should note the following advisory items before coding:

1. **[Safety / Completeness]** Specify where S is stored relative to the commit/rollback boundary — either "S stored in `StateStore.cell` and rolls back with the mastery posterior" or "S updates fire only after the §8 gate passes." One line at the plug-point closes the strongest remaining adversarial angle.
2. **[Correctness / Completeness]** Add `r*` input validation: assert `0 < r* < 1`; `r*=1` produces `t_next=0` (permanent-due flood); `r*=0` produces `t_next=+∞` (cell never reviewed).
3. **[Completeness]** Scope `test_probe_bounds_inflation` to assert expected undetected crammed intervals <= `1/p_probe` (the stated interval-count bound), not that S magnitude is bounded to `1/p_probe × initial`.
4. **[Calibration]** Consider making the ≥2-consecutive step the default or adding guidance on when to enable it; at defaults (a=1.0) it reduces worst-case S inflation from 1024× to 32× after 10 passes, which is significant for high-stakes or cramming-prone cells.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `B4-spacing-review.md` (round 3) — specifically the revised `## B4 · Forgetting-aware spacing` section of `docs/research/BUILD-SPECS.md` (lines 110–143) — to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit. Advisory items 1–4 above should be addressed during implementation, not as a condition of commit.
