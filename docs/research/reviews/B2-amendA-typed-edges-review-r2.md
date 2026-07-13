# 360 Review: B2-amendA-typed-edges (round 2) — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md:213-243` (Amendment A to the approved B2, round 2 — "typed hierarchy edges + derived traversal order") |
| Proposed change | Adds `part_of` (composite→constituent) edges alongside `prereq`, an additive-z-score-derived traversal/confirmation-priority order, and a bounded `hard`-flag tie-break — this round removes the round-1 type-precedence short-circuit, defines the `Edge` schema (mirrored into `DATA-LAYER.md:138`), resolves the `weight`/`confidence` naming collision, scopes acyclicity over the edge-type union with an author-time check, bounds the `hard` tie-break by `δ_hard`, and adds an "Honest risks" subsection |
| Reviewer | review-360 |
| Date | 2026-07-13 |

Scope note: this is a **fresh** re-review of Amendment A only (BUILD-SPECS.md:213-243), against its round-1 review (`docs/research/reviews/B2-amendA-typed-edges-review.md`, overall 55, 7 blockers). The already-approved B2 base (BUILD-SPECS.md:182-211) and its decision record (`B2-prereq-gap-decision.md`) are fixed context; findings on the base itself are out of scope except where Amendment A's changes newly interact with them.

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Filing as a full review report (not a proposal).

## Round-1 blocker resolution scorecard

| # | Round-1 blocking change required | Resolved? |
|---|---|---|
| 1 | Remove type-precedence short-circuit; collect both types; test the co-occurring-gap case | **Partially** — candidacy fixed (BUILD-SPECS.md:222); the *confirmation*-stage half of the same risk is not (see Correctness/Red-team below) |
| 2 | Specify `GraphStore` interface delta + `Edge` schema | **Partially** — `Edge` schema now explicit (BUILD-SPECS.md:218-219) and `DATA-LAYER.md:138` updated; the `GraphStore` **port method** to read `part_of` edges was never added (`DATA-LAYER.md:69-74` still only exposes `prereqs()`), and no Plug-point subsection was added to the amendment |
| 3 | Reconcile the `weight` naming collision | **Attempted, but the resolution asserts a fact that isn't true** — see Correctness finding 1 |
| 4 | Define acyclicity scope + author-time check | **Mostly** — union scope and "checked at insertion, authored edges not exempt" are now stated (BUILD-SPECS.md:228); the concrete mechanism/interface is still not named |
| 5 | Normalize the traversal formula, pin down `z(...)` | **Yes** — additive frontier z-scores, both terms disambiguated (BUILD-SPECS.md:223-227) |
| 6 | Bound the `hard` tie-break tolerance | **Yes** — `δ_hard=0.1` z-units, defaulted, tested (BUILD-SPECS.md:229-230, :242) |
| 7 | Add an "Honest risks" subsection | **Yes** — BUILD-SPECS.md:231-234 |

Net: 3 of 7 cleanly resolved (5, 6, 7), 3 partially resolved with a residual gap each (1, 2, 4), 1 resolved-in-form-but-factually-flawed (3). This is genuine, substantial progress over round 1 — but two of the partial resolutions (1 and 3) reopen adjacent versions of the exact problems they were meant to close.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 66 | weak |
| 2 | Design faithfulness | 76 | pass |
| 3 | Red-team resistance (CRITICAL) | 62 | weak |
| 4 | Implementability | 58 | weak |
| 5 | Safety / integrity (CRITICAL) | 72 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 66 | weak |
| 8 | Consistency | 58 | weak |
| 9 | Calibration / honesty | 56 | weak |

## Findings by dimension

### 1. Correctness

- **The `weight`/`confidence` disambiguation asserts a fact §5.2 does not contain.** BUILD-SPECS.md:221 states: *"`weight` is the §5.2 reachability input (how strongly the parent gates the child) and is excluded from traversal order."* But `ALGORITHM-v0.2-pathway-learner.md:145` defines reachability as `reach_weight(s, n) = ∏_{p ∈ prereqs(s)} P(mastery[p] ≥ θ)` — an **unweighted** product of prereq-mastery probabilities. There is no `weight` term anywhere in that formula, and no other line in `ALGORITHM-v0.2-pathway-learner.md` shows `weight` being consumed by any computation (verified by grep across the whole file — the only other hits are `rerank weights`, `weight axis/updates`, none of them the edge field). The amendment resolves round-1's *naming* collision (finding 3) by inventing a *functional* role for `weight` that the cited section doesn't actually implement. Either §5.2's formula needs a companion weighted variant that doesn't exist yet, or the field is simply unused by any existing mechanism and the amendment should say so instead of citing a formula that contradicts the claim. This is a genuine, checkable factual error in a load-bearing disambiguation, not a stylistic nit — a developer implementing `reach_weight` per §5.2 verbatim, then reading this amendment, would look for a `weight` input that isn't there.
- **The additive z-score priority formula (BUILD-SPECS.md:225) is well-formed for `|frontier| ≥ 2` but degenerate for `|frontier| = 1`.** `z(x | frontier)` (a population z-score) requires a defined sample SD; a BFS frontier consisting of a single edge (a composite with exactly one constituent, or a skill with exactly one prereq — common at shallow depth) yields SD=0 for both terms, making `z(...)` `0/0`. Round 1's normalization fix (finding 2) is correctly applied in form but the amendment does not state a degenerate-case fallback (e.g., "if `|frontier|=1`, priority is irrelevant — visit it"), unlike `significant()` (§2) which is defined for all inputs.
- The type-precedence contradiction from round 1 (BUILD-SPECS.md:217 old text vs. :218 old text) is genuinely gone — BUILD-SPECS.md:222 now states a single, non-contradictory rule (collect across both types, no short-circuit).

### 2. Design faithfulness

- The priority formula's shape (`z(...) + z(...)`, additive, frontier-relative) now matches the §5.3 convention (`Uz = zscore(Q̃|cands) + λ·zscore(reach_infogain(a)|cands)`, `ALGORITHM-v0.2-pathway-learner.md:165`) structurally. One divergence from that convention: §5.3's analogous combination carries an explicit weighting hyperparameter `λ` (registered in the §12 parameter list, `ALGORITHM-v0.2-pathway-learner.md:282`); Amendment A's formula (BUILD-SPECS.md:225) implicitly weights both terms 1:1 with no equivalent knob, and no argument is given for why this combination needs no such weight where §5.3's near-identical shape does. Not necessarily wrong (ranking-only, non-gating use lowers the stakes), but an unacknowledged departure from the pattern it claims to follow.
- **Acyclicity-over-the-union is asserted as a policy but still has no mechanism to inherit.** BUILD-SPECS.md:228 says edges "pass the same acyclicity check" at insertion — but as round 1 already found, the only acyclicity language anywhere in `ALGORITHM-v0.2-pathway-learner.md` is the inline comment at line 129 (`add_soft_prereq_edges(...) # soft, capped fan-in, acyclic`), which names no algorithm. Round 2 strengthens the *policy* statement (union-scoped, author-time too) without closing the underlying gap that there is still no concretely specified acyclicity-check mechanism anywhere in the referenced spec for the amendment to point to. `DATA-LAYER.md:180,195` (§6.2, itself concurrently `IN GATE` and not yet approved) defines `GraphStore.merge(delta) -> MergeReport{rejected: [...]}`, which is the natural home for such a check — but Amendment A never names it, so the linkage is inferable, not specified.
- Provenance (STUDY P6) is still faithfully represented, and the amendment correctly documents that round 1 caught and removed the precedence violation (BUILD-SPECS.md:215) — an honest, traceable revision note.

### 3. Red-team resistance

- **RC-1 (point estimates / structural override) is fixed at the candidacy layer but reopens at the confirmation layer, and the amendment's own regression test does not cover the reopened form.** BUILD-SPECS.md:222 correctly removes the type-precedence short-circuit so that candidacy — which prereq gaps are even considered — is type-blind. But BUILD-SPECS.md:223 introduces new, undefined language: *"children are visited — **and confirmation items allocated under budget** — in order of priority."* This implies a scarce confirmation resource whose allocation order can leave a candidate under-confirmed or unconfirmed within a diagnostic pass. The amendment's own Honest-risks bullet concedes this directly: *"ordering could starve a late candidate's confirmation budget"* (BUILD-SPECS.md:232) — which only makes sense if some real cap exists (otherwise nothing could be "starved"). Yet: (a) no `confirmation budget` parameter is defined, defaulted, or even named in the Parameters line (BUILD-SPECS.md:230 lists only `δ_hard`); (b) the test cited as "the regression guard" for this risk, `test_both_types_reach_candidacy` (BUILD-SPECS.md:236), is described purely as a **candidacy** test ("yields both candidates; the prereq gap is not dropped") — it does not exercise confirmation-budget exhaustion at all. So the amendment names a real residual risk, then cites a test that verifies a *different, already-solved* stage of the same mechanism as its mitigation. This is functionally a fresh instance of RC-1's structural-override hazard, one stage downstream from where round 1 found it (confirmation-ordering rather than type-precedence), and it is not closed by anything currently in the spec or its test list.
- **RC-1/RC-4 residual not raised in round 1: confidence never gates candidacy, only orders it — reopening the base B2 decision's own deferred advisory item.** `B2-prereq-gap-decision.md`'s advisory item 1 explicitly recommended: *"Add a traversal guard `edge.confidence >= tau_traverse` to the BFS walk to avoid diagnosing prereq paths the graph has already learned are unreliable."* Amendment A had the opportunity to close this (it redefines `confidence`'s role from scratch, BUILD-SPECS.md:221) but explicitly restricts `confidence` to *ordering* only (BUILD-SPECS.md:223-227) — candidacy is governed solely by `significant(θ-ĉ_mastery[P], SE[P])` on the prereq's own mastery (BUILD-SPECS.md:222), with no floor on edge confidence. A `P→S` edge that `g.decay_edges()` has already driven toward zero confidence because past redirects to `P` never lifted `ĉ[S]` (the base B2 outcome-feedback loop, BUILD-SPECS.md:189) remains, forever, an eligible candidate whenever `P`'s own mastery gap is independently significant — the walk will keep re-surfacing and re-confirming a prereq the system has statistically learned is not causal for `S`. This is a genuine, if narrower, residual of the same root-cause family (RC-1: non-statistical/structural rule overriding what evidence has already shown) that this round's fixes do not touch.
- **RC-4 (mixed-type cycles, authored edges bypassing acyclicity)** — meaningfully improved: union-scoped, author-time-inclusive acyclicity is now stated as policy (BUILD-SPECS.md:228) and tested (`test_union_acyclicity_at_insertion`, :241). Residual is implementability-level (mechanism not named), not a red-team reopening — see Design faithfulness / Implementability.
- **RC-4 inverse (hard edges undecayable / density-as-override)** — the round-1 adversarial objection (a densely-`hard`-tagged curriculum turning "tie-break" into a de facto override) is now closed by construction: `|Δpriority| < δ_hard` bounds the tie-break regardless of how many edges are marked `hard` (BUILD-SPECS.md:229), decay is unconditional (unchanged), and a density test now exists (`test_hard_edge_tiebreak_bounded`, :242). No residual found here.

### 4. Implementability

- **No `GraphStore` port method exists to read `part_of` edges, still.** `DATA-LAYER.md:69-74` (`GraphStore` Protocol) is unchanged from round 1: `add_skill(self, s, prereqs: list[Edge], *, status="live")` and `prereqs(self, s) -> list[Edge]` are the only edge-facing methods. The schema line (`DATA-LAYER.md:138`) now lists `part_of{weight, confidence, hard}`, but nothing in the port interface can create or retrieve one — a schema/port mismatch inside `DATA-LAYER.md` itself, and a direct carry-over of round-1 finding 1 under Implementability.
- **No Plug-point subsection was added.** Every other item/amendment in `BUILD-SPECS.md` (base B2: line 192; B3: line 257; R1: line 309, etc.) has one; Amendment A (lines 213-243, re-read in full for this round) still has none. Round-1 finding 3 (Implementability) is unresolved.
- **No authoring-API is named for Teacher-created `part_of`/`hard` edges.** BUILD-SPECS.md:219's "e.g. from a Teacher's domain map" remains illustrative provenance, not a specified interface. `test_part_of_constituent_diagnosed` and `test_union_acyclicity_at_insertion` both require constructing authored edges in a fixture, and there is still no stated path (via `GraphStore.merge(delta)`, §6.2, or a dedicated method) to do so deterministically.
- **The "confirmation budget" introduced at BUILD-SPECS.md:223 is an entirely new, unparameterized concept.** It has no default, no bound, and is not in the Parameters line (:230). This is a genuinely new implementability gap introduced by this round's revision (the base B2 mechanism has no such concept — see Correctness/Red-team above).
- **Resolved cleanly this round:** the `Edge` schema (:218-219), the `DATA-LAYER.md:138` schema mirror, and `δ_hard`'s default (0.1, :229-230) are now concrete enough to build against.

### 5. Safety / integrity

- The §8 commit gate, §14 calibration layer, and the verifier (`HUMAN-LEARNING-VERIFIER.md`) remain untouched — no direct weakening.
- The acyclicity invariant (an RC-4 integrity guarantee) is now stated to cover authored edges too (BUILD-SPECS.md:228), which is a genuine strengthening of scope over round 1, even though the concrete mechanism is still asserted rather than fully specified (see Implementability).
- **Residual, scoped concern:** the confirmation-budget-starvation gap (Correctness/Red-team above) touches B2's core integrity hinge — "confirm before redirect" (BUILD-SPECS.md:189) — because a true, severe root gap that never receives its confirmation slot cannot be confirmed, and therefore cannot be redirected to, leaving the learner mis-diagnosed for that diagnostic pass. This is bounded (it delays correct diagnosis; it does not cause a false positive redirect, since confirmation still gates any redirect that does happen) and does not roll back an existing gate, which is why this scores in the acceptable band rather than below 50 — but it is a real, unquantified integrity gap in a mechanism this amendment itself introduces.

### 6. Efficiency / cost

- No new LLM calls introduced beyond the existing confirmation-item cost already priced into base B2. Collecting candidates across two edge types roughly doubles the branching factor of the backward walk in the worst case (a skill with both `prereq` and `part_of` edges at every level), still bounded by `d_max` — no asymptotic regression (`O(branches · types · log)` for the frontier sort, negligible).
- **New, unbounded cost driver:** the undefined "confirmation budget" (BUILD-SPECS.md:223) means the actual number of confirmation-item batches administered per diagnostic pass is not capped anywhere in this spec — in the worst case (many significant candidates across both edge types at one depth), confirmation cost could scale linearly with candidate count with no stated ceiling. Not catastrophic (still bounded by graph branching × `d_max`), but a real gap in cost predictability that round 1's clean 90 didn't have to account for, since round 1's type-precedence short-circuit implicitly limited confirmation to one type at a time.

### 7. Completeness

- **Improved:** `test_both_types_reach_candidacy`, `test_union_acyclicity_at_insertion`, `test_hard_edge_tiebreak_bounded`, `test_priority_is_frontier_zscored`, `test_weight_not_in_traversal` all add real coverage the round-1 spec lacked.
- **Gap carried forward in a new form:** no test exercises confirmation-budget exhaustion — the actual mechanism the amendment's own Honest-risks section names as a residual (BUILD-SPECS.md:232). `test_both_types_reach_candidacy` is necessary but not sufficient for that risk (see Red-team finding 1).
- No test for the frontier-size-1 degenerate z-score case (Correctness finding 2).
- No test or spec language for the `part_of`/`hard` edge authoring path (Implementability).
- The Parameters line (:230) is incomplete: it lists `δ_hard` but not the confirmation-budget concept the mechanism text itself now depends on.
- No test targets the residual advisory item from the base B2 decision record (edge-confidence traversal floor, `tau_traverse`) that this amendment's redefinition of `confidence` had a natural opportunity to close (see Red-team finding 2) — not a new requirement of this amendment, but a missed chance to retire a known, already-recorded advisory gap while touching the exact mechanism it concerns.

### 8. Consistency

- **Resolved:** `DATA-LAYER.md:138`'s schema line now includes `part_of{weight, confidence, hard}` and `prereq{weight, confidence, hard}`, consistent with BUILD-SPECS.md:218-219's `Edge` definition. Round-1's Consistency finding on this point is closed.
- **New inconsistency:** the claim that `weight` is "the §5.2 reachability input" (BUILD-SPECS.md:221) is inconsistent with `ALGORITHM-v0.2-pathway-learner.md:145`'s actual `reach_weight` formula, which takes no `weight` argument (Correctness finding 1, restated here as a cross-document consistency defect between `BUILD-SPECS.md` and `ALGORITHM-v0.2-pathway-learner.md`).
- **New inconsistency, internal to `DATA-LAYER.md`:** the schema (§5, line 138) now describes `part_of` edges as first-class graph data, but the `GraphStore` Protocol (§2.1, lines 69-74) has no method to write or read them — the record schema and the port interface disagree about what the store can do.
- **Unacknowledged cross-gate dependency:** Amendment A's acyclicity-at-insertion claim (BUILD-SPECS.md:228) most naturally integrates with `DATA-LAYER.md §6.2`'s `GraphStore.merge(delta) -> MergeReport{rejected}` — but that section is itself dated 2026-07-13 and marked "IN GATE" (i.e., not yet approved). Two concurrently-gated proposals now have an implicit, unstated dependency on each other's most natural integration point; neither document flags it.

### 9. Calibration / honesty

- **The Honest-risks section overstates its own mitigation.** BUILD-SPECS.md:232 states the masking risk is "mitigated structurally" and cites a specific test as "the regression guard" — but that test, per its own description (:236), verifies candidacy only, not the confirmation-budget-starvation scenario the risk bullet itself describes one sentence earlier. Naming a real risk honestly (good) and then claiming a stronger mitigation than the cited evidence supports (not good) is exactly the kind of overstatement the Calibration dimension exists to catch.
- **The `weight` disambiguation (BUILD-SPECS.md:221) is stated with full confidence** ("Field roles, disambiguated") but rests on a claim about §5.2 that a direct read of that section contradicts (Correctness finding 1). Confidently resolving a flagged ambiguity with an incorrect grounding is worse, calibration-wise, than leaving the ambiguity open with a stated "TBD."
- **Genuinely well-calibrated, by contrast:** the mixed-type-cycle and hard-edge-density risk bullets (BUILD-SPECS.md:233-234) are both accurately scoped to what their respective tests actually check, and the round-1→round-2 provenance note (:215) honestly documents what was caught and fixed rather than glossing over it.

## Strongest adversarial objection

The amendment's central selling point — "the type carries no evidential authority of its own" (BUILD-SPECS.md:222) — is only true at the **candidacy** boundary. At the **confirmation** boundary, the amendment introduces an unbounded, unparameterized notion of a scarce "confirmation budget" (BUILD-SPECS.md:223) whose allocation is governed by the very priority formula the amendment presents as "ranking-only, non-gating." But ranking *is* gating once the resource being ranked over is scarce and the low-ranked item's confirmation is deferred indefinitely (or across many diagnostic episodes, if the underlying skill keeps failing for other reasons) — at that point, "visited later" and "never confirmed in practice" converge. Combine this with a second, separate gap: `confidence` is defined to influence ordering only, never candidacy (BUILD-SPECS.md:229), so a prereq edge whose confidence has already been driven low by `g.decay_edges()` after a prior failed redirect (i.e., the graph has *already learned* this path isn't causal) is nevertheless treated identically to a fresh, never-tested edge at the candidacy stage, and — because low confidence also lowers its *priority* — is *systematically pushed to the back of the confirmation queue* every single time it resurfaces as a candidate. The two gaps compound: the amendment's own priority formula makes it *more* likely that a known-unreliable prereq edge is exactly the one starved of confirmation budget, while a fresh, unproven `part_of` edge (born with default confidence, per :221 "`weight` defaults 1.0" — confidence defaults are not stated but presumably also high/neutral) jumps the queue. The net effect the amendment must defend against, and does not: repeatedly re-diagnosing (and never confirming, hence never gaining outcome-feedback evidence to decay further) the *same* already-suspect prereq path, while a genuinely fresh candidate that could clear or convict it waits — the opposite of what the outcome-feedback loop (BUILD-SPECS.md:189) is supposed to achieve. This is not raised in any of the nine dimensions above in this compound form (each half is touched separately — the budget gap under Correctness/Red-team/Completeness, the confidence-never-gates-candidacy gap under Red-team finding 2 — but not their interaction, which is the actual adversarial case).

## Aggregate confidence

```
critical_floor  = min(Correctness=66, RedTeam=62, Safety=72) = 62
weighted_mean   = (66*2 + 76 + 62*2 + 58 + 72*2 + 78 + 66 + 58 + 56) / 11
                = (132 + 76 + 124 + 58 + 144 + 78 + 66 + 58 + 56) / 11
                = 792 / 11
                = 72.0 → 72
overall         = min(62, 72) = 62
```

**Overall confidence: 62 / 100**

## Verdict

**needs-revision**

Round 2 made real progress (55 → 62; 3 of 7 round-1 blockers cleanly closed, 3 more genuinely narrowed). It does not clear the bar. Specific blocking changes required to clear 80:

1. **Correct or retract the `weight` = "§5.2 reachability input" claim (BUILD-SPECS.md:221).** Either amend §5.2's `reach_weight` formula (`ALGORITHM-v0.2-pathway-learner.md:145`) to actually consume an edge weight, or state plainly that `weight` is currently unused by any mechanism and reserved for a future use — do not cite a formula that doesn't contain the term.
2. **Define the confirmation-budget concept or remove it.** BUILD-SPECS.md:223's "confirmation items allocated under budget" and the Honest-risks admission that "ordering could starve a late candidate's confirmation budget" (:232) need either (a) an explicit, defaulted budget parameter plus a rule for what happens to a significant candidate that doesn't get confirmed this pass (deferred to next trigger? escalated?), added to the Parameters line, or (b) a statement that all significant candidates across both types are always confirmed in the same pass (no real budget), in which case the "budget" language and the associated risk bullet should be removed as inaccurate.
3. **Add a test that actually covers confirmation-budget starvation** (not just candidacy) if the budget is retained per (2) — the current `test_both_types_reach_candidacy` does not test the risk it is cited as guarding against.
4. **Add the `GraphStore` port method(s) and a Plug-point subsection.** Name the concrete interface delta for reading/writing `part_of` edges and for the authored-edge acyclicity check (e.g., cross-reference `DATA-LAYER.md §6.2`'s `GraphStore.merge`/`MergeReport.rejected` explicitly, and note the cross-gate dependency this creates on an unapproved §6.2).
5. **Decide whether `confidence` should floor candidacy, not just order it** — either explicitly defer the base B2 decision record's advisory `tau_traverse` guard with a stated reason (this amendment isn't the place), or close it now, since Amendment A is already redefining `confidence`'s role end-to-end.
6. **Handle the `|frontier|=1` degenerate z-score case** explicitly in the formula or its surrounding text, and add a test for it.
