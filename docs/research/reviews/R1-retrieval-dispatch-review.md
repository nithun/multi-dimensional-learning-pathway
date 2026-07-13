# 360 Review: R1-retrieval-dispatch — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` (R1 item, lines 263–311) |
| Proposed change | New build-spec: names the §16.4 store-dispatch API as five named retrieval "modes" and fully specifies the §16.5 fusion reranker's feature vector (`sim, struct, state_gap, rel, heat`), a mode-level EIG-driven dispatch step, a reference-validation guard, and a reliability-blind exploration floor `ε_ret` |
| Reviewer | review-360 |
| Date | 2026-07-13 |
| Round | 1 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 62 | weak |
| 2 | Design faithfulness | 66 | weak |
| 3 | Red-team resistance (CRITICAL) | 54 | weak/blocking |
| 4 | Implementability | 56 | weak |
| 5 | Safety / integrity (CRITICAL) | 68 | weak |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 55 | weak |
| 8 | Consistency | 54 | weak |
| 9 | Calibration / honesty | 55 | weak |

## Findings by dimension

### 1. Correctness

**Finding 1.1 — the mode-level "EIG estimate" is asserted, not derived (BUILD-SPECS.md:274).** Mechanism 1 states: "the mode itself is chosen per-`EXPAND` by the same rule applied at preset granularity (a mode's EIG estimate = the learned mean contribution of its store set)." This is the load-bearing formula of the whole mode-dispatch mechanism and it is not actually specified: no formula for "learned mean contribution" is given (mean of what — `rel`? realised per-episode lift? historical `EIG_Q`?), no variance/SE term, and no statement of the sampling unit (per mode, per query-type, per learner, global?). Contrast with §16.2–§16.3 (ALGORITHM-v0.2-pathway-learner.md:405–415), where `EIG_Q` is *exactly* defined as A1's closed-form Beta entropy reduction on the `Q` posterior — a quantity whose own uncertainty is baked into its derivation. Calling an undefined empirical average "the same rule" as a closed-form Bayesian quantity is a category error: the two are not computing the same kind of object, and the spec does not establish that the mean-contribution proxy inherits any of the statistical properties (falls with `n_eff`, near-flat at fixed `n_eff`, etc.) that A1 painstakingly proves for `EIG_cell` (BUILD-SPECS.md:24–33). This is not a sign error, but it is a genuine correctness gap in the spec's central novel claim — the "one algorithm, two levels" merge (§16.1) is silently being asked to support a *third*, ungrounded level.

**Finding 1.2 — the fusion score, `ε_ret`, and reference-validation guard are internally correct.** `score(source) = w·x(source)` over five z-scored features (BUILD-SPECS.md:275–284) is dimensionally sound (z-scoring keeps terms commensurable, per §16.3's mandatory z-scoring, ALGORITHM-v0.2-pathway-learner.md:408). `rel` as leave-one-out lift history (§5.2's `update_w`, ALGORITHM-v0.2-pathway-learner.md:154) is a correct re-application of the existing counterfactual-credit mechanism. The reference-validation guard (BUILD-SPECS.md:285) is a sound, cheap invariant. No arithmetic/formula errors found in these parts.

**Finding 1.3 — `w`'s indexing is silently redefined from §5.2's `w`.** §5.2 defines `update_w(ctx, r): for item ∈ ctx: w[item] += marginal_lift(item)` — `w` is indexed **per retrieved item** (ALGORITHM-v0.2-pathway-learner.md:154). R1's `w` is indexed **per feature** (5-dimensional: `sim, struct, state_gap, rel, heat`, BUILD-SPECS.md:275–277) — a different mathematical object bearing the same symbol. The Plug-point ("reranker weights `w` live beside §5.2's `update_w`", BUILD-SPECS.md:289) says "beside," implying the two `w`s coexist rather than one replacing the other, but never reconciles what that means operationally (does the per-item `w` still get computed and, if so, does it feed `rel`, or is it now dead code?). This is a real notational/consistency defect that a developer cannot resolve without guessing.

**Score rationale:** No proven-wrong formula, but the central new mechanism (mode dispatch) rests on an undefined statistic, and the `w` symbol collision is a genuine correctness/consistency defect. **62.**

### 2. Design faithfulness

**Finding 2.1 — §16.1 states exactly two selection problems; R1 introduces a third without amending §16.** §16.1 is explicit: "there are **two** selection problems: inner `π_Q` … outer `π_C`" and calls this "the honest form of 'one policy': **one** value-of-information rule dispatched at **two** cadences" (ALGORITHM-v0.2-pathway-learner.md:397–401). R1's mode dispatch ("the mode itself is chosen per-`EXPAND`", BUILD-SPECS.md:274) is a **third** selection problem — at preset granularity, above `π_Q` — that did not exist in §16.4's design (which only says inner `π_Q` "learns which store to call by measured contribution," ALGORITHM-v0.2-pathway-learner.md:418, with no notion of a named coarser-grained mode layer). R1's own framing text claims this "adds NO new objective, gate, or belief" (BUILD-SPECS.md:265) — that claim is not fully supportable given Finding 2.1; at minimum §16.1's "two selection problems" characterization is now stale and the build-spec should either say so explicitly or justify why the mode layer doesn't count as a third problem.

**Finding 2.2 — the five modes and fusion features are faithful, well-sourced adoptions.** The mode taxonomy (`skill-local / curriculum-global / episode-naive / hybrid / mix`) and the multi-signal fusion feature idea are correctly attributed to the LightRAG/RAG-Anything `QueryParam` pattern and OpenSpace's quality-weighted retrieval (STUDY-raganything-agentscope-openspace.md:27, 61, 85) — the provenance claim is accurate and appropriately labeled as "the statistics are ours" (BUILD-SPECS.md:265).

**Finding 2.3 — R1 does not close either advisory item the S16 gate commissioned it to close.** The S16 round-3 decision record explicitly directs: (1) "a 'New parameters' subsection for §16 listing `b_ret`, `K`, and `α_Q0/β_Q0` with defaults and ranges" and (2) "which clause of §8 the reranker weight gate uses (the generalization gate specifically…)" (S16-unified-retrieval-decision.md:27–30). R1's Parameters line reads only "`b_ret` (existing, §16.6)" with no default/unit/range, and never mentions `K` or `(α_Q0,β_Q0)` at all (BUILD-SPECS.md:292). R1's gating language ("gated like any learned weight (§8)", BUILD-SPECS.md:284) reproduces the *exact* ambiguous phrasing the S16 review flagged (S16-unified-retrieval-review-r3.md:57, 61) without pinning the clause. Since R1's own header calls itself "the §16 companion build-spec," this is a direct, evidenced failure to discharge the prior gate's own instructions — the strongest design-faithfulness-to-process finding.

**Score rationale:** Faithful adoption of external patterns and the fusion-feature concept; a real architectural addition (mode dispatch) not acknowledged as new; and a concrete failure to close both S16-commissioned advisory items. **66.**

### 3. Red-team resistance

**Finding 3.1 — `rel` itself is well-defended against RC-1/RC-7 (per the specific check requested).** `rel` is defined strictly as leave-one-out/counterfactual lift (never shared credit — BUILD-SPECS.md:282, citing §5.2), it is one z-scored feature among five (never a gate), and `ε_ret` forces reliability-blind sampling so a cold source can still earn evidence (BUILD-SPECS.md:286, mirroring the §5.3 coverage floor and A5's diversity mechanism). `test_rel_from_leave_one_out_only` and `test_rel_biases_never_excludes` (BUILD-SPECS.md:306–307) target exactly this. This part of the design does not reopen RC-1 or RC-7.

**Finding 3.2 — the mode-dispatch layer *does* reopen RC-1.** RC-1's patch requires "every gate becomes a test against its own standard error, not a scalar compare" (ALGORITHM-v0.1-redteam.md:39). The mode-selection rule ("a mode's EIG estimate = the learned mean contribution," BUILD-SPECS.md:274) is precisely the shape of the RC-1 pathology already named for LP: "LP = difference of small-sample Beta means is mostly noise" (ALGORITHM-v0.1-redteam.md:37) — here it is a mode-level mean with no stated SE, no `significant()` gate, and no `n_min`-style floor before it is allowed to steer which stores get queried. Unlike `EIG_Q`/`EIG_C`, whose uncertainty is intrinsic to the Beta-entropy derivation, "learned mean contribution" is a bare point estimate.

**Finding 3.3 — the mode-dispatch layer creates a new instance of RC-7 (starvation/filter-bubble) that no existing mechanism defends against.** RC-7's patch is "reachability-exploration… sample context by info-gain on unlocking unreachable regions" plus a coverage floor (ALGORITHM-v0.1-redteam.md:65). `ε_ret` (mechanism 4, BUILD-SPECS.md:286) provides this protection *within* an active mode's candidate set, but there is no analogous floor *across* modes: if `curriculum-global` (multi-hop, costlier, likely noisier at low `n_eff`) starts with a lower "learned mean contribution" than `skill-local`, nothing in R1 prevents it from being selected less and less until it stops accumulating the very evidence that could correct the estimate — the textbook RC-7 pattern applied one layer up from where the spec's other defenses (`ε_ret`, coverage floor, A5's diversity filter) already operate. The "Honest risks" section (BUILD-SPECS.md:294–298) lists "rich-get-richer via `rel`" (correctly defended) and "mode proliferation" (a closed-set concern, unrelated to starvation) but does **not** name mode-level starvation at all — this root cause is present in the mechanism and absent from the spec's own risk accounting.

**Finding 3.4 — no other RC (2, 3, 4, 5, 6, 8) is disturbed.** The commit gate, provisioning, decay, tree, and promotion machinery are untouched; RC-2 (format-correlation gaming) is explicitly re-acknowledged as a residual with the existing §8 generalization-gate mitigation (BUILD-SPECS.md:297).

**Score rationale:** `rel` (the specifically-flagged feature) is sound. The mode-dispatch mechanism — new in this build-spec — is an unmitigated, freshly-introduced instance of both RC-1 (ungated point-estimate comparison) and RC-7 (no cross-mode exploration floor). Per the rubric, a new instance of a named root cause with no mitigation scores well below the pass line. **54.**

### 4. Implementability

**Finding 4.1 — a developer cannot code the mode-selection rule as written.** "The learned mean contribution of its store set" (BUILD-SPECS.md:274) leaves undefined: the source statistic, the aggregation window, whether it is per-learner or global/pooled, and how a mode with no history bootstraps (no analogue of A5's flat-prior floor, BUILD-SPECS.md:73, is offered here). This is a strictly larger gap than the round-3 S16 findings about `b_ret`/`K` (which were *named but undefaulted* — S16-unified-retrieval-review-r3.md:63–67); here the formula itself does not exist.

**Finding 4.2 — the fusion vector, `ε_ret`, and reference-validation guard are cleanly implementable.** Plug-point (`mdlp/retrieval.py :: Retriever.retrieve`, BUILD-SPECS.md:289), feature list, and defaults (`ε_ret=0.1`, `d_ret=2`, feature-weight init uniform, BUILD-SPECS.md:292) give a developer everything needed for those parts.

**Finding 4.3 — `b_ret`, `K`, `(α_Q0,β_Q0)` remain without defaults despite being commissioned (see Finding 2.3).** A developer implementing "the §16 companion build-spec" specifically to close this gap still cannot find a default for any of the three.

**Score rationale:** Half the spec (fusion vector, guard, `ε_ret`) is cleanly buildable; the other half (mode dispatch, and the still-open S16 parameter defaults) is not. **56.**

### 5. Safety / integrity

**Finding 5.1 — no existing gate is weakened.** `w` updates remain cold-path, §8-gated (BUILD-SPECS.md:284); `retrieve` still produces no child/checkpoint; the §5.3 coverage floor for skill practice is unaffected (retrieval stays `C`-neutral, consistent with §16.7, ALGORITHM-v0.2-pathway-learner.md:436).

**Finding 5.2 — the reference-validation guard is a genuine safety-positive addition** (BUILD-SPECS.md:285), closing a dangling-reference/context-poisoning channel not previously named in §16, and directly modeled on AgentScope's hallucination-filter pattern (STUDY-raganything-agentscope-openspace.md:39, 97).

**Finding 5.3 — the un-gated mode-dispatch layer is an integrity gap, though not a hard-safety violation.** Because a systematically under-selected mode (e.g., `curriculum-global`) could mean structurally-relevant context (prereq/lineage) is silently withheld from certain query types with no gate ever firing — the same "harm accrues with no gate firing" pattern RC-7 names for skill practice (ALGORITHM-v0.1-redteam.md:64) — applied here to retrieval quality rather than competence safety. This does not touch the §8 `safe` clause or the calibration layer (§14) directly, so it is not scored as low as a hard safety violation, but it is a real, unaddressed erosion of the "every root cause gets an explicit floor" discipline the rest of the design (and R1 itself, via `ε_ret`) otherwise honors.

**Score rationale:** No hard gate weakened; one safety-positive addition; one un-mitigated integrity gap at the new mode-dispatch layer, just below the pass line. **68.**

### 6. Efficiency / cost

**Finding 6.1 — the fusion score is O(1) per candidate** (five scalar features, one dot product); no new O(n²) hot-path cost.

**Finding 6.2 — mode dispatch is coarse-grained (5 presets) and cheap** regardless of how its formula is eventually defined; even a naive per-mode running-mean lookup is O(1).

**Finding 6.3 — the reference-validation guard and `ε_ret` are both cheap, bounded overheads,** explicitly called out as such (BUILD-SPECS.md:285, 295).

**Finding 6.4 — `d_ret=2` bounds the graph-hop cost** for `struct`, consistent with §16.4's existing multi-hop bound.

**Score rationale:** No efficiency concerns identified anywhere in the spec. **85.**

### 7. Completeness

**Finding 7.1 — the single most novel mechanism (mode dispatch) has zero dedicated test.** Of the nine tests (BUILD-SPECS.md:301–309), `test_mode_presets_are_closed_set` only checks that an *unknown* mode is rejected — it does not test the selection *rule* (the "learned mean contribution" formula), its bootstrapping, or its exploration behavior across modes. No test exercises mode-level starvation, mode cold-start, or the mode-EIG formula's correctness (e.g., an `A1`-style `test_eig_falls_with_n_eff`-equivalent at the mode level is absent).

**Finding 7.2 — the two S16-commissioned advisory items are not closed** (Finding 2.3/4.3): no `K` default, no `(α_Q0,β_Q0)`, no `b_ret` default/unit, and no §8-clause pin for the reranker gate.

**Finding 7.3 — `rel`'s own maintenance is unspecified.** §5.2's `update_w` includes an explicit passive-decay term, `w ← w · (1 − l1_decay)` (ALGORITHM-v0.2-pathway-learner.md:155), so a source's influence ages out. R1 never states whether `rel` (built from the same leave-one-out lift history) inherits an equivalent decay, leaving open whether a source's reliability score can go stale under non-stationarity (the same concern RC-5/RC-6 raise for competence decay and the MCTS tree) with no analogous fix specified here.

**Finding 7.4 — the "Honest risks" section omits mode-level starvation** (Finding 3.3), despite naming the analogous `rel`-level risk carefully.

**Score rationale:** The fusion-vector half of the spec is complete; the mode-dispatch half and the carried-over S16 obligations are not. **55.**

### 8. Consistency

**Finding 8.1 — `w`-symbol collision with §5.2, unreconciled** (Finding 1.3): R1's per-feature `w` and §5.2's per-item `w` are described as coexisting ("live beside," BUILD-SPECS.md:289) without specifying how, whether the old per-item update still runs, or whether §5.2's `l1_decay` still applies to either.

**Finding 8.2 — tension between "mode chosen per-`EXPAND`" (dynamic) and "mode default (`mix`)" as a fixed ablation arm.** Mechanism 1 says the mode is dynamically selected every `EXPAND` by the mean-contribution rule (BUILD-SPECS.md:274), yet the Parameters line treats `mode` as a static default (`mix`, BUILD-SPECS.md:292) and `test_defaults_reduce_to_approved_16` requires holding "mode `mix`" fixed to reproduce §16 (BUILD-SPECS.md:309), while the ablation claim ("Mode-vs-`episode-naive` is the §16 build's measurable claim," BUILD-SPECS.md:274) implicitly requires holding `episode-naive` fixed for a clean baseline arm (`test_naive_arm_is_clean_baseline`, BUILD-SPECS.md:303). The spec never states how a dynamically-dispatched mode and a fixed-arm ablation study coexist in the same evaluation protocol — is dispatch disabled during the ablation, or does it run alongside it? This is left for the implementer to invent.

**Finding 8.3 — §12 vs. R1's own Parameters line.** §12 (ALGORITHM-v0.2-pathway-learner.md:286) already lists `b_ret`, `K`, `(α_Q0,β_Q0)` as §16 parameters to calibrate. R1, as the item responsible for making §16 "implementable," should restate these with concrete defaults (the way A1 gives `u_ref` default 0.15 alongside the existing §12 entry, BUILD-SPECS.md:41) but instead only references `b_ret` in passing and drops the other two — inconsistent with the spec's own established convention (Finding 2.3 detail).

**Finding 8.4 — `§16.1`'s "two selection problems" framing is now stale** given the mode layer (Finding 2.1) and R1 does not flag or reconcile this.

**Score rationale:** Multiple unreconciled internal tensions, concentrated in the parts of R1 that are genuinely new (mode dispatch, the fusion `w`). **54.**

### 9. Calibration / honesty

**Finding 9.1 — the header claim overstates certainty.** "Adds NO new objective, gate, or belief" (BUILD-SPECS.md:265) is defensible for the fusion feature vector (a concretization of an already-abstract §5.2/§16.5 mechanism) but not fully defensible for the mode-dispatch layer, which is a new decision function not present in §16.1's "two selection problems" account (Finding 2.1). The claim should be qualified, not stated flatly.

**Finding 9.2 — the risk section is calibrated for the well-defended parts and silent on the least-defended one.** "Honest risks" (BUILD-SPECS.md:294–298) carefully names and defends the `rel`/rich-get-richer risk and the format-gaming residual, but says nothing about mode-level starvation or the undefined mode-EIG formula (Finding 3.3, 7.4) — exactly the place where the spec's self-critique should be most active, since it is the least specified part of the design.

**Finding 9.3 — the S16-commissioned advisory items are neither closed nor acknowledged as still-open.** R1 presents itself as the completed companion build-spec without noting that two specific, named prior-review obligations (S16-unified-retrieval-decision.md:27–30) remain outstanding (Finding 2.3). Silence here reads as more complete than the artifact actually is.

**Score rationale:** No dishonest claim about a proven result, but a pattern of confident framing ("adds NO new..,", "the §16 companion build-spec") in exactly the areas that are least rigorously specified. **55.**

## Strongest adversarial objection

**The mode-dispatch mechanism is the spec's one genuinely new idea, and it is also its least statistically disciplined part — reintroducing, in a brand-new location, the exact two failure patterns (RC-1, RC-7) that every other layer of this fifteen-section design was hardened specifically to prevent.** Every other selection rule in the algorithm — `π_C` (§5.3/§13.1), `π_Q` (§16.3), the coverage floor (§5.3), A5's warm-start weighting (BUILD-SPECS.md:67), B1's misconception lift gate (BUILD-SPECS.md:154) — either computes a closed-form, uncertainty-aware quantity or explicitly tests a difference against its standard error before acting on it, and every one of them pairs that decision with an explicit floor/exploration mechanism to prevent starvation. R1's mode dispatch does neither: "a mode's EIG estimate = the learned mean contribution of its store set" (BUILD-SPECS.md:274) is a bare point estimate with no SE, no `n_min`-style floor, and no cross-mode analogue of `ε_ret`. If this is implemented literally as written, a mode that looks weak on a handful of early, noisy episodes can be starved of the very traffic that would let it recover — while every one of the nine listed tests (BUILD-SPECS.md:301–309) checks something else. The spec's own "Honest risks" section, which is otherwise careful and specific, does not mention this at all. This is the strongest objection because it is not a hypothetical: it is the identical shape of harm the red-team report already diagnosed twice (RC-1 for LP, RC-7 for curricula), reintroduced by the one new mechanism this build-spec adds, in a build-spec whose entire purpose is described as making an already-approved, carefully-hardened design "implementable."

## Aggregate confidence

```
critical_floor  = min(Correctness=62, RedTeam=54, Safety=68) = 54
weighted_mean   = (62×2 + 66 + 54×2 + 56 + 68×2 + 85 + 55 + 54 + 55) / 11
              = (124 + 66 + 108 + 56 + 136 + 85 + 55 + 54 + 55) / 11
              = 739 / 11
              = 67.2
overall         = min(54, 67.2) = 54
```

**Overall confidence: 54 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to clear the 70 CRITICAL floor on all three critical dimensions):

1. **Define the mode-level dispatch rule with the same rigor as `EIG_Q`/`EIG_C`.** Replace "the learned mean contribution of its store set" (BUILD-SPECS.md:274) with an explicit formula: the statistic being averaged, the window/sample unit, an SE or `n_min`-style floor before it is allowed to rank modes, and a stated cold-start behavior for a mode with no history (an A5-style flat-prior floor is the obvious template).
2. **Add a cross-mode exploration floor** analogous to `ε_ret` (which only operates within a mode's candidate set) so a mode cannot be starved of traffic by a noisy early estimate — the direct RC-7 fix this layer currently lacks.
3. **Close both S16-commissioned advisory items explicitly in R1's own Parameters section:** state a default/unit for `b_ret`, a default for `K`, a value for `(α_Q0,β_Q0)`, and pin the reranker-weight gate to the specific §8 sub-clause (generalization gate) rather than repeating "gated like any learned weight (§8)."
4. **Reconcile the `w` symbol** between §5.2's per-item rerank weight and R1's per-feature fusion weight — state explicitly whether one replaces the other, and whether §5.2's `l1_decay` (or an equivalent) still applies to `rel`'s own staleness.
5. **Resolve the dynamic-dispatch vs. fixed-ablation-arm tension** (Finding 8.2): state whether mode dispatch is disabled/fixed during the `mode`-vs-`episode-naive` measurable-claim evaluation, and update the "two selection problems" language in §16.1 (or explicitly justify why the new mode layer doesn't count as a third) so the design document and the build-spec no longer disagree on how many selection problems exist.
6. **Add at least one test targeting the mode-dispatch mechanism itself** (its formula, its cold-start behavior, and its resistance to starvation) — none of the nine current tests (BUILD-SPECS.md:301–309) exercise it.
