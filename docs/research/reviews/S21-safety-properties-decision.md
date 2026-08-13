# Decision: APPROVED — S21-safety-properties

**Date:** 2026-08-13
**Approver:** change-approver
**Review source:** docs/research/reviews/S21-safety-properties-review-r3.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 83 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 86 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 85 | >= 70 | PASS |
| G2: Safety floor | Safety / integrity score | 83 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**

All three gates clear. G1 (83 > 80) and G2 (Correctness 86, Red-team resistance 85, Safety/integrity 83 — each ≥ 70) pass on the review's own scored figures. G3 passes because round 3 records zero blocking items: rounds 1 and 2's blocking defects (PR-5's self-contradiction against §9's own text; the invented `lineage` "irreversible-class" schema field) are both independently re-verified in the r3 report against source text (`DATA-LAYER.md:91,150`, `ALGORITHM-v0.2-pathway-learner.md:266,507`), not merely asserted closed. The report's single prominently-reported item — the preamble bucketing PR-5 under "preserved (untouched)" while §21.2 clause (ii) is structurally a second normative clarification — is explicitly scored by review-360 as non-blocking (Correctness 86, not held below the CRITICAL floor; verdict recorded as "ready-for-approval" with the item framed as "recommended — not required"). The check-on-the-checker scan of the findings body found no item tagged critical, blocking, must-fix, or severity ≥ HIGH anywhere in the r3 report's nine dimension sections or its "strongest adversarial objection" — the four "weak" dimension statuses (Design faithfulness 75, Completeness 74, Consistency 75, Calibration/honesty 78) are all non-CRITICAL dimensions scored well above a blocking bar and each traces to the same single, explicitly-non-blocking preamble-labeling item. No contradiction between the headline score and the review's own findings was found; the headline is not miscalibrated.

**Post-review disposition, verified.** The r3 report's recommended fix offered two options; the artifact was updated to take option (a) exactly as specified. I read the current preamble (`ALGORITHM-v0.2-pathway-learner.md:651`) as disposition-of-findings verification (not a re-review): it now declares **two** conformance clarifications, each with its own property-impact line — "(1) the §21.2 event-indexed decay clause resolves §5.1's unstated `decay_edges` clock — **PR-7 strengthened**" and "(2) §21.2's guard clause (ii) gives §9's Stage-2 merge a normative reading against the already-present DL §5 registry field (`stage: probation → merged` on `merge_to_base` — no schema change) — **PR-5 made legible**," with "PR-1–PR-4, PR-6, PR-8, PR-9 preserved (untouched)" now correctly excluding PR-5 from that bucket. This closes the r3 report's one open item (round-2 required change #2, per the r3 Completeness section) exactly as its first suggested resolution path. This confirmation does not change any gate outcome — the review's own scoring already treated the item as non-blocking — but it removes the sole advisory item the report flagged for the implementer's attention.

All gates pass; no CRITICAL-dimension floor is at risk; no unresolved blocking item exists; the one advisory item the review recommended is confirmed closed in the artifact.

## Advisory (non-blocking) items for the implementer

These do not block approval; review-360 scored them as non-blocking and none reached CRITICAL-dimension severity. Noted for implementation-phase awareness, per r3's Completeness/Implementability/Design-faithfulness sections:

1. §21.2's property text states the Stage-2 *end* of the `stage: probation → merged` transition but does not explicitly state that Stage-1 (`train_LoRA`) is what sets `stage: probation` in the first place — a developer implementing `test_stage2_merge_gated_behind_reversible_stage1` needs to infer the Stage-1 write from the enum's existence rather than from an explicit statement in §9 or §21 (r3 §4, "Implementability").
2. Round-2 required change #4 (state explicitly whether a Stage-2 merge's source checkpoint is tagged as a GC-exempt milestone) was sidestepped defensibly rather than answered directly — PR-5 instead states the honest pessimistic bound ("unconditionally irreversible" past GC). Acceptable per r3, but the direct question remains open if a future round wants to close it in the letter rather than the spirit (r3 §7, "Completeness").

## Next step

**Authorized for commit.** This decision record authorizes the change described in `S21-safety-properties-review-r3.md` — ALGORITHM-v0.2-pathway-learner.md §21 "Safety properties," including the post-review preamble update verified above — to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.
