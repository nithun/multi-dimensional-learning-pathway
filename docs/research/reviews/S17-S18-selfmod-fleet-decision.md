# Decision: APPROVED — S17-S18-selfmod-fleet

**Date:** 2026-06-27
**Approver:** change-approver
**Review source:** docs/research/reviews/S17-S18-selfmod-fleet-review-r3.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 84 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 82 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass across three review rounds. The review traveled from 45/100 (round 1, 8 blockers) to 80/100 (round 2, 3 pre-implementation notes) to 82/100 (round 3, 0 blockers). Every critical dimension clears the >= 70 floor by a wide margin: Correctness 84, Red-team resistance 82, Safety 82. The check-on-the-checker scan of the full findings body found one remaining concern — the JUDGE boundary being defined in prose rather than a machine-readable artifact — but this is explicitly and correctly classified by the reviewer as a non-blocking companion BUILD-SPECS obligation, not a structural flaw in the algorithm design; the capability-isolation runtime backstop (address-space separation) catches boundary-classification errors at runtime even if the prose-to-artifact translation is imperfect, so no critical finding contradicts the 82 headline. The three round-2 pre-implementation notes are all verified genuinely resolved: (1) the SOLVE/JUDGE static check is now sound/conservative with a runtime capability-isolation backstop providing defense-in-depth; (2) the Stage-2 rollback trigger is fully specified as `significant(Δ, SE)` over window `w_promo`; (3) the fleet-cache staleness bound `τ_cache` is registered in §12 with conservative `φ=1` on stale/missing reads, ensuring over-coverage rather than under-coverage. This is the most safety-critical addition in the spec; the Safety dimension specifically rose from 80 to 82 in round 3 owing to the defense-in-depth capability-isolation backstop, and all nine JUDGE-surface items in §17.1 are confirmed accounted for under address-space isolation.

**Advisory (non-blocking) — companion BUILD-SPECS obligation:**
The JUDGE boundary must be represented as a machine-readable artifact (e.g., an allowlist of JUDGE module identifiers) that the static analysis tool consults. The companion BUILD-SPECS item must specify: (a) the machine-readable JUDGE boundary artifact and its format; (b) the review process when new components are added or promoted via `self_modify`; (c) how the static analysis is re-run and the boundary artifact updated after each Stage-2 promotion. Failure to close this governance gap before implementation would reduce the static check to an informal convention as SOLVE grows — the address-space isolation remains as a runtime safety net, but the static layer would lose meaning over time.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `S17-S18-selfmod-fleet-review-r3.md` — §17 "The self-modification axis" and §18 "Multi-agent populations" as revised through round 3 — to be committed to `docs/research/ALGORITHM-v0.2-pathway-learner.md`. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

Before implementation begins, the companion BUILD-SPECS item must be drafted and gate-reviewed per the advisory above. The JUDGE boundary governance gap is not a runtime safety risk (capability isolation is in place) but it is a maintainability risk that grows with every `self_modify` promotion cycle.
