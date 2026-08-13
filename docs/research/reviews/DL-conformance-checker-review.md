# 360 Review: DL-conformance-checker — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §12 "Conformance checker — replaying truth against ALGORITHM §21" (uncommitted working tree), plus co-dependent deltas: §5's two new event kinds (`conformance_report`, `conformance_manifest`), §6.1's exemption-list addition, §2's `conformance.py` layout line, and the §11 bookkeeping status flip |
| Proposed change | Add a JUDGE-side, read-only, cold-path conformance checker (`conformance.py`) that replays TruthStore against ALGORITHM §21's nine safety properties via per-property trace predicates (§12.2) and a live-path-reachability manifest (§12.3), emitting a redacted `conformance_report` administrative event; plus a pure-bookkeeping status-marker flip on §11 |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"`. Filing as a direct review report (not a proposal).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 58 | weak/blocking |
| 2 | Design faithfulness | 78 | acceptable |
| 3 | Red-team resistance (CRITICAL) | 68 | weak |
| 4 | Implementability | 64 | weak |
| 5 | Safety / integrity (CRITICAL) | 66 | weak |
| 6 | Efficiency / cost | 74 | acceptable |
| 7 | Completeness | 68 | weak |
| 8 | Consistency | 64 | weak |
| 9 | Calibration / honesty | 60 | weak |

## Findings by dimension

### 1. Correctness

The predicate table's own honesty discipline (partial/conditional/not-trace-checkable, applied correctly to PR-1, PR-2, PR-3, PR-7) is **not applied consistently to PR-5, PR-6, PR-8, PR-9**, each of which claims `full` checkability while resting on a truth record the current schema does not establish exists:

- **PR-8(iii) (`DATA-LAYER.md:386`)**: "no lease exhibits a heartbeat gap > `g_lease` while its owner's records continue (a dead-claim signature)." `work_unit_opened.lease_expires_at` is described everywhere it is defined (`DATA-LAYER.md:146`, `ALGORITHM-v0.2-pathway-learner.md:609,611,614`) as a single column that is "heartbeat-refreshed" — i.e. **mutated**, not appended. A mutated field preserves only its current value; there is no historical trail of successive heartbeat timestamps to detect a *transient* gap that has since been re-extended. Detecting "a gap > `g_lease` while records continue" ex post from a replay requires either (a) heartbeats logged as discrete append events, or (b) some other durable trail — neither exists in the schema as specified. This is not a labeling nitpick: **it means PR-8(iii) cannot be computed as `full` from the schema this very delta ships**, and building it as specified silently requires a new logging mechanism — directly contradicting the section preamble's own claim ("No mechanism changes... its single schema addition is the administrative `conformance_report` event kind," `DATA-LAYER.md:356`).
- **PR-5(i) (`:383`)**: requires "the Stage-1 evidence records §9 requires (`sustained_heldout` evals on the adapter, **spot-check event**, `MONITORED` no-regression evals)." No truth event kind for a human spot-check exists anywhere in DATA-LAYER §5 (grepped; zero hits for `spot-check`/`spotcheck` outside this line and the ALGORITHM pseudocode `human_spotcheck(kept_set)`, `ALGORITHM-v0.2-pathway-learner.md:253`). ALGORITHM §9's pseudocode never states that `human_spotcheck` logs anything to truth. This is exactly the situation PR-3 (`:381`) correctly downgrades to `conditional` ("checkable exactly when the deployment logs effective thresholds with decisions... mandating new logging would be a mechanism change out of this section's scope") — but the identical logic is not applied here.
- **PR-6(i) (`:384`)**: requires "an admitted verifier whose reliability record clears `ρ_min`." No truth event records verifier admission or a point-in-time `reliability_lowerCI(v)` value (`ALGORITHM-v0.2-pathway-learner.md:103,137` define the *computation*, not a truth-logged *record* of it). Without a historical record, the checker can only test current config against a past decision — the same non-replayable hazard §21.2's event-indexed-decay clause (`:673`) was written specifically to rule out for other quantities.
- **PR-9 (`:387`)**: "evaluated over the same trailing window the §5.3 floor is enforced over." §5.3 (`ALGORITHM-v0.2-pathway-learner.md:158-173`) never names a trailing window for `f_min` — it states a rate floor with no measurement window. The predicate borrows a term that does not exist in the section it cites, so "full / window-covering scopes" checkability is not actually well-defined as written.

Four of nine properties' checkability claims rest on evidence the schema doesn't establish. This is a systemic pattern in the deliverable's core table, not an isolated slip, and it directly undercuts the artifact's central promise (buildable, honest checkability from the schema as given).

### 2. Design faithfulness

Mostly faithful: JUDGE-bundle-only placement (`:361-366`), cold-path/maintenance-job scheduling reuses §20.2 verbatim (`:367`), administrative-event-class treatment mirrors §6.1/§11's pattern exactly, and the etcd-raft TLA+ provenance citation is apt and consistent with `STUDY-ontologies-and-raft.md`.

Two faithfulness gaps:
- §12.3's always-fires/conditional bifurcation for live-path-reachability (`:393`) is a substantive reinterpretation of §21.2's stated audit rule ("A mechanism with no trace in the canonical run leaves its property non-conformant," `ALGORITHM-v0.2-pathway-learner.md:672`, no carve-out given there for rare-path mechanisms). It is a sensible fix — a literal reading of §21.2 would make every conditional-mechanism property perpetually non-conformant even when correctly built — but §21's own preamble enumerates exactly **two** declared conformance clarifications (`:651`) and this is a third, introduced only in the DL delta, not cross-referenced back into §21's accounting.
- No `Port delta:` closing statement (the house convention this document uses everywhere else a schema/interface changes — see the end of §6.1 `:201` and §6.2 `:232`). §12 introduces `Manifest`, `ConformanceReport`, and a manifest-entry shape only in prose; no equivalent statement appears for §12.

### 3. Red-team resistance

No RC-1..RC-8 mechanism is touched or reintroduced — the checker is additive and read-only, correctly scoped away from remediation (§12.4, "the checker never remediates"). The residual risk is adjacent to the *shipped-but-inert-detector* failure mode the section explicitly invokes as its own justification (`STUDY-automaton-autonomy.md` A2, cited at `:356` and `:399`): as found under Correctness, four predicates claim `full` checkability against evidence that doesn't exist in the schema. If built literally, an implementer under time pressure could stub those sub-clauses to a default `conformant`/`True` rather than blocking on the missing schema, producing exactly the false-assurance instrument this section exists to prevent. The per-predicate synthetic-fire-test requirement (`test_checker_fires_on_synthetic_violation`, `:405`) is a real, structural mitigant — it should force the gap to surface at test-authoring time, since a synthetic PR-5(i)/PR-8(iii)/PR-6(i) violation fixture cannot be constructed without the missing event kinds. That mitigant is real but not proven sufficient on paper; the section does not itself notice or flag the gap it would need to catch.

### 4. Implementability

`check_conformance(truth, manifest, scope) -> ConformanceReport` is a clear entry point and the event schemas are fully spelled out. Gaps: no `schemas.py` dataclass shape given for `Manifest`, `ManifestEntry`, or `ConformanceReport` (contrast §6.1's port-delta paragraph, which states exact field additions); no ArtifactStore method specified for storing the manifest blob — `ArtifactStore` (`:90-93`) exposes only `put_checkpoint`/`register`/`gc`, none of which is a generic content-hash-addressed blob store, yet `:395` requires "the content itself is an ArtifactStore blob keyed by that hash" with no stated method or interface delta. `cursor: {predicate_id → opaque_state}` is left literally opaque for every predicate — a developer has to reverse-engineer per-predicate continuation state from prose (`:370` names only two examples: PR-4(ii) seq continuity, PR-5(iii) row monotonicity; the other seven predicates' incremental-state shape is unstated).

### 5. Safety / integrity

No gate, calibration layer, or verifier is weakened; the checker is correctly scoped to report-only (§12.4). The one real gap sits on the P1 boundary, which is the single highest-stakes property in the whole spec: **the redaction guarantee is stated only for `violation_refs`** ("`violation_refs` carry `(record_id, predicate_id)` pairs — ids and hashes only, never item content and never held-out `item_ids`," `:368`) — the sibling `cursor: {predicate_id → opaque_state}` field on the *same* `conformance_report` event (`DATA-LAYER.md:146`) is never addressed by the redaction discussion. PR-1(ii)'s predicate ("payload scan against the held-out id set," `:379`) is exactly the kind of check whose natural incremental implementation might persist held-out-derived state (a watermark over the held-out id set, a bloom filter, etc.) in its own `cursor` slot. Because `RedactedTruthView`'s stated scrub rule is scoped to `evals` rows with `split=held_out` (`:63,191`), not to arbitrary `events`-table payloads, there is no textual guarantee that a future `cursor.opaque_state` implementation for PR-1(ii) stays redacted if this event is ever read through a generic `events` query. `test_report_redacted` (`:405`) asserts "no held-out `item_ids` or item content **in any report field**" — which implicitly includes `cursor` — but no mechanism is specified to make that true, only a test that would catch it after the fact. This is the same "promise without the mechanism that would make it true" pattern this document elsewhere names and corrects (§21.2's own account of its round-2 self-catch, `ALGORITHM-v0.2-pathway-learner.md:674`); it recurs here uncaught.

### 6. Efficiency / cost

No hot-path additions; correctly cold/maintenance-scheduled. Incremental scope avoids full rescans via the cursor design — good discipline, consistent with §6.2's coalescing pattern. PR-7's expensive double-replay is correctly gated to `full` scope only (`:369,385`). One omission: PR-1(ii)'s "payload scan against the held-out id set" over every non-eval record has no stated complexity bound, indexing strategy, or cost cap — unlike this document's own convention elsewhere of stating explicit costs (e.g. §6.2's "O(|V|+|E|) time and transient 2× memory per merge call," `:228`). At `full` scope over a long-lived truth log this could be a materially expensive scan with no acknowledged bound.

### 7. Completeness

Strong on stated edge cases: manifest staleness (`manifest_error`, loud never silent), incremental-vs-full scoping for the one expensive predicate, five-status worst-of severity ordering defined once and consistently. Gaps: no `Manifest`/`ConformanceReport` schema in `schemas.py` (see Implementability); §12 has no equivalent to §11.4's explicit "Register scope note" stating whether this delta carries a BUILD-SPECS item (grep of BUILD-SPECS.md/ALGORITHM-INTEGRATIONS.md turns up no RAF-1b entry at all — consistent with the no-BUILD-SPECS-item precedent §11.4 states explicitly, but §12 never states it for itself, leaving the omission ambiguous rather than declared); the four checkability-claim gaps found under Correctness are themselves a completeness failure of the predicate table.

### 8. Consistency

Mostly consistent with §5's schema conventions, §6.1's exemption list (correctly extended to include both new event kinds), §20.2's maintenance-job pattern, §20.6's alarm/fire-test discipline, and §20.7's always-delivered class. Two concrete inconsistencies:
- The preamble states "its single schema addition is the administrative `conformance_report` event kind" (`:356`) — but the diff itself adds **two** new event kinds, `conformance_report` **and** `conformance_manifest` (`DATA-LAYER.md:146`, confirmed in the working-tree diff). The preamble undercounts its own footprint by one, a directly citable, easily-verified inaccuracy.
- The always-fires/conditional bifurcation (§12.3) extends §21.2's audit rule without being reflected in §21's own "two declared conformance clarifications" accounting (see Design faithfulness).

### 9. Calibration / honesty

The section's culture is genuinely good in places: `not_trace_checkable` is correctly treated as a first-class, non-omittable result (`:401`), PR-2's honest "rests on its guards" framing (`:380`) and PR-3's honest downgrade to `conditional` (`:381`) are exactly the right instinct — the S21 lesson ("a predicate's existence is not the property's truth," `:375`) is stated and, in those two cases, followed. The calibration failure is that the **same standard is not applied to PR-5(i), PR-6(i), PR-8(iii), and PR-9**, each of which claims a stronger checkability grade (`full`) than its own evidentiary basis supports, by the identical reasoning that correctly downgraded PR-3. For a document whose entire purpose is to police honest checkability claims, overclaiming on four of nine properties is a direct hit to its own founding premise, compounded by the schema-footprint undercount noted under Consistency.

## Strongest adversarial objection

**PR-8(iii) requires a mechanism this delta explicitly disclaims having added.** The section preamble states in its own words: "No mechanism changes; no new parameters (no §12 delta)... its single schema addition is the administrative `conformance_report` event kind" (`DATA-LAYER.md:356`). But PR-8(iii)'s "no lease exhibits a heartbeat gap > `g_lease`" predicate is only computable from a truth log that records each heartbeat as a discrete, append-only event — and the schema this same document specifies for lease heartbeats (`work_unit_opened.lease_expires_at`, `supervisor_lease.lease_expires_at`) is a single **mutated** column, described consistently as "heartbeat-refreshed" everywhere it appears in both DATA-LAYER and ALGORITHM §20.2. A mutated column has no history; PR-8(iii) as written cannot be built without adding exactly the kind of new append-only logging mechanism the preamble says this section does not add. This is not a hypothetical implementation detail — it is a **self-contradiction provable from the artifact's own text**, on a CRITICAL-adjacent property (bounded claims / dead-claim detection), and it was specifically the kind of gap the task brief asked to check ("PR-8(iii)'s heartbeat-gap detection against what truth actually records of heartbeats"). No other single objection in the nine dimensions is as concretely self-refuting.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(58, 68, 66) = 58
weighted_mean   = (58*2 + 78 + 68*2 + 64 + 66*2 + 74 + 68 + 64 + 60) / 11
                = (116 + 78 + 136 + 64 + 132 + 74 + 68 + 64 + 60) / 11
                = 792 / 11
                = 72.0
overall         = min(58, 72.0) = 58
```

**Overall confidence: 58 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to clear the CRITICAL floor of 70 on Correctness, Red-team resistance, and Safety):

1. **Downgrade or fix PR-8(iii)'s checkability.** Either specify heartbeat refreshes as discrete append events (an explicit, acknowledged §20 mechanism/schema delta, not a silent one — and re-verify this doesn't reopen §20's own "no in-memory-only" or claims-rule discipline), or downgrade PR-8(iii) to `conditional`/`not_trace_checkable` and state honestly what remains uncheckable from a mutated `lease_expires_at` column.
2. **Downgrade or fix PR-5(i)'s "spot-check event" and PR-6(i)'s "admitted verifier... reliability record" clauses.** Either name the truth event kind(s) that must exist for these to be logged (a declared schema delta) or apply the same `conditional` downgrade PR-3 correctly uses for the analogous logging-not-guaranteed situation.
3. **Define or remove PR-9's "trailing window" reference**, since §5.3 names no such window for `f_min` as written; either add the window definition where it belongs (flagged for the ALGORITHM side, out of this delta's own scope) or state PR-9's checkability honestly as conditional on that missing definition.
4. **State the redaction mechanism (not just the test) for `cursor.opaque_state`**, explicitly extending the redaction guarantee already given for `violation_refs` to cover every field of `conformance_report`, with a stated rule for what may and may not be persisted in `cursor` for the held-out-touching predicates (PR-1 in particular).
5. **Correct the preamble's schema-footprint claim** ("single schema addition") to acknowledge both `conformance_report` and `conformance_manifest`.
6. Non-blocking but should accompany the next round: add a `Port delta:` statement for `schemas.py` (`Manifest`/`ConformanceReport`/manifest-entry shapes) and for `ArtifactStore`'s manifest-blob storage method, matching this document's own established convention; reconcile §12.3's always-fires/conditional bifurcation with §21's "two declared conformance clarifications" accounting, or note it explicitly as a third; add a §12 "Register scope note" mirroring §11.4's, stating whether this delta carries a BUILD-SPECS item; state a complexity bound for PR-1(ii)'s payload scan.
