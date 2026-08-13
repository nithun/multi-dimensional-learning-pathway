# 360 Review: DL-constraint-table — 2026-08-13 (round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.3 "The structural constraint table — declared admissibility at `merge()`" (uncommitted), plus its co-dependent §5 event-kind deltas (`constraint_flag`, `constraint_table`), the §6.1 exemption-list line, and the §6.2 `MergeReport` schema line it now extends |
| Proposed change | Round 2 of the same delta: generalize `merge()`'s one hard-coded structural check into a declared, versioned, severity-graded, fire-tested constraint table — revised to (1) add a synchronous `MergeReport.flags` channel + orchestrator-side `constraint_flag` emission, (2) allow conjunctive multi-family predicates, (3) retarget `C-RETIRE-PROVENANCE` to the actual delta-level `provenance` field, (4) downgrade the `warning` surfacing promise to the ordinary suppressible §20.7 digest, (5) honestly flag `C-FANIN-CAP`'s cap as unregistered in §12 rather than falsely citing it as registered |
| Round 1 | `docs/research/reviews/DL-constraint-table-review.md` — 52/100, needs-revision, 6 numbered blocking items |
| Reviewer | review-360 |
| Date | 2026-08-13 |

**Scope note.** The working tree also carries an independent, uncommitted delta to `ALGORITHM-v0.2-pathway-learner.md` §20.10 and an untracked `IMPL-PROTOCOL.md`. Neither is part of this artifact and neither was read for, or allowed to influence, this review's scoring.

**Circuit-breaker check.** `.claude/memory/circuit-breaker.json`: `agents.status = "open"`. This review is filed as a normal report, not a proposal.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 82 | pass |
| 2 | Design faithfulness | 88 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 74 | weak |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 65 | weak |
| 8 | Consistency | 90 | pass |
| 9 | Calibration / honesty | 86 | pass |

## Findings by dimension

### 1. Correctness

**Round 1 Finding 1 (blocking — MergeReport/severity-conveyance contradiction) — resolved, and verified against both sides of the text.** DATA-LAYER.md:225-226 now reads `MergeReport{ added: [id], deduped: [id], merged: [(id,id)], retired: [id], updated: [id], rejected: [(id, reason)], flags: [(id, constraint_id, severity)] }` — the §6.2 canonical schema block itself carries the field, not just a claim about it elsewhere. §6.3:251 ("The channel, precisely") specifies who reports (`GraphStore.merge()` returns `flags` synchronously) and who records (the §6 orchestrator emits `constraint_flag` per flag, referencing the report — `GraphStore.merge()` itself never touches TruthStore). §6.3:283's "Port delta, declared" now matches: it names the field additively rather than claiming "Port delta: none." `test_every_hit_flagged` (DATA-LAYER.md:285) is now buildable against this mechanism. The caller specifically asked me to check whether §6.2's code block itself was updated or left disagreeing with §6.3's claim — confirmed updated and consistent; the round-1 "Port delta: none" self-contradiction (round 1 Correctness Finding 1, `reviews/DL-constraint-table-review.md`) no longer exists in the text.

**Round 1 Finding 2 (blocking — single-family predicate schema) — resolved.** DATA-LAYER.md:256-259 changes `predicate: (family, params)` to `predicate: [(family, params), ...]` with an explicit comment ("a CONJUNCTION of atoms... an entry combining families... is a list, expressible as written"). `C-LIVENESS-SHAPE` (DATA-LAYER.md:274, enum + non-null-pair, two families) and `C-EDGE-TYPE` (DATA-LAYER.md:275, enum + property-pair + closed-shape, three families) are now expressible under the declared schema; the "fixed and small" vocabulary claim (DATA-LAYER.md:252) is preserved (still 6 named families; only the combinator changed, and that change is disclosed inline rather than smuggled in).

**Round 1 non-blocking Finding (C-RETIRE-PROVENANCE anchor mismatch) — resolved by honest rescoping, not by strengthening the check.** DATA-LAYER.md:279 now reads "non-empty `retires` ⇒ non-empty `delta.provenance`" with the limitation stated in the entry itself: "the schema's provenance is delta-level... per-retire attribution would require a schema §6.2 does not have, and this entry does not pretend otherwise." This matches the actual `GraphDelta.provenance: [truth_event_ids]` field at DATA-LAYER.md:224. The predicate is still close to vacuous in practice — a delta produced by any real growth tick will almost always carry *some* provenance, so the check mainly catches a delta assembled with a completely empty provenance list rather than a genuinely untraceable individual retirement — but this is now an honestly disclosed limitation (correctly scored under Calibration, §9 below), not a false anchor claim (which was the correctness defect round 1 flagged).

**New, narrower correctness gap surfaced this round (not one of round 1's six): no durability treatment for the `constraint_flag` emission step.** §6.2/§6.1 give every other posterior-adjacent or identity-bearing write an explicit crash-recovery story (the orphan-scan at DATA-LAYER.md:185, the atomic `dispatch.seq` counter at DATA-LAYER.md:183-184, `rejected_ingest`'s durable full-payload retention at DATA-LAYER.md:193). §6.3's new `flags`/`constraint_flag` channel (DATA-LAYER.md:251) has none: `MergeReport` is an ephemeral return value with no truth-log backing of its own, so if the orchestrator crashes after `merge()` returns a `warning`/`info` flag on an *admitted* entry but before it appends the corresponding `constraint_flag` event, that flag is lost permanently — the graph mutation already succeeded (nothing to retry), and no recovery-scan analog to step 3 of §6.1's lifecycle (DATA-LAYER.md:185) exists for this class. `test_every_hit_flagged` (DATA-LAYER.md:285) as literally stated is a crash-free-execution guarantee, not the crash-inclusive guarantee every other identity/administrative write in this document is held to. See the adversarial pass for the fuller implication.

**Item 6 from round 1 remains open (see Completeness §7 and Implementability §4): no atomic `table_version` assignment mechanism, and no stated `GraphDelta` collection scope for node/edge-targeted predicates.** These were not addressed by this round's revisions (the caller's revision-response list covers items 1-5 of round 1's six).

### 2. Design faithfulness

- The round-1 port-layering divergence is resolved: `GraphStore.merge()` gains no `TruthStore` dependency (confirmed at DATA-LAYER.md:83, 251, 283 — all consistent), and the emission is explicitly routed through the existing §6 orchestrator (`EvolutionLoop`, DATA-LAYER.md:309-312, already holding both `graph` and `truth`), matching the established §17.6 "orchestrator observes and records" pattern this document uses elsewhere (e.g. DATA-LAYER.md:146's `trace`/`score` rows, "all rows JUDGE-emitted").
- "MERGE stays a projection writer, never a gate" (DATA-LAYER.md:207, 246) is honored throughout: `warning` admits unchanged (DATA-LAYER.md:249, explicitly reasoned — "altering status would make MERGE assign liveness, which §6.2 forbids"), `info` is inert.
- `C-LIVENESS-SHAPE`'s honest partial scoping (checks only the resulting shape, not the "admitted verifier" half of PR-6) is unchanged from round 1 and still correctly disclosed in-entry (DATA-LAYER.md:274). The top-level "PR-6 strengthened" property-impact line (DATA-LAYER.md:240) still states this as a blanket claim rather than scoped to the suite-presence half — a minor, carried-over calibration point (see §9), not a design-faithfulness defect since the in-entry text is honest even where the summary line is not.

### 3. Red-team resistance

*Cross-checked against `ALGORITHM-v0.1-redteam.md`'s eight root causes.*
- **RC-3** (unscorable growth) and **RC-4** (add-only ratchet with no inverse): still not reopened; unchanged from round 1's analysis, and this round's fixes (conjunctive predicates, delta-level `C-RETIRE-PROVENANCE`, honest `warning` downgrade) touch none of the RC-3/RC-4 machinery.
- **RC-2/RC-1/RC-5/RC-6/RC-7/RC-8:** not applicable, unchanged.
- **Residual watch item, carried over unaddressed from round 1:** the gate-free amendment path (DATA-LAYER.md:266) still lets a JUDGE-side operator remove a `warning`/`info` entry — including `C-RETIRE-PROVENANCE`, the table's only audit-signal-shaped entry — unilaterally, with only a self-supplied rationale string and no independent review. This round's revisions did not touch the amendment rule and did not address this. Combined with the still-near-vacuous predicate that entry checks (Correctness §1 above), the one non-`violation` entry the initial set actually ships is both weak when present and freely removable — worth naming again as a watch item, not upgraded to a root-cause reopening (it requires a privileged JUDGE-side actor, not an optimization-pressure exploit reachable by SOLVE).

### 4. Implementability

Three of round 1's five concrete developer-facing gaps are closed:
- The `MergeReport`/severity-conveyance gap — closed (Correctness §1).
- The compound-predicate schema mismatch — closed (Correctness §1).
- `C-FANIN-CAP`'s false-registration claim — closed: DATA-LAYER.md:277 now states plainly "unregistered in §12 — an ALGORITHM-side registration gap, flagged here and out of this delta's scope," and binds `predicate.params` to `§5.1.top_k` by name rather than a literal. Verified against ALGORITHM-v0.2-pathway-learner.md:282-286 (the §12 added-parameters list) — no fan-in-cap parameter is registered there under any name, so the "unregistered" claim is now accurate where round 1's "§12-registered... by name" claim (round 1 Implementability finding) was not.

Two remain open, unaddressed by this round's revisions:
- **No atomic `table_version` assignment mechanism.** `test_constraint_table_versioned_in_truth` (DATA-LAYER.md:285) still assumes "the evaluation uses the highest `constraint_table` version" without a stated concurrency-safe assignment analogous to the `dispatch.seq` atomic-upsert pattern this same document specifies in detail at DATA-LAYER.md:183 (`INSERT … ON CONFLICT DO UPDATE … RETURNING`). Registration is rarer and more likely single-writer in practice than the hot dispatch path, which lowers the practical risk relative to round 1's framing, but the document doesn't say so — a developer still has to invent the mechanism or assume single-writer without that assumption being stated.
- **No stated `GraphDelta` collection scope for node/edge-targeted predicates.** DATA-LAYER.md:256-278 does not say whether `target: node` predicates apply only to `GraphDelta.adds` or also to nodes touched by `merges`/`edge_updates`. This is partially self-resolving on inspection: `GraphDelta.retires: [node_id]` (DATA-LAYER.md:222) is a bare id list with no `status`/`suite_ref` fields, so `C-LIVENESS-SHAPE`'s enum/non-null predicate structurally cannot be evaluated against a `retires` entry as literally schema'd — the ambiguity round 1 flagged (a retiring node spuriously failing the `{live, pending_human}` enum) may not be reachable given the actual delta shape. But the document doesn't say this explicitly, so a developer still has to work it out rather than being told.

### 5. Safety / integrity

- The round-1 defect here is resolved. DATA-LAYER.md:249 no longer claims a `warning` is "surfaced for review through §20.7's delivery path" (that language is gone); it now states the flag "is reported in the **ordinary §20.7 digest (suppressible)**... the always-delivered class stays reserved for the conditions ALGORITHM's §20.7/§20.10 enumerate (the §20.10 structure-freeze precedent — informative, not alarm-class)." I verified this citation against the source: ALGORITHM-v0.2-pathway-learner.md:659 states, for an analogous non-alarm structural finding, "A structure-freeze under nonzero progress... is reported in the ordinary digest — informative, suppressible; it joins the always-delivered class only through the state machine below" — and ALGORITHM-v0.2-pathway-learner.md:638's always-delivered enumeration ("`unknown` attempts (§20.2), sustained-deferral alerts (§20.4), breaker trips, and saturation events") correctly excludes constraint warnings. The citation is precise, not invented, and the promise §6.3 now makes is one the rest of the spec actually keeps.
- No existing gate, §14 calibration layer, or `HUMAN-LEARNING-VERIFIER.md` verifier is touched, weakened, or referenced by this delta (not applicable to a structural write-path check) — unchanged from round 1.
- `authorized_by`'s "presence and format" scoping (DATA-LAYER.md:265) is unchanged and still appropriately honest.
- Residual: the new emission-durability gap (Correctness §1, adversarial pass) is an integrity concern in a narrow sense — it means the audit trail this section exists to create can silently lose exactly the evidence class (`warning`/`info` flags on admitted entries) it was built for, under a crash. It does not weaken any existing gate or verifier, and it is a new mechanism's edge case rather than a regression, so it does not pull this dimension below 70, but it keeps the score short of the 90s.

### 6. Efficiency / cost

- Unaffected by this round's changes. The complexity bound (DATA-LAYER.md:243) and the correct separation of cheap per-entry families from the pre-existing O(|V|+|E|) acyclicity cost are unchanged from round 1 and still accurate.
- The minor, previously-noted point that `C-FANIN-CAP`'s check reads existing incoming edges (proportional to the node's current fan-in, not literally O(|delta|)) is unchanged and still not called out in the blanket complexity claim — non-blocking, unaddressed, carried over.

### 7. Completeness

- Round 1's test-list-cannot-be-written gap is resolved: `test_every_hit_flagged`, `test_constraint_fires[C-LIVENESS-SHAPE]`, and `test_constraint_fires[C-EDGE-TYPE]` are now writable against the revised schema and channel.
- Still open, unaddressed by this round: no concurrency rule for `table_version` registration (Implementability §4); no stated `GraphDelta` collection scope for node/edge-targeted predicates (Implementability §4, though narrower than round 1 believed); no stated growth/retention bound for `constraint_table` version history (round 1 also flagged this and it remains unaddressed — contrast with `w_rejected`'s explicit 30-day bound at DATA-LAYER.md:193).
- New this round: no crash-recovery / retry story for the `constraint_flag` emission step (Correctness §1) — an edge case this document's own established discipline (explicit recovery scans, atomic counters, durable-payload retention for every other write class) would normally require being named, even if only to say "best-effort, not durable" explicitly.

### 8. Consistency

- The round-1 internal contradiction ("Port delta: none" vs. the emission requirement) no longer exists — verified the §6.2 code block and the §6.3 "Port delta, declared" line agree (Correctness §1).
- The round-1 inconsistency between `C-FANIN-CAP`'s claim and ALGORITHM §12's actual parameter registry no longer exists — verified against ALGORITHM-v0.2-pathway-learner.md:282-286 (Implementability §4).
- Anchors re-checked and hold: `C-ACYCLIC`'s quoted B2-AmendA text (DATA-LAYER.md:273) matches BUILD-SPECS.md:237 verbatim ("enforced at the graph write path: `GraphStore.merge()` validation, reporting via `MergeReport.rejected`"); `C-NAMESPACE`'s anchor matches ALGORITHM-v0.2-pathway-learner.md:607 ("`provision_suite` (§5.1) rejects any real skill/suite claiming it... `test_maintenance_namespace_reserved`"); `C-FANIN-CAP`'s anchor (`add_soft_prereq_edges`, "soft, capped fan-in, acyclic") matches ALGORITHM-v0.2-pathway-learner.md:129; PR-6's text (ALGORITHM-v0.2-pathway-learner.md:687) matches `C-LIVENESS-SHAPE`'s anchor framing. No new anchor mismatches found in this pass.
- No regressions found elsewhere in the file: the diff against the prior committed state touches only §5 (event kinds), §6.1's exemption list, §6.2's `MergeReport` code block, and the new §6.3 body — §§7-9 and the rest of §§1-6.2 prose are untouched and internally consistent with the new material.

### 9. Calibration / honesty

- The round-1 overclaim ("Port delta: none," round 1 line 279) is gone, replaced by an honest, specific, additive declaration (DATA-LAYER.md:283) — this is the single largest calibration improvement in this round.
- `C-RETIRE-PROVENANCE`'s near-vacuity is now disclosed in the entry itself rather than hidden behind a false per-entry anchor (DATA-LAYER.md:279) — an honest trade (a weak check, stated as weak) rather than a false claim of a strong one.
- `C-FANIN-CAP`'s registration status is now honestly stated as a gap rather than falsely claimed as registered (DATA-LAYER.md:277).
- The `warning` digest downgrade (DATA-LAYER.md:249) replaces an unenforced promise with one the spec actually keeps, verified against ALGORITHM-v0.2-pathway-learner.md:638, 659 (Safety §5).
- Residual, carried over from round 1 and not addressed this round: "PR-6 strengthened" (DATA-LAYER.md:240) is still stated as a blanket per-property claim in the property-impact summary line, though the underlying entry (`C-LIVENESS-SHAPE`, DATA-LAYER.md:274) correctly scopes itself to the suite-presence half in its own prose. This is a small, non-blocking inconsistency between the summary line's precision and the entry's — round 1 flagged it as a Calibration/Design-faithfulness note, not one of the six numbered blocking items, and it remains exactly that.

## Strongest adversarial objection

Round 1's central objection was that the two severities whose entire purpose is "watch and record, don't gate" (`warning`/`info`) depended on a channel the section simultaneously declared not to exist. That channel now exists and is correctly wired. But look at what it costs to make it exist: the fix routes every `warning`/`info` hit through a **second, unsynchronized write** — `merge()` returns `MergeReport.flags` (an in-memory value), and *only after that call returns* does the orchestrator separately append the corresponding `constraint_flag` truth event (DATA-LAYER.md:251). Nothing in §6.3 makes that second write durable-or-retried the way every other identity-bearing write in this document is: `dispatch`/`work_unit_opened` get an explicit orphan-scan recovery path (DATA-LAYER.md:185), `rejected_ingest` gets full-payload durable retention specifically so "re-association is always possible" (DATA-LAYER.md:193), and `merge()` itself has an explicit all-or-nothing failure contract with retry (DATA-LAYER.md:229). The new `constraint_flag` emission gets none of that: it is a plain, unguarded, non-idempotent append that happens to run after a state change that already succeeded and cannot be retried (the graph mutation is done; there is nothing to "resubmit"). If the orchestrator process dies in the gap between `merge()` returning a `warning`/`info` flag and the `constraint_flag` append landing, that flag is gone forever, with no trace it was ever raised — not even a partial or ambiguous record, just silence. For `violation`-severity hits this is low-stakes (the entry didn't apply; a retried delta re-evaluates and re-flags it identically). But it is exactly the two severities this section was built to give a home to — "watch and record, don't gate" — that inherit this hole, and inherit it *because* they are the harmless, no-rollback-needed case: nothing else in the system will ever notice or re-derive a lost `warning`, because by design nothing about the graph state changed to signal that one was ever due. The section's stated purpose — "turns 'a check someone remembered to code' into a declared table... so the constraint inventory is data with an audit trail" (DATA-LAYER.md:241) — is undercut a second time, at one level of depth further down than round 1 found: the audit trail is not silently absent anymore, but it is silently loseable, on exactly the class of evidence (soft, non-blocking, human-reviewable signals) that has no other mechanism to catch its own loss. This is a narrower defect than round 1's (a crash-window edge case, not a structural impossibility), which is why it does not push any CRITICAL dimension below 70 — but it is real, it is new to this round, and it was not surfaced in the caller's five listed fixes.

## Aggregate confidence

```
critical_floor  = min(Correctness=82, RedTeam=82, Safety=85) = 82
weighted_mean   = (Correctness*2 + Design + RedTeam*2 + Implementability + Safety*2 + Efficiency
                   + Completeness + Consistency + Calibration) / 11
                = (82*2 + 88 + 82*2 + 74 + 85*2 + 85 + 65 + 90 + 86) / 11
                = (164 + 88 + 164 + 74 + 170 + 85 + 65 + 90 + 86) / 11
                = 986 / 11
                = 89.64 → 90
overall         = min(82, 90) = 82
```

**Overall confidence: 82 / 100**

## Verdict

**ready-for-approval**

All five of round 1's numbered blocking changes that this revision targeted are verified fixed against the text: the `MergeReport`/severity-conveyance channel now exists and is consistently declared in both the §6.2 schema block and the §6.3 port-delta line; the predicate schema now supports conjunctive multi-family entries and both previously-inexpressible entries (`C-LIVENESS-SHAPE`, `C-EDGE-TYPE`) are expressible; `C-RETIRE-PROVENANCE` is honestly retargeted to the delta-level provenance field it actually has; the `warning` surfacing promise is downgraded to match what §20.7/§20.10 actually deliver, verified against source; and `C-FANIN-CAP`'s registration claim is corrected to an honestly-flagged gap. No CRITICAL dimension (Correctness 82, Red-team resistance 82, Safety 85) is below 70, and the overall score of 82 clears the 80 threshold.

Two items are not blocking at this score but should be tracked, either as a light follow-up delta or explicitly deferred in the decision record:
1. Round 1's sixth numbered item (atomic `table_version` assignment; `GraphDelta` collection scope for node/edge-targeted predicates) was not addressed by this revision and remains open — the collection-scope half is now believed lower-risk than round 1 assessed (the `retires` schema structurally lacks the fields `C-LIVENESS-SHAPE` would need to misfire), but this is inferred by the reviewer, not stated in the text.
2. The `constraint_flag`/`constraint_table` emission path has no durability or recovery story for a crash between `merge()` returning and the orchestrator's truth append landing — new to this round (see the adversarial pass) and not one of round 1's or this round's addressed items.
