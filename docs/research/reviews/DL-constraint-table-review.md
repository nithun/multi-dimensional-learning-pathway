# 360 Review: DL-constraint-table — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §6.3 "The structural constraint table — declared admissibility at `merge()`" (uncommitted), plus its co-dependent §5 event-kind deltas (`constraint_flag`, `constraint_table`) and the §6.1 exemption-list addition |
| Proposed change | Generalize `merge()`'s one hard-coded structural check (B2-AmendA acyclicity) plus the liveness-shape check into a declared, versioned, severity-graded, fire-tested constraint table evaluated inside `GraphStore.merge()` (ONT-1′) |
| Reviewer | review-360 |
| Date | 2026-08-13 |

**Scope note.** The working tree also carries an independent, uncommitted delta to `ALGORITHM-v0.2-pathway-learner.md` §20.10 (a separate gate run). That delta is not part of this artifact and was not read for, or allowed to influence, this review's scoring.

**Circuit-breaker check.** `.claude/memory/circuit-breaker.json`: `agents.status = "open"`. This review is filed as a normal round-1 report, not a proposal.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 52 | blocking |
| 2 | Design faithfulness | 70 | weak |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 55 | weak |
| 5 | Safety / integrity (CRITICAL) | 74 | weak |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 58 | weak |
| 8 | Consistency | 58 | weak |
| 9 | Calibration / honesty | 68 | weak |

## Findings by dimension

### 1. Correctness

**Blocking — the warning/info severity channel has no carrier back to the caller, and the artifact's own "Port delta: none" claim is self-contradictory.**
- DATA-LAYER.md:248 states every `warning`-severity hit is "admitted unchanged" and "surfaced for review"; DATA-LAYER.md:249 states `info` hits are "admitted, recorded"; DATA-LAYER.md:250 states "**Every** hit of any severity emits one `constraint_flag` administrative event... referencing the `MergeReport`." That requires *something* — the orchestrator, per the established §17.6 pattern (ALGORITHM-v0.2 §17.6, e.g. lines 484–486: "A row is appended by the §6 orchestrator the moment a proposal passes... admission checks") — to learn, per delta entry, which constraint fired at which severity, in order to write the `constraint_flag` row.
- But DATA-LAYER.md:279 states plainly: "**Port delta: none.** `merge()`'s signature and `MergeReport` are unchanged (constraint rejections use the existing `rejected` field; `constraint_id` is the reason string)." `MergeReport`'s fields (DATA-LAYER.md:225: `added, deduped, merged, retired, updated, rejected`) carry **only** rejections. There is no field through which a `warning` or `info` hit on an *admitted* entry is reported back to the caller.
- Net effect: a developer following the spec literally cannot implement `test_every_hit_flagged` (DATA-LAYER.md:281) for anything but `violation`-severity hits, because the one synchronous channel the section names (line 250: "`MergeReport` itself remains the caller's synchronous channel") is declared unchanged and structurally cannot carry the information. This is not a hypothetical edge case — it is required by every non-`info`, non-`violation` entry the initial set ships (`C-RETIRE-PROVENANCE`, `warning`, DATA-LAYER.md:275) and by the design's own `info` severity. Either `MergeReport` needs a new field (contradicting "Port delta: none," a port-level change) or `GraphStore.merge()` needs a direct `TruthStore` write path (a new cross-port dependency contradicting §2's ports-and-adapters separation, and also a port-level change). The claim as written is false under either resolution.

**Blocking — two of seven initial entries violate the table's own single-family predicate schema.**
- `ConstraintEntry{... predicate: (family, params) ...}` (DATA-LAYER.md:255–256) declares **one** vocabulary family per entry.
- `C-LIVENESS-SHAPE` (DATA-LAYER.md:270): `status ∈ {live, pending_human}` is a *value-type/range* predicate (enum membership); `live ⇒ non-null suite_ref` is a *property-pair* predicate (cross-field, conditional). These are two different families of the six enumerated at DATA-LAYER.md:251, combined in one `ConstraintEntry` row.
- `C-EDGE-TYPE` (DATA-LAYER.md:271): `type ∈ {prereq, part_of, transition}` is *value-type/range*; "with the B2-AmendA field set... for typed hierarchy edges" is a type-conditional field requirement (*property-pair*-shaped); "closed shape — no undeclared fields" is the *closed shape* family. Three families in one row.
- The schema at line 255 gives no mechanism for a conjunctive/compound predicate (no list, no AND-combinator). Either the schema needs to become `predicate: [(family, params)]` (a real, undisclosed change to the one piece of the design stated to be fixed and load-bearing — "The predicate vocabulary is fixed and small," line 251), or these two entries must be split into multiple `constraint_id`s, which the initial-set table (DATA-LAYER.md:267–276) does not do. As written, `C-LIVENESS-SHAPE` and `C-EDGE-TYPE` are not expressible in the declared vocabulary.

**Non-blocking but real — `C-RETIRE-PROVENANCE`'s anchor does not match the schema it cites at the granularity the predicate needs.**
- The predicate (DATA-LAYER.md:275) is "every `retires` entry carries a `provenance` truth-event id" — a *per-entry* claim.
- The cited `GraphDelta` schema (DATA-LAYER.md:219–224) is `retires: [node_id]` (a bare list of ids, no attached provenance) plus a single delta-level `provenance: [truth_event_ids]` field ("list — one delta per tick coalesces many events"). The delta-level `provenance` list is not attributable to any individual `retires` entry — it is the union of whatever truth events coalesced into that tick's delta, which will almost always be non-empty regardless of whether any specific retirement is actually traceable. A predicate meant to catch "a retire without traceable provenance" (line 275's own gloss) will pass vacuously against this schema as long as the delta contains *any* provenance at all — which is close to always. This is exactly the inert-alarm failure §12.4 elsewhere in this same document warns against (DATA-LAYER.md:447), self-inflicted in the entry designed to demonstrate the pattern's non-triviality.

### 2. Design faithfulness

- Mostly faithful to established conventions: the `constraint_table` event reuses the §12 `conformance_manifest` inline-content pattern (DATA-LAYER.md:261, correctly cross-referenced against DATA-LAYER.md:414/443); the severities/reject-and-report discipline is consistent with §6.2's "MERGE stays a projection writer, never a gate" line (DATA-LAYER.md:207, 246); the set-based amendment/gate rule (DATA-LAYER.md:262) mirrors the spirit of ALGORITHM PR-3's "never loosen below the gated floor" pattern without literally reusing it (a defensible, undeclared parallel, not a contradiction).
- Diverges from §2.1's port layering: `GraphStore.merge()` is defined purely over `GraphDelta → MergeReport` (DATA-LAYER.md:83, 225) with no `TruthStore` dependency anywhere in the port list (DATA-LAYER.md:54–94). §6.3's requirement that "every hit... emits one `constraint_flag` administrative event" (line 250) needs either `GraphStore` to gain a `TruthStore` reference (an unstated new cross-port coupling) or the caller to be handed severity data `MergeReport` doesn't carry (Finding 1, above). Either path is a real design-layering change the section does not name as one, despite explicitly claiming "Port delta: none."
- `C-LIVENESS-SHAPE` only re-checks the "provisioned suite" half of PR-6 ("live ⇒ non-null `suite_ref`"), honestly scoped ("this entry checks the resulting shape, which is what a structural table can check," line 270) — it does not, and structurally cannot from `GraphDelta` alone, re-check "admitted verifier." This is disclosed, not hidden, and is fine as a design choice, but the property-impact statement's "PR-6 strengthened" (line 240) should be read as strengthening only the suite-presence half, not the whole property.

### 3. Red-team resistance

*Cross-checked against `ALGORITHM-v0.1-redteam.md`'s eight root causes.*
- **RC-3** (unscorable growth) and **RC-4** (add-only ratchet with no inverse): not reopened. `C-LIVENESS-SHAPE`/`C-NAMESPACE` reinforce RC-3's invariant with a second write-surface check rather than weakening it; the amendment rule (DATA-LAYER.md:262) gives violation-grade changes a real inverse-via-gate (an added/removed/upgraded/downgraded violation entry always requires the L-010 gate), which is the correct RC-4-shaped defense for the load-bearing half of the table.
- **RC-2** (gameable, self-calibrated verifier): not applicable — no verifier logic touched.
- **RC-1/RC-5/RC-6/RC-7/RC-8**: not implicated; this is a deterministic structural check, not a statistical or optimization mechanism.
- **Residual, not root-cause-reopening but worth naming as a watch item:** the amendment rule makes `warning`/`info` entry changes (add, edit, remove) "curator/operator-grade: gate-free, with `authorized_by` carrying the registering actor and a rationale string" (DATA-LAYER.md:262). A JUDGE-side operator can therefore remove `C-RETIRE-PROVENANCE` (currently the table's only audit-signal-shaped entry) unilaterally, with no independent review, no decision record, and only a self-supplied rationale string — exactly the "constraint inventory discovered one review round at a time" pattern (L-018, cited at line 240) applied in reverse, to *silencing* rather than *missing* a constraint. This does not reopen an RC (it requires a privileged JUDGE-side actor, not an optimization-pressure exploit reachable by SOLVE), but it is a governance gap the section does not address, and the fire-test discipline (§12.4-style, line 263) does not defend against an entry being *removed* rather than *never firing*.

### 4. Implementability

- Several load-bearing points leave a developer guessing:
  - The `MergeReport`/severity-conveyance gap (Finding 1, §1 above) — a developer cannot build `test_every_hit_flagged` without inventing a mechanism the spec disclaims.
  - The compound-predicate schema mismatch (Finding 2, §1 above) — a developer implementing `C-LIVENESS-SHAPE`/`C-EDGE-TYPE` must invent an AND-combinator or split the entries, neither of which the section specifies.
  - No concurrency rule for `table_version` assignment. DATA-LAYER.md:262/281 assume "the evaluation uses the highest `constraint_table` version" (`test_constraint_table_versioned_in_truth`), but unlike the `dispatch.seq` atomic-counter pattern this document specifies elsewhere in detail (DATA-LAYER.md:183, "assigned atomically inside the append transaction... including the first dispatch, via atomic upsert"), no equivalent atomic-versioning mechanism is stated for `constraint_table`. Two concurrent registrations racing on "next version" is unaddressed.
  - No stated scope for which `GraphDelta` collection(s) a `target: node`/`target: edge` predicate applies to (`adds` only, or also `merges`-produced survivors / any node touched by the delta). `C-LIVENESS-SHAPE`/`C-NAMESPACE` target "node" without saying whether a `retires`-bound node (whose effective status becomes `retired`, outside the entry's own `{live, pending_human}` enum) is in scope — as literally stated it would be, which would make every retirement a spurious violation.
  - `C-FANIN-CAP`'s anchor assumes an existing named, §12-registered cap parameter ("entries reference §12-registered parameters by name in `predicate.params`, never literals," DATA-LAYER.md:273). ALGORITHM-v0.2 §5.1's pseudocode (`add_soft_prereq_edges(s_new, top_k_by_confidence(co_mastery))`, line 129) implies a `k`/cap value but does not name it, and §12's open-parameter list (ALGORITHM-v0.2 lines 280–286) does not register a fan-in-cap parameter (it registers `topK, m` for §5.2 *retrieval*, a different mechanism). `C-FANIN-CAP` as written references a parameter that does not yet exist under any name in the base spec.
- The parts that are concrete are genuinely concrete: the `ConstraintEntry` dataclass shape, the fire-test discipline (uniform binding to `test_constraint_fires[constraint_id]`), the gate-vs-gate-free amendment split, and the initial 7-entry table with per-entry anchors are all specified precisely enough to start from, once the above gaps are closed.

### 5. Safety / integrity

- No existing gate, calibration layer (§14), or verifier (`HUMAN-LEARNING-VERIFIER.md`) is touched or weakened; "MERGE stays a projection writer, never a gate" is explicitly restated and not contradicted anywhere in the delta.
- Real, if currently low-consequence, gap: the promise that a `warning` "is surfaced for review through §20.7's delivery path" (DATA-LAYER.md:248) is not actually wired to §20.7's contract. ALGORITHM-v0.2 §20.7 (lines 637) names the classes that are *always delivered*: "`unknown` attempts (§20.2), sustained-deferral alerts (§20.4), breaker trips, and saturation events." A constraint `warning` is not in that list, and §20.7's rule is that "only success may be suppressed, via an explicit silence marker" — meaning anything not classified into an always-delivered class risks being folded into the default (suppressible) digest path. Without an explicit amendment naming constraint warnings as an always-delivered class, the entire justification for the `warning` severity ("surfaced for review," not silently applied) is unenforced by anything the spec actually wires. Currently low-consequence because the initial set ships zero `info` entries and only one `warning` entry (`C-RETIRE-PROVENANCE`, itself flagged above as likely vacuous) — but the gap is structural, not incidental, and would bite the moment a second `warning` entry is added under the gate-free amendment path.
- `authorized_by`'s dual form (decision-record reference vs. actor+rationale) is checked only for "presence and format," honestly disclosed as not validating the cited decision record's actual authenticity (DATA-LAYER.md:261) — appropriately scoped, consistent with how §12's checker treats similar deferred-validity claims elsewhere in this document (DATA-LAYER.md:411 "read-only observer").

### 6. Efficiency / cost

- The complexity bound is correctly stated and correctly separates the cheap per-entry families (cardinality, value-type/range, closed-shape, property-pair, namespace — all O(1) per entry, so O(|delta|) total) from the one genuinely expensive family (edge-set acyclicity, correctly attributed to the pre-existing §6.2 O(|V|+|E|) shadow-copy cost rather than double-counted as new — DATA-LAYER.md:242, consistent with DATA-LAYER.md:228).
- No new LLM/inference calls introduced; the whole mechanism is deterministic and stdlib-evaluable, matching the no-`eval` reasoning already established for §17.1 (DATA-LAYER.md:251).
- Minor, unaddressed: `C-FANIN-CAP`'s check (counting a node's existing prereq fan-in against a cap) requires reading existing incoming edges, not just the delta's new edges — a cost proportional to the node's current fan-in, bounded by the cap itself, so cheap in practice but not literally O(|delta|) as the blanket complexity claim (line 242) implies.

### 7. Completeness

- No edge-case handling for concurrent `constraint_table` version registration (see Implementability, §4).
- No stated scope for which `GraphDelta` collections node/edge-targeted predicates apply to (see Implementability, §4) — this is an edge-case gap, not just an implementability one, since retirement is a normal, expected code path.
- Test list (DATA-LAYER.md:281) is a reasonable set for the mechanism as *intended*, but several of its members (`test_every_hit_flagged`, and implicitly `test_constraint_fires[C-LIVENESS-SHAPE]`/`[C-EDGE-TYPE]`) cannot be written against the spec as literally stated (Findings 1 and 2, §1 above) — the test list inherits the same gaps rather than resolving them.
- No hyperparameter/bound is stated for constraint-table history growth (how many versions accumulate, whether/how old versions prune) — likely inherits the general truth-log retention discipline used elsewhere in this document, but that inheritance is not stated for this record class the way it is, e.g., for `rejected_ingest` (DATA-LAYER.md:193, explicit `w_rejected` retention window).

### 8. Consistency

- Internally contradicts itself: "Port delta: none" (line 279) vs. the requirement that every severity hit be conveyable to a truth-event writer (line 250) — see Finding 1.
- `C-FANIN-CAP`'s anchor assumes a §12-registered parameter that ALGORITHM-v0.2 §12 does not currently register under any name (see Implementability, §4) — an inconsistency between what this delta assumes is already true of the base spec and what the base spec actually contains.
- Otherwise consistent with §6.1/§6.2 (correctly extends the exemption list at DATA-LAYER.md:189, correctly extends the write-discipline test set structure at line 235/281) and with §11/§12's administrative-event and inline-content conventions.

### 9. Calibration / honesty

- Several places are carefully, appropriately hedged: the registration-validity disclaimer (line 261, "stated honestly rather than claimed as a runtime verification"), the acyclicity migration's precise scoping to "rejection-set-identical" rather than "byte-identical" (line 277), and the explicit statement that `C-LIVENESS-SHAPE` only checks what a structural table *can* check rather than the whole of PR-6 (line 270). This is good practice, consistent with this document's own established discipline (e.g. §12.1's "stated honestly" pattern at DATA-LAYER.md:411).
- Against that, "**Port delta: none**" (line 279) is a flat, unhedged claim that the correctness findings above show to be false as the mechanism is actually specified — an overclaim of exactly the kind the rest of the section is careful to avoid elsewhere, and the kind of claim §21.3's property-impact discipline exists to force honest treatment of.
- "PR-6 strengthened" (line 240) is defensible but should be scoped to the suite-presence half of PR-6 rather than stated as a blanket strengthening of the whole property (see Design Faithfulness, §2).

## Strongest adversarial objection

The section's central selling point — "turns 'a check someone remembered to code' into a declared table the write path evaluates, so the constraint inventory is data with an audit trail, not scattered code" (DATA-LAYER.md:240) — is undermined by its own audit-trail mechanism for exactly the two severities (`warning`, `info`) that exist *only* to produce an audit trail rather than to gate. A `violation` entry needs no `constraint_flag` event to be effective: it already shows up in `MergeReport.rejected`, in the delta's rejection, in downstream test assertions. It is precisely the non-blocking severities — the ones whose entire reason for existing is "watch and record, don't gate" (line 249) — that depend on the one channel (`constraint_flag`, sourced from `MergeReport`) the section simultaneously declares unchanged (line 279). So the part of the design that is genuinely new (severity-graded, non-gating structural observation) is the part that doesn't actually work as specified, while the part that already worked before this change (violation → reject, via the pre-existing `rejected` field) is the part that needed no new mechanism at all. A reviewer could reasonably read this as the proposal having fully solved the easy 90% (which already existed) and silently assumed away the hard 10% (the actual generalization) — the same "presence of a mechanism is not the mechanism's truth" trap this document explicitly names for the conformance checker (DATA-LAYER.md §12.4, "a predicate's existence is not the property's truth") applied to itself, one section earlier in the same file.

## Aggregate confidence

```
critical_floor  = min(Correctness=52, RedTeam=80, Safety=74) = 52
weighted_mean   = (52*2 + 70 + 80*2 + 55 + 74*2 + 85 + 58 + 58 + 68) / 11
                = (104 + 70 + 160 + 55 + 148 + 85 + 58 + 58 + 68) / 11
                = 806 / 11
                = 73.27 → 73
overall         = min(52, 73) = 52
```

**Overall confidence: 52 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to clear Correctness ≥ 70):

1. Resolve the `MergeReport`/severity-conveyance contradiction: either add a field to `MergeReport` (e.g. `flagged: [(id, constraint_id, severity)]`) covering non-rejecting hits, or specify a concrete `GraphStore → TruthStore` write path for `constraint_flag`, and correct the "Port delta: none" claim (DATA-LAYER.md:279) to match whichever is chosen.
2. Resolve the single-family predicate-schema mismatch for `C-LIVENESS-SHAPE` and `C-EDGE-TYPE`: either extend `ConstraintEntry.predicate` to a conjunctive/list form and state that as an explicit, deliberate extension to the "fixed and small" vocabulary, or split each into multiple single-family `constraint_id`s in the initial set.
3. Re-anchor or re-scope `C-RETIRE-PROVENANCE` against the actual `GraphDelta` schema (per-entry vs. delta-level `provenance`), or add the per-entry provenance field it needs and disclose that as a schema delta.
4. Name constraint `warning`s as an explicit always-delivered class in ALGORITHM §20.7 (or state, if intentionally deferred, that the "surfaced for review" promise (DATA-LAYER.md:248) does not yet hold and is future work), so the one severity whose entire purpose is human review is not silently swallowed by the default digest-suppression rule.
5. Either register the §5.1 fan-in-cap parameter by name in ALGORITHM §12, or drop the "§12-registered parameters by name" claim from `C-FANIN-CAP` (DATA-LAYER.md:273) until it is.
6. State the `GraphDelta` collection scope (`adds` vs. `retires` vs. `merges`-survivors) each node/edge-targeted predicate applies to, and specify an atomic `table_version` assignment mechanism analogous to the existing `dispatch.seq` pattern.
