# Decision: APPROVED — S19-self-calibrating-gate

**Date:** 2026-06-29
**Approver:** change-approver
**Review source:** docs/research/reviews/S19-self-calibrating-gate-review-r3.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 85 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 88 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 85 | >= 70 | PASS |
| G2: Safety floor | Safety score | 87 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | No contradiction | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1 clears with overall confidence 85 (threshold > 80). G2 clears on all three critical dimensions: Correctness 88, Red-team resistance 85, and Safety 87, each well above the 70 floor. G3 clears: the three round-2 blockers (B1 — correct clause-coverage claim, B2 — define `w_obs`, B3 — define `δ_border` operationally) are all marked "Resolved" by the review and verified substantively, not by rewording. The check-on-the-checker finds no contradiction: the caller's primary safety concern — that §19 can never make the effective gate looser than §8 — is directly and thoroughly addressed by findings S-1 through S-6. S-1 individually verifies each knob's clamp direction (`z ∈ [z_8, 2·z_8]`, `ρ_gen ≥ ρ_gen⁸`, `ε_cum ≤ ε_cum⁸`), S-2 confirms the four-clause conjunctive structure is untouched, S-3 confirms thin-data fallback degrades to §8 not past it, and S-4 confirms the safe clause is never tuned. No finding in the body is tagged critical, blocking, or must-fix; the strongest adversarial surface identified (R-5: strategic submitters can bias attribution toward `z`, holding `ρ_gen` and `ε_cum` at §8 defaults) is correctly bounded by the floor clamps and does not constitute a safety breach. The normalization gap (C-4/I-1/Co-4) is classified as an implementation-time decision, not a structural flaw, and acknowledged as a non-blocking advisory.

## Next step

**Authorized for commit.** This decision record authorizes the §19 "self-calibrating gate" change described in `S19-self-calibrating-gate-review-r3.md` to be committed to `docs/research/ALGORITHM-v0.2-pathway-learner.md`. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.

**Advisory items for the implementation team (non-blocking):**

1. **Marginal-clause normalization (C-4 / I-1 / Co-4):** The "passed most marginally" attribution criterion does not specify how margins across the three clauses are placed on a common scale. The review suggests fractional excess `(observed_value − threshold) / threshold` per clause as a natural normalization. The companion BUILD-SPECS item should define this explicitly before the attribution mechanism is coded; otherwise attribution behavior in multi-clause near-misses is implementation-defined and may vary across developers.

2. **`η_gate` scale mismatch (Co-6 / Cs-4 / Ca-5):** §19.7 registers a single step-size `η_gate` for three knobs measured on different scales (`z` is a unitless multiplier, `ρ_gen` is a ratio, `ε_cum` is an absolute competence gap). In practice three per-knob step sizes will likely be needed; the companion BUILD-SPECS item or parameter table should clarify whether `η_gate` is a proportional (fractional) step or requires per-knob instantiation.

3. **`n_cal` default value (I-5 / Co-2):** §19.7 lists `n_cal` without a default. A pilot calibration pass should establish this value before production deployment; the BUILD-SPECS item should record the chosen default and its derivation.

4. **Per-clause attribution count and cold-start interaction (I-2):** When `n_accepts_clause` for a specific clause falls below `n_cal` (because failures from other clauses dominate attribution), the §19.5 fallback behavior for that clause should be stated explicitly in the implementation rather than read implicitly from §19.5's general statement.

5. **Attribution gaming residual (Ca-4 / R-5):** Strategic submitters that can control their margin profile may bias attributions systematically toward `z`, keeping `ρ_gen` and `ε_cum` at §8 defaults. This is bounded (cannot go below §8) but defeats per-clause calibration benefit for those knobs. Operational documentation should acknowledge this as a known limitation.
