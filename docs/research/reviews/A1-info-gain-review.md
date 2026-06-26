# 360 Review: BUILD-SPECS A1 (info-gain selection) — Round 2 — 2026-06-26

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` § "A1 · Information-gain selection — the Tutor's core objective" (lines 9–62) |
| Proposed change | Make §13.1's `argmax E[ΔH]` computable: closed-form one-step Beta EIG, advance↔diagnose blend `U(a)` with a fully-specified `w` schedule, sub-additive multi-cell aggregation, corrected peak/zero claim, and updated red-team-style tests; plug into `mdlp/decision.py::DecisionEngine.choose` and `mdlp/state.py`. |
| Round | **2** (supersedes the round-1 report below; round-1 scored 78/100, needs-revision, 6 blockers) |
| Reviewer | review-360 |
| Date | 2026-06-26 |

---

## Round-1 → Round-2 blocker resolution (explicit per-blocker verdict)

Six blockers were listed in round-1. Each is verified here before the fresh scores.

**Blocker 1 — Digamma: recurrence-then-asymptotic for small α,β.**
Round-1 finding: the spec said "a 6-term digamma asymptotic series" which is catastrophically wrong at small argument (err ~80 at α=0.5); EIG error was order-of-EIG.
Revised spec (line 31): "ψ via the **recurrence** `ψ(x)=ψ(x+1)−1/x` to shift the argument to `x≥6`, then the standard asymptotic series — accurate to ~1e-12." The recipe is now correct. Verified by running the recurrence-to-6 recipe against NIST reference values: errors are 1.25e-9 at x=0.5, 2.36e-9 at x=1.0. These propagate to EIG errors of ~1e-9, which are 7–8 orders of magnitude below typical EIG values (~1e-2 to 1e-1). The recipe is fully implementable and numerically safe.
Minor residual: the spec claims "~1e-12" accuracy, but recurrence-to-6 with a 6-term series achieves ~1.25e-9 (not 1e-12); reaching 1e-12 requires shifting to x≥8 or adding a 7th term. This is a small overclaim on precision (EIG itself is unaffected at any relevant scale) and is noted but not blocking.
**Status: RESOLVED.**

**Blocker 2 — "peaks at ĉ≈0.5/→0 at mastery" over-claim corrected.**
Round-1 finding: the spec incorrectly attributed EIG→0 to ĉ→1 rather than to n_eff growth; the peak-at-0.5 claim was near-flat and mis-stated; test_eig_zero_at_mastery was mis-specified.
Revised spec (lines 29, 33): the comment on the EIG formula now reads "FALLS as n_eff grows (NOT a peak at ĉ=0.5)"; the explanatory box (line 33) states explicitly "EIG_cell measures *uncertainty* about a cell and **falls as effective sample size `n_eff` grows**...it is *not* a function of `ĉ` peaking at 0.5 — at fixed `n_eff` it is near-flat across mid-mastery." Verified numerically: EIG at n_eff=10 varies from 0.0422 (ĉ=0.1) to 0.0475 (ĉ=0.5) — a 13% spread, correctly described as "near-flat." EIG falls monotonically with n_eff at fixed ĉ=0.5 (confirmed: 0.193 → 0.110 → 0.059 → 0.030 → ... as n_eff doubles). The old test_eig_zero_at_mastery is replaced by test_eig_falls_with_n_eff (line 51), which is correctly specified.
**Status: RESOLVED.**

**Blocker 3 — `w`/`u_ref`/`mean_frontier_uncertainty` estimator defined with defaults.**
Round-1 finding: u_ref had no default; mean_frontier_uncertainty had no estimator definition; the w schedule was not implementable.
Revised spec (lines 36–41): the w-schedule section now gives explicit formulas — `Var[Beta] = αβ/((α+β)²(α+β+1))`; `mean_frontier_uncertainty = mean over the reachable candidate cells of sqrt(Var[Beta])`; `w = clip(mean_frontier_uncertainty / u_ref, 0, 1)`; `u_ref default 0.15`. The semantic anchor is given: "≈ the SD of a lightly-populated cell" — verified numerically: Beta(5,5) (n_eff=10, ĉ=0.5) has SD=0.1508≈0.15, confirming the calibration claim. The spec also states the reachable candidate set is "the cells `choose` already scores — no extra cost." The dependency on §14 calibration for SE honesty is explicitly named (line 41).
**Status: RESOLVED.**

**Blocker 4 — Section citations fixed to §5.2/§5.3.**
Round-1 finding: spec cited "§3.6 normalization" and "§3.3 reachability" — both are non-existent subsections in v0.2 (§3 has no sub-headers).
Revised spec (line 19): now reads "the §5.3 frontier-policy normalization." Line 31: now reads "soft reachability §5.2." Both are confirmed present in v0.2 (`ALGORITHM-v0.2-pathway-learner.md` lines 158–172 for §5.3, lines 143–155 for §5.2). The "§3.6 DecisionEngine" label is still used in the plug-point context (line 44 of v0.2 §13), but A1 no longer cites it as an algorithm section — the citation is now to the correct §5.2/§5.3 mechanisms.
**Status: RESOLVED.**

**Blocker 5 — Multi-cell aggregation made sub-additive.**
Round-1 finding: the spec summed per-cell EIGs across prereq-linked cells, over-counting joint information because §3 explicitly ties cells via the prereq graph and hierarchical prior; the plain sum biases toward shallow multi-cell sweeps.
Revised spec (line 31): now reads "Cells linked by the prereq graph (§5.2) are statistically **dependent**, so a raw `Σ EIG_cell` over multiple cells **over-counts** the joint information — use a sub-additive aggregate (the max, or a correlation-discounted sum), never the plain sum." The plain-sum error is explicitly forbidden. Two options are offered: the max (trivially defined, conservative) and a "correlation-discounted sum." The max is implementable as-is. The correlation-discounted sum option is mentioned but not formally specified (no formula for the discount factor). This leaves a residual: a developer choosing the correlation-discounted path must guess the formula. However, the safe fallback (max) is explicit and sufficient to implement without guessing, and the over-counting error from round-1 is clearly named and forbidden. This is a weak remaining gap, not a blocker.
**Status: SUBSTANTIALLY RESOLVED** (max option is concrete; correlation-discounted formula is open).

**Blocker 6 — Tests updated.**
Round-1 finding: test_eig_zero_at_mastery was mis-specified; no test for the uncertainty-chaser dynamic.
Revised spec test list (lines 50–55): test_eig_zero_at_mastery is gone; replaced by `test_eig_falls_with_n_eff` — "EIG_cell decreases monotonically as n_eff grows at fixed ĉ (NOT a peak at ĉ=0.5; near-flat across mid-mastery at fixed n_eff)." New test `test_blend_beats_pure_eig_on_frontier` — "a very thin off-frontier cell (high EIG, low reach × advance) loses to a near-frontier cell under the blended U(a) — the blend, not EIG, picks the frontier." This directly tests the round-1 adversarial objection (uncertainty-chaser). Both new test descriptions are correctly specified and verifiable.
**Status: RESOLVED.**

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 92 | pass |
| 3 | Red-team resistance (CRITICAL) | 85 | pass |
| 4 | Implementability | 88 | pass |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 92 | pass |
| 7 | Completeness | 79 | weak |
| 8 | Consistency | 85 | pass |
| 9 | Calibration / honesty | 85 | pass |

All numerical checks were run with `python3` against NIST reference values and grid integration; results reproduced inline.

---

## Findings by dimension

### 1. Correctness — 85 (CRITICAL, pass)

**Core math verified correct (unchanged from round-1).** The closed-form Beta differential entropy at line 26–27 matches grid integration to ~1e-10 across all tested Beta parameters. The one-step EIG formula at lines 28–29 matches numeric EIG to ~1e-11. These are confirmed again this round; no regression.

**Digamma recipe: now correct and implementable.** The recurrence-then-asymptotic recipe described at line 31 was verified against NIST reference values:
```
psi(0.5): ref=-1.963510026021  spec-recipe=-1.963510027276  err=1.25e-9
psi(1.0): ref=-0.577215664902  spec-recipe=-0.577215667266  err=2.36e-9
psi(2.0): ref=0.422784335098   spec-recipe=0.422784332734  err=2.36e-9
psi(5.0): ref=1.506117668432   spec-recipe=1.506117666068  err=2.36e-9
```
EIG errors from this digamma imprecision are ~1e-9 — 7 to 8 orders below EIG values (0.01–0.3), so the recipe is numerically safe for all practical inputs. Round-1's blocking flaw is resolved.

**Minor residual — accuracy overclaim.** The spec claims "accurate to ~1e-12." The actual accuracy of recurrence-to-6 with a 6-term series is ~1.25e-9 at x=0.5. To reach 1e-12 requires shifting to x≥8 (gives ~3.7e-12 at x=0.5) or adding a 7th asymptotic term. The overclaim is ~3 orders of magnitude. It does not affect correctness for this application (EIG is unaffected), but a developer following the spec who writes a unit test pinning to 1e-12 tolerance will get a spurious failure. This is a documentation imprecision, not a math error. Score penalized by ~4 points.

**EIG peak/zero claim: corrected.** The "near-flat across mid-mastery at fixed n_eff" description is now precise and verified. The "falls with n_eff" test is correctly specified. At n_eff=10: EIG ranges from 0.0422 (ĉ=0.1) to 0.0475 (ĉ=0.5) — 13% spread, accurately described as near-flat. At fixed ĉ=0.5: EIG halves with each n_eff doubling — monotone decay confirmed.

**α<1 edge case: still unguarded (minor).** If cold-start prior has α0<1 or β0<1, the `(α−1)ψ(α)` term is non-zero and the integrable singularity at x=0 in the Beta density means entropy is still well-defined; however the spec does not explicitly state this and does not constrain α0,β0≥1. The algorithm's §3 references `Beta(α0,β0)` cold start (v0.2 line 68) without pinning α0≥1. Numeric check confirms EIG_cell works at Beta(0.5,0.5) with the recurrence recipe (EIG=0.3069, mathematically correct), so this is not a fatal flaw — but no test covers it and the spec doesn't acknowledge it.

### 2. Design faithfulness — 92 (pass)

Citations are now correct. Line 19 cites "the §5.3 frontier-policy normalization" — §5.3 (`v0.2` lines 158–173) is where `zscore(... | cands)` is defined. Line 31 cites "soft reachability §5.2" — §5.2 (`v0.2` lines 143–155) defines `reach_weight(s,n) = ∏ P(mastery[p]≥θ)`. Both are confirmed present.

A1 continues to faithfully extend §13.1 (`v0.2` lines 320–327), which defines `A* = argmax E[ΔH]` but leaves it non-computable. The advance↔diagnose blend with the `significant(LP, SE)` fallback faithfully mirrors §5.3's `if not significant(LP_component(a), SE): Uz ← Uz_explore_only(a)` (`v0.2` line 166). The `z(·)` candidate-set z-score is consistent with §5.3's normalized terms.

Residual (not penalized heavily): the spec's note section (line 57) calls the `w` schedule "the one genuine judgment call" and defers its tuning to the pilot — faithful to the v0.2 spirit of explicit open parameters. One notation note: the Parameters line (line 47) lists "advance-term significance `z` (existing)" — this `z` is the §2 significance multiplier, while the formula uses `z(·)` for the candidate-set z-score (line 18). The collision is mild but survives from round-1; no further deduction.

### 3. Red-team resistance — 85 (CRITICAL, pass)

**RC-1 (point estimates) — unchanged, strong.** The advance term enters only when `significant(LP, SE)` (line 21), with a dedicated regression test (line 55). `test_insignificant_lp_falls_back_to_eig` guards this.

**RC-7 (uncertainty-chaser) — directly addressed.** Round-1's strongest adversarial objection was that EIG alone chases the thinnest cell, not the frontier. The revised spec (line 33 explanatory box) now states this explicitly: "So **EIG alone goes where you know least**, which at unequal `n_eff` is the *thinnest* cell, not necessarily the learnable frontier." And `test_blend_beats_pure_eig_on_frontier` (line 52) directly tests that the blended U(a) — not EIG — picks the frontier over a thin off-frontier cell. The uncertainty-chaser objection is now acknowledged, documented, and guarded.

**Residual surface (why not ≥90):**

1. The `w` schedule introduces `mean_frontier_uncertainty / u_ref` as a ratio of two uncertain quantities. RC-1's lesson is that ratios of small-sample estimates can drive noise-walks. The spec says §14 calibration "keeps the SD honest, so `w` can't be driven by over-confident variance" (line 41). This is the correct hook, but `w` itself is not gated by `significant(...)` the way every other decision quantity is. If §14 ECE_band is high and the calibration breaker has not fired yet, `w` can still be driven by miscalibrated uncertainty. The calibration breaker (§14.3) is the defense, but A1 does not state what happens to `w` in the interval between miscalibration onset and breaker trip. This is residual surface from RC-7 routed through `w`, not a reopened killer.

2. RC-2/RC-3/RC-4/RC-5/RC-6/RC-8 are not touched by A1. The held-out machinery, commit gates, coverage floor, reachability, and soft prereqs are explicitly stated unchanged (line 44). No failure mode is reopened.

### 4. Implementability — 88 (pass)

All four round-1 implementability blockers are resolved:

- **Digamma recipe**: fully stated as recurrence-then-asymptotic with the shift threshold (x≥6) and the standard asymptotic formula. A developer can implement directly.
- **u_ref default**: explicitly 0.15, with semantic anchor ("≈ the SD of a lightly-populated cell"; verified: Beta(5,5) SD=0.1508).
- **mean_frontier_uncertainty estimator**: "mean over the reachable candidate cells of sqrt(Var[Beta])" — the cell set is "cells `choose` already scores — no extra cost." The formula uses §3's `u[s,d] = Beta_sd(mastery)` (`v0.2` line 64), which is consistent.
- **reach_weight citation**: now explicitly names §5.2's `reach_weight(s,n)` (line 31).

Remaining gap (score deduction): the correlation-discounted sum option for multi-cell aggregation is not given a formula. A developer choosing that path must supply the discount factor independently. However, the max alternative is fully defined, so a developer can build without guessing (they may choose max and note that a more refined aggregation is a future improvement). The plug-point (`mdlp/decision.py::DecisionEngine.choose`, `mdlp/state.py`) remains clear with a concrete before/after description (line 44).

### 5. Safety / integrity — 85 (CRITICAL, pass)

A1 weakens no gate. The coverage floor, hard cost constraint, `significant()` on LP, and the held-out verifier are explicitly stated unchanged (line 44). The §14 calibration breaker (§14.3: `ECE_band > τ_cal` trips circuit breaker) is named as the guard that keeps `w` from being driven by miscalibrated uncertainty.

**Remaining residual from round-1 (smaller now).** The spec now explicitly names the §14 dependency (line 41: "§14 calibration keeps the SD honest, so `w` can't be driven by over-confident variance"). But it still does not state a degraded-mode behavior for the `w` schedule when calibration is stale — e.g., "fall back to a fixed `w=0.5` or pure advance-only until the breaker resets." The calibration breaker eventually halts the system, but during the interval between miscalibration and breaker trip, `w` can over-diagnose or over-advance based on miscalibrated uncertainty. This is a bounded window of risk (breaker caps it), not a permanent hole, so it does not pull below 80.

No new safety surface relative to §1–§14 is introduced by A1's addition of the w-schedule and EIG term. The EIG computation is pure arithmetic on the existing posterior — it does not create a new optimization channel that could be gamed.

### 6. Efficiency / cost — 92 (pass)

Unchanged from round-1. EIG_cell is O(1) per cell (a small fixed number of lgamma/digamma evaluations, stdlib-only). The digamma recurrence loop (while x < 6) adds at most ~6 iterations per call — still O(1). Multi-cell aggregation is O(#affected cells), linear in reach. No new LLM calls. The mean_frontier_uncertainty estimator runs over the same candidate set that `choose` already iterates — no extra cost (explicitly stated in line 40). Efficiency is the strongest dimension.

### 7. Completeness — 79 (weak)

Round-1 gaps addressed:
- test_eig_zero_at_mastery (mis-specified) replaced by test_eig_falls_with_n_eff (correctly specified). Resolved.
- test_blend_beats_pure_eig_on_frontier added (uncertainty-chaser guard). Resolved.
- u_ref bounded (natural range stated in §3/§14 derivation) and defaulted. Resolved.

Remaining gaps:

**test_digamma_accuracy missing.** The digamma recipe is now correct, but the spec does not include a test pinning ψ accuracy at small arguments (α,β ∈ {0.5, 1, 2, 5}) against a reference. Round-1 blocker 1 asked for this test; the revised spec fixed the algorithm but did not add the test. Given that the recipe is now correct, this is a completeness gap rather than a correctness blocker — but it remains open.

**Multi-cell aggregation test missing.** The spec forbids the plain sum (line 31) and offers max or correlation-discounted sum, but no test verifies that the implemented aggregation is sub-additive or that it matches §5.2's `reach_weight`. `test_eig_multicell_aggregation` is not in the test list.

**w-schedule stability test missing.** `w = clip(mean_frontier_uncertainty / u_ref, 0, 1)` has no test for monotonicity (w rises as uncertainty rises), clipping behavior at the (0, max_SD] range, or stability when the frontier set changes between steps.

**α<1 unguarded, no test.** No test covers behavior with Jeffreys-style α0=0.5 cold start. The math works, but the boundary is untested.

**No end-to-end integration test.** No test demonstrates the full `choose` pipeline under the new U(a) (coverage floor + hard cost + `significant()` + EIG + z-score normalization together) against a multi-skill scenario.

These gaps collectively prevent the score from reaching 85, but none is a hard blocker — they are completeness weaknesses in a spec that otherwise specifies the key behaviors correctly.

### 8. Consistency — 85 (pass)

Citations are now internally consistent with v0.2 (§5.2 for reachability, §5.3 for z-score normalization). The `z(·)` z-score notation overload (z for candidate-set normalization at line 18 vs. z for significance multiplier at line 47) survives from round-1 but is mild. No contradiction with DATA-LAYER or HUMAN-LEARNING-VERIFIER was found (A1 does not touch either). A1's note section (lines 57–58) accurately summarizes what changed vs. round-1, including correctly characterizing blocker resolutions. Consistent with the ALGORITHM-INTEGRATIONS.md register (A1 is the A-row "Info-gain selection" item).

### 9. Calibration / honesty — 85 (pass)

The peak/zero overclaim is corrected and replaced with precise language (near-flat at fixed n_eff, falls with n_eff). The spec is explicit that "the remaining genuine judgment call is `u_ref` — tune on the pilot" (line 58). The calibration dependency is explicitly named (line 41). The spec now includes a precise explanatory box (lines 33) that carefully distinguishes what EIG does from what the blend does, and where the frontier-selection property comes from — a genuine improvement in honesty.

Residual: the "accurate to ~1e-12" claim for the digamma recipe (line 31) is a ~3 order overclaim (actual is ~1.25e-9 with the stated recipe). Harmless for practice but a mild imprecision. The spec also says the blend delivers "bias-free + informative + fast" from a single objective (line 33); this is fair given the test_blend_beats_pure_eig_on_frontier guard, but is still conditional on the w schedule being properly calibrated — acknowledged in line 41 but worth flagging as not unconditional.

---

## Strongest adversarial objection

Round-1's strongest adversarial objection (EIG as an uncertainty-chaser + multi-cell over-counting) has been partially addressed: the spec now explicitly describes the chaser dynamic, names the blend — not EIG — as the frontier-selector, and adds test_blend_beats_pure_eig_on_frontier. The over-counting problem is named and the plain sum is forbidden.

**New strongest objection: the `w` schedule degrades gracefully under calibration failure, but its failure mode is not symmetric — it always biases toward diagnose (high w), never silently toward advance.**

When §14 calibration is off and uncertainty is systematically over-estimated (a common early-run failure mode, where the posterior is not yet sharpened), `mean_frontier_uncertainty` will be inflated, pushing `w` toward 1. The Tutor then over-diagnoses: it selects high-EIG cells when it should be advancing the learner. This is recoverable (calibration is a cold-path correction) but the recovery path is not stated.

Conversely, if uncertainty is under-estimated (over-confident posterior, the §14 miscalibration direction that is more dangerous), `w` is suppressed and the Tutor over-advances: it acts on the advance term even when the LP estimate may not yet be reliable. The `significant(LP, SE)` gate exists, but if the SE is under-estimated (over-confident posterior, exactly the dangerous miscalibration direction), the significance test gates too permissively and noisy LP drives selection — a soft re-entry of RC-1 routed through mis-calibrated SE. The spec mentions §14's guard but does not bound the damage in the window between miscalibration onset and breaker trip.

This objection does not break the algorithm (the calibration breaker eventually halts the system), and it is narrower than the round-1 adversarial objection. It is noted as a surface that a future robustness pass should address (w degraded-mode fallback), but it does not by itself prevent approval.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(85, 85, 85) = 85
weighted_mean   = (85*2 + 92 + 85*2 + 88 + 85*2 + 92 + 79 + 85 + 85) / 11
                = (170 + 92 + 170 + 88 + 170 + 92 + 79 + 85 + 85) / 11
                = 1031 / 11
                = 93.7
overall         = min(85, 93.7) = 85
```

**Overall confidence: 85 / 100**

---

## Verdict

**ready-for-approval**

All six round-1 blockers are resolved. The three CRITICAL dimensions each clear 70 (all score 85), and the overall score clears 80. No new blocking issue was found in round-2. The spec is implementable, math-correct, design-faithful, and safe.

**Non-blocking items for the implementer to address during build (not re-review required):**

1. Add `test_digamma_accuracy`: pin ψ accuracy at α ∈ {0.5, 1, 2, 5} against NIST references. Tighten the spec's "~1e-12" accuracy claim to "~1e-9" (recurrence-to-6 + 6-term) or shift the recurrence threshold to x≥8 to actually achieve ~1e-12 if that precision is desired. *(Correctness minor, Completeness)*

2. Add `test_eig_multicell_aggregation`: verify the chosen aggregation (max or correlation-discounted) is sub-additive for a pair of prereq-linked cells. *(Completeness)*

3. Add `test_w_schedule_monotone`: verify w rises with uncertainty and clips correctly at 0 and 1. *(Completeness)*

4. Document degraded-mode behavior for `w` when §14 calibration is stale (e.g., "fall back to w=0.5 or pure advance-only until the calibration breaker resets"). *(Safety residual)*

5. If the "correlation-discounted sum" aggregation path is chosen over max, specify the discount formula before implementation. *(Implementability residual — max is always available as a safe default)*

---

## Round-1 report (archived below for reference)

*(The original round-1 report text is preserved here for lineage. Round-2 scores supersede round-1 scores.)*

**Round-1 overall: 78/100, needs-revision. Round-2 overall: 85/100, ready-for-approval.**

Round-1 dimension scores:

| # | Dimension | Round-1 Score | Round-2 Score |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 78 | 85 |
| 2 | Design faithfulness | 88 | 92 |
| 3 | Red-team resistance (CRITICAL) | 82 | 85 |
| 4 | Implementability | 74 | 88 |
| 5 | Safety / integrity (CRITICAL) | 85 | 85 |
| 6 | Efficiency / cost | 92 | 92 |
| 7 | Completeness | 72 | 79 |
| 8 | Consistency | 80 | 85 |
| 9 | Calibration / honesty | 80 | 85 |
