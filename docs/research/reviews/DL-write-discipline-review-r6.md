# 360 Review: DL-write-discipline — 2026-07-13 (Round 6)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 159–189) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 191–222), both marked *revised r6 — IN GATE* |
| Proposed change | Round-6 rewrite claiming to close all three round-5 findings: `open_work_unit(episode_id, suite_id, intent_key)` is made idempotent on a caller-independent `intent_key = hash(episode_id, suite_id, tick)`, where `tick` is asserted to be "the §6 loop tick," "persisted before dispatch"; `attempt_idx` derivation is stated to be atomic in-store on both tiers (embedded: "under the §6.2 single-writer lock"); `rejected_ingest` is claimed to retain the full payload, not a hash. |
| Reviewer | review-360 |
| Round | 6 (`-r6`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `-r2.md` (78/100); round 3: `-r3.md` (68/100); round 4: `-r4.md` (64/100); round 5: `-r5.md` (66/100, 5 items left) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Full round 1–5 audit — every numbered item, closed or explicitly carried

| Round | # | Item | Status as of r6 | Evidence |
|---|---|---|---|---|
| 1 | 1 | Occurrence/provenance component in the hash | **Closed (r2), holds** | `DATA-LAYER.md:161-168` — `occurrence_provenance` unchanged in substance |
| 1 | 2 | Missing-repeat-evidence regression test | **Closed (r2), holds** | `test_repeat_measurement_not_deduped`, still listed at `:222` |
| 1 | 3 | Append-only vs. return-existing-on-duplicate | **Closed (r2), holds** | `:185` "idempotence, not upsert" |
| 1 | 4 | Reconcile the two merge mechanisms (`τ_merge` reuse) | **Closed (r2), holds** | `:196-203` |
| 1 | 5 | `GraphDelta`/`MergeReport` schema, tier semantics, failure contract | **Closed (r2/r3), holds** | `:205-216` |
| 1 | 6 | EXTRACT-phase liveness pre-decided (RC-3) | **Closed (r2), holds** | `:195` |
| 2 | 1 | Reconcile §2.1 `Protocol` with §6.1/§6.2 deltas | **Closed (r3), holds** | `:53-57,76-77` |
| 2 | 2 | Episode/attempt-id generation, durability, retry-reuse, owner+tests | **Attempted across r3→r6; r6 introduces a new mechanism (`intent_key`/`tick`) that itself has unresolved gaps** | see Correctness §1 below — **not cleanly closed** |
| 2 | 3 | `record_eval` also returns `AppendResult` | **Closed (r3), holds** | `:54,177,189` |
| 2 | 4 | Concrete schema for the reconciled semantic-merge event | **Closed (r3), holds** | `:197-203` (`skill_merge{...}`) |
| 2 | 5 | Bound/coalesce shadow-copy cost; tie to M1 trigger | **Closed (r3), holds** | `:216` |
| 3 | 1 | Attempt-index granularity vs. batched `evals` row | **Closed (r4), holds** | `:172` "the work unit is the eval run" |
| 3 | 2 | Write path for `prune_orphans`/`decay_edges` | **Closed (r4), holds** | `:205-213`, `:141` (`retired` status) |
| 3 | 3 | §5 schema staleness vs. §6.1 delta | **Closed (r4), holds — but see the new r6 instance of the same defect class below** | `:138` |
| 3 | 4 | `GraphDelta.provenance` singular vs. per-tick coalescing | **Closed (r4), holds** | `:212` (`[truth_event_ids]`) |
| 3 | 5 | Schema for the durable work-unit row | **Closed (r5), holds in outline — but incomplete for r6's own new requirement** | `:138` `work_unit_opened(...)` has no `intent_key` field (Correctness, below) |
| 4 | 1 | Concrete `work_unit_opened` schema | **Closed (r5), holds** | `:138` |
| 4 | 2 | Port method + bootstrap resolution | **Closed (r5), holds** | `:53,174` |
| 4 | 3 | `AppendResult` 2-vs-3-field contradiction | **Closed (r5), holds** | `:53-55,177,189` all three-field, no regression |
| 4 | 4 | Disposition of evidence after rejection | **Attempted in r5 (narrowed), attempted again in r6 (full payload) — NOT cleanly closed: r6 introduces a fresh, self-inflicted contradiction** | `:138` vs `:181` (Correctness/Consistency, below) |
| 4 | 5 | Embedded-tier `attempt_idx` count-then-insert race | **Closed (r6), with a citation-precision residual** | `:175` (Correctness, below) |
| 5 | 1 | Idempotency mechanism for `open_work_unit`, or bound the residual risk | **Attempted substantively (`intent_key`) — NOT closed: no schema field to check it against, and the concurrent-same-key race the task explicitly asked about is unaddressed** | `:53,138,174,189` (Correctness, below) |
| 5 | 2 | Regression test for the mint-side double-count scenario | **Closed in name** (`test_ack_loss_recovery_no_double_count`, `:183`) — **but its own fixture (a durable, queryable `tick`/`intent_key`) does not exist in the schema**, so the test is not yet buildable as specified | `:183` |
| 5 | 3 | Race-safety of `attempt_idx` derivation | **Closed (r6), with a citation-precision residual** | `:175` |
| 5 | 4 | Caller obligation / store capability for rejected evidence | **NOT closed — contradicted by the unchanged canonical schema** | `:138` vs `:181` |
| 5 | 5 | Consolidate the two test lists (§6.1 `:183` vs §6.2 `:222`) | **STILL NOT closed — 4th consecutive round unaddressed** | `:183`, `:222` |

**Net verdict on the task's framing:** the calling agent's brief states round 5's two blockers and one partial were "ALL now addressed." Independent verification finds this only **partially true**: round-5 item 3 (attempt-idx race) is genuinely closed; item 2 (mint-race test) exists in name; but items 1 and 4 are **not** cleanly closed — item 1's central mechanism has a missing schema field and an untested concurrency case, and item 4's claimed fix is **directly contradicted** by the document's own canonical schema line. This is a materially different picture from "all addressed," and it is the dominant finding of this round.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 46 | blocking |
| 2 | Design faithfulness | 58 | weak |
| 3 | Red-team resistance (CRITICAL) | 44 | blocking |
| 4 | Implementability | 48 | weak |
| 5 | Safety / integrity (CRITICAL) | 63 | weak |
| 6 | Efficiency / cost | 65 | weak |
| 7 | Completeness | 47 | weak |
| 8 | Consistency | 42 | weak |
| 9 | Calibration / honesty | 38 | blocking |

## Findings by dimension

### 1. Correctness

**Finding A — the round's own claimed fix to round-5 item 4 is directly contradicted by the canonical schema it was supposed to change.** `DATA-LAYER.md:181` (§6.1 prose, this round's edit): "the store logs a `rejected_ingest{reason, payload}` event... **full payload retained**." But `DATA-LAYER.md:138` (§5, the document's own canonical "Record schemas" listing, header at `:136`) still declares `rejected_ingest{reason, payload_hash, ts}` — unchanged from round 5. These are not two readings of ambiguous prose; they are two incompatible field lists for the same record type, one asserting a hash, the other asserting the content. This is the identical defect class flagged in rounds 2 (`:59`, §2.1 vs. §6.1/§6.2), 3 (`:92`, §5 vs. §6.1), and 4 (`:47`, `AppendResult` 2-vs-3 field) — a canonical declaration left stale relative to prose changed in the same revision — but this round it is worse in one specific way: in round 5, `:180`'s prose and the (not-yet-existing) schema agreed (`payload_hash`, consistently narrow); round 6's edit *introduced* the contradiction by changing only one of the two places. This is a correctness regression this round caused itself, not a carried-forward gap.

**Finding B — the round's headline idempotency mechanism has no field to implement it against.** `:174` states `open_work_unit` "is idempotent on `intent_key`: an existing row with the same key returns the EXISTING work unit." But the persisted row this must be checked against, `work_unit_opened(occurrence_id, episode_id, suite_id, attempt_idx, ts)` (`:138`), and the return type, `WorkUnit{occurrence_id, attempt_idx}` (`:53,174,189`), both carry **zero fields for `intent_key` or `tick`**. There is no column to index or query to answer "does a row already exist for this `intent_key`?" — the store cannot implement the idempotency check the prose asserts as a settled fact. This is not a minor omission: it is the literal mechanism the round exists to add, and it has no data path. (This is the fourth-through-sixth round in a row this exact "stale/incomplete schema vs. confident prose" pattern recurs — see the audit table.)

**Finding C — `tick` is an entirely unspecified durable primitive, cited to a section that does not contain it.** `:174` grounds `intent_key`'s determinism in "the §6 loop tick... which is persisted before dispatch." `ALGORITHM-v0.2-pathway-learner.md` §6 (lines 177–207, checked directly) is a bare `loop forever: 1. SELECT ... 6. COMMIT or ROLLBACK` — it names no `tick` variable, states no persistence step, and describes no crash-recovery semantics anywhere in its six numbered steps. Nor does DATA-LAYER itself define where `tick` lives (which store, which schema, which port writes it) or when it advances relative to the six loop steps (only *if* it advances strictly after a full iteration's COMMIT/ROLLBACK does the "recovery re-derives the same key" claim at `:174` actually hold — nothing states this). This is precisely the same class of gap round 4 found for the original work-unit row ("no schema, no write path, and an unresolved bootstrap question," `r4:49-52`) recurring for a *new* primitive this round invents to fix the old one.

**Finding D — the exact question this round was asked to resolve (does idempotent-return-existing interact correctly with `attempt_idx` under concurrency) is not addressed.** `:174`'s idempotency claim and `:175`'s atomic-`attempt_idx`-derivation claim are stated as two separate mechanisms, and nothing states that the *combination* — "check for an existing row with this `intent_key`, and if none exists, atomically count-and-insert with the next `attempt_idx`" — executes as **one** atomic unit. If two concurrent calls carry the **same** `intent_key` (a plausible retry-storm pattern, not a contrived one — e.g., a caller that times out and retries while its first call is still in flight) and both observe "no existing row" before either inserts, both proceed to the atomic count-and-insert step described at `:175` — which is explicitly scoped only to "the count-of-prior-rows-and-insert for `(episode, suite)`," not to the intent_key-lookup-then-insert compound operation — and mint **two** rows with two different `attempt_idx` values for what is genuinely one attempt. `test_attempt_idx_atomic_under_concurrency` (`:183`) explicitly tests only "concurrent opens with **distinct** keys" (per its own parenthetical) — the same-key concurrent case is untested and unaddressed anywhere in the six-round history of this gate.

**Positive, genuine progress, fairly credited:** the WAL-style design of minting an `intent_key` from durable pre-dispatch state (rather than trusting "the crashed attempt's records never landed," round 5's flagged assumption) is architecturally the right shape of fix, and closes round 5's adversarial objection *in direction*. `attempt_idx`'s atomicity claim (`:175`) is a genuine advance over round 4/5, where this was flagged unaddressed twice running.

### 2. Design faithfulness

**A new, citation-level faithfulness gap: the "per-tick budget" invoked to flood-bound minting does not match §5.3 as written.** `:174`'s closing sentence — "each fresh work unit is dispatched by the §6 loop under its per-tick budget (§5.3 cost constraint)" — cites `ALGORITHM-v0.2-pathway-learner.md:163`'s `if spent + cost(a) > budget: continue`. That line is a **per-`choose()`-call spend ceiling on action selection**, not a rate limiter on how often a new work unit (tick) can be minted; nothing in §5.3 states or implies a cadence bound on tick advancement. This is an attempt (a good-faith one) to close round 5's flagged asymmetry with §17.6's `b_sm` flood-bounding (`r5:59`) — real progress in intent — but the specific mechanism cited does not do the job claimed, so the asymmetry is narrowed in wording only, not in substance.

**A second citation mismatch: "under the §6.2 single-writer lock" for `TruthStore`'s embedded tier.** `:175` states `attempt_idx` derivation on the embedded tier runs "under the §6.2 single-writer lock." But §6.2's single-writer lock (`:216`) was built specifically because `networkx`, the embedded **GraphStore** backend, has no native transactions — the embedded **TruthStore** backend is **SQLite** (`DATA-LAYER.md`, §3 table, "TruthStore | SQLite (stdlib) | PostgreSQL"), which already has ACID transactions on both tiers, exactly like the "full tier: DB transaction" case stated in the same sentence. Borrowing a different store's non-transactional workaround for a store that is already transactional is an internally inconsistent cross-reference — the correct statement is simply "an SQLite transaction, same mechanism as the full tier," not a pointer to `GraphStore`'s bespoke shadow-copy lock.

### 3. Red-team resistance

**RC-3 and RC-4 remain closed**, unaffected by this round.

**The RC-1-adjacent over/under-counting concern — sixth consecutive round without a verifiable closure, and this round's version of the residual is structurally the same shape as every prior one.** Round 1 found systemic under-counting; rounds 2–5 relocated the residual through "reuse ids on retry" → "reference-check has no write path" → "mint-side has no idempotency" → "mint-side has an idempotency *claim* resting on an unenforceable assumption." Round 6's fix, per Correctness Findings B–D above, does not close this: it asserts idempotency on a key that has no place to be stored or checked, grounds the guarantee in a primitive (`tick`) that is unspecified anywhere in the algorithm document it is attributed to, and leaves the specific concurrent-same-key race untested. This is scored **blocking**, not merely "weak" as in rounds 3–5, because the gap this round is a *structural absence of a data path* (a field that does not exist) rather than an *assumption about caller behavior* (rounds 3–5's framing) — the store cannot perform the check even if every caller behaves perfectly.

### 4. Implementability

A developer building `test_reopen_same_intent_idempotent` or `test_ack_loss_recovery_no_double_count` (`:183`) has no schema to build a fixture from: neither `work_unit_opened` nor `WorkUnit` carries `intent_key` or `tick`, so "look up the existing row for this key" cannot be written as stated. A developer would also have to invent, unguided, where `tick` itself is persisted (a new TruthStore table? An in-process orchestrator field — which would not survive a crash, reopening exactly the failure this round exists to close?) since no port method, table, or store is named for it anywhere in either document. The split test-list gap (`:183` vs. `:222`) persists for a fourth consecutive round.

### 5. Safety / integrity

No §8 gate clause, §14 formula, or §19 calibration knob is touched — structurally clean, as in every prior round.

**A new, second-order integrity/DoS concern introduced by this round's own fix.** Round 5's `rejected_ingest` retained only a `payload_hash` — cheap to store, bounded growth. Round 6's claimed change to retain the **full payload** (`:181`) — if actually implemented, which per Correctness Finding A the schema does not yet reflect — removes that bound with no offsetting rate limit: unlike `self_modify` proposals (flood-bounded by `b_sm` **at submission**, `ALGORITHM-v0.2-pathway-learner.md:503`) or work-unit minting (loosely tied to the loop's cadence per Design-faithfulness above), nothing caps how many `append_event`/`record_eval` calls with unregistered occurrence provenance a buggy or hostile caller can issue, each now retained **permanently** ("under standard truth retention," `:181`) at full payload size rather than a hash. This is a genuine, new, unaddressed storage-growth/DoS surface this round's own change creates, not present in this form in round 5.

**Because the mint-side idempotency gap (Correctness B–D) is unresolved, the specific over-counting failure §9's `sustained_heldout`, §17.3's monitored-subset check, and §19.1's `r̂`/`q_explore` all depend on being absent (ALGORITHM-v0.2-pathway-learner.md:253,464-465,561-565) remains a live, silent risk under concurrent retry** — scored here because it is integrity-adjacent (the evidentiary base feeding those mechanisms), consistent with how this concern has been scored across all six rounds.

### 6. Efficiency / cost

The `O(|V|+|E|)` shadow-copy cost, coalesced to one `merge()` per tick and tied to the §9 M1 trigger (`:216`), is unaffected and still sound. The new concern is the unbounded, unrated `rejected_ingest` full-payload retention path (Safety, above) — narrow in scope (a rejection path, not the hot act path) but real and newly introduced, which is why this scores "weak" rather than "pass" as in rounds 3–5.

### 7. Completeness

- **No test for the concurrent-same-`intent_key` race** (Correctness Finding D) — the one test that could target it, `test_attempt_idx_atomic_under_concurrency`, is explicitly scoped to *distinct* keys per its own description (`:183`).
- **`test_reopen_same_intent_idempotent` and `test_ack_loss_recovery_no_double_count` have no concrete fixture to build against**, since neither `intent_key` nor `tick` appears in any schema (Implementability, above) — these are named tests, not yet buildable ones.
- **No test asserts the `rejected_ingest` payload-vs-payload_hash question either way** — given the two-line self-contradiction (Correctness Finding A), a test would at least have forced the authors to pick one field name.
- **The split test-list gap** (`:183` vs `:222`) is unaddressed for the 4th consecutive round.

### 8. Consistency

**Two direct, in-document contradictions, both freshly introduced or freshly exposed by this round's own edits.** (1) `rejected_ingest{reason, payload_hash, ts}` (`:138`) vs. "the store logs a `rejected_ingest{reason, payload}` event... full payload retained" (`:181`) — a flat two-way disagreement on the same record's field list, introduced this round (round 5 had these agree). (2) The idempotency claim at `:174` ("an existing row with the same key returns the EXISTING work unit") has no corresponding column in `work_unit_opened` (`:138`) or `WorkUnit` (`:53,174,189`) to make that claim checkable — this is a claim/schema mismatch of the same recurring class, now on a new subject. Both are the same defect the `AppendResult` fix in round 5 was praised for having (for the first time) *not* repeated (`r5:99`, "the first round since round 1 in which this specific defect class does not reappear somewhere new") — that streak is broken this round, twice over.

### 9. Calibration / honesty

**The document's confident closing language is materially unsupported by its own text, for the fifth consecutive round, and this round the overclaim is sharper because it directly concerns a claim the task itself was asked to verify.** `:179`'s heading, "No circularity, no unenforced hole," is carried over from round 5 essentially unchanged, despite round 6 having *introduced* two fresh internal contradictions (Consistency, above) in the very mechanism that heading describes. `:181`'s "full payload retained" is stated as settled fact directly contradicted two rows away in canonical schema (Correctness Finding A) — this is a stronger, more concrete instance of the overclaiming pattern rounds 3 (`r3:98`), 4 (`r4:109`), and 5 (`r5:105`) each flagged, because it is not a subtle inferential gap but a two-line textual disagreement a careful self-read would have caught trivially. Scored lower than round 5 (38 vs. 63) because the standard for "closed" claimed by this revision is now directly falsified by its own canonical schema, not merely optimistic about an unenforced assumption.

## Strongest adversarial objection

**The rotating held-out sample can make "the same occurrence" produce genuinely different evidentiary content on recovery, and nothing in six rounds of this gate has considered it.** §4.1 draws the reward-bearing evidence from `secret = suite[s].held_out @ rotating_sample` (`ALGORITHM-v0.2-pathway-learner.md:81`) — by name, a **rotating** sample, not a fixed one. Consider a caller that opens a work unit, begins evaluating against the rotating sample, and crashes before its `record_eval` call is acknowledged. Per this round's own recovery story (`:174`), it re-derives the *same* `intent_key` from its durable `tick` state and receives the *same* `occurrence_id`/`attempt_idx` back — correctly reusing the work unit's *identity*. But if the recovery path **re-runs the evaluation** (rather than replaying a cached result) and the rotating sample's cursor has itself advanced in the interim (by wall-clock, by another concurrent process, or simply because "rotating" is defined independently of `occurrence_id`), the re-run draws a **different** `item_ids` set and outcome — a different `semantic_payload` — for the identical `occurrence_provenance`. Because `id = hash(record_type ‖ semantic_payload ‖ occurrence_provenance)` (`:164`), this produces a **new, distinct `identity_hash`** that does not dedupe against the original attempt's `evals` row — the store has no way to recognize "this occurrence already produced a result" versus "this occurrence never produced a result," because identity is keyed on content, not occurrence alone. The result: two `evals` rows, both correctly and individually well-formed, both carrying the **same** `occurrence_id`/`attempt_idx`, silently violating the section's own implicit one-record-per-occurrence assumption that every downstream Beta-update/statistical mechanism (§9, §17.3, §19.1) is built on — a subtler sibling of exactly the double-counting failure this entire six-round gate exists to close, hiding behind the technically-true observation that "the two records have different, correctly-computed identity hashes." None of the nine dimensions above surface this because each was scoped to §6.1/§6.2's stated mechanisms in isolation; it only appears when §6.1's occurrence-identity model is read against §4.1's *rotating* (not fixed) held-out sample.

## Aggregate confidence

```
critical_floor  = min(Correctness=46, RedTeam=44, Safety=63) = 44
weighted_mean   = (46*2 + 58 + 44*2 + 48 + 63*2 + 65 + 47 + 42 + 38) / 11
                = (92 + 58 + 88 + 48 + 126 + 65 + 47 + 42 + 38) / 11
                = 604 / 11
                = 54.9 → 55
overall         = min(44, 55) = 44
```

**Overall confidence: 44 / 100**

## Verdict

**needs-revision**

This round is a **regression** from round 5's 66, not the closure its own framing claims. Genuine, verifiable progress exists (round-4 item 5's `attempt_idx` race is finally closed in substance, modulo a citation-precision residual; the WAL-style `intent_key` design is architecturally the right shape and a real advance over round 5's "no idempotency mechanism at all"). But two of round 5's three closure claims do not survive independent verification: the idempotency mechanism has no schema field to check against and leaves the exact concurrency question this round was asked to scrutinize (same-`intent_key` races) untouched, and the rejected-evidence fix is directly contradicted by the document's own unchanged canonical schema — a fresh, self-inflicted instance of the exact "stale declaration vs. revised prose" defect class this gate has fought since round 2. All three CRITICAL dimensions (Correctness 46, Red-team 44, Safety 63) are below 70.

1. **Add `intent_key` (or the `tick` it derives from) as a persisted field on `work_unit_opened` and `WorkUnit`**, so the idempotency check `:174` asserts has a column to query. State explicitly which store/table durably holds `tick`, which port method (if any, beyond `open_work_unit` itself) writes it, and when it advances relative to the §6 loop's six numbered steps (specifically: does it advance only after a full iteration's COMMIT/ROLLBACK, which is the property the crash-recovery claim silently depends on?).
2. **Fix the `rejected_ingest` schema contradiction.** `:138` says `payload_hash`; `:181` says full `payload` is retained. Pick one, update both, and state the storage-growth/retention policy for whichever is chosen (see item 4).
3. **Specify atomicity for the *combined* find-or-create operation, not just the count-and-insert sub-step.** State explicitly whether "check for an existing row with this `intent_key`, else atomically derive `attempt_idx` and insert" executes as one transaction/critical section on both tiers, and add a test for concurrent calls sharing the **same** `intent_key` (the current `test_attempt_idx_atomic_under_concurrency` is explicitly scoped to distinct keys only).
4. **Bound `rejected_ingest`'s growth.** If the full payload is retained (per the intended fix), state a rate limit or cap analogous to `self_modify`'s `b_sm`-at-submission discipline (`ALGORITHM-v0.2-pathway-learner.md:503`) or the write-discipline reasoning already used for work-unit minting — full-payload, permanent, unrated retention on a rejection path callable by any caller with fabricated provenance is an unaddressed storage/DoS surface this round's own change introduces.
5. **Correct the embedded-tier concurrency-mechanism citation** (`:175`) — `TruthStore`'s embedded backend is SQLite (already transactional per the §3 table), not `networkx`; do not borrow `GraphStore`'s bespoke shadow-copy/single-writer-lock workaround (`:216`), built for a backend with no native transactions, to describe a backend that already has them.
6. **Reconcile the mismatched §5.3/§17.6 citation** used to argue `open_work_unit` is flood-bounded (`:174`) — §5.3's `budget` is a per-`choose()`-call spend ceiling, not a mint-rate limiter; either cite a mechanism that actually rate-bounds work-unit creation, or state plainly that none currently exists.
7. **Consolidate the two test lists** (`:183`, `:222`) — flagged in rounds 3, 4, 5, and now 6 without being addressed.
8. **Address the rotating-sample/occurrence-identity interaction** named in the adversarial pass — state whether a recovery-triggered re-evaluation against a rotating held-out sample is guaranteed to reproduce the same `item_ids`/outcome for a given `occurrence_id`, or add a mechanism (e.g., binding the rotation cursor to `occurrence_id` deterministically) that makes it so.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-<n>","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r6.md","why":"360 review (round 6) of DATA-LAYER.md §6.1/§6.2 revised r6 -- overall 66 -> 44/100, needs-revision, a REGRESSION not a closure: independent audit finds round-5's 3 claimed closures only 1 of 3 genuinely holds (attempt_idx race); the intent_key idempotency mechanism has no schema field to check against (work_unit_opened/WorkUnit carry no intent_key/tick column) and leaves the exact same-key concurrency race the task asked about untested; the rejected_ingest full-payload fix directly contradicts the unchanged canonical schema (still payload_hash at DATA-LAYER.md:138 vs 'full payload retained' prose at :181) -- a fresh, self-inflicted instance of the stale-schema-vs-prose defect class recurring since round 2; the tick concept cited as backing intent_key's determinism does not exist anywhere in ALGORITHM-v0.2 §6 or DATA-LAYER itself; adversarial pass flags a new rotating-held-out-sample interaction with occurrence identity not covered by any of the 9 dimensions in 6 rounds","evidence":["docs/research/DATA-LAYER.md §2.1 (line 53), §5 (line 138), §6.1/§6.2 (lines 159-222)","docs/research/reviews/DL-write-discipline-review-r5.md","docs/research/reviews/DL-write-discipline-review-r4.md","docs/research/reviews/DL-write-discipline-review-r3.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §3 (lines 54-69), §4.1 (lines 77-87), §5.1 (lines 115-141), §5.3 (lines 158-173), §6 (lines 177-207), §9 (lines 242-260), §17.6 (lines 479-510), §19.1 (lines 561-563)","docs/research/ALGORITHM-v0.1-redteam.md RC-1 (lines 36-39), RC-4 (lines 51-53)","docs/research/HUMAN-LEARNING-VERIFIER.md:35"],"outcome":"pending"}
```
