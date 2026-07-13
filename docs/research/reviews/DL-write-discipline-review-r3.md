# 360 Review: DL-write-discipline — 2026-07-13 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 158–177) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 179–208), both marked *revised r3 — IN GATE* |
| Proposed change | Round-3 rewrite closing round 2's five findings: reconciles §2.1's `Protocol` block with the `AppendResult`/`GraphStore.merge` port deltas; adds a durability contract for occurrence-id minting (orchestrator-owned, persisted before work runs, retries reuse the durable row); makes `record_eval`'s `AppendResult` return explicit; gives the reconciled semantic-merge truth event a concrete schema (`skill_merge{...}`) replayed by both `rebuild_state`/`rebuild_graph`; states and bounds the embedded-tier shadow-copy cost, coalesces it to one `merge()` per loop tick, and ties it to the §9 M1 tier-flip trigger. |
| Reviewer | review-360 |
| Round | 3 (`-r3`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `docs/research/reviews/DL-write-discipline-review-r2.md` (78/100, 5 items left) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Round-2 items — verification of closure

| # | Round-2 item | Verdict | Evidence |
|---|---|---|---|
| 1 | Reconcile §2.1's `Protocol` block with §6.1/§6.2's port deltas | **Closed** | `DATA-LAYER.md:53-54` (`append_event`/`record_eval` both `-> AppendResult`), `:76` (`GraphStore.merge(delta) -> MergeReport`, "the only projection write path — §6.2"), `:75` (`in_edges`, correctly attributed to the separate B2 amendment, not this gate) |
| 2 | Specify episode/attempt-id generation, durability across restart, and reuse on literal retry; name owner + tests | **Closed for what round 2 asked** (restart-durability + retry-reuse), **but see §1/§3/§7 below for a distinct, narrower granularity gap the fix itself surfaces | `DATA-LAYER.md:171` (durability contract: minted once at work-unit creation, persisted to truth before work runs, attempt index from the *persisted count* of prior attempts, retries "read... from the durable work-unit row," ownership stated, `test_occurrence_id_stable_across_restart` + `test_retry_reuses_occurrence_id` named) |
| 3 | State explicitly whether `record_eval` also returns `AppendResult` | **Closed** | `DATA-LAYER.md:54` |
| 4 | Give the reconciled single truth event a concrete schema | **Closed** | `DATA-LAYER.md:184-190` (`skill_merge{survivor_id, absorbed_id, evidence_union, graph_ops, provenance}`, explicit `# replayed by rebuild_state` / `# replayed by rebuild_graph` annotations) |
| 5 | Bound the shadow-copy cost; batch/coalesce; tie to the M1 tier-flip trigger | **Closed** | `DATA-LAYER.md:202` (O(\|V\|+\|E\|) time, transient 2× memory, coalesced to "one `merge()` per §6 loop tick," explicitly named as "an explicit, measurable additional trigger for the §9 M1 flip") |

All five items are genuinely and concretely closed as originally framed — this is real progress, not restated prose. The hunt below is for what round 3's own fixes newly expose.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 74 | acceptable |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 68 | weak |
| 4 | Implementability | 67 | weak |
| 5 | Safety / integrity (CRITICAL) | 80 | pass |
| 6 | Efficiency / cost | 84 | pass |
| 7 | Completeness | 65 | weak |
| 8 | Consistency | 62 | weak |
| 9 | Calibration / honesty | 77 | acceptable |

## Findings by dimension

### 1. Correctness

**The round-2 durability gap is genuinely fixed, but the fix introduces a granularity mismatch between what the hash covers and what "attempt" is defined over.** `DATA-LAYER.md:171` defines the attempt index as "derived from the **persisted count** of prior attempts for that `(episode, item)` in TruthStore" — i.e., attempt-counting is scoped **per single item**. But §6.1's occurrence-provenance tuple itself (`DATA-LAYER.md:165`, `episode/trace id + checkpoint_id + attempt index`) has no `item` component, and the established `evals` schema it must key (`DATA-LAYER.md:137`: `evals(id, ts, skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id)`) is a **single row spanning a batch of `item_ids`**, not one row per item. If "attempt index" genuinely increments per `(episode, item)`, a single `Eval.score()` call over a multi-item `held_out @ rotating_sample` batch (`ALGORITHM-v0.2-pathway-learner.md:81`) would need either (a) one shared attempt-index value for the whole batch (in which case "per `(episode, item)`" is the wrong description), or (b) a separate occurrence id *per item inside one eval row* (in which case the hash's granularity no longer matches the record it identifies — one `evals` row would need N occurrence ids, one per item). Neither is stated. This is a real, load-bearing ambiguity for exactly the same reason round 1/round 2's gaps were: it determines whether a genuine repeat batch-eval (same items, new episode) is correctly counted once or is mis-split/mis-merged.

This granularity choice is not academic: `HUMAN-LEARNING-VERIFIER.md:35` establishes per-**item** `attempts` as a first-class behavioral signal (`P(correct, response_time, hints_used, attempts | competence, item)`), confirming the per-item reading is intentional *somewhere* in the design — but §6.1/§6.2 never states whether the TruthStore evidence record this section governs is scoped at that same per-item granularity or at the batched-eval-row granularity established at `DATA-LAYER.md:137`. A developer implementing `record_eval` would have to guess which.

**Secondary, structural correctness issue (see also Consistency/Red-team below): the claim that `merge()` is "the only projection write path" (`DATA-LAYER.md:76`) is not actually achievable for two of the four operations `g.step` performs every loop tick.** `ALGORITHM-v0.2-pathway-learner.md:131-133` runs `g.maybe_merge()`, `g.prune_orphans()` ("retire live skills with no progress"), and `g.decay_edges()` ("prereq-edge confidence decays") as three sibling calls inside the same `g.step`, all under "growth (§5.1)" — the exact scope `DATA-LAYER.md:181` says is two-phased through `merge()`. But `GraphDelta`'s schema (`DATA-LAYER.md:195-198`) has only `adds: [Node]`, `edges: [Edge]`, `merges: [(survivor,absorbed)]`, and a **singular** `provenance: truth_event_id` — there is no field to express "retire this existing node" or "update this existing edge's confidence in place," and the canonical Graph node-status enum itself (`DATA-LAYER.md:140`: `status: live|pending_human`) has **no `retired` value at all** to hold what `prune_orphans` would even produce. So either `prune_orphans`/`decay_edges` bypass the declared "only projection write path" (contradicting `:76`), or they are silently unspecified. This is not a hypothetical — it is the literal, unavoidable consequence of `GraphDelta`'s stated field list against `g.step`'s stated behavior.

### 2. Design faithfulness

The reconciled semantic-merge event (`DATA-LAYER.md:184-190`) and the RC-3 liveness-ordering statement (`:183`) remain faithful to `ALGORITHM-v0.2-pathway-learner.md:127-131` (`provision_suite` invariant, `g.maybe_merge()`'s hysteresis) — this is unchanged good news from round 2.

New faithfulness gap (same root cause as Correctness #2 above): `DATA-LAYER.md`'s §6.2 claims coverage of "growth (§5.1 of the algorithm)... writes" (`:181`) but does not model `g.prune_orphans()`/`g.decay_edges()` (`ALGORITHM-v0.2-pathway-learner.md:132-133`), which are named, load-bearing halves of §5.1's own inverse pattern (P2: "every `add` has an inverse"). A section whose stated job is "growth's writes, made safe" that is silent on 2 of `g.step`'s 4 sub-operations is a faithfulness shortfall, not just an implementation gap — it doesn't just under-specify a detail, it under-covers the scope it names for itself.

### 3. Red-team resistance

**RC-3 (unscorable growth) — remains closed**, per round 2's finding, unaffected by anything new this round.

**RC-4 (add-only ratchet) — a new, narrower residual, distinct from round 1/round 2's double-merge-mechanism concern (which is now closed).** RC-4's patch (`ALGORITHM-v0.1-redteam.md:51-53`) is explicitly "give every `add` an inverse — periodic merge... **prereq edges soft/probabilistic/decaying**... **orphan pruning**... tree GC." Round 3's `GraphDelta`/`MergeReport` schema handles the *merge* inverse concretely and safely (atomic swap, dedup-by-identity, failure contract — genuinely good). It does **not** show how the *prune* and *decay* inverses reach the store safely: no schema field, no status value, and (per Correctness #2) no stated write path at all. If a later implementer wires `prune_orphans`/`decay_edges` as **direct, unbatched writes to `GraphStore`** outside `merge()` (the only concrete path this section actually specifies), those writes lose the shadow-copy/atomic-swap guarantee `:202` builds specifically for the embedded tier — reintroducing exactly the kind of unprotected, non-transactional structural mutation RC-4's patch was written to close, just for the two inverse operations this revision happens not to cover. This is a residual attack/ambiguity surface, not a re-fired failure mode (nothing today demonstrably breaks), which keeps this at "weak," not "blocking" — but it is squarely inside RC-4's named scope and unaddressed by three rounds of revision so far.

### 4. Implementability

Concrete round-3 positives: the durability contract (`:171`) gives a developer a mintable, testable rule for the *restart* case; `record_eval`'s return type is unambiguous (`:54`); the `skill_merge` schema (`:184-190`) is buildable as stated.

Remaining/new gaps a developer would have to resolve by guessing:
- **No schema for the "durable work-unit row"** that `:171` says occurrence ids are "persisted to truth" into and later "read... from" on retry. `schemas.py`'s stated delta (`:177`) only adds `identity_hash` (+ provenance fields) to existing evidence records — there is no named event/table for the pre-work "work-unit created" row itself, nor a stated key (work-unit id? job id?) that survives a process restart so a retry can find "its" row. Without this, `test_occurrence_id_stable_across_restart` has no concrete fixture to assert against.
- **The `(episode, item)` attempt-index granularity vs. the batched `evals` row** (Correctness #1) is a direct build-ambiguity: an implementer cannot write `record_eval` without deciding this first, and the spec doesn't decide it for them.
- **`GraphDelta` has no update/retire path** (Correctness #2 / Design faithfulness): a developer tasked with implementing `prune_orphans`/`decay_edges` against this port has nothing to build against.
- **The two `self_modify`-style test lists remain split across §6.1 and §6.2.** `:171`'s regression pair (`test_occurrence_id_stable_across_restart`, `test_retry_reuses_occurrence_id`) is stated inline in §6.1 and is not folded into §6.2's consolidated "Tests (for the eventual build)" enumeration at `:208` — a minor but real discoverability gap for whoever builds the test suite from this doc (nine tests are listed at `:208`; the other two exist only in prose two subsections earlier).

### 5. Safety / integrity

The core safety story from round 2 (idempotent dedup closing the under-count risk; `StateStore` double-keyed by evidence id as defense-in-depth, `:173`) is unchanged and still sound — no §8 gate clause, §14 formula, or verifier admission rule is touched.

New, second-order concern (not a direct gate weakening, hence not scored below "pass"): if `prune_orphans`/`decay_edges` end up implemented outside the one atomic `merge()` path (Correctness #2 / Red-team #3), a reader of the graph mid-write (e.g. `reach_weight` computing soft reachability for `choose()`, `ALGORITHM-v0.2-pathway-learner.md:145,160`) could observe a partially-applied prune/decay — the exact "reader never observes a half-applied delta" property `:202`'s atomic-swap design and `test_embedded_merge_atomic_swap` (`:208`) exist to guarantee, but only for adds/edges/merges, not prune/decay. This is integrity-adjacent (data consistency feeding a downstream policy decision) rather than a gate/calibration weakening, which is why it doesn't pull this dimension below "acceptable."

### 6. Efficiency / cost

Round 2's flagged gap is genuinely and concretely closed: `O(|V|+|E|)` time / transient 2× memory is stated, coalescing to one `merge()` per loop tick is specified, and the cost is explicitly tied to the §9 M1 `graph→neo4j` flip trigger (`DATA-LAYER.md:202`) as an additional, quantified reason to flip. No new efficiency concern surfaces this round — the coalescing strategy is architecturally sound for the operations it covers (adds/edges/merges). Scored "pass."

### 7. Completeness

Improvements: the durability regression pair (Completeness gap from round 2) now exists (`:171`), even if not consolidated into one list (Implementability, above).

Residual/new gaps:
- **No test exercises the `(episode, item)` batched-eval granularity question** (Correctness #1) — none of the eleven named tests (nine at `:208`, two at `:171`) touches multi-item eval batches at all.
- **No schema/status value for `prune_orphans`/`decay_edges` outputs**, and correspondingly no test analogous to `test_embedded_merge_atomic_swap` (`:208`) that would catch a non-atomic prune/decay write (Correctness #2 / Red-team #3).
- **No schema for the durable work-unit row** (Implementability, above) that the durability contract depends on.

### 8. Consistency

**A new instance of the exact class of defect round 2 caught and closed at §2.1: a canonical section left stale relative to §6.1's own stated port delta — this time it is §5, not §2.1.** `DATA-LAYER.md:177` states "`schemas.py` records gain `identity_hash` (+ its provenance fields)," but §5 ("Record schemas — what lives where," the document's own canonical schema listing per its header at `:135`) is **unchanged**: the `evals` row at `:137` still lists only `(id, ts, skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id)` — no `identity_hash`, `episode_id`, or `attempt_index` column — and the Graph node schema at `:140` still lists `status: live|pending_human` with no `retired` value, despite `g.prune_orphans()` needing exactly that (Correctness #2). Round 2 closed this failure mode for §2.1 (the ports); the same failure mode recurred, uncaught, at §5 (the schemas) in the very revision meant to close the class of issue.

**`GraphDelta.provenance` is a singular `truth_event_id` (`:198`), but the round-3-added coalescing claim ("one `merge()` per §6 loop tick," `:202`) implies **multiple** originating truth events (potentially several `new_skill`/`provision_suite` growth events plus a `skill_merge` event) are batched into one `merge()` call. A single scalar provenance field cannot reference multiple originating events, so either the coalescing claim (new this round) or the provenance schema (unchanged since round 2) is wrong — they were not checked against each other when the coalescing text was added.

### 9. Calibration / honesty

The round-2 self-critique pattern (naming round 1's own defect plainly, `:169`) is preserved and still commendable. This round's revision, however, does not extend that same rigor to its **own** new claims: `:76`'s "the only projection write path" is stated flatly, without the hedge that two of `g.step`'s four operations (prune, decay) are not shown to go through it — a claim the section itself cannot yet back (Correctness #2). Compare to `:169`'s explicit "Round 1... would have silently under-counted..." framing — this round doesn't apply the same self-audit to the prune/decay gap or the granularity ambiguity, both of which a careful re-read of the section's own cross-references (§5.1's `g.step`, §5's own schemas) would have surfaced. Scored "acceptable," not "strong," for this reason — the honesty bar set by rounds 1–2 slipped slightly here.

## Strongest adversarial objection

**Round 2's over-counting objection was narrowed, not closed — it moved from "unspecified" to "specified-but-unenforced."** Round 2's adversarial pass argued that the fix trades under-counting for a symmetric over-counting risk if a retry harness mints a fresh trace id per call instead of reusing the original. Round 3's answer (`DATA-LAYER.md:171`) is real progress: it names the owner (the §6 orchestrator), states the mechanism (mint once at work-unit creation, persist before work runs, retries read from the durable row), and asserts "there is no 'fresh trace id per call' path to misuse... a retry harness that minted one would fail the regression tests below." But look at what actually backs that assertion: nothing in the `TruthStore` port (`append_event(ev: Event) -> AppendResult`, `:53`) validates, at write time, that an incoming event's `occurrence_provenance` corresponds to a real, previously-persisted work-unit row — there is no foreign-key-style check, no schema constraint, nothing the store itself can refuse. The guarantee is **entirely a discipline convention plus a pair of unit tests**, not a structural/type-level barrier. That is a materially weaker claim than the confident language around it ("has no API to invent provenance") suggests: any future code path that doesn't happen to route through the one orchestrator implementation exercised by `test_retry_reuses_occurrence_id` — a bulk backfill script, an out-of-band curator re-digestion job (explicitly named as an intended dedup case at `:169`), or simply a second ingestion entry point added by a future engineer who doesn't know the convention — can silently re-mint a fresh id per call and reopen round 1's original over-counting failure with **no test, no schema, and no runtime check to catch it**, because the only thing standing between "reuse the id" and "mint a new one" is that one code path's own discipline. Three rounds in, the round-1-era over-counting/under-counting risk has been narrowed twice but has never actually been closed by anything the `TruthStore` port itself can enforce — it has only ever been closed by prose and a matching test for the one call site the authors had in mind.

## Aggregate confidence

```
critical_floor  = min(Correctness=74, RedTeam=68, Safety=80) = 68
weighted_mean   = (74*2 + 80 + 68*2 + 67 + 80*2 + 84 + 65 + 62 + 77) / 11
                = (148 + 80 + 136 + 67 + 160 + 84 + 65 + 62 + 77) / 11
                = 879 / 11
                = 79.9 → 80
overall         = min(68, 80) = 68
```

**Overall confidence: 68 / 100**

## Verdict

**needs-revision**

All five round-2 items are genuinely closed (see the closure table above) — this round made real progress on exactly what it targeted. The verdict remains `needs-revision` because Red-team resistance (68) is below 70 (CRITICAL floor), driven by gaps this round's own fixes newly expose rather than by anything from round 1/2 recurring unaddressed:

1. **Specify the granularity of "attempt index."** State explicitly whether occurrence-identity is scoped per `(episode, item)` or per batched `evals` row (`DATA-LAYER.md:137`), and reconcile that choice with the occurrence-provenance tuple at `:165` (which has no `item` component) and with `HUMAN-LEARNING-VERIFIER.md:35`'s per-item `attempts` signal.
2. **Give `prune_orphans` and `decay_edges` (`ALGORITHM-v0.2-pathway-learner.md:131-133`) a concrete write path.** Either extend `GraphDelta` (`DATA-LAYER.md:195-198`) with fields to express node-retirement and in-place edge-confidence updates and add a `retired` value to the Graph node-status enum (`:140`), or explicitly state that these two operations use a different, equally-atomic mechanism — but do not leave `:76`'s "the only projection write path" claim covering operations the schema cannot represent.
3. **Update §5's "Record schemas" section** (`DATA-LAYER.md:135-142`) to reflect the `identity_hash`/occurrence-provenance fields §6.1 adds to `schemas.py` (`:177`) — the same class of staleness round 2 caught and fixed at §2.1 has recurred at §5 in this very revision.
4. **Reconcile `GraphDelta.provenance`'s singular `truth_event_id` field with the new coalescing claim** ("one `merge()` per §6 loop tick" batching potentially several growth events) — either make `provenance` a list or state how one call is attributed to one event.
5. **Specify a schema (or explicit event type) for the durable "work-unit row"** the §6.1 durability contract depends on, so `test_occurrence_id_stable_across_restart` has a concrete fixture to assert against.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-51","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r3.md","why":"360 review (round 3) of DATA-LAYER.md §6.1/§6.2 revised r3 — overall 78 -> 68/100, needs-revision (RedTeam CRITICAL 68 <70): all 5 round-2 items genuinely closed, but the fixes surface new gaps — attempt-index granularity mismatch vs the batched evals row, GraphDelta/node-status schema cannot represent prune_orphans/decay_edges despite merge() being declared the only projection write path (RC-4 residual), §5's Record schemas section left stale relative to §6.1's own port delta (recurrence of the class of defect round 2 caught at §2.1), and GraphDelta's singular provenance field conflicts with the new per-tick coalescing claim","evidence":["docs/research/DATA-LAYER.md §5 (lines 135-142), §6.1/§6.2 (lines 158-208)","docs/research/reviews/DL-write-discipline-review-r2.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §5.1 (lines 117-133), §5.2, §5.3","docs/research/ALGORITHM-v0.1-redteam.md RC-3/RC-4 (lines 46-53)","docs/research/HUMAN-LEARNING-VERIFIER.md:35"],"outcome":"pending"}
```
