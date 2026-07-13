# Decision: APPROVED — R1-retrieval-dispatch

**Date:** 2026-07-13
**Approver:** change-approver
**Review source:** docs/research/reviews/R1-retrieval-dispatch-review-r3.md
**Prior rounds (context only):** docs/research/reviews/R1-retrieval-dispatch-review.md (round 1, 54, needs-revision), docs/research/reviews/R1-retrieval-dispatch-review-r2.md (round 2, 76, needs-revision)

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 87 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 88 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 87 | >= 70 | PASS |
| G2: Safety floor | Safety score | 88 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass on the round-3 report. G1: overall confidence is 87, clearing the >80 bar (critical floor = min(88, 87, 88) = 87; weighted mean 91.73; overall = min(87, 91.73) = 87 per the report's own aggregate-confidence derivation). G2: all three CRITICAL dimensions clear the 70 floor with margin — Correctness 88, Red-team resistance 87, Safety/integrity 88. G3: the round-3 verdict is explicitly "ready-for-approval," and its own Verdict section states plainly that the three residual items it lists (unchanged header overclaim, unresolved `μ_m`/`SE_m` steady-state formula, the adversarial cache/episode-naive provenance-leak finding) are "recorded as required follow-ups rather than blocking conditions for this gate" and that "none of these three items involve a CRITICAL dimension or a proven-wrong formula" — i.e., zero unresolved blockers as of round 3.

Check-on-the-checker: the review's own findings body was scanned for critical/blocking/must-fix/severity>=HIGH items that might contradict the 87 headline. The one dimension flagged weak is Calibration/honesty (65) — not one of the three CRITICAL dimensions (Correctness, Red-team resistance, Safety), so it does not trip G2, and the report is explicit that this weak score reflects a repeat-miss on a low-cost wording fix (Finding 9.1), not a correctness or safety defect. The "Strongest adversarial objection" (episode-naive/cache provenance leak) is a genuine, well-reasoned finding, but the reviewer explicitly judged it non-blocking and it is not tagged critical/blocking in the report; it does not, on inspection, contradict any of the three CRITICAL dimension scores (Safety remains 88, supported by Findings 5.1–5.3, none of which concern this adversarial point). No critical/blocking finding with severity >= HIGH was found paired with a passing headline score in a way that indicates miscalibration on the gating dimensions. No override triggered.

Round-3 also independently re-verified (not merely re-asserted) 4 of round 2's 6 numbered blockers as cleanly closed against the underlying algorithm/spec text: the `w`→`v` naming sweep, the `ε_mode` deterministic-quota mechanism, the corrected "registered in §12" claim, and the B2-Amendment-A cross-gate flag (shown to rest on the already-approved base spec, independent of the still-unresolved Amendment A). This is the kind of substantive, re-derived progress the gate is designed to recognize as sufficient for approval, distinct from a review that merely accepts self-reported fixes at face value.

**Advisories (non-blocking — carried forward for the implementer, per the S16 precedent):**
1. **Header overclaim, unaddressed for a third consecutive round.** `BUILD-SPECS.md:288`'s "Adds NO new objective, gate, or belief" claim was named as a required blocking fix in round 2 and remains byte-for-byte unchanged, despite the `N(μ_m, SE_m)` mode-dispatch posterior (`:298`) being, on plain reading, a new belief object. Soften the header to acknowledge the new posterior, while the Mechanism section's argument that it is not a new *selection problem* may stand.
2. **`μ_m`/`SE_m` steady-state update formula still prose, not closed-form.** Cold-start numbers `(μ0, SE0)` are now concrete, but the steady-state statistic is only described ("over a sliding window `W_m`"), not written as a formula analogous to `EIG_cell`'s closed form. State the exact estimator (windowed sample mean/SD is the natural reading) and add a test analogous to `test_eig_falls_with_n_eff` at the mode level.
3. **Episode-naive/cache provenance-leak risk (the round-3 adversarial finding).** `BUILD-SPECS.md:296`'s "cache consulted first in every mode" read literally includes `episode-naive`, whose entire purpose is to be a clean, non-graph/non-state-conditioned ablation baseline. If the cache holds graph/state-materialized content from an earlier `mix`/`curriculum-global` episode, `episode-naive` could silently receive graph/state-influenced signal through the cache even though `test_naive_arm_is_clean_baseline` (`:339`) only asserts no *direct* `GraphStore`/`StateStore` call. Investigate before relying on the full-R1-vs-`episode-naive` measurable claim: either scope cache consultation for `episode-naive` to vector-origin entries only (or bypass cache entirely for that arm), or strengthen the test to assert cache-content provenance, not just direct store calls.
4. **Calibration/honesty is the weakest dimension (65, "weak" band), driven by advisory 1 above** — a repeat, low-cost, explicitly-named fix that survived two full review rounds untouched while materially harder problems in the same document were resolved. This does not block approval (Calibration is not a CRITICAL gating dimension) but should inform how quickly advisory 1 is actually closed once implementation starts.

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`R1-retrieval-dispatch-review-r3.md` to be committed. The change-approver does not apply the
edit; the committing agent or user must reference this record when creating the commit. The four advisory items above are non-blocking but should be tracked to closure (e.g., filed as follow-up tasks) rather than silently dropped, consistent with the S16 precedent for carrying forward non-blocking pre-implementation notes.
