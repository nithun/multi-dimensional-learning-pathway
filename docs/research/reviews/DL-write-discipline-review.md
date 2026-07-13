# 360 Review: DL-write-discipline — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — content-hash identity"), §6.2 ("Two-phase projection writes — extract, then transactional merge"), lines 156–175 |
| Proposed change | Add content-hash identity to every evidence-bearing record (with `TruthStore.append_event`/`record_eval` returning the existing id on a hash match) and a two-phase EXTRACT→transactional-MERGE write discipline for GraphStore/VectorStore, to prevent duplicate evidence from double-counting into Beta posteriors and to bound write amplification during continual growth. |
| Reviewer | review-360 |
| Date | 2026-07-13 |

**Round:** 1 (unsuffixed). **Circuit-breaker:** `agents.status = "open"` (checked in `.claude/memory/circuit-breaker.json`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 38 | blocking |
| 2 | Design faithfulness | 62 | weak |
| 3 | Red-team resistance (CRITICAL) | 55 | weak |
| 4 | Implementability | 55 | weak |
| 5 | Safety / integrity (CRITICAL) | 58 | weak |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 46 | blocking |
| 8 | Consistency | 55 | weak |
| 9 | Calibration / honesty | 48 | blocking |

## Findings by dimension

### 1. Correctness

**The central claim is only half-proven, and the unproven half is the dangerous half.**

`DATA-LAYER.md:158` specifies the hash input as "a hash of the semantic payload, never of filename/timestamp," with no further specification of which fields belong to that payload per record type. `DATA-LAYER.md:135` (established, §5) gives the `evals` schema as `(id, ts, skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id)`. If the "semantic payload" for an eval is `(skill, difficulty, split, n_pass, n_total, verifier, item_ids)` — the natural reading, since `ts` is explicitly excluded and `checkpoint_id`/an occurrence identifier is never mentioned as included — then **two genuinely distinct evaluation events that happen to share skill, difficulty, item selection, and outcome will hash identically and the second is silently discarded as a no-op** (`DATA-LAYER.md:158`: "return the existing id when the hash matches (the append is a no-op)").

This is not a contrived corner case. It is the *common* case for several mechanisms the rest of the spec already relies on:
- `ALGORITHM-v0.2-pathway-learner.md:465` — Stage-2 promotion monitoring requires observing competence "over a window `w_promo`," which means *repeated* re-evaluation of an (initially) unchanged candidate. A stable, well-behaved system tends to produce highly repeatable pass/fail patterns on a `rotating_sample` (`ALGORITHM-v0.2-pathway-learner.md:82`) drawn from a finite held-out pool — exactly the condition that triggers a hash collision under §6.1's rule.
- `ALGORITHM-v0.2-pathway-learner.md:253` (`sustained_heldout(adapter)`) and `:552` (§19.1's `q_explore` shadow observations over `w_obs`) both depend on accumulating multiple independent held-out observations over time to build statistical confidence. If §6.1 dedupes identical-looking repeat observations, the *sample count* feeding these checks is silently smaller than the real number of trials run, without any error or signal.

Every real occurrence not recorded is evidence that never reaches `update(cell, successes, failures)` (`ALGORITHM-v0.2-pathway-learner.md:60-63`), so `n_eff` under-grows relative to the true number of independent trials — the exact opposite failure mode from the one §6.1 was written to prevent (over-counting), and just as capable of "silently bias[ing] every downstream decision the algorithm makes" (§6.1's own words, `DATA-LAYER.md:160`).

**What's missing, concretely:** the hash needs an explicit **occurrence/provenance component** distinct from wall-clock timestamp — e.g., a `checkpoint_id` + `episode_id`/`trace_id`/`attempt_counter` that identifies *which underlying occurrence* produced the record — so that re-ingesting the *same* occurrence (pipeline retry, replayed transcript, curator re-digestion) hashes identically (correctly deduped) while two *different* occurrences that happen to share outcome content do not (correctly counted twice). §6.1 never states this distinction exists, let alone specifies which field carries it. This is the load-bearing gap: "hash of the semantic payload" is ambiguous between "the content that defines *what happened*" (which is what should be deduped) and "the content that defines *what was measured*, independent of *when/which attempt*" (which is what §6.1 actually specifies, and which is wrong for this purpose).

**Secondary correctness issue — the "idempotent by construction" claim overclaims what it proves.** `DATA-LAYER.md:160`: "Content-hash identity also makes `rebuild.py` idempotent by construction: replaying truth N times yields identical posteriors." This is true, but idempotence and correctness are being conflated: if the dedup rule under-counts (as above), replaying the (already-thinned) truth log N times will indeed yield the *same* wrong posterior every time. Idempotence in this framing certifies determinism, not accuracy — a subtlety the rationale sentence doesn't distinguish, and the surrounding argument leans on it as if it were evidence of correctness.

### 2. Design faithfulness

The overall direction — content-hash identity for idempotent evidence, and set-merge (`V∪V'`, `E∪E'`) for graph writes — is faithful to `ALGORITHM-v0.2-pathway-learner.md`'s RC-4 patch ("periodic merge... union evidence of duplicate skills," `:131`) and its general P1/P2 spirit (measurement independence, every `add` has an inverse). Two faithfulness gaps:

- **Two independent merge mechanisms are introduced without reconciliation.** `ALGORITHM-v0.2-pathway-learner.md:131` (`g.maybe_merge()`) is the *semantic* merge — it unions **Beta evidence** in `StateStore` for duplicate skills, using `τ_merge` hysteresis over skill similarity. `DATA-LAYER.md:169` introduces a *second*, independent merge at the `GraphStore` — structural, content-hash + the *same* `τ_merge` symbol, but operating on graph nodes/edges, not `StateStore` cells. Nothing in §6.2 states how these two merges stay synchronized: a `GraphStore.merge()` structural dedup could collapse two skill nodes in the graph while their `StateStore` posteriors remain un-unioned (or vice versa), leaving the two stores describing a different number of "skills" for the same underlying concept. Reusing the `τ_merge` *symbol* without stating whether it is the *same* threshold value/computation or merely an analogous one compounds the ambiguity.
- **No explicit "additive, no mechanism change" framing.** Every other additive section added to `ALGORITHM-v0.2-pathway-learner.md` (§13–§19) opens by stating precisely what does *not* change (e.g., `:333` "nothing in §1–§13 changes," `:446` "the §1–§16 mechanisms are unchanged"). §6.1/§6.2 do not carry an equivalent statement inside `DATA-LAYER.md` itself, even though they materially change §6's own established "append-only" framing (see Consistency, below) — a stylistic gap that in this case tracks a real substantive one.

### 3. Red-team resistance

No named root cause (RC-1..RC-8) is affirmatively reopened, but two are placed at risk by under-specification:

- **RC-3 (unscorable growth) — ordering ambiguity at the EXTRACT/MERGE boundary.** `ALGORITHM-v0.2-pathway-learner.md:127-129` makes `provision_suite` gating happen *inside* `g.step`, before a new skill's prereq edges are ever added — the RC-3 invariant is "no node enters the live graph without a suite + admitted verifier." `DATA-LAYER.md:168` describes EXTRACT as "parallel, cheap candidate generation (new skills / edges / embeddings), producing a `GraphDelta`... from growth (§5.1) **and indexing paths**" — a general two-phase pattern applied across both growth and retrieval-indexing writes. Nothing in §6.2 states that a growth-originated candidate entering `GraphDelta` must already carry a `live`/`pending_human` status decided by `provision_suite` before EXTRACT can propose it, nor that MERGE never itself assigns liveness. If EXTRACT is implemented as a decoupled, concurrency-friendly stage that runs ahead of/independent from the provisioning decision (a natural reading of "extractors hold no write locks"), a developer could wire it so an un-provisioned candidate reaches MERGE. This doesn't clearly *break* RC-3 as written, but it doesn't clearly *preserve* it either — the invariant needs to be re-asserted at the store boundary, not assumed to survive by reference.
- **RC-4 (add-only ratchet) — the double-merge-mechanism risk (see §2 above) reopens a milder version of RC-4's own concern**: if `GraphStore.merge()`'s structural dedup and `g.maybe_merge()`'s semantic dedup disagree (e.g., the store-level `τ_merge` similarity check is computed differently than the skill-level one), duplicate-but-distinct-looking nodes could still accumulate at the layer that isn't checked, i.e., a "half-merged" state that is exactly the kind of drift RC-4 was written to close.

Neither of these is scored as reopening a failure mode outright (hence not 0), but both are real residual attack/ambiguity surfaces that a hostile implementer or a careless later edit could exploit into a genuine RC-3/RC-4 regression.

### 4. Implementability

Concrete positives: the port deltas are named at the signature level (`content_hash` field on schemas, `TruthStore.append_event` documents return-existing-on-duplicate, `GraphStore.merge(delta: GraphDelta) -> MergeReport`, `VectorStore.upsert` ids as content-hashes — `DATA-LAYER.md:162,173`), and four acceptance-test names are given (`:175`).

Concrete gaps a developer would have to resolve by guessing:
- **No per-record-type hash-field specification.** "A hash of the semantic payload" (`:158`) is not defined per record type (`events`, `evals`, lessons, skill artifacts) — this is the same gap driving the Correctness finding above, and it recurs here as a build-ambiguity, not just a soundness bug.
- **`GraphDelta` and `MergeReport` have no schema.** `DATA-LAYER.md:169` says the report "lists added / deduped / merged" but gives no field names/types; `GraphDelta` is never defined beyond "producing a `GraphDelta`" (`:168`). Compare to the concreteness of the existing `Cell`/`Event`/`Lineage` schemas in §5 (`:135-140`) — these two new types are introduced at a lower specificity than everything else in the document.
- **"Transactional" is asserted, not implemented, for either tier** — see Efficiency/cost and the adversarial pass below.
- **No failure/partial-application contract for `merge()`.** If a MERGE call raises partway through applying `V∪V'`/`E∪E'`, is the result all-or-nothing? The word "transactional" implies yes, but nothing states how that's achieved on the embedded (`networkx`, in-proc) tier, which has no native transaction/rollback primitive.

### 5. Safety / integrity

No §8 gate clause, no §14 calibration formula, and no verifier admission rule is directly altered — the structural gates are untouched. The concern is second-order but real: **the evidentiary inputs to those gates can be silently thinned by the Correctness-dimension under-count**. Specifically:
- `ALGORITHM-v0.2-pathway-learner.md:340` (§14.1) pairs each logged prediction `p̂` with its realized outcome to compute ECE/Brier; a genuinely repeated observation that gets deduped under §6.1 is a calibration data point that never gets logged as a *second* pair, thinning the population the calibration layer needs (`:347`: "a single learner's single cell never has enough data to calibrate; the cohort does").
- `ALGORITHM-v0.2-pathway-learner.md:552` — §19.1's regression-rate estimator `r̂` and its `q_explore` shadow-quota SE explicitly depend on counting real repeat observations; an under-count here degrades the statistical power of §19's own safety floor (§19.3, `:557-558`) not by loosening the floor's clamp, but by feeding it a systematically smaller `n` than actually occurred.

This is a real weakening of the evidence base feeding several JUDGE-side mechanisms, but it is indirect (no gate formula is touched) and fixable by the same one-line hash-specification fix identified under Correctness — hence "weak," not "blocking," on this dimension in isolation. It is flagged here explicitly because §14/§19 are the specific calibration/gate-integrity surfaces named in this agent's charter.

### 6. Efficiency / cost

Content-hash computation is O(1) per record — no concern. `GraphStore.merge()` over a `GraphDelta` is efficient *if* content-hash lookups are backed by an index (a hash-set/dict), which the spec doesn't explicitly require but is the obvious implementation and not a real risk. The one unaddressed cost path: the `τ_merge` *fuzzy*-similarity dedup (distinct from exact content-hash dedup) requires comparing each new candidate against existing live nodes; unless this explicitly reuses the existing `VectorStore.ann` index already used for skill-similarity checks in §5.1 (`ALGORITHM-v0.2-pathway-learner.md:126`, `:149`), a naive implementation is O(|delta| × |live skills|) per merge, which is not currently ruled out or ruled in by the spec. No new LLM calls are introduced. Otherwise sound; scored "pass" but with this one open efficiency question worth a line in a revision.

### 7. Completeness

- **Missing test for the under-count edge case.** The four listed tests (`:175`) all test that duplicates *are* correctly no-op'd; none tests that two independently-generated, content-identical *distinct* observations are correctly counted twice. The absence of a `test_distinct_repeat_evidence_not_deduped`-shaped test is itself evidence the authors did not consider this failure mode.
- **No schema for `GraphDelta`/`MergeReport`** (repeated from Implementability — it is also a completeness gap on its own terms).
- **No merge failure/rollback test** (`test_merge_atomic_on_failure` or equivalent is absent).
- **No embedded-tier concurrency story.** `DATA-LAYER.md:98` lists the embedded GraphStore backend as `networkx (in-proc)`. "In-proc" is single-process by construction; §6.2's "one transactional `GraphStore.merge()`" doesn't address what happens when multiple concurrent callers (or, at fleet scale, `ALGORITHM-v0.2-pathway-learner.md` §18's multiple agents sharing "the shared substrate," `:510-511`) attempt merges against a single in-process graph object with no external lock. This interacts with (c) in the task brief directly — see the adversarial pass.
- **Hash-collision handling is unaddressed** (low materiality assuming a cryptographic hash, but literally unstated).

### 8. Consistency

- **Direct tension with §6's own preamble, three lines above the new text.** `DATA-LAYER.md:146` (established, untouched): "`TruthStore` is canonical and **append-only**." `DATA-LAYER.md:158` immediately below (new): `append_event`/`record_eval` "return the **existing** id when the hash matches (the append is a no-op)" — i.e., under some inputs, calling the append operation performs **no append**. This is not merely wording; it changes `append_event`'s contract from "record this occurrence" to "ensure this content is present" (upsert/set semantics), which is the semantics normally reserved for the **projection** stores (`StateStore`/`GraphStore`, described at `DATA-LAYER.md:146` as the things that get deduped/merged/rebuilt), not the canonical event log itself. §1's own role table (`DATA-LAYER.md:15`) defines `TruthStore` as holding the "canonical event log" — an *events, not facts* structure — while §6.1 pushes fact-level (deduped-identity) semantics down into the event layer. This blurs a distinction the rest of the document otherwise holds cleanly (events are what happened, projections are derived/current-state), and does so silently: unlike §6.2's `MergeReport` (which makes dedup/merge observable, `:169,171` "so growth's inverses stay observable"), §6.1 gives `append_event`'s caller no signal that a dedup occurred versus a fresh append — the return type is `-> str` either way (`DATA-LAYER.md:53`, unchanged port signature). §6.1 does not meet the observability standard §6.2 sets for itself in the same review.
- **The reused `τ_merge` symbol** (see Design faithfulness) is a second internal-consistency gap — same name, unclear whether same computation, across §5.1 (skill-level, StateStore evidence) and §6.2 (store-level, GraphStore structural).

### 9. Calibration / honesty

The rationale is confident and one-sided: it states plainly that "duplicated evidence... would double-count into `(α,β)` and silently bias every downstream decision" (`DATA-LAYER.md:160`) but never acknowledges the symmetric risk that the same mechanism can *under*-count genuine repeat evidence — despite the fact that the mechanism as literally specified (hash excludes timestamp, never mentions an occurrence identifier) demonstrably does so in realistic conditions (see Correctness). A design note this central to §3's correctness (the section header even calls it "a §3 correctness requirement") should carry an explicit caveat about what the hash must and must not include, and currently does not. The "idempotent by construction ⇒ correct" framing (`:160`) is a second instance of the same pattern — a true but insufficient claim presented without the caveat that idempotence guarantees repeatability, not accuracy. On the positive side, the provenance line (`:160`, crediting RAG-Anything/LightRAG for the content-hash *pattern* while explicitly owning "the Beta-bias argument is ours") is a genuinely honest and well-calibrated attribution — the document does distinguish borrowed mechanism from novel claim where it matters for credit, it just doesn't extend the same rigor to the correctness claim's own limits.

## Strongest adversarial objection

**§6.1's dedup rule is most likely to fire — and to do the most damage — in exactly the scenario the rest of the spec relies on most: repeated observation of an *unchanged* candidate.** §17.3's Stage-1 shadow run explicitly re-observes a candidate "on the held-out suite + a monitored live subset" to build "sustained" confidence over a window (`ALGORITHM-v0.2-pathway-learner.md:464-465`), §9's `sustained_heldout(adapter)` check (`:253`) is defined the same way, and §19.1's `q_explore` shadow quota exists precisely to accumulate multiple independent observations of borderline cases over `w_obs` (`:552`). All three mechanisms get their statistical power from *many independent looks at a system that isn't changing* — which, for a genuinely stable/well-behaved candidate drawing from a `rotating_sample` over a finite held-out pool, is a system that will frequently produce **the same item selection and the same pass/fail pattern** on consecutive observations. That is not the edge case this review's prompt describes as unusual ("two genuinely distinct evaluation events... at different times") — it is the *modal* case for a candidate that is actually working, at exactly the moment its promotion case is being built. Under §6.1 as specified, most of the repeat observations that Stage-1/`sustained_heldout`/`q_explore` are counting on would silently collapse to a single logged event, and the promotion/gate-calibration machinery would be operating on **far fewer real trials than its own math assumes** — with no error, no report, and no test that would catch it (per the Completeness finding). This is worse than a rare correctness bug: it is a **structural interaction between a new write-discipline rule and three existing statistical-confidence mechanisms**, none of which appears in any single one of the nine dimensions above because each dimension was scoped to §6.1/§6.2 in isolation, while the actual failure mode only shows up when §6.1 is read against §9/§17.3/§19 together.

## Aggregate confidence

```
critical_floor  = min(Correctness=38, RedTeam=55, Safety=58) = 38
weighted_mean   = (38*2 + 62 + 55*2 + 55 + 58*2 + 78 + 46 + 55 + 48) / 11
                = (76 + 62 + 110 + 55 + 116 + 78 + 46 + 55 + 48) / 11
                = 646 / 11
                = 58.7 → 59
overall         = min(38, 59) = 38
```

**Overall confidence: 38 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to bring Correctness/Safety above 70):

1. **Specify the hash inputs per record type explicitly**, including an occurrence/provenance component (e.g., `checkpoint_id` + an episode/trace/attempt identifier) distinct from wall-clock `ts`, so that re-ingesting the *same* occurrence dedupes while two *different* occurrences with identical outcome content do not. This is the fix for the central Correctness finding and removes most of the Safety/integrity and Red-team-adjacent concern.
2. **Add the missing edge-case test** — a genuine repeat measurement (same skill/items/outcome, different occurrence/checkpoint context) must be shown to produce two events and two Beta updates, not one.
3. **Reconcile §6.1's return-existing-on-duplicate `append_event` with §6's own "append-only" framing** (`DATA-LAYER.md:146`) — either state explicitly why upsert-on-content-match is compatible with an append-only event log, or move the dedup responsibility to the consumption side (`rebuild_state`/`update_posteriors`) and keep `append_event` a true append; and give `append_event` a `MergeReport`-equivalent observable (was this new or a dedup?) to match the standard §6.2 sets for itself.
4. **Reconcile the two merge mechanisms** — state explicitly whether `GraphStore.merge()`'s `τ_merge`-based structural dedup is the same computation as `g.maybe_merge()`'s semantic (StateStore-evidence-union) merge, and how the two stores are kept from diverging (a merged graph node with an un-merged posterior cell, or vice versa).
5. **Specify `GraphDelta` and `MergeReport` schemas**, the tier-specific meaning of "transactional" (in particular, how the embedded/`networkx` in-proc tier achieves atomicity with no native transaction primitive, and what happens under concurrent merges from a multi-agent (§18) fleet sharing one in-proc graph object), and the failure/partial-application contract for `merge()`.
6. **State explicitly that EXTRACT-phase candidates from growth carry an already-decided `live`/`pending_human` status from `provision_suite` before entering a `GraphDelta`**, and that MERGE never itself assigns liveness — closing the RC-3 ordering ambiguity at the EXTRACT/MERGE boundary.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-<n>","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review.md","why":"360 review of DATA-LAYER.md §6.1/§6.2 (idempotent evidence, two-phase projection writes)","evidence":["docs/research/DATA-LAYER.md"],"outcome":"pending"}
```
