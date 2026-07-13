# Decision: APPROVED — S17-6-lineage-schema

**Date:** 2026-07-13
**Approver:** change-approver
**Review source:** docs/research/reviews/S17-6-lineage-schema-review-r7.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 84 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 88 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 84 | >= 70 | PASS |
| G2: Safety floor | Safety score | 84 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass on round 7's report. G1: overall confidence is 84, above the >80 threshold — the first round in this artifact's seven-round history to clear the bar. G2: all three CRITICAL dimensions (Correctness 88, Red-team resistance 84, Safety/integrity 84) clear the 70 floor with margin. G3: the rounds-1–6 item-resolution audit table (items 1–12) shows every previously-flagged item still closed with no regression, and round 6's three blocking items (fleet-scoping enforcement claim, missing §7 RC-6 cross-reference, missing cross-agent-prohibition test) are confirmed genuinely closed by direct verification against `DATA-LAYER.md:138` and the section text — not narrative claims. The review's own "Findings" and "Aggregate confidence" sections list zero unresolved blocking/must-fix items for this round; the one open item (item 13 / Correctness C-1 / Red-team RT-2 / Safety S-3 / Completeness Co-5 / Calibration Ca-5 — write-path population of `lineage.agent_id` on ordinary commits is unspecified) is explicitly and repeatedly characterized by the reviewer as non-blocking, reasoned through in depth (the property is very plausibly true by construction for the single-agent M1/M2 case, since §18.1's B3 zero-trust transfer re-validates and re-commits on the receiver's own chain rather than importing another agent's node directly), and is scored into the dimension totals rather than hidden beneath them (Correctness held to 88, not inflated; the adversarial-objection section gives it the report's most thorough treatment). Check-on-the-checker: a scan of the full report for items tagged critical / blocking / must-fix / severity >= HIGH found none attached to this residual — the only occurrences of "blocking" and "critical" in the body either (a) label the three CRITICAL *dimension categories* (Correctness, Red-team resistance, Safety — a scoring-table header, not a finding tag) or (b) explicitly state the opposite, that item 13 and Co-6 are "non-blocking" / "not a CRITICAL-dimension failure or a blocking defect." There is no contradiction between the headline score and a buried critical finding; the review is not miscalibrated. Consistent with the S16/R1 precedent, the two reasoned, non-blocking follow-ups are carried forward as advisories rather than treated as gate failures.

**Advisories for the implementer (non-blocking, from review-r7):**
1. Name the exact commit-path line (§6 pseudocode or §8's `commit_gate`) that populates `lineage.agent_id` on an ordinary (non-`CAPTURE`) commit, and add a corresponding test (e.g. `test_lineage_row_tagged_with_committing_agent`) so the write side of the fleet-scoping property is as checkable as the read side (`test_capture_cross_agent_prohibited`) already is.
2. Pin down the literal value of "the constant" used for `agent_id` in a single-agent deployment (`DATA-LAYER.md:138`), so a future migration to real per-agent values (§18/M3) has a stated starting point.

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`S17-6-lineage-schema-review-r7.md` — §17.6 "The scaffold-version log — concrete schema & mutation operators" in `docs/research/ALGORITHM-v0.2-pathway-learner.md` (revised r7), together with its four verified `DATA-LAYER.md` §5 delta artifacts (`scaffold_versions`, `selfmod_rejected`, `component_invoked`, `lineage.agent_id`) — to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit, and should carry the two advisories above as tracked follow-up work (not conditions of this approval).
