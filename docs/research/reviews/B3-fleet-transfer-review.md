# 360 Review: B3-fleet-transfer — 2026-06-26 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` — section "## B3 · Cross-agent skill transfer / fleet learning (agent-side)" |
| Proposed change | Add a Transfer component that copies a verified skill from a source agent to a frontier-matching recipient agent, validated exclusively by the recipient's own held-out verifier (full §8 gate, isomorphic variants, quarantine before admission). |
| Reviewer | review-360 |
| Date | 2026-06-26 |
| Round | 3 (previous scores: R1 65/100 needs-revision; R2 78/100 needs-revision; two blockers issued in R2) |

---

## Round-2 blocker resolution audit

Round-2 issued two blocking changes required to clear 80. Before scoring, verify each.

| Blocker (R2) | Required fix | Verified? |
|---|---|---|
| **[RT-2 / I-3 / CM-1] MMR diversity weight default missing** | Add `λ_div = 0.5` default to Parameters, parallel to A5 | YES — BUILD-SPECS.md line 229 now reads: "MMR `λ_div` (0.5)" — an explicit default is present |
| **[RT-1 / Adversarial] Isomorphic variants undefined for agent skills** | Either reference `provision_suite` variant-generator or add a one-sentence definition for the agent-skill context | YES — BUILD-SPECS.md line 222 now reads: "validate on **isomorphic variants** — same task structure with freshly sampled operands / context-IDs / surface params, verified by the §4.2 trajectory-shape + counterfactual check — (or `B`-partitioned / rotated held-out items)" |

**Both round-2 blockers are resolved.** The MMR weight is now `λ_div = 0.5` (matching A5's precedent). The isomorphic-variant definition is now scoped to agent skills: same task structure, freshly sampled operands/context-IDs/surface params, verified by the §4.2 trajectory-shape + counterfactual check. This is a well-grounded definition that ties to existing verification infrastructure rather than introducing a new mechanism.

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 82 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 84 | pass |
| 5 | Safety / integrity (CRITICAL) | 82 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 84 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 80 | pass |

---

## Findings by dimension

### 1. Correctness

**Score: 82 — pass (unchanged from R2)**

The isomorphic-variant definition resolves the principal independence-guarantee gap identified in R2. The §4.2 tie-in (trajectory-shape + counterfactual check) is the same verification used for the public/held-out split throughout the algorithm; using it here is consistent and derivationally sound.

Two residual correctness concerns from R2 remain, both non-blocking:

**C-1 (moderate, carried from R2): "Verified trajectory data" is still undefined.** BUILD-SPECS.md line 222: "copying the skill artifact (+ its verified trajectory data)." No schema for what "verified trajectory data" constitutes, whether it is included in `apply(candidate)`, or whether it enters B's public or held-out pool. The isomorphic-variant clause now governs validation independently of this payload, so the risk of contamination is further reduced — but a developer implementing `apply(candidate)` still lacks a definition of this parameter. Non-blocking given validation is now explicitly variant-based, but should be resolved before implementation.

**C-2 (mild, carried from R2): Cumulative baseline initialization for a cold-start cell is unspecified.** When skill `s` is entirely new to agent B (`B.n_eff[s] < n_transfer`), the `cumulative` clause of §8 (`ĉ_secret[s] ≥ ĉ_baseline[s] − ε_cum`) requires a pre-existing `ĉ_baseline[s]`. The spec does not state how this is initialized for the cold-start case. If an absent baseline causes the `cumulative` check to pass vacuously, that check is silently disabled for all first-time transfers. A recommended default (e.g., initialize to `α0/(α0+β0)` = the cold prior mean) should be stated explicitly.

### 2. Design faithfulness

**Score: 84 — pass (unchanged from R2)**

The spec remains well-anchored to v0.2 architecture. The isomorphic-variant definition now cross-references §4.2 explicitly, which tightens the design integration.

**D-1 (mild, carried from R2): "Frontier" still not anchored to §5.2 reach_weight.** The cold-start trigger is `B.n_eff[s] < n_transfer`, but the spec does not state whether `reach_weight(s, B) > threshold` is also required before a transfer is proposed. An agent could receive a transfer for a skill whose prerequisites it has not mastered, bypassing the §5.2 soft reachability filter. This is an architectural ambiguity — not a correctness error — but it should be clarified.

**D-2 (minor, carried from R2): No `mdlp/transfer.py` filename.** Other approved specs (A1, A5) name the exact `mdlp/` file. B3's plug-point names the three functions but not the filename. Minor convention gap.

### 3. Red-team resistance

**Score: 82 — pass (up from 78 in R2)**

The two R2 blockers directly addressed the principal RT vulnerabilities:

**RT-1 (resolved): Isomorphic-variant generation is now defined.** The definition "same task structure with freshly sampled operands / context-IDs / surface params, verified by the §4.2 trajectory-shape + counterfactual check" establishes that: (a) the variant must change the surface parameters so memorization of A's specific items fails; (b) the §4.2 counterfactual check (inject a variant at runtime, confirm it passes) provides the independence verification; (c) this reuses existing verification infrastructure rather than requiring a new component. The independence guarantee now holds at both the data-access level (no `A.StateStore` read) and the item-distribution level (variant operands/context-IDs differ from A's items). This closes the strongest adversarial objection from R2.

**RT-2 (resolved): MMR diversity weight is now defaulted.** `λ_div = 0.5` in Parameters matches A5's precedent. The echo-chamber guard is now operationally defined.

Two mild residual concerns remain:

**RT-3 (mild, carried from R2): Quarantine visibility to `choose()` not explicitly excluded.** The spec quarantines the transferred skill as `pending_human` but does not state that a `pending_human` node is excluded from `choose()`'s candidate set before validation passes. §5.1 of ALGORITHM-v0.2 and DATA-LAYER.md §5 imply this exclusion (only `live` nodes are reachable), but B3 does not invoke this explicitly. For a standalone implementation guide this is a gap. It is not a logical flaw given the v0.2 invariants apply.

**RT-4 (informational, carried from R2): Transfer-cycle provenance not addressed.** If A transfers a skill to B, B refines it, and B's refined skill later becomes a transfer candidate back to A, the TruthStore records individual `transfer(A.s→B.s)` edges but no cycle-detection over the transfer graph is specified. In a small fleet this is unlikely to cause harm; in a large fleet it is a latent risk. Recommended: note in honest risks.

No new red-team concerns introduced by the round-3 changes.

### 4. Implementability

**Score: 84 — pass (up from 82 in R2)**

The MMR default (`λ_div = 0.5`) closes I-3, the last undefaulted parameter. All Parameters now carry defaults.

**I-1 (moderate, carried from R2): `apply()` return type is underspecified.** `apply(candidate) → quarantined skill in B.SkillLibrary` does not specify: the return value on success; the quarantined-node schema in SkillLibrary; or the behavior on failure (malformed artifact, duplicate). `propose` returns `[Candidate(A, s_A, sim)]` — a concrete type. `apply` should be equivalently typed.

**I-2 (moderate, carried from R2): Post-validation state transitions not enumerated.** On `validate` pass: the skill transitions `pending_human → live`. On `validate` fail: the spec does not state whether the node is discarded, retained for retry, or flagged for human review. This was noted as the R2 I-3 blocker (which was about the MMR default, now resolved) — this is a distinct I-2 gap that was raised in R2 as non-blocking and remains.

Both are non-blocking but should be resolved before implementation begins.

### 5. Safety / integrity

**Score: 82 — pass (unchanged from R2)**

The three round-1 safety blockers and the round-2 safety findings are addressed at the specification level. No regression introduced by the round-3 changes.

**S-3 (residual, mild, carried from R2): Cumulative baseline initialization for cold-start.** As noted under Correctness C-2, a cold-start baseline for the `cumulative` gate is not specified. If the implementation interprets a missing baseline as "pass vacuously," the cumulative check is silently disabled for all first-time transfers. The statistical, generalization, and safety gates remain active, bounding the risk.

**S-4 (mild, carried from R2): No fleet-level circuit-breaker hook.** A fleet-wide transfer cascade degrading performance across multiple agents would trip per-agent circuit breakers (§8) but not a systemic fleet-level halt. This is appropriate given the current system milestone ordering (fleet monitoring is a post-M1 concern) but should be noted in honest risks.

The zero-trust invariant (no `A.StateStore` read path) and the full §8 gate remain intact and unweakened by the round-3 changes.

### 6. Efficiency / cost

**Score: 78 — pass (unchanged from R2)**

No efficiency changes in round 3. The three operations (ANN query, EvalHarness run, TruthStore write) remain bounded and proportional to cold-frontier skill count.

**E-1 (moderate, carried from R2): "Verified trajectory data" payload still unbounded.** If trajectory data includes full execution traces, the copy cost scales with trace length × number of transfer candidates. The spec should bound the payload or specify that only metadata or a compact summary is transferred.

**E-2 (mild, carried from R2): Transfer-success prior lookup not classified by store.** The MMR-diversity-weighted transfer-success prior is a new read pattern not explicitly assigned to TruthStore or GraphStore. In the embedded tier (networkx) this is a cheap edge filter; in Neo4j it may require a graph traversal.

### 7. Completeness

**Score: 84 — pass (up from 80 in R2)**

The MMR default (`λ_div = 0.5`) closes the R2 CM-1 gap. All parameters in the Parameters section now carry defaults, and the isomorphic-variant definition closes the substantive validation-independence gap.

**CM-2 (mild, carried from R2): No edge case for B having zero held-out items for s.** If `s` is entirely new to B, B's held-out set for `s` may be empty. The spec does not state whether the `provision_suite`-generated items serve as the validation set (consistent with §5.1) or whether an empty held-out set causes `validate` to fail defensively.

**CM-3 (mild, carried from R2): No test for cumulative baseline initialization in cold-start.** The Correctness C-2 gap has no test coverage. If the cumulative gate passes vacuously on first transfer, this should be an explicit, documented behavior with a test.

### 8. Consistency

**Score: 84 — pass (unchanged from R2)**

The isomorphic-variant definition is consistent with §4.2 of ALGORITHM-v0.2 (which defines the trajectory-shape + counterfactual check) and with HUMAN-LEARNING-VERIFIER.md §2.1 (which defines isomorphic items as "same concept, different surface/numbers" for human assessment). The agent-skill definition ("same task structure, freshly sampled operands / context-IDs / surface params") is the agent analog of that human-side definition — the terminology is coherent across the spec ecosystem.

**CS-1 (mild, carried from R2): `transfer(A.s→B.s)` edge type not reconciled with GraphStore schema.** DATA-LAYER.md §5 defines Graph edges as `prereq{weight, confidence}` and `transition{visits, value}`. A `transfer` edge is a new edge type. The spec should confirm this is recorded as a TruthStore event (not a GraphStore edge) or that the GraphStore schema extension is acceptable.

### 9. Calibration / honesty

**Score: 80 — pass (unchanged from R2)**

The round-3 changes do not affect the calibration/honesty dimension. The spec's honest-risks section covers negative transfer, over-transfer, echo chamber (now operationally guarded with `λ_div = 0.5`), and provenance/safety.

**CA-1 (mild, carried from R2): "Fleet learns which transfers generalize" is an aspiration.** The transfer-success prior's usefulness in a small or heterogeneous fleet is an empirical assumption, not a proven mechanism. Recommended: add an honest-risks bullet parallel to A5's ("warm-start must be shown to beat the flat prior on held-out convergence — not presumed").

**CA-2 (minor, carried from R2): Transfer-cycle provenance not acknowledged.** Not mentioned in honest risks.

---

## Strongest adversarial objection

**The §4.2 tie-in anchors variant quality to the trajectory-shape + counterfactual check, but the counterfactual check verifies that output changes when input is varied — not that the variant requires the same capability as the original.**

The round-3 isomorphic-variant definition makes meaningful progress: "same task structure, freshly sampled operands / context-IDs / surface params, verified by §4.2 trajectory-shape + counterfactual check." The §4.2 counterfactual passes if the agent's answer changes when the injected variant changes the item. This closes the most direct attack (A memorizes its specific item bank; B's validation sees the same items and passes on memorized output). It does NOT close a more subtle attack: a skill that generalizes across surface-parameter variation but exploits a structural pattern in the task class. If A's learned skill solves "all tasks of type X by pattern Y" and the isomorphic variants are drawn from the same type-X class, B's validation may pass not because the skill transfers genuinely but because both A and B exploit the same structural shortcut. The §4.2 counterfactual verifies output sensitivity to operand change, not structural-pattern independence.

This objection is narrower than the R2 adversarial objection (which argued the independence guarantee had no mechanism at all). The R3 definition materially reduces the attack surface. The residual concern is: the isomorphic-variant test verifies surface-parameter sensitivity but not capability generality across task sub-types. For a strong capability claim ("this skill transfers"), the correct defense is held-out items drawn from a diverse sub-type distribution, not just varied operands within one sub-type. The spec could acknowledge this by noting: "for strong generalization claims, the isomorphic variants should sample across task sub-types, not only across operands within a single sub-type." This is a calibration gap rather than a blocking flaw, since the `significant(Δĉ_secret, SE, margin=ε)` gate still applies to the transfer validation — a skill that exploits a narrow structural pattern will fail on items from different sub-types if any are present.

No finding beyond the nine dimensions (at this level of analysis) that could not be addressed by the above note.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety)
              = min(82, 82, 82)
              = 82

weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2
                   + Implementability + Safety*2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
              = (82*2 + 84 + 82*2 + 84 + 82*2 + 78 + 84 + 84 + 80) / 11
              = (164 + 84 + 164 + 84 + 164 + 78 + 84 + 84 + 80) / 11
              = 986 / 11
              = 89.6  → 90

overall         = min(critical_floor, weighted_mean)
              = min(82, 90)
              = 82
```

**Overall confidence: 82 / 100**

---

## Verdict

**ready-for-approval**

The score of 82 clears the 80 threshold, and no CRITICAL dimension falls below 70. All six round-1 blockers were resolved in round 2. Both round-2 blockers (MMR diversity weight default, isomorphic-variant definition) are resolved in round 3. The spec is consistent with v0.2 architecture, the zero-trust invariant is enforced, the full §8 gate is cited, quarantine is present, and all parameters carry defaults.

**Non-blocking issues to address before implementation (do not block approval):**

1. **[Correctness / Safety — C-2, S-3]** Specify the `cumulative` baseline initialization for a first-time transfer (recommended: `ĉ_baseline[s] = α0/(α0+β0)`, the cold prior mean). Add `test_cold_start_cumulative_gate_conservative` verifying this.

2. **[Implementability — I-1, I-2]** Specify `apply()` return type and the post-validation state transitions: on pass `pending_human → live` (with `transferred_from: A` provenance tag); on fail `pending_human → discarded` (removed from SkillLibrary, outcome recorded to TruthStore for the transfer-success prior).

3. **[Completeness — CM-2]** Document the edge case: if B has zero held-out items for `s`, `validate` uses the `provision_suite`-generated held-out items (consistent with §5.1), else fails defensively.

4. **[Calibration — CA-1]** Add an honest-risks bullet: "Transfer-success prior quality: in small or homogeneous fleets, individual transfer outcomes may be too noisy to constitute a reliable prior; treat as an assumption to validate empirically, not a guaranteed mechanism (parallel to A5 warm-start)."

5. **[Design faithfulness — D-1]** Clarify whether `reach_weight(s, B) > threshold` is required alongside `B.n_eff[s] < n_transfer` before a transfer is proposed — i.e., whether §5.2 soft reachability gates the proposal step.

6. **[Adversarial objection]** Optionally note in the validation spec: "for strong generalization claims, isomorphic variants should sample across task sub-types (not only varied operands within one sub-type) to verify capability generality beyond surface-parameter sensitivity."

---

## Round history

| Round | Date | Overall | Verdict | Primary gap |
|---|---|---|---|---|
| 1 | 2026-06-26 | 65 | needs-revision | Six blockers: zero-trust unenforced, §8 gate incomplete, no quarantine, no defaults, no interface, no echo-chamber guard |
| 2 | 2026-06-26 | 78 | needs-revision | Two blockers: MMR `λ_div` default missing; isomorphic variants undefined for agent skills |
| 3 | 2026-06-26 | 82 | ready-for-approval | Both R2 blockers resolved; six non-blocking implementation-time gaps noted |
