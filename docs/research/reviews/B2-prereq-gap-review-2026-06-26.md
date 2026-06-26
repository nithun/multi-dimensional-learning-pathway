# 360 Review: B2-prereq-gap — 2026-06-26 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` |
| Proposed change | Revised build-spec B2 (Round 3): Prerequisite-gap diagnosis with `d_max=4`, `n_trigger≥3` failures **or** `significant(θ−ĉ[S], SE)`, confirmation items ≥5 (power-noted), B1-absent fallback, and a **time-windowed** post-redirect outcome check requiring `n_post≥5` held-out attempts on `S` after `P`-mastery before `g.decay_edges()` fires |
| Reviewer | review-360 |
| Date | 2026-06-26 (Round 3; Round 2 score: 78/100 needs-revision; Round 1 score: 68/100 needs-revision) |

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 90 | pass |
| 2 | Design faithfulness | 88 | pass |
| 3 | Red-team resistance (CRITICAL) | 83 | pass |
| 4 | Implementability | 83 | pass |
| 5 | Safety / integrity (CRITICAL) | 88 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 84 | pass |
| 8 | Consistency | 85 | pass |
| 9 | Calibration / honesty | 87 | pass |

---

## Findings by dimension

### 1. Correctness

**Score: 90 — pass**

**Round-2 blocker 1 (resolved): `d_max` and `n_trigger` defaults.**
BUILD-SPECS.md B2 §Parameters (line 196) now reads: "`θ` mastery bar (existing §5.2) · `d_max` depth cap (4) · `n_trigger` failures (3) · confirmation items (≥5, power-noted) · `n_post` post-redirect window (5) · `z` (existing)." All four previously unanchored parameters now have explicit defaults. `d_max=4` is a plausible depth cap for typical prerequisite chains; `n_trigger=3` is a sensible minimum-evidence trigger; confirmation ≥5 is sufficient to run `significant()` with a meaningful SE; `n_post=5` provides a minimum observation window. The depth cap makes the BFS O(|V| ∩ depth≤4), bounded.

**Round-2 blocker 2 (resolved): trigger condition quantified.**
The trigger (line 187) is now explicit: "`n_trigger ≥ 3` held-out failures at `S` **or** `significant(θ − ĉ[S], SE)`." Both a count-based criterion and a statistical criterion are provided. A developer can implement either branch unambiguously. The disjunction is correct: a learner can accumulate 3 failures before the posterior is wide enough for `significant()` to fire, and the `significant()` branch catches a case where failures are sparse but the posterior mean is already clearly below `θ`.

**Round-2 blocker 3 (resolved): temporal window for outcome check.**
The R2 adversarial objection (the most important blocker) is resolved by the addition in §Mechanism step 3 (line 189): "measured over `n_post≥5` held-out attempts on `S` *after* `P` is mastered (so a valid edge isn't decayed before transfer can manifest)." This is the correct fix. Gating the decay trigger on post-mastery observations rather than post-redirect observations correctly handles the transfer lag: the system waits until `P` is actually mastered and then requires evidence from `S` before firing the edge decay. The causal test is now: "P was mastered, then S was assessed ≥5 times, and S did not significantly rise." This is a sound operationalization of the causal hypothesis.

**B1-absent fallback (new, resolved from R2 blocker 5 interface spec):**
Line 187 now includes: "if B1 is absent, skip that filter." This is the correct minimal specification for the B1 dependency — it degrades gracefully when B1 is not deployed, turning the misconception-filter into a no-op. The trigger fires on repeated failure alone.

**Residual 1-A (minor — Finding 1-C from R2, partially resolved):**
The confirmation step (line 189) now reads "confirm with targeted held-out items on `P` before redirecting" in the context of `significant()` descents. However, the confirmation gate is still described without explicitly invoking `significant(θ−ĉ_confirmed[P], SE)`. The R2 Finding 1-C noted this as implied but not stated. With `n_post ≥ 5` items specified and the overall `significant()` discipline of the spec, this is a minor documentation gap rather than a mechanism flaw. A developer following the spirit of §2 will apply the gate correctly.

**Residual 1-B (minor):**
The "or" in the trigger ("`n_trigger ≥ 3` **or** `significant(θ − ĉ[S], SE)`") creates an edge case: if `n_trigger=3` fires before `significant()` would, the trigger fires with a potentially noisy posterior. This is intentional (a count-based safety net), but the spec does not state how many of the 3 failures must be on held-out items vs. practice items. Given the spec's consistent use of held-out items for all gates, this is implied, but a one-word clarification ("held-out failures") would remove ambiguity. Not blocking.

---

### 2. Design faithfulness

**Score: 88 — pass**

**Finding 2-A (pass, confirmed from R2):**
The branch-local BFS with `significant(θ−ĉ_mastery[P], SE[P])` descent continues to be architecturally faithful to §2 (gate primitive) and §3 (mastery posterior). The `n_post≥5` window uses the mastery posterior from §3, not the drift posterior — appropriate because the transfer measurement is medium-term, not a real-time drift signal.

**Finding 2-B (pass, confirmed from R2):**
The post-redirect outcome check correctly calls `g.decay_edges()` (§5.1, line 133 of ALGORITHM-v0.2). The R2 adversarial objection about firing too early is resolved by the `n_post` window. The mechanism now asks: "after P is mastered AND after n_post≥5 held-out attempts on S, did ĉ[S] rise significantly?" That is a valid use of the existing §5.1 decay hook with a pre-condition.

**Finding 2-C (substantially resolved from R2 Finding 2-D):**
The B1-dependency interface gap is resolved to the extent that the fallback is specified ("if B1 is absent, skip that filter"). The field/call used to check B1 at runtime is still not formally defined (StateStore field? API call? CacheStore entry?), but the fallback makes this a graceful degradation rather than a hard dependency. For a full spec this would ideally name the interface, but it is no longer a blocking gap.

**Finding 2-D (pass):**
Redirect adds the confirmed prereq to the Tutor's candidate set, which flows through A1's `U(a)` and the coverage floor (§5.3). No architecture bypass.

**Finding 2-E (minor, residual from R2 Finding 8-E):**
The parameter comment "Acyclicity + depth-cap `d_max`, §5.1/§5.2" (line 188) still attributes `d_max` to §5.1/§5.2, where it does not appear by that name. This is a citation issue, not a mechanism flaw. `d_max` is B2-local; the acyclicity invariant is inherited from §5.1. Minor.

---

### 3. Red-team resistance

**Score: 83 — pass**

Citing root causes from `ALGORITHM-v0.1-redteam.md`:

**Finding 3-A (resolved from R1/R2 — RC-1):**
The descent criterion `significant(θ−ĉ_mastery[P], SE[P])` correctly gates out cold-start noise. The trigger `n_trigger≥3 or significant(θ−ĉ[S], SE)` is also now RC-1-clean. RC-1 reintroduction in the BFS descent and in the trigger is closed.

**Finding 3-B (resolved from R2 adversarial objection — temporal RC-4 confounding):**
The `n_post≥5` post-mastery window closes the R2 adversarial objection. A valid causal P→S edge is now protected from premature decay: the edge decay check does not fire until P is mastered and at least 5 held-out S observations have been made. This is the critical safety improvement from R3. The residual confounding (a hidden common cause) remains honestly acknowledged in the spec.

**Finding 3-C (residual — moderate — RC-4 edge-confidence filter):**
R2 Finding 3-C noted that B2 does not filter backward-walk edges by current edge confidence. This is **not resolved** in R3. The B2 walk still traverses any edge in `GraphStore` regardless of its current confidence value (which may have decayed via `g.decay_edges()`). A prereq P→S edge that was placed in `GraphStore` by `g.step()` but later accumulated multiple negative outcome signals may have decayed confidence close to zero — yet B2 will still walk it. This means B2 can diagnose a prereq relationship the overall system has already learned is spurious. The fix would be to add a traversal filter: traverse edge P→S only if `edge.confidence ≥ τ_traverse`. This is a moderate residual gap. It does not cause unsafe behavior (the confirmation step will not find a gap if P is actually mastered), but it wastes diagnostic effort and may confuse the learner with a redirect to a prereq the graph already has low confidence in.

**Finding 3-D (residual — minor — RC-3 thin-item-bank):**
R2 Finding 3-D (thin item bank on recently-grown P produces systematically conservative confirmation) remains unaddressed. With only 5 confirmation items at the minimum, a thin item bank produces a wide SE on `ĉ[P]`, making `significant(θ−ĉ, SE)` hard to satisfy for borderline gaps. The `pending_human` fallback correctly handles zero-item-bank prereqs; the thin-bank case produces false negatives silently. The spec's "power-noted" acknowledgment in the parameters covers this partially, but the impact on diagnosis sensitivity is not explicitly quantified. Minor — honest risk coverage is adequate.

**Finding 3-E (pass — RC-2):**
The confirmation step uses held-out items from §4. No RC-2 reintroduction.

**Finding 3-F (pass — RC-7):**
The redirect adds P to the candidate set without removing S. The coverage floor (§5.3, f_min) continues to protect S. No RC-7 starvation.

**Finding 3-G (pass — RC-1 on trigger OR branch):**
The disjunctive trigger "`n_trigger≥3 or significant(θ−ĉ[S], SE)`" means the count branch (`n_trigger≥3`) can fire without the statistical branch passing. Three held-out failures is a reasonable empirical floor — the posterior mean will typically be below θ by then, making the count-based trigger a useful early-warning. The two branches complement each other correctly.

---

### 4. Implementability

**Score: 83 — pass**

**Finding 4-A (resolved from R2 — `d_max`, `n_trigger`, `n_post` defaults):**
All three unanchored parameters from R2 now have defaults. A developer can write a self-contained first implementation without guessing: `d_max=4` for BFS, fire at `n_trigger=3` failures or `significant(θ−ĉ[S],SE)`, confirm with ≥5 items, check outcome after `n_post=5` post-mastery S observations.

**Finding 4-B (substantially resolved from R2 — trigger condition):**
"Repeated held-out failure at S" is now defined as `n_trigger≥3 held-out failures or significant(θ−ĉ[S], SE)`. A developer can implement both branches.

**Finding 4-C (substantially resolved from R2 — B1 fallback):**
The "if B1 is absent, skip that filter" fallback means the B1 interface is no longer a hard dependency. When B1 is present, the spec still does not name the exact API (e.g., `Misconception.is_active(skill, learner)`), but the graceful degradation resolves the deployment blocker.

**Finding 4-D (residual — moderate — post-mastery window tracking):**
The `n_post≥5` window requires tracking: (a) when P-mastery was confirmed, and (b) counting held-out S attempts after that point. Neither is specified as a state field. Concretely: does the `Diagnose` component write a `redirect_active{skill_S, prereq_P, mastery_confirmed_at, n_post_observations}` record to `StateStore` or `TruthStore`? Without this, two developers will implement the window tracking in incompatible ways. This is a moderate gap — the mechanism is clear but the state lifecycle is not. Recommend adding a `redirect_log` entry to `TruthStore` (or a `Diagnose`-owned `StateStore` record) as the tracking artifact.

**Finding 4-E (residual — minor — outcome-feedback "lift" threshold):**
R2 Finding 9-C noted that "lift" is not quantified. R3 resolves the *temporal* aspect (n_post≥5 window) but still does not explicitly state that "lift" means `significant(Δĉ[S], SE)` over the n_post window. Given the spec's consistent use of `significant()` everywhere else, this is strongly implied — a developer following the spec's discipline will use it. Minor gap.

**Finding 4-F (pass):**
The five tests are concrete and testable. The `test_failed_redirect_decays_edge` test, combined with the `n_post` window, now provides a clear scenario for the post-redirect loop. The `test_no_gap_not_misdiagnosed` test and `test_confirmation_rejects_spurious_prereq` cover the negative cases. Test coverage is adequate for a spec.

---

### 5. Safety / integrity

**Score: 88 — pass**

**Finding 5-A (pass, confirmed):**
The double-gate structure is maintained and strengthened: (1) `significant(θ−ĉ_mastery[P], SE[P])` in the walk gates against noise-driven candidate selection; (2) targeted held-out confirmation gates against false positives before redirect; (3) `n_post≥5` post-mastery window on S gates `g.decay_edges()` against premature causal-edge destruction.

**Finding 5-B (resolved from R2 adversarial objection — the key safety improvement):**
The `n_post≥5 held-out attempts on S *after* P is mastered` condition directly closes the R2 adversarial objection. The spec explicitly states the guard ("so a valid edge isn't decayed before transfer can manifest," line 189). This is the critical safety fix: without the temporal guard, the feedback loop could silently corrupt the prereq graph by decaying valid causal edges before transfer has had time to manifest. With it, the feedback loop is a sound downstream corrector.

**Finding 5-C (residual — moderate — decay rate unspecified):**
R2 Finding 5-C (the rate at which `g.decay_edges()` reduces edge confidence is not specified) is **not addressed** in R3. The spec inherits the decay rate from §5.1, which does not specify a default decay per negative outcome. If the decay is slow (e.g., confidence halves per 10 negative post-redirect outcomes), many learners may be redirected to a spurious path before the edge confidence drops below `τ_traverse`. The `n_post≥5` window reduces the false-negative rate on the outcome check, but the *speed of correction* remains unquantified. This does not threaten the gates (they remain sound) but leaves the safety recovery window uncharacterized.

**Finding 5-D (pass — resolved from R2 Finding 5-F):**
The `if B1 is absent, skip that filter` text means the trigger is well-defined regardless of B1 deployment. The `d_max=4` cap provides a hard termination guarantee for any single BFS invocation. The spec does not address sequential re-triggering (B2 invoked on S, which then diagnoses P, which could itself trigger B2 on P), but `d_max=4` on each BFS call bounds the single-invocation depth; sequential chaining is bounded by the same `n_trigger` threshold on each skill individually. The risk is acknowledged implicitly through the acyclicity invariant.

**Finding 5-E (pass):**
B2 reads from `ProbabilisticState` and `EvalHarness`; it does not modify their internals. The §14 calibration layer and verifier admission criteria are untouched. No gate is weakened.

**Finding 5-F (pass — RC-7):**
Redirect adds P to the candidate set. The coverage floor on S is preserved through §5.3 `f_min`. The Tutor then allocates via A1's info-gain — a mathematically sound prioritization. No starve condition.

---

### 6. Efficiency / cost

**Score: 85 — pass**

**Finding 6-A (pass):**
BFS with `d_max=4` and the §5.1 fan-in cap is O(branching_factor^4) in the worst case, bounded to a small constant in realistic prereq graphs. The trigger is infrequent (≥3 held-out failures) and off the hot path. No hot-path regression.

**Finding 6-B (pass):**
The `n_post≥5` post-mastery tracking adds one counter increment per held-out S observation post-redirect. This is O(1) per observation. The `g.decay_edges()` call when the window completes is O(1) per edge. Negligible overhead.

**Finding 6-C (minor — unchanged from R2):**
The synchronous/asynchronous timing of the BFS walk and confirmation step is not specified. In an interactive human-learning session, synchronous confirmation (issuing ≥5 held-out P items in the same session turn as the diagnosis) adds observable latency. The expected amortized cost is low given the infrequent trigger, and this is a deployment detail outside the scope of a spec. No complexity impact.

**Finding 6-D (minor):**
Tracking `n_post` requires persisting a redirect-state record between sessions (the P-mastery confirmation timestamp and subsequent S-observation counter). This is at most one additional StateStore read/write per post-redirect S observation. Cost is negligible but the state record adds a small schema footprint (noted in Finding 4-D as unspecified).

---

### 7. Completeness

**Score: 84 — pass (was 76 — pass in R2; was 58 — blocking in R1)**

**Finding 7-A (resolved from R2 — all parameters now have defaults):**
`d_max=4`, `n_trigger=3`, `n_post=5`, confirmation ≥5 (power-noted), `θ` from §5.2, `z` from existing. All parameters needed to implement B2 without guessing are now provided.

**Finding 7-B (resolved from R2 — trigger condition):**
The trigger is now fully specified: count-based (`n_trigger≥3 held-out failures`) or statistical (`significant(θ−ĉ[S], SE)`), with B1 fallback.

**Finding 7-C (resolved from R2 — outcome-feedback temporal guard):**
The `n_post≥5 held-out attempts after P-mastery` condition provides the time-window the R2 adversarial objection demanded. The post-redirect loop is now implementable.

**Finding 7-D (residual — minor):**
No test for the B2 trigger firing via the `significant(θ−ĉ[S], SE)` branch specifically (as distinct from `n_trigger≥3`). The existing tests cover the count-based path. A test like `test_statistical_trigger_fires_before_count` — where `significant()` fires at 2 failures because the posterior is strongly below θ — would close this minor gap. Not blocking but a coverage hole.

**Finding 7-E (residual — minor, unchanged from R2 Finding 7-D):**
No test for B2 invoked on a root node (S has zero prereqs). The expected behavior is "no gap found — issue is S itself." This is logically correct but remains unstated and untested.

**Finding 7-F (residual — minor):**
The `n_post` window completion event (when do we declare "n_post observations have been collected and the lift check can now fire?") is not tied to a specific test. `test_failed_redirect_decays_edge` is the closest, but it does not explicitly test the guard condition "lift check fires only after n_post≥5 post-mastery S observations." A test `test_edge_not_decayed_before_npost_observations` would make the guard verifiable.

---

### 8. Consistency

**Score: 85 — pass (was 83 in R2)**

**Finding 8-A (pass):**
All gate primitives use `significant(Δ, se, margin, z)` from §2 (ALGORITHM-v0.2 lines 43–49). No new gate formula introduced. The trigger, descent criterion, and the implied confirmation gate all follow the §2 discipline.

**Finding 8-B (pass — confirmed from R2):**
`g.decay_edges()` is the §5.1 method (ALGORITHM-v0.2 line 133). B2 correctly adds a trigger condition for it without introducing a new mechanism.

**Finding 8-C (pass):**
`ProbabilisticState.estimate()` returns the calibrated posterior (§14.2). B2 uses `ĉ_mastery[P]` which is the slow-decay mastery posterior — the appropriate one for a medium-term diagnosis walk (not the fast-decay drift posterior, which is for rollback). Consistent with §3 and §14.

**Finding 8-D (pass):**
`GraphStore.prereqs(s)` (DATA-LAYER.md line 74) is the correct interface for the BFS walk. `GraphStore.reach_weight()` (DATA-LAYER.md line 72) is available for the soft-reachability view. No schema inconsistency.

**Finding 8-E (minor, residual from R2):**
The `d_max` citation to "§5.1/§5.2" (line 188) remains technically incorrect — `d_max` is a B2-local parameter not defined in those sections. The acyclicity invariant and fan-in cap ARE from §5.1; the depth cap is not. This is a documentation inconsistency, not a mechanism flaw.

**Finding 8-F (pass):**
The B1-absent fallback is consistent with the overall spec philosophy of graceful degradation (analogous to `pending_human` for missing item banks). No contradiction with B1's spec.

---

### 9. Calibration / honesty

**Score: 87 — pass (was 82 in R2)**

**Finding 9-A (resolved from R2 adversarial objection — temporal validity):**
The spec now honestly bounds the outcome-feedback loop: "measured over `n_post≥5` held-out attempts on `S` *after* `P` is mastered (so a valid edge isn't decayed before transfer can manifest)." The parenthetical is an honest acknowledgment of the temporal gap between P-mastery and S-improvement — exactly the limitation the R2 adversarial objection raised. This is correct epistemic framing: the spec names the assumption (transfer manifests within the n_post observation window) and its parameter (`n_post=5` as a default).

**Finding 9-B (pass, confirmed):**
"Confirmation + this feedback loop reduce, but don't eliminate, confounding" (line 189) is the correct honest framing. A hidden common cause (latent ability underlying both P and S) cannot be ruled out from observation alone. The spec does not overclaim.

**Finding 9-C (residual — minor):**
The "lift" definition in the outcome check is still not stated explicitly as `significant(Δĉ[S], SE)`. This was R2 Finding 9-C. It is now less critical because the temporal condition (`n_post≥5 post-mastery observations`) resolves the dominant concern, and the implied use of `significant()` follows from the spec's overall discipline. However, explicitly writing "significant rise in ĉ[S] over the n_post window" would make the feedback loop fully self-contained. Minor gap.

**Finding 9-D (pass):**
The honest risk section correctly identifies the three main failure modes (wrong-prereq attribution, cycles/dense graphs, unobservable gaps) and provides appropriate fallbacks or mitigations for each. The honest-risk section does not overclaim or understate.

**Finding 9-E (pass — power note):**
"Confirmation items (≥5, power-noted)" is an honest acknowledgment that 5 items is a minimum and statistical power at this sample size is modest. This is appropriate calibration — it does not claim the confirmation is definitive with 5 items.

---

## Strongest adversarial objection

**The `n_post≥5` window after P-mastery is a minimum observation count, not a minimum time window — and for human learners, counts can cluster in a single session.**

The R2 adversarial objection was about firing the outcome check too early, before transfer has manifested. The R3 fix requires `n_post≥5` held-out S attempts *after P is mastered*. This resolves the agent-learning case (where n_post observations occur across meaningful time gaps) but creates a residual problem in the human-learning case: a learner can complete 5 held-out S attempts in the same session as P-mastery, before any sleep-consolidation or spaced-practice effect has had time to operate. For skills where transfer requires consolidation (mathematical procedures, language grammar), a learner who masters P and then immediately attempts S 5 times may show no lift simply because the knowledge hasn't yet integrated — which would incorrectly trigger `g.decay_edges()` and suppress a valid causal path.

This is not fully addressed by `n_post≥5` alone. A stronger guard would be: `n_post≥5 held-out S attempts *AND* at least one session boundary (or a minimum elapsed time) between P-mastery and the S-lift check`. The spec does not address this temporal/session dimension. It is mitigated somewhat by B4's spacing scheduler (which would naturally spread the n_post observations over time), but B4 is a separate build and is not listed as a B2 dependency.

This objection is distinct from all nine dimension findings above and represents the remaining genuine limitation of the R3 spec for the human-learning use case.

---

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety)
              = min(90, 83, 88) = 83

weighted_mean   = (Correctness×2 + DesignFaithfulness + RedTeam×2
                   + Implementability + Safety×2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
              = (90×2 + 88 + 83×2 + 83 + 88×2 + 85 + 84 + 85 + 87) / 11
              = (180 + 88 + 166 + 83 + 176 + 85 + 84 + 85 + 87) / 11
              = 1034 / 11 = 94.0 => 94

overall         = min(83, 94) = 83
```

**Overall confidence: 83 / 100**

---

## Verdict

**ready-for-approval**

Overall score is 83 (≥80). No CRITICAL dimension is below 70 (Correctness 90, Red-team 83, Safety 88). The two R2 hard blockers (missing defaults + unquantified trigger) and the R2 adversarial objection (premature edge decay before transfer manifests) are all resolved. The aggregate is floored by Red-team resistance at 83, reflecting two moderate residual gaps that are real but not blocking:

**Residual gaps to track (not blocking, but recommended for a future revision pass):**

1. **RC-4 edge-confidence traversal filter (Finding 3-C):** Specify that B2 only walks edges whose current `confidence ≥ τ_traverse` (inheriting from `g.decay_edges()`'s existing confidence model). A prereq relationship the system has already learned is unreliable should not drive a diagnosis. This is a correctness improvement, not a correctness flaw — the confirmation step catches most bad diagnoses even on decayed edges.

2. **Post-redirect state record (Finding 4-D):** Specify a `redirect_log` entry (e.g., in `TruthStore` or a `Diagnose`-owned `StateStore` record) that tracks `{skill_S, prereq_P, mastery_confirmed_at, n_post_observations}` — the bookkeeping needed to implement the `n_post` window across sessions. Without naming the artifact, two developers will implement this tracking incompatibly.

3. **Session-boundary guard for human learning (Adversarial objection):** Consider whether `n_post≥5` alone is sufficient for human learning, or whether a minimum session boundary (or elapsed time) should be required between P-mastery and the S-lift check, to allow consolidation effects. This is a B4-adjacent concern that can be noted as a known limitation without blocking approval.
