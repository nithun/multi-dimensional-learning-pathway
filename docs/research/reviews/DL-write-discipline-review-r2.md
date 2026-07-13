# 360 Review: DL-write-discipline — 2026-07-13 (Round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 156–173) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 175–197), both marked *revised r2 — IN GATE* |
| Proposed change | Round-2 rewrite of both sections to close all six round-1 blockers: hash now includes occurrence provenance (episode/trace id + `checkpoint_id` + attempt index, never wall-clock `ts`); `append_event`/`record_eval` stay true appends returning an observable `AppendResult{id, deduped}`; the two merge mechanisms (structural identity-dedup at `GraphStore` vs. semantic `τ_merge` unification at `g.maybe_merge()`) are explicitly reconciled to a single truth event; `GraphDelta`/`MergeReport` are given concrete schemas; per-tier transactional/failure semantics are specified; RC-3 EXTRACT/MERGE liveness ordering is closed with a named test. |
| Reviewer | review-360 |
| Round | 2 (`-r2`) — round 1: `docs/research/reviews/DL-write-discipline-review.md`, overall 38/100, needs-revision, 6 blockers |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 78 | acceptable |
| 2 | Design faithfulness | 85 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | acceptable |
| 4 | Implementability | 62 | weak |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 65 | weak |
| 7 | Completeness | 72 | acceptable |
| 8 | Consistency | 68 | weak |
| 9 | Calibration / honesty | 85 | pass |

## Findings by dimension

### 1. Correctness

**Round-1 blocker genuinely resolved at the formula level.** `DATA-LAYER.md:161-165` now defines `id = hash(record_type ‖ semantic_payload ‖ occurrence_provenance)` with `occurrence_provenance = episode/trace id + checkpoint_id + attempt index (NEVER wall-clock ts, NEVER filename)`. `DATA-LAYER.md:167` states the discriminating logic directly and correctly: re-ingesting the *same* occurrence dedupes; a genuine repeat measurement in a *new* episode/attempt produces a new id — and the paragraph explicitly names the exact mechanisms round 1 flagged (`sustained_heldout` §9, Stage-1 shadow monitoring §17.3, §19.1's `w_obs`) as the reason this distinction is load-bearing. This is a correct fix to the round-1 defect, not a cosmetic one, and it is honest about what round 1 got wrong (see Calibration, below).

**Residual correctness risk: the load-bearing new field is itself unspecified.** `DATA-LAYER.md:163` introduces "attempt index" with no definition of how it is generated, scoped, or guaranteed unique — durable monotonic counter in `TruthStore`? UUID-based token? An in-process counter? Each choice has a different failure mode:
- If "attempt index" (or "episode/trace id") is an in-memory counter that resets on process restart, a **new, genuinely distinct occurrence** that happens to reuse `(episode_id, checkpoint_id, attempt_index)` from before the restart would hash identically to the earlier occurrence and be silently deduped — reopening the exact round-1 failure mode (under-counting), just in a narrower, restart-triggered window instead of the "every stable-candidate re-observation" modal case round 1 found.
- This is not a hypothetical corner case for this project specifically: `HUMAN-LEARNING-VERIFIER.md:35` establishes "attempts" (`P(correct, response_time, hints_used, attempts | competence, item)`) as a first-class, **expected-to-recur-many-times** behavioral signal for the `HumanLearnerAdapter` — i.e., the human-learning path is exactly the one where repeat attempts on the same item are common and load-bearing, making a non-durable attempt-index counter a live, not theoretical, risk.

No test in the `:197` list exercises attempt-index/episode-id durability across a process restart (see Completeness). This keeps Correctness at "acceptable," not "strong": the *shape* of the fix is right, but the one new primitive it depends on is not specified precisely enough to certify it closes the gap in practice.

### 2. Design faithfulness

Substantially improved from round 1. `DATA-LAYER.md:180` cleanly resolves the round-1 dual-merge-mechanism ambiguity: `GraphStore.merge()` dedups **by identity only**; `τ_merge`-based semantic unification is **exclusively** `g.maybe_merge()`'s (§5.1, algorithm layer, `ALGORITHM-v0.2-pathway-learner.md:131`), and when it fires it is folded into one truth event so both projections replay from the same source — "two mechanisms, two jobs, one symbol no longer shared." This directly answers round-1 finding #2 and is faithful to RC-4's merge/prune/decay-inverse pattern (`ALGORITHM-v0.1-redteam.md:51-53`).

One stylistic gap persists from round 1: other additive sections in `ALGORITHM-v0.2-pathway-learner.md` open with an explicit "nothing in §X changes" framing sentence (`:292` §13, `:335` §14, `:481` §17.6). §6.1/§6.2's revision doesn't carry an equivalent sentence inside `DATA-LAYER.md` itself, even though its own §6 preamble (`:146`) is what it materially amends. Minor — does not by itself justify a lower score, but is repeated from round 1 without being picked up.

### 3. Red-team resistance

**RC-3 (unscorable growth) — closed.** `DATA-LAYER.md:179` now states explicitly: "Liveness is decided before the delta exists: growth candidates enter the `GraphDelta` already carrying the `live`/`pending_human` status that `provision_suite` (§5.1, RC-3) assigned — MERGE never assigns or upgrades liveness." Backed by a named test, `test_merge_never_assigns_liveness` (`:197`: "a delta node without `provision_suite` status is rejected"). This directly closes the round-1 ordering ambiguity at the EXTRACT/MERGE boundary.

**RC-4 (add-only ratchet) double-merge risk — closed**, per Design faithfulness above: a single reconciled merge path removes the "half-merged state" risk round 1 flagged.

**Residual, milder RC-1-adjacent risk (not squarely reopened).** RC-1 (`ALGORITHM-v0.1-redteam.md:36-39`) is about decisions firing on quantities whose sampling error exceeds the effect measured. If the Correctness-dimension attempt-index gap causes occasional silent under-counting, every downstream `significant()` computation (§2) that consumes that count — `sustained_heldout`, `w_promo`, `q_explore`'s SE — is operating on an `n` quietly smaller than reality. This is a narrower, edge-case version of round 1's finding (restart-triggered, not modal), and no root cause is reopened outright, but it is a real residual attack/ambiguity surface a careless implementation could hit. Scored "acceptable," not "strong," for this reason.

### 4. Implementability

Concrete positives: `GraphDelta`/`MergeReport` now have field-level schemas (`DATA-LAYER.md:182-189`, closing round-1's biggest implementability gap); nine named tests (`:197`, up from four in round 1) cover dedup observability, atomicity, liveness-ordering, and the semantic-merge-single-event property; per-tier "transactional" semantics and a failure contract are stated (`:191`).

Four concrete gaps a developer would still have to resolve by guessing:

- **The `AppendResult` change does not ripple into §2.1's canonical port listing.** `DATA-LAYER.md:53-54` (§2.1, unchanged since round 1) still declares `def append_event(self, ev: Event) -> str: ...` and `def record_eval(self, r: EvalResult, lineage: Lineage) -> str: ...` — flatly contradicting §6.1's stated port delta at `:173` (`TruthStore.append_event(ev) -> AppendResult{id, deduped}`). Similarly, §2.1's `GraphStore` Protocol (`:69-74`) has no `merge` method at all, despite §6.2's port delta at `:195` (`GraphStore.merge(delta: GraphDelta) -> MergeReport`). A developer who builds strictly from §2 ("the ports & adapters," the document's own canonical interface section per its header at `:26`) would ship the pre-round-2 interface. This is a direct, easily-checked textual contradiction introduced by the revision's own incompleteness — the "Port delta" call-outs describe changes that were never merged into the section they claim to delta against.
- **`record_eval`'s return-type change is stated ambiguously.** `DATA-LAYER.md:169` says "`TruthStore.append_event` / `record_eval` stay true appends" and describes the `AppendResult` return in the same breath, but the explicit "Port delta" line (`:173`) names only `append_event`'s new signature. Whether `record_eval` also returns `AppendResult` (very likely intended, given the shared sentence) is left for the implementer to infer.
- **"Attempt index" has no stated generation mechanism** (repeated from Correctness — this is also a build-ambiguity, not just a soundness risk).
- **The mechanics of the reconciled single truth event are asserted, not specified.** `DATA-LAYER.md:180` says a `g.maybe_merge()` firing "emits its outcome as ordinary operations inside a delta (a merge-node op + the StateStore evidence-union), recorded as one growth event in truth, so graph and posterior projections can never diverge." But `rebuild_graph` and `rebuild_state` are two separate replay functions (`:149-151`), and no schema is given for a single truth event that carries both a `GraphDelta`-shaped graph operation *and* a `StateStore` evidence-union instruction, nor how each replay function extracts the piece relevant to its own store from one event. The `GraphDelta.merges` field (`:186`) covers only the graph side.

### 5. Safety / integrity

The round-1 second-order concern (thinned evidence feeding §14.1's ECE/Brier pairing and §19.1's `r̂`/`q_explore` statistics, `ALGORITHM-v0.2-pathway-learner.md:340,552,558`) is substantially closed: by design, genuine repeat measurements now produce new events (`DATA-LAYER.md:167`), so the modal under-counting scenario round 1 identified no longer occurs. `DATA-LAYER.md:169` adds a genuine safety-positive beyond what round 1 required: `StateStore` Beta updates are **also** keyed by the evidence id they consumed, so even a duplicate that slips past ingestion cannot double-update a posterior — real defense-in-depth against over-counting, which is the opposite failure mode.

No §8 gate clause, §14 formula, or verifier admission rule is touched — structurally clean, as in round 1.

Residual: the same attempt-index specification gap (Correctness, above) could, in the narrow restart-collision case, still thin the population feeding §14/§19 — but this is now an edge case rather than the systematic bias round 1 found, so it does not pull this dimension below "acceptable."

### 6. Efficiency / cost

Content-hash lookups remain O(1) — unchanged and fine. **New, round-2-specific concern:** `DATA-LAYER.md:191` specifies the embedded tier's "transactional" merge as "apply the delta to a **shadow copy**, then atomically swap the graph reference under a single writer lock." For `networkx` in-proc (`:98`), a shadow copy of the whole graph is an O(|V|+|E|) time and (transient 2×) memory operation **per merge call**. Nothing in §6.2 states a batching/coalescing strategy (one shadow-copy per accumulated batch of growth events vs. one per individual `g.step` growth event, `ALGORITHM-v0.2-pathway-learner.md:117`), and nothing ties this cost explicitly to the existing §9 M1 "flip to full tier when the skill graph... outgrows in-proc" trigger (`DATA-LAYER.md` §9, established) as an additional, quantifiable reason to flip. This is a legitimate new question the round-2 specification makes visible for the first time — round 1 could not surface it because "transactional" was previously wholly unspecified, so its round-1 score of 78 (Efficiency) was optimistic by omission rather than by analysis. This sits on the cold/learn path (§1 table, `:22`), not the hot act path, which keeps it from being a blocking finding, but it is a real, currently unbounded cost.

### 7. Completeness

Marked improvement: nine named tests (`:197`) replace round 1's four, directly closing the missing-regression-test blocker (`test_repeat_measurement_not_deduped`) and adding coverage for atomicity (`test_embedded_merge_atomic_swap`), liveness-ordering (`test_merge_never_assigns_liveness`), and merge-observability (`test_merge_report_shows_inverses`).

Residual gaps:
- **No test for occurrence-id durability/collision-safety across a process restart** — the specific scenario the Correctness/Implementability findings raise is untested even in the expanded test list.
- **Hash-collision handling remains unaddressed** (low materiality assuming a cryptographic hash; still literally unstated, same as round 1).
- **No schema for the combined graph+state truth event** that must drive both `rebuild_graph` and `rebuild_state` from one record (repeated from Implementability — also a completeness gap on its own terms).

### 8. Consistency

Two round-1 tensions are now cleanly resolved:
- **Append-only vs. dedup-as-no-op.** `DATA-LAYER.md:169` explicitly reframes the operation as idempotence, not upsert ("nothing is ever modified... append-only preserved; identical-identity re-appends are no-ops, which is idempotence, not upsert"), directly answering round-1 finding #8's tension with `:146`.
- **The `τ_merge` dual-use ambiguity.** `DATA-LAYER.md:180` scopes `τ_merge` to exactly one place (`g.maybe_merge()`); `GraphStore.merge()` now dedups by identity-hash equality only, not by any similarity threshold.

**New, unresolved inconsistency introduced by this very revision:** §2.1 (`DATA-LAYER.md:51-85`), the document's own canonical "ports & adapters" listing (§2 header, `:26`), was left completely unedited and now directly contradicts §6.1/§6.2's stated port deltas on three points — `append_event`'s return type, `record_eval`'s return type, and the absence of `GraphStore.merge` from the `GraphStore` Protocol (see Implementability for full detail). This is a textual self-contradiction inside one document, not a subtle inference — a reader who reads only §2 gets a stale, incomplete interface, and a reader who reads only §6 gets a delta with nothing to diff against. This is the concrete finding the task brief specifically asked this round to check for, and it is present and unaddressed.

### 9. Calibration / honesty

A markedly more honest revision than round 1. `DATA-LAYER.md:167` names round 1's own defect directly and accurately: "Round 1 of this gate hashed the semantic payload alone, which would have silently under-counted exactly those repeat observations — the inverse bias of the duplication it set out to fix." `DATA-LAYER.md:171` also repairs round 1's second calibration complaint (the "idempotent ⇒ correct" conflation) by explicitly separating the two claims: "the guarantee is determinism given the log — ingestion correctness above is what makes the log itself right." This is exactly the caveat round 1 asked for, stated in the artifact's own words rather than asserted defensively.

One small residual overclaim remains: `DATA-LAYER.md:171`'s "Occurrence-identity hashing removes exactly the true duplicates and nothing else" is stated with more confidence than the currently-unspecified attempt-index generation mechanism (Correctness, above) can fully back — the claim is true *if* occurrence provenance fields are collision-free and durable, a condition the section asserts but does not yet establish.

## Strongest adversarial objection

**The fix trades a well-diagnosed under-counting bug for an equally dangerous, symmetric over-counting bug that the spec never rules out — because it depends entirely on an unstated assumption about retry-plumbing discipline.** `DATA-LAYER.md:167` names "pipeline retry" as the canonical case the occurrence-identity hash is *supposed* to dedupe: "re-ingesting the same occurrence (pipeline retry, replayed transcript, curator re-digestion — same episode, same checkpoint, same attempt) produces the same id and dedupes." But this only works if the retry harness is disciplined enough to **reuse** the original `episode_id`/`checkpoint_id`/`attempt_index` on retry — and nothing in §6.1/§6.2 states this as an obligation on the ingestion boundary, names which component is responsible for it, or tests it. The more natural, and arguably more common, implementation choice — giving every call/attempt its own freshly-generated trace id (a common tracing convention, and exactly the choice that would make the attempt-index-durability problem from the Correctness finding moot in the *other* direction) — would mean a literal retry of the exact same occurrence gets a **new** id every time, silently **double-counting** into `(α,β)` again: the precise round-1-era failure mode (over-counting), now re-opened through the opposite implementation error. The spec asks the reader to trust that whichever component generates episode/attempt identifiers gets this exactly right — reusing IDs on true retries, and never reusing them across genuinely distinct occurrences — without stating who owns that guarantee, how it's enforced, or what test would catch a violation in either direction. Neither of the nine dimensions above states this precisely: the Correctness/Implementability findings focus on the *under*-counting direction (stale/reused IDs after a restart); this is the *inverse* risk (fresh IDs on a literal retry), and it is not covered by any of the nine `:197` tests, none of which exercises a literal same-occurrence retry through an ID-generation layer that might or might not reuse identifiers.

## Aggregate confidence

```
critical_floor  = min(Correctness=78, RedTeam=80, Safety=85) = 78
weighted_mean   = (78*2 + 85 + 80*2 + 62 + 85*2 + 65 + 72 + 68 + 85) / 11
                = (156 + 85 + 160 + 62 + 170 + 65 + 72 + 68 + 85) / 11
                = 923 / 11
                = 83.9 → 84
overall         = min(78, 84) = 78
```

**Overall confidence: 78 / 100**

## Verdict

**needs-revision**

No CRITICAL dimension (Correctness 78, Red-team 80, Safety 85) is below 70 — round 2 made real, substantive progress (38 → 78) and closed all six round-1 blockers as originally framed. The verdict is `needs-revision` because the aggregate is below 80, driven by new/residual gaps this round's revisions themselves surfaced or left unaddressed:

1. **Reconcile §2.1's port `Protocol` block with §6.1/§6.2's stated deltas.** Update `TruthStore.append_event`/`record_eval` to their `AppendResult`-returning signatures and add `GraphStore.merge(delta) -> MergeReport` to the `GraphStore` Protocol (`DATA-LAYER.md:51-85`) so the document's own canonical ports section does not contradict its later sections.
2. **Specify how `episode`/`trace id` and `attempt index` are generated and guaranteed durable/collision-free across process restarts** (and, per the adversarial pass, guaranteed **reused** — not regenerated — on a literal same-occurrence retry). State which component owns this guarantee. Add a regression test for both directions: `test_occurrence_id_stable_across_restart` (no false dedup) and `test_retry_reuses_occurrence_id` (no false new-count on a literal retry).
3. **State explicitly whether `record_eval` also returns `AppendResult`** (the prose at `:169` implies yes; the Port delta at `:173` names only `append_event`).
4. **Give the reconciled single truth event (graph-merge-op + StateStore-evidence-union) a concrete schema**, so it's specified how one truth event replays through both `rebuild_graph` and `rebuild_state` without ambiguity.
5. **Bound the embedded-tier shadow-copy-swap cost** — state its complexity explicitly and either specify a batching/coalescing strategy for `GraphStore.merge()` or tie "shadow-copy cost too high" to the §9 M1 tier-flip trigger as an explicit, quantified additional reason to flip `graph → neo4j`.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-48","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r2.md","why":"360 review (round 2) of DATA-LAYER.md §6.1/§6.2 revised r2 — overall 38 -> 78/100, needs-revision (below-80 aggregate, no CRITICAL dim <70): all 6 round-1 blockers genuinely closed, but the AppendResult/GraphStore.merge port delta never merged into §2.1's canonical Protocol block, 'attempt index' occurrence-provenance field has no stated generation/durability mechanism, and the embedded-tier shadow-copy merge cost is newly-visible and unbounded","evidence":["docs/research/DATA-LAYER.md §2.1 (lines 51-85), §6.1/§6.2 (lines 156-197)","docs/research/reviews/DL-write-discipline-review.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §3/§5.1/§9/§14/§17.3/§19","docs/research/ALGORITHM-v0.1-redteam.md RC-1/RC-3/RC-4","docs/research/HUMAN-LEARNING-VERIFIER.md:35"],"outcome":"pending"}
```
