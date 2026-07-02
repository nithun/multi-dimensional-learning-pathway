# 360 Review: S19-self-calibrating-gate — 2026-06-29

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §19 (lines 522–554) |
| Proposed change | Add a self-calibrating commit-gate layer (§19.1–19.7) that learns the §8 acceptance bar from realized accept/reject outcomes to hold a target false-accept rate `α_gate`, bounded below by the original §8 conservative threshold (`bar_floor`). |
| Reviewer | review-360 |
| Date | 2026-06-29 |

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 70 | weak |
| 2 | Design faithfulness | 82 | pass |
| 3 | Red-team resistance (CRITICAL) | 68 | weak |
| 4 | Implementability | 72 | pass |
| 5 | Safety / integrity (CRITICAL) | 72 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 65 | weak |
| 8 | Consistency | 75 | pass |
| 9 | Calibration / honesty | 68 | weak |

---

## Findings by dimension

### 1. Correctness

**Finding C-1 — FAR is not directly observable; the ROC framing overstates the math (blocking).**
§19.2 (line 532) claims: "Treat the accept/reject threshold as the operating point on a learned ROC over the logged pairs." The ROC requires both FP (accepted-then-regressed, observable) and TN (correctly-rejected, would-have-failed if admitted). By §19.1's own construction, rejected changes are unobserved. `q_explore` samples only *borderline* rejects — not the full reject population. Therefore:
- `FAR = FP / (FP + TN)` cannot be computed exactly; TN must be estimated from the borderline sample with non-uniform coverage of the reject region (borderline rejects are over-represented relative to hard rejects).
- The false-reject rate `FN / (FN + TP)` suffers identically.
- The spec says the system "minimiz[es] false-rejects subject to" FAR ≤ α_gate. This is a constrained optimization that requires an accurate FAR estimate; the estimate is systematically biased by the non-uniform `q_explore` sampling strategy.

The conceptual idea is sound — the ROC framing is the right mental model — but the spec presents a biased estimator as if it were exact. Correct form requires acknowledging that FAR is estimated as `FP / (FP + TN_hat)` where `TN_hat` is derived from the borderline sample, and that the resulting bar movement should account for the estimation bias (e.g., by reporting a wider SE that incorporates the sampling-fraction uncertainty).

**Finding C-2 — "bar" is not uniquely identified in §8; the singular clamp is ambiguous (blocking).**
§19.7 (line 552) defines `bar_floor` / `bar_ceiling` as clamping "the §8 conservative bar." §8's `commit_gate` (lines 222–228) has *four* distinct threshold-bearing clauses: (a) `z` and `ε` in the statistical clause, (b) `ρ_gen` in the generalization clause, (c) `ε_cum` in the cumulative clause, and (d) a pass/fail for the safety clause. §19.5 (line 543) states the section "tunes only the threshold" (singular) but never specifies *which* of the four it moves. A developer reading §19 cannot determine what `bar` is a variable over: `z`? `ε`? the composite score for the scored promotion index? Without this specification the entire adaptive mechanism is unimplementable and the clamp's meaning is undefined.

**Finding C-3 — `significant(FAR − α_gate, SE)` in §19.2 is not fully derived.**
The significance test is over a fraction, which requires specifying whose SE is used. FAR has SE = `sqrt(FAR*(1-FAR)/n_decisions)` if TN is exact, but with the biased TN estimator (see C-1) the SE of FAR is wider. The spec states SE without derivation; for a gate-primitive that controls the gate that controls the system's safety, a hand-waved SE is not adequate.

**Finding C-4 — per-band calibration can narrow the floor guarantee (not immediately blocking, contextual).**
§19.5 says calibration is "per skill-difficulty band (like §14)." The floor `bar_floor` = the original §8 conservative bar is apparently a global scalar. If §8 was specified with per-band thresholds, a global floor with per-band bars is incoherent: band B at a high difficulty might have a lower per-band §8 bar than band A, meaning `bar_floor` would be band B's bar, while band A's original §8 bar is above that floor — so band A could be learned downward to `bar_floor` below its own §8 baseline. The spec does not address whether `bar_floor` is global or per-band.

**Score rationale:** Two blocking flaws (C-1, C-2) prevent correct implementation. C-3 and C-4 add additional weakness. The conceptual logic of threshold learning from outcomes is sound, but the precision required for a gate-controlling gate falls below the standard already set by §2 and §14.

---

### 2. Design faithfulness

**Finding D-1 — JUDGE placement is correct and explicitly stated (positive).**
§19.4 (line 539) correctly assigns the calibration logic to the JUDGE set. This faithfully follows §17.1 (lines 453–457), which defines JUDGE as including "the commit/rollback/safety gates (§8)." The extension is architecturally consistent: a gate-learning layer that cannot be reached by `self_modify` is exactly what §17's JUDGE boundary was designed for.

**Finding D-2 — Additive pattern followed correctly (positive).**
§19 opens with "Additive: makes §8's commit gate learn its own thresholds … Rides §2, §8, §14 … never changes the four-clause gate structure" (line 524). This matches the established pattern from §13, §14, §15, §16, §17, §18 — each uses the identical "additive" header and cites which existing sections it extends without changing. The naming convention for parameters (§19.7 extends §12) is also faithful.

**Finding D-3 — The `n_cal` cold-start floor mirrors `n_min` correctly (positive).**
§19.5 (line 542) specifying a cold-start floor below which §19 is off directly mirrors the `n_min` effective-sample floor at §3 (line 61–62). This is the established pattern for preventing thin-data decisions from driving system-level changes; its application to the meta-gate is design-faithful.

**Finding D-4 — Mild tension with §14's per-band calibration scope.**
§14 (lines 340–357) calibrates the probability `p̂` and `n_eff` per band. §19 calibrates the bar per band. The interaction between these two per-band calibrations is not specified: both corrections operate on the same gate input stream, and both are per-band, but whether they run sequentially or jointly, and whose estimates serve as inputs to the other, is not addressed. This is not a blocker but leaves an integration gap.

**Score: 82** — design faithfully follows the established additive pattern with JUDGE placement; minor gap at the §14-interaction boundary.

---

### 3. Red-team resistance

**Finding R-1 — RC-1 (point estimates / noise-driven moves): partially mitigated, with an unaddressed residual.**
§19.2 explicitly gates the bar move on `significant(FAR − α_gate, SE)` and bounds the step by `η_gate`. This is the correct RC-1 pattern. However, C-1 above shows the FAR estimate is biased by `q_explore`'s non-uniform sampling, meaning the SE used in the significance test is too small — the gate can move on what is effectively noise in the unobserved reject region. The mitigation exists but is incomplete; the RC-1 risk is partially re-introduced through the observability gap.

**Finding R-2 — RC-2 (self-modifier capturing the meta-gate): structurally closed for §17 agents; gap for §18 fleet influence (potentially blocking).**
§19.4 (line 539) states that `self_modify` cannot edit the gate calibration because §19 is in JUDGE, and the §17.1 static no-write-path check enforces this. For a single-agent §17 setup this is sound.

However, §18's multi-agent fleet shares the *same* JUDGE substrate (§17.1 partition is described per-agent: "the partition is per-agent; the shared JUDGE has no agent's write-path" — §18.5 line 510). The question is whether N agents can, through their *input* to the calibration log, collectively bias the (decision, realized-outcome) pairs in the TruthStore without ever writing to JUDGE code. Specifically: a fleet agent can modulate *which* changes it submits to the gate (adversarially selecting near-threshold submissions), influencing the FAR estimate that drives bar movement. This is not a JUDGE write — it is an input-distribution manipulation. §19 does not address this fleet-adversarial path. Given §18's explicit N-agent population and M3 targeting both §17 and §18 simultaneously, this is a gap that reopens RC-2 at the meta-gate level through a different surface than the spec considered.

**Finding R-3 — RC-1 on `q_explore` selection bias introducing a new failure mode.**
The `q_explore` borderline-reject quota is described (§19.1, line 529) as sampling "a fraction of *borderline* rejects." What defines "borderline" is not specified. If borderline is defined relative to the *current* bar, then as the bar moves, the borderline region moves — creating a feedback loop where the calibration data is always sampled from near the bar's current position, not from a fixed or diverse region. This can cause the bar to chase its own tail: drift the bar up → new borderline region → new calibration data → bar drifts further. The spec acknowledges "feedback instability" in §19.6 but attributes it only to the accept/reject loop, not to the moving borderline window.

**Finding R-4 — RC-7 (abandoned weak skills): §19 does not introduce or close this.**
The safety floor prevents the bar from going below §8. RC-7's coverage floor (§5.3) is unaffected.

**Score: 68** — RC-2 has a fleet-adversarial residual (R-2) that the spec does not close. RC-1 has a partial re-introduction via biased FAR estimation (R-1). The moving-borderline feedback (R-3) is a new risk mode not found in any of the nine RC findings and not adequately bounded.

---

### 4. Implementability

**Finding I-1 — Which threshold parameter "bar" refers to must be specified before any implementation (blocking per C-2).**
A developer reading §19 together with §8 (lines 222–228) cannot determine what variable to tune. The four threshold clauses each have their own parameter (`z`, `ε`, `ρ_gen`, `ε_cum`). §19.7's parameter list (line 552) lists `bar_floor`/`bar_ceiling` as a single pair with no mapping to the §8 parameters.

**Finding I-2 — `q_explore` operational definition is underspecified.**
§19.1 says "a fraction of borderline rejects are admitted to a §17.3-style shadow/canary." Missing: how "borderline" is defined operationally (within `η_gate` of the current bar? a fixed margin?); whether the shadow run produces a child node in the MCTS tree or only a lightweight scoring pass; and whether the realized outcome of the shadow run enters the TruthStore under a distinct flag so it is not counted as a real commit. Without these, the implementation risks confusing exploration-outcomes with production-outcomes.

**Finding I-3 — The interaction with §17.3 stage-1 sandbox is not delineated.**
§19.1 references "a §17.3-style shadow/canary" but §17.3 (line 464–465) is a two-stage promotion for *code*. An `q_explore` shadow run for a *gate-calibration* purpose may not need the full stage-1 infrastructure. The spec conflates two distinct use-cases without saying whether `q_explore` reuses §17.3 literally or analogically.

**Finding I-4 — Acceptance tests in §19.7 are good (positive).**
The five stubs (`test_bar_never_below_floor`, `test_self_modify_cannot_edit_gate_calibration`, `test_cold_start_uses_fixed_gate`, `test_bar_moves_only_on_significant_far`, `test_far_converges_to_target_above_floor`) cover the core invariants and are concrete enough for a developer to translate. This partially offsets the definition gaps.

**Score: 72** — The acceptance tests are sound, but finding I-1 (ambiguous `bar`) is implementation-blocking; I-2 and I-3 are weak but fixable with a revision pass.

---

### 5. Safety / integrity

**Finding S-1 — `bar_floor` clamp analysis: the "monotone toward strictness" safety claim is sound under one reading, but the per-band interpretation leaves a gap.**
§19.3 (lines 534–535) states: "the gate may learn to be *stricter* than §8, **never looser**." If `bar_floor` is the exact §8 threshold (same numerical value, per band), then the clamp is correct by construction: any self-calibrated bar `≥ bar_floor = §8_original` cannot accept a change §8 would have blocked. This is the principal safety argument and it is structurally sound *if* `bar_floor` is correctly initialized to the §8 baseline and never itself modified.

**Finding S-2 — `bar_floor` must itself be immutable and initialized from a known-good §8 configuration (partially unaddressed).**
The spec does not state how `bar_floor` is set at initialization time or how it is protected from drift. If the §8 thresholds were themselves ever changed (e.g., tuned during M0/M1 pilots), the `bar_floor` could be initialized to a *post-tuning* §8 threshold that is already less conservative than the original conservative specification. The safety claim "never looser than §8" depends on `bar_floor` tracking the *most conservative* §8 configuration ever used, not the current one.

**Finding S-3 — `q_explore` shadow runs must not affect live competence `C` (unverified).**
§19.1 admits borderline rejects to "observe their would-be outcome." If the shadow run's outcome leaks into the competence posterior `C` (§3) — even partially — then the gate's calibration data generation has modified the thing it is supposed to measure independently (P1 violation). The spec does not explicitly state that shadow-run outcomes are *not* propagated to `C`. The §17.3 analogy implies isolation (sandbox), but the spec does not make this guarantee explicit for §19's use-case. This needs to be a stated invariant of the `q_explore` mechanism, analogous to §17.1's JUDGE immutability statement.

**Finding S-4 — JUDGE placement prevents gate-calibration editing by SOLVE (positive).**
§19.4 is correct and unambiguous on this point. The static no-write-path check described in §17.1 (line 457) covers this surface, so the §19 JUDGE claim is structurally enforced, not merely asserted by policy.

**Finding S-5 — §14 circuit-breaker applies to calibration miscalibration but §19 lacks its own breaker condition.**
§14.3 trips the circuit breaker on `ECE_band > τ_cal`. §19.6 mentions "the breaker (§14) halts oscillation" but does not specify what §19-specific condition would trigger the §14 breaker. A runaway bar drift (bar monotonically increasing toward `bar_ceiling` across many episodes) is not obviously covered by ECE of the probability calibration layer. A dedicated §19 breaker condition — e.g., `bar_change_over_window > threshold` — is missing.

**Score: 72** — The principal safety argument (`bar_floor` clamp) is architecturally sound. The main weaknesses are S-2 (bar_floor immutability not stated), S-3 (`q_explore` outcome isolation not explicit), and S-5 (missing dedicated breaker condition). None of these individually block, but together they represent meaningful implementation risk for a gate that controls the safety of all other gates.

---

### 6. Efficiency / cost

**Finding E-1 — No hot-path cost added (positive).**
§19 operates on logged (decision, realized-outcome) pairs in the TruthStore (§10), which is a cold read. The bar move is on a cadence (implied — "the bar shifts only when `significant(...)`"), not per-decision. This is the same cold-path pattern as §14's calibration recomputation. No O(n²) additions; no new LLM calls.

**Finding E-2 — `q_explore` shadow runs add bounded overhead.**
The shadow fraction `q_explore` is a new cost (borderline rejects are re-evaluated in sandbox). The cost is bounded because (a) only borderline rejects are shadowed, not all, (b) the §17.3 sandbox has a `sandbox_cost_cap`, and (c) the system is below `n_cal` it is off entirely. This is within budget per the spec.

**Finding E-3 — Per-band calibration over TruthStore is O(events_per_band) per calibration cycle, consistent with §14's pattern (positive).**
No new complexity class introduced; the same sliding-window approach as §14.1.

**Score: 85** — Efficient. Cold-path; bounded exploration cost. Shadow runs add real cost but it is explicitly capped.

---

### 7. Completeness

**Finding Co-1 — `q_explore` selection criterion not defined (blocking for implementation).**
See I-2. What "borderline" means operationally is not specified. The calibration data-collection strategy is the core mechanism of §19 and its most implementation-sensitive component.

**Finding Co-2 — No definition of `bar_ceiling` beyond "ceiling".**
§19.7 lists `bar_ceiling` as a parameter without bounding or defaulting it. A ceiling at the wrong value could prevent the gate from becoming strict enough to matter in practice, or could allow no learning at all. Unlike `bar_floor` (which has a natural anchor in §8), `bar_ceiling` has no stated derivation or default.

**Finding Co-3 — Interaction with per-band §8 thresholds not addressed.**
See C-4 and D-4. If §8 thresholds already differ by band (plausible — different difficulty bands may warrant different `ε` or `z`), then `bar_floor` must also be per-band. The spec provides no guidance.

**Finding Co-4 — No definition of what constitutes a "realized outcome" with a timeout.**
§19.1 describes "did an accepted change hold up (its held-out gain persisted on subsequent independent evals, no regression)." Subsequent means after how many evaluations? Over what time window? The outcome of a commit might only be observable after 10 or 100 subsequent evals, and the spec gives no guidance on the observation window. This directly affects how many usable calibration pairs the system accumulates and how quickly `n_cal` can be reached.

**Finding Co-5 — The check stubs in §19.7 are adequate for the specified invariants (positive).**
Five stubs covering the key safety and behavioral invariants are present. Their scope is appropriately scoped to what the spec claims.

**Score: 65** — Co-1, Co-2, Co-3, and Co-4 each represent gaps that a developer would have to resolve independently, inconsistently, or incorrectly. The check stubs are good but the mechanism specification itself is materially incomplete.

---

### 8. Consistency

**Finding Cs-1 — §19's per-band calibration is consistent with §14's pattern (positive).**
§14 (lines 340–358) calibrates `g_band` and `c_band` per difficulty band; §19 applies the same per-band discipline to the threshold bar. The naming convention (`_band` suffix), the cold-path cadence, and the circuit-breaker linkage are all consistent with §14.

**Finding Cs-2 — §19 correctly cites §2, §8, §14, §17.1 and the `n_min` pattern (positive).**
All hook citations (§19's preamble, §19.4's P1 claim, §19.5's cold-start parallel to §3's `n_min`, §19.6's RC-1/RC-2 mapping) are traceable to the cited sections. There are no fabricated line references.

**Finding Cs-3 — Tension with §8's four-clause structure and the "tunes only the threshold" claim.**
§19.5 (line 543): "§19 tunes only the *threshold*; the four gate clauses (statistical ∧ generalization ∧ cumulative ∧ safe, §8) are unchanged." But the four gate clauses *are* threshold-bearing — statistical clause uses `ε` and `z`, the generalization clause uses `ρ_gen`, etc. Saying "tunes the threshold, not the clauses" presupposes the threshold is a separate scalar distinct from the clause parameters, which does not match §8's structure as written. This is a consistency problem with §8 (lines 222–228): there is no single `bar` variable in §8's definition that sits outside the four clauses.

**Finding Cs-4 — §19.6's reference to "feedback instability" mitigation cites the §14 breaker but §14 only triggers on ECE.**
§19.6 (line 549): "the breaker (§14) halts oscillation." §14.3 (line 351) triggers the circuit breaker on `ECE_band > τ_cal`. ECE is a probability calibration metric, not a bar-stability metric. A bar that is oscillating ±η_gate between episodes would not necessarily show elevated ECE. This cross-reference is soft.

**Score: 75** — Overall consistent with the established §2/§8/§14 framework, but Cs-3 (the "tunes only the threshold" claim is inconsistent with §8's structure) and Cs-4 (the breaker cross-reference is imprecise) are genuine inconsistencies.

---

### 9. Calibration / honesty

**Finding Ca-1 — The "ROC over logged pairs" framing overstates precision (blocker for honest spec-writing).**
As established in C-1, FAR is estimated from a biased sample. The spec presents this as a clean "learned ROC" without acknowledging the estimator bias. For a spec that has been exemplary in its honesty about the limits of statistical methods (RC-1 in ALGORITHM-v0.1-redteam.md explicitly warns against acting on noisy estimates), using an unqualified ROC framing for a quantity that is systematically biased by a non-uniform exploration strategy falls below the standard the rest of the spec sets.

**Finding Ca-2 — The claim "§19 can only raise assurance or reduce false-rejects within the safe region" is overstated.**
§19.3 (lines 534–535) states this as a consequence of the clamp. This is true in the limit (the clamp is the enforcer), but it ignores the possibility that `bar_ceiling` is set below the locally optimal threshold for some band, preventing learning from raising assurance further. The claim should be "within the `[bar_floor, bar_ceiling]` corridor, §19 can only raise or maintain strictness" — not "raise assurance" globally.

**Finding Ca-3 — "Monotone toward strictness" is framed as a property of the algorithm, but it only holds if `α_gate` is never relaxed.**
If `α_gate` is a tunable parameter (§19.7 lists it as such), a human operator raising `α_gate` (permitting more false-accepts) combined with the bar-learning converging toward a higher `α_gate` level would effectively loosen the gate, even with the `bar_floor` clamp in place — because the bar would settle at a lower point within `[bar_floor, bar_ceiling]` than before. The spec does not distinguish "bar is monotone toward strictness in one tuning run" from "the gate is monotone toward strictness across all parameter changes." This distinction matters for the safety argument.

**Finding Ca-4 — Feedback-loop risk is acknowledged but the analysis is thin.**
§19.6 (lines 545–549) lists risks and mitigations. The moving-borderline window feedback loop (R-3 above), where the calibration data is always drawn from near the current bar's position, is not discussed. The spec correctly identifies the main accept/reject feedback loop but misses this more subtle interaction.

**Score: 68** — The section is honest about the existence of feedback risks but overstates the cleanness of the ROC construction and the universality of the "monotone toward strictness" claim. The spec holds itself to a high evidential standard in §§2–18; §19 falls somewhat short of that standard at several key claims.

---

## Strongest adversarial objection

**The fleet-adversarial input-distribution attack on the meta-gate (not covered by any of the nine dimension findings above).**

Consider a fleet of M3 agents (§18) that have learned — via §17 SOLVE optimization — that *selectively submitting near-threshold changes* to the commit gate inflates the FAR estimate in a direction that moves `bar` downward (toward `bar_floor`). No agent writes to JUDGE. No agent edits the calibration logic. Each agent simply produces SOLVE candidates whose held-out competence deltas are clustered just above the bar, so they are accepted. Over time, the accepted-then-regressed count (FP) rises; the calibration system detects elevated FAR; it raises the bar. But simultaneously, agents also generate candidates just below the new bar — which are sampled by `q_explore` and admitted to shadow runs, biasing the TN estimate toward outcomes that just barely fail. The combined effect is a bar that oscillates in a range determined by the collective submission strategy of the fleet, not by the actual learning quality the gate is supposed to measure.

This is not verifier capture (RC-2) because no agent touches the verifier, item generator, or gate logic. It is not threshold drift from noise (RC-1) because the signal is real (the candidates really are near-threshold). It is input-distribution manipulation of the calibration data that produces a systematic bias in the FAR estimate — a form of Goodharting the meta-gate through the data rather than the code. The spec's JUDGE partition and SOLVE/JUDGE boundary do not address input-distribution attacks; they address write-path attacks. §19.6's risk list does not include this class of attack. §18.6 does not include it either. The only partial defense is `η_gate` (slow bar movement), which limits the *rate* of drift but not its eventual direction.

This is the strongest adversarial objection because it is structurally analogous to the v0.1 verifier-gaming failure (RC-2, ALGORITHM-v0.1-redteam.md lines 42–44: "the whole system is an optimizer aimed at it") applied one level up: §19 makes the bar a learned quantity, and a fleet optimizer aimed at the bar can game the calibration data without touching any code.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety)
                = min(70, 68, 72)
                = 68

weighted_mean   = (Correctness×2 + DesignFaithfulness + RedTeam×2
                   + Implementability + Safety×2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
                = (70×2 + 82 + 68×2 + 72 + 72×2 + 85 + 65 + 75 + 68) / 11
                = (140 + 82 + 136 + 72 + 144 + 85 + 65 + 75 + 68) / 11
                = 867 / 11
                = 78.8

overall         = min(68, 78.8) = 68
```

**Overall confidence: 68 / 100**

---

## Verdict

**needs-revision**

The Red-team score (68) falls below the 70 CRITICAL threshold, which alone triggers `needs-revision`. The Correctness score (70) is at the floor. Specific blocking changes required:

1. **Resolve which §8 threshold parameter `bar` refers to.** §8 has four threshold-bearing clauses (`z`, `ε`, `ρ_gen`, `ε_cum`) and no single `bar` scalar. §19 must specify: (a) which parameter(s) `bar` represents, (b) how `bar_floor` maps to those parameters (globally or per-band), and (c) whether a per-band §8 baseline requires a per-band `bar_floor`. Until this is resolved, the entire mechanism is undefined. *(Fixes C-2, I-1, Cs-3)*

2. **Correct the FAR observability claim.** §19.2's "learned ROC" and the FAR formula must be stated as an estimate: `FAR_hat = FP / (FP + TN_hat)` where `TN_hat` is derived from the `q_explore` sample with acknowledgement that (a) borderline rejects are over-represented, (b) the SE used in `significant(FAR − α_gate, SE)` must incorporate sampling-fraction uncertainty from the `q_explore` quota, not just the Bernoulli SE of FP counts. *(Fixes C-1, Ca-1)*

3. **Define "borderline" operationally for `q_explore`.** Specify the criterion (e.g., within `δ · η_gate` of the current bar, for some `δ`), note that the borderline window moves with the bar, and bound the resulting moving-window feedback (R-3). One option: fix the borderline definition relative to `bar_floor`, not the current bar, so the sampling frame is stable. *(Fixes Co-1, R-3)*

4. **Add the fleet-adversarial input-distribution risk to §19.6.** The JUDGE partition closes write-path attacks but not input-distribution manipulation by a §18 fleet. §19.6 must acknowledge this class and provide at least one mitigation (e.g., stratified sampling of calibration pairs across the score distribution, not just borderline; anomaly detection on submission-score distribution). *(Fixes R-2 residual)*

5. **Require explicit `q_explore` outcome isolation.** §19.1 must state as a hard invariant — parallel to §17.1's JUDGE write-path statement — that shadow-run outcomes from `q_explore` are **not** propagated to competence posterior `C` (§3) and are logged under a distinct flag in TruthStore so they are not counted as real commits for any subsequent gate's calibration. *(Fixes S-3)*

6. **Add `bar_ceiling` default and rationale; add §19-specific breaker condition.** `bar_ceiling` requires a default and derivation (e.g., the maximum `z · SE` achievable given the available `n_cal`). Add a §19-specific breaker condition for runaway bar drift (e.g., `bar_change_over_window > threshold`) that is distinct from §14's ECE trigger. *(Fixes Co-2, S-5)*
