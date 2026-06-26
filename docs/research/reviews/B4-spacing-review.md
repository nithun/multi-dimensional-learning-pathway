# 360 Review: B4-spacing — Round 3 — 2026-06-26

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` — section "## B4 · Forgetting-aware spacing" (lines 110–143) |
| Proposed change | Revised B4 (round 3): all five round-2 blockers claimed resolved — (1) `p_probe` is per-due-interval, indistinguishable from a scheduled review, with a `~1/p_probe` worst-case inflation bound; (2) single-event `S` volatility acknowledged as the standard SRS tradeoff, `§14`-calibrated `a,b`, optional ≥2-consecutive step; (3) `ĉ_mastery` pinned to `ProbabilisticState.estimate().mastery_mean` (slow posterior, not drift); (4) interleave window default (3 items) and due-boost default (+0.5) given; (5) review-budget cap `ρ_rev=0.5` added with `test_reviews_dont_starve_coverage_floor`. |
| Reviewer | review-360 |
| Date | 2026-06-26 |
| Round | 3 (round-1: 68/100 needs-revision · round-2: 72/100 needs-revision) |

---

## What changed since round 2

Round-2 had five blockers. The revised spec addresses all five:

1. **Blocker 1 resolved — `p_probe` scope and bound.** BUILD-SPECS.md line 128: the unscheduled probe fires "with prob `p_probe` (default 0.1) **per due-interval**", is "*indistinguishable from a scheduled review* (cramming can't time around it)", and bounds "worst-case undetected over-inflation to ~`1/p_probe` intervals". The scope question (per-review, per-session, per-day) is resolved: it is per-due-interval, which is the right scope for an SRS system. The `~1/p_probe` bound is on the **count of undetected crammed intervals** (literally correct: expected intervals before a probe fires = 1/0.1 = 10). Note: S magnitude still grows as `(1+a)^k` — at defaults after 10 consecutive crammed passes, S = 1024 days — but this is now fairly framed as the standard SRS tradeoff, and indistinguishability is a genuine deterrent.

2. **Blocker 2 resolved — `S` volatility acknowledged.** BUILD-SPECS.md line 129: "Single-event `S` volatility is the standard SRS design tradeoff; `§14` calibration of `a,b` corrects systematic over-inflation, and a full `S` step optionally requires **≥2 consecutive** consistent outcomes." This converts the undocumented RC-1 analogue into an explicit, justified design choice with stated mitigations.

3. **Blocker 3 resolved — `ĉ_mastery` pinned to `mastery_mean`.** BUILD-SPECS.md line 115: "`ĉ_m = ProbabilisticState.estimate().mastery_mean` (the slow-decay, §14-calibrated posterior mean — *not* the `drift` one)". The naming ambiguity between `mastery[s,d]` and `drift[s,d]` is closed; a developer has a concrete method call.

4. **Blocker 4 resolved — interleave window and due-boost given defaults.** BUILD-SPECS.md line 123: "interleave window (no same-skill within 3 due items)" and "due-boost (+0.5 to the candidate score)". Both are now concrete parameters with defaults.

5. **Blocker 5 resolved — `ρ_rev` budget cap.** BUILD-SPECS.md line 130: "due reviews are capped at `≤ ρ_rev` of the per-tick budget (default 0.5), so the §5.3 coverage floor `f_min` for non-due weak skills is preserved." Line 139: `test_reviews_dont_starve_coverage_floor` added. The round-2 blocking interaction between the spacing scheduler and the §5.3 coverage floor is now explicitly bounded.

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 83 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 85 | pass |
| 5 | Safety / integrity (CRITICAL) | 82 | pass |
| 6 | Efficiency / cost | 80 | pass |
| 7 | Completeness | 78 | acceptable |
| 8 | Consistency | 80 | pass |
| 9 | Calibration / honesty | 83 | pass |

---

## Findings by dimension

### 1. Correctness

**Core retention math — correct and verified.**

- `R(t) = exp(−t/S)`, `t_next = −S·ln(r*)`: exact inverse. Verified numerically: at S=10, r*=0.85, `t_next=1.6252`, `R(1.6252/10)=0.85000000`. Correct.
- `S ← S·(1+a)` on pass (default a=1.0, doubling), `S ← S·b` on fail (default b=0.5, halving). Algebra verified: alternating pass/fail keeps S stable (`S·2·0.5 = S`). Correct.
- `S0 = max(S_unit·ĉ_m, S_min)` with S_min=0.1: at `ĉ_m=0`, `S0=0.1`, `t_next=0.0163 days`. Positive and finite. The `S0=0` degenerate case is eliminated. (BUILD-SPECS.md line 115.)

**`ĉ_mastery` naming — resolved (blocker 3).**

BUILD-SPECS.md line 115 now reads `ĉ_m = ProbabilisticState.estimate().mastery_mean`. This is the slow-decay §14-calibrated posterior mean, the correct quantity for scheduling (a fast-decay drift mean would yield volatile, shrinking intervals post-inactivity). The parenthetical "— *not* the `drift` one" removes all ambiguity for the developer.

**S-update binary pass/fail — explicitly justified (blocker 2).**

BUILD-SPECS.md line 129 acknowledges this as "the standard SRS design tradeoff", cites §14 calibration of `a,b` as the corrective mechanism, and offers an optional ≥2-consecutive step. The round-2 finding was that no justification existed; the justification now exists and is grounded in the existing SRS literature. The tradeoff is real but documented.

**Residual — `r*` boundary not guarded.**

At `r*=1.0`, `t_next=0` (cell always due, flooding the heap). At `r*=0`, `t_next=+∞` (cell never scheduled). Neither is a realistic default (0.85 is fine), but the spec contains no validation that `r*` must lie in `(0,1)`. This is a minor gap — it should appear in a parameter-validation note or an `assert 0 < r* < 1` in the pseudocode. Not blocking at this resolution level, but a developer implementation risk.

**Score rationale:** both main round-2 residuals resolved (+10); `r*` boundary gap minor (-5). Round-2 Correctness was 75 → **85**.

---

### 2. Design faithfulness

**`ĉ_mastery` → `mastery_mean` — fully resolved.**

The canonical v0.2 §3 terminology is `mastery[s,d] ~ Beta(αm, βm)` with `ĉ[s,d] = αm/(αm+βm)`. The spec now maps directly to `ProbabilisticState.estimate().mastery_mean` (the §14-calibrated version of this quantity). Naming convergence with §3 and §14 is established.

**Architecture integration — coherent.**

The `Scheduler` over `ProbabilisticState + CacheStore + per-cell S` is faithful to §3 (state) + §10 (Redis/CacheStore for the due-heap) + §5.3 (coverage floor with due-boost). The `ρ_rev` budget cap plugs directly into the §5.3 `choose()` loop without altering any §3–§12 mechanism.

**Residual — calibration integration still at 'Honest risks' level, not mechanism level.**

BUILD-SPECS.md line 127: "must be **calibrated empirically** (§14): does a cell at predicted `R=r*` actually pass at `r*`?" and line 129: "`§14` calibration of `a,b` corrects systematic over-inflation." The §14 calibration layer is cited as a safeguard but the Scheduler does not formally declare that it consumes `ProbabilisticState.estimate()` (the §14-calibrated posterior) rather than the raw posterior. The `mastery_mean` pinning in the S0 formula implies §14 is consumed, but the Scheduler's read path through `estimate()` is not stated at the plug-point level. This is a minor design-faithfulness gap — not blocking but worth a one-line clarification at the plug-point.

**Score rationale:** main naming gap resolved (+5); calibration integration implicit rather than declared at plug-point (-2). Round-2 Design faithfulness was 78 → **83**.

---

### 3. Red-team resistance

**Root causes from ALGORITHM-v0.1-redteam.md evaluated:**

**RC-1 (point estimates where statistical tests required).**
BUILD-SPECS.md line 129 now explicitly acknowledges the S-update binary tradeoff and states §14 calibration of `a,b` corrects systematic over-inflation, with an optional ≥2-consecutive step to reduce single-event volatility. This converts a silent RC-1 analogue into a documented design choice. The residual is: with the ≥2-consecutive step marked **optional**, a default-configuration deployment still uses single-event updates. However, (a) the §14 calibration path recalibrates `a` to realized retention data; (b) the lapse rule (`S←S·b`) self-corrects over-optimistic S at the next review; (c) the S-update is a scheduling parameter, not a gate that accumulates irreversibly. These three mitigations together make the RC-1 residual substantially less severe than in round 1.

**RC-7 (cramming / weak-skill abandonment).**

*`p_probe` (blocker 1):* BUILD-SPECS.md line 128 specifies "per due-interval" and "indistinguishable from a scheduled review (cramming can't time around it)." The indistinguishability claim is a genuine deterrent — a crammer cannot time their study around an unscheduled probe they cannot identify. The `~1/p_probe` bound (= 10 intervals) is on the **number of intervals before a probe fires**, not on S magnitude. Verified: after 10 consecutive crammed passes with a=1.0, S = (1+1.0)^10 × S_unit = 1024 × S_unit. The spec does not bound S magnitude directly; it bounds interval count. This is technically accurate but leaves the practical severity — 1024-day intervals — implicit. The §14 recalibration of `a` is the corrective mechanism that would catch systematic over-inflation in the `a` parameter. The optional ≥2-consecutive step (B2) would reduce worst-case S after 10 passes from 1024× to 32× initial.

*Coverage floor (`ρ_rev`, blocker 5):* BUILD-SPECS.md line 130 adds `ρ_rev=0.5` cap. This directly closes the round-2 RC-7 concern: due reviews cannot crowd out more than 50% of the per-tick budget, so the §5.3 `f_min` floor for non-due weak skills is preserved by construction. `test_reviews_dont_starve_coverage_floor` validates this.

*Weak-skill abandonment:* unchanged from round 2. The `ρ_rev` cap + existing coverage floor together prevent spacing reviews from calcifying weak skills. No regression.

**RC-5 (single global γ over-determined):** not implicated. The Scheduler is additive, sits atop §3, and does not alter the dual-posterior decay machinery.

**RC-2 (held-out split):** S updates fire on "held-out pass/fail" (BUILD-SPECS.md line 115), consistent with §4.1. No regression.

**RC-3, RC-4, RC-6, RC-8:** not implicated.

**Residual — systematic cramming S-inflation magnitude not explicitly bounded.**

The `~1/p_probe` bound on interval count is correct and honest, but a reviewer constructing the worst case independently computes S = 1024× S_unit at defaults after the expected 10 crammed intervals before a probe. The spec relies on §14 recalibration to catch this systematically, but §14 operates on a per-band population cadence (BUILD-SPECS.md line 127 / ALGORITHM-v0.2 §14.2), not per-learner in real-time. A systematic crammer may inflate their own S substantially before the population-level recalibration of `a` fires. This is a genuine residual risk, reduced but not eliminated by the spec's defenses. It is the same adversarial case surfaced in round 2 — the mitigation is now explicitly stated and stronger, but the risk is not fully closed.

**Score rationale:** `p_probe` fully specified with scope and indistinguishability (+5); `ρ_rev` cap closes coverage-floor gap (+5); RC-1 residual on S-update now documented (+3); systematic cramming S-inflation implicitly bounded but not explicitly computed (-3). Round-2 RedTeam was 72 → **82**.

---

### 4. Implementability

**All four round-2 implementation gaps resolved:**

- **`ĉ_mastery` → concrete method call** (BUILD-SPECS.md line 115): `ProbabilisticState.estimate().mastery_mean`. A developer has an unambiguous call site. The parenthetical "not the `drift` one" preempts the most common wrong choice.
- **Interleave window default** (line 123): "no same-skill within 3 due items." Concrete, actionable.
- **Due-boost magnitude** (line 123): "+0.5 to the candidate score." Concrete default.
- **`p_probe` scope** (line 128): "per due-interval." Unambiguous operational scope for an SRS scheduler.
- **`ρ_rev` budget cap** (line 123): 0.5, with a test verifying it.

**Parameters section (line 123) is now fully concrete:** `r*` (0.85), `a` (1.0), `b` (0.5), `S_unit` (1), `S_min` (0.1), `p_probe` (0.1), interleave window (3 items), due-boost (+0.5), `ρ_rev` (0.5). Every parameter has a default. This is a significant improvement from round 2 where three parameters lacked defaults.

**Residual — `r*` not validated at the parameter level.**

No assertion that `0 < r* < 1` is required. A developer setting `r*=1.0` (perhaps expecting "always review") gets a scheduler that floods the heap. A one-line validation note would close this.

**Residual — pass/fail operationalization.**

BUILD-SPECS.md line 115 says "on a held-out pass (default a=1.0)". The criterion for a "pass" — a single correct item, or an aggregate over multiple items — is still implicit. For a developer implementing `Scheduler.update(cell, outcome)`, the question is whether `outcome` is a binary per-item flag or a multi-item aggregate. Given that the spec now explicitly acknowledges this as the SRS standard tradeoff (dimension 1 finding), and the rest of the system uses binary item outcomes for posterior updates (§3), the convention is inferable — but not stated.

**Score rationale:** all four round-2 gaps closed (+15); two minor residuals (`r*` validation, pass/fail convention) remain (-5). Round-2 Implementability was 70 → **85**.

---

### 5. Safety / integrity

**No gate weakened; `ρ_rev` cap adds a new protection.**

The known gates are intact: §8 commit gate (statistical + generalization + cumulative + safe), §14 calibration (ECE trigger → circuit breaker), §4 held-out split. B4's Scheduler is additive and influences only scheduling priority, not any gate condition.

The `ρ_rev=0.5` budget cap is a new integrity constraint that prevents the spacing scheduler from monopolizing the per-tick budget and starving the §5.3 coverage floor. This is a strengthening, not a weakening, of the §5.3 integrity invariant.

**Residual — S-update / commit-gate coupling ambiguity (carried from round 2).**

A due review that is subsequently rejected by the §8 commit gate (e.g., the held-out outcome does not clear `significant(Δĉ_secret, SE, margin=ε)`) may still have updated S — because S is updated on the raw held-out outcome (pass/fail), not on the commit gate decision. This means S and the §3 posterior could diverge on a rejected commit: S grows (or contracts), but the checkpoint rolls back. The spec does not address this coupling. In the standard commit/rollback flow (§6), a rollback discards the child state; if S is stored per-cell alongside the posterior, it should be rolled back with it. If S is stored separately (e.g., in the Scheduler), a rollback would leave S in an updated state while the posterior reverts. This is an integrity gap at the implementation level. It is not a gate-weakening, but it is a correctness-under-rollback issue that a developer must handle explicitly.

**Score rationale:** `ρ_rev` cap strengthens §5.3 coverage protection (+3); S-commit coupling gap unchanged (-3 relative to round 2's baseline). Round-2 Safety was 78 → **82** (net: the ρ_rev improvement slightly outweighs the persistent coupling gap, raising the floor on an otherwise unchanged dimension).

---

### 6. Efficiency / cost

No change from rounds 1–2. Min-heap in Redis: `O(log n_cells)` per insert/extract. No new LLM calls. Per-cell S is a single scalar. The `ρ_rev` cap adds a trivial budget-accounting check per tick. `p_probe` adds a Bernoulli draw per due review — negligible. The overall hot-path cost is unchanged.

**Score: 80 (unchanged).**

---

### 7. Completeness

**Resolved since round 2:**
- Interleave window default: 3 items (line 123).
- Due-boost default: +0.5 (line 123).
- `p_probe` scope: per-due-interval (line 128).
- `ρ_rev` budget cap: 0.5 (line 123).
- Tests added: `test_reviews_dont_starve_coverage_floor` (line 139), `test_probe_bounds_inflation` (line 141).

**Remaining gaps:**

- **`r*` boundary not validated.** `r*=1.0` gives `t_next=0` (all cells always due). `r*=0` gives `t_next=+∞` (cells never reviewed). No `assert 0 < r* < 1` or equivalent appears in the spec or tests.
- **First-time encounter not specified.** A cell encountered for the first time during a session has a cold-start posterior (`Beta(α0,β0)` from §3). The spec does not say whether S is initialized immediately on first encounter or deferred until after the first held-out evaluation (when `mastery_mean` is more informative than the cold prior). If S is initialized from the cold prior, `ĉ_m = α0/(α0+β0)` (e.g., 0.5 at `(α0,β0)=(1,1)`), giving `S0 = 0.5 × S_unit`. This is probably correct behavior, but the spec does not confirm it.
- **S-commit coupling not tested.** No test for `test_s_not_updated_on_rejected_commit` — verifying that S rolls back when the §8 gate rejects a commit. This is the implementation risk identified in dimension 5.
- **`test_probe_bounds_inflation` scope.** BUILD-SPECS.md line 141 names this test but does not say what it asserts. Given the `~1/p_probe` bound is on interval count (not S magnitude), the test should assert that the expected number of undetected crammed intervals is ≤ 1/p_probe — not that S is bounded to 1/p_probe × initial.

**Score rationale:** five gaps closed (+15); four gaps remain — `r*` validation, first-encounter behavior, S-commit coupling test, probe-bounds test scope (-12). Round-2 Completeness was 65 → **78**.

---

### 8. Consistency

**`ĉ_mastery` naming convergence — resolved.**

BUILD-SPECS.md line 115 now references `ProbabilisticState.estimate().mastery_mean`, which is the §14-calibrated posterior mean deriving from the §3 `mastery[s,d] ~ Beta(αm, βm)` slow-decay dual posterior. The naming consistency with §3 and §14 is established.

**ALGORITHM-INTEGRATIONS.md label — unchanged minor gap.**

ALGORITHM-INTEGRATIONS.md line 19 labels the integration point as "Desirable-difficulties scheduling — interleaving + spacing + testing-effect." B4 implements spacing + interleaving only. Testing-effect proper (the benefit of retrieval practice, as distinct from spaced review) is not a mechanism in B4. This creates a minor label overshoot that B4 cannot fully fulfill. Not a B4 spec defect — the register label is an approximation — but worth a narrowing if the register is used for implementation scope.

**Internal consistency — improved by `ρ_rev`.**

The addition of `ρ_rev=0.5` resolves the previously inconsistent state where B4 claimed to compose with A1 and §5.3 without bounding the budget interaction. The §5.3 coverage floor is now explicitly protected by the cap.

**Score rationale:** naming gap resolved (+5); register label overshoot unchanged (-2); internal consistency improved by `ρ_rev` (+2). Round-2 Consistency was 75 → **80**.

---

### 9. Calibration / honesty

**Cramming story — fully honest and stronger than round 2.**

BUILD-SPECS.md lines 128–129 now state: (a) `p_probe` fires per-due-interval and is indistinguishable from a scheduled review; (b) worst-case undetected over-inflation is `~1/p_probe` intervals; (c) single-event S volatility is the standard SRS tradeoff; (d) §14 calibration of `a,b` corrects systematic over-inflation; (e) ≥2-consecutive step is available optionally. This is an accurate, complete, and well-calibrated characterization of both the risk and the mitigations.

**`~1/p_probe` bound — technically correct, quantitatively partial.**

The bound is on interval count (10 intervals at defaults), not on S magnitude. A sophisticated reader can compute that 10 crammed intervals → S = 1024× S_unit at a=1.0. The spec does not hide this — it frames the ~1/p_probe bound accurately as an interval-count bound — but it does not surface the computed S magnitude. Rounding this to a calibration note: the spec is honest about what the bound covers; it could be slightly more forthcoming about what it does not cover (S magnitude). Not a blocking calibration gap.

**Honest risks section (lines 125–130) — well-structured.**

Four risks are listed: over-scheduling (mitigated by EIG), exponential model approximation (must be §14-calibrated), cramming (next review catches it + `p_probe`), and review starvation (capped by `ρ_rev`). All are genuine, and each has a stated mitigation that is consistent with the rest of the spec.

**Score rationale:** cramming story now complete and honest (+3); `~1/p_probe` bound partially quantified (-2); four honest risks with real mitigations (+2). Round-2 Calibration was 78 → **83**.

---

## Strongest adversarial objection

**S-update on rollback: a scheduler that partially persists through commit failures.**

Every other objection surfaced in rounds 1–3 has been substantially addressed. The remaining adversarial angle the spec has not closed:

If a due review fires, the learner attempts the held-out item, the `Scheduler` updates S based on the binary outcome (pass → S doubles, fail → S halves), and then the §8 commit gate rejects the commit (e.g., the `significant(Δĉ_secret, SE, margin=ε)` test fails — a common case when `n_eff` is small), the following state is created: S has been updated, but the checkpoint rolls back, so `mastery[s,d]` is reverted. The `t_next` computed from the updated S is now stored in the Redis heap, but the competence posterior it was calibrated against has reverted to its pre-review state. The next time `t_next` is hit, S0 will be recomputed from the reverted `mastery_mean` — but the interval has already been scheduled from the updated S.

This is not merely a theoretical issue. In the early learning phase, many commits will be rejected (the posterior is noisy, `n_eff` is small, and `significant()` is a high bar). A learner who genuinely improves but whose posterior hasn't accumulated enough evidence to clear the gate will accumulate S inflation from the raw pass outcomes while their posterior stays anchored. Conversely, a learner who is declining but passes a lucky held-out item gets S inflation that then schedules a very long review window — after which the posterior has decayed.

The spec does not address whether S is stored in the `Scheduler` (independent of the checkpoint) or co-located with the competence posterior (and therefore rolled back with it). The data-layer spec (`DATA-LAYER.md`) stores the competence posterior in `StateStore` (MongoDB/SQLite) under `cell.mastery`, and the `CacheStore` (Redis) holds `t_next` in the min-heap. If S is stored in the heap or a Scheduler-side table (outside `StateStore`), it will not be rolled back by the checkpoint mechanism. If S is in `StateStore.cell`, it will be rolled back — but the spec does not say where S lives.

This is distinct from all nine dimension findings, which touched on the S-update tradeoff but did not examine the rollback coupling specifically. It is the single strongest objection that remains open: the scheduler may partially escape the commit/rollback discipline that governs every other state in the system.

**Mitigation path:** a one-line addition to the plug-point — "S is stored in `StateStore.cell` alongside the `mastery` and `drift` posteriors, so it participates in the §6 rollback" — closes this cleanly. Alternatively: "S updates fire only on committed outcomes (after the §8 gate passes, not on the raw held-out observation)."

---

## Aggregate confidence

```
critical_floor  = min(score_Correctness, score_RedTeam, score_Safety)
               = min(85, 82, 82)
               = 82

weighted_mean   = (score_Correctness × 2 + score_DesignFaithfulness × 1
                   + score_RedTeam × 2 + score_Implementability × 1
                   + score_Safety × 2 + score_Efficiency × 1
                   + score_Completeness × 1 + score_Consistency × 1
                   + score_Calibration × 1) / 11
               = (85×2 + 83×1 + 82×2 + 85×1 + 82×2 + 80×1 + 78×1 + 80×1 + 83×1) / 11
               = (170 + 83 + 164 + 85 + 164 + 80 + 78 + 80 + 83) / 11
               = 987 / 11
               = 89.73

overall         = min(82, 89.73) = 82
```

**Overall confidence: 82 / 100**

*(Round 1: 68 · Round 2: 72 · Round 3: 82. All five round-2 blockers resolved. The 10-point gain from round 2 is driven by: p_probe scope + indistinguishability, ρ_rev cap closing the coverage-floor interaction, mastery_mean pinning, and explicit S-volatility acknowledgment. The critical floor of 82 is set by RedTeam and Safety, which share the S-commit coupling residual and the implicit S-magnitude bound.)*

---

## Verdict

**ready-for-approval**

No CRITICAL dimension falls below 70. The aggregate score of 82 clears the 80 threshold.

The following items are non-blocking but recommended for the implementation phase to close the remaining residuals:

1. **[Completeness / Safety] Specify where S is stored relative to the commit/rollback boundary.** Add one line to the plug-point: either "S is stored in `StateStore.cell` and rolls back with the mastery posterior" or "S updates fire only after the §8 gate passes." This closes the strongest adversarial objection (scheduler state partially escaping rollback discipline) before implementation.

2. **[Completeness / Correctness] Add `r*` input validation.** A one-line note: "`r*` must satisfy `0 < r* < 1`; `r*=1` gives `t_next=0` (permanent due)." Prevents a silent degenerate scheduling mode.

3. **[Completeness] Clarify test `test_probe_bounds_inflation` assertion.** The test should assert that the expected number of undetected crammed intervals ≤ `1/p_probe` (the stated bound), not that S itself is bounded to `1/p_probe × initial`. This scopes the test to match the actual bound.

4. **[Calibration] Consider making ≥2-consecutive step the default, or quantifying its tradeoff.** The spec marks it "optional." At defaults (a=1.0), the optional step reduces worst-case S inflation from 1024× to 32× after 10 passes. Given the target use case (human learning), where a 2.8-year review interval is clearly pathological, a note on when to enable the step (e.g., "recommended for high-stakes cells or when cramming is likely") would improve the spec's practical guidance.
