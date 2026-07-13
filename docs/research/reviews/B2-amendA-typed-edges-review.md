# 360 Review: B2-amendA-typed-edges — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md:213-226` (Amendment A to the approved B2, "typed hierarchy edges + confidence-ordered traversal") |
| Proposed change | Adds a `part_of` (composite→constituent) edge type walked before `prereq` edges on composite failure, a derived confidence×gap traversal order, and a tie-break-only `hard` flag on edges |
| Reviewer | review-360 |
| Date | 2026-07-13 |

Scope note: this review evaluates **only** the Amendment A block (BUILD-SPECS.md:213-226) and its interaction with the already-approved B2 base (BUILD-SPECS.md:182-211, decision record `B2-prereq-gap-decision.md`). The base mechanism, parameters, and prior review findings are treated as fixed context, not re-litigated.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 58 | weak |
| 2 | Design faithfulness | 62 | weak |
| 3 | Red-team resistance (CRITICAL) | 55 | weak |
| 4 | Implementability | 45 | blocking |
| 5 | Safety / integrity (CRITICAL) | 68 | weak |
| 6 | Efficiency / cost | 90 | pass |
| 7 | Completeness | 45 | blocking |
| 8 | Consistency | 50 | weak |
| 9 | Calibration / honesty | 45 | blocking |

## Findings by dimension

### 1. Correctness

- **Self-undermining precedence rule.** BUILD-SPECS.md:217 states an unconditional, structural rule: on a failing composite `S`, `part_of` constituents are walked **first**, then `prereq` edges — a type-level precedence that holds regardless of the live confidence/gap values. BUILD-SPECS.md:218 then states the amendment's own governing principle: "**Traversal order is derived, never constant** ... **No static edge weight may bias traversal** — a hardcoded constant fossilizes the diagnosis order." Line 217's rule is exactly the kind of evidence-independent, structural bias line 218 forbids — it is not a numeric constant, but it is a constant *precedence*, decided by edge **type**, not by `edge.confidence × z(...)`. The amendment does not reconcile these two bullets; taken together they say "order is always derived from live evidence" and "except part_of always outranks prereq," which is a direct internal contradiction, not a stylistic tension.
- **Un-normalized combination of scales.** The traversal-priority formula `edge.confidence × z(θ − ĉ_mastery[P])` (BUILD-SPECS.md:218) multiplies a bounded `[0,1]` quantity (`confidence`, DATA-LAYER.md:138) by an unbounded significance/z-statistic. The established pattern for combining heterogeneous-scale terms in this codebase is to **z-score every term before combining** — ALGORITHM-v0.2-pathway-learner.md:165-166, `Uz = zscore(Q̃ | cands) + λ · zscore(reach_infogain(a) | cands)`, explicitly called out as an RC-1 fix ("Normalized terms ... kills v0.1's λ/μ knife-edge"). Amendment A's raw product does not follow that convention and gives no argument for why the departure is safe here.
- **`z(...)` is not a defined function at the point of use.** ALGORITHM-v0.2 uses `z` in two distinct senses: the significance multiplier inside `significant(Δ, se, margin, z)` (§2, line 43) and `zscore(...)`, a population-normalization function (§5.3, line 165). Amendment A's `z(θ − ĉ_mastery[P])` (line 218) does not specify which is meant, or whether it is simply `(θ−ĉ)/SE` (the significance test statistic, repurposed here as a continuous ranking signal rather than a binary gate — a new use not validated anywhere else in the spec).

### 2. Design faithfulness

- B2's base mechanism (BUILD-SPECS.md:188) frames the backward walk as producing **candidate root gaps** (plural, collected per-branch to depth) which are then confirmed (line 189) — it is architecturally agnostic about *which* candidate is remediated first beyond "deepest significant-gap prereqs on a failing path." Amendment A layers a **new precedence axis** (edge type) on top of this without amending the base mechanism text describing candidate collection, leaving it unclear whether type-precedence changes *which candidates are collected* (masking) or merely *the order in which an already-complete candidate set is confirmed* (a UX/efficiency detail). The base spec gives no basis for resolving this ambiguity.
- The amendment asserts "same `d_max`/acyclicity" (BUILD-SPECS.md:217) as if there is a single, edge-type-general acyclicity/depth-cap invariant already defined in ALGORITHM-v0.2. In fact the only acyclicity language in the referenced sections is a one-line inline comment scoped specifically to growth-added `prereq` edges (`ALGORITHM-v0.2-pathway-learner.md:129`, `add_soft_prereq_edges(... ) # soft, capped fan-in, acyclic`) — there is no generic, edge-type-agnostic acyclicity invariant defined in §5.1/§5.2/§10 for the amendment to inherit. "Same acyclicity" is asserted, not derived from an existing generalized mechanism.
- Provenance (STUDY P6, cited at BUILD-SPECS.md:215) is faithfully represented — the `part_of`/`belongs_to` pattern and the hard/soft distinction do match the cited external analogues.

### 3. Red-team resistance

- **(a) `part_of`-first traversal can mask a true prereq root gap — a new instance of RC-1's core complaint.** `test_part_of_constituent_diagnosed` (BUILD-SPECS.md:222) is phrased as "roots to the constituent, **not** the composite's prereqs," i.e. an exclusive outcome, not merely "is visited earlier." If a composite `S` has both a significant `part_of` constituent gap **and** an independent, significant, and possibly more severe `prereq` gap on `S` itself, the spec as written (type-precedence, line 217) provides no rule for surfacing the latter once the former is found — there is no test covering the co-occurring-gap case, and the base B2 spec's "candidate root gaps" (plural) framing is silently narrowed by an edge-type filter that is not evidence-derived. This is functionally the same failure class RC-1 names (a non-statistical, structural rule overriding what significance testing would otherwise surface) applied at the edge-type layer instead of the numeric-weight layer — i.e., the amendment reproduces, in a new place, the exact hazard its own provenance note (the RAG-Anything hardcoded-weight cautionary tale, line 215) warns against.
- **(c) Mixed-type cycles and authored `part_of` edges bypass the one place acyclicity is actually enforced — an RC-4 residual.** RC-4's patch (`ALGORITHM-v0.1-redteam.md:53`) calls for edges to be "soft/probabilistic/decaying ... with an acyclicity invariant and fan-in cap" — and the only place this is concretely implemented is at growth-time insertion (`ALGORITHM-v0.2-pathway-learner.md:129`, inside `g.step`). Amendment A introduces `hard=True` edges explicitly described as **authored** ("e.g. from a Teacher's domain map," BUILD-SPECS.md:219) — i.e. edges that do not go through `g.step`'s insertion path at all. No author-time acyclicity check is specified anywhere for `part_of` or `hard` edges. Worse, because `part_of` (composite→constituent) and `prereq` (prerequisite→skill) are semantically compatible in the same direction for a constituent that is also a prerequisite of a sibling constituent, a 2-cycle across types (`S --part_of--> C`, `C --prereq--> S`) is easy to construct and is not excluded by anything in the amendment or by the base spec's single-edge-type invariant. A BFS visited-set will still terminate the *walk* (no infinite loop), but the underlying graph invariant ("no cycles") that the rest of the algorithm's soft-reachability reasoning implicitly assumes is not actually guaranteed for the union of both edge types.
- **(b) The `hard` flag does not reintroduce the RC-4 inverse (undecayable authored edge).** This is handled correctly: `hard=True` is explicit tie-break-only (BUILD-SPECS.md:219), `g.decay_edges()` still applies unconditionally, and `test_hard_edge_still_decays` (line 225) directly targets this. No regression found here — see the adversarial pass below for a residual concern in the same area that the nine dimensions do not fully capture.

### 4. Implementability

- **No port method exists to retrieve `part_of` edges.** `GraphStore` (DATA-LAYER.md:69-74) exposes exactly one edge-reading method, `prereqs(self, s) -> list[Edge]` (line 74). There is no `part_of(s)`, no `edges(s, type=...)`, and `add_skill` (line 70) takes only a `prereqs: list[Edge]` parameter — no path to attach `part_of` edges at all. The amendment specifies behavior ("descend both... under the same rule") without specifying the interface change a developer would need to build it.
- **`Edge` is never defined as a concrete type anywhere in DATA-LAYER.md.** It appears only as a bare type-hint (`list[Edge]`); the only place any edge fields are named at all is the prose schema line `edges prereq{weight, confidence}` (DATA-LAYER.md:138). There is no dataclass/schema to add a `type` (`prereq`|`part_of`) discriminator or a `hard: bool` field to.
- **No "Plug-point" subsection.** Every other item and amendment in BUILD-SPECS.md (including the base B2, line 192-193; R1, line 288-289; B3, line 239-240) has an explicit Plug-point naming the concrete file/interface touched. Amendment A has none — a marked omission given the interface gap above.
- **"Equal derived priority" (the `hard` tie-break trigger, line 219) has no defined tolerance.** `confidence × z(...)` are continuous real numbers; exact floating-point equality will almost never occur. Either the tie-break is practically dead code (harmless but pointless), or an unstated epsilon band is intended (in which case its width determines how often `hard` actually steers order — a hyperparameter the amendment claims doesn't exist: "Parameters: none new," line 220).
- **No specification of how `part_of`/`hard` edges are created** (via `g.step`'s growth path, a separate Teacher-authoring API, or both), which blocks writing `test_part_of_constituent_diagnosed` deterministically without guessing a fixture-construction path.

### 5. Safety / integrity

- The §8 commit gate, §14 calibration layer, and the verifier (`HUMAN-LEARNING-VERIFIER.md`) are untouched by this amendment — no direct weakening found there.
- The residual concern is narrower: the acyclicity invariant is one of the concrete integrity guarantees RC-4's patch established for the graph (`ALGORITHM-v0.1-redteam.md:53`), and finding 3(c) above shows it is not actually extended to authored/`hard`/`part_of` edges. This is a real but bounded integrity gap (scoped to a new edge class, not a rollback of an existing gate), which is why this scores in the "weak" band rather than the sub-50 "clear weakening" band the rubric reserves for gate/calibration/verifier regressions.

### 6. Efficiency / cost

- No new LLM calls, no change to hot-path asymptotic complexity: sorting a BFS frontier by a derived key is `O(k log k)` in the frontier's branching factor, negligible next to the existing walk. `d_max` remains the bound on depth. No concern.

### 7. Completeness

- No test exercises the co-occurring-gap scenario central to finding (a) — every part_of test (`test_part_of_constituent_diagnosed`, line 222) uses a composite with **one** weak constituent, never a composite with both a weak constituent *and* an independent significant `prereq` gap on `S` itself, which is exactly the case that would reveal masking.
- No test for the mixed-type-cycle scenario in finding (c).
- No test for the tie-break epsilon/equality definition (finding 4).
- No test or spec language for `part_of`/`hard` edge creation/authoring paths.
- "Parameters: none new" (line 220) is not accurate once the implicit tie-break tolerance is accounted for (see finding 4) — an unbounded, undefaulted parameter is a completeness gap even if unnamed.

### 8. Consistency

- Contradicts DATA-LAYER.md:138's graph schema, which lists only `prereq{weight, confidence}` — `part_of` and `hard` do not exist in the schema, and the amendment neither updates DATA-LAYER.md nor flags that it requires such an update.
- Collides with the existing `weight` field on `prereq` edges (DATA-LAYER.md:138): the amendment's rule "no static edge weight may bias traversal" (line 218) is stated in a graph whose edges already carry a field literally called `weight`, and the amendment never clarifies whether that field is superseded, unused, or repurposed for `part_of` edges too.
- Internally inconsistent between its own bullets 1 and 2, as detailed in Correctness finding 1.
- Deviates from the §5.3 normalization convention without acknowledgment (Correctness finding 2).

### 9. Calibration / honesty

- Every other item in BUILD-SPECS.md carries an explicit "Honest risks" subsection (base B2: line 198-201; B3: line 245-249; R1: line 294-298). Amendment A has none. Given the file's own established convention, and given that this review surfaced a genuine masking risk (a) and a genuine cycle risk (c) that the amendment's authors were positioned to anticipate (the provenance note at line 215 already names the hardcoded-weight cautionary tale, one step short of noticing the type-precedence analog), the absence of a risks section reads as an unacknowledged gap rather than a considered "no material risk" judgment.
- The claim "Parameters: none new" (line 220) mildly overstates certainty — see finding 4/7 on the undefaulted tie-break tolerance.

## Strongest adversarial objection

The "tie-break, not override" framing of `hard` (line 219) implicitly assumes hard edges are a small, occasional nudge among otherwise well-separated derived priorities. Nothing in the amendment bounds **how many edges a Teacher/curriculum author may mark `hard=True`**, and nothing prevents an authoring pipeline (lazy, over-cautious, or simply following a "mark everything in the official curriculum as hard" convention) from marking most or all edges in a subgraph `hard=True`. Separately, newly-grown edges are seeded from a shared computation (`add_soft_prereq_edges(s_new, top_k_by_confidence(co_mastery))`, ALGORITHM-v0.2-pathway-learner.md:129) and so cluster near similar confidence values early in a skill's life — exactly when "equal derived priority" ties are most likely and exactly when diagnosis is least reliable (cold-start, thin posteriors — the same regime RC-1 flags as dangerous for point-in-time decisions). Put together: a densely-`hard`-tagged curriculum, combined with early-life confidence clustering, turns "tie-break only" into a de facto override during precisely the period the amendment should least want authored opinion dominating live evidence. Nothing in the nine dimensions above captures this — it is a governance/adoption-pattern attack on the tie-break mechanism itself, not a mechanics bug in decay or in the traversal formula.

## Aggregate confidence

```
critical_floor  = min(Correctness=58, RedTeam=55, Safety=68) = 55
weighted_mean   = (58*2 + 62 + 55*2 + 45 + 68*2 + 90 + 45 + 50 + 45) / 11
                = (116 + 62 + 110 + 45 + 136 + 90 + 45 + 50 + 45) / 11
                = 699 / 11
                = 63.5 → 64
overall         = min(55, 64) = 55
```

**Overall confidence: 55 / 100**

## Verdict

**needs-revision**

Specific blocking changes required to clear 80:

1. **Resolve the type-precedence vs. derived-order contradiction (Correctness finding 1, Red-team finding a).** Either make `part_of`-before-`prereq` itself a term inside the derived `confidence × z(gap)` ranking (e.g., a small additive/multiplicative bonus that a sufficiently large prereq gap can still outrank), or explicitly collect **all** significant candidates across both edge types (not a type-ordered short-circuit) and let confirmation (base B2 step 3) adjudicate — then add a test with a composite that has both a weak constituent and an independent, more-severe direct prereq gap, and assert the prereq gap is not silently dropped from the candidate set.
2. **Specify the `GraphStore` interface delta and the `Edge` schema.** Add a concrete Plug-point subsection naming the new/changed `GraphStore` method(s) for reading `part_of` edges, and define the `Edge` fields (`type`, `weight`, `confidence`, `hard`) as an explicit schema, cross-referencing the required DATA-LAYER.md §5 update (`part_of{weight, confidence}` alongside the existing `prereq{...}` line, plus the `hard` field).
3. **Reconcile the `weight`-field naming collision.** Clarify whether the existing schema `weight` field on `prereq` edges is superseded by `confidence`-driven traversal, retained for a different purpose, or removed — and whether `part_of` edges carry the same field.
4. **Define the acyclicity scope explicitly.** State whether acyclicity is enforced over the union of `prereq` ∪ `part_of` edges or per-type, and specify an insertion-time (author-time, not just growth-time) acyclicity check for `hard`/authored edges, since `g.step`'s existing invariant (ALGORITHM-v0.2-pathway-learner.md:129) does not cover Teacher-authored edges.
5. **Normalize the traversal-priority formula or justify the departure.** Either z-score `confidence` across the frontier before multiplying (matching the §5.3 convention), or explicitly argue why the raw product is safe for a ranking-only (non-gating) use, and pin down which `z(...)` function is meant.
6. **Bound the `hard`-flag tie-break tolerance** ("equal derived priority") with an explicit epsilon, add it to the parameter list, and add a test for the hard-edge-density scenario in the adversarial pass.
7. **Add an "Honest risks" subsection** naming at minimum the masking risk (a), the mixed-type-cycle risk (c), and the hard-edge-density risk (adversarial pass), consistent with every other item in BUILD-SPECS.md.
