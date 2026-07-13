# 360 Review: DL-write-discipline — 2026-07-13 (Round 8)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 159–190) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 192–225), both marked *revised r8 — IN GATE* |
| Proposed change | Round-8 rewrite claiming to close all eight of round 7's numbered verdict items: `seq` (the persisted count of prior dispatches for `(agent, episode, suite)`, assigned atomically inside the dispatch append's transaction) becomes the sole discriminator for `intent_key`, with `action_fingerprint` demoted to an explicit content-descriptor-only role; the `dispatch` event's own retry-idempotency is stated explicitly (follows the general §6.1 identity rule, `ts` excluded); `dispatch` is added to the administrative-events exemption list; the embedded-tier citation is corrected (SQLite's own transactions, not `networkx`'s graph-writer lock); the false §5.3 rate-bounding citation is replaced with a plain "no rate limit" statement; `rejected_ingest` gets a stated growth bound (`w_rejected`, prune-to-hash after the window, rows permanent); the two §6.1/§6.2 test lists are consolidated into one; and `agent_id` fleet-scoping is added to `events`, `evals`, `work_unit_opened`, and `dispatch`. |
| Reviewer | review-360 |
| Round | 8 (`-r8`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `-r2.md` (78/100); round 3: `-r3.md` (68/100); round 4: `-r4.md` (64/100); round 5: `-r5.md` (66/100); round 6: `-r6.md` (44/100, regression); round 7: `-r7.md` (42/100, flat, 8 items in verdict) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, `last_run` 2026-07-03) → filing as a direct review, not a proposal.

## Full round 1–7 audit — every numbered item, closed or explicitly carried

| Round | # | Item | Status as of r8 | Evidence |
|---|---|---|---|---|
| 1 | 1 | Occurrence/provenance component in the hash | **Closed (r2), holds** | `DATA-LAYER.md:164-167` |
| 1 | 2 | Missing-repeat-evidence regression test | **Closed (r2), holds** | `test_repeat_measurement_not_deduped`, `:224` |
| 1 | 3 | Append-only vs. return-existing-on-duplicate | **Closed (r2), holds** | `:186` "idempotence, not upsert" |
| 1 | 4 | Reconcile the two merge mechanisms (`τ_merge` reuse) | **Closed (r2), holds** | `:197-204` |
| 1 | 5 | `GraphDelta`/`MergeReport` schema, tier semantics, failure contract | **Closed (r2/r3), holds** | `:207-217` |
| 1 | 6 | EXTRACT-phase liveness pre-decided (RC-3) | **Closed (r2), holds** | `:196` |
| 2 | 1 | Reconcile §2.1 `Protocol` with §6.1/§6.2 deltas | **Closed (r3), holds — with a fresh, narrower instance this round; see Consistency Finding A** | `:52-57,76-77` (port list itself now stale re: `agent_id` — see below) |
| 2 | 2 | Episode/attempt-id generation, durability, retry-reuse, owner+tests | **Closed (r8) — the core discriminator gap that survived rounds 2–7 is genuinely closed this round** | `:174` (`seq` discriminator), `test_distinct_dispatches_distinct_keys` |
| 2 | 3 | `record_eval` also returns `AppendResult` | **Closed (r3), holds** | `:54,178,190` |
| 2 | 4 | Concrete schema for the reconciled semantic-merge event | **Closed (r3), holds** | `:198-204` |
| 2 | 5 | Bound/coalesce shadow-copy cost; tie to M1 trigger | **Closed (r3), holds** | `:217` |
| 3 | 1 | Attempt-index granularity vs. batched `evals` row | **Closed (r4), holds** | `:172` "the work unit is the eval run" |
| 3 | 2 | Write path for `prune_orphans`/`decay_edges` | **Closed (r4), holds** | `:207-214`, `:141` |
| 3 | 3 | §5 schema staleness vs. §6.1 delta | **Closed (r4), holds** | `:138` |
| 3 | 4 | `GraphDelta.provenance` singular vs. per-tick coalescing | **Closed (r4), holds** | `:213` |
| 3 | 5 | Schema for the durable work-unit row | **Closed (r5/r7), holds, extended this round with `agent_id`** | `:138` |
| 4 | 1 | Concrete `work_unit_opened` schema | **Closed (r5), holds, extended (r7/r8)** | `:138` |
| 4 | 2 | Port method + bootstrap resolution | **Closed (r5), holds** | `:53,175` |
| 4 | 3 | `AppendResult` 2-vs-3-field contradiction | **Closed (r5), holds** | `:53-55,178,190` |
| 4 | 4 | Disposition of evidence after rejection | **Closed (r7), holds, extended this round with the growth bound** | `:138,182` |
| 4 | 5 | Embedded-tier `attempt_idx` count-then-insert race | **Closed (r6) in substance; citation-precision fixed this round — see item 6.5 below** | `:175` |
| 5 | 1 | Idempotency mechanism for `open_work_unit`, or bound the residual risk | **Closed (r7), holds** | `:175`, `test_same_intent_concurrent_open` |
| 5 | 2 | Regression test for the mint-side double-count scenario | **Closed (r7), holds** | `test_ack_loss_recovery_no_double_count`, `:224` |
| 5 | 3 | Race-safety of `attempt_idx` derivation | **Closed (r6), holds** | `:175` |
| 5 | 4 | Caller obligation / store capability for rejected evidence | **Closed (r7), holds, extended (growth bound)** | `:138,182` |
| 5 | 5 | Consolidate the two test lists | **Closed (r8) — first round this is genuinely done** | `:184,223-225` |
| 6 | 1 | Add `intent_key`/`tick` as a persisted, documented field | **Closed (r7), holds** | `:138,175` |
| 6 | 2 | Fix the `rejected_ingest` schema contradiction | **Closed (r7), holds** | `:138,182` |
| 6 | 3 | Specify combined find-or-create atomicity + same-key concurrent test | **Closed (r7), holds** | `:175`, `test_same_intent_concurrent_open` |
| 6 | 4 | Bound `rejected_ingest`'s (full-payload) growth | **Closed (r8)** | `:182` (`w_rejected`, `test_rejected_payload_pruned_after_window`) |
| 6 | 5 | Correct the embedded-tier concurrency-mechanism citation | **Closed (r8)** | `:175` ("SQLite is natively transactional on the embedded tier... TruthStore never borrows §6.2's graph writer lock") |
| 6 | 6 | Reconcile the mismatched §5.3/§17.6 rate-bounding citation | **Closed (r8)** | `:178` ("the store imposes no rate limit on `open_work_unit`") |
| 6 | 7 | Consolidate the two test lists | **Closed (r8), same item as 5.5** | `:184,223-225` |
| 6 | 8 | Address the rotating-sample/occurrence-identity interaction | **Closed (r7), holds** | `:175`, `test_resumed_work_unit_reuses_pinned_items` |
| 7 | 1 | Define `action_fingerprint`; guarantee two distinct dispatches differ; add a regression test | **Closed (r8)** | `:174` (`seq` discriminator, `action_fingerprint` explicitly non-discriminating), `test_distinct_dispatches_distinct_keys` |
| 7 | 2 | State whether/how `dispatch`'s own append is idempotent under retry | **Closed (r8)** | `:174` ("follows the general §6.1 identity rule — hash over `(record_type ‖ payload incl. seq)`, `ts` excluded") |
| 7 | 3 | Add `dispatch` to the administrative-events exemption list | **Closed (r8)** | `:180` ("administrative events (**`dispatch`**, `selfmod_rejected`, `component_invoked`, `rejected_ingest`)") |
| 7 | 4 | Correct the embedded-tier concurrency-mechanism citation | **Closed (r8), same item as 6.5** | `:175` |
| 7 | 5 | Reconcile the §5.3 rate-bounding citation | **Closed (r8), same item as 6.6** | `:178` |
| 7 | 6 | Bound `rejected_ingest`'s growth | **Closed (r8), same item as 6.4** | `:182` |
| 7 | 7 | Consolidate the two test lists | **Closed (r8), same item as 5.5/6.7** | `:184,223-225` |
| 7 | 8 | Scope `intent_key`/`work_unit_opened`/`dispatch`/`evals` by `agent_id` before §18 | **Closed in schema, with a fresh, narrower port-signature gap — see Consistency Finding A** | `:138` (schemas), `:53` (port signature not updated to match) |

**Net verdict on the task's framing:** the calling agent's brief states all eight round-7 items are "now addressed." Independent verification confirms this is **substantially true** — all eight are genuinely closed at the level round 7 asked for, and this is the first round in the gate's eight-round history where every open item from the prior round is closed rather than partially closed or silently dropped. The hunt below is for what this round's own fixes newly expose — consistent with the pattern every round of this gate has followed since round 2.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 79 | acceptable |
| 2 | Design faithfulness | 85 | pass |
| 3 | Red-team resistance (CRITICAL) | 76 | acceptable |
| 4 | Implementability | 75 | acceptable |
| 5 | Safety / integrity (CRITICAL) | 80 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 76 | acceptable |
| 8 | Consistency | 68 | weak |
| 9 | Calibration / honesty | 74 | acceptable |

## Findings by dimension

### 1. Correctness

**The central round 2–7 defect — no discriminator that guarantees two genuinely distinct same-action dispatches receive different `intent_key`s — is genuinely and correctly closed.** `DATA-LAYER.md:174`: "`seq` is the discriminator: the persisted count of prior dispatches for that `(agent, episode, suite)`, assigned atomically inside the append's own transaction — so two *genuinely distinct* dispatch decisions, even selecting the *identical action* in the same episode (routine repeated practice), always carry different `seq` and therefore different ids." This is the correct fix: `seq` is monotonic per `(agent, episode, suite)` by construction, and `action_fingerprint` is explicitly demoted to "a content descriptor only, never the discriminator" (`:174`). `attempt_idx := dispatch.seq` (`:175`, "one counter, not two") removes the historical two-counter drift risk. This is real, verifiable, and correctly derived — not a restatement.

**A new, narrower correctness/specification gap: `open_work_unit`'s derivation of `attempt_idx` from `dispatch.seq` requires a lookup of the dispatch event by `id = intent_key`, and nothing states this lookup is validated.** `:175` — "`TruthStore.open_work_unit(episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}` with `attempt_idx := dispatch.seq`" — presupposes that `open_work_unit` reads an existing `dispatch` row keyed by `intent_key` to obtain its `seq`. This is the **mint-side** analog of the well-specified **reference-side** check at `:178` (`append_event`/`record_eval` reject a posterior-moving record whose occurrence references no `work_unit_opened` row). No equivalent sentence states what happens if `open_work_unit` is called with an `intent_key` that does not correspond to any previously-appended `dispatch` event (a caller bypassing step 1 entirely, or a bug that mints an `intent_key` that isn't actually a dispatch-event hash). Two developer resolutions are equally plausible from the text as written — reject with an error (symmetric with `:178`'s posture) or silently fail/default `attempt_idx` some other way — and the document doesn't pick one. This is narrower than round 7's finding (the discriminator itself is now sound), but it is a real, unstated gap in the same family.

**A secondary, location/attribution imprecision: the atomicity guarantee for `seq` is asserted twice, once correctly (at the dispatch append, `:174`) and once in a way that describes the wrong operation (at `open_work_unit`, `:175`).** `:175`: "no count-then-insert race exists for `seq`/`attempt_idx` on either tier" is stated in the paragraph about `open_work_unit`'s minting step — but per the design, `seq` is generated once, at the **dispatch append** (`:174`, "assigned atomically inside the append's own transaction"), not inside `open_work_unit`, which by this round's own design merely receives an already-fixed `intent_key`/`seq` pair and mints (or returns) a `WorkUnit` from it. Restating the same atomicity guarantee under the wrong operation's paragraph is not a contradiction of substance (both operations are claimed atomic), but it is imprecise in exactly the way that a careful reader building `test_attempt_idx_atomic_under_concurrency` would need resolved — see Completeness.

### 2. Design faithfulness

Faithful and, in one respect, newly strengthened: the record-class exemption pattern (`work_unit_opened` as identity-root, `dispatch`/`selfmod_rejected`/`component_invoked`/`rejected_ingest` as administrative, `:180`) mirrors `ALGORITHM-v0.2-pathway-learner.md:503`'s `self_modify`-admission-failure pattern exactly, and `agent_id`'s addition to `events`/`evals`/`work_unit_opened`/`dispatch` (`DATA-LAYER.md:138`) is a correct, faithful extension of §18.1's per-agent `StateStore` keying pattern (`ALGORITHM-v0.2-pathway-learner.md:521`) and §17.6's precedent on `lineage.agent_id` (already established, cited at `DATA-LAYER.md:138`). The rate-bounding honesty fix (`:178`, "the store imposes no rate limit on `open_work_unit`... a compromised orchestrator could mint freely, and the defense there is that minting alone moves no posterior") is faithful to §17.1's actual JUDGE/SOLVE partition (`ALGORITHM-v0.2-pathway-learner.md:452-457`) rather than borrowing an unrelated §5.3 mechanism, correctly closing the citation mismatch rounds 6–7 both flagged. No divergence found from §§2–15's layering or naming conventions this round.

### 3. Red-team resistance

**RC-3 and RC-4 remain closed**, unaffected by this round.

**RC-1 (point estimates / undercounting where a discriminator is required) — the specific instance round 7 found (silent merging of genuinely distinct dispatches) is closed.** `test_distinct_dispatches_distinct_keys` (`:224`, "two independent dispatches selecting the IDENTICAL action in one `(episode, suite)` ⇒ distinct `seq` ⇒ distinct `intent_key`s, two work units — the round-7 silent-merge regression") directly targets the round-7 failure mode by name. This is a genuine closure of a CRITICAL-severity finding that survived rounds 2 through 7.

**A narrower, fresh RC-1-adjacent residual, one layer over from where round 7 found its issue: the mint-side lookup gap (Correctness, above).** If `open_work_unit` does not validate that `intent_key` resolves to a real, previously-appended `dispatch` row before deriving `attempt_idx`, a caller with a fabricated or stale `intent_key` has an unspecified failure mode — this is not demonstrated to reopen under-counting or over-counting outright (the discriminator logic itself remains sound wherever a real dispatch exists), so it does not warrant a 0, but it is a real, uncovered gap in the exact family of concern (mint-side validation) this gate has spent multiple rounds closing on the reference side. Scored "acceptable," reflecting genuine, substantial progress with one bounded residual, not a re-fired failure mode.

### 4. Implementability

Concrete round-8 positives: `seq`'s derivation and role are unambiguous and buildable (`:174`); the growth-bound mechanism for `rejected_ingest` is concrete and testable (`w_rejected`, prune-to-hash, `:182`); the corrected embedded-tier citation (`:175`) and the honest no-rate-limit statement (`:178`) remove two developer-facing false leads; the single consolidated test list (`:223-225`) gives a developer one place to build a suite against, ending a discoverability gap flagged in five consecutive rounds (3–7).

Remaining/new gaps a developer would have to resolve by guessing:
- **`open_work_unit`'s Protocol signature (`DATA-LAYER.md:53`: `open_work_unit(self, episode_id, suite_id, intent_key) -> WorkUnit`) has no `agent_id` parameter, yet `work_unit_opened`'s schema (`:138`) and `dispatch`'s schema (`:138`) both now carry `agent_id` as a column.** A developer implementing this port cannot tell whether `agent_id` is (a) bound to the `TruthStore` instance at construction time (a per-agent-scoped store, consistent with "single-agent default is a constant," `:138`), (b) threaded through some other unstated channel, or (c) simply omitted from the signature by oversight. This is the same class of gap (a schema field with no corresponding, updated port-level plumbing) that recurred at §2.1 in round 2, at §5 in round 3, and at `AppendResult` in round 4 — this round's instance is narrower (one missing parameter, not a flat contradiction) but is a fresh occurrence of the pattern, introduced by this round's own `agent_id` delta.
- **No stated validation for `open_work_unit`'s `intent_key → dispatch` lookup** (Correctness, above) — a developer has no guidance on the rejection/error contract for a fabricated or missing `intent_key`.
- **The dispatch-append's own atomic `seq`-assignment mechanism is asserted ("assigned atomically inside the append's own transaction," `:174`) but not specified at the same level of concreteness §6.2 gives its own atomicity mechanism** (shadow-copy + single-writer lock, `:217`) — is this a `SELECT COUNT... `then `INSERT` inside a `SERIALIZABLE` transaction, a dedicated counter row with row-level locking, or an auto-incrementing sequence keyed by `(agent, episode, suite)`? Any of these would work, but none is named, leaving the actual concurrency-safety mechanism to a developer's judgment call rather than the document's specification.

### 5. Safety / integrity

No §8 gate clause, §14 formula, or §19 calibration knob is touched — structurally clean, as in every prior round.

**The growth-bound fix for `rejected_ingest` (`:182`) closes a genuine, round-6/7-flagged storage/DoS surface**: full-payload retention is now paired with a stated retention window (`w_rejected`, default 30 days) after which the payload is pruned to a hash while the row persists — "the same blobs-prunable/rows-permanent discipline as §10/§17.6," a correct reuse of an already-established pattern rather than a new one.

**Because the mint-side lookup gap (Correctness/Red-team, above) is unresolved, a narrow residual risk to the evidentiary base feeding §9's `sustained_heldout`, §17.3's monitored-subset check, and §19.1's `r̂`/`q_explore`** (`ALGORITHM-v0.2-pathway-learner.md:253,464-465,561-565`) persists in the one case where `open_work_unit` is invoked without a valid preceding `dispatch` — narrower and less severe than any prior round's version of this concern (the discriminator itself is sound), which is why this scores "pass" rather than "acceptable" as in most prior rounds, with the residual noted rather than driving the score down further.

### 6. Efficiency / cost

Unaffected and still sound on the parts untouched this round: `O(|V|+|E|)` shadow-copy cost, coalesced to one `merge()` per loop tick, tied to the §9 M1 flip trigger (`:217`). The new `rejected_ingest` growth bound (`w_rejected`) genuinely closes what round 6 flagged as an unrated, unbounded storage-growth path — real cost-profile improvement, not merely a documentation fix. No new hot-path cost introduced. Scored "pass."

### 7. Completeness

Genuine improvements: the consolidated **write-discipline test set** (`:223-225`) now lists 20 tests in one place (13 for §6.1, 7 for §6.2) — closing a gap flagged in five consecutive rounds (3, 4, 5, 6, 7); `test_distinct_dispatches_distinct_keys` and `test_rejected_payload_pruned_after_window` are new, concrete, and each targets exactly the failure mode its round introduced.

Residual/new gaps:
- **No test for the mint-side `intent_key → dispatch` validation gap** (Correctness, above) — none of the 20 listed tests exercises `open_work_unit` called with a fabricated or non-existent `intent_key`.
- **`test_attempt_idx_atomic_under_concurrency`'s description ("concurrent opens, distinct keys ⇒ distinct gapless `seq`," `:224`) targets `open_work_unit`, but per the current design `seq` is generated at the dispatch-append step, not inside `open_work_unit`** (Correctness, above) — the test as named doesn't obviously exercise the actual race window the design now has (concurrent dispatch appends for the same `(agent, episode, suite)`), a minor but real test-scope/design mismatch.
- **No test asserts `agent_id`'s presence/enforcement on `open_work_unit`'s written row** given the port-signature gap (Implementability, above).

### 8. Consistency

**A fresh, narrower instance of the recurring "schema updated, corresponding declaration not co-updated" defect class — this round's version of a pattern present in every one of the prior seven rounds.** `DATA-LAYER.md:138` adds `agent_id` to `work_unit_opened` and `dispatch`'s schemas (this round's own item-8 fix), but `DATA-LAYER.md:53`, the canonical §2.1 `Protocol` block (the exact site round 2 found stale and round 3 verified fixed), still declares `open_work_unit(self, episode_id, suite_id, intent_key) -> WorkUnit` with no `agent_id` parameter — and no other line states how (or whether) `agent_id` reaches the row `open_work_unit` writes. This is materially narrower than round 2's contradiction (a missing parameter, not a flatly wrong return type) and does not, by itself, make any single claim in the document false — but it is the same defect class recurring an eighth time, this time triggered by the very delta (`agent_id` fleet-scoping) this round was asked to add.

**A second, milder consistency wrinkle: the dispatch event's stated identity-hash rule doesn't cleanly restate the general §6.1 formula's shape.** The general rule (`:163-167`) is `id = hash(record_type ‖ semantic_payload ‖ occurrence_provenance)` with `occurrence_provenance = episode/trace id + checkpoint_id + attempt index`. `dispatch`'s own hash rule (`:174`) is described as "hash over `(record_type ‖ payload incl. seq)`, `ts` excluded" — a different decomposition (no `checkpoint_id` component at all; `dispatch`'s schema at `:138` has no `checkpoint_id` field) that is nonetheless described as "the general §6.1 identity rule." Since `dispatch` is administrative (never posterior-moving, per `:180`), the general rule's `checkpoint_id` requirement — stated for records that "move a posterior" (`:161`) — may not strictly apply to it, and the practical uniqueness of `dispatch`'s id is not in doubt (`seq` alone, scoped to `(agent, episode, suite)`, is sufficient). But calling a differently-shaped formula "the general rule" without noting the divergence is a loose cross-reference, not a hard contradiction — scored here as a contributing, non-blocking factor.

The recurring test-attribution mismatch (Completeness, above) is also, at bottom, a consistency gap between prose and the test it names.

### 9. Calibration / honesty

**Markedly more honest than round 7 on the two claims that most needed it.** `:178`'s "On mint rate, stated plainly: the store imposes no rate limit on `open_work_unit`... a compromised orchestrator could mint freely, and the defense there is that minting alone moves no posterior (only gated eval outcomes do)" is exactly the caveat rounds 6–7 asked for in place of the previously-false §5.3 citation — a genuine, well-calibrated admission of a real limit rather than an invented mitigation. The embedded-tier citation fix (`:175`) replaces an incorrect claim with a correct, appropriately modest one ("SQLite is natively transactional... TruthStore never borrows §6.2's graph writer lock").

One overclaim-adjacent residual persists in the same register rounds 3–7 each flagged: `:180`'s heading, "**No circularity, no unenforced hole — the exemption is by record class, and the class is checkable**," is accurate for the specific claim it makes (the administrative/identity-root exemption boundary is a genuine, checkable property of the update path) but is stated with the same confident, closing-the-loop cadence that has, in six of the prior seven rounds, preceded a residual the section's own text did not yet support. This round, the specific claim under that heading holds up under scrutiny — but the heading's placement invites a reader to conclude the *entire* mint/reference lifecycle has "no unenforced hole," when the mint-side `intent_key → dispatch` lookup (Correctness, above) is, in fact, an unaddressed hole one layer over from what the heading's own paragraph discusses. This is a narrower version of the historical overclaiming pattern — the sentence is true as scoped, but its rhetorical reach exceeds what the surrounding section actually closes.

## Strongest adversarial objection

**The `dispatch`-then-`open_work_unit` two-step lifecycle creates a window, unaddressed by any of the twenty listed tests, in which a `dispatch` event can be durably appended and never followed by a corresponding `open_work_unit` call — and nothing in the section states what, if anything, notices.** `DATA-LAYER.md:174` has the orchestrator "declare intent, durably and distinctly" by appending a `dispatch` event *before* any work begins; `:175` then mints (or resumes) a work unit from that event's id. The crash-recovery story at `:176` ("on restart, the orchestrator scans truth for work units with no terminal eval record and resumes them") is scoped to *work units* — but a crash between the `dispatch` append succeeding and the *subsequent* `open_work_unit` call (a narrower, earlier window than the crash-after-`open_work_unit` case the recovery scan already handles) leaves a durable `dispatch` row with **no** corresponding `work_unit_opened` row at all. Does the recovery scan at `:176` also scan for *dispatches* with no corresponding work unit, and resume from there? The text only says it scans "work units with no terminal eval record" — silent on orphaned dispatches. If it does not, such a `dispatch` event is simply inert forever (harmless, since `dispatch` moves no posterior, `:180`) — but if some later process, or a differently-implemented recovery path, ever treats "the most recent `dispatch` for `(agent, episode, suite)`" as authoritative for deriving the *next* `seq` (a very natural implementation, since `:174` defines `seq` as "the persisted count of prior dispatches"), an orphaned dispatch with no work unit still correctly increments the count for future dispatches (this part is fine — `seq` counts dispatch rows, not work-unit rows) but **the orchestrator itself has no stated way to know, on restart, whether its last dispatch was ever turned into a work unit**, and therefore no stated way to decide whether to call `open_work_unit(intent_key=<that dispatch's id>)` (resuming the abandoned intent) or to issue a **fresh** dispatch (abandoning it, which would silently strand that `seq` value forever — harmless for correctness, since `seq` values need not be dense, but a real, unexamined "orphaned intent" case the document's own five-step lifecycle (`:174-178`) implies is handled by "recover by reading truth" without ever stating the read includes dispatches, not just work units). None of the nine dimensions above surface this because each was scoped to the mint/reference/rejection mechanics `:174-182` state explicitly; this finding only appears when the two-step (`dispatch` → `open_work_unit`) design is read against the single recovery sentence at `:176`, which names only one of the two record types the lifecycle now has.

## Aggregate confidence

```
critical_floor  = min(Correctness=79, RedTeam=76, Safety=80) = 76
weighted_mean   = (79*2 + 85 + 76*2 + 75 + 80*2 + 85 + 76 + 68 + 74) / 11
                = (158 + 85 + 152 + 75 + 160 + 85 + 76 + 68 + 74) / 11
                = 933 / 11
                = 84.8 → 85
overall         = min(76, 85) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

This is the strongest result in the gate's eight-round history (76, vs. round 7's 42) and the **first round in which all three CRITICAL dimensions clear 70** (Correctness 79, Red-team 76, Safety 80) — genuine, independently-verified progress: all eight of round 7's numbered items are closed, including the core discriminator defect (`seq`) that had survived rounds 2 through 7 unresolved. The verdict remains `needs-revision` because the aggregate (76) is below the 80 threshold, driven by a handful of narrower, newly-surfaced gaps this round's own fixes expose — consistent with the pattern every round of this gate has shown since round 2 (closing one layer reveals the next):

1. **Add `agent_id` to `open_work_unit`'s Protocol signature (`DATA-LAYER.md:53`), or state explicitly that it is bound to the `TruthStore` instance at construction (per-agent-scoped store) rather than passed per call.** `work_unit_opened` and `dispatch`'s schemas (`:138`) both carry `agent_id` as a column; the port method that writes the former has no parameter or stated binding to supply it.
2. **State whether `open_work_unit` validates that `intent_key` resolves to a real, previously-appended `dispatch` row before deriving `attempt_idx := dispatch.seq`, and what happens if it does not** (a fabricated or missing `intent_key`) — the mint-side analog of the reference-side check already specified at `:178`. Add a regression test for this case.
3. **Relocate or duplicate the atomic-`seq`-assignment guarantee to the dispatch-append step, where `seq` is actually generated** (`:174`), rather than stating "no count-then-insert race... for `seq`" only under `open_work_unit`'s paragraph (`:175`); name the actual mechanism (e.g., a `SERIALIZABLE` transaction, a locked counter row, or a DB-native sequence keyed by `(agent, episode, suite)`) at the same level of concreteness §6.2 gives its own shadow-copy/lock mechanism.
4. **Correct `test_attempt_idx_atomic_under_concurrency`'s description** (`:224`) to target the operation where the race actually lives under the current design (the dispatch append's `seq` derivation), or clarify that `open_work_unit`'s own idempotent-return-existing path is a distinct, already-covered case.
5. **State whether the crash-recovery scan (`:176`) also covers a `dispatch` event with no corresponding `work_unit_opened` row** (the adversarial-pass finding), or state explicitly that an orphaned dispatch is harmless-by-design and requires no recovery action.
6. **Loosen or scope the "follows the general §6.1 identity rule" claim for `dispatch`'s own hash** (`:174`) to acknowledge it omits `checkpoint_id` (which `dispatch`'s schema doesn't carry), rather than presenting a differently-shaped formula as an unqualified instance of the general rule.

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-63","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r8.md","why":"360 review (round 8) of DATA-LAYER.md §6.1/§6.2 revised r8 -- overall 42 -> 76/100, needs-revision but the strongest result in 8 rounds and the first round where all 3 CRITICAL dims clear 70 (Correctness 79, RedTeam 76, Safety 80): all 8 of round-7's numbered items independently verified closed, including the core seq-discriminator fix that survived rounds 2-7 unresolved (action_fingerprint demoted to non-discriminating content descriptor, seq = persisted per-(agent,episode,suite) dispatch count is now the sole discriminator, backed by test_distinct_dispatches_distinct_keys), the embedded-tier SQLite-vs-networkx citation fixed, the false §5.3 rate-bound citation replaced with an honest no-rate-limit statement, rejected_ingest given a w_rejected growth bound, the two test lists finally consolidated into one 20-test set, and agent_id fleet-scoping added to events/evals/work_unit_opened/dispatch; this round's own agent_id delta introduces a fresh, narrower instance of the gate's recurring schema-vs-port-signature defect class (open_work_unit's Protocol signature at DATA-LAYER.md:53 has no agent_id parameter despite the schema requiring one), plus an unvalidated mint-side intent_key-to-dispatch lookup and a seq-atomicity guarantee stated under the wrong operation's paragraph; adversarial pass finds the crash-recovery scan is stated to cover orphaned work units but is silent on whether it also covers a dispatch event with no corresponding work_unit_opened row","evidence":["docs/research/DATA-LAYER.md §2.1 (lines 52-57), §5 (line 138), §6.1/§6.2 (lines 159-225)","docs/research/reviews/DL-write-discipline-review-r7.md","docs/research/reviews/DL-write-discipline-review-r6.md","docs/research/reviews/DL-write-discipline-review-r5.md","docs/research/reviews/DL-write-discipline-review-r4.md","docs/research/reviews/DL-write-discipline-review-r3.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §3 (lines 54-69), §4.1 (lines 77-87), §5.1 (lines 115-141), §5.3 (lines 158-173), §6 (lines 177-207), §9 (lines 242-260), §10 (line 266), §17.1 (lines 452-457), §17.6 (lines 479-510), §18.1 (line 521), §19.1 (lines 561-563)","docs/research/ALGORITHM-v0.1-redteam.md RC-1 (lines 36-39), RC-3 (lines 46-49), RC-4 (lines 51-53)","docs/research/HUMAN-LEARNING-VERIFIER.md:35"],"outcome":"pending"}
```
