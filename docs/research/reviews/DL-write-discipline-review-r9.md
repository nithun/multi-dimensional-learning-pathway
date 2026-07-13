# 360 Review: DL-write-discipline — 2026-07-13 (Round 9)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing," lines 159–190) and §6.2 ("Two-phase projection writes — extract, then transactional merge," lines 192–225), both marked *revised r9 — IN GATE* |
| Proposed change | Round-9 rewrite claiming to close round 8's four narrow items + one adversarial finding: (1) `open_work_unit`'s §2.1 `Protocol` signature gains an `agent_id` parameter; (2) `open_work_unit` now validates that `intent_key` resolves to a real `dispatch` row before deriving `attempt_idx`, rejecting otherwise, with `test_open_requires_dispatch_row`; (3) the atomic-`seq`-assignment guarantee is relocated to the dispatch-append step (step 1), with `open_work_unit` stated to only *copy* the value ("open performs no counting of its own"); (4) the mis-scoped test is renamed `test_seq_atomic_under_concurrency` with a corrected description; (5) the crash-recovery scan is now stated to cover both orphan kinds — work units with no terminal eval, and `dispatch` rows with no `work_unit_opened` row — via `test_recovery_completes_lost_mint`. |
| Reviewer | review-360 |
| Round | 9 (`-r9`) — round 1: `docs/research/reviews/DL-write-discipline-review.md` (38/100); round 2: `-r2.md` (78/100); round 3: `-r3.md` (68/100); round 4: `-r4.md` (64/100); round 5: `-r5.md` (66/100); round 6: `-r6.md` (44/100, regression); round 7: `-r7.md` (42/100, flat, 8 items in verdict); round 8: `-r8.md` (76/100, strongest of all rounds, all criticals ≥70, 6 items in verdict) |
| Date | 2026-07-13 |

**Circuit-breaker:** `agents.status = "open"` (`.claude/memory/circuit-breaker.json:6`, `last_run` 2026-07-03) → filing as a direct review, not a proposal.

## Full round 1–8 audit — every numbered item, closed or explicitly carried

Rounds 1–7's audit (verified independently in round 8, `reviews/DL-write-discipline-review-r8.md` lines 17–58) is carried forward unchanged; nothing in this round touches those closures. This table adds round 8's own six verdict items, freshly audited against the r9 text.

| Round | # | Item | Status as of r9 | Evidence |
|---|---|---|---|---|
| 1–7 | all | (38 items, see r8 lines 17–58) | **Carried, all still hold** — unaffected by r9's changes | `docs/research/reviews/DL-write-discipline-review-r8.md:17-58` |
| 8 | 1 | Add `agent_id` to `open_work_unit`'s Protocol signature (`:53`), or state it's bound at construction | **Closed in the canonical Protocol and lifecycle text — NOT closed in the §6.1 "Port delta" summary line, which still shows the stale 3-arg form** | `DATA-LAYER.md:53` (`def open_work_unit(self, agent_id, episode_id, suite_id, intent_key)`), `:175` (same 4-arg form) **vs.** `:190` (`TruthStore.open_work_unit(episode_id, suite_id, intent_key)` — no `agent_id`) — see Consistency Finding A below |
| 8 | 2 | State whether `open_work_unit` validates `intent_key → dispatch`, and what happens if not; add a test | **Closed in substance, residual on the failure-signaling mechanism** | `:175` ("Open validates its reference first... rejected"), `test_open_requires_dispatch_row` `:224` — see Correctness Finding A below (the `WorkUnit` return type has no stated rejection channel) |
| 8 | 3 | Relocate/duplicate the atomic-`seq` guarantee to the dispatch-append step; name the actual mechanism | **Relocation closed; mechanism-naming NOT closed** | `:174` ("assigned atomically inside the append's own transaction") — still asserts atomicity without naming a concrete mechanism (row lock / `SERIALIZABLE` tx / DB sequence), unlike §6.2's named shadow-copy+lock (`:217`) |
| 8 | 4 | Correct `test_attempt_idx_atomic_under_concurrency`'s description/target | **Closed** | `:224` — renamed `test_seq_atomic_under_concurrency`, description now "concurrent `dispatch` appends ⇒ distinct gapless `seq` — the counter is assigned at dispatch, opens only copy it; no lost update on either tier" |
| 8 | 5 | State whether the crash-recovery scan also covers an orphaned `dispatch` (the r8 adversarial finding) | **Closed** | `:176` ("the orchestrator scans truth for **both** kinds of orphan... `dispatch` rows with no `work_unit_opened` row yet"), `test_recovery_completes_lost_mint` `:224` |
| 8 | 6 | Loosen/scope the "follows the general §6.1 identity rule" claim for `dispatch`'s own hash (it omits `checkpoint_id`) | **NOT addressed — untouched since r8, and not claimed as addressed by this round's own framing either** | `:174` ("it follows the general §6.1 identity rule — hash over `(record_type ‖ payload incl. seq)`, `ts` excluded") — wording is byte-identical in substance to r8; `dispatch`'s schema (`:138`) still has no `checkpoint_id` field, and the divergence from the general formula (`:164-167`, which includes `checkpoint_id`) is still not acknowledged |

**Net verdict on the task's framing.** The calling brief frames round 9 as closing "four narrow items + one adversarial finding" — which maps to r8's verdict items 1–5 (item 5 is explicitly r8's own "adversarial-pass finding" label). This framing is **accurate as scoped**: items 1, 2, 4, and 5 are genuinely, verifiably closed; item 3 is closed only in part (the misattribution is fixed, the mechanism is still unnamed). But the brief is silent on r8's verdict item 6, which **remains completely unaddressed** — not fixed, not acknowledged, not deferred with a stated reason. This is the first round in the gate's history where a numbered verdict item was neither touched nor explicitly carried by name in the revision's own framing; every prior round's regressions were at least visible as "not addressed" in the calling context. Independent audit is what surfaces it here.

Separately, this round's own fix for item 1 (`agent_id` threaded into the canonical `Protocol` at `:53` and the lifecycle prose at `:175`) was not propagated to the "Port delta" summary line at `:190`, which is the exact same subsection's own closing developer-facing reference — see Consistency Finding A. This is the **ninth** occurrence, across nine rounds, of the same "one location updated, a co-dependent location not" defect class that r8 itself named explicitly ("the same defect class recurring an eighth time," r8 §8 finding).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 78 | acceptable |
| 2 | Design faithfulness | 86 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 71 | acceptable |
| 5 | Safety / integrity (CRITICAL) | 79 | acceptable |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 75 | acceptable |
| 8 | Consistency | 62 | weak |
| 9 | Calibration / honesty | 70 | acceptable |

## Findings by dimension

### 1. Correctness

**The core `seq`-discriminator fix (r8's headline closure) is untouched and remains correct.** `DATA-LAYER.md:174`: `seq` is "the persisted count of prior dispatches for that `(agent, episode, suite)`, assigned atomically inside the append's own transaction," with `action_fingerprint` explicitly "a content descriptor only, never the discriminator." Nothing in r9 regresses this.

**Finding A (new, r9-specific) — `open_work_unit`'s stated rejection behavior has no corresponding channel in its own return type.** `:175` states the mint-side validation genuinely closes r8 item 2: "an `intent_key` that resolves to no `dispatch` row is rejected." But the method's signature, both at the canonical `Protocol` (`:53`) and restated at `:175` itself, is `open_work_unit(agent_id, episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}` — a bare `WorkUnit`, with no `rejected`/`rejected_reason` field, and no stated exception type. The document's only precedent for a rejection *contract* is `AppendResult{id, deduped, rejected_reason}` (`:178`), which is explicitly the return type of `append_event`/`record_eval`, not `open_work_unit`. A developer implementing `open_work_unit` per the stated behavior ("rejected") has two equally plausible readings — raise an exception, or return some sentinel/error variant of `WorkUnit` — and the document commits to neither. This is narrower than r8's finding (the *validation itself* is now unambiguous; only the *signaling mechanism* is not), so it does not warrant a floor-level score, but it is a genuine, freshly-introduced gap in the same family the gate has repeatedly found (a stated behavior with no concrete return-type/error-contract to realize it).

**Finding B — the atomic-`seq`-assignment mechanism remains asserted, not named** (r8 item 3, partially closed). `:174`: "assigned atomically inside the append's own transaction" is now correctly scoped to the dispatch-append step (the misattribution to `open_work_unit` that r8 flagged is fixed at `:175`, "open performs no counting of its own"), but *how* the append's transaction assigns a gapless, atomic `seq` (a locked counter row? a `SELECT ... FOR UPDATE`? a DB-native sequence keyed by `(agent, episode, suite)`?) is still not named, at a lower concreteness than §6.2's own atomicity mechanism (`:217`, "shadow copy, then atomically swap... under a single writer lock").

### 2. Design faithfulness

Faithful, and genuinely strengthened in one respect: `agent_id` now appears consistently across the canonical `Protocol` (`:53`) and the lifecycle prose (`:175`), correctly extending §18.1's per-agent `StateStore` keying (`ALGORITHM-v0.2-pathway-learner.md:521`) and §17.6's `agent_id`-on-`lineage` precedent (`ALGORITHM-v0.2-pathway-learner.md:501,507`, "mirroring §18.1's per-agent `StateStore` keying"). The mint-side validation added this round (`:175`) mirrors the reference-side enforcement (`:178`) exactly, giving the identity-root/reference-record boundary symmetric treatment on both the minting and consuming sides — a design move consistent with the section's own stated principle ("identity is only ever copied from the dispatch record, never invented at open," `:175`). No divergence found from §§2–15's layering or naming conventions this round.

### 3. Red-team resistance

**RC-1, RC-3, RC-4 remain closed at the level r8 established.** The core discriminator (`seq`) is unaffected by r9. The r8-era mint-side lookup gap (a fabricated or missing `intent_key` with an unspecified outcome) is now genuinely closed on the *validation* axis — `test_open_requires_dispatch_row` (`:224`) directly targets it, closing what r8 scored "acceptable" with a residual. This raises Red-team resistance from r8's 76.

**The fresh Correctness Finding A (rejection-channel ambiguity) is RC-1-adjacent but not RC-1-reopening.** A developer resolving the ambiguity by, say, raising an unchecked exception a caller doesn't catch could in principle cause an orchestrator to crash rather than gracefully escalate — an availability concern, not a silent double-count or under-count of evidence (the specific disease RC-1 names). Scored here as a residual attack surface, not a reopened root cause: nothing in the text permits `open_work_unit` to *silently* mint a duplicate or phantom occurrence on a bad `intent_key` — the validation itself is stated to reject, unambiguously; only the *shape* of that rejection is unspecified.

### 4. Implementability

Genuine round-9 gains: `open_work_unit`'s Protocol signature (`:53`) now matches its own written row's schema (`work_unit_opened` carries `agent_id`, `:138`) — closing a gap round 8 itself introduced. The dual-orphan recovery scan (`:176`) gives a developer an unambiguous restart algorithm covering both failure windows the two-step (`dispatch` → `open_work_unit`) design creates.

Residual/fresh gaps a developer would still have to resolve by guessing:
- **Finding A above** — no stated return type or exception for `open_work_unit`'s rejection path.
- **Finding B above** — the dispatch-append's own atomicity mechanism is unnamed at implementation-relevant concreteness.
- **The "Port delta" summary at `:190` still cites the pre-fix 3-argument `open_work_unit` signature** (Consistency Finding A, below) — a developer who reads only this line (a natural shortcut, since "Port delta" paragraphs exist precisely to be the terse take-away at the end of each subsection) would build a `TruthStore` implementation that silently drops `agent_id`, undoing this round's own fix and reopening the exact fleet-collision risk r7's adversarial pass first raised and r8 claimed to close.
- Item 8-6 (dispatch's hash-formula divergence from the general rule) is still unresolved, so a developer implementing `dispatch`'s identity hash from `:164-167`'s general formula (which includes `checkpoint_id`) rather than from `:174`'s narrower restatement (which doesn't) could produce a different, non-matching hash than intended — a latent ambiguity, not yet closed.

### 5. Safety / integrity

No §8 gate clause, §14 formula, §19 calibration knob, or verifier gate is touched — structurally clean, as in every prior round.

**Because `:190`'s stale summary line contradicts `:53`/`:175`'s corrected signature, the fleet-scoping fix itself carries a live implementation risk.** The whole point of adding `agent_id` to `open_work_unit` (r7's adversarial finding; r8's item 1) was to prevent two different fleet agents from colliding on the same `intent_key` and one silently inheriting the other's occurrence identity (`ALGORITHM-v0.2-pathway-learner.md:521`, §18.1's per-agent `StateStore` keying is the precedent this exists to protect). If a developer builds strictly from the section's terminal "Port delta" reference (`:190`) rather than the fuller prose above it, the fleet-collision protection is not actually wired in, even though two other passages in the very same subsection state it correctly. This is a genuine, if narrow and avoidable-by-careful-reading, integrity residual — narrower than r7's original finding (which had *no* passage stating the fix), but real.

**The `open_work_unit` rejection-channel ambiguity (Correctness Finding A) is a second, smaller safety-adjacent residual** feeding the same evidentiary base §9's `sustained_heldout`, §17.3's monitoring, and §19.1's `r̂`/`q_explore` depend on (`ALGORITHM-v0.2-pathway-learner.md:253,464-465,561-565`) — bounded, since the validation itself unambiguously rejects; only the caller's ability to *observe and handle* that rejection cleanly is unspecified.

### 6. Efficiency / cost

Unaffected: `O(|V|+|E|)` shadow-copy cost, coalesced to one `merge()` per loop tick, tied to the §9 M1 flip trigger (`:217`), and the `w_rejected` growth bound on `rejected_ingest` (`:182`) both carry over from r8 unchanged. No new hot-path cost introduced this round.

### 7. Completeness

Genuine gains: `test_open_requires_dispatch_row` and `test_recovery_completes_lost_mint` (`:224`) are new, concrete, and each targets exactly the gap its predecessor round named. `test_seq_atomic_under_concurrency`'s renamed description now correctly targets the dispatch-append race rather than `open_work_unit`'s.

Residual/fresh gaps:
- **No test exercises the shape of `open_work_unit`'s rejection** (Correctness Finding A) — `test_open_requires_dispatch_row`'s stated description ("an `intent_key` resolving to no `dispatch` row is rejected at open," `:224`) confirms *that* rejection happens but not *how* (exception type / return value), leaving the ambiguity untested as well as unspecified.
- **No test targets `:190`'s stale summary directly** — unsurprising, since a doc-internal cross-reference isn't code, but a `test_protocol_signature_matches_schema`-style static check (or simply a documentation-consistency pass before each gate submission) would have caught this ninth recurrence of the pattern before this review did.
- **Item 8-6 remains untested** — no test asserts or denies whether `dispatch`'s hash includes `checkpoint_id`.

### 8. Consistency

**Finding A (new, headline) — the §6.1 "Port delta" summary line contradicts the very subsection's own canonical Protocol and lifecycle prose on `open_work_unit`'s signature.** `DATA-LAYER.md:53` (§2.1, the canonical `Protocol`) and `:175` (the lifecycle prose, step 2) both state `open_work_unit(agent_id, episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}` — the 4-argument, `agent_id`-carrying form this round's own fix (r8 item 1) introduced. But `:190`, the "Port delta" sentence closing §6.1 — the exact place a developer looks for a terse restatement of what changed — still reads: "`TruthStore.open_work_unit(episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}`" (idempotent on `intent_key`)" — the pre-fix, 3-argument form, verbatim from round 8's own (then-broken) text. This is not a new class of defect; it is the *same* class r8's own Consistency section named explicitly ("a fresh, narrower instance of the recurring 'schema updated, corresponding declaration not co-updated' defect class... present in every one of the prior seven rounds") — recurring here for a **ninth** time, and specifically in the one line this round's own fix should have touched but didn't. The behavioral ground truth is not in doubt (two of three restatements agree, and agree with the schema at `:138`), which is why this is scored "weak" rather than "blocking" — but a document that has now stated the identical caveat about itself eight times without the pattern stopping is a genuine, worsening consistency signal, not a one-off slip.

**Finding B (carried, unresolved) — `dispatch`'s hash-formula restatement still diverges from the general rule it claims to follow, without acknowledging the divergence** (r8 item 6, see the audit table). `:174`'s "hash over `(record_type ‖ payload incl. seq)`" omits `checkpoint_id`, which the general rule (`:164-167`) requires as part of `occurrence_provenance`; `dispatch`'s schema (`:138`) has no `checkpoint_id` field. Calling this "the general §6.1 identity rule" without noting the divergence, verbatim as in r8, is a loose cross-reference carried unchanged.

**Minor, non-blocking, carried:** `BUILD-SPECS.md:311` ("Mode dispatch (per `EXPAND`)") uses "dispatch" as a term of art for retrieval-mode selection, unrelated to this section's `dispatch` TruthStore event kind — the same terminology collision r7 flagged as worth a rename for developer clarity, still present, still non-blocking.

### 9. Calibration / honesty

**More honest than r7/r8 in one specific respect: the calling brief's own framing ("four narrow items + one adversarial finding") is scoped accurately to what it claims** — it does not overclaim closure of r8 item 6, it simply omits mentioning it, which this review treats as a real gap rather than a false claim of closure (contrast with r7's brief, which claimed "ALL are now addressed" for a broader set than was actually true).

**The persistent overclaiming pattern in the document's own text is unchanged, and newly undercut by Finding A above.** `:180`'s heading, "**No circularity, no unenforced hole — the exemption is by record class, and the class is checkable**," is carried verbatim from r7/r8. The specific claim it makes (the administrative/identity-root exemption boundary) still holds up. But the heading sits nine lines above `:190`'s stale summary — a literal, verifiable self-contradiction within the same subsection the heading's confident framing describes. A reader taking the heading's cadence at face value would not expect to find, ten lines later, the section's own terminal reference line stating the wrong method signature for the one method (`open_work_unit`) the heading's very sentence discusses ("`open_work_unit` is therefore the one legitimate entry point that creates identity," `:180`). This is the same overclaiming register rounds 3–8 have each flagged, now co-located with its clearest concrete counterexample yet.

## Strongest adversarial objection

**The durable, queryable `item_ids` pinned at `work_unit_opened` (and echoed on `evals`) may leak §4.1's secret held-out split through the generic, access-control-free `read_events` port — undermining the very secrecy guarantee the whole eval harness depends on, and no round of this eight-round-plus gate has examined it.** `ALGORITHM-v0.2-pathway-learner.md:81` (§4.1) states the reward-bearing sample is `secret = suite[s].held_out @ rotating_sample # never enters ctx` — the entire generalization-gate argument (`:85`, `Δĉ_secret ≥ ρ_gen·Δĉ_public`) depends on the secret split staying outside anything the agent under evaluation (or code acting on its behalf) can read. But `DATA-LAYER.md:175` states this round's own closed feature ("the row **pins `item_ids` at open**") writes the concrete drawn item ids into the durable, append-only `work_unit_opened` row (schema at `:138`), and `evals` (also `:138`) independently carries `item_ids` too. `TruthStore.read_events(**filter) -> Iterator[Event]` (`DATA-LAYER.md:56`) is a fully generic query port with **no stated access-control boundary** anywhere in the document — no mention of which principals (the orchestrator only? the agent's own harness? a retrieval component acting under §16.4's "the five stores as one retrieval substrate," `ALGORITHM-v0.2-pathway-learner.md §16.4`) may call it, and against which record types. If the agent under evaluation, or any SOLVE-side component with `TruthStore` access, can call `read_events(type="work_unit_opened")` or `read_events(type="evals")` and filter to its own `episode_id`, it can recover the exact held-out item ids for its *next* work unit before "seeing" them in context — a direct, mechanical defeat of "never enters `ctx`" that does not require gaming the verifier at all, just reading the truth log the identity-hashing machinery itself now durably populates. None of the nine dimensions above surface this because each was scoped to the mint/reference/rejection mechanics `:174-182` state explicitly, not to who is permitted to query the rows those mechanics create; it only appears when this round's own `item_ids`-pinning fix (closed cleanly since r7 against the *rotating-sample* adversarial finding) is read against §4.1's secrecy requirement from a different document.

## Aggregate confidence

```
critical_floor  = min(Correctness=78, RedTeam=80, Safety=79) = 78
weighted_mean   = (78*2 + 86 + 80*2 + 71 + 79*2 + 85 + 75 + 62 + 70) / 11
                = (156 + 86 + 160 + 71 + 158 + 85 + 75 + 62 + 70) / 11
                = 923 / 11
                = 83.9 → 84
overall         = min(78, 84) = 78
```

**Overall confidence: 78 / 100**

## Verdict

**needs-revision**

This is the strongest result in the gate's nine-round history (78, up from round 8's 76), and the first round where every CRITICAL dimension is genuinely acceptable-or-better on independent re-derivation (Correctness 78, Red-team 80, Safety 79) without a fresh CRITICAL-severity regression. Genuine, verifiable progress: four of round 8's five explicitly-claimed closures hold (items 1's *canonical* signature, 2, 4, 5); the fifth (item 3) is half-closed. The verdict remains `needs-revision` because the aggregate (78) is still below the 80 threshold, driven by:

1. **Fix `DATA-LAYER.md:190`'s "Port delta" summary line** — it still states `open_work_unit(episode_id, suite_id, intent_key)`, the pre-fix 3-argument form, contradicting the corrected 4-argument (`agent_id`-carrying) signature at `:53` and `:175` in the very same subsection. This is the ninth recurrence of the gate's "one location fixed, a co-dependent location not" defect class and the single highest-leverage fix available for this round (one line).
2. **Specify `open_work_unit`'s rejection contract**: does an `intent_key` with no matching `dispatch` row raise an exception (name the type) or return a variant of `WorkUnit` (add a field)? The `AppendResult{id, deduped, rejected_reason}` pattern already exists for `append_event`/`record_eval` (`:178`) — either extend it here or state explicitly why `open_work_unit` needs a different contract.
3. **Name the concrete mechanism behind the dispatch-append's atomic `seq` assignment** (`:174`) at the same concreteness §6.2 gives its own shadow-copy/lock mechanism (`:217`) — e.g., a locked counter row, a `SELECT ... FOR UPDATE`, or a DB-native sequence keyed by `(agent, episode, suite)`.
4. **Address round 8's item 6** (never touched this round): either loosen "follows the general §6.1 identity rule" for `dispatch`'s hash to note it omits `checkpoint_id`, or add `checkpoint_id` to `dispatch`'s schema and hash if it is in fact required.
5. **State the access-control boundary on `TruthStore.read_events`** (`:56`), specifically whether the `item_ids` pinned in `work_unit_opened`/`evals` are reachable by the agent under evaluation or any SOLVE-side component — and if they are not reachable, say so and name the enforcing mechanism; if they are, this reopens §4.1's secrecy guarantee and needs its own gate (the adversarial-pass finding).

## Evolution-log record (for the invoking agent to append)

```json
{"id":"EV-65","date":"2026-07-13","actor":"review-360","action":"create","target":"docs/research/reviews/DL-write-discipline-review-r9.md","why":"360 review (round 9) of DATA-LAYER.md §6.1/§6.2 revised r9 -- overall 76 -> 78/100, needs-revision but the strongest result in 9 rounds: 4 of round-8's 5 claimed closures verified genuine (mint-side dispatch-row validation + test_open_requires_dispatch_row; dual-orphan recovery scan + test_recovery_completes_lost_mint; the atomic-seq misattribution relocated to the dispatch-append step; the mis-scoped test renamed with a corrected description), the 5th (naming the concrete seq-assignment mechanism) only half-closed, and round-8's own item 6 (dispatch's hash-formula omitting checkpoint_id while calling itself 'the general rule') left completely untouched and unacknowledged by this round's own framing; independent audit surfaces a fresh, ninth-recurrence instance of the gate's chronic schema/declaration-not-co-updated defect class: DATA-LAYER.md:190's 'Port delta' summary line still states the pre-fix 3-argument open_work_unit signature, directly contradicting the corrected 4-argument (agent_id-carrying) form at lines 53 and 175 in the same subsection -- a developer following the summary line would silently reopen the exact fleet-collision risk r7's adversarial pass raised and r8 claimed to close; also finds open_work_unit's stated rejection behavior has no corresponding return-type/exception contract; adversarial pass finds the durable item_ids pinned at work_unit_opened/evals (closed since r7 against rotating-sample gaming) may be readable via the access-control-free TruthStore.read_events port, potentially leaking section4.1's secret held-out split ('never enters ctx') to the agent under evaluation -- unexamined by any of the prior 8 rounds","evidence":["docs/research/DATA-LAYER.md §2.1 (lines 52-57), §5 (line 138), §6.1/§6.2 (lines 159-225)","docs/research/reviews/DL-write-discipline-review-r8.md","docs/research/reviews/DL-write-discipline-review-r7.md","docs/research/reviews/DL-write-discipline-review-r6.md","docs/research/reviews/DL-write-discipline-review-r5.md","docs/research/reviews/DL-write-discipline-review-r4.md","docs/research/reviews/DL-write-discipline-review-r3.md","docs/research/ALGORITHM-v0.2-pathway-learner.md §3 (lines 54-69), §4.1 (lines 77-87), §5.1 (lines 115-141), §5.3 (lines 158-173), §6 (lines 177-207), §9 (lines 242-260), §10 (line 266), §16.4, §17.1 (lines 452-457), §17.6 (lines 479-510), §18.1 (line 521), §19.1 (lines 561-563)","docs/research/ALGORITHM-v0.1-redteam.md RC-1 (lines 36-39), RC-2 (lines 41-44), RC-3 (lines 46-49), RC-4 (lines 51-53)","docs/research/BUILD-SPECS.md:299-363 (R1, dispatch terminology)"],"outcome":"pending"}
```
