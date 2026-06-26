# 360 Review: S16-unified-retrieval-r3 — 2026-06-27

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` |
| Proposed change | §16 "Unified retrieval — value-of-information over a typed action space" (§§16.1–16.8), revised to address the three non-blocking items named in round-2 |
| Reviewer | review-360 |
| Date | 2026-06-27 |
| Round | 3 (round-2 score: 80 / ready-for-approval) |

---

## Round-3 scope

Round-2 scored 80 / 100 (ready-for-approval) with all six round-1 blockers resolved. The round-2 adversarial objection and two non-blocking findings were flagged as items the author should address in §16 before the companion build-spec is written:

1. **Inner-loop stopping condition** — §16.6 now adds an "Inner-loop termination (mirrors §15.3)" paragraph.
2. **Reranker gradient-update timing** — §16.5 now states the update is across-episode (cold path), batched at goal completion, gated like any learned weight (§8).
3. **Named retrieve budget parameter** — `b_ret` introduced in §16.6.

This round verifies these three fixes are genuine, checks their internal consistency, and rescores all nine dimensions.

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 89 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 84 | pass |
| 4 | Implementability | 82 | pass |
| 5 | Safety / integrity (CRITICAL) | 86 | pass |
| 6 | Efficiency / cost | 84 | pass |
| 7 | Completeness | 84 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 84 | pass |

---

## Fix verification — the three non-blocking items

### Fix 1: Inner-loop stopping condition (round-2 adversarial objection) — GENUINELY RESOLVED, with one minor imprecision

§16.6 line 430 now reads:

> "The retrieve loop stops when the best remaining pull's expected gain falls below its bar — `significant(EIG_Q, SE)` fails ⇒ the answer is as resolved as retrieval can make it ⇒ **act** — or when the per-`EXPAND` retrieve budget `b_ret` is spent, or on diminishing returns (K low-gain pulls)."

The fix is genuine. The three named conditions (`significant(EIG_Q, SE)` fails, `b_ret` spent, K low-gain pulls) directly address the round-2 adversarial objection. The information-theoretic stopping rule is now explicit and the "infinity bounded by information, not enumeration" framing is correctly applied to `Q`.

**Partial-mirror caveat (minor, non-blocking).** §15.3 has four termination conditions: (i) `significant(ΔH, SE)` fails, (ii) K low-gain visits, (iii) per-revisit budget, (iv) circuit breaker (oscillation/thrash → halt, §14). §16.6's paragraph carries three of the four — conditions (i), (ii), (iii) — but omits the circuit-breaker trigger. The claim "mirrors §15.3" therefore slightly overstates the symmetry. The omission is defensible (the outer §8 circuit breaker governs the whole EXPAND call, so a separate inner-loop circuit breaker would be redundant), but the word "mirrors" implies full structural equivalence. This is a calibration imprecision, not a correctness error. It reduces Calibration / honesty from 85 to 84.

### Fix 2: Reranker gradient-update timing — GENUINELY RESOLVED, with a wording ambiguity

§16.5 line 425 now reads:

> "The rerank update is **across-episode (cold path)**: at goal completion the realised held-out outcome applies a batched gradient step to the rerank weights, gated like any learned weight (§8) — never on the hot path."

The fix is genuine. The across-episode / cold-path timing is explicit, "never on the hot path" is unambiguous, and the "batched at goal completion" constraint is now stated.

**Wording ambiguity (minor, non-blocking).** "Gated like any learned weight (§8)" is slightly ambiguous. §8's commit gate has four clauses (`statistical ∧ generalize ∧ cumulative ∧ safe`) and produces a child checkpoint. The reranker weight is not a checkpoint weight; it is the `w` vector in §5.2's `update_w`. The applicable gate is most likely the generalization gate (§16.7 says "subject the reranker weights to the same generalization gate (§8) as any learned weight"), not the full four-clause gate that requires producing a child node. The phrase "gated like §8" without specifying which clause of §8 will require a disambiguation in the companion build-spec. This is a build-spec-level precision issue, not a design error. It is already acknowledged in §16.7, and §5.2's `l1_decay` passive decay provides an independent safety net against a rogue reranker.

### Fix 3: Named retrieve budget parameter `b_ret` — INTRODUCED BUT NOT FORMALLY LISTED

`b_ret` appears at §16.6 line 430 ("the per-`EXPAND` retrieve budget `b_ret` is spent") and is a genuine parameter introduction that was the round-2 completeness gap.

**New gap (non-blocking).** `b_ret` and `K` (low-gain pulls) are introduced in §16.6 but do not appear in §12's parameter list (line 282) and §16 has no "New parameters" subsection of the form used by §13.1, §14.5. This is inconsistent with the spec's own convention: every additive section that introduces new hyperparameters documents them explicitly (§14.5: "calibration window · c_band bounds · τ_cal breaker threshold · recalibration cadence"). §16 introduces at least `b_ret`, `K` (inner-loop low-gain count), and implicitly the initial Beta parameters for `Q` (`α_Q0, β_Q0`) — none are formally listed. The fix addresses the existence problem (parameter is named) but not the listing problem (parameter is not enumerable for implementation). This reduces Completeness from 87 to 84 and Consistency from 86 to 84.

---

## Findings by dimension

### 1. Correctness

**Finding 1.1 — All six round-2 blockers remain resolved.** Z-scored objective, Q as Binary Beta, EIG_Q closed form, §6 dispatch, coverage-floor structural proof, §15.4 caveat — all intact. No regression introduced by the three round-3 fixes.

**Finding 1.2 — Stopping condition math is correct.** `significant(EIG_Q, SE)` is the A1 gate primitive applied to the inner-loop's EIG estimate. The SE here is the standard error of EIG_Q under the current Beta(α,β) — the same instrument as §2, applied to the right quantity. The math is internally consistent.

**Finding 1.3 — Reranker timing: no math error, one wording ambiguity (see Fix 2 above).** The batched gradient step at episode end is mathematically coherent: the realised held-out outcome is known, the leave-one-out credit (§5.2) is well-defined at episode end, and the cold-path batching matches §8's convention for learned weights. No formula error.

**Finding 1.4 — Reduction to A1 claim remains exact.** Unchanged from round 2. Disable retrieval → Q empty → U_Q never fires → U_C = A1 verbatim. Correct.

**Finding 1.5 — Round-2 drafting nit (finding 1.5 in r2) now resolved.** The reranker timing is explicit; the r2 imprecision is closed.

**Score rationale:** The math is internally consistent and A1-faithful throughout. The partial-mirror (Fix 1) and §8 wording ambiguity (Fix 2) are precision issues at the description layer, not formula errors. Score: **89** (up from 88; the reranker timing nit from r2 finding 1.5 is genuinely closed).

---

### 2. Design faithfulness

**Finding 2.1 — §15.3 parallel: mostly faithful.** The inner-loop termination correctly borrows §15.3's conceptual framing ("infinity bounded by information, not enumeration") and three of four conditions. The missing circuit-breaker condition is defensible (outer-loop CB covers it) but is a slight departure from the "mirrors" claim. Design-faithfulness score is not materially affected because the principle is honored.

**Finding 2.2 — §8 cold-path convention: consistent.** Learned weights updated on the cold path, batched at goal completion, gated — this is exactly how §8/§9 handle promotion weights. The reranker's cross-episode update is architecturally faithful to the established hot/cold split.

**Finding 2.3 — §12 parameter-list convention: not followed.** §§13–15 introduce new parameters in dedicated subsections (§13.1's info-gain objective parameters implicitly in A1, §14.5's explicit list, §15.3's parameters implicit in §15). §16 introduces `b_ret` and `K` inline without a subsection. This is a minor divergence from the spec's own documentation convention. Non-blocking for the design section but should be addressed in the build-spec companion.

**Score rationale:** The architectural framing is faithful to §§5–15. The documentation convention gap is the only new finding. Score: **84** (up from 82).

---

### 3. Red-team resistance

**Finding 3.1 — RC-1 regression: closed (round 2).** Unchanged. Z-scored objective, mandatory warning, A1 verbatim for U_C.

**Finding 3.2 — RC-2 context gaming: reranker gating now more explicit.** §16.5's cold-path, batched, §8-gated statement strengthens the r2 defense. A reranker updated only at episode end on held-out outcomes and gated by the generalization check cannot be exploited within an episode.

**Finding 3.3 — RC-7 coverage floor: resolved (round 2).** Retrieve is inner-loop / C-neutral. The explicit stopping condition (Fix 1) also bounds the inner loop's duration, providing an additional structural guard against U_Q dominance (r2 finding 3.5). The round-3 explicit `b_ret` budget reinforces this.

**Finding 3.4 — RC-7 / U_Q dominance (r2 finding 3.5): now bounded by explicit stopping conditions.** The `b_ret` budget (Fix 3) and the `significant(EIG_Q, SE)` gate (Fix 1) together bound the inner loop from both the resource side and the information side. This finding, which was "non-blocking" in r2, is now substantively addressed.

**Finding 3.5 — No new RC regressions.** The three fixes add termination rules and hot/cold timing clarity. None of RC-3 (provisioning), RC-5 (decay), RC-6 (tree invalidation), or RC-8 (promotion) are affected.

**Score rationale:** The two remaining residuals from r2 (U_Q dominance, reranker hot-path concern) are now structurally addressed. Score: **84** (up from 80).

---

### 4. Implementability

**Finding 4.1 — Stopping condition now implementable.** A developer implementing the inner loop knows: stop when `significant(EIG_Q, SE)` fails, or `b_ret` is spent, or K consecutive low-gain pulls. The algorithm is now unambiguous.

**Finding 4.2 — Reranker timing now implementable.** A developer knows: after goal completion (not per-step), collect the realised held-out outcome, apply a batched gradient to rerank weights `w`, gate by §8's generalization check. The "when" is resolved; the "which clause of §8" needs one clarification sentence in the build-spec.

**Finding 4.3 — `b_ret` is named but not defaulted.** A developer must still choose a value. Given §12's precedent of listing parameters with notes on empirical calibration, the absence of a default or a range for `b_ret` and `K` is an implementability gap. It is at the same level as §12's other open-calibration dials ("These are the dials a Milestone-0/1 empirical pass tunes") and is acceptable for a design section — but the build-spec must supply defaults.

**Finding 4.4 — Q initialization not specified.** The initial Beta parameters for Q (`α_Q0, β_Q0`) are not named. A developer initializing Q at goal start needs these. They are likely `Beta(1,1)` (uniform, maximum entropy) by analogy with the cold-start prior, but this is inferred, not stated.

**Score rationale:** The two round-2 build-spec ambiguities (stopping condition, reranker timing) are substantially resolved. Two new minor gaps (default for `b_ret`/`K`, Q initialization Beta) replace them at a slightly lower severity. Score: **82** (up from 75).

---

### 5. Safety / integrity

**Finding 5.1 — Commit gate unchanged.** Retrieve produces no child node, no gate is touched. Unchanged from r2.

**Finding 5.2 — Cold-path reranker: explicit, safety-positive.** "Never on the hot path" removes the possibility that a fast within-episode reranker update could inject a learned bias before the held-out gate fires. This is a safety strengthening over r2's implicit timing.

**Finding 5.3 — Coverage floor: structurally resolved (round 2).** `b_ret` budget (Fix 3) provides a second structural bound against inner-loop overrun into the outer practice quota — an additional safety property.

**Finding 5.4 — Q→C leakage: unchanged.** Q is discarded at goal completion; only verifier-gated outcomes touch C (§8). Unchanged and correct.

**Finding 5.5 — No integrity gate weakened.** The three fixes add specificity; none relax any gate or calibration layer.

**Score rationale:** No safety regression; two safety strengthenings (explicit cold-path reranker, b_ret budget bound). Score: **86** (up from 84).

---

### 6. Efficiency / cost

**Finding 6.1 — `b_ret` budget makes cost accounting explicit.** R2's implicit cost bound is now supplemented by an explicit per-EXPAND budget. This is a meaningful improvement in cost accounting clarity.

**Finding 6.2 — Cold-path reranker: eliminates hidden hot-path gradient overhead.** R2's "gated like any learned weight" was ambiguous about timing. The explicit "never on the hot path, batched at goal completion" removes the concern that the reranker might be updated per-step (which would add per-retrieve gradient computation to the hot path). The cold-path batching is O(1) amortized cost per goal.

**Finding 6.3 — EIG_Q computation: O(1) per step.** Unchanged. Beta closed form, no additional complexity.

**Finding 6.4 — K low-gain pulls: early-exit optimization confirmed.** The "K consecutive low-gain" condition provides a practical early termination that bounds worst-case inner-loop length below `b_ret`, especially in cases where EIG_Q is uniformly low (e.g., no relevant context exists for the goal).

**Score rationale:** Three efficiency improvements in r3 (explicit budget, cold-path reranker clarity, K early-exit). Score: **84** (up from 82).

---

### 7. Completeness

**Finding 7.1 — Stopping condition: complete.** Three conditions named; the logic is closed. The missing circuit-breaker (fourth §15.3 condition) is covered by the outer-loop circuit breaker — the gap is in the "mirrors" claim, not in actual coverage.

**Finding 7.2 — Reranker timing: complete at the design level.** Which clause of §8 applies (generalization gate specifically) needs one clarification sentence, but the design is sufficiently specified.

**Finding 7.3 — New parameter gap (b_ret, K, Q initialization).** `b_ret` and `K` are introduced in §16.6 without defaults or bounds. `α_Q0, β_Q0` for Q initialization are not named anywhere. These are the completeness items opened by Fix 3. Unlike §14.5 ("New parameters: calibration window · c_band bounds · τ_cal breaker threshold · recalibration cadence"), §16 has no equivalent subsection.

**Finding 7.4 — Test stubs unchanged.** Three stubs in §16.8 remain adequate for the design section; the build-spec must add tests for the stopping condition and reranker timing.

**Score rationale:** Fix 1 closes the round-2 primary completeness gap (stopping condition). Fix 3 opens a new secondary gap (parameters not listed). Net movement: 78 → 84 (the primary gap was larger than the secondary one). Score: **84**.

---

### 8. Consistency

**Finding 8.1 — §15.3 mirror: mostly consistent.** Three of four §15.3 conditions are carried forward. The language "mirrors §15.3" is slightly stronger than the structural reality (three conditions mirrored, one handled by the shared outer-loop circuit breaker). The principle is consistent; the word is mildly imprecise.

**Finding 8.2 — §8 gating language: mostly consistent.** "Gated like any learned weight (§8)" is consistent with the broad §8 philosophy (no learned weight without a gate). The specific clause (generalization gate, as stated in §16.7) is consistent with §8's sub-clauses. The imprecision is at the level of which sub-clause, not inconsistency of principle.

**Finding 8.3 — §12 parameter-list convention: inconsistent.** §16 introduces `b_ret` and `K` without adding them to §12 or providing a subsection following the §13–§15 pattern. Every other section that introduces new hyperparameters either extends §12's list or has its own subsection. §16 does neither. This is the clearest consistency gap opened by Fix 3.

**Finding 8.4 — All round-2 consistency findings: unchanged resolved.** §15.4 caveat, store-name mapping, A1 reduction claim, two-level MCTS alignment, §5.3 coverage-floor consistency — all remain resolved.

**Score rationale:** Fix 1 closes the §15.3 alignment gap. Fix 3 opens the §12 parameter-list gap. Net improvement from 82 → 84. Score: **84**.

---

### 9. Calibration / honesty

**Finding 9.1 — "Mirrors §15.3" overclaim.** §16.6 says the termination "mirrors §15.3" but carries three of its four conditions. The claim is directionally accurate but quantitatively imprecise. A more honest framing would be "analogous to §15.3" or "borrows §15.3's first three conditions." This is a calibration nit, not a substantive misstatement.

**Finding 9.2 — Reranker §8 claim: slightly overclaims.** "Gated like any learned weight (§8)" could be read as claiming the full four-clause gate. The correct reading (generalization gate as stated in §16.7) is defensible but requires two paragraphs to establish. A reader of §16.5 in isolation might infer stronger gating than is actually specified.

**Finding 9.3 — All round-2 calibration findings: resolved.** "Two beliefs" framing, EIG_Q expected-not-realized distinction, §15.4 determinism caveat — unchanged and correct.

**Finding 9.4 — Q initialization is unspecified.** Not stating `α_Q0, β_Q0` is an implicit assumption (probably uniform Beta(1,1)) that is not surfaced as a choice. This is a calibration gap at the design level — the spec is silent where it should either state a choice or flag the calibration decision.

**Score rationale:** Two minor overclaims (mirrors §15.3, §8 gating) and one unacknowledged implicit assumption (Q initialization). All round-2 calibration gaps resolved. Score: **84** (up from 83 but tempered by the new partial overclaims).

---

## Strongest adversarial objection

The round-2 strongest objection (inner-loop has no stopping condition) is now directly addressed. The hardest objection remaining after all nine dimension findings above is:

**`b_ret` and `K` are parameters without defaults, bounds, or a "New parameters" subsection, and `Q`'s initial Beta is entirely implicit. This means §16 introduces three to four implementation decisions that a developer must guess.** §§13–15 each introduce new parameters and either list them explicitly (§14.5) or have them captured in the companion build-specs (A1, A5, B1–B4). §16 has no equivalent. A developer writing the §16 companion build-spec must choose: an initial `b_ret` (what unit? number of retrieve steps? time budget?), a `K` for low-gain diminishing returns, and `α_Q0, β_Q0`. None of these choices are empirically pinned — they are free parameters with no guidance. In a retrieval-heavy deployment, a poor choice of `b_ret` can make the inner loop either trivially short (one retrieve, then stop) or pathologically long (hundreds of retrieves before a cost-denominated stop). The spec introduced `b_ret` as a parameter name but did not complete the specification. This is a build-spec gap, not a design-section blocker — but it is the strongest argument that the companion build-spec must not simply inherit §16 as-is.

No additional objection beyond the nine dimensions is found beyond this elaboration of the completeness/consistency gap already surfaced in dimensions 7 and 8.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=89, RedTeam=84, Safety=86) = 84
weighted_mean   = (89×2 + 84 + 84×2 + 82 + 86×2 + 84 + 84 + 84 + 84) / 11
              = (178 + 84 + 168 + 82 + 172 + 84 + 84 + 84 + 84) / 11
              = 1020 / 11
              = 92.7
overall         = min(84, 92.7) = 84
```

**Overall confidence: 84 / 100**

---

## Verdict

**ready-for-approval**

All three round-2 non-blocking items are genuinely resolved: the inner-loop stopping condition is explicit and information-theoretically grounded (Fix 1); the reranker update timing is cold-path, batched, and gated (Fix 2); `b_ret` is named (Fix 3). All three CRITICAL dimensions clear 70 (Correctness 89, Red-team resistance 84, Safety 86). The aggregate scores 84 (up from 80 in round 2), above the 80 threshold.

The companion build-spec should address:
1. A "New parameters" subsection for §16 listing `b_ret`, `K`, and `α_Q0/β_Q0` with defaults and ranges.
2. Which clause of §8 the reranker weight gate uses (the generalization gate specifically, as §16.7 implies, not the full four-clause commit gate).
3. The precise unit and default for `b_ret` (number of retrieve steps? time ms? cost units?).
