# 360 Review: S21-safety-properties — 2026-08-13 (round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §21 "Safety properties — what is always true" (lines 649–698, uncommitted working-tree revision, round 3) |
| Proposed change | Revision responding to round 2's two required changes: (1) clause (ii) of `test_stage2_merge_gated_behind_reversible_stage1` (§21.2, line 674) now cites the **existing** ArtifactStore `registry` field `stage: probation\|merged` (DATA-LAYER §5) instead of the previously-invented `lineage` "irreversible-class" marker — declared "no new field, no schema delta," with an in-artifact honesty note that round 2 caught the first draft inventing a field (the L-013 class); (2) PR-5's rewind clause (§21.1, line 663) now carries §10's bounded retention horizon explicitly — rewind is available only within it, and the merge is "unconditionally irreversible" past checkpoint-blob GC — mirrored in the §21.3 honesty bullet (line 681). |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Round-1/2 disposition (for reference)

Round 1: 35/100, needs-revision — PR-5 flatly contradicted §9's own text. Round 2: 64/100, needs-revision — the contradiction was fixed, but the new guard's clause (ii) invented a nonexistent `lineage` schema field. This round re-scores fresh per the reviewing brief's instruction.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 86 | pass |
| 2 | Design faithfulness | 75 | weak |
| 3 | Red-team resistance (CRITICAL) | 85 | pass |
| 4 | Implementability | 81 | pass |
| 5 | Safety / integrity (CRITICAL) | 83 | pass |
| 6 | Efficiency / cost | 95 | pass |
| 7 | Completeness | 74 | weak |
| 8 | Consistency | 75 | weak |
| 9 | Calibration / honesty | 78 | weak |

## Findings by dimension

### 1. Correctness

**Round 2's blocking-adjacent finding is genuinely fixed, and verified against the actual schema, not just the artifact's own claim.** `DATA-LAYER.md:150` — `registry{ckpt_id, base, adapter, dataset_id, metrics, parent, stage: probation|merged, created_ts}` — confirms the field cited by §21.2 clause (ii) (`ALGORITHM-v0.2-pathway-learner.md:674`) genuinely exists with exactly the two enum values the clause requires, and `DATA-LAYER.md:91` — `def register(self, ckpt_id: str, lineage: Lineage, metrics: dict, stage: str) -> None: ...` — confirms `ArtifactStore` already exposes a `stage`-setting write path. A `grep` for "class" or "irreversible" against `DATA-LAYER.md` (round 2's failure mode) is moot this round because the cited field is real, not invented. This is a real, evidence-backed fix, not a narrative claim.

**The rewind-horizon addition to PR-5 is also correct and well-sourced.** `ALGORITHM-v0.2-pathway-learner.md:663` now reads "...and only within §10's bounded retention horizon: past checkpoint-blob GC, the merge is unconditionally irreversible" — this matches `ALGORITHM-v0.2-pathway-learner.md:266` ("Checkpoints and the tree get retention/GC policies (bounded rewind horizon + tagged milestones)") and is consistent with the "blobs prunable, rows permanent" discipline stated identically elsewhere (`ALGORITHM-v0.2-pathway-learner.md:507`: "§10's checkpoint retention/GC prunes checkpoint *blobs* only — lineage *rows*... are permanent"). This closes round 2's required change #3 cleanly, and does so by strengthening the claim's honesty rather than its scope (it narrows what "undoable...at the priced cost" can honestly promise, exactly the standard §17.6 already models at line 508).

**Residual, non-blocking correctness note — the preamble's own property-impact self-audit is imprecise for PR-5.** The preamble (`ALGORITHM-v0.2-pathway-learner.md:651`) states the section's exception rule as: "**No mechanism changes... with one declared exception:** the §21.2 event-indexed decay clause is a normative conformance clarification (it resolves §5.1's unstated `decay_edges` clock)... **PR-7 strengthened; PR-1–PR-6, PR-8, PR-9 preserved (untouched).**" But §21.2 clause (ii) (line 674) is structurally the same move as the decay clause: it resolves an ambiguity §9 never states (that `merge_to_base` writes `registry.stage`) and mandates it as a conformance requirement ("every Stage-2 merge flips... `stage: probation → merged`"). Nothing in §9's own text (`ALGORITHM-v0.2-pathway-learner.md:242-260`) or in DATA-LAYER's generic registry description (`DATA-LAYER.md:150`) previously stated that `merge_to_base` performs this write — it is new normative content introduced by §21 itself, the same shape of thing the preamble flags for the decay clause but not for this one. Labeling PR-5 as merely "preserved (untouched)" alongside PR-1–PR-4/PR-6/PR-8/PR-9 is therefore an overclaim of settledness. This is meaningfully softer than round 1's defect (PR-5's *content* is accurate against source text) and softer than round 2's (no nonexistent field is invoked; the field's enum values — `probation`/`merged` — make the Stage-1/Stage-2 correspondence close to unambiguous, unlike the genuinely two-way-plausible decay-clock question), so it does not reach blocking severity, but it is a real, precisely-locatable claim that does not hold up on a literal reading. Scored in the high-80s rather than higher for this reason; treated primarily as a Design Faithfulness / Consistency / Calibration matter below rather than double-counted heavily here.

### 2. Design faithfulness

The macro-pattern (additive; a declared-exception discipline modeled on KIP-595/CockroachDB naming-and-defending deviations) is followed faithfully for the decay clause, and PR-5's own content now matches §9/§10 closely. The gap is the one named in §1: §21.2 clause (ii) performs the same kind of move the section itself elevates to "declared exception" status for PR-7, without extending that treatment to PR-5. The section's entire premise (line 653, "this section states what is *always true*," restating §1–§20 rather than adding to it) is best served by naming *every* ambiguity-resolving clause the same way, not just the first one encountered. This is a real, if modest, faithfulness gap — not a reintroduction of round 1/2's defects, but the same underlying discipline (declare precisely, don't let a clarifying requirement hide inside a guard bullet) applied inconsistently within the same section.

### 3. Red-team resistance

RC-8's documentation-level exposure (round 1) remains closed: PR-5 does not over-claim reversibility, the `RC-8 → PR-5` map entry (`ALGORITHM-v0.2-pathway-learner.md:694`) states the correct staged-form patch, and this round's changes only narrow and correctly bound the claim further (the retention-horizon addition, if anything, closes a residual sliver of RC-8's risk — a future reader can no longer read PR-5 as implying indefinite rewind availability). The clause-(ii) registry-flip requirement, now grounded in a real field, is itself a red-team-positive addition: it makes irreversibility legible to downstream tooling rather than merely asserting it in prose. No root cause from `ALGORITHM-v0.1-redteam.md` is reintroduced or newly exposed. The residual finding in §1/§2 (undeclared second clarification) is a documentation-precision issue, not an attack surface — it does not create a path by which a future change could cite PR-5 for something false, since PR-5's actual content is accurate.

### 4. Implementability

**Both guard clauses are now concretely implementable against the current schema — this closes round 2's Implementability gap.** Clause (i) (`sustained_heldout ∧ human_spotcheck ∧ no_cum_regression(MONITORED)`, `ALGORITHM-v0.2-pathway-learner.md:674`) matches `ALGORITHM-v0.2-pathway-learner.md:253` verbatim and was already implementable. Clause (ii) now targets a real field (`registry.stage`) with a real write path (`ArtifactStore.register(..., stage: str)`, `DATA-LAYER.md:91`) — a developer can write `test_stage2_merge_gated_behind_reversible_stage1` today without first landing a schema delta, unlike round 2's version.

Minor residual gap: the property text specifies the Stage-2 *end* of the transition ("flips... `probation → merged`") but does not explicitly state that `train_LoRA` (Stage 1) is what sets `stage: probation` in the first place — a developer implementing the guard needs to infer the Stage-1 write from the enum's existence rather than from an explicit statement in §9 or §21. Small, easily closed, not blocking.

The §21.3 enforcement claim (verified present and accurate in round 2 — `skills/spec-change-gate/SKILL.md:92-101`) is unchanged this round and remains correctly wired.

### 5. Safety / integrity

No existing gate, the §14 calibration layer, the §19 self-calibrating gate, or the verifier is weakened; §8/§9/§14/§19 are quoted, not altered, this round exactly as in round 2. The clause-(ii) fix directly improves this dimension relative to round 2: round 2's concern was an *unbacked assurance* (a downstream-tooling-legibility claim resting on a schema capability that didn't exist); that gap is now closed with a real, existing field. The residual finding (§1/§2) is not a safety-integrity concern in the sense the rubric tests ("does the change weaken any gate/calibration/verifier/integrity constraint") — nothing regresses, and the registry-flip requirement is itself a modest safety-positive addition (irreversibility becomes machine-legible, not just narrated). Scored above the round-2 level to reflect the closed gap, with a few points held back because the requirement that `merge_to_base` actually performs the write is still asserted as a to-be-implemented normative requirement rather than shown already wired — consistent with this document's usual level of abstraction (comparable status-flip requirements elsewhere, e.g. `ALGORITHM-v0.2-pathway-learner.md:508`, are stated the same way), so this is not treated as a special weakness of this section specifically.

### 6. Efficiency / cost

Unchanged from rounds 1–2 — purely additive documentation/naming layer, no new runtime mechanism or LLM call. The clause-(ii) requirement, if implemented, is a single field write on an already-open registry row at merge time — no measurable cost.

### 7. Completeness

Round 2's required changes, assessed against this round's actual text:

1. **Fix clause (ii)'s schema claim** (declare a delta, or narrow to clause (i) alone) — **addressed via a third path**: neither offered option was taken; instead the clause was re-grounded in a pre-existing field, which resolves the "does this field exist" half of round 2's concern cleanly (§1 above) but leaves the "should this be a declared exception" half of the concern (round 2's required change #2, below) not fully closed.
2. **Reconcile clause (ii) with §21's "one declared exception" framing** — **not done.** The preamble still names only the decay clause as an exception and still buckets PR-5 under "preserved (untouched)" (§1/§2 above). This is the one round-2 required change genuinely left open.
3. **Narrow PR-5's rewind clause to acknowledge §10's bounded retention horizon** — **done, well-executed** (§1 above).
4. **State explicitly whether a Stage-2 merge's source checkpoint is tagged as a GC-exempt milestone** — **not explicitly answered**, but sidestepped defensibly: rather than assert an unestablished fact (that merge-source checkpoints are milestone-tagged), the revision states the honest pessimistic bound instead ("unconditionally irreversible" past GC, full stop). This is a reasonable substitute for a direct answer, though it does not literally satisfy what was asked.

Net: 2 of 4 required changes cleanly closed (#1 substantively, #3 fully); #2 is the one still genuinely open; #4 is answered in spirit but not in the letter requested.

### 8. Consistency

The one remaining internal-consistency issue is the same one named in §1/§2/§7: the preamble's self-audit (`ALGORITHM-v0.2-pathway-learner.md:651`, "PR-1–PR-6... preserved (untouched)") is in tension with §21.2's own clause (ii), which is a normative clarification for PR-5's maintaining mechanism of the same *kind* the preamble elsewhere calls out as an exception. Everything else checked this round is internally consistent: the PR-5 row (line 663), the Maintained-by column, the §21.3 "declared irreversibility, named honestly" bullet (line 681), and the §21.4 RC-map entry (line 694) all agree with each other and with `DATA-LAYER.md:150`/`ALGORITHM-v0.2-pathway-learner.md:266,507` — a real improvement over round 2, where the guard clause contradicted the schema outright.

### 9. Calibration / honesty

Genuine strengths, carried forward and extended: the in-artifact note that round 2 caught the first draft of clause (ii) inventing a field (`ALGORITHM-v0.2-pathway-learner.md:674`, "the L-013 class, in the section written to prevent it; the recurrence is recorded here deliberately") is verified accurate — `L-013` is a real, standing lesson (`.claude/memory/lessons.md:37`) about exactly this defect class, and citing it by name against one's own prior draft is real, applied epistemic discipline. The rewind-horizon honesty addition (§1) is likewise a genuine strengthening of an already-honest claim.

The calibration gap is the same one flagged throughout: labeling PR-5 "preserved (untouched)" in the preamble's own property-impact statement is a modest overclaim of settledness, and it is the same *shape* of gap the project's own `L-013`/`skills/spec-change-gate/SKILL.md:96-101` checklist step 4 exists to catch ("presence-checking... is not truth-checking") — here turned reflexively on the property-impact statement's own accuracy rather than on a guard's cited name. It is materially smaller than what it replaces (round 1's false property claim, round 2's nonexistent-field claim) but is a recognizable instance of the same recurring pattern in this specific artifact's history.

## Strongest adversarial objection

**The property-impact self-audit in §21's own preamble is itself imprecise about PR-5, in the same document whose stated purpose is precision about exactly this kind of claim.** §21.2 clause (ii) resolves an ambiguity in §9's text ("does `merge_to_base` write to the registry, and with what value?") the same way the decay clause resolves an ambiguity in §5.1's text ("what clock does `decay_edges` use?") — both are conformance-clarifying normative content introduced by §21 itself, not restatements of something §1–§20 already states. The preamble declares the decay clause an exception with its own property-impact line ("PR-7 strengthened") but buckets the structurally identical registry-flip clarification under "PR-1–PR-6... preserved (untouched)." A hostile reader does not need a novel attack surface to find this — the preamble's own stated test ("no mechanism changes... with one declared exception") is directly falsifiable by reading the very next subsection. This is a real, well-evidenced finding, but it is meaningfully weaker than the two prior rounds' headline defects: PR-5's actual content is accurate against §9/§10/DATA-LAYER §5 (verified independently, §1 above), the cited field genuinely exists with matching semantics, and the correspondence between the field's own enum names (`probation`/`merged`) and §9's two stages is close to unambiguous — unlike the decay clock, where wall-clock-vs-event-indexed were two live, materially different interpretations. So this is a self-consistency precision gap in the artifact's own bookkeeping, not a claim that misleads a future reader about what is actually true or safe.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(86, 85, 83) = 83
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (86*2 + 75 + 85*2 + 81 + 83*2 + 95 + 74 + 75 + 78) / 11
                = (172 + 75 + 170 + 81 + 166 + 95 + 74 + 75 + 78) / 11
                = 986 / 11
                = 89.6 → 90
overall         = min(83, 90) = 83
```

**Overall confidence: 83 / 100**

## Verdict

**ready-for-approval**

Substantial, verified progress from round 2 (64 → 83): both of round 2's schema/reversibility findings are genuinely closed against source text, not merely asserted closed. One non-blocking finding remains and is recommended — not required — for tightening before or alongside `change-approver`'s decision:

- **Recommended, non-blocking:** either (a) add the §21.2 registry-flip clarification as a second named item in the preamble's exception list, with its own one-line property-impact statement ("PR-5: registry-legibility clarification — irreversibility becomes machine-checkable, not newly true"), replacing PR-5's current bucketing under "preserved (untouched)"; or (b) if the authors judge the field's own naming makes the correspondence non-ambiguous enough not to need exception-level treatment (a defensible position — see the adversarial-objection section), state that judgment explicitly in §21.3 rather than leaving it implicit. Either resolves the one open item from round 2's required change #2 without requiring another full review round, since it does not change any scored dimension's substance — only the preamble's self-description of its own scope.

This recommendation is not a blocking condition under the stated formula (overall 83 ≥ 80, all three CRITICAL dimensions — Correctness 86, Red-team resistance 85, Safety/integrity 83 — clear 70), and per this agent's INVARIANTS the approval decision itself belongs to `change-approver`, not to this report.
