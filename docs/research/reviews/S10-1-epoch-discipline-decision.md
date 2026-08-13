# Decision: APPROVED — S10-1-epoch-discipline

**Date:** 2026-08-13
**Approver:** change-approver
**Review source:** docs/research/reviews/S10-1-epoch-discipline-review-r3.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score (r3) | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 85 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 87 | >= 70 | PASS |
| G2: Safety floor | Safety score | 82 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:** All three gates pass on the r3 review. G1: overall confidence is 82, above the >80 bar (critical floor 82, weighted mean 92, `overall = min(82,92) = 82`, per the review's own aggregate). G2: all three CRITICAL dimensions clear the 70 floor (Correctness 85, Red-team resistance 87, Safety 82). G3: r3 records zero unresolved blocking items — round 2's two required blockers (guard-list desync at `:283`; the false "(§18.7, existing)" citation on `test_stale_fleet_read_no_discount`) are both independently re-verified fixed in r3's Correctness/Consistency findings, and r3's verdict is `ready-for-approval` with its three carried residuals explicitly scored non-blocking ("none of them blocking at the current score").

Check-on-the-checker: r3's findings body was scanned for any item tagged critical/blocking/must-fix/severity>=HIGH. None is present — the review's "Strongest adversarial objection" section (the `test_tree_stats_invalidated_on_checkpoint_change` guard having no supporting assertion anywhere in the document) is explicitly a Correctness/Safety/Completeness/Calibration finding scored into the dimension numbers already reflected in the table above (Correctness 85, Safety 82, Completeness 79, Calibration 81) — it is not carried as a separate unresolved blocking item, and the review itself lists it under "residual items ... none of them blocking at the current score." A headline score of 82 with no contradicting critical/blocking tag is internally consistent; no override to REJECT is warranted.

**Post-review disposition verification (not a re-review).** Per the caller's brief, I independently verified in the current artifact (`docs/research/ALGORITHM-v0.2-pathway-learner.md`) that r3's top residual — the previously-uncited seventh canonical guard, `test_tree_stats_invalidated_on_checkpoint_change` — has since been given the same provenance treatment its sibling `test_stale_fleet_read_no_discount` received in r3. §10.1's Checks bullet (line 285) now reads: *"`test_tree_stats_invalidated_on_checkpoint_change` (**defined here, owned by §7's mechanism, the same coverage-gap close** — after `invalidate(node)` on a checkpoint change, the affected subtree's `value`/`visits` are discounted/reset per §7 and no selection reads the pre-change statistics at full weight; §7 predates the guard convention and had no named test)."* This matches the reviewer's diagnosis exactly (asserted spelled-out assertion + honest provenance) and closes the last open item in r3's "Strongest adversarial objection." All seven canonical guards named in the §21.1 PR-10 row (line 708) now have a defined assertion. This does not change the gate outcome — the item was already scored non-blocking at 82 — but it removes the one residual r3 flagged as worth closing before further rounds.

**Advisory (non-blocking) items for the implementer**, carried forward from r2 and reconfirmed open by r3 (Implementability, weak at 74):
1. Which `checkpoint_id` is authoritative for a scaffold candidate's "generation" at the §17.6 site is not yet spelled out (`scaffold_versions`, `:509-521`, still no direct `checkpoint_id` field; the `gate_ref` indirection is implicit).
2. Whether a second live-generation change occurring mid-flight during an in-flight synthetic eval invalidates that eval's evidence is unaddressed.

Neither is required to clear the approval bar; both are foreseeable implementation gaps and should be tracked before or during build.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `S10-1-epoch-discipline-review-r3.md` (RAF-3: ALGORITHM §10.1 + coordinated §17.6/§21/§12 amendments, including PR-10's admission via the modified-with-argument path) to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit. The two advisory implementability gaps above should be carried into the implementation task (or a companion BUILD-SPECS item) as pre-implementation notes, consistent with this project's established pattern for non-blocking residuals.
