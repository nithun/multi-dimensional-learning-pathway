# 360 Review: S21-safety-properties — 2026-08-13 (round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §21 "Safety properties — what is always true" (lines 649–698, uncommitted working-tree revision, round 2) |
| Proposed change | Revision responding to round 1's five required changes: PR-5 rewritten as "Staged Reversibility" narrowing the claim to what §9 actually establishes; the Maintained-by column corrected; a new guard (`test_stage2_merge_gated_behind_reversible_stage1`, §21.2) defined to close the round-1 guard-coverage gap; the §21.3 enforcement claim wired into `skills/spec-change-gate/SKILL.md`'s checklist (step 4, committed this session); the §21.4 RC-map entries for RC-1/RC-5/RC-8 rewritten with named connective mechanisms. |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Round-1 disposition (for reference)

Round 1 overall: 35/100, needs-revision, five numbered required changes (`docs/research/reviews/S21-safety-properties-review.md`). This round re-scores fresh per the reviewing brief's instruction.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 64 | weak |
| 2 | Design faithfulness | 68 | weak |
| 3 | Red-team resistance (CRITICAL) | 68 | weak |
| 4 | Implementability | 68 | weak |
| 5 | Safety / integrity (CRITICAL) | 72 | pass |
| 6 | Efficiency / cost | 95 | pass |
| 7 | Completeness | 73 | pass |
| 8 | Consistency | 65 | weak |
| 9 | Calibration / honesty | 68 | weak |

## Findings by dimension

### 1. Correctness

**Round 1's flat contradiction is genuinely fixed.** PR-5 (`ALGORITHM-v0.2-pathway-learner.md:663`) now reads: *"Every growth operation (§5.1) and every code-axis promotion (§17.3) has an inverse reachable without data loss. The **sole declared irreversibility** is the weight-axis Stage-2 base merge (§9 — its own text: 'irreversible, fully gated' / 'mostly-reversible' path)..."* — this quotes §9's own language (`ALGORITHM-v0.2-pathway-learner.md:254,256`) instead of contradicting it, and the Maintained-by column no longer attributes a retained fallback to §9 (it now says "§9 Stage-1 detachable adapter (the reversible half; Stage-2 declared irreversible)"). Verified against source: §5.1's `g.prune_orphans()` inverse is confirmed genuinely data-loss-free — `DATA-LAYER.md:148` gives Graph nodes a `status: live|pending_human|retired` field ("`retired` realizes `g.prune_orphans`'s inverse at the store"), and `DATA-LAYER.md:235`'s `MergeReport{...retired...}` makes retirement visible, not silent deletion. §17.3/§17.6's code-axis claim is also confirmed — snapshots are immutable and reactivation is "byte-exact" (`ALGORITHM-v0.2-pathway-learner.md:508`). This is a real, well-evidenced fix.

**New blocking-adjacent finding — the new guard's clause (ii) asserts a schema capability that does not exist and is not declared as a delta.** §21.2 (`ALGORITHM-v0.2-pathway-learner.md:674`) defines `test_stage2_merge_gated_behind_reversible_stage1` with two clauses: (i) the Stage-1 conjunction gate (verified — matches §9's code block verbatim, `ALGORITHM-v0.2-pathway-learner.md:253`), and (ii) *"every Stage-2 merge is recorded in lineage (§10) as **irreversible-class**, so no downstream tooling can ever treat a base merge as freely revertible."* The `lineage` table's actual schema, per `DATA-LAYER.md:145`, is `lineage(checkpoint_id, parent, dataset_id, eval_run_id, agent_id)` — there is no "class" field, no irreversibility marker, and no event kind recording a promotion/merge at all (`grep` for "irreversible" or "class" in `DATA-LAYER.md` returns nothing). §9's own pseudocode (`ALGORITHM-v0.2-pathway-learner.md:242-260`) never writes to lineage on `merge_to_base`. Every other schema-touching addition in this document is explicitly flagged as a delta (e.g. `ALGORITHM-v0.2-pathway-learner.md:501` "DATA-LAYER schema delta ships with this section... four artifacts, all recorded in DATA-LAYER §5"; `:552`, `:605`, `:614` use the identical "delta gated with/under §N" convention throughout §17.6/§18/§20) — clause (ii) is the one schema-touching claim in this document that does *not* follow that convention. As literally written, the guard cannot be run against the current schema; it either needs a declared DATA-LAYER delta or must be narrowed to what clause (i) alone can check.

Secondary: PR-5's rewind-availability claim ("undoable only by checkpoint rewind (§10) at the priced cost of subsequent progress") does not carry forward §10's own qualifier. §10 states checkpoints get "**retention/GC policies (bounded rewind horizon + tagged milestones)**" (`ALGORITHM-v0.2-pathway-learner.md:266`), traceable to RC-4's patch ("tree GC + checkpoint retention (bounded rewind horizon + tagged milestones)", `ALGORITHM-v0.1-redteam.md:53`), and §17.6 confirms GC actually deletes checkpoint *blobs* ("§10's checkpoint retention/GC prunes checkpoint blobs only", `ALGORITHM-v0.2-pathway-learner.md:508`). Nothing in the spec states that a Stage-2 merge's source checkpoint is automatically tagged as a GC-exempt milestone (the only "tagged milestones" mention is the general §10 sentence at line 266 — no cross-reference from §9 or §21). So "undoable... at the priced cost" is accurate only *within* the bounded retention horizon; past it, the merge is not "priced," it is unconditionally irreversible — a stronger claim than PR-5 makes, and the gap is not acknowledged.

### 2. Design faithfulness

The macro-pattern (additive, one declared exception, restating not inventing) is followed faithfully for the PR-5 statement itself — a real improvement over round 1. But clause (ii) of the new guard (§1 above) is itself a design-faithfulness break: §21's preamble (`ALGORITHM-v0.2-pathway-learner.md:651`) states "**No mechanism changes; no new parameters... with one declared exception**: the §21.2 event-indexed decay clause." Requiring Stage-2 merges to be "recorded in lineage as irreversible-class" is a new behavior for §9/§10 that is not established anywhere in §1–§20 — it is a second, undeclared mechanism/schema addition smuggled into a guard-test bullet rather than named as an exception with its own property-impact statement. A section whose entire premise is "this restates what already exists" (line 653: "the properties are the *state*... this section states what is *always true*") should not introduce a new requirement inside its own guard definitions.

### 3. Red-team resistance

RC-8's documentation-level exposure from round 1 is substantively closed: PR-5 no longer over-asserts reversibility for the weight axis, and §21.4's RC-8 entry (`ALGORITHM-v0.2-pathway-learner.md:694`) now correctly states "whose staged form is RC-8's actual patch: irreversibility only behind a passed reversible stage, never in one step" rather than an unqualified reversibility claim. `ALGORITHM-v0.1-redteam.md:67-69` (RC-8: promotion mis-fire bakes an overfit skill irreversibly into weights) is no longer contradicted by the property figure.

However, the clause-(ii) gap (§1/§2 above) reopens a narrower version of the same residual: the entire reason clause (ii) exists is "so no downstream tooling can ever treat a base merge as freely revertible" — i.e., it is *itself* the mechanism meant to close the last sliver of RC-8's documentation risk. Because the schema capability it asserts doesn't exist, a developer or reviewer relying on "conformant to PR-5, per §21.2's guard" as evidence that Stage-2 merges are safely flagged would be trusting a check that cannot currently run. This is a smaller instance of round 1's exact failure mode (a guard cited as closing a gap, without actually being able to).

### 4. Implementability

**Concrete win — the §21.3 enforcement claim is now genuinely wired.** Round 1 flagged this as aspirational text describing a behavior nowhere in the repo. It is now real: `skills/spec-change-gate/SKILL.md:92-101` adds step 4 to the pre-submission checklist, requiring a per-property (PR-1..PR-9) *preserved/strengthened/modified-with-argument* statement, explicitly citing the round-1 presence-vs-truth lesson ("Presence-checking a cited guard's name is not truth-checking the property — the S21 round-1 review caught a property whose cited guards all existed while the property itself was false against §9..."). This is verified present, matches §21.3's description (`ALGORITHM-v0.2-pathway-learner.md:678`) accurately, and closes round-1 required change #4 cleanly.

Clause (i) of the new guard is concretely implementable today (it re-checks an existing conjunction against existing code). Clause (ii) is not implementable without first landing the DATA-LAYER delta it presupposes (§1 above) — a developer attempting to "implement conformance to PR-5" hits the same wall round 1 found, one level deeper: the guard exists on paper but not against the current schema.

### 5. Safety / integrity

No existing gate, calibration layer, or verifier mechanism is weakened; §8/§9/§14/§19 are quoted, not altered. The clause-(ii) gap is not a *weakening* of an existing safety mechanism (nothing regresses) — it is an *unbacked assurance*: the property figure implies a downstream safety property ("no downstream tooling can ever treat a base merge as freely revertible") is already achievable when the schema to achieve it doesn't yet exist. That is a lesser defect than round 1's (which asserted an existing safety property was true when the spec's own text said otherwise); this round asserts a *checkable enforcement mechanism* exists when it doesn't. Scores above the CRITICAL floor (70) but is flagged as the dimension's residual concern.

### 6. Efficiency / cost

Unchanged from round 1 — purely additive documentation/naming layer, no new runtime mechanism or LLM call. The (undeclared) lineage delta implied by clause (ii), if actually built, would be a small, bounded addition (one column or one event kind) — not a complexity concern in itself, but it is currently uncosted/unregistered, which is a completeness gap rather than an efficiency one.

### 7. Completeness

Round 1's five required changes are addressed to varying degrees:
1. PR-5 rewrite — done, option (a), well-executed.
2. Maintained-by correction — done.
3. New guard for §9 Stage-2 — attempted; clause (i) is solid, clause (ii) introduces a new gap (§1 above).
4. Enforcement wired — done, verified against the actual `SKILL.md` content.
5. RC-map re-examination — done; RC-1→PR-3+PR-4 and RC-5→PR-4+decay-clause now carry explicit connective-mechanism sentences (`ALGORITHM-v0.2-pathway-learner.md:687,691`) rather than bare arrows, satisfying round 1's "or add one sentence justifying the indirect connection" option. The connections remain indirect (defensible, not tight) but are now argued rather than asserted.

Net: 4 of 5 required changes are cleanly closed; the 5th (guard for §9 Stage-2) is half-closed and introduces a new, narrower defect in its own definition.

### 8. Consistency

The central new issue: §21.2's clause (ii) (`ALGORITHM-v0.2-pathway-learner.md:674`) is inconsistent with `DATA-LAYER.md`'s actual `lineage` schema (`DATA-LAYER.md:145`) and with this document's own established practice of flagging every schema-touching sentence as a declared delta (contrast `ALGORITHM-v0.2-pathway-learner.md:501,552,605,614` — all of which say "delta gated under/with §N" for far smaller additions than an irreversibility classifier). This is the same defect class `skills/spec-change-gate/SKILL.md:67-101` names as the project's single most common recurring failure ("claiming a fix that was never actually written down consistently... a schema field... asserted as present/registered when it isn't") — ironically recurring inside the very section whose own preamble cites the discipline of naming things precisely (`ALGORITHM-v0.2-pathway-learner.md:651-652`, invoking KIP-595/CockroachDB named-property defense). Elsewhere, the round-2 revision is internally consistent — PR-5's figure text, Maintained-by column, and §21.3's "declared irreversibility, named honestly" bullet (`:681`) all agree with each other and with §9's source text.

### 9. Calibration / honesty

Genuine strengths, carried and extended from round 1: §21.3 gains an explicit "declared irreversibility, named honestly" bullet (`:681`) that states plainly "PR-5 does **not** claim §9 Stage-2 is reversible... A safety-properties section that glossed this would be exactly the false assurance it exists to prevent" — this is real, applied epistemic discipline, and it is why the headline PR-5 defect is fixed. The same discipline is not applied to two smaller items in this round's own new material: (a) the checkpoint-rewind-horizon omission (§1) — the section's own honesty standard (as modeled by §17.6's "narrows... does not close" pattern, `:508`) is not extended to PR-5's rewind clause; (b) clause (ii)'s schema claim is stated as a settled fact ("recorded in lineage... as irreversible-class") rather than flagged as a needed delta, which is a smaller version of the exact "presence vs. truth" gap the round-1 review named and `SKILL.md`'s new checklist step 4 now explicitly warns against.

## Strongest adversarial objection

**The guard written specifically to close round 1's "guard-vs-universal gap" for PR-5 is itself unimplementable against the current schema, and its scope violates §21's own "one declared exception" framing.** §21.2's `test_stage2_merge_gated_behind_reversible_stage1` clause (ii) requires Stage-2 merges to be "recorded in lineage... as irreversible-class" — a capability absent from `DATA-LAYER.md`'s `lineage` schema and never declared as a delta anywhere in this round's changes, unlike every other schema-touching sentence in the same document (§17.6, §18.1, §20.2-20.9 all say "delta gated under §N" for additions smaller than this one). A hostile reader does not need a novel attack surface here either — the guard's own two clauses are directly comparable: clause (i) is grep-verifiable against §9's existing code block; clause (ii) references a field that a `grep` of `DATA-LAYER.md` shows does not exist. Because clause (ii) exists precisely to make PR-5's safety-relevant claim ("no downstream tooling can ever treat a base merge as freely revertible") checkable, its own unimplementability leaves that specific assurance resting on nothing yet built — a narrower recurrence of round 1's defect class, introduced by the very fix meant to close it.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(64, 68, 72) = 64
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (64*2 + 68 + 68*2 + 68 + 72*2 + 95 + 73 + 65 + 68) / 11
                = (128 + 68 + 136 + 68 + 144 + 95 + 73 + 65 + 68) / 11
                = 845 / 11
                = 76.8 → 77
overall         = min(64, 77) = 64
```

**Overall confidence: 64 / 100**

## Verdict

**needs-revision**

Substantial progress from round 1 (35 → 64): the headline defect (PR-5 false against §9) is genuinely fixed, and round-1 required changes #2, #4, and #5 are cleanly closed. Blocking changes required to clear 80 (and the CRITICAL floor of 70 on Correctness, Red-team resistance, and Safety):

1. **Fix the new guard's clause (ii).** Either (a) declare the "irreversible-class" lineage marking as an explicit DATA-LAYER §5 schema delta — following this document's own convention (a new field on `lineage`, or a dedicated `promotion_merged{checkpoint_id, adapter_id, ts}` event kind), gated under §9 or §21 as every other addition in this document is; or (b) narrow the guard to what clause (i) alone establishes (the Stage-1 conjunction gate, which is already implementable and correct) until the schema delta is separately proposed and gated through its own round.
2. **Reconcile clause (ii) with §21's "one declared exception" framing.** If the lineage-classification requirement is a genuine new mechanism (it is — §9 currently writes nothing to lineage on `merge_to_base`), either declare it as a second named exception in the preamble with its own property-impact statement, or remove it from a section whose stated purpose is restating existing invariants, not adding new ones.
3. **Narrow PR-5's checkpoint-rewind clause to acknowledge §10's bounded retention horizon.** E.g., "...undoable only by checkpoint rewind within §10's bounded retention horizon, at the priced cost of subsequent progress — beyond that horizon (checkpoint blob GC'd) the merge is permanently irreversible" — applying the same honesty standard §17.6 already models ("narrows... does not close") to PR-5's own escape hatch.
4. **State explicitly whether a Stage-2 merge's source checkpoint is tagged as a GC-exempt milestone** (§10's "tagged milestones" clause) — this materially changes how strong the rewind-availability claim in PR-5 can honestly be, and is currently unstated in both §9 and §21.

None of these require touching §1–§20's mechanisms beyond the DATA-LAYER delta named in #1(a) if that path is chosen; all are corrections/additions within §21 (and optionally a small, explicitly-gated DATA-LAYER delta), consistent with the section's own additive scope.
