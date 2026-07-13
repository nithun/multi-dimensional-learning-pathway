# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 6)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–511), marked "added 2026-07-13, revised r6" |
| Proposed change | Round-6 rewrite of the `CAPTURE` bullet (line 507) closing round 5's two blocking scope gaps: (1) fleet scoping — states the ancestry walk runs on "the proposing agent's own checkpoint chain," claims the lineage table now "carries the `agent_id` key exactly as `StateStore` does," and states CAPTURE from another agent's episodes is "prohibited outright" via B3-only transfer; (2) retention — states §10's checkpoint retention/GC prunes checkpoint *blobs* only, that lineage *rows* are permanent (same discipline as `scaffold_versions`), so the ancestry walk never dead-ends on a GC'd row |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Rounds 1–5 item resolution audit (every numbered item, closed or explicitly deferred)

| # | Item (originating round) | Status this round | Evidence |
|---|---|---|---|
| 1 | `revalidation` in the formal schema block (R3) | **Still closed, unchanged** | `:498` — `revalidation ∈ {n/a, pending, passed, failed}` remains in the code block. |
| 2 | Quantify + register `κ_reval` (R3) | **Still closed, unchanged** | `:508` (κ_reval = 0.5, tightened-monitor multiplier); `:509` (registered, "extends §17.5"); `:286` (§12 list). Text verbatim-identical to r4/r5 on this point. |
| 3 | `source_ref` self-contradiction: schema field vs. `CAPTURE` bullet (R4/R5) | **Still closed, unchanged** | `:489–491` defers to the `CAPTURE` bullet; `:507` states the ancestry predicate once. No regression — grep for `eval rows` / `TruthStore eval rows` / `gated episode` still returns zero hits in §17.6. |
| 4 | Temporal soundness — ancestry vs. bare existence, single-agent case (R4→R5) | **Still closed, unchanged, for the single-agent case** | `:507` unchanged from r5 on this specific clause ("a checkpoint whose commit was later reversed... is off the current ancestry path"). Re-verified sound against §3/§8's RC-5 rollback mechanism — see Correctness C-1. |
| 5 | `snapshot`/`snapshot_ref` naming/content-vs-reference mismatch with DATA-LAYER (R4) | **Still closed, unchanged** | `:492–493` matches `DATA-LAYER.md:138`'s `snapshot_ref` field exactly. |
| 6 | Register `scaffold_versions` + `selfmod_rejected` (+ `component_invoked`) as one DATA-LAYER §5 delta (R3/R4) | **Still closed, unchanged** | `DATA-LAYER.md:138` — the three artifacts are present, field-for-field matching `:485–499`. |
| 7 | Name the §6-orchestrator plug-point for per-component invocation logging (R3, closed R5) | **Still closed, unchanged** | `:506` — `component_invoked{component_id, episode_id, ts}`, unchanged. |
| 8 | (R2/R3 legacy) `τ_sm`/`w_prune` §12 registration, invocation-based prune well-definedness, `selfmod_rejected` flood bound | **Still closed, unchanged** | `:286`, `:503`, `:506` unedited, no regression found. |
| 9 | Reactivation mechanism never cross-referenced to §7's RC-6 fix (discounted UCT + tree invalidation) as the code-axis analog (R2 DF-4 → R3 DF-4 → R4 DF-4 → R5 DF-1) | **Still open — now unaddressed across 4 consecutive rounds (R3, R4, R5, R6)** | `:508` (the entire reactivation/rollback paragraph) has no mention of §7, `discounted`, `invalidate`, or `UCT`. A grep for `§7` inside §17.6 (`:479–511`) returns zero hits. See Design faithfulness DF-1. |
| 10 | Fleet-scoping well-definedness of "current live checkpoint" under §18's multi-agent architecture (raised as R5 item 10 / R5 verdict item 1) | **Substantively addressed for the *interpretive* ambiguity; the specific enforcement-mechanism claim is unverified/false** | `:507` — "the walk runs on the **proposing agent's own** checkpoint chain" now explicitly answers r5's Correctness C-2 ("does 'current live checkpoint' mean the checkpoint of the agent performing this episode?" — yes, now stated). But the accompanying claim — "under §18 the lineage rows carry the `agent_id` key exactly as `StateStore` does (§18.1's schema delta extends to lineage)" — is false as literally written: `DATA-LAYER.md:138`'s `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` has no `agent_id` column, and `DATA-LAYER.md:139`'s `StateStore` `cell{...}` record doesn't have one either (§18.1's own `agent_id` claim, `:521`, was never itself shipped as a DATA-LAYER delta — `IMPLEMENTATION-v2.md:243` correctly describes it in *planned* tense, "`Cell` gains an `agent_id` key," not as an already-existing field). Worse, `:501` — this section's *own* "DATA-LAYER schema delta ships with this section" note — lists exactly three artifacts (`scaffold_versions`, `selfmod_rejected`, `component_invoked`) and does **not** include a lineage/`agent_id` delta, directly contradicting `:507`'s claim that this delta "ships"/"extends to lineage." See Correctness C-2, Consistency Cs-1, Calibration Ca-1. |
| 11 | Retention/GC interaction — do §10's checkpoint retention policies risk pruning `lineage` rows the ancestry walk depends on? (raised as R5 item 10 / R5 verdict item 2) | **Genuinely, cleanly resolved** | `:507` — "§10's checkpoint retention/GC prunes checkpoint *blobs* only — lineage *rows* (the parent chain) are permanent, the same rows-permanent discipline as `scaffold_versions`." This is a sound, verifiable argument, not a bare assertion: `DATA-LAYER.md:87`'s `ArtifactStore.gc(self, retention)` is the only GC-capable port in the whole data layer; `TruthStore` (§2.1, `DATA-LAYER.md:52–57`) has no `gc`/`prune` method at all, and `DATA-LAYER.md:149` states "`TruthStore` is canonical and append-only." §10's own text (`:266`, "Checkpoints and the tree get retention/GC policies") is ambiguous in isolation, but read against the concrete port definitions, the "blobs-only" reading is the only one the actual store contracts support. `test_lineage_rows_never_deleted` (`:510`) is now implementable and well-grounded. See Correctness C-3. |

Two of round 5's blocking items are addressed this round: item 11 (retention) cleanly; item 10 (fleet scoping) only partially — the interpretive question (whose chain to walk) is now genuinely resolved, but the round introduces a new, directly falsifiable schema claim to justify it, recurring the exact "claimed-but-absent artifact" defect class that has appeared, in some form, in every one of rounds 1 through 4 (and that round 5 was specifically praised for avoiding *within* §17.6's own four walls). Item 9 (the §7 cross-reference) remains untouched for a fourth consecutive round.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 80 | pass |
| 2 | Design faithfulness | 75 | pass |
| 3 | Red-team resistance (CRITICAL) | 76 | pass |
| 4 | Implementability | 78 | pass |
| 5 | Safety / integrity (CRITICAL) | 78 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 76 | pass |
| 8 | Consistency | 62 | weak |
| 9 | Calibration / honesty | 70 | pass |

## Findings by dimension

### 1. Correctness

**Score: 80 — pass**

**C-1. Round 5's flagship fix (ancestry, not existence, for the single-agent checkpoint chain) remains sound and unchanged.** `:507` unedited on this specific clause; re-traced against §3 (`:57–58`, dual mastery/drift posteriors, drift "drives rollback only") and §8 (`:229`, "rollback fires only on a FRESH, adequately-powered re-eval"): a rolled-back checkpoint is structurally excluded from the current ancestry path, so "is an ancestor" correctly and permanently excludes it where "exists in lineage" would not. No regression.

**C-2. NEW, the round's central defect: the fleet-scoping fix's *interpretive* answer is genuinely correct and well-defined; its *cited mechanism* is false.** `:507` states, correctly and for the first time across all six rounds, which checkpoint "current live checkpoint" refers to: "the walk runs on the **proposing agent's own** checkpoint chain." This is a real, substantive fix to round 5's Correctness C-2 (which flagged exactly this ambiguity as unresolved) — a developer reading this sentence alone now knows precisely which checkpoint to pass to the walk, and the underlying logic (walk `parent`-chain from a specific, named starting checkpoint) does not actually *require* a fleet-wide disambiguator to be correct, since a single starting checkpoint's own ancestor chain is well-defined regardless of what else lives in the shared table. But the sentence does not stop there — it continues: "under §18 the lineage rows carry the `agent_id` key exactly as `StateStore` does (§18.1's schema delta extends to lineage)." This is a separate, additional, and **false** factual claim, checked directly: `DATA-LAYER.md:138`'s `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` schema has no `agent_id` field, and (as a check on the "exactly as `StateStore` does" comparator) `DATA-LAYER.md:139`'s `StateStore` `cell{...}` record doesn't have one either — §18.1's own `agent_id` claim (`:521`, "the schema delta") was itself never reflected in `DATA-LAYER.md`'s registered schema; `IMPLEMENTATION-v2.md:243` independently confirms this is a *planned*, not-yet-built item ("`Cell` **gains** an `agent_id` key"). So the comparator itself ("exactly as `StateStore` does") points at an artifact that also doesn't exist yet, compounding rather than grounding the claim. Because the correctness of the *walk itself* does not depend on this sentence being true (a specific starting checkpoint's ancestor chain is well-defined with or without a table-wide `agent_id` column), this is scored as a real but narrower defect than a logic error — it is an unverified, false citation attached to an otherwise-sound fix, not a broken mechanism. It is nonetheless a serious defect in its own right: see Consistency Cs-1 and Calibration Ca-1.

**C-3. Round 5's retention/GC gap is genuinely, cleanly resolved with a well-grounded argument (see the audit table, item 11).** This closes round 5's Correctness C-3.

**C-4. `κ_reval`'s arithmetic remains correct, unchanged from rounds 4–5.** Re-verified by direct substitution (no formula change this round):
```
python3 -c "z=2.0; se=1.0; print('normal trip:', z*se, ' tightened trip:', 0.5*z*se)"
→ normal trip: 2.0  tightened trip: 1.0
```
A smaller `Δ` clears the tightened bar, correctly realizing "stricter scrutiny," matching round 4/5's verified result.

**Summary:** two of round 5's two open items are addressed — one (retention) cleanly, one (fleet scoping) with the underlying interpretive question genuinely resolved but a false, unnecessary schema-mechanism claim attached. Because the walk's actual soundness does not hinge on the false claim, this dimension clears 70 for a second consecutive round, higher than round 5's residual (a mechanism that is sound where checked, undermined only by an over-claimed justification for a part that would have been fine left unstated or stated honestly as a future delta).

---

### 2. Design faithfulness

**Score: 75 — pass**

**DF-1. Unresolved across four consecutive rounds (R3 DF-4, R4 DF-4, R5 DF-1, now R6): the reactivation mechanism (`:508`) is still never explicitly connected to §7's RC-6 fix (discounted UCT + tree-value invalidation) as the deliberate code-axis analog.** A one-line fix, requested by name for the fourth time, still not made — see the audit table item 9. This is a pattern of the revision process reliably fixing the items a round's own cover note names and reliably not picking up a previously-identified, trivially-fixable item even while making substantive edits to the same paragraph's neighboring bullet.

**DF-2. The `:507` fleet-scoping addition follows §18.1's own established in-document convention** (a narrative "(the schema delta)" annotation for a per-agent key, rather than an immediate `DATA-LAYER.md` edit) — faithful to how §18.1 itself is written. **But this is in tension with the stricter, more concrete bar this specific section (§17.6) has itself been held to and has itself met across rounds 3–4**, where the caller was required to (and did) add `scaffold_versions`/`selfmod_rejected`/`revalidation` as an actual `DATA-LAYER.md` line, not merely a prose reference — see Consistency Cs-1. Faithful to one precedent in the document family, inconsistent with the higher bar this exact section has already cleared for its own other artifacts three rounds running.

**DF-3. The retention argument (`:507`) is a faithful, correctly-reasoned extension of §10's existing checkpoint/tree GC clause (`:266`) and the store-role split (`DATA-LAYER.md:15`, `:20`, `:87`)** — good design reuse, not an invented mechanism.

**DF-4. Attribution to OpenSpace (`:481`) is unchanged and remains accurate.**

---

### 3. Red-team resistance

**Score: 76 — pass**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8.

**RT-1. Round 5's RT-1 (single-agent ancestry closing the RC-2-adjacent "no capturing lucky runs" gap) remains closed, unchanged.**

**RT-2. Round 5's RT-2 (fleet-scale RC-6-adjacent residual — is the ancestry guarantee well-defined at fleet scale?) is narrowed but not fully closed.** The *definition* is now explicit and unambiguous ("the proposing agent's own checkpoint chain") — a real improvement that removes the specification gap RT-2 identified. What remains open is *auditability*: `:507`'s claim that cross-agent `CAPTURE` "is prohibited outright" is an architectural-intent statement consistent with §18.1's B3-only transfer doctrine (`:521`, "never by reading another agent's state"), but the specific artifact cited as making it *checkable* (an `agent_id` key on `lineage`) does not exist, so there is currently no way to *audit after the fact* that the prohibition actually held — the same "stated safety rule with no enforcement artifact behind it" shape RC-2's root pattern names, and the same shape rounds 1 and 3 flagged for `CAPTURE`'s original provenance gap and the `revalidation` field respectively. It is narrower than either of those instances because the underlying walk (parent-chain traversal from a single named checkpoint) plausibly enforces the "own chain only" property *structurally*, by construction, without needing the cited column at all — but the section asserts the wrong justification for a claim that might otherwise be true, which is a real, if smaller, instance of the same defect family.

**RT-3. Round 3's honestly-scoped RC-6 residual (reactivation narrows but does not close the stale-fallback window) remains open in the same, unchanged, honestly-labeled form** (`:508`, "narrows... does not close"). No regression.

**RT-4. No previously-closed red-team item is reopened.** The wall invariant, capability isolation, dedup-in-JUDGE-admission-path, and `selfmod_rejected` flood bound are all unchanged and re-verified present.

**Summary:** the round's fleet-scoping fix removes a genuine specification gap (RT-2's definitional half) without reopening anything previously closed, but leaves the auditability half of that same gap open in a new, narrower shape — enough to keep this CRITICAL dimension in the "pass" band, below round 5's 78 but above the 70 floor.

---

### 4. Implementability

**Score: 78 — pass**

**I-1. The fleet-scoping ambiguity that blocked implementation in round 5 (I-2, "what checkpoint value to pass as 'the current live checkpoint'") is now resolved as a matter of specification.** "The proposing agent's own checkpoint chain" is a complete, actionable instruction — a developer can implement the walk today by parameterizing it on the calling agent's own current checkpoint, with no invented scoping rule required. This closes round 5's I-2 for the part that actually blocks implementation.

**I-2. NEW, minor: the unverified `agent_id`/lineage claim (Correctness C-2) creates a smaller, secondary implementation hazard — a developer might spend effort searching for, or incorrectly assume the pre-existence of, a `lineage.agent_id` column that isn't in the registered schema**, before realizing (or not realizing) that the walk as actually specified doesn't need it. Not blocking, since the operative instruction ("own chain only") doesn't depend on the column, but a real, avoidable friction the section itself introduces.

**I-3. The retention fix (`:507`) is now implementable and consistent with the concrete store contracts** (`DATA-LAYER.md:87`'s `ArtifactStore.gc`, `TruthStore`'s absence of any prune method) — closes round 5's I-4.

**I-4. Unresolved, unchanged: no cross-reference from the reactivation mechanism to §7's discounted-UCT/invalidation pattern** (DF-1) — a documentation-only gap, not implementation-blocking, but still a missed opportunity to reuse an already-specified pattern by name.

---

### 5. Safety / integrity

**Score: 78 — pass**

**S-1. No named gate, budget enforcer, or partition is weakened.** §17.1/§17.3/§17.5 text is unchanged; the `self_modify` budget enforcer remains JUDGE-owned (`:455`).

**S-2. The retention fix is a genuine, verified safety improvement:** the ancestry walk can no longer silently dead-end or behave undefined-ly on a GC'd row, closing a real (if narrow) potential availability/correctness gap in `CAPTURE`'s admission path.

**S-3. The cross-agent `CAPTURE` prohibition ("prohibited outright," `:507`) is a stated safety property whose *architectural intent* is sound and consistent with §18.1's established B3-only doctrine, but whose claimed enforcement artifact (the `agent_id` key) does not exist, so the property is not currently auditable from the schema as literally described.** This is the safety-relevant expression of Correctness C-2 / Red-team RT-2 — not a weakening of any existing gate, but a safety-relevant claim resting on an unverified citation, which is a real (if narrower) instance of the pattern this exact review thread has repeatedly flagged as safety-relevant when it recurs (round 2's S-3, round 3's S-3, round 4's S-3).

**S-4. The single-agent `CAPTURE` safety improvement from round 5 (RT-1/S-2 in that report) remains fully intact, unchanged.**

---

### 6. Efficiency / cost

**Score: 78 — pass**

**E-1. The ancestor-chain walk remains a bounded, cold-path operation**, unchanged from round 5 — no complexity regression.

**E-2. The retention fix (`:507`) newly and explicitly confirms that `lineage` rows are permanent** (rather than merely "plausible" as in round 5's C-3) — which means round 5's E-2 concern (chain depth grows unboundedly over a long-running agent's lifetime, since rows never age out) is now a *confirmed*, not merely inferred, property of the system, and remains unaddressed as a cost note (no amortization or milestone-shortcut mechanism is offered for the walk's own performance as chains grow, though §10 does mention "tagged milestones" for the rewind horizon generally). Slightly more concrete than round 5's E-2, not new in kind.

**E-3. `w_prune`'s soft eviction bound (unchanged from rounds 3–5) remains open** — no cap on live-component count, unchanged.

---

### 7. Completeness

**Score: 76 — pass**

**Co-1. Resolved: the retention/GC interaction with the ancestry walk (round 5's Co-4)** — now cleanly present and well-grounded against the concrete store contracts.

**Co-2. Substantially resolved: the fleet-scoping gap (round 5's Co-3)** — the *definitional* half (which checkpoint) is now fully specified; the *enforcement/audit* half (how the "own chain only" / "prohibited outright" property is actually checked or observed) is not — no field, event, or test asserts that a `CAPTURE` was in fact scoped to the proposing agent's own chain, beyond the (unverified) `agent_id` reference. A `test_capture_scoped_to_own_agent_chain`-style stub is conspicuously absent from the `:510` checks list, unlike every other safety-relevant claim in this section (each of which does have a named test).

**Co-3. Unresolved, unchanged across four rounds: no explicit cross-reference from the reactivation mechanism to §7's RC-6 pattern** (DF-1) — minor, non-blocking, but now a persistent gap in the document's own stated practice of naming design-pattern reuse explicitly.

**Co-4. NEW: this section's own `:501` "DATA-LAYER schema delta ships with this section" note is now incomplete relative to `:507`'s own claim** — if the lineage table really is meant to gain an `agent_id` key as part of this round's change, `:501` is the place that should say so (as it already does for `scaffold_versions`/`selfmod_rejected`/`component_invoked`), and it does not. See Consistency Cs-1.

**Co-5. Positive:** the test-stub list (`:510`) is otherwise complete and well-mapped to the section's other claims (`test_lineage_rows_never_deleted` is a clean, direct addition matching the retention fix).

---

### 8. Consistency

**Score: 62 — weak**

**Cs-1. NEW, and the round's single most concrete, grep-verifiable inconsistency: `:501`'s own "DATA-LAYER schema delta ships with this section" note omits the lineage/`agent_id` extension that `:507` claims exists in the same round's text.** `:501` reads, in full: "the `scaffold_versions` table and the `selfmod_rejected` + `component_invoked` event kinds are Truth-store schema — recorded as a delta line in DATA-LAYER §5." Three lines later, `:507` states, in the same section, about the same DATA-LAYER §5: "under §18 the lineage rows carry the `agent_id` key... (§18.1's schema delta extends to lineage)." These two sentences, in the same section, about the same target file, disagree about what that section's own delta covers — the shape of defect is identical to round 4's Cs-1 (two bullets of the same list disagreeing about the same mechanism), just relocated from an intra-section ("schema field vs. `CAPTURE` bullet") disagreement to an intra-section-but-cross-file ("delta note vs. `CAPTURE` bullet, both about `DATA-LAYER.md`") disagreement. A reader (or a developer literally implementing "the DATA-LAYER schema delta ships with this section" as an instruction) would build exactly three artifacts from `:501` and miss the fourth (`lineage.agent_id`) that `:507` implies should also be there.

**Cs-2. Direct cross-file inconsistency, independent of Cs-1: `:507`'s present-tense claim ("the lineage rows carry the `agent_id` key") is false against `DATA-LAYER.md:138`'s actual, current `lineage` schema, and the comparator it invokes ("exactly as `StateStore` does") is also false against `DATA-LAYER.md:139`'s actual, current `StateStore` `cell{...}` schema** — neither table has this field. `IMPLEMENTATION-v2.md:243` independently confirms the correct, hedged tense for this exact addition ("`Cell` **gains** an `agent_id` key" — a planned build item, not a shipped fact), which is the register `:507` should have used and did not.

**Cs-3. All of rounds 4–5's previously-resolved consistency fixes remain resolved, unchanged** — `source_ref`/`CAPTURE` bullet agreement, `snapshot_ref` naming, `revalidation`'s presence across the schema block/prose/§12/DATA-LAYER.

**Summary:** this round cleanly and correctly closes the retention interaction (a genuine consistency win, reconciling `:507` against `DATA-LAYER.md`'s actual `ArtifactStore`/`TruthStore` port contracts), but in fixing the fleet-scoping gap it introduces a new, concrete, easily-checked contradiction of the same species as round 4's flagship defect — recurring for a fifth time across six rounds, now in a form that spans this section's own two internal claims about the same external file. This is why the dimension does not clear 70 this round despite the round's otherwise-strong showing.

---

### 9. Calibration / honesty

**Score: 70 — pass**

**Ca-1. Overclaim, narrower than round 2's or round 4's flagship instances but real: "the lineage rows carry the `agent_id` key exactly as `StateStore` does (§18.1's schema delta extends to lineage)" (`:507`) is stated as settled, present-tense fact when it is an unshipped, narrative-only extension — not even listed in this section's own `:501` delta note, and not reflected in `DATA-LAYER.md`'s current schema for either table.** The honest phrasing (matching this document's own better practice elsewhere, e.g. `:508`'s "narrows... does not close," or `:507`'s own adjacent "Residual honesty, two-fold") would be something like "the walk is scoped to the proposing agent's own checkpoint chain; disambiguating this at the schema level (an `agent_id` key on `lineage`, mirroring the planned `StateStore` delta) is a DATA-LAYER follow-up, not yet shipped." This is a real, citable overclaim, but it is a secondary/qualifying clause supporting an otherwise-correct headline claim (the definitional scoping fix), not the load-bearing claim itself — narrower in consequence than round 2's flat-false "registered in §12" or round 4's "EXISTS ⇔ gate passed" overclaim, both of which were the *entire* substance of their round's headline fix.

**Ca-2. Genuine, accurate: the retention claim (`:507`) is stated with an argument that holds up under direct verification against the concrete store contracts** (Correctness C-3) — well-calibrated, not overclaimed.

**Ca-3. The "Residual honesty, two-fold" language (`:507`, unchanged from round 5) remains accurate and appropriately hedged** for the two properties it explicitly scopes (post-admission rollback of the source; ancestry-proves-gating-not-causation) — this round doesn't touch or regress this language.

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (`:481`)** — verified true.

**Summary:** the round's calibration is a mixed picture — genuinely well-hedged and verified on the retention fix, but the fleet-scoping fix's supporting citation is asserted with more confidence than its actual, checkable state supports. This is a smaller-scope version of a defect class this section's calibration has now shown in some form in rounds 2 (flagship), 4 (flagship), and 6 (secondary clause) — real progress in *severity* (this round's version doesn't undermine the headline claim), but the underlying discipline gap (assert only what's been checked against the current state of every file referenced) has still not been closed as a matter of process.

---

## Strongest adversarial objection

**Six rounds in, the review has now caught the identical base defect — a schema/registration claim asserted as fact when the referenced file does not contain it — five times, each time in a narrower or more distant scope than the last, and this round's instance is the first to be internally self-contradicted by the very same section's own adjacent sentence.**

Trace the escalation precisely. Round 1: `CAPTURE`'s admission invariant had no field to anchor it at all (a bare omission). Round 2: `τ_sm`/`w_prune` were asserted "registered in §12" when they were not (a false claim about a *different section of the same file*). Round 3: `revalidation` was used in prose and by a test stub but was absent from the section's own code block (a false claim about *the section's own schema block*). Round 4: `source_ref`'s two descriptions directly contradicted each other within three lines of the same bullet list (an *intra-section* contradiction). Round 5 was the first round to show no new instance of this defect class — its own residual (fleet-scoping ambiguity) was an honestly-flagged, unaddressed gap, not a false claim. Round 6, commissioned specifically to close that gap, reintroduces the defect in a fifth shape: a claim about a field's presence in **an external file** (`DATA-LAYER.md`), asserted in a section whose own immediately-preceding delta note (`:501`) — written in the very same round, about the very same file — does not include it. This is not merely "the same category of mistake happening again"; it is evidence that no amount of the specific closing-pass discipline requested by rounds 3, 4, and 5 (grep the schema block; grep the section; grep the whole document for the referenced concept) will structurally prevent the next recurrence, because each round's discipline has correctly caught the *previous* round's scope of the problem and then the *next* round's fix has found a new scope one level further out — schema block → section → document → file the document merely references. The pattern strongly suggests the actual fix is not another instruction to check one more place; it is a standing rule for this specific artifact's revision process: **no round's diff may add a present-tense claim about the contents of `DATA-LAYER.md` (or any file besides the one being edited) without that round's own diff also touching `DATA-LAYER.md` to make the claim true, in the same commit.** Absent that rule, a seventh round fixing whatever this round leaves open has a well-established base rate of introducing an eighth instance of the same defect somewhere the current review does not think to check.

## Aggregate confidence

```
critical_floor  = min(Correctness=80, RedTeam=76, Safety=78) = 76
weighted_mean   = (80*2 + 75 + 76*2 + 78 + 78*2 + 78 + 76 + 62 + 70) / 11
                = (160 + 75 + 152 + 78 + 156 + 78 + 76 + 62 + 70) / 11
                = 907 / 11 = 82.45 → 82
overall         = min(76, 82) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

This is the strongest round in the section's six-round history on substance — both gaps round 5 left open are addressed, one (retention) cleanly and with a sound, verifiable argument against the concrete `ArtifactStore`/`TruthStore` port contracts, and the other (fleet scoping) genuinely resolves the harder, definitional half of the ambiguity round 5 flagged (which checkpoint chain "current live checkpoint" refers to — now explicit: "the proposing agent's own"). All three CRITICAL dimensions individually clear 70 (Correctness 80, Red-team 76, Safety 78) for the second round running. The score does not clear 80 because the round's own fix for the harder of round 5's two gaps introduces a new, directly falsifiable claim — the fifth instance across six rounds of this section's single most persistent defect class (asserting a schema/registration fact that does not hold when checked):

1. **Fix the `agent_id`/lineage claim in the `CAPTURE` bullet (`:507`).** Either (a) actually add `agent_id` to `DATA-LAYER.md:138`'s `lineage` schema in the same commit and list it in `:501`'s delta note alongside `scaffold_versions`/`selfmod_rejected`/`component_invoked`, or (b) drop the schema-mechanism claim entirely and rely on the (already sufficient, already correct) definitional statement — "the walk runs on the proposing agent's own checkpoint chain" — without asserting an unshipped column exists to enforce it, hedging honestly if a future schema delta is intended (matching `IMPLEMENTATION-v2.md:243`'s already-correct planned-tense phrasing for the analogous `StateStore` case). Either fix also closes the `:501`-vs-`:507` intra-section inconsistency (Consistency Cs-1) and the overclaim (Calibration Ca-1). (Correctness C-2, Red-team RT-2, Implementability I-2, Completeness Co-2/Co-4, Consistency Cs-1/Cs-2, Calibration Ca-1)
2. **Add a test stub asserting the cross-agent `CAPTURE` prohibition** (e.g. `test_capture_rejects_other_agent_checkpoint`), so "prohibited outright" (`:507`) has an auditable check the way every other safety-relevant claim in `:510`'s list already does. (Red-team RT-2, Completeness Co-2)
3. **(Minor, carried across four rounds, easy to close) Add the one-line cross-reference from the reactivation mechanism (`:508`) to §7's RC-6 fix**, naming it explicitly as the code-axis analog of discounted-UCT/tree-invalidation. (Design faithfulness DF-1, Completeness Co-3, Implementability I-4)

If a round 7 is commissioned, the standing rule proposed in the adversarial pass above should be applied explicitly: any new sentence in this section that makes a present-tense claim about the contents of `DATA-LAYER.md` (or any other file) must be checked against that file's *current* text before submission, and if the claim isn't true yet, either make it true in the same diff or state it in planned/future tense. Given this defect class has now recurred in five of six rounds in five different shapes, a single additional review pass is unlikely to be sufficient without this rule being adopted as a standing authoring discipline for this section specifically.
