# 360 Review: DL-write-discipline — 2026-07-13 (Round 4)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 158–177) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 179–211), both marked *revised r4 — IN GATE* |
| Proposed change | Round-4 rewrite closing round 3's five findings: `GraphDelta`/`MergeReport`/the Graph node-status enum are extended with `retires`/`edge_updates`/`retired` so `g.prune_orphans`/`g.decay_edges` have a concrete write path; §5's `events`/`evals` schemas gain `identity_hash`+`episode_id`/`checkpoint_id`/`attempt_idx` columns; the work unit is declared to be the eval run (aligning attempt-index granularity with the batched `evals` row); `GraphDelta.provenance` becomes a list to match per-tick coalescing; and the retry-id-reuse guarantee is claimed to be enforced structurally at the `TruthStore` port (rejecting events with no matching persisted work-unit row) rather than by test discipline alone. |
| Reviewer | review-360 |
| Round | 4 (`-r4`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `docs/research/reviews/DL-write-discipline-review-r2.md` (78/100); round 3: `docs/research/reviews/DL-write-discipline-review-r3.md` (68/100, 5 items left) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Round-3 items — verification of closure

| # | Round-3 item | Verdict | Evidence |
|---|---|---|---|
| 1 | Specify the granularity of "attempt index" (per-`(episode,item)` vs. batched `evals` row) | **Closed** | `DATA-LAYER.md:171` — "The work unit is the eval run (matching the batched `evals` row over `item_ids` — §5; not per-item, so the granularities agree)"; `attempt_idx` is now explicitly scoped to `(episode, suite)`, not `(episode, item)`. `HUMAN-LEARNING-VERIFIER.md:35`'s per-item `attempts` is a separate behavioral-likelihood signal (§2.2 of that doc), not the TruthStore occurrence-identity primitive — the naming overlap ("attempt") is a minor cross-document terminology nit, not a structural conflict, now that §6.1 states its own scope unambiguously. |
| 2 | Give `prune_orphans`/`decay_edges` a concrete write path | **Closed** | `DATA-LAYER.md:195-201` (`GraphDelta` gains `retires: [node_id]`, `edge_updates: [(edge_id, confidence)]`; `MergeReport` gains `retired: [id]`, `updated: [id]`); `DATA-LAYER.md:140` (Graph node `status` enum gains `retired`, annotated "realizes `g.prune_orphans`'s inverse at the store"); `:193` states the rationale ("a write path that could express `add` but not `retire`/`decay` would force §5.1's inverse operations to bypass the atomic-swap guarantee"). This is a real, concrete fix — RC-4's residual from round 3 is closed at the schema level. |
| 3 | Update §5's "Record schemas" to reflect `identity_hash`/occurrence fields | **Closed** | `DATA-LAYER.md:137` — `events(id = identity_hash, ts, type, payload, actor, episode_id, checkpoint_id, attempt_idx)`; `evals(id = identity_hash, ..., episode_id, attempt_idx)`, annotated "delta gated with §6.1." The staleness class round 2 caught at §2.1 and round 3 caught again at §5 does not recur a third time. |
| 4 | Reconcile `GraphDelta.provenance`'s singular field with the per-tick coalescing claim | **Closed** | `DATA-LAYER.md:200` — `provenance: [truth_event_ids]  # list — one delta per tick coalesces many events`. Direct, correct fix. |
| 5 | Specify a schema (or explicit event type) for the durable "work-unit row" | **NOT closed — see Correctness/Implementability below.** | `DATA-LAYER.md:171` refers to "the work-unit row" four times in prose ("persists the work-unit row to truth," "reads its occurrence id from the durable work-unit row," "an event... references no persisted work-unit row") but never defines its fields, its own id scheme, which store/table holds it, or which port method creates it. `schemas.py`'s only stated delta (`:177`) is "records gain `identity_hash` (+ its provenance fields)" — a delta to *existing* record types (events/evals), not a new schema for the work-unit row itself. This item is the one round-3 finding this revision does not close; it is silently left open rather than explicitly deferred with a stated reason, and — as detailed below — it is now load-bearing for a much stronger claim ("structurally enforced... not by convention") than round 3's prose-only guarantee, which makes leaving it unspecified a materially bigger problem this round than it was last round. |

**Round-3's own adversarial objection** ("the retry-id-reuse guarantee is enforced only by convention + a matching test, not by anything the `TruthStore` port itself can check") is **addressed in direction, not in substance**: `:171` now asserts a port-level rejection mechanism and names `test_unregistered_occurrence_rejected`. But because the mechanism it rests on (item 5, above) has no schema or write path, the new claim cannot yet be verified as true — see Correctness/Red-team/Implementability findings below, which supersede round 3's adversarial objection with a sharper, round-4-specific version of the same underlying concern.

No round-1 or round-2 item shows any regression this round (§2.1's `Protocol` block, `record_eval`'s `AppendResult` return, the `skill_merge` schema, and the shadow-copy cost bound are all still intact and consistent with §6.1/§6.2 as revised — `DATA-LAYER.md:52-56,76,184-190,204`).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 64 | weak |
| 2 | Design faithfulness | 78 | acceptable |
| 3 | Red-team resistance (CRITICAL) | 66 | weak |
| 4 | Implementability | 55 | weak |
| 5 | Safety / integrity (CRITICAL) | 76 | acceptable |
| 6 | Efficiency / cost | 83 | pass |
| 7 | Completeness | 60 | weak |
| 8 | Consistency | 58 | weak |
| 9 | Calibration / honesty | 60 | weak |

## Findings by dimension

### 1. Correctness

**The granularity fix is genuinely correct** (round-3 item 1, closed — see table above).

**A new, self-contained schema contradiction is introduced by this very revision.** `AppendResult` is defined identically, three times, as a strict two-field record: `DATA-LAYER.md:53` (`# {id, deduped} — §6.1`), `:173` ("returns `AppendResult{id, deduped: bool}`"), and `:177` ("`TruthStore.append_event(ev) -> AppendResult{id, deduped}`"). But `:171`'s new port-rejection claim requires a *third* outcome — "`append_event`/`record_eval` **reject** an event... (`AppendResult` error)" — that none of the three declared shapes of `AppendResult` can represent. `{id, deduped: bool}` has no field for "rejected" versus "accepted-fresh" versus "accepted-deduped," and no error/exception variant is named anywhere in the document. This is not a stylistic gap; it is a literal type-shape contradiction inside the same section revision, of the same class round 2 caught at the §2.1/§6.1 boundary and round 3 caught at the §5/§6.1 boundary — except this time it is internal to §6.1 itself, introduced by the very sentence that makes the round's headline claim.

**The mechanism the headline claim depends on has no schema, no write path, and an unresolved bootstrap question.** `:171`'s claim — "the over-counting path is closed by the store itself, not by test discipline" — requires that *some* write operation persists the first, canonical "work-unit row" for a brand-new occurrence, and that `append_event`/`record_eval` can check an incoming event's occurrence-provenance against it. But:
- §2.1's `TruthStore` `Protocol` (`DATA-LAYER.md:52-56`) lists exactly four methods — `append_event`, `record_eval`, `read_events`, `lineage` — none named `create_work_unit`, `begin_episode`, or similar. There is no port method whose stated job is "persist a new work-unit row."
- If work-unit-row creation is itself implemented as a call to `append_event` (the only write method available), then the very first `append_event` call for a genuinely new occurrence would, by `:171`'s own rule, need to reference "a persisted work-unit row" that does not yet exist — either this creation call is a special-cased exemption from the reference check (unstated), or it is circular. Neither resolution is written down.
- If, instead, work-unit-row creation is a *separate*, unenumerated primitive outside `append_event`/`record_eval` entirely, then that primitive is — by construction — **not** covered by the port-level rejection check the section is built around, meaning there **is** an unenforced entry point for minting occurrence identifiers (exactly the round-3 adversarial concern), just relocated from "some future ingestion path" to "the one call every occurrence must ultimately pass through first."

Either reading leaves the section's central, most-confidently-stated claim (`:171`, "structurally enforced at the port, not by convention") unverifiable as written. This is a Correctness finding, not merely an Implementability one, because the claim is stated as true and is not yet shown to be true under either of its two plausible resolutions.

**Does it hold on the embedded tier? Not demonstrably.** §6.2 states a specific, careful atomicity mechanism for the embedded (`networkx`) tier — shadow copy + atomic swap under "a single writer lock" (`DATA-LAYER.md:204`) — but that guarantee is scoped explicitly to `GraphStore.merge()`. Nothing analogous is stated for `TruthStore`'s work-unit-row creation on the embedded (SQLite) tier. `attempt_idx` is defined as "derived from the **persisted count** of prior runs for that `(episode, suite)`" (`:171`) — a classic read-count-then-insert sequence that races if two work-unit creations for the same `(episode, suite)` are ever in flight concurrently (e.g., a retry issued while the original is still running, or concurrent §18 fleet agents sharing one embedded process before the "multi-process fleet requires the full tier" constraint at `:204` applies — that constraint is about `GraphStore`, not `TruthStore`). No lock, transaction, or uniqueness-constraint discipline is stated for this specific sequence on either tier. The single-process nature of the embedded tier (§3) makes this *unlikely* to be exercised by the intended single-threaded main loop, but "unlikely by intended usage" is exactly the informal-discipline standard round 3's adversarial pass rejected as insufficient for the over-counting/under-counting guarantee — the spec doesn't rule the race out, it simply doesn't discuss it.

### 2. Design faithfulness

The `retires`/`edge_updates`/`retired`-status additions (`DATA-LAYER.md:140,195-201`) are now faithful to `ALGORITHM-v0.2-pathway-learner.md:131-133`'s three sibling `g.step` operations (`maybe_merge`/`prune_orphans`/`decay_edges`) and to P2's "every add has an inverse" (`ALGORITHM-v0.2-pathway-learner.md:9`) — this closes round 3's design-faithfulness gap cleanly.

One faithfulness strength worth surfacing that the document itself does not claim credit for: the "§6 orchestrator" that `:171` makes the sole minter of occurrence ids is explicitly part of **JUDGE**, not SOLVE (`ALGORITHM-v0.2-pathway-learner.md:455`: "the **§6 orchestrator loop** that runs SOLVE and calls JUDGE" is listed as JUDGE-immutable). That means a `self_modify` candidate cannot rewrite who is allowed to mint occurrence ids — a genuine, unforced alignment with §17.1's SOLVE/JUDGE wall. `DATA-LAYER.md` never states this cross-reference, so a reader of the data layer alone cannot see why the orchestrator is trustworthy as sole minter; citing §17.1 explicitly would strengthen both the design-faithfulness and the safety story materially. This is a missed opportunity, not a defect, so it does not lower the score, but is worth a line in the next revision.

### 3. Red-team resistance

**RC-3 (unscorable growth) — remains closed**, unaffected by this round's changes.

**RC-4 (add-only ratchet) — the round-3 residual (no write path for prune/decay) is genuinely closed** (see closure table, item 2). This is real progress.

**A narrower, round-4-specific reopening of the RC-1-adjacent over/under-counting concern, via the unresolved bootstrap gap (Correctness, above).** Round 1 found systemic under-counting; round 2/3 narrowed it to a restart-collision edge case and then to "enforced by convention only." Round 4's fix *claims* to close the convention-only gap with a structural, port-level check — but because the check's own foundation (the work-unit row's schema and creation path) is unspecified, the residual attack surface has not shrunk to zero, it has shrunk to exactly the one call that creates a work-unit row for a genuinely new occurrence. If that call turns out to be an unchecked, separate primitive (one of the two readings identified under Correctness), it is now the *single* place where a bug or an out-of-band tool (a bulk backfill script, a re-digestion job that — unlike ordinary re-digestion of an *existing* occurrence, `:169` — needs to register a occurrence that has no prior work-unit row, e.g. importing historical data) could mint an arbitrary, attacker- or bug-chosen `(episode_id, checkpoint_id, attempt_idx)` tuple with no port-level check to catch it, because the port-level check only fires on the *reference*, never on the *creation*. This is narrower than round 1's modal-case failure and narrower even than round 3's "any future ingestion path" framing, but it is a real, currently-unclosed residual, not a re-fired root cause — hence "weak," not "blocking."

### 4. Implementability

Concrete round-4 positives: `GraphDelta`/`MergeReport`'s new fields (`:195-201`) are buildable as stated; the granularity decision (`:171`) removes an ambiguity a developer previously had to guess at; §5's schema additions (`:137`) are concrete, typed columns.

Remaining/new gaps a developer cannot resolve without guessing:
- **No schema for "the durable work-unit row"** (Correctness, above) — a developer implementing `test_occurrence_id_stable_across_restart` or `test_unregistered_occurrence_rejected` has no concrete table/record to construct a fixture from, and no stated primary key or lookup index the "reference check" would query against.
- **No port method to create it.** §2.1's `TruthStore` `Protocol` (`:52-56`) is unchanged this round and still has no method for it — a developer building strictly from §2 (the document's own canonical port listing, per its own header at `:26`) has nothing to call.
- **`AppendResult`'s rejection case has no type.** Is a rejection a raised exception, a third enum value, a `None` return, or a boolean flag added to the existing two-field record? `:171`'s parenthetical "(`AppendResult` error)" is the only hint, and it contradicts the record's own declared shape (Correctness, above) rather than resolving it.
- **The two per-section test lists remain split**, as round 3 noted for a different reason: `test_unregistered_occurrence_rejected` (new this round) is stated only in §6.1's prose (`:171`) and is not folded into §6.2's consolidated "Tests (for the eventual build)" enumeration at `:210` — the same minor discoverability gap round 3 flagged for the other two §6.1 tests, now with a third test added to the same un-consolidated spot.

### 5. Safety / integrity

No §8 gate clause, §14 formula, or §19 calibration knob is touched — structurally clean, as in every prior round.

**New, second-order integrity concern:** the fix trades a *soft* failure mode (silent dedup/under-count, rounds 1–3) for a *hard* one (outright rejection) at exactly the point where genuine work has already been performed — an eval run has consumed real compute and drawn real `held_out @ rotating_sample` items (`ALGORITHM-v0.2-pathway-learner.md:81`) by the time `record_eval` is called. `:171` states the rejection ("`AppendResult` error") but nothing states what happens to that already-completed, real evidence afterward: is it retried automatically, queued, logged as an incident, or silently dropped by whatever caller receives the error? A rejection that is not itself observably handled converts a **counting** bug into a **data-loss** bug — worse for the exact statistical machinery (§9's `sustained_heldout`, §17.3's monitored-subset check, §19.1's `r̂`/`q_explore`) this whole line of revisions exists to protect, because a dropped occurrence isn't merely mis-attributed, it's gone. This is integrity-adjacent (data completeness feeding downstream statistics) rather than a direct gate/calibration weakening, which is why it doesn't pull this dimension below "acceptable" — but it is a genuinely new risk this round's own fix introduces and does not discuss.

### 6. Efficiency / cost

Unaffected and still sound: `O(|V|+|E|)` shadow-copy cost, coalesced to one `merge()` per loop tick, tied to the §9 M1 flip trigger (`DATA-LAYER.md:204`) — no regression, no new hot-path cost. The only new efficiency-adjacent question (the possible read-count-then-insert contention on work-unit creation, Correctness above) is a correctness/concurrency concern, not a cost concern, since it would occur at most once per occurrence, not per merge. Scored "pass," marginally below round 3's 84 only because the work-unit-row mechanism's absence of a stated index/lookup structure leaves its own cost (is the "persisted count of prior runs" query indexed, or a table scan per new occurrence?) formally unbounded, mirroring the pre-round-2 "transactional is asserted, not specified" pattern for a different operation.

### 7. Completeness

Improvements: `test_unregistered_occurrence_rejected` is a genuinely useful new regression test name, addressing part of round 3's completeness gap.

Residual/new gaps:
- **No test — indeed no way to write one yet — for the durable work-unit row's own creation path**, its restart-survival guarantee at the point of creation (as opposed to at the point of a later reference), or the bootstrap case (Correctness/Implementability, above).
- **No test for what happens after a rejection** (Safety, above) — none of `:171`'s three named tests nor `:210`'s nine cover the caller-side handling of an `AppendResult` error.
- **Still no test analogous to `test_embedded_merge_atomic_swap` for the new `retires`/`edge_updates` fields** — the round-3 completeness gap ("no test would catch a non-atomic prune/decay write") is only half-closed: the schema now exists, but no test targets it specifically; the existing atomic-swap test's scope (`:210`) is not stated to cover the new fields.

### 8. Consistency

**The `AppendResult` three-way contradiction (Correctness, above) is itself the headline consistency defect this round** — the same class of defect (a canonical declaration left stale relative to prose introduced in the same revision) that round 2 caught at §2.1 and round 3 caught at §5, now recurring a third time, this time *within* §6.1 itself rather than across sections. Three explicit statements of `AppendResult`'s shape (`:53,173,177`) as a strict `{id, deduped}` pair are contradicted by one new sentence (`:171`) that requires a third outcome.

Otherwise, this round's changes are internally consistent: `GraphDelta`/`MergeReport`'s new fields (`:195-201`) correctly mirror each other (`retires`↔`retired`, `edge_updates`↔`updated`); §5's schema additions (`:137`) match the `identity_hash`/provenance fields §6.1 requires; the `provenance` list fix (`:200`) matches the per-tick coalescing claim (`:204`). No new instance of the §2.1-vs-§6 staleness class recurs.

### 9. Calibration / honesty

The round's central sentence overclaims relative to what the section actually specifies: "**Structurally enforced at the port, not by convention**" (`:171`) is stated as an accomplished fact, but (per Correctness/Implementability above) the mechanism that would make it true — a schema and a write path for the work-unit row — does not exist in this document. This is a sharper instance of the same pattern round 3 flagged ("this round's revision does not extend [round 1/2's self-critique] rigor to its own new claims"): the confident, closing-the-loop language ("closed by the store itself, not by test discipline") is exactly the register that should be reserved for a claim the section can actually back, and round 3 already warned that this specific claim (retry-reuse enforcement) had previously been "closed... only by prose and a matching test." Round 4 restates the same confidence with a new mechanism named but not built. This is a real slip relative to rounds 1–2's more careful self-auditing, and it is the second round running (after round 3's slip on `:76`'s "only projection write path" claim) where a headline claim outruns its own specification.

## Strongest adversarial objection

**A rejected append is a strictly worse failure mode than the one this whole line of revisions was built to close, and the spec never notices.** Every round of this gate — 1 through 4 — has framed the central risk as a *counting* problem: does a given occurrence get counted zero times (under-count, round 1's original finding), twice (over-count, round 2/3's adversarial objection), or exactly once (the goal)? Round 4's fix reframes the over-counting side of that problem as a **hard port-level rejection** (`DATA-LAYER.md:171`: `append_event`/`record_eval` "reject an event whose occurrence provenance references no persisted work-unit row"). But a rejection is not a form of correct counting — it is a **third, worse outcome** the spec has never modeled: real work already performed (compute spent, held-out items drawn, an outcome observed) is refused entry to the canonical, append-only truth log entirely. Unlike round 1's under-counting (where at least the *first* occurrence was recorded) or round 2/3's over-counting (where the evidence existed, just attributed twice), a rejected append leaves **zero trace of a real event that happened** — worse for `sustained_heldout` (§9), the Stage-1 monitored subset (§17.3), and `r̂`/`q_explore` (§19.1) than either of the failure modes the last three rounds fought over, because those mechanisms can tolerate noise in *counting* far better than silent, undetectable *loss*. And this is not a hypothetical edge case invented for this review: the rejection path fires precisely whenever the (unspecified — see Correctness) work-unit-row bookkeeping is even slightly out of sync with what the store considers "persisted" — a process restart at the wrong instant, a retry issued a beat before the original work-unit row's write is confirmed durable, or (per Red-team, above) any legitimate ingestion path that doesn't happen to pre-register a work-unit row the way the one intended orchestrator call does. None of the three regression tests named this round (`test_occurrence_id_stable_across_restart`, `test_retry_reuses_occurrence_id`, `test_unregistered_occurrence_rejected`) tests what happens to the real evidence *after* a rejection — they test that the rejection fires, not what it costs. A design that would rather silently destroy real evidence than risk miscounting it has not obviously made the safer trade, and nothing in this round's revision, or in any of the nine dimensions scored above in isolation, weighs that tradeoff explicitly.

## Aggregate confidence

```
critical_floor  = min(Correctness=64, RedTeam=66, Safety=76) = 64
weighted_mean   = (64*2 + 78 + 66*2 + 55 + 76*2 + 83 + 60 + 58 + 60) / 11
                = (128 + 78 + 132 + 55 + 152 + 83 + 60 + 58 + 60) / 11
                = 806 / 11
                = 73.3 → 73
overall         = min(64, 73) = 64
```

**Overall confidence: 64 / 100**

## Verdict

**needs-revision**

Four of round 3's five items are genuinely and concretely closed (attempt-index granularity, the prune/decay write path, §5's schema staleness, and `GraphDelta.provenance`'s list form) — real, verifiable progress. The verdict is `needs-revision`, and the score *fell* from round 3's 68 to 64, because the fifth item (a schema for the durable work-unit row) was left open rather than closed or explicitly deferred, and the round's own new, more confident claim ("structurally enforced at the port, not by convention") is not yet backed by anything the document specifies — it introduces a fresh, self-contained `AppendResult` schema contradiction and leaves the mechanism's bootstrap case unresolved. Both CRITICAL dimensions Correctness (64) and Red-team resistance (66) are below 70.

1. **Specify a concrete schema for the durable "work-unit row"** — its fields (at minimum an id, `episode_id`, `checkpoint_id`/suite ref, `attempt_idx`, a created-timestamp), which store/table holds it, and give it a name in `schemas.py`'s stated delta (`DATA-LAYER.md:177` currently only adds fields to *existing* record types).
2. **State which port method creates the work-unit row**, and resolve the bootstrap case explicitly: either add a new `TruthStore` method (e.g. `begin_occurrence(...)`) to §2.1's `Protocol` (`:52-56`) that is exempt from the reference-check by construction (it *is* the row being referenced), or state precisely how the very first `append_event`/`record_eval` call for a new occurrence is admitted despite `:171`'s stated rule that such calls require a pre-existing persisted row.
3. **Fix the `AppendResult` schema contradiction.** Either add an explicit third state/field (e.g. `AppendResult{id, deduped: bool, rejected: bool, reason: str | None}`) and update all three existing declarations (`:53,173,177`) to match, or specify that rejection is signaled by an exception rather than a return value — but do not leave `:171`'s "(`AppendResult` error)" contradicting the record's own declared two-field shape.
4. **State what happens to real evidence after a rejection** (Safety / adversarial pass, above) — is the caller expected to retry, and if so from what state; is a rejection itself logged as a truth event (mirroring the failure contract already given for `merge()` at `:204`, "the failure is a truth event"); is there a test that a rejected append does not silently disappear without operator visibility.
5. **State explicitly whether the read-count-then-insert sequence for `attempt_idx` (`:171`, "derived from the persisted count of prior runs") is safe from a race under the embedded tier**, or extend the existing writer-lock discipline already specified for `GraphStore.merge()` (`:204`) to cover this `TruthStore` sequence too.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-<n>","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r4.md","why":"360 review (round 4) of DATA-LAYER.md §6.1/§6.2 revised r4 — overall 68 -> 64/100, needs-revision (Correctness 64 and RedTeam 66 both <70): 4 of round-3's 5 items genuinely closed (attempt-index granularity, prune/decay write path, §5 schema staleness, GraphDelta.provenance list), but the 5th (a schema for the durable work-unit row) was left open, and the round's new 'structurally enforced at the port' claim introduces a fresh AppendResult 2-vs-3-field self-contradiction, an unresolved bootstrap question (what write path persists the FIRST work-unit row, and is that call itself occurrence-checked), and an unaddressed embedded-tier race in attempt_idx's count-then-insert derivation","evidence":["docs/research/DATA-LAYER.md §2.1 (lines 52-56), §5 (lines 135-142), §6.1/§6.2 (lines 158-211)","docs/research/reviews/DL-write-discipline-review-r3.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §5.1 (lines 115-141), §6 (lines 177-207), §9 (lines 242-260), §10 (line 266), §17.1 (lines 452-457), §17.3 (lines 462-465), §19.1 (line 562)","docs/research/ALGORITHM-v0.1-redteam.md RC-1 (lines 36-39), RC-4 (lines 51-53)","docs/research/HUMAN-LEARNING-VERIFIER.md:35"],"outcome":"pending"}
```
