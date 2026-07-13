# 360 Review: DL-write-discipline — 2026-07-13 (Round 7)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 159–190) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 192–224), both marked *revised r7 — IN GATE* |
| Proposed change | Round-7 rewrite claiming to close round 6's three headline findings: (1) `intent_key` is now a persisted `UNIQUE` field on `work_unit_opened`, minted as the id of a new `dispatch` administrative event appended before work begins (replacing the unspecified "tick" primitive); (2) `rejected_ingest`'s schema now matches the "full payload retained" prose; (3) `work_unit_opened` pins `item_ids` at open, closing the rotating-held-out-sample/occurrence-identity adversarial finding. |
| Reviewer | review-360 |
| Round | 7 (`-r7`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `-r2.md` (78/100); round 3: `-r3.md` (68/100); round 4: `-r4.md` (64/100); round 5: `-r5.md` (66/100); round 6: `-r6.md` (44/100, regression, 8 items in verdict) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, last_run 2026-07-03) → filing as a direct review, not a proposal.

## Full round 1–6 audit — every numbered item, closed or explicitly carried

| Round | # | Item | Status as of r7 | Evidence |
|---|---|---|---|---|
| 1 | 1 | Occurrence/provenance component in the hash | **Closed (r2), holds** | `DATA-LAYER.md:164-167` |
| 1 | 2 | Missing-repeat-evidence regression test | **Closed (r2), holds** | `test_repeat_measurement_not_deduped`, `:223` |
| 1 | 3 | Append-only vs. return-existing-on-duplicate | **Closed (r2), holds** | `:186` "idempotence, not upsert" |
| 1 | 4 | Reconcile the two merge mechanisms (`τ_merge` reuse) | **Closed (r2), holds** | `:197-204` |
| 1 | 5 | `GraphDelta`/`MergeReport` schema, tier semantics, failure contract | **Closed (r2/r3), holds** | `:206-217` |
| 1 | 6 | EXTRACT-phase liveness pre-decided (RC-3) | **Closed (r2), holds** | `:196` |
| 2 | 1 | Reconcile §2.1 `Protocol` with §6.1/§6.2 deltas | **Closed (r3), holds** | `:53-57,76-77` |
| 2 | 2 | Episode/attempt-id generation, durability, retry-reuse, owner+tests | **Substantively re-attempted (r7): schema field now exists, "tick" eliminated — but a fresh gap opens in the new mechanism** | Correctness Finding A below — **not cleanly closed, new instance of the same defect class** |
| 2 | 3 | `record_eval` also returns `AppendResult` | **Closed (r3), holds** | `:54,178,190` |
| 2 | 4 | Concrete schema for the reconciled semantic-merge event | **Closed (r3), holds** | `:198-204` |
| 2 | 5 | Bound/coalesce shadow-copy cost; tie to M1 trigger | **Closed (r3), holds** | `:217` |
| 3 | 1 | Attempt-index granularity vs. batched `evals` row | **Closed (r4), holds** | `:173` "the work unit is the eval run" |
| 3 | 2 | Write path for `prune_orphans`/`decay_edges` | **Closed (r4), holds** | `:206-214`,`:141` |
| 3 | 3 | §5 schema staleness vs. §6.1 delta | **Closed (r4), holds — the defect class recurs fresh this round in a new location** | Consistency Finding below (`dispatch` vs. the administrative-events list) |
| 3 | 4 | `GraphDelta.provenance` singular vs. per-tick coalescing | **Closed (r4), holds** | `:213` |
| 3 | 5 | Schema for the durable work-unit row | **Closed (r7)** — now carries `intent_key UNIQUE` and `item_ids` | `:138` |
| 4 | 1 | Concrete `work_unit_opened` schema | **Closed (r5), extended and closed further (r7)** | `:138` |
| 4 | 2 | Port method + bootstrap resolution | **Closed (r5), holds** | `:53,175` |
| 4 | 3 | `AppendResult` 2-vs-3-field contradiction | **Closed (r5), holds** | `:53-55,178,190` |
| 4 | 4 | Disposition of evidence after rejection | **Closed (r7)** — schema (`:138`) now literally matches prose (`:182`) | `:138,182` |
| 4 | 5 | Embedded-tier `attempt_idx` count-then-insert race | **Closed (r6) in substance, but the citation-precision residual r6 flagged is UNFIXED, carried a 2nd round** | `:175` (Design faithfulness, below) |
| 5 | 1 | Idempotency mechanism for `open_work_unit`, or bound the residual risk | **Genuinely re-attempted: schema field added, "tick" replaced by the `dispatch`-event-id design, same-key concurrency now specified+tested — real progress on all three r6 sub-findings — but a new, comparably severe gap opens (no discriminator against two *genuinely distinct* dispatch decisions colliding on the same key)** | Correctness Finding A (below) |
| 5 | 2 | Regression test for the mint-side double-count scenario | **Closed (r7)** — `test_ack_loss_recovery_no_double_count` now has a schema to build against | `:184` |
| 5 | 3 | Race-safety of `attempt_idx` derivation | **Closed (r6), holds — same unfixed citation-precision residual as R4#5 above** | `:175` |
| 5 | 4 | Caller obligation / store capability for rejected evidence | **Closed (r7)** — schema/prose agree | `:138,182` |
| 5 | 5 | Consolidate the two test lists (§6.1 vs §6.2) | **STILL NOT closed — 5th consecutive round unaddressed** | `:184` vs `:223` |
| 6 | 1 | Add `intent_key`/`tick` as a persisted, documented field | **Addressed** — schema field + `dispatch` event grounding, no more free-floating "tick" | `:138,174` |
| 6 | 2 | Fix the `rejected_ingest` schema contradiction | **Closed** | `:138,182` agree |
| 6 | 3 | Specify combined find-or-create atomicity + same-key concurrent test | **Closed** | `:175`, `test_same_intent_concurrent_open` `:184` |
| 6 | 4 | Bound `rejected_ingest`'s (now full-payload) growth | **NOT addressed** — no rate limit/cap stated for `rejected_ingest` anywhere | Safety Finding below |
| 6 | 5 | Correct the embedded-tier concurrency-mechanism citation (SQLite ≠ `networkx` lock) | **NOT addressed** — `:175` still says "embedded: the §6.2 single-writer lock" for `TruthStore` | Design faithfulness Finding below |
| 6 | 6 | Reconcile the mismatched §5.3/§17.6 rate-bounding citation | **NOT addressed** — `:178` still cites §5.3's per-`choose()`-call budget as a mint-rate limiter | Design faithfulness Finding below |
| 6 | 7 | Consolidate the two test lists | **NOT addressed** (duplicate of R5#5) | `:184` vs `:223` |
| 6 | 8 | Address the rotating-sample/occurrence-identity interaction | **Closed** — `item_ids` pinned at open; `test_resumed_work_unit_reuses_pinned_items` | `:175,184` |

**Net verdict on the task's framing:** the calling agent's brief states round 6's findings "ALL are now addressed." Independent verification finds this **true only for the three items the brief actually named** (intent_key schema, rejected_ingest contradiction, rotating-sample pinning) — and even the first of those three, while genuinely improved, opens a fresh correctness gap of comparable severity (Correctness Finding A). Separately, **four of round 6's own eight numbered verdict items (4, 5, 6, 7) were never in the task's "addressed" list and remain unaddressed in the text** — this is consistent with the task brief scoping to a subset, not a false claim, but it means the artifact itself has *not* cleared round 6's full punch list, which the "IN GATE" status implies it must before promotion out of this loop.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 52 | blocking |
| 2 | Design faithfulness | 55 | weak |
| 3 | Red-team resistance (CRITICAL) | 42 | blocking |
| 4 | Implementability | 52 | weak |
| 5 | Safety / integrity (CRITICAL) | 58 | weak |
| 6 | Efficiency / cost | 62 | weak |
| 7 | Completeness | 48 | blocking |
| 8 | Consistency | 55 | weak |
| 9 | Calibration / honesty | 40 | blocking |

## Findings by dimension

### 1. Correctness

**Finding A (primary) — `action_fingerprint` is wholly undefined, and nothing in the section states it disambiguates two genuinely distinct dispatch decisions from one another; as specified, the `intent_key` mechanism can silently merge genuine repeat measurements into one occurrence.** `:174`: `intent_key` is minted as the id of a `dispatch{episode_id, suite_id, action_fingerprint}` event, and `work_unit_opened.intent_key` carries a `UNIQUE` constraint (`:138,175`) — "an existing row with the same key returns the existing work unit." `attempt_idx` is scoped per `(episode_id, suite_id)` (`:138`), meaning the schema itself anticipates **multiple genuinely-distinct attempts of the same suite within one episode** (attempt 1, 2, 3…). Nothing in the document defines what `action_fingerprint` is a fingerprint *of* — whether it includes a sequence/nonce component that necessarily differs between two separate loop iterations that happen to select the identical action for the identical `(episode_id, suite_id)` (a routine occurrence: repeated practice of the same skill is exactly how evidence accumulates, per §6's main loop, `ALGORITHM-v0.2-pathway-learner.md:180-207`). If `action_fingerprint` captures only the *content* of the decision (e.g., "practice skill s at difficulty d") and not a discriminator that varies call-to-call, then two **genuinely different** dispatch decisions collide on `intent_key`, and the `UNIQUE` constraint's "return the existing work unit" behavior (`:175`) silently treats the second, real, independent attempt as a retry of the first — no new `attempt_idx` is minted, no new occurrence is created, and the evidence from the second attempt is never distinctly recorded. This is a **fresh instance of exactly the under-counting failure §6.1 exists to prevent** — the document's own text at `:170` states the "modal case for a stable candidate under `sustained_heldout` §9, Stage-1 shadow monitoring §17.3, and the §19.1 `w_obs` machinery" is a genuine repeat measurement that "produces a new id and a new event"; Finding A shows the brand-new `intent_key` gate, as specified, can prevent exactly that from happening at the *work-unit* layer, one level upstream of where the identity-hash formula operates. No test in the regression set (`:184`) checks two *distinct* dispatch decisions that happen to select the same action for the same `(episode_id, suite_id)` — `test_reopen_same_intent_idempotent` (`:184`) tests only the case where the caller intends to reference the *same* work unit.

**Finding B — the `dispatch` event's own retry-safety (a precondition for the whole design) is unaddressed.** The entire point of "declare intent, durably... before any work" (`:174`) is to survive a crash between the declaration and the work that follows — but nothing states that appending the *same* dispatch decision twice (e.g., a crash between the `dispatch` append and its ack, followed by a caller-side retry of the append itself, which is a more primitive crash window than the `open_work_unit` retry the section otherwise handles) produces the *same* event id. The general identity-hash rule (`:161`, "every record that can move a posterior... carries an identity hash") is explicitly scoped to posterior-moving records, and `dispatch` is administrative (moves no posterior, `:174`) — so it is unclear whether `dispatch`'s id is even computed via the deterministic, `ts`-excluding formula at `:164-167`, or via some other (unstated) mechanism. If `dispatch`'s own append is not idempotent on its semantic content, a crash at this earlier point re-introduces the double-mint risk the whole section exists to close, one step upstream of `open_work_unit`.

**Positive, genuine progress, fairly credited:** the schema now has the field round 6 found missing (`work_unit_opened.intent_key UNIQUE`, `:138`) — Finding B of round 6 is closed. The "tick" primitive (round 6 Finding C, cited to a §6 that never defined it) is eliminated in favor of grounding `intent_key` in an ordinary, already-defined mechanism (an appended event, `:174`) — a genuinely sounder design move. The combined find-or-create atomicity and the same-key concurrent race (round 6 Finding D) are now explicitly specified and tested (`:175`, `test_same_intent_concurrent_open` `:184`) — closed. The `rejected_ingest` schema/prose contradiction (round 6 Finding A) is fixed: `:138`'s `rejected_ingest{reason, payload, ts}` now matches `:182`'s "full payload retained" verbatim.

### 2. Design faithfulness

**Two carried-forward citation mismatches from round 6, neither touched by this round.** (1) `:175` still states `attempt_idx` derivation on the embedded tier runs "under the §6.2 single-writer lock" — but §6.2's lock (`:217`) exists specifically because `networkx` (the embedded **GraphStore** backend) has no native transactions; the embedded **TruthStore** backend is **SQLite** (`DATA-LAYER.md` §3 table: "TruthStore | SQLite (stdlib) | PostgreSQL"), which is already ACID-transactional on both tiers — this is the identical citation error round 6 flagged (its Design-faithfulness section, verdict item 5), carried unchanged into r7. (2) `:178`'s "each fresh work unit is dispatched... under the §6 loop's per-step budget (§5.3 hard cost constraint)" still cites `ALGORITHM-v0.2-pathway-learner.md:163`'s `if spent + cost(a) > budget: continue` — a per-`choose()`-call spend ceiling on action selection within one candidate loop, not a cadence limiter on how often a new work unit/dispatch can be minted across outer-loop iterations; nothing in §5.3 states or implies a mint-rate bound. This is the same mismatch round 6 flagged (verdict item 6), also carried unchanged.

**§6.2 substantively unchanged; only renumbered.** Comparing the current §6.2 text (`:192-224`) against round 6's citations, the `GraphDelta`/`MergeReport` schema, tier-transaction contract, and coalescing rule are identical in substance — the section header is marked "revised r7" but the task's own framing of round 7's changes (intent_key, rejected_ingest, item_ids) is entirely a §6.1 story. No new §6.2 issue found, none regressed.

### 3. Red-team resistance

**RC-3 and RC-4 remain closed**, unaffected by this round.

**RC-1 is reopened in a new location by this round's own headline fix (Correctness Finding A).** Round 1 found systemic under-counting of genuine repeat measurements; rounds 2–6 relocated the residual through successive layers of the mint-side idempotency mechanism. Round 7's fix closes the schema-existence gap (round 6 Finding B) and the tick-grounding gap (round 6 Finding C) cleanly, but the mechanism it substitutes — `intent_key = id(dispatch{episode_id, suite_id, action_fingerprint})` — has no stated component that guarantees two independently-chosen, genuinely-repeated attempts of "the same action in the same episode/suite" receive different keys. This is scored **blocking**, consistent with round 6's severity assessment for the same underlying disease (a structural absence, not a caller-behavior assumption): a developer implementing `action_fingerprint` naively (e.g., as `hash(skill, difficulty)`) would produce a system that *provably* undercounts, and nothing in the text warns against that implementation or specifies the alternative.

**A second, genuinely new fleet-scale instance of the same failure mode — see the adversarial pass.**

### 4. Implementability

A developer can now build `work_unit_opened` and the `intent_key UNIQUE` check (round 5/6's gap is closed) but **cannot implement `dispatch`'s `action_fingerprint` without inventing its content**, since the document never states what it must capture or why two distinct decisions are guaranteed to differ. This is the same class of gap round 4 found for the original work-unit row and round 6 found for `tick` — recurring for the field that replaced `tick`. The split test-list gap (`:184` vs. `:223`) persists for a 5th consecutive round. Minor: the "Port delta" summary paragraphs (`:190,221`) do not enumerate the concrete new fields (`intent_key`, `item_ids`, the `dispatch` event kind) a developer must add to `schemas.py` — they rely on the generic "records gain identity_hash + provenance fields" sentence, which does not obviously cover a field that is *not* part of the identity-hash formula (`intent_key`/`item_ids` are not listed as hash inputs at `:164-167`).

### 5. Safety / integrity

No §8 gate clause, §14 formula, or §19 calibration knob is touched — structurally clean, as in every prior round.

**Round 6's unbounded `rejected_ingest` growth concern is carried, unaddressed.** Round 6 flagged that retaining the full payload (rather than a hash) removes the storage bound with no offsetting rate limit. `:182`'s current text ("the store logs a `rejected_ingest{reason, payload}` event... the caller receives `rejected_reason` and must either re-associate... or escalate to the breaker") still states no cap, quota, or retention policy specific to this event kind — unlike `self_modify` proposals, which are explicitly "flood-bounded by construction" at submission (`ALGORITHM-v0.2-pathway-learner.md:503`, cited approvingly elsewhere in this same document, `:138`'s `scaffold_versions` delta). A caller with fabricated occurrence provenance (the exact scenario `:178`'s enforcement clause exists to reject) can still generate unbounded full-payload rows at no cost to itself.

**Because Correctness Finding A is unresolved, the specific over/under-counting failure §9's `sustained_heldout`, §17.3's monitored-subset check, and §19.1's `r̂`/`q_explore` all depend on being absent remains a live risk** — scored here because it is integrity-adjacent (the evidentiary base feeding those mechanisms), consistent with how this concern has been scored across all seven rounds.

### 6. Efficiency / cost

The `O(|V|+|E|)` shadow-copy cost, coalesced to one `merge()` per tick and tied to the §9 M1 trigger (`:217`), is unaffected and still sound. The unbounded, unrated `rejected_ingest` full-payload retention path (Safety, above) is unchanged from round 6 — narrow in scope but real and still open, hence "weak" rather than "pass."

### 7. Completeness

- **No test for two genuinely distinct dispatch decisions colliding on `intent_key`** (Correctness Finding A) — the only test that could target it, `test_reopen_same_intent_idempotent` (`:184`), is scoped to the caller *knowingly* referencing the same intent, not to two independent decisions that happen to fingerprint identically.
- **No test for the `dispatch` event's own retry-idempotency** (Correctness Finding B).
- **No test asserts a `rejected_ingest` growth bound** — Safety, above, has no test named for it either.
- **The split test-list gap** (`:184` vs. `:223`) is unaddressed for the 5th consecutive round.
- Positive: `test_ack_loss_recovery_no_double_count`, `test_reopen_same_intent_idempotent`, `test_same_intent_concurrent_open`, and `test_resumed_work_unit_reuses_pinned_items` (`:184`) are now all buildable against a concrete schema — a genuine completeness gain over round 6.

### 8. Consistency

**A fresh, self-inflicted cross-reference gap: `dispatch` is called "administrative... see the record-class rule below," but the record-class rule omits it.** `:174`: "the §6 orchestrator appends a `dispatch` event (**administrative** — see the record-class rule below)." The rule it points to, `:180`, enumerates the administrative-events exemption explicitly: "Identity-root records (`work_unit_opened`) and administrative events (`selfmod_rejected`, `component_invoked`, `rejected_ingest`) move no posterior." **`dispatch` does not appear in that list.** This is the identical defect class flagged in rounds 2 (`AppendResult`), 3 (§5 vs. §6.1), 4 (`AppendResult` 2-vs-3 field), and 6 (`rejected_ingest` schema vs. prose) — a forward reference introduced in the same revision that the target it points to does not actually satisfy. Read literally, if `dispatch` is *not* administrative, then `:178`'s enforcement rule ("set `rejected_reason` for a posterior-moving record whose occurrence references no `work_unit_opened` row") would apply to it — and since `dispatch` necessarily precedes `work_unit_opened`'s existence, every `dispatch` event would be definitionally unrecordable, which cannot be the intent. The fix is one line (add `dispatch` to the `:180` list), but as written the cross-reference does not resolve.

**Minor terminology collision (non-blocking):** `BUILD-SPECS.md:299-363` (R1, approved) already uses "dispatch" as a term of art for retrieval-mode selection ("Mode dispatch (per `EXPAND`)," `BUILD-SPECS.md:311`) — unrelated to this section's new `dispatch` TruthStore event kind. Not a substantive conflict (different namespaces, no shared field), but the same word now names two distinct, unrelated mechanisms in the same document set — worth a rename for developer clarity, not a blocking finding.

### 9. Calibration / honesty

**The document's confident closing language remains materially unsupported by its own text, for the sixth consecutive round.** `:180`'s heading, "**No circularity, no unenforced hole — the exemption is by record class, and the class is checkable**," is carried over from round 6 essentially unchanged — yet Consistency's finding above shows the class, as literally enumerated at that exact location, is **not** checkable for `dispatch`, the one new record type this round introduces. This is the same overclaiming pattern rounds 3, 4, 5, and 6 each flagged, now recurring in the very sentence that was supposed to be this round's closing argument. Separately, the task brief's "ALL are now addressed" framing is accurate for the three items it names but silently leaves four of round 6's eight numbered verdict items open (R6#4, #5, #6, #7) — a scope-narrowing that, if taken as "the gate's outstanding punch list is clear," would be a miscalibrated read of where this artifact actually stands.

## Strongest adversarial objection

**The new `intent_key`/`dispatch`/`work_unit_opened` mechanism has no fleet (`agent_id`) scoping, unlike every other identity-bearing structure this document has added under the §18 multi-agent extension — a real collision risk once §18 (M3) is live.** `ALGORITHM-v0.2-pathway-learner.md` §18.1 (line 521) states "Each agent keeps its **own** posterior `C_a` in a `StateStore` **keyed by `agent_id`**" — and `DATA-LAYER.md` explicitly added an `agent_id` column to `lineage` for exactly this reason (`:138`: "`agent_id` = the fleet key, mirroring §18.1's per-agent `StateStore` keying; single-agent default is a constant"). The document is demonstrably aware that identity-bearing structures need fleet scoping once §18 is enabled. Yet `dispatch{episode_id, suite_id, action_fingerprint, ts}` and `work_unit_opened(occurrence_id, episode_id, suite_id, attempt_idx, intent_key UNIQUE, item_ids, ts)` (both `:138`, both introduced or extended *this round*) carry **no `agent_id` field**, and `evals` (`:138`, unchanged across all seven rounds) has none either. Nothing in the document states that `episode_id` is guaranteed globally unique across the whole fleet rather than per-agent — and if it is not (a very ordinary implementation choice, e.g., a per-agent sequential counter), then **two different fleet agents independently practicing the same suite could produce colliding `intent_key`s**, and the `UNIQUE` constraint's "return the existing work unit" behavior (`:175`) would silently hand agent B the occurrence identity minted for agent A — merging two agents' distinct evidence into one work unit, corrupting both agents' `StateStore` updates at the source. This is structurally the same disease as Correctness Finding A (undercounting via key collision) but at a different, previously un-examined axis (fleet, not intra-agent retry) — none of the nine dimensions above name it, because all were scoped to the single-agent occurrence model this section is written in, and §18's fleet interaction with §6.1's brand-new schema has not been checked in any of the seven rounds of this gate.

## Aggregate confidence

```
critical_floor  = min(Correctness=52, RedTeam=42, Safety=58) = 42
weighted_mean   = (52*2 + 55 + 42*2 + 52 + 58*2 + 62 + 48 + 55 + 40) / 11
                = (104 + 55 + 84 + 52 + 116 + 62 + 48 + 55 + 40) / 11
                = 616 / 11
                = 56.0 → 56
overall         = min(42, 56) = 42
```

**Overall confidence: 42 / 100**

## Verdict

**needs-revision**

This round is **essentially flat against round 6** (42 vs. 44), not the closure its own framing claims — real, verifiable progress on two of the three named items (the `rejected_ingest` contradiction and the rotating-sample pinning are both cleanly closed) is offset by a fresh, comparably severe gap in the third: the `intent_key` mechanism now has the schema field round 6 demanded, but the field it's grounded in (`action_fingerprint`) is undefined in a way that permits — and does not test against — silently merging genuinely distinct repeat measurements, which is precisely the failure mode this entire seven-round gate exists to prevent (RC-1). All three CRITICAL dimensions (Correctness 52, Red-team 42, Safety 58) are below 70.

1. **Define `action_fingerprint` concretely and state what guarantees it differs between two genuinely separate dispatch decisions for the same `(episode_id, suite_id)`** (e.g., include a monotonic per-`(episode_id, suite_id)` sequence number, or the pre-dispatch checkpoint/state snapshot hash, as an explicit hash input) — and add a regression test for two independent dispatches that select the identical action colliding on `intent_key` (the gap `test_reopen_same_intent_idempotent` does not cover).
2. **State whether/how the `dispatch` event's own append is idempotent under retry** (Correctness Finding B) — if it relies on the general identity-hash rule, say so explicitly and confirm `ts` is excluded from its hash input; if it relies on something else, name the mechanism.
3. **Add `dispatch` to the administrative-events exemption list at `:180`** (or state explicitly why it is deliberately excluded) — the forward reference at `:174` currently points to a list that omits the very record type it describes.
4. **Correct the embedded-tier concurrency-mechanism citation** (`:175`, carried from round 6 unaddressed) — `TruthStore`'s embedded backend is SQLite (already transactional), not `networkx`'s bespoke shadow-copy lock.
5. **Reconcile the §5.3 rate-bounding citation** (`:178`, carried from round 6 unaddressed) — §5.3's `budget` is a per-`choose()`-call spend ceiling, not a work-unit mint-rate limiter; cite an actual rate bound or state plainly that none exists.
6. **Bound `rejected_ingest`'s growth** (carried from round 6 unaddressed) — full-payload, permanent, unrated retention on a rejection path is an unaddressed storage/DoS surface.
7. **Consolidate the two test lists** (`:184`, `:223`) — flagged in rounds 3, 4, 5, 6, and now 7 without being addressed.
8. **Scope `intent_key`/`work_unit_opened`/`dispatch`/`evals` by `agent_id` before §18 (M3) is enabled**, or explicitly state and justify why `episode_id` is guaranteed fleet-globally-unique without one (the adversarial-pass finding).

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-61","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r7.md","why":"360 review (round 7) of DATA-LAYER.md §6.1/§6.2 revised r7 -- overall 44 -> 42/100, needs-revision, essentially flat: 2 of round 6's 3 named closures (rejected_ingest schema/prose contradiction; rotating-sample item_ids pinning) genuinely hold, but the third (intent_key idempotency) trades round 6's missing-schema-field gap for a fresh, comparably severe one -- action_fingerprint (the new dispatch event's content) is undefined and nothing guarantees it differs between two genuinely distinct dispatch decisions for the same (episode_id, suite_id), so the new UNIQUE(intent_key) constraint can silently merge genuine repeat measurements into one work unit -- a fresh RC-1 instance one layer upstream of where round 1-6 fought it; separately, 4 of round 6's own 8 verdict items (rejected_ingest growth bound, embedded-tier SQLite-vs-networkx citation, section5.3 rate-bound citation, split test lists) were never touched; adversarial pass finds the new dispatch/work_unit_opened/evals schemas have no agent_id fleet-scoping unlike lineage/StateStore, a collision risk once section18 (M3) is live","evidence":["docs/research/DATA-LAYER.md §2.1 (lines 52-57), §5 (line 138), §6.1/§6.2 (lines 159-224)","docs/research/reviews/DL-write-discipline-review-r6.md","docs/research/reviews/DL-write-discipline-review-r5.md","docs/research/reviews/DL-write-discipline-review-r4.md","docs/research/reviews/DL-write-discipline-review-r3.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §3 (lines 54-69), §4.1 (lines 77-87), §5.1 (lines 115-141), §5.3 (lines 158-173), §6 (lines 180-207), §9 (lines 242-260), §10 (line 266), §17.6 (lines 479-510), §18.1 (line 521), §19.1 (lines 561-563)","docs/research/ALGORITHM-v0.1-redteam.md RC-1 (lines 36-39), RC-4 (lines 51-53)","docs/research/BUILD-SPECS.md:299-363 (R1, dispatch terminology)"],"outcome":"pending"}
```
