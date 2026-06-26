# Decision: APPROVED — S16-unified-retrieval

**Date:** 2026-06-27
**Approver:** change-approver
**Review source:** docs/research/reviews/S16-unified-retrieval-review-r3.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 84 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 89 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 84 | >= 70 | PASS |
| G2: Safety floor | Safety score | 86 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No critical/blocking finding in body | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1: the round-3 aggregate confidence is 84 (critical floor min(89,84,86)=84; weighted mean 92.7; overall = min(84, 92.7) = 84), clearing the >80 threshold. G2: all three CRITICAL dimensions — Correctness (89), Red-team resistance (84), and Safety/integrity (86) — clear the 70 floor by wide margins. G3: the review body contains zero blocking or must-fix items; every finding in round 3 is classified minor/non-blocking or designated as a companion build-spec obligation. The check-on-the-checker scan found no finding tagged critical, blocking, or severity >= HIGH anywhere in the nine dimension sections or the adversarial-objection section; the headline score of 84 is consistent with the body. The review is correctly calibrated. The three round-2 non-blocking items (inner-loop stopping condition, reranker cold-path timing, `b_ret` named) are all verified genuinely resolved. Two remaining non-blocking advisory items are carried forward for the companion build-spec (see Next step).

## Next step

**Authorized for commit.** This decision record authorizes the §16 "Unified retrieval — value-of-information over a typed action space" change to `docs/research/ALGORITHM-v0.2-pathway-learner.md` to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

**Advisory items for the companion build-spec** (non-blocking, do not require re-review of the design section):

1. **New parameters subsection.** Add a "New parameters" subsection to §16 (cf. §14.5 pattern) listing `b_ret` (per-EXPAND retrieve budget — specify unit: retrieve steps, time budget, or cost units — plus default/range), `K` (low-gain pull count for early-exit — default/range), and the initial Beta parameters for Q (`α_Q0`, `β_Q0`, likely `Beta(1,1)` uniform but must be stated explicitly). Without these, a developer must guess three to four implementation decisions.
2. **§8 clause pin for reranker-weight gating.** Add one sentence in the §16.5 / §16.7 area clarifying that "gated like any learned weight (§8)" means specifically the generalization gate sub-clause of §8, not the full four-clause commit gate (which requires producing a child node checkpoint). This removes the wording ambiguity already acknowledged in §16.7 and prevents a build-spec author from over-specifying the gate.
