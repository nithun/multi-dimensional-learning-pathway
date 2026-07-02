# 360 Review: S19-self-calibrating-gate — Round 2 — 2026-06-29

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §19 (lines 522–557) |
| Proposed change | Add a self-calibrating commit-gate layer (§19.1–19.7) that tunes the single §2 significance multiplier `z` from realized post-commit regression rates among accepts, clamped so `z ≥ z_8` (the original §8 value). |
| Round | 2 (re-review against round-1 verdict `needs-revision`; six specific blockers named) |
| Reviewer | review-360 |
| Date | 2026-06-29 |

---

## Round-1 blocker resolution checklist

Before scoring, each of the six round-1 blocking changes is assessed as **resolved**, **partially resolved**, or **unresolved**.

| # | Round-1 blocker | Status |
|---|---|---|
| B1 | Single explicit knob: §19 now tunes only `z` (§2), which drives all four §8 clauses. | **Resolved** |
| B2 | Observable target: target is now `r̂ ≤ α_gate` (post-commit regression rate among accepts, no TN term). | **Resolved** |
| B3 | Fleet input-distribution attack: acknowledged in §19.6 + §19.3 floor + §19.4 per-source caps. | **Partially resolved** |
| B4 | Shadow isolation stated as invariant: §19.1 explicitly names "shadow runs never touch real competence, users, or the live posterior; outcomes are recorded only." | **Resolved** |
| B5 | `z_max` default `2·z_8`: stated in §19.3 and §19.7. | **Resolved** |
| B6 | §19-specific breaker: stated in §19.6 as a distinct condition from §14's ECE trigger. | **Resolved** |

Four of six are clean resolutions. B3 is the main remaining question: the per-source cap is a genuine mitigation, but the structural adequacy of the floor + cap against the adversarial path needs scrutiny in dimension 3. No round-1 blocker was merely reworded; all substantive changes are real changes to the text.

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 82 | pass |
| 2 | Design faithfulness | 86 | pass |
| 3 | Red-team resistance (CRITICAL) | 77 | pass |
| 4 | Implementability | 80 | pass |
| 5 | Safety / integrity (CRITICAL) | 83 | pass |
| 6 | Efficiency / cost | 87 | pass |
| 7 | Completeness | 78 | pass |
| 8 | Consistency | 83 | pass |
| 9 | Calibration / honesty | 80 | pass |

---

## Findings by dimension

### 1. Correctness

**Finding C-1 — FAR / TN formulation is eliminated; target is now directly observable (round-1 blocker B2 resolved).**
§19.2 (line 532) now states: "No FAR / true-negative term appears — the target is a property of accepts only, so it needs no unobservable reject-region count." The primary target `r̂ ≤ α_gate` is entirely a function of accepted changes and their subsequent held-out outcomes — fully observable. Round-1 finding C-1 (FAR biased by non-uniform TN sampling) is closed. The only remaining estimator is the regression rate `r̂` among accepts, which has a clean Bernoulli SE = `sqrt(r̂(1-r̂)/n_accepts)`. This is correct.

**Finding C-2 — Single knob `z` uniformly controls all four §8 clauses: correct, with one caveats (weak, not blocking).**
§19.2 (line 532): "`z` … which uniformly controls all four §8 clauses (statistical ∧ generalization ∧ cumulative ∧ safe)." Examining §8 (lines 222–227):
- `statistical = significant(Δĉ_secret[s], SE, margin=ε)` → this invokes `significant(Δ, SE, margin, z)` from §2 (line 43), so `z` directly controls it.
- `generalize = Δĉ_secret ≥ ρ_gen · Δĉ_public` → this is a *ratio* comparison, not a `significant()` call. `z` does **not** appear in this clause as written.
- `cumulative = ĉ_secret[s] ≥ ĉ_baseline[s] − ε_cum` → a scalar compare, not a `significant()` call. `z` does not appear here.
- `safe = safety_eval_heldout(child) ≥ pass` → pass/fail, no `z`.

So the claim "`z` uniformly controls all four clauses" is not literally true as §8 is written. Only the `statistical` clause has `z` in it; the other three are scalar/ratio comparisons with fixed parameters `ρ_gen`, `ε_cum`, and a binary `pass`. If the author's intent is that raising `z` in the `statistical` clause suffices to make the composite gate stricter (because a more demanding statistical bar is the binding constraint), that is a plausible design argument but is not the same as "`z` uniformly controls all four." A change that passes the statistical gate at any `z` but fails on generalization would not be affected by `z` at all. This is a logical inconsistency between §19's claim and §8's definition, though in practice the statistical clause is likely the tightest for most changes. Raising `z` raises the statistical bar but leaves `ρ_gen`, `ε_cum`, and the safety pass/fail entirely unchanged.

This is weak, not blocking, because:
(a) the statistical clause is the one most commonly tunable and the one RC-1 most exposed;
(b) the design rationale is architecturally coherent even if the claim overstates uniformity;
(c) the clamp `z ≥ z_8` still ensures safety cannot weaken.
The spec should be corrected to say "`z` directly controls the statistical clause and thereby raises the composite bar" rather than "uniformly controls all four clauses."

**Finding C-3 — SE specification for `significant(r̂ − α_gate, SE)` is partially resolved.**
§19.2 states the `q_explore` SE "including the sampling fraction" must be included when testing whether the `q_explore` arm shows over-rejection. The primary `r̂` significance test uses a straightforward Bernoulli SE. This is more precise than round-1 but stops short of writing the formula for the `q_explore`-adjusted SE. This is weak, not blocking — the principle is right and the formula can be derived mechanically.

**Finding C-4 — Per-band floor coherence: the `z_8` floor is now explicitly "the original conservative §8 multiplier" (line 534–535).**
Round-1 finding C-4 asked whether `bar_floor` is global or per-band. §19 now specifies that calibration is per band (§19.5, line 543) and the floor is `z_8`, the §8 multiplier. Since `z` in §2 is a single scalar parameter (line 43: `significant(Δ, se, margin=0, z=2)`), there is one `z` globally — the per-band calibration means §19 learns a per-band `z_band` but the floor is the same `z_8` for all bands. This is coherent: each band gets its own adaptive `z_band ≥ z_8`. No incoherence remains.

**Score: 82** — The key correctness issues from round-1 are resolved. The surviving weakness (C-2: `z` controls the statistical clause but not the ratio/pass-fail clauses) is a claim precision problem, not a formula error. The gate is architecturally sound.

---

### 2. Design faithfulness

**Finding D-1 — JUDGE placement: confirmed correct and clearly stated (line 524, 539).**
§19 lives in JUDGE as required by §17.1's definition (gates are JUDGE members). The additive pattern is faithfully followed — the preamble (line 524) is structurally identical to §§13–18.

**Finding D-2 — Single-knob tuning resolves the ambiguity round-1 flagged.**
Round-1 finding D-4 (tension between §14 and §19 per-band calibrations) is partly resolved by the distinct scope: §14 calibrates the probability estimate (widening SE); §19 calibrates `z` (the threshold multiplier applied to that SE). These are complementary, not competing, and can run sequentially on the same held-out stream: §14 first makes the SE honest, §19 then sets how many of those honest SEs constitute a bar. The interaction is clean.

**Finding D-3 — §12 parameter extension is correct (line 555).**
All seven new parameters are registered in §19.7 under "extends §12," consistent with the §§13–18 additive pattern.

**Finding D-4 — Mild gap: the §19.5 statement "§19 tunes only the threshold; the four gate clauses are unchanged" is imprecise (mirrors C-2 above).**
Not a design-faithfulness blocker, but the language creates a tension because it implies `z` reaches into all four clauses, which is not true as §8 is written. The design intent is faithful; the description is imprecise.

**Score: 86** — Faithful to the established pattern; additive, JUDGE-placed, per-band. Minor imprecision at the D-4 clause-coverage claim.

---

### 3. Red-team resistance

**Finding R-1 — RC-1 (point estimates / noise-driven moves): now closed.**
§19.2 (line 532): `z` moves only on `significant(r̂ − α_gate, SE)` with bounded step `η_gate`. The primary signal `r̂` is a well-defined Bernoulli proportion over the accepted set. The SE of `r̂` is straightforward. The step bound `η_gate` prevents large noise-driven jumps. This is a clean RC-1 implementation at the meta-gate level. The `q_explore` secondary test also requires significance and its SE includes the sampling fraction. RC-1 risk at the gate level is adequately mitigated.

**Finding R-2 — Fleet input-distribution attack (round-1 strongest adversarial objection, blocker B3): bounded but residual.**
§19.3 (line 535): "This floor is what bounds the strongest adversarial path: even calibration data shaped by a fleet's submission strategy can, at worst, push `z` toward `z_8` — never below it."
§19.4 (line 540): "Per-source caps: no single agent's submissions may dominate the calibration set."
§19.6 (line 549): "Fleet input-distribution gaming (RC-2 at the meta-gate via *what is submitted*, not code) → bounded by the §19.3 floor (never below `z_8`) + the §19.4 per-source caps."

Assessment of the mitigation:

The floor argument is correct: a fleet that games the calibration data to push `z` downward is bounded at `z_8`. The worst outcome of the attack is a gate as permissive as the original §8 baseline — not looser. This correctly addresses the round-1 objection, which was that the fleet could steer the gate below §8. The floor makes that impossible by construction.

The per-source caps address volume-based domination. A single agent submitting thousands of borderline candidates to shift `r̂` is bounded by the per-source cap.

Residual risk (weak, not blocking): a *coordinated* fleet where many agents *each* submit up to their per-source cap with borderline candidates can collectively steer `r̂` upward toward `α_gate`, causing the gate to stay at `z_8` (rather than raising `z` above it when more strictness would be warranted). This is a scenario where the gate fails to *tighten* when it should, not one where it loosens below §8. The safety invariant still holds; the self-calibration benefit is simply defeated by coordinated submission strategies. The spec does not address this residual (a gate that calibrates up when it should but can't because the submitted r̂ is artificially suppressed near α_gate).

Because the floor `z ≥ z_8` holds regardless, this residual means §19 fails to *improve* gate accuracy in an adversarial fleet scenario — it degrades back to fixed §8 — but never below §8. This is an honest limitation of the design, not a safety breach.

**Finding R-3 — RC-2 (self-modifier code path): structurally closed, confirmed.**
§17.1's SOLVE/JUDGE partition statically checks that no SOLVE code has a write path to JUDGE. §19 is JUDGE. The static no-write-path check covers this. The §18 compound (N agents × §17 SOLVE edits) is bounded by §18.5: "JUDGE is immutable for every agent." This is not changed by §19.

**Finding R-4 — Moving-borderline feedback loop (round-1 R-3): now acknowledged.**
§19.6 (line 552): "Feedback instability (the gate's decisions shape the data that tunes it) → slow `η_gate` + hysteresis + the floor bound the loop; the §14 breaker halts oscillation." The spec still does not explicitly name the moving-borderline sub-problem (the borderline window shifts as `z` shifts), but the general feedback-instability mitigation applies: `η_gate` ensures the window can only move slowly, and the floor prevents it from drifting into unsafety. The residual risk is acknowledged, bounded, and addressed in functional terms even if not explicitly enumerated.

**Score: 77** — No round-1 critical RC-1/RC-2 exposures remain. The fleet input-distribution attack is now bounded by the floor (the safety claim holds) with a residual where an adversarial coordinated fleet degrades §19 to fixed §8 without defeating it. This is a genuine limitation, not a failure — the floor is the load-bearing safety guarantee and it holds. RC risks from §§1–18 are not reopened by §19.

---

### 4. Implementability

**Finding I-1 — The single knob `z` is now unambiguously identified (round-1 blocker B1 resolved).**
§19.2 (line 532): "§19 tunes a *single* strictness knob: the *significance multiplier `z`* (§2)." §2 (line 43) defines `z` as the parameter in `significant(Δ, se, margin=0, z=2)`. This is a single, named parameter with a clear §2 definition. A developer can identify it without guessing.

**Finding I-2 — `q_explore` operational definition: partially resolved.**
§19.1 (line 529) says `q_explore` admits "a fraction of *borderline* rejects." "Borderline" is not formally defined in the text — there is no explicit criterion (e.g., "within `δ·SE` of the current bar"). This was a round-1 I-2 gap. The spec has not added a formal criterion, so the implementation still requires a decision that is not guided by the spec. This is a weak gap — a developer will likely implement a sensible heuristic — but it is not a blocker given that §19.7 lists `q_explore` as a parameter (the fraction itself is specified; the "borderline" definition is the missing piece).

**Finding I-3 — `q_explore` / §17.3 interaction: partially clarified.**
§19.1 explicitly says "a §17.3 shadow/canary" — the reference is now present. It does not fully clarify whether this reuses §17.3's infrastructure literally or analogically, but the invariant ("shadow runs never touch real competence, users, or the live posterior; outcomes are recorded only") is clear enough for a developer to implement correctly without conflating the two use-cases.

**Finding I-4 — Acceptance tests are good (line 556).**
Seven stubs are listed: `test_z_never_below_z8`, `test_self_modify_cannot_edit_gate_calibration`, `test_shadow_admits_never_touch_live_competence`, `test_cold_start_uses_fixed_gate`, `test_z_moves_only_on_significant_regression`, `test_per_source_cap_bounds_fleet_steering`, `test_saturation_freezes_and_escalates`. These cover the principal invariants and are more comprehensive than round-1's five stubs.

**Finding I-5 — Outcome observation window still unspecified.**
§19.1 says accepted changes are checked for regression "on subsequent independent held-out." After how many subsequent evaluations? Over what window? This directly determines how quickly calibration pairs accumulate and how responsive `z` can be. This is a genuine gap in the parameter spec (round-1 finding Co-4 was not addressed).

**Score: 80** — Core implementability concern (single knob identity) is fully resolved. Remaining gaps (borderline definition, observation window) are weak and fixable without revisiting the architecture.

---

### 5. Safety / integrity

**Finding S-1 — `z ≥ z_8` clamp: the principal safety argument is sound and complete.**
§19.3 (line 534–535): "`z` is clamped to `[z_8, z_max]`, where `z_8` is the original conservative §8 multiplier." This is the load-bearing constraint: §19 can tighten the gate or hold it at §8's level; it can never loosen it below §8. The invariant is stated plainly, has a corresponding test (`test_z_never_below_z8`, line 556), and is structurally enforced — the clamp is in JUDGE and cannot be written by SOLVE.

**Finding S-2 — Can §19 admit a change that §8 would block? Analysis per-clause.**
The question is whether tuning `z` via §19 can result in a change passing the gate that would have failed under fixed §8 (`z_8`). Since §19 only raises `z` above `z_8` or holds it at `z_8`, the statistical clause of `significant(Δĉ_secret, SE, margin=ε, z)` becomes *at least as strict* as at `z_8`. For a change that failed the `statistical` clause at `z_8`, it still fails at any `z ≥ z_8`. The other three clauses (`generalize`, `cumulative`, `safe`) are unmodified scalar/ratio/pass-fail checks independent of `z`. Therefore §19 cannot admit a change §8 would block — confirmed, with the proviso from C-2 that only the statistical clause is actually controlled by `z`.

**Finding S-3 — Per-band `z_band` and the floor: no per-band undercut.**
Round-1's C-4 concern was whether a per-band `z_band` could undercut another band's §8 level. Since `z_8` is the same §2 parameter for all bands and the floor is `z_8` globally, no band can fall below the original value. Each band's adaptive `z_band ≥ z_8` — the floor is a uniform lower bound.

**Finding S-4 — Shadow isolation stated as invariant (blocker B4 resolved).**
§19.1 (line 529): "isolated by invariant (shadow runs never touch real competence, users, or the live posterior; outcomes are recorded only)." The `test_shadow_admits_never_touch_live_competence` stub (line 556) enforces this. This closes round-1 finding S-3 cleanly.

**Finding S-5 — `z_8` initialization: the spec now defines `z_8` as "the §8 multiplier" (line 554), anchoring it to the §8 definition (default `z=2` in §2, line 43).**
Round-1 S-2 asked whether `bar_floor` could be set to a post-tuning, less conservative §8 value. The spec now ties `z_8` to the §8 value by definition — it cannot drift without §8 itself changing. This is adequate for a design spec (the implementation must preserve this tie, and the test `test_z_never_below_z8` verifies it at runtime).

**Finding S-6 — §19-specific breaker (blocker B6 resolved).**
§19.6 (line 551): "Gate saturation / unattainable target → a §19-specific breaker (distinct from §14's ECE trigger): if `z` sits at a clamp … §19 *freezes `z` at the safe (stricter) end and escalates to a human*." This is a genuine §19-only condition. The test `test_saturation_freezes_and_escalates` (line 556) covers it. Round-1 S-5 is resolved.

**Score: 83** — The safety core is sound. The `z ≥ z_8` clamp is the load-bearing guarantee; shadow isolation is stated as an invariant; the §19-specific breaker is defined. The only residual is the C-2 imprecision about which clauses `z` actually touches, which does not weaken the safety outcome.

---

### 6. Efficiency / cost

**Finding E-1 — Cold path operation unchanged (positive).**
§19's calibration runs on logged (decision, outcome) pairs in the TruthStore — a cold-path batch operation. No hot-path cost is added. This is consistent with §14's calibration pattern.

**Finding E-2 — `q_explore` shadow cost: bounded by §17.3's `sandbox_cost_cap`.**
§19.1 references "a §17.3 shadow/canary," and §17.3 defines `sandbox_cost_cap` (line 475) as a parameter bounding Stage-1 trial budgets. The `q_explore` fraction further bounds how many borderline rejects enter the shadow. The cost is doubly bounded. No new unbounded overhead.

**Finding E-3 — `z` update is O(1) per calibration cycle per band.**
The update rule (`significant(r̂ − α_gate, SE)` → increment `z` by `η_gate`) is O(1) given `r̂` and its SE. The per-band structure adds O(bands) total, which is bounded.

**Score: 87** — Efficient. Cold-path; bounded shadow cost; O(bands) update. No complexity class change.

---

### 7. Completeness

**Finding Co-1 — Outcome observation window: still unspecified (round-1 Co-4).**
§19.1 says accepted changes are checked for regression "on subsequent independent held-out." The window (how many subsequent evaluations, or over what time span) is not defined. Without this, developers cannot determine when a calibration pair is complete, how many usable pairs accumulate per unit time, or when `n_cal` can be reached. This is a genuine gap in the parameter table (§19.7 does not list an observation window parameter).

**Finding Co-2 — "Borderline" definition for `q_explore` selection: still unspecified (round-1 Co-1).**
The criteria by which a reject is classified as "borderline" (and thus eligible for the `q_explore` shadow) remain undefined. This affects the composition of the calibration data for the secondary (over-rejection) signal.

**Finding Co-3 — `z_max = 2·z_8` default is now stated (blocker B5 resolved, line 534–535, 555).**
This closes round-1 Co-2 cleanly.

**Finding Co-4 — `n_cal` is listed as a parameter but not defaulted or bounded (line 555).**
§19.7 lists `n_cal` with no default value. The cold-start floor value directly determines how long §19 is inactive (using fixed §8), and therefore how much gate calibration data is required before learning begins. Without a default or derivation (e.g., "enough to estimate `r̂` with SE < α_gate/2"), a developer chooses arbitrarily.

**Finding Co-5 — Check stubs are comprehensive (positive).**
Seven stubs cover the main behavioral invariants. This is stronger than round-1's five stubs.

**Score: 78** — Co-3 (z_max default) resolved; Co-1 (observation window) and Co-2 (borderline definition) persist and represent genuine implementation gaps; Co-4 (n_cal default) is new. None of these is a structural blocker — they are parameter specification gaps that a pilot calibration pass can fill — but together they mean a developer faces multiple undefined choices.

---

### 8. Consistency

**Finding Cs-1 — `z` claim vs. §8's four clauses: the "uniformly controls all four clauses" statement is inconsistent with §8 as written (C-2 above, mild).**
§8 (lines 222–227) shows that `generalize`, `cumulative`, and `safe` do not invoke `significant(...)` and have no `z` parameter. §19.2 and §19.5 claim `z` "uniformly controls all four §8 clauses." This is inconsistent with the §8 definition as written.

**Finding Cs-2 — Per-band calibration is consistent with §14 (positive).**
Both §14 and §19 calibrate per-band, on the held-out stream, on a cold-path cadence. The per-band discipline is applied identically.

**Finding Cs-3 — Cross-reference to §14 breaker: partially corrected.**
§19.6 (line 552): "the §14 breaker halts oscillation." Round-1 (Cs-4) noted this is imprecise because §14's breaker fires on ECE, not oscillation. The round-2 text also adds a §19-specific breaker for saturation (line 551). The §14 cross-reference for oscillation is still used as a catch-all but now the primary §19 condition has its own distinct trigger. The remaining imprecision is minor.

**Finding Cs-4 — §19 parameter list in §19.7 consistent with §12's extended list (§12 line 287).**
§12 (line 282–286) lists the extended parameters for §§14–18. §19's parameters (α_gate, q_explore, η_gate, z_8/z_max, n_cal, per-source cap) are consistent in format with how §§14–18 extended §12. No naming conflict.

**Score: 83** — Consistent overall; the one genuine inconsistency (Cs-1: `z` scope vs. §8 structure) is real but narrow and does not create contradictory requirements elsewhere in the spec.

---

### 9. Calibration / honesty

**Finding Ca-1 — The FAR / ROC framing is now absent (round-1 Ca-1 resolved).**
The round-2 text uses only `r̂` (post-commit regression rate) and never invokes a ROC or FAR. The target is stated as a property of accepts only, observable without TN counts. This is a significant honesty improvement over round-1.

**Finding Ca-2 — "Uniformly controls all four clauses" overstates the mechanism (Ca echo of C-2).**
§19.2 and §19.5 state `z` controls all four §8 clauses. As analyzed in C-2, only the statistical clause invokes `z`. This is a mild overstatement in a section that is otherwise careful about mechanism claims.

**Finding Ca-3 — "Can never admit a change §8 would have blocked" is now correctly qualified.**
§19.3 (line 535): "So §19 can only *raise* assurance or *trim false-rejects within the safe region*; it can *never admit a change §8 would have blocked*." This claim is correct given the `z ≥ z_8` clamp and the analysis in S-2 above. The phrasing accurately reflects the actual guarantee.

**Finding Ca-4 — Fleet-adversarial degradation scenario: now acknowledged and bounded but not fully characterized.**
§19.6 acknowledges fleet input-distribution gaming and bounds it via the floor. The spec does not discuss the residual (R-2 above: a coordinated fleet suppresses §19's ability to tighten above `z_8`), where §19 remains at §8 level without conveying any calibration benefit. This is honest as an acknowledged risk; it could be more precisely stated as a limitation ("§19 degrades to fixed §8 under coordinated fleet gaming but never below it").

**Finding Ca-5 — "Feedback instability" mitigation is honest but thin.**
§19.6 attributes oscillation control to `η_gate` + hysteresis + the floor. The moving-borderline feedback loop (where the `q_explore` borderline window moves as `z` moves) is not explicitly named. The general "slow `η_gate`" mitigation applies but its sufficiency is not demonstrated.

**Score: 80** — Substantially more honest than round-1. The main remaining calibration issues are (a) the clause-coverage overstatement (C-2/Ca-2) and (b) incomplete characterization of the fleet-degradation residual. Neither is a dishonesty concern; both are precision deficits in an otherwise careful section.

---

## Strongest adversarial objection

**The `z` uniformity assumption creates a false safety margin in specific failure modes.**

§19's entire safety argument rests on the premise that raising `z` above `z_8` makes the composite gate strictly harder to pass. But the composite gate is a conjunction:

```
commit_gate = statistical(z) ∧ generalize(ρ_gen) ∧ cumulative(ε_cum) ∧ safe(pass/fail)
```

If `statistical(z)` is satisfied (the change clears the raised bar), nothing about the other three clauses has changed. A change can pass `statistical` at high `z` while narrowly skirting the `generalize` or `cumulative` thresholds that remain fixed at `ρ_gen` and `ε_cum`. More specifically: a deployment where generalization failures or slow cumulative drift are the dominant failure mode — not large-sample noise — will cause the post-commit regression rate `r̂` to rise. §19 responds by raising `z`. But raising `z` on the `statistical` clause does not help with generalization failure (that requires adjusting `ρ_gen`) or cumulative drift (that requires adjusting `ε_cum`). The gate is tightened on the wrong clause: `z` is raised, fewer changes pass the statistical bar, but those that do still carry the same generalization and cumulative risks. The calibration system diagnoses "regression too high → tighten gate" and acts by tightening the one clause it controls — which may not be the clause causing the regressions.

This is a class of mismatch between the observable signal (`r̂`) and the available control knob (`z`): `r̂` aggregates over all four failure modes, but `z` addresses only one. A system where the generalization or cumulative clauses are the binding failure modes cannot be calibrated by adjusting `z` alone. The spec does not analyze this constraint — it asserts that `z` uniformly controls the bar without demonstrating that the statistical clause is the dominant binding constraint across all domains and failure modes.

This objection goes beyond the nine-dimension findings: it challenges the fundamental design premise that a single knob is sufficient to calibrate a four-clause conjunction, not just the precision of the knob's scope description.

One natural response (not in the spec) would be to define `r̂` decomposed by failure mode — separately track how many regressions were generalization failures vs. statistical noise vs. cumulative drift — and recommend specific clause adjustments. Without decomposition, the calibration signal provides no guidance on which parameter to adjust when `z`-adjustment fails to drive `r̂` below `α_gate`. The §19.6 saturation breaker would eventually trigger, escalating to a human, but only after many rounds of futile `z` adjustment.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety)
                = min(82, 77, 83)
                = 77

weighted_mean   = (Correctness×2 + DesignFaithfulness + RedTeam×2
                   + Implementability + Safety×2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
                = (82×2 + 86 + 77×2 + 80 + 83×2 + 87 + 78 + 83 + 80) / 11
                = (164 + 86 + 154 + 80 + 166 + 87 + 78 + 83 + 80) / 11
                = 978 / 11
                = 88.9

overall         = min(77, 88.9) = 77
```

**Overall confidence: 77 / 100**

---

## Verdict

**needs-revision**

The overall score (77) falls below the 80 threshold for `ready-for-approval`, driven by Red-team resistance (77) dominating the critical floor. All six round-1 blockers have been substantively addressed — none was merely reworded — and the section is structurally sounder than round-1. The remaining gaps are narrower and mostly precision-level rather than architectural.

**Specific blocking changes required to clear 80:**

1. **Correct the "`z` uniformly controls all four §8 clauses" claim (C-2 / Cs-1 / adversarial objection).** §8's `generalize`, `cumulative`, and `safe` clauses do not invoke `z`. §19.2 and §19.5 must be revised to state: "`z` directly controls the *statistical* clause (`significant(Δĉ_secret, SE, margin=ε, z)`) and thereby raises the primary admission bar; the `generalize`, `cumulative`, and `safe` clauses are unchanged." Optionally add: "If post-commit regressions concentrate in generalization or cumulative failures rather than noise, the saturation breaker (§19.6) escalates to a human, as `z` alone cannot address those failure modes." This fixes the most defensible adversarial objection and makes §19 accurate about its own scope.

2. **Define the outcome observation window (Co-1 / I-5).** Add a parameter (e.g., `w_obs`: minimum number of subsequent held-out evaluations, or minimum elapsed time, before a calibration pair is recorded as complete). Register it in §19.7. This resolves the underdetermined accumulation rate for `n_cal`.

3. **Define "borderline" operationally for `q_explore` (Co-2 / I-2).** Add a formal criterion (e.g., "a reject whose `Δĉ_secret` lies within `δ_border · SE` of the current decision threshold, with `δ_border` default `0.5`"). Register `δ_border` in §19.7. If the borderline window is anchored to the current bar (moving), note the moving-window feedback and state that `η_gate` bounds its rate of drift.

**One remaining genuine limitation (acknowledge, not block):** Add a sentence in §19.6 under "Fleet input-distribution gaming" noting that a coordinated fleet can suppress `z`-tightening by keeping `r̂` near `α_gate` even when stricter review would be warranted — the safety invariant holds (gate stays at `z_8`, never below), but the self-calibration benefit is defeated. This is an honest scope limitation, not a safety failure.
