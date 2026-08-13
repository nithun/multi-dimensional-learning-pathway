# Decision: APPROVED — S20-10-learning-liveness

**Date:** 2026-08-13
**Approver:** change-approver
**Review source:** docs/research/reviews/S20-10-learning-liveness-review-r5.md (round 5 of 5; priors: r1 70, r2 76, r3 66, r4 78)

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 83 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 83 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 87 | >= 70 | PASS |
| G2: Safety floor | Safety score | 90 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:** All three gates pass on r5's own numbers. G1: overall confidence 83 clears the >80 bar. G2: all three CRITICAL dimensions clear their 70 floor with margin (Correctness 83, Red-team resistance 87, Safety 90); the two dimensions scored "weak" in r5 (Implementability 78, Consistency 75) and the low Calibration score (69) are not gating dimensions under this policy and do not block approval on their own. G3: r5's verdict is explicit — "ready-for-approval," zero blocking items; the round's single flagged item (line 668's stale §2.1 citation, disagreeing with the corrected §5 citation at line 659) was named "not blocking this verdict but recommended as a trivial pre-implementation cleanup," i.e. advisory, not a blocker. Check-on-the-checker: scanning r5's findings body (not just the summary table) for anything tagged critical/blocking/must-fix/severity>=HIGH — none is present. The only recurring theme across all nine dimension write-ups is the same single non-blocking citation defect, explicitly and repeatedly classified as advisory by the reviewer itself; there is no critical/blocking finding coexisting with a >80 score, so no miscalibration override applies.

**Post-review disposition verified (not a re-review).** Per the caller's brief, I independently confirmed both of r5's non-blocking advisory items were subsequently addressed exactly as specified, before finalizing this decision:
1. **Line 668 citation.** A grep of `docs/research/ALGORITHM-v0.2-pathway-learner.md` for `§2.1` and `EvalResult` returns zero matches anywhere in the file. Direct read of the current line 668 confirms it now reads "...the DL §5 truth-schema fields as defined today, no new record kind or field..." — matching line 659's citation nine lines above it. The internal §5-vs-§2.1 contradiction r5 flagged (Correctness, Consistency, Calibration, Implementability findings) no longer exists in the artifact as it stands.
2. **Zero-held-out-rows edge case.** Direct read confirms the behavior is now stated in both places r5's Implementability finding said it was missing: the mechanics paragraph (line 659) — "A cell with zero held-out rows in the window computes no rate (no-data, never a breach — absence of evidence routes to the evidence signal, not this one)" — and the test description (line 668) — "a cell with zero held-out rows in `w_live` reports no-data — never a rate, never a breach."

Both fixes are exactly what r5 specified, and both are the *only* residual items r5 flagged (advisory, non-blocking) across five rounds. Their resolution does not change this gate evaluation's outcome (r5 already cleared all three gates without them), but it does close the last named gap and removes the one recurring defect class (a citation not supporting what it's cited for, and its downstream internal contradiction) that every one of the five rounds' reviews independently rediscovered in a different location. No new finding was introduced by this verification — it is confirmatory, not a re-review, per the caller's framing.

**On the five-round history and Calibration 69.** The flagship absorbed-rate-derivability claim was advanced too confidently in r2/r3, correctly rejected on adversarial re-derivation in r3, and properly narrowed in r4/r5 to only what DL §5's schema actually computes — that narrowing is real, verified progress and is the reason r4 and r5 both cleared the Correctness floor after r3's regression below it. r5's Calibration 69 score is scoring that round's own half-applied citation fix (one of two named locations corrected), which is now fully applied per the disposition above. Calibration is not one of the three G2 floor dimensions, so it does not gate this decision either before or after the post-review fix; it is noted here for the record, not as a basis for the verdict.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `S20-10-learning-liveness-review-r5.md` — ALGORITHM §20.10 "Learning liveness" (lines 647-669) and its §12 parameter registration (line 286) — to be committed, inclusive of the two post-review fixes verified above (line 668 citation correction; zero-held-out-rows edge case documented at lines 659 and 668). The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

**Advisory, non-blocking, carried forward for future work (not required for this approval):** name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's growth-event tally; distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test. Both are unaddressed across all five rounds and were explicitly scoped out of every round's brief so far.
