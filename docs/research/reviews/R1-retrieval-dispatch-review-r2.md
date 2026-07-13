# 360 Review: R1-retrieval-dispatch (round 2) — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` R1 item (lines 281–342) |
| Proposed change | Revision of the §16 companion build-spec — replaces the round-1 undefined "mode's EIG estimate = learned mean contribution" with a Normal(μ,SE) Thompson-sampled mode posterior + `ε_mode` cross-mode floor + `n_min_mode` cold start; renames the fusion weight `w`→`v`; closes both S16-commissioned Parameters advisories explicitly; resolves the dynamic-dispatch/ablation-arm tension; adds two mode-dispatch tests |
| Reviewer | review-360 |
| Date | 2026-07-13 |
| Round | 2 (round-1 score: 54, `reviews/R1-retrieval-dispatch-review.md`) |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"` (`recent_outcomes` include `effective:EV-1-review-360-2026-07-02-audit`). Filing as a full review report, not a proposal.

## Round-1 blocker resolution scorecard

| # | Round-1 blocking change required | Resolved? |
|---|---|---|
| 1 | Define mode-level dispatch rule with `EIG_Q`/`EIG_C` rigor (statistic, sample unit, SE/`n_min` floor, cold start) | **Mostly** — `N(μ_m,SE_m)` posterior over realized per-pull lift/pulls-taken, Thompson-sampled, `n_min_mode=10` stated (BUILD-SPECS.md:293). Residual: no closed-form/numeric formula, and the "flat optimistic cold-start prior" has no stated `(μ0,SE0)` values (unlike A5's explicit `Beta(α0+n_eff_warm·μ_knn,…)`) |
| 2 | Add a cross-mode exploration floor (`ε_ret`-analog) | **Mostly** — `ε_mode=0.05` added with a default (BUILD-SPECS.md:293, 318). Residual: the *enforcement mechanism* for the "hard floor" is unspecified — see Correctness/Red-team finding 1 below |
| 3 | Close both S16-commissioned advisory items with defaults + a pinned §8 clause | **Yes** — `b_ret=8`, `K=3`, `(α_Q0,β_Q0)=(1,1)`, `v`-gate pinned to the §8 generalization sub-clause, all stated explicitly (BUILD-SPECS.md:314–317) |
| 4 | Reconcile the `w` symbol between §5.2's per-item weight and R1's per-feature fusion weight | **Partially** — renamed to `v` in the Mechanism section with an explicit `rel = w[item]` division of labour (BUILD-SPECS.md:296, 303, 305) and a dedicated test (`test_rel_is_w_item`, :335). **Not swept through the whole spec**: the Plug-point still reads "reranker weights `w` live beside §5.2's `update_w`" (BUILD-SPECS.md:310) — the exact naming collision this blocker existed to close, left unfixed in one place |
| 5 | Resolve dynamic-dispatch vs. fixed-ablation-arm tension; reconcile "two selection problems" | **Mostly** — frozen arm configurations stated explicitly (BUILD-SPECS.md:295), and an explicit argument that mode dispatch is "not a third selection problem" is given (BUILD-SPECS.md:294) rather than amending §16.1. The argument is asserted, not incontrovertible — see adversarial pass |
| 6 | Add at least one test targeting mode dispatch (formula, cold-start, starvation resistance) | **Yes** — `test_mode_dispatch_thompson_with_floors` and `test_mode_dispatch_collapses_under_mix` added (BUILD-SPECS.md:329–330). Residual: no test analogous to `test_eig_falls_with_n_eff` for the mode-level statistic itself, and no test for the (unstated) cold-start prior values |

**Net: 2 of 6 cleanly resolved (3, 6), 4 more genuinely narrowed with a residual gap each (1, 2, 4, 5).** This is real, substantial progress (54 → below) but not yet a clean sweep — most importantly, blocker 4's exact defect (the `w`/`v` collision) still has one literal unfixed instance in the artifact.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 76 | pass |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 78 | pass |
| 4 | Implementability | 74 | pass |
| 5 | Safety / integrity (CRITICAL) | 84 | pass |
| 6 | Efficiency / cost | 86 | pass |
| 7 | Completeness | 75 | pass |
| 8 | Consistency | 66 | weak |
| 9 | Calibration / honesty | 68 | weak |

## Findings by dimension

### 1. Correctness

**Finding 1.1 — the mode-posterior formula is now well-defined in prose but not in closed form, and the cold-start prior has no numbers.** BUILD-SPECS.md:293: "Each mode `m` keeps a posterior `N(μ_m, SE_m)` over its realized per-pull contribution: the sample unit is one episode's leave-one-out lift attributable to `m`'s pulls … divided by pulls taken, over a sliding window `W_m`." Read literally: for each episode `e` in which mode `m` was dispatched, one sample `x_e = lift_e(m) / pulls_e(m)`; `μ_m, SE_m` are the sample mean/SE of `{x_e}` over the last `W_m=50` episodes. This is a legitimate, implementable statistic (no sign error, no category error — unlike round-1's conflation of an undefined "mean contribution" with `EIG`), and Normal-Thompson-sampling over a sample mean/SE is a standard, well-understood technique consistent with §5.3's `Q̃ = thompson(value_posterior(n,a))` pattern (ALGORITHM-v0.2-pathway-learner.md:164). However, the exact formula for `μ_m`/`SE_m` (sample mean / sample-SD-over-√n) is never written out — it is described, not specified, unlike `EIG_cell`'s literal closed form (BUILD-SPECS.md:24–30). And the "flat optimistic cold-start prior (the A5 template)" (BUILD-SPECS.md:293) names an analogy but gives no `(μ0, SE0)` numbers the way A5 gives explicit `Beta(α0+n_eff_warm·μ_knn, β0+n_eff_warm·(1−μ_knn))` (BUILD-SPECS.md:71). A developer can build the window/Thompson machinery but must invent the cold-start prior's numeric shape.

**Finding 1.2 — the `ε_mode` "hard floor" enforcement mechanism is unspecified, which matters for its literal claim.** BUILD-SPECS.md:293 states "every mode receives ≥ `ε_mode` of dispatches per window regardless of its posterior" — a hard, per-window guarantee. Elsewhere in this same spec, `ε_ret` is described as "an `ε_ret` fraction of pulls samples reliability-blind" (BUILD-SPECS.md:307) — phrasing consistent with a *per-decision probabilistic mixture* (with probability `ε`, ignore the posterior), which only guarantees the fraction *in expectation*, not with certainty in any given finite window. If `ε_mode` is implemented the same way (a per-`EXPAND` coin flip), a finite `W_m`-sized window can, by chance, fall short of `≥ε_mode·W_m` dispatches for an unlucky mode — a probabilistic mixture cannot literally guarantee a lower bound, only a deterministic quota mechanism can (the pattern the design already uses elsewhere: `enforce_coverage_floor(cands)` in §5.3, ALGORITHM-v0.2-pathway-learner.md:161, is a deterministic admission rule, not a coin flip). `test_mode_dispatch_thompson_with_floors` (BUILD-SPECS.md:329) asserts the mode "still receives ≥ `ε_mode` of dispatches per window" as if this were a hard invariant — but the spec text doesn't say whether the underlying mechanism is the deterministic-quota kind (which could actually satisfy that test reliably) or the stochastic-mixture kind (which could not, for an adversarially/unluckily-drawn window). This is a genuine, checkable gap between what is claimed ("hard … floor") and what is specified (an unnamed mechanism).

**Finding 1.3 — the `v`/`w` rename is not fully swept.** The Mechanism section correctly renames the 5-scalar fusion weight to `v` and reconciles it with §5.2's per-item `w[item]` (BUILD-SPECS.md:296, 303, 305; test `test_rel_is_w_item`, :335). But the Plug-point still reads: *"reranker weights `w` live beside §5.2's `update_w`"* (BUILD-SPECS.md:310) — this is the exact symbol collision round-1 Finding 1.3/8.1 flagged as blocking, left as a literal, uncorrected instance in the one place a developer reads last before opening the file to build. Minor to fix, but it means the round-1 defect is not *fully* closed — see the resolution scorecard, blocker 4.

**Score rationale:** No proven-wrong formula (an improvement over round 1's category error); one implementability-adjacent formula gap (cold-start numbers), one genuine mechanism-vs-claim gap (`ε_mode`'s hard-floor guarantee), and one un-swept naming leftover. **76.**

### 2. Design faithfulness

**Finding 2.1 — the "not a third selection problem" argument is asserted, not proven, and is not formalized as an amendment to §16.1.** BUILD-SPECS.md:294: "mode-then-pull is a hierarchical decomposition of the single inner `π_Q` decision — one value-of-information rule applied at two granularities … collapsing to flat `π_Q` over the union when `mix` is dispatched." The collapse-under-`mix` claim is true by construction (`mix`'s candidate set is defined as the union of all stores, BUILD-SPECS.md:291, so restricting `π_Q` to "mix's candidates" is definitionally unrestricted `π_Q` — `test_mode_dispatch_collapses_under_mix`, :330, verifies an implementation detail, not a live risk). But the broader claim — that a `N(μ_m,SE_m)`-over-realized-episode-lift bandit layered above `π_Q`'s live `EIG_Q` posterior is "the same decision" rather than a second, distinct estimator — is a rhetorical framing more than a proof: it has its own sampling unit (episode, not pull), its own evidence source (realized post-hoc lift, not a live Beta belief), and its own floors (`n_min_mode`, `ε_mode`) that exist nowhere else in `π_Q`. This is a genuinely defensible design choice, but note that the project's own convention for architecturally-significant additions to an approved section is a formal, separately-reviewed amendment — see B2's "Amendment A" (BUILD-SPECS.md:213, itself `▢ IN GATE (round 2)`). R1 folds an analogous addition into a companion build-spec's prose instead of that track. See also the adversarial pass.

**Finding 2.2 — `struct` now depends on a schema (`part_of` edges, edge `confidence`) defined only by an *unapproved* sibling artifact.** BUILD-SPECS.md:301: "`struct` — … path-weight … over prereq/`part_of` edges, computed from edge `confidence`." `part_of` edges and the `weight`/`confidence` field split are introduced by B2's Amendment A (BUILD-SPECS.md:217–221), which is **itself** `▢ IN GATE (round 2)` and scored **62/100, needs-revision**, with both CRITICAL dimensions (Correctness 66, Red-team 62) below 70 (`reviews/B2-amendA-typed-edges-review-r2.md`). R1 does not flag this cross-gate dependency anywhere (contrast `DATA-LAYER.md:138`, which explicitly annotates its own `part_of` schema line as *"schema delta gated under B2 Amendment A, BUILD-SPECS"* — R1 makes no equivalent note). Concretely: B2-amendA-r2's own Correctness finding 1 says the `weight` field's claimed role ("the §5.2 reachability input") is **not actually implemented** by `reach_weight` (ALGORITHM-v0.2-pathway-learner.md:145 takes no `weight` argument) — so R1's `struct` feature is built on a schema whose sibling reviewer has already found internally inconsistent. If Amendment A's round-3 fix changes `confidence`'s semantics (e.g., per that review's recommendation to have `confidence` floor candidacy, not just order it), `struct`'s definition here would need re-verification that this review has no way to perform. This is a real, evidenced, previously-unflagged design-faithfulness/process risk.

**Score rationale:** Faithful closure of the two S16 advisories and a reasonable (if asserted) resolution of the ablation-arm tension; docked for the unformalized "third selection problem" argument and the unacknowledged dependency on an unapproved, currently-failing sibling artifact. **80.**

### 3. Red-team resistance

**Finding 3.1 — RC-1/RC-7 at the mode-dispatch layer are substantively closed by Thompson-over-Normal-posterior + two floors.** This directly answers round-1 Finding 3.2/3.3: a bare point-estimate comparison is gone (Thompson sampling over an explicit posterior, mirroring the pattern already used at §5.3's `choose()`), and the `n_min_mode`/`ε_mode` floors are the RC-7 anti-starvation analogue `ε_ret` already provides within a mode (BUILD-SPECS.md:293). `test_mode_dispatch_thompson_with_floors` (:329) targets exactly this. This is a genuine, structural fix, not a cosmetic one.

**Finding 3.2 — but the `ε_mode` floor's *hard-guarantee* claim (Correctness finding 1.2) is itself a red-team-relevant gap.** If `ε_mode` is implemented as a per-decision probabilistic mixture (as `ε_ret`'s phrasing suggests, BUILD-SPECS.md:307) rather than a deterministic per-window quota (as `enforce_coverage_floor` is, ALGORITHM-v0.2-pathway-learner.md:161), the claimed "hard … floor regardless of its posterior" is not actually hard — a bad-luck run could still under-serve a mode within any given window, i.e., a weaker, residual instance of the exact RC-7 starvation pattern this mechanism exists to close. This does not fully re-open RC-7 (the floor still exists in expectation, and Thompson sampling itself provides substantial protection independent of the floor), so it does not score below 70, but it is a genuine, evidenced gap between the design's own stated guarantee and what is actually specified.

**Finding 3.3 — no other RC is newly disturbed.** RC-2 (format-correlation gaming) mitigation is unchanged and still cited (BUILD-SPECS.md:324); `rel`'s RC-1/RC-7 defenses (leave-one-out credit, `ε_ret`) are unchanged and still hold (BUILD-SPECS.md:303, 307, tests :335–337).

**Score rationale:** The central round-1 red-team defect (an ungated, unfloored mode-selection point estimate) is genuinely closed; one residual gap (the floor's enforcement mechanism) keeps this from a higher score. **78.**

### 4. Implementability

**Finding 4.1 — the fusion vector, guard, `ε_ret`, and the two closed S16 advisories are cleanly buildable** (BUILD-SPECS.md:296–307, 314–317) — unchanged from round 1's assessment of this half of the spec.

**Finding 4.2 — a developer still cannot code the mode-dispatch cold start or the exact `μ_m`/`SE_m` update rule without inventing details.** No numeric `(μ0, SE0)` for the "flat optimistic cold-start prior" (Finding 1.1); no stated update rule for `μ_m`/`SE_m` (sample mean/SD over the window vs. an exponentially-weighted running estimate — both are plausible readings of "sliding window `W_m`" and they behave differently near the window boundary).

**Finding 4.3 — the `ε_mode` enforcement mechanism is unspecified** (Finding 1.2/3.2) — a developer must choose between a deterministic quota scheme and a stochastic mixture, and the choice changes whether `test_mode_dispatch_thompson_with_floors`'s literal assertion (`≥ ε_mode` **always**) can even be satisfied.

**Score rationale:** More than half the spec (fusion vector, guard, `ε_ret`, Parameters closure) is cleanly implementable; the mode-dispatch half still leaves two concrete, non-trivial decisions to the implementer. Improved substantially from round 1's 56 (where the mode formula did not exist at all) but not yet fully specified. **74.**

### 5. Safety / integrity

**Finding 5.1 — no existing gate is weakened; the round-1 integrity gap (an un-floored mode-dispatch layer) is closed.** The `n_min_mode`/`ε_mode` floors directly answer round-1 Finding 5.3 (the RC-7-shaped "harm accrues with no gate firing" pattern at the mode-dispatch layer) — a mode can no longer be silently starved by construction (modulo Finding 3.2's residual on the floor's hardness).

**Finding 5.2 — the `v`-update gate pin (generalization sub-clause only, not the full four-clause commit gate) is exactly what the S16 decision record asked for, and was already scrutinized and accepted at the design level.** `S16-unified-retrieval-review-r3.md:61` already reasoned through this exact question ("the applicable gate is most likely the generalization gate … not the full four-clause gate") and accepted it (S16 round 3 scored Safety 86/100), noting `l1_decay`'s passive decay as an independent safety net against a rogue reranker weight. R1 pinning this explicitly (BUILD-SPECS.md:305, 317) is a correct, faithful implementation of an already-approved design decision, not a new weakening introduced by R1. Reviewed here for completeness since a fresh round-2 review should not assume inherited soundness, but no new safety defect found in this specific item.

**Finding 5.3 — the reference-validation guard remains a genuine safety-positive, unchanged from round 1** (BUILD-SPECS.md:306).

**Score rationale:** The one round-1 integrity gap in this dimension is closed; nothing new found that weakens a gate, §14, or the verifier. **84.**

### 6. Efficiency / cost

**Finding 6.1 — the added mode-dispatch bookkeeping is negligible.** Five Normal posteriors (one per mode), each backed by a `W_m=50`-episode sliding window (≤250 floats total) and a Thompson draw per `EXPAND` — O(1) relative to the existing per-pull fusion score and retrieve budget. No new O(n²) term introduced anywhere.

**Finding 6.2 — no new LLM/verifier calls.** The mode-posterior signal reuses the existing §16.5 cold-path realized outcome (BUILD-SPECS.md:293) — same accounting as round 1's assessment.

**Score rationale:** No efficiency concerns identified; consistent with (marginally better than) round 1's 85. **86.**

### 7. Completeness

**Finding 7.1 — two new tests target mode dispatch, but no test covers the mode-level statistic's own correctness properties.** `test_mode_dispatch_thompson_with_floors` and `test_mode_dispatch_collapses_under_mix` (BUILD-SPECS.md:329–330) are a genuine improvement over round 1's zero coverage. But there is still no analogue of A1's `test_eig_falls_with_n_eff` (BUILD-SPECS.md:51) at the mode level — e.g., a test that `SE_m` shrinks as more episodes accumulate in `W_m`, or that the cold-start prior is actually "optimistic" in some checkable numeric sense. Given Finding 1.1/4.2 (the cold-start prior has no stated numbers), such a test could not currently be written precisely — the missing specification and the missing test are the same gap viewed from two sides.

**Finding 7.2 — the Parameters line's own claim ("All registered in §12," BUILD-SPECS.md:318) is not accurate against the current text of `ALGORITHM-v0.2-pathway-learner.md`.** §12's "Added-section parameters (extend §12)" line (ALGORITHM-v0.2-pathway-learner.md:286) lists, for §16, only `b_ret`, `K`, `(α_Q0,β_Q0)` — the three items the S16 decision already commissioned. It does **not** list `ε_mode`, `n_min_mode`, `W_m`, `ε_ret`, `d_ret`, per-store `k`, or `v` init — all newly introduced or newly defaulted by R1 (BUILD-SPECS.md:318). "All registered in §12" is a specific, checkable factual claim, and as of this document's current state it is false; none of the other approved build-specs (A1, A5, B4, B1, B2, B3) makes an equivalent blanket claim about their own new parameters, so this is a new, avoidable overclaim rather than an established convention.

**Finding 7.3 — `rel`'s staleness (round-1 Finding 7.3) is now closed.** `rel = w[item]` inherits `l1_decay` explicitly (BUILD-SPECS.md:303), with a dedicated test (`test_rel_is_w_item`, :335).

**Finding 7.4 — the mode-level starvation risk (round-1 Finding 7.4) is now named in "Honest risks"** (BUILD-SPECS.md:322), closing that gap. No honest-risk statement exists, however, for the floor-enforcement-hardness question (Finding 1.2/3.2) or for the time-to-recover for a persistently floor-reliant mode (at `ε_mode=0.05`, filling a `W_m=50`-episode window purely from floor-guaranteed dispatches takes on the order of 1,000 `EXPAND`s in the worst case — a slow-but-bounded property that is not itself wrong, but is not acknowledged anywhere).

**Score rationale:** Real, targeted new test coverage and closure of the `rel`-decay and mode-starvation-risk gaps; docked for the still-unspecified cold-start numbers (and the test that would exercise them) and the inaccurate "All registered in §12" claim. **75.**

### 8. Consistency

**Finding 8.1 — the `w`/`v` Plug-point leftover (Finding 1.3) is a direct, unreconciled internal inconsistency** between the Mechanism section's explicit rename and the Plug-point's literal text (BUILD-SPECS.md:296 vs. :310).

**Finding 8.2 — the "All registered in §12" claim (Finding 7.2) is a direct inconsistency between R1's own Parameters section and the current text of the algorithm document it claims to register against** (BUILD-SPECS.md:318 vs. ALGORITHM-v0.2-pathway-learner.md:286).

**Finding 8.3 — the unacknowledged cross-gate dependency on B2 Amendment A** (Design faithfulness finding 2.2) is also a consistency defect in the narrow sense that R1 presents its `struct` feature definition (BUILD-SPECS.md:301) as settled when the schema it depends on is explicitly marked provisional one file over (`DATA-LAYER.md:138`).

**Finding 8.4 — the previously-flagged tensions (dynamic-dispatch/ablation-arm, "two selection problems") are now reconciled at the level of stated intent** (BUILD-SPECS.md:294–295), a genuine improvement over round 1's Finding 8.2/8.4.

**Score rationale:** The two major round-1 tensions are resolved; three new/residual concrete inconsistencies (an un-swept symbol, a false claim about §12, and an unflagged dependency on a currently-failing sibling artifact) keep this in the weak band. **66.**

### 9. Calibration / honesty

**Finding 9.1 — the header's "Adds NO new objective, gate, or belief" claim (round-1 Finding 9.1) is still asserted flatly and is harder to defend now than in round 1.** BUILD-SPECS.md:283 is unchanged text. Round 1 flagged this as not fully defensible given the mode-dispatch layer's existence; round 2 gives that layer an explicit new posterior object, `N(μ_m,SE_m)` — this is, on its face, a new *belief* (a mode-level estimate of realized contribution) that did not exist in the approved §16 design at all. R1's own Mechanism text argues this is "not a third selection problem" (BUILD-SPECS.md:294), but that argument is about *decision problems*, not about whether a new *belief object* was introduced — and the header's claim is specifically about beliefs ("no new … belief"). The header was not one of round 1's six numbered blockers, so its being unchanged does not constitute an unresolved blocker — but it remains a genuine, evidenced overclaim in a fresh full review.

**Finding 9.2 — "All registered in §12" (Finding 7.2/8.2) is a confidently-stated claim that is checkably false**, in the same pattern round 2 of the sibling B2 Amendment A review flagged as worse than leaving a gap open ("Confidently resolving a flagged ambiguity with an incorrect grounding is worse, calibration-wise, than leaving the ambiguity open," `reviews/B2-amendA-typed-edges-review-r2.md:103`).

**Finding 9.3 — the "Honest risks" section is now honest about mode starvation but silent on the floor-hardness question** (Finding 1.2) — the section states the starvation risk is "closed by … the hard `ε_mode` floor" (BUILD-SPECS.md:322) without acknowledging that "hard" is an unverified property of an unnamed enforcement mechanism.

**Score rationale:** No claim about a proven result is false, but three separate instances of confident language exceeding what is actually specified or true — the same pattern this project's own reviewers have flagged as a distinct failure mode from an honestly-acknowledged gap. **68.**

## Strongest adversarial objection

**R1 presents itself as a complete, self-contained companion spec — but its `struct` feature is built directly on the schema of a sibling artifact (B2's Amendment A) that is simultaneously in-gate and currently *failing* its own round-2 review at 62/100, with both CRITICAL dimensions below 70.** BUILD-SPECS.md:301 defines `struct` as "path-weight … over prereq/`part_of` edges, computed from edge `confidence`." Both `part_of` edges and the specific `weight`/`confidence` field split are constructs of B2's Amendment A (BUILD-SPECS.md:217–221), not of the base, already-approved B2 or of any §1–§16 mechanism. `reviews/B2-amendA-typed-edges-review-r2.md` — filed the same day as this round of R1 — found that Amendment A's own claim about what `weight` means is factually inconsistent with `ALGORITHM-v0.2-pathway-learner.md:145`'s actual `reach_weight` formula, and that its round-3 fix may need to change `confidence`'s role (e.g., whether it should floor candidacy, not just order it — that review's recommendation 5). If Amendment A's semantics shift under revision, R1's `struct` feature — a z-scored input to `score(source)`, one of the five terms gating what context reaches the learner (BUILD-SPECS.md:296–298) — inherits that instability without any mechanism in either document to catch it. Neither BUILD-SPECS.md nor `DATA-LAYER.md`'s R1-adjacent text flags this; only `DATA-LAYER.md:138`'s own schema line (for the *other* artifact) is annotated as provisional. Because change-approver gates items individually, R1 could clear its own bar this round while resting on ground its sibling review just found unstable — a dependency that is invisible to anyone reading R1 in isolation, which is exactly how R1 presents itself ("Adds NO new objective, gate, or belief," BUILD-SPECS.md:283). This is not raised in any of the nine dimension findings above in this exact cross-artifact form (Design faithfulness 2.2 and Consistency 8.3 each touch one half of it) — the compound risk (an unstable foundation, invisibly inherited, in a spec that claims completeness) is the adversarial case.

## Aggregate confidence

```
critical_floor  = min(Correctness=76, RedTeam=78, Safety=84) = 76
weighted_mean   = (76×2 + 80 + 78×2 + 74 + 84×2 + 86 + 75 + 66 + 68) / 11
              = (152 + 80 + 156 + 74 + 168 + 86 + 75 + 66 + 68) / 11
              = 925 / 11
              = 84.09
overall         = min(76, 84.09) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

Round 2 made real, substantive progress (54 → 76) and cleanly closed 2 of the 6 round-1 blockers with 4 more genuinely narrowed (see resolution scorecard). It does not clear the ≥80 bar. Blocking changes required to clear 80:

1. **Finish the `w`→`v` sweep.** Fix the Plug-point (BUILD-SPECS.md:310, "reranker weights `w` live beside §5.2's `update_w`") to read `v`, and re-check the rest of the document for any other un-renamed instance.
2. **Specify the `ε_mode` floor's enforcement mechanism concretely** (a deterministic per-window quota, mirroring `enforce_coverage_floor`, vs. a per-decision probabilistic mixture like `ε_ret`), so the "hard … floor regardless of its posterior" claim (BUILD-SPECS.md:293) and `test_mode_dispatch_thompson_with_floors`'s literal `≥ ε_mode` assertion (:329) are actually satisfiable as stated.
3. **Give the mode-dispatch cold-start prior concrete numbers** (an explicit `(μ0, SE0)` or equivalent, the way A5 gives `Beta(α0+n_eff_warm·μ_knn, …)`), and state the exact `μ_m`/`SE_m` update rule (windowed sample mean/SD vs. an exponentially-weighted running estimate).
4. **Correct or remove the "All registered in §12" claim** (BUILD-SPECS.md:318) — as of `ALGORITHM-v0.2-pathway-learner.md:286`, §12 lists only `b_ret`/`K`/`(α_Q0,β_Q0)` for §16; `ε_mode`, `n_min_mode`, `W_m`, `ε_ret`, `d_ret`, per-store `k`, and `v`'s init are not there. Either state this as a pending §12 amendment or drop the claim.
5. **Flag the cross-gate dependency on B2's Amendment A explicitly** (the `struct` feature's reliance on `part_of`/`confidence`, currently defined only by an amendment scored 62/100 needs-revision) — at minimum note it the way `DATA-LAYER.md:138` does for its own schema line, and revisit `struct`'s definition once Amendment A's round-3 outcome is known.
6. **Soften the header's "Adds NO new objective, gate, or belief" claim** (BUILD-SPECS.md:283) to acknowledge the new `N(μ_m,SE_m)` mode-level posterior as a genuinely new belief object, even while arguing (as the Mechanism section does) that it does not constitute a new *selection problem*.
