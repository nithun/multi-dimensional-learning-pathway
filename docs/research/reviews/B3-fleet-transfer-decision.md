# Decision: APPROVED — B3-fleet-transfer

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/B3-fleet-transfer-review.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 82 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 82 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction — all body findings tagged moderate/mild/minor/informational; strongest adversarial objection explicitly classified as a calibration gap, not a blocking flaw | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. The overall confidence of 82 clears the G1 threshold of 80. All three critical-dimension floors (Correctness 82, Red-team resistance 82, Safety 82) clear the G2 floor of 70. Round 3 resolved both round-2 blocking items: the MMR diversity weight default (`λ_div = 0.5`) is now present in Parameters, and isomorphic variants are now defined for the agent-skill context via the §4.2 trajectory-shape + counterfactual check. The check-on-the-checker scan found no finding tagged critical, blocking, or must-fix anywhere in the body — every residual concern is explicitly classified as moderate, mild, minor, or informational, and the strongest adversarial objection is explicitly called a calibration gap rather than a blocking flaw. There is no contradiction between the headline score and the body findings.

Six non-blocking pre-implementation items should be addressed before or during implementation (listed below). They do not block the commit authorization.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `B3-fleet-transfer-review.md` to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

**Advisory items the implementer must address before or during implementation (non-blocking):**

1. **[C-2 / S-3] Cold-start cumulative baseline** — specify `ĉ_baseline[s]` initialization for a first-time transfer (recommended: `α0/(α0+β0)`, the cold prior mean); add `test_cold_start_cumulative_gate_conservative` to verify it.

2. **[I-1 / I-2] `apply()` return type and post-validation transitions** — define the return type on success; specify `pending_human → live` (with `transferred_from: A` provenance tag) on validate-pass and `pending_human → discarded` (outcome recorded to TruthStore) on validate-fail.

3. **[CM-2] Zero held-out items edge case** — document that if B has zero held-out items for skill `s`, `validate` uses `provision_suite`-generated held-out items (consistent with §5.1), else fails defensively.

4. **[CA-1] Transfer-success prior honest-risks bullet** — add: "in small or homogeneous fleets, individual transfer outcomes may be too noisy to constitute a reliable prior; treat as an assumption to validate empirically (parallel to A5 warm-start)."

5. **[D-1] Frontier trigger clarification** — clarify whether `reach_weight(s, B) > threshold` is required alongside `B.n_eff[s] < n_transfer` before a transfer is proposed (i.e., whether §5.2 soft reachability gates the proposal step).

6. **[Adversarial] Isomorphic-variant sub-type sampling note** — optionally note: "for strong generalization claims, isomorphic variants should sample across task sub-types (not only varied operands within one sub-type) to verify capability generality beyond surface-parameter sensitivity."
