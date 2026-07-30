# Decision: APPROVED — S20-continuous-operation

**Date:** 2026-07-30
**Approver:** change-approver
**Review source:** docs/research/reviews/S20-continuous-operation-review-r5.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 87 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 88 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 87 | >= 70 | PASS |
| G2: Safety floor | Safety score | 87 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass on round 5's report. G1: overall confidence is 87, clearing the >80 threshold — the first round in this section's five-round history (58 -> 75 -> 72 -> 76 -> 87) to reach `ready-for-approval`. G2: all three CRITICAL dimensions clear the 70 floor with real margin (Correctness 88, Red-team resistance 87, Safety/integrity 87). G3: the report's full rounds-1–4 ledger (19 items, freshly re-audited against the r5 text) shows every one of round 4's five explicitly-numbered blocking items — watchdog scoping, candidate lease-acquisition atomicity/cadence, the maintenance-namespace guard plus stale test rename, tier-enum total order, digest-LLM ambiguity, and wake/schedule retention — genuinely closed with concrete, named mechanisms and, in every load-bearing case, a corresponding test (`test_candidate_not_killed_by_watchdog`, `test_lease_acquisition_atomic`, `test_maintenance_namespace_reserved`, `test_wake_retention_prunes_consumed_only`, `test_recovery_predicate_four_way`). Zero items in the r5 report are tagged blocking, must-fix, or critical-and-unresolved; the reviewer's own verdict states explicitly that none of the residuals "independently drives any CRITICAL dimension below 70 or the aggregate below 80."

**Check-on-the-checker:** a scan of the full r5 report for findings tagged critical / blocking / must-fix / severity>=HIGH found none attached to an open item. The word "CRITICAL" appears only as the scoring-table's category label for the three gated dimensions (Correctness, Red-team resistance, Safety), not as a finding-severity tag; every occurrence of "blocking" in the findings body is a negation ("not a blocking error," "non-blocking," "not scored as a safety defect"). The new r5 finding — maintenance-unit empty `item_ids` vs. the recovery predicate's reconstructability test — is explicitly traced through the normative evaluation order and shown to fail toward the safe outcome (`unknown`, not double-execution or auto-resume) with no evidence-integrity consequence, since maintenance units never move a posterior; the report docks it as a completeness-adjacent gap, not a correctness or safety defect. The two carried-forward items (the "no second lease system" phrasing tension, now three rounds old, and `test_supervisor_singleton`'s stale description, two rounds old) are Design-faithfulness/Implementability/Consistency/Calibration observations about textual self-consistency and documentation hygiene — neither has a stated unsafe failure mode, neither is tagged as blocking anywhere in the report, and the reviewer's own "strongest adversarial objection" section frames the pattern behind them (each round's fix leaving one new adjacent, non-blocking interaction unreconciled) as a process observation about the review-and-revise cycle, not a defect in the round-5 text under review. No headline-score/buried-critical-finding contradiction exists; the review is not miscalibrated. Consistent with the S16/R1/S17-6/B2-amendA/DL-write-discipline precedent, the five reasoned, non-blocking residuals are carried forward as advisories rather than treated as gate failures.

**Advisories for the implementer (non-blocking, from review-r5, in the reviewer's stated ascending order of stakes):**
1. Reconcile the "no second lease system" principle (ALGORITHM §20.2, line 607) with the two lease mechanisms the section now contains (the per-occurrence work-unit lease and the per-agent `supervisor_lease`) — a one-sentence scoping fix (e.g., "no second *scheduling* lease system — the supervisor's own singleton lease is orthogonal, protecting the process rather than an occurrence") closes an item flagged in rounds 3, 4, and 5 without acknowledgment.
2. State the maintenance-unit/`item_ids` reconstructability interaction explicitly — confirm that an empty, intentionally-pinned `item_ids` set is trivially "intact" for the recovery predicate's reconstructability test (line 609), and add a corresponding test.
3. Edit §20.6's own text (line 631) to state the holder-scoping of the loop-progress watchdog directly, rather than leaving the qualifier solely in §20.2 — closes the residual consistency gap between the two sections describing the same mechanism.
4. Update `test_supervisor_singleton`'s description (line 645) to the round-4/5 "candidate" vocabulary, and consider a small jitter/backoff note for simultaneous candidate polling at `s_cand` — both minor, carried across rounds.
5. Add an honest-scope caveat, in the style of DATA-LAYER.md:508's precedent, naming any residual the change-approver should track post-approval (e.g., advisory 2 above) — the review has asked for this three times without it appearing in the artifact text.

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`S20-continuous-operation-review-r5.md` — §20 "Continuous operation — the unattended loop" in `docs/research/ALGORITHM-v0.2-pathway-learner.md` (revised r5), together with its `DATA-LAYER.md` §5 schema deltas (`schedule`, `wake_events`, `work_unit_closed`, `supervisor_lease`, `owner`/`lease_expires_at` on `work_unit_opened`, `schedule_id?` on `dispatch`) and its §12 parameter registrations — to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit, and should carry the five advisories above as tracked follow-up work (not conditions of this approval).
