# 360 Review: S19-self-calibrating-gate — Round 3 — 2026-06-29

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §19 (lines 522–562) |
| Proposed change | Add a self-calibrating commit-gate layer (§19.1–19.7) that tunes three per-clause strictness knobs — `z` (statistical), `ρ_gen` (generalization), `ε_cum` (cumulative) — each clamped so it can only move stricter than its §8 default, with per-clause attribution routing regressions to the correct knob, an observation window `w_obs` and borderline margin `δ_border` defined, and thin-data fallback to fixed §8. |
| Round | 3 (re-review against round-2 verdict `needs-revision`; three specific blockers named) |
| Reviewer | review-360 |
| Date | 2026-06-29 |

---

## Round-2 blocker resolution checklist

Before scoring, each of the three round-2 blocking changes is assessed as **resolved**, **partially resolved**, or **unresolved**.

| # | Round-2 blocker | Status |
|---|---|---|
| B1 | Correct the "`z` uniformly controls all four §8 clauses" claim — §8's `generalize`, `cumulative`, and `safe` clauses do not invoke `z`; §19.2 and §19.5 needed revision. | **Resolved** |
| B2 | Define the outcome observation window — add `w_obs` and register it in §19.7. | **Resolved** |
| B3 | Define "borderline" operationally for `q_explore` — add a formal criterion and register `δ_border` in §19.7. | **Resolved** |

All three blockers are substantively resolved, not merely reworded. The key architectural change is the shift from a single-knob `z` to per-clause attribution with three distinct tunable knobs, each clamped independently. This directly addresses the round-2 adversarial objection (tightening the wrong clause).

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 88 | pass |
| 3 | Red-team resistance (CRITICAL) | 85 | pass |
| 4 | Implementability | 83 | pass |
| 5 | Safety / integrity (CRITICAL) | 87 | pass |
| 6 | Efficiency / cost | 87 | pass |
| 7 | Completeness | 83 | pass |
| 8 | Consistency | 87 | pass |
| 9 | Calibration / honesty | 84 | pass |

---

## Findings by dimension

### 1. Correctness

**Finding C-1 — The "uniformly controls all four clauses" overstatement is eliminated (round-2 blocker B1 resolved).**
§19.2 (line 532) now states the attribution architecture explicitly: each regressed accept is attributed to the clause it passed most marginally, and §19 tightens *that* clause's knob — `z` (§2) for the statistical clause, `ρ_gen` for generalization, `ε_cum` for cumulative, with the safe clause explicitly excluded from tuning. The preamble (line 524) also correctly enumerates all three tunable knobs. The round-2 correctness flaw — claiming `z` uniformly controls four clauses when only the statistical clause invokes `z` — is resolved by design: the spec now assigns a distinct knob to each clause. This is the architecturally correct fix.

**Finding C-2 — Per-clause clamp directions are correct.**
§19.3 (line 535): `z ∈ [z_8, 2·z_8]`, `ρ_gen ≥ ρ_gen⁸`, `ε_cum ≤ ε_cum⁸`. Each direction must be verified independently:
- `z` higher → `significant(Δ, SE, margin, z)` requires `Δ > margin + z·SE` → harder to satisfy → stricter. Correct.
- `ρ_gen` higher → `Δĉ_secret ≥ ρ_gen · Δĉ_public` requires a larger secret/public ratio → harder to satisfy → stricter. Correct.
- `ε_cum` lower (floor is the lower bound, `ε_cum ≤ ε_cum⁸`) → `ĉ_secret[s] ≥ ĉ_baseline[s] − ε_cum` requires the current competence to stay closer to the baseline (smaller allowed degradation) → harder to satisfy → stricter. Correct. The directional logic is sound for all three knobs.

**Finding C-3 — Loosening condition is directionally consistent with the floor.**
§19.2 (line 532): a loosening step is "never below the §8 floor (§19.3)." For each knob: a loosening step on `z` moves it toward `z_8` (the floor), so the clamp `z ≥ z_8` prevents loosening below §8. For `ρ_gen ≥ ρ_gen⁸`, a loosening step moves `ρ_gen` toward `ρ_gen⁸` (the floor). For `ε_cum ≤ ε_cum⁸`, a loosening step raises `ε_cum` toward `ε_cum⁸` (the ceiling). In all three cases the §8 default is the boundary and a loosening step cannot cross it. The loosening condition is correctly coupled to the clamp structure.

**Finding C-4 — "Marginal clause" attribution: the criterion is well-defined for the statistical clause; it is underspecified for cumulative and generalization.**
§19.1 (line 529) says the attributed clause is "the clause it passed most marginally." For the statistical clause, marginality is naturally measured in units of `z·SE` — how many SE above the threshold did the acceptance sit? For the generalization clause, it would be the ratio `Δĉ_secret / (ρ_gen · Δĉ_public)` measured against 1.0. For the cumulative clause, it would be `ĉ_secret[s] − (ĉ_baseline[s] − ε_cum)` measured against 0. These are comparable only after normalization (each expressed as a fraction of its own threshold), and the spec does not state how multi-clause margins are placed on a common scale for comparison. This is a weak gap — a developer can choose a normalization — but it is a genuine underdetermination that could produce different attribution behaviors in multi-clause near-misses.

**Finding C-5 — `w_obs` and `δ_border` are now defined and registered (round-2 blockers B2, B3 resolved, line 529, 557).**
`w_obs` (observation window after commit) is named in §19.1 and listed in §19.7. `δ_border` (borderline margin — a reject whose decisive clause missed its threshold by less than `δ_border`) is operationally defined in §19.1 and listed in §19.7. Both parameters have defaults/registrations that are compatible with a developer implementing them. The round-2 Co-1/Co-2 gaps are closed.

**Score: 88** — The principal correctness concern across rounds 1 and 2 is resolved by the per-clause architecture. Three remaining minor gaps: the marginal-clause comparison normalization (C-4), the SE formula for the multi-knob significance tests is not written out (though the principle is stated), and `n_cal` still lacks a default value. None is blocking.

---

### 2. Design faithfulness

**Finding D-1 — Per-clause tuning is coherent with §8's four-clause conjunction.**
§8 (lines 222–227) defines four named Boolean clauses. §19.2 maps each to a distinct tunable parameter (`z`, `ρ_gen`, `ε_cum`) or marks it untounable (`safe`). The architecture is tightly coupled to §8's actual structure rather than a simplified abstraction of it. This is a stronger design-faithfulness signal than round 2, where the single-knob claim was inconsistent with §8.

**Finding D-2 — JUDGE placement, additive pattern, and §12 parameter extension: unchanged and correct.**
§19 (line 524) is tagged as additive, JUDGE-resident, with seven new parameters registered in §19.7 (line 557) per the §§13–18 convention. The preamble structure matches §§13–18 precisely. No divergence from the established §§2–15 layering.

**Finding D-3 — Interaction with §14 (calibration) and §2 (gate primitive): consistent and complementary.**
§19 tunes thresholds; §14 calibrates the probability estimate (the SE inputs). The two layers operate on different parts of the `significant()` call — §14 makes the SE honest, §19 tunes `z` that multiplies it. The multi-knob extension does not disturb this complementarity: `ρ_gen` and `ε_cum` are scalar parameters not modified by §14 at all, so no interaction conflict arises.

**Finding D-4 — §19.5 "§19 tunes only the thresholds; the four gate clauses and their conjunction are unchanged" is now precise.**
In round 2, this statement was imprecise because it implied `z` reached into all four clauses. In round 3, the statement is accurate: the four-clause conjunction structure is unchanged (the clauses themselves are still `statistical ∧ generalize ∧ cumulative ∧ safe`); §19 only tunes the parameters within each clause's existing formula. The structure/parameter distinction is now correctly drawn.

**Score: 88** — Strong design faithfulness. The per-clause architecture is tightly aligned with §8's actual structure.

---

### 3. Red-team resistance

**Finding R-1 — Round-2 adversarial objection resolved: attribution prevents wrong-clause tightening (RC-2 root at meta-gate level).**
The round-2 strongest adversarial objection was: a system where generalization or cumulative failures dominate will cause `r̂` to rise, and §19 (single-knob) responds by raising `z` — which addresses the statistical clause but not the dominant failure mode. §19.6 (line 547) now explicitly names this: "Tightening the wrong clause → per-clause attribution routes each regression to the clause it slipped through; raising `z` cannot mask a generalization or cumulative leak." The attribution mechanism in §19.2 prevents the single-knob failure mode by design. If generalization failures dominate, `ρ_gen` is raised; if cumulative failures dominate, `ε_cum` is lowered; `z` is only raised for statistical-clause failures. This is the correct fix.

**Finding R-2 — Fleet input-distribution attack: now correctly characterized for all three knobs.**
§19.3 (line 535): "even calibration data shaped by a fleet's submission strategy can, at worst, push the knobs toward their §8 defaults — never past them." This statement holds for all three knobs:
- For `z`: the floor `z_8` prevents the knob being pushed below §8.
- For `ρ_gen`: the floor `ρ_gen⁸` prevents it being pushed below §8.
- For `ε_cum`: the floor `ε_cum⁸` prevents it being raised above §8 (the floor is a ceiling in this direction).
The coordinated-fleet suppression residual (round-2 R-2: a coordinated fleet can keep `r̂` near `α_gate` per clause to prevent tightening) remains as a genuine limitation. The spec now acknowledges it in §19.6 (line 551): "below `n_cal` per clause, §19 falls back to the fixed §8 default for that clause — under-supply degrades to §8, never to a looser gate." A coordinated fleet that starves one clause of `n_cal` tuples causes that clause to stay at its §8 default — which is safe (never looser), but defeats per-clause calibration benefit. This is an honest bounded limitation.

**Finding R-3 — RC-1 (noise-driven moves): held across all three knobs.**
Each knob moves only on `significant(r̂_clause − α_clause, SE)` by a bounded step `η_gate`. The multi-knob structure does not weaken this: per-clause significance tests are computed over the same Bernoulli SE with the sampling-fraction correction for `q_explore`. Three separate significance tests add no new noise-amplification risk; they reduce it (each test is applied only to regressions attributed to its own clause, not the aggregate signal).

**Finding R-4 — RC-2 (self-modifier code path): closed for all three knobs.**
§19 is in JUDGE (line 524, 539). The `test_self_modify_cannot_edit_gate_calibration` stub covers all three knobs by testing the JUDGE membership invariant generically. The multi-knob extension does not create new write paths.

**Finding R-5 — New adversarial surface: per-clause attribution can be gamed if the marginal-clause metric is manipulated.**
This is a new concern not present in rounds 1–2. The attribution rule attributes each regressed accept to "the clause it passed most marginally." If an attacker (a self-modifier, or a sophisticated fleet member) can control the margin by which its changes pass each clause — e.g., always passing the generalization clause with a large margin while barely passing the statistical clause — it can systematically direct all attributions to `z`, keeping `ρ_gen` and `ε_cum` at their §8 defaults while subjecting only `z` to tightening. Whether this is exploitable depends on whether a submitter has enough control over how its submission sits relative to each clause's threshold. The floor (§19.3) bounds the worst case to §8 defaults on the non-targeted knobs, so this does not create a safety breach — but it means the generalization and cumulative knobs could be permanently held at their §8 values by a strategically-behaving submitter while only `z` tightens. This is a residual attack on §19's calibration benefit, not a safety failure.

**Score: 85** — The round-2 adversarial objection (wrong-clause tightening) is resolved by the per-clause architecture. The safety floor holds across all three knobs. Remaining residuals: coordinated fleet can defeat calibration (but not safety), and a strategic submitter can bias attribution to `z` (but cannot loosen any knob below §8). Both are acknowledged or bounded by the design.

---

### 4. Implementability

**Finding I-1 — Per-clause attribution: the rule is stated but the normalization for "most marginal" is unspecified (echoes C-4).**
A developer implementing `argmin_clause(pass_margin_clause / threshold_clause)` needs to decide how margins across the three clauses are compared. The statistical clause margin is `(Δĉ_secret − (ε + z·SE)) / (z·SE)` (normalized excess). The generalization clause margin is `(Δĉ_secret / Δĉ_public − ρ_gen) / ρ_gen`. The cumulative margin is `(ĉ_secret[s] − ĉ_baseline[s] + ε_cum) / ε_cum`. These are dimensionless ratios but are not on the same scale. The spec says only "the clause it passed most marginally" without specifying the normalization. This is the implementability analog of C-4.

**Finding I-2 — Three per-clause significance tests: SE specification is stated for `q_explore`, partially for the primary signal.**
§19.2 states the SE for `q_explore` includes the sampling fraction. The SE for `r̂_clause` (per-clause regression rate) uses a Bernoulli SE over the accepted-and-attributed set. With per-clause attribution, the per-clause `n_accepts_clause` (number of accepts attributed to that clause) may be small, especially for the generalization or cumulative clauses if statistical failures dominate. The spec does not address the case where `n_accepts_clause < n_cal` for a specific clause: should that clause's significance test also fall back to fixed §8 for that clause? §19.5 says below `n_cal` per clause, §19 is off — this is the correct answer, but the interaction between the per-clause cold-start floor and the per-clause attribution count is not explicitly stated. A developer could implement this correctly by reading §19.5 as applying to both the incoming calibration tuple count and the per-clause attributed count, but the connection is implicit.

**Finding I-3 — `w_obs` and `δ_border` are defined and registered (round-2 B2, B3 fully resolved).**
§19.1 (line 529): "`w_obs` after commit" and "`δ_border`" are both named with their operational definition. §19.7 (line 557) lists them in the parameter table. A developer can implement both. `w_obs` resolves the observation window gap (round-2 Co-1/I-5); `δ_border` resolves the borderline definition gap (round-2 Co-2/I-2). Both round-2 implementability gaps are closed.

**Finding I-4 — Acceptance test stubs: updated and comprehensive (line 558).**
Eight stubs now include `test_each_knob_only_stricter_than_§8` (per-clause), `test_regression_attributed_to_marginal_clause`, `test_thin_or_suppressed_calibration_falls_back_to_§8`, and the five from round 2. The attribution test is new and directly tests the load-bearing per-clause mechanism. Coverage is strong.

**Finding I-5 — `n_cal` default value: still missing.**
§19.7 (line 557) lists `n_cal` but provides no default or derivation. A developer must choose arbitrarily. This persists from round 2 (Co-4) and is a minor gap — not a blocker since a pilot calibration pass can establish this — but it remains the one genuinely underdetermined parameter.

**Score: 83** — Major round-2 gaps (observation window, borderline definition) are closed. Residual gaps: marginal-clause normalization (C-4/I-1), per-clause attribution count interaction with `n_cal` cold-start (I-2), `n_cal` default (I-5). These are implementable with reasonable engineering judgment and none is blocking.

---

### 5. Safety / integrity

**Finding S-1 — Per-knob floor safety property: confirmed for all three knobs.**
The core safety argument for round 3 is: can §19 make any single knob looser than its §8 default? Answer:
- `z ∈ [z_8, 2·z_8]`: the clamp prevents `z < z_8`. The statistical clause of `significant(Δĉ_secret, SE, margin=ε, z)` requires `Δĉ_secret > ε + z·SE`. With `z ≥ z_8`, the bar is at least as high as §8. Confirmed.
- `ρ_gen ≥ ρ_gen⁸`: the clamp prevents `ρ_gen < ρ_gen⁸`. The generalization clause `Δĉ_secret ≥ ρ_gen · Δĉ_public` is at least as strict as §8. Confirmed.
- `ε_cum ≤ ε_cum⁸`: the clamp prevents `ε_cum > ε_cum⁸`. The cumulative clause `ĉ_secret[s] ≥ ĉ_baseline[s] − ε_cum` is at least as strict as §8 (less allowed degradation). Confirmed. Note: the directional asymmetry is correct. "Looser" for the cumulative clause means a larger allowed degradation (higher `ε_cum`), and the clamp prevents that by imposing `ε_cum ≤ ε_cum⁸`.

The "never admit a change §8 would have blocked" property holds for all four clauses: the three tunable knobs are all clamped strictly at or beyond §8, and the safe clause is not tuned at all.

**Finding S-2 — The §8 conjunctive gate structure is preserved.**
§19.5 (line 543) explicitly states: "§19 tunes only the thresholds; the four gate clauses (statistical ∧ generalization ∧ cumulative ∧ safe, §8) and their conjunction are unchanged." The conjunction structure is load-bearing — loosening it from AND to OR would be a safety regression — and §19 does not touch it.

**Finding S-3 — Thin-data fallback: under-supply degrades to §8, not to a looser gate.**
§19.6 (line 551): "below `n_cal` per clause, §19 falls back to the fixed §8 default for that clause — under-supply degrades to §8, never to a looser gate." This directly closes the round-2 coordinated-fleet residual at the safety level: a fleet that starves the calibration signal causes the affected clause to stay at the §8 default. It cannot cause the clause to become looser than §8. The `test_thin_or_suppressed_calibration_falls_back_to_§8` stub covers this. Safety invariant holds under calibration suppression.

**Finding S-4 — Safe clause is explicitly non-tunable.**
§19.2 (line 532): "(the safe clause is hard — never tuned)." §19.6 does not list the safe clause as a tunable knob. The `test_each_knob_only_stricter_than_§8` stub covers "each" tunable knob; safe is excluded from tuning. The safety gate (`safety_eval_heldout(child) ≥ pass`) is untouched by §19.

**Finding S-5 — Shadow isolation invariant: unchanged and confirmed.**
§19.1 (line 529): "shadow runs never touch real competence, users, or the live posterior; outcomes are recorded only." `test_shadow_admits_never_touch_live_competence` is retained. The multi-knob extension does not introduce new shadow paths.

**Finding S-6 — Saturation breaker covers all three knobs.**
§19.6 (line 553): "if a knob sits at a clamp across the window, or `r̂` stays above `α_gate` even at max strictness, §19 freezes the knobs at the strict end and escalates to a human." "A knob" generalizes across all three tunable knobs. The breaker condition is sound for all three.

**Score: 87** — The safety core is strong. All three clamps enforce "never looser than §8." The safe clause is untouched. Thin-data fallback is safe. The JUDGE write-path protection applies to all three knobs. One mild residual: the saturation breaker triggers "if a knob sits at a clamp" — if `z` is at `2·z_8` but `ρ_gen` and `ε_cum` still have headroom, the breaker does not necessarily fire, meaning the system can be simultaneously saturated on one knob but not on others. The spec treats them as independent breaker triggers per knob, which is the correct behavior (escalate when the available remedy is exhausted on that clause), but the spec does not say "per knob" explicitly — it uses the indefinite singular "a knob." This is a minor language precision point, not a safety gap.

---

### 6. Efficiency / cost

**Finding E-1 — Three significance tests instead of one: O(1) per clause per calibration cycle.**
The per-clause architecture adds two additional significance tests (for `ρ_gen` and `ε_cum`) per calibration cycle per band, each O(1) given the attributed `r̂_clause` and its SE. Total cost is O(3·bands) per calibration cycle — a constant factor increase over round-2's O(bands), not a complexity-class change.

**Finding E-2 — Attribution step: O(1) per logged accept.**
For each regressed accept, computing the three clause margins and identifying the minimum requires O(1) operations per logged tuple. No additional storage or LLM calls are introduced.

**Finding E-3 — Cold-path operation: unchanged.**
§19 still runs on logged (decision, outcome, attributed-clause) tuples in the TruthStore. The per-clause logging adds one categorical field to each tuple (the attributed clause), which is a negligible storage increase. The calibration loop remains off the hot path.

**Score: 87** — Efficient. The three-knob extension is a constant-factor increase over round 2 with no hot-path impact.

---

### 7. Completeness

**Finding Co-1 — `w_obs` and `δ_border` defined and registered (round-2 Co-1, Co-2 resolved).**
Both are named in §19.1 (line 529) with operational definitions and listed in §19.7 (line 557). These close the two primary completeness gaps from round 2.

**Finding Co-2 — `n_cal` default: still missing.**
§19.7 (line 557) lists `n_cal` with no default value. This persists from round 2. The impact is limited: the §19.5 cold-start behavior is clear (off below `n_cal`), so the parameter's semantics are defined; only its default is absent.

**Finding Co-3 — Per-clause `n_cal` floor: appropriately scoped.**
§19.5 (line 543): "below `n_cal` logged tuples per clause." The per-clause scoping means a clause with sparse data degrades independently. This is correct behavior and is now explicit.

**Finding Co-4 — Marginal-clause normalization: not addressed.**
The "passed most marginally" criterion (§19.1, line 529) lacks a normalization specification for cross-clause comparison. See C-4 and I-1. This is a completeness gap at the parameter-definition level.

**Finding Co-5 — Test stubs: comprehensive (8 stubs, covering the new per-clause attribution).**
`test_regression_attributed_to_marginal_clause` and `test_each_knob_only_stricter_than_§8` are additions that directly test the round-3 architecture. Coverage is strong.

**Finding Co-6 — Interaction of `η_gate` across three knobs: single step size applies to all three.**
§19.7 (line 557) lists a single `η_gate` parameter. The three knobs are on different scales (`z` is a unitless multiplier, `ρ_gen` is a ratio, `ε_cum` is an absolute competence difference). A single step size `η_gate` applied across all three would need to be expressed in each knob's native units, or the spec needs to clarify that `η_gate` is a per-knob parameter (or a fractional/proportional step). This is a minor completeness gap — a developer would likely implement per-knob step sizes — but the spec as written implies a single `η_gate`.

**Score: 83** — Substantially more complete than round 2. Major gaps (observation window, borderline definition) are closed. Remaining gaps: `n_cal` default, marginal-clause normalization, `η_gate` multi-knob scoping. None is structural.

---

### 8. Consistency

**Finding Cs-1 — The "uniformly controls all four clauses" inconsistency is eliminated (round-2 Cs-1 resolved).**
§19.2 and §19.5 no longer claim `z` controls all four clauses. §19.2 now correctly assigns `z` to the statistical clause, `ρ_gen` to generalization, `ε_cum` to cumulative, and leaves safe untouched. §19.5 states "the four gate clauses and their conjunction are unchanged" — correct. The principal cross-spec inconsistency from round 2 is gone.

**Finding Cs-2 — Preamble knob list (line 524) matches §19.2, §19.3, §19.7.**
The preamble names three tunable knobs (`z`, `ρ_gen`, `ε_cum`). §19.2 names the same three. §19.3 clamps the same three. §19.7 registers the same three plus all other parameters. No naming divergence within the section.

**Finding Cs-3 — §19.6 "tightening the wrong clause" risk now correctly addressed.**
Round-2 Cs-3 noted the §14 cross-reference for oscillation was imprecise. The round-3 text retains §19.6's reference (line 554): "the §14 breaker halts oscillation." §14 is the ECE calibration breaker. Using §14 to bound §19 oscillation is an indirect coupling — if calibration quality degrades (ECE spike), §14 halts all calibration including §19. This cross-reference is now a secondary backstop, with §19's own saturation breaker as the primary. The coupling is stated but the mechanism by which §14 halts §19's feedback loop specifically (rather than §14's own calibration cycle) is not explained. This is a minor consistency gap — the claim is plausible (if §14 halts, §19 should also pause as it depends on §14's calibrated SEs), but the dependency chain is implicit.

**Finding Cs-4 — §19.7 `η_gate` single parameter vs. three-knob architecture: potential internal inconsistency.**
§19.7 registers a single `η_gate` against a system that tunes three distinct knobs on different scales. See Co-6. This is a consistency gap between the parameter table (one step size) and the implied multi-knob implementation.

**Score: 87** — Major inconsistency (Cs-1) eliminated. Remaining minor gaps: `η_gate` single-parameter vs. multi-knob architecture (Cs-4), and the §14 breaker cross-reference for oscillation (Cs-3). Neither creates contradictory requirements.

---

### 9. Calibration / honesty

**Finding Ca-1 — The attribution mechanism is now honest about its scope.**
Round-2's adversarial objection was that `r̂` aggregates all four failure modes while `z` addresses only one — a fundamental mismatch. The round-3 spec resolves this by decomposing `r̂` into per-clause rates `r̂_clause` and routing each to its own knob. The spec now correctly represents what it can and cannot do: it can calibrate each clause's threshold based on that clause's regression contribution. The Ca-2 overstating concern from round 2 is gone.

**Finding Ca-2 — "Can never admit a change §8 would have blocked" is extended to all three knobs.**
§19.3 (line 535) states this property and the per-knob clamp structure enforces it. The claim is now accurate across all three tunable dimensions and the safe clause.

**Finding Ca-3 — Fleet adversarial limitation: now explicitly bounded and characterized.**
§19.6 (line 550–551) addresses both the volume-based attack (per-source caps) and the thin-data suppression scenario (fallback to §8). The residual (coordinated fleet degrades calibration but not safety) is bounded and is honestly treated as a limitation rather than a solved problem.

**Finding Ca-4 — Attribution gaming residual: not acknowledged.**
The R-5 finding (strategic submitters can bias attribution toward the statistical clause by controlling their submission's margin profile) is not acknowledged in the spec. A fully honest calibration/honesty section would note that per-clause attribution can be influenced by the submitter's behavior if submitters have enough control over their margin profile. This is a minor honesty gap.

**Finding Ca-5 — `η_gate` single step size claim: potentially overconfident.**
The spec implies a single `η_gate` governs three different-scaled knobs. A single step size that works for `z` (a unitless multiplier ranging from `z_8` to `2·z_8`) may not be appropriate for `ε_cum` (an absolute competence difference) or `ρ_gen` (a ratio). The spec does not acknowledge this scale mismatch, which is mildly overconfident about how easily `η_gate` can be set.

**Score: 84** — Substantially more honest than round 2. The attribution mechanism is correctly represented. Minor remaining honesty gaps: attribution gaming residual (Ca-4) and `η_gate` scale mismatch (Ca-5). Neither is blocking.

---

## Strongest adversarial objection

**Per-clause attribution is contingent on a normalization that the spec does not define — and the choice of normalization changes what the gate learns from.**

The round-3 architecture resolves the round-2 adversarial objection by routing regressions to the clause they slipped through most marginally. But "most marginally" requires comparing margins across three clauses that are measured in incompatible units: the statistical margin is in units of `z·SE` (a product of a dimensionless multiplier and a competence standard error); the generalization margin is a ratio difference relative to `ρ_gen`; the cumulative margin is an absolute competence gap relative to `ε_cum`. Without a stated normalization, the attribution rule is implementation-defined.

This matters beyond a specification precision complaint. Depending on the normalization:
- A change that barely passes the statistical clause at `z=2·SE_above` while comfortably passing generalization and cumulative will be correctly attributed to statistical.
- A change that passes all three clauses at roughly equal absolute margins will be attributed differently depending on whether margins are normalized by the threshold value (fractional excess) or expressed in absolute units.
- In domains where `ε_cum` is a small absolute number (e.g., 0.02), even a small absolute cumulative margin will look larger than a large statistical margin in absolute terms — so the statistical knob gets tightened even when cumulative was the thin clause.

The practical consequence: the attribution layer could systematically misdirect tightening in domains where the threshold scales are poorly matched, causing some knobs to tighten excessively while others never tighten — all while `r̂` stays above `α_gate` because the dominating clause is not receiving the adjustment. This is subtler than the round-2 objection (wrong clause entirely) but operates on the same structural principle.

A natural fix (not in the spec) is to normalize each clause's margin as `(observed_value − threshold) / threshold`, yielding a dimensionless "fractional excess above the bar" for each clause. Attribution then goes to the lowest fractional excess. This would need to be stated explicitly in §19.1 or §19.2.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety)
                = min(88, 85, 87)
                = 85

weighted_mean   = (Correctness×2 + DesignFaithfulness + RedTeam×2
                   + Implementability + Safety×2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
                = (88×2 + 88 + 85×2 + 83 + 87×2 + 87 + 83 + 87 + 84) / 11
                = (176 + 88 + 170 + 83 + 174 + 87 + 83 + 87 + 84) / 11
                = 1032 / 11
                = 93.82

overall         = min(85, 93.82) = 85
```

**Overall confidence: 85 / 100**

---

## Verdict

**ready-for-approval**

The score of 85 clears the 80 threshold. All three critical dimensions (Correctness 88, Red-team 85, Safety 87) are above 70. The round-2 minimum-critical bottleneck (Red-team 77 → critical floor 77) is resolved by the per-clause attribution architecture, which directly addresses the round-2 adversarial objection. All three round-2 blockers are substantively resolved.

Remaining weak points that do not block approval but should be noted to the implementation team:

- The "most marginally" attribution criterion needs a normalization specification at implementation time (suggest fractional excess `(value − threshold)/threshold` per clause).
- A single `η_gate` step size applied across three differently-scaled knobs will require per-knob tuning; the spec implies a single parameter where three may be needed in practice.
- `n_cal` has no default value; a pilot calibration pass should establish this before production deployment.
- A coordinated fleet can prevent calibration benefit (per-clause `r̂` artificially suppressed near `α_clause`) while the safety floor holds — acknowledge as a known limitation in operational documentation.
