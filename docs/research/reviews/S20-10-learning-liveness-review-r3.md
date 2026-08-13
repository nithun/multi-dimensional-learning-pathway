# 360 Review: S20-10-learning-liveness — 2026-08-13 (round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20.10 "Learning liveness — detecting absence, not just harm" (lines 647-669), plus its §12 parameter registration (line 286) |
| Proposed change (this round) | Revision responses to round-2's two blockers: (1) rebuild the absorbed-failure-rate derivability argument as three graded steps, each independently grounded in truth structure, replacing the single "necessity, not assertion" framing; (2) fix the preamble's parameter-count drift (three → four, matching §12) |
| Round 1 | `docs/research/reviews/S20-10-learning-liveness-review.md` — 70/100, needs-revision |
| Round 2 | `docs/research/reviews/S20-10-learning-liveness-review-r2.md` — 76/100, needs-revision |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Proceeding as a normal (committable) review, not a proposal.

## Scope note

Per instruction, `docs/research/DATA-LAYER.md`'s §6.3 delta and `docs/research/IMPL-PROTOCOL.md` remain out of scope, as in rounds 1-2. DATA-LAYER is read at its state through the approved §6.1/§6.2/§12 content.

## Dimension scores

| # | Dimension | Score | Status | Δ vs round 2 |
|---|---|---|---|---|
| 1 | Correctness (CRITICAL) | 66 | weak | −10 |
| 2 | Design faithfulness | 86 | pass | −6 |
| 3 | Red-team resistance (CRITICAL) | 80 | pass | −6 |
| 4 | Implementability | 78 | weak | −7 |
| 5 | Safety / integrity (CRITICAL) | 88 | pass | −3 |
| 6 | Efficiency / cost | 85 | pass | 0 |
| 7 | Completeness | 78 | weak | −4 |
| 8 | Consistency | 78 | weak | −2 |
| 9 | Calibration / honesty | 55 | weak | −21 |

## Findings by dimension

### 1. Correctness

This round's brief asked for one specific adversarial act: verify step (iii)'s control-flow reading against §5.1's actual pseudocode, and verify step (ii) against §6.1's record-type text. Doing exactly that produces a split result — one step holds, the other does not.

**Step (iii) — genuinely correct, independently verified.** §5.1 (ALGORITHM-v0.2-pathway-learner.md:119-122):
```
for traj in child.failures:
    s* = nearest_admitted_skill(traj)
    if coherent_with(traj, s*.success_items):  attribute(traj, s*)
    else:                                       F.add(embed(traj))      # outlier → candidate split
```
This is genuinely single-path: the `if` branch is the only route to a cell (`attribute(traj, s*)`); the `else` branch sends the trace to `F` (the clustering buffer feeding `new_skill`/`provision_suite`) and never touches a cell. §20.10's claim (line 659) — "attribution has exactly one path... so every cell-consumed failure trace passed `coherent_with` by construction. No claim is made about which branch *would* have fired counterfactually — only which did" — is an accurate description of this code. This is a clean, load-bearing verification: no defect found.

**Step (ii) — does not hold on inspection; the claimed "record-type distinction truth already carries" is not established by the cited text.** §20.10 line 659 states: "*absorbed vs direct* is a **record-type** distinction truth already carries — §6.1's identity hash begins `record_type ‖ …`, and failure **traces** and eval **results** are distinct record types in §6.1's own enumeration — so the absorbed-failure rate is defined as the cell's consumed failure-**trace** records relative to its eval volume, no new field." Checking each part of this against DATA-LAYER.md:

- The identity-hash formula is quoted correctly: `id = hash( record_type ‖ semantic_payload ‖ occurrence_provenance )` (DATA-LAYER.md:173).
- The "enumeration" cited is DATA-LAYER.md:170: "Every record that can move a posterior — eval results, failure traces, lessons, skill artifacts — carries an identity hash..." This is real text, not a fabricated citation. But it is **scope-setting prose for the identity-hashing requirement**, not a schema definition. It names four illustrative *categories* of records that would be identity-hashed *if* they exist and move a posterior — it does not declare "failure trace" as an actual table, event kind, or `record_type` value anywhere concrete.
- The actual schema enumeration — DATA-LAYER.md:146, §5's full table/event-kind list — contains no `failure_trace` table or event kind at all: `events`, `evals`, `lineage`, `work_unit_opened`, `dispatch`, `scaffold_versions`, plus administrative event kinds `selfmod_rejected`, `component_invoked`, `rejected_ingest`, `work_unit_closed`, `trace`/`score`, `conformance_report`/`conformance_manifest`, `constraint_flag`/`constraint_table`. Nothing named "failure trace" is defined with a `skill` (or any cell-attributing) field the way `evals` carries `skill` directly (DATA-LAYER.md:146).
- Worse, the schema's only entity literally named **`trace`** (DATA-LAYER.md:146, the `trace{correlation_id, kind ∈ dispatch|span|cycle|delivery, payload, ts}` event kind, §11) is the **opposite** of what step (ii) needs: it is explicitly on §6.1's administrative-exemption list and DATA-LAYER.md:189 states plainly it "**move[s] no posterior**." A reader following §20.10's citation to "failure traces... distinct record types" could easily land on this schema entity by name association; it cannot supply the signal at all, since the whole premise of the absorbed-rate check is that the underlying record *did* move a posterior.
- There is a genuine, unresolved tension inside DATA-LAYER.md itself that §20.10 papers over rather than resolves: line 170 lists "failure traces" among records that "**can** move a posterior," while line 189 states "StateStore Beta updates key only off **eval/outcome** records" — DATA-LAYER.md never defines whether a `coherent_with`-absorbed failure attribution (§5.1's `attribute(traj, s*)`) is itself an "eval/outcome record," a distinct persisted record class with its own schema entry (not present in §5's table), or something that updates no Beta posterior at all (in which case it would not appear in `rebuild_state`'s replay — DATA-LAYER.md:160, "replay evals → recompute Beta posteriors," which names only `evals`, not any failure-trace table). §20.10 cites this ambiguous, self-tensioned text as though it settles a question it does not settle.

**Net assessment.** Round 2's blocking item 1 (absorbed-failure-rate ↔ `coherent_with` linkage) is **not closed this round** — it is re-argued with a citation that, checked directly against its source per this round's own brief, does not establish the claim it is offered for. `test_absorbed_rate_derivable_from_evidence_keys` (line 668, "splitting by the §6.1 `record_type` — failure traces vs eval results") remains unwritable as specified: there is no concrete field or table to split on. This is the same substantive gap identified in round 1 (Correctness finding 2) and round 2 (Correctness finding, "the load-bearing layer... is still not shown"), now in its third form, and — unlike round 2's version, which was honestly hedged ("implied by proximity to the now-solid argument next to it") — this round's version is stated with **higher, not lower, confidence** ("a record-type distinction truth already carries," "no new field") while remaining just as unsupported. That is a regression, not an improvement, on the specific claim this round targeted for repair.

Scored below round 2 (66 vs 76) because: (a) the flagship unresolved claim from rounds 1-2 is still unresolved, now presented as resolved; (b) that presentation is itself a new, distinct defect (a citation that does not support what it is cited for — the same defect class as round 1's §5.2 mis-citation); (c) step (iii)'s clean verification and the parameter-count fix are real, partial credit, but do not offset (a)/(b) given how consequential state 3 is stated to be within the section's own text (line 664: "the one state where 'everything is green' is itself the finding").

**Fix confirmed clean: parameter-count drift.** The preamble (line 649) now reads "four parameters registered in §12 (`w_live`, `τ_pin`, `τ_absorb`, `n_absorb`...)" — matching §12's registration exactly (line 286: "`w_live`... `τ_pin`... `τ_absorb`... `n_absorb` (consecutive-evaluation debounce on the `τ_absorb` alert, default 3)") and the body's own use of `n_absorb` (line 659). Grep-verified, no drift. Clean, mechanical, fully resolved.

### 2. Design faithfulness

The architectural placement, ownership, and reuse discipline (§17.6-under-§17 precedent, JUDGE-side ownership, reuse of `significant()`/`k`/`θ`, mapping onto §20.7's delivery taxonomy) is unchanged from round 2 and still holds — no regression there. Docked from round 2's 92 to 86 for the same reason the round-1 §5.2 mis-citation was docked here: citing a source as establishing a distinction it does not establish is a design-faithfulness lapse (borrowing more architectural authority than the cited section actually grants), and this round's step (ii) repeats that pattern against §6.1 rather than §5.2.

### 3. Red-team resistance

Re-checked against `docs/research/ALGORITHM-v0.1-redteam.md`'s eight root causes; none is newly reopened:

- **RC-4** (wrong-cell absorption, add-only ratchet, redteam.md:51): still honestly framed as visibility-only, not a fix — the section does not claim to close the residual. But the Correctness finding above means state 3's value as an RC-4 mitigation is, if anything, **less** demonstrated than round 2 found, while being described with more certainty. A mitigation an operator is invited to trust, that has a meaningful chance of either never firing correctly or firing on a substitute quantity, is a soft residual-attack-surface concern in its own right — not a reopened RC, but a real regression from round 2's posture on this specific point.
- **RC-1/2/3/5/6/7/8**: unchanged; not applicable or correctly aligned, same as rounds 1-2.
- The round-2 debounce fix (`n_absorb`) remains in place and unaffected by this round's changes (line 659, `test_absorb_alert_debounced` at line 668) — that closed concern stays closed.

Docked from round 2's 86 to 80: not for reopening a root cause, but because the section's own single flagship always-delivered alert (state 3) is now described with confidence its derivation does not support, which is exactly the kind of gap between "looks armed" and "is armed" that this section exists to detect elsewhere in the system.

### 4. Implementability

The two round-2-closed gaps (debounce, degenerate-floor-set precondition) remain closed and unaffected this round. The previously-flagged, still-open, non-blocking gap (no stated algorithm for the structure signal's growth-event tally) is unchanged and out of this round's stated scope. Docked from round 2's 85 to 78 because `test_absorbed_rate_derivable_from_evidence_keys` is, after three rounds, still not implementable as named — a developer given this round's text would still have no concrete field or table to query, and the new "three graded steps" framing, unlike the honest-narrowing fix applied to the structure signal, gives no fallback instruction for what to build if the cited grounding turns out (as it does) not to hold.

### 5. Safety / integrity

Core safety posture unchanged and clean: `test_no_signal_touches_selection_or_gates` (line 668) still asserts bit-identical `π`/§8/§19/tier outcomes; §14/§19.6 breakers untouched (line 666); no calibration-layer or verifier interaction. Docked slightly from round 2's 91 to 88 — not for a weakened gate (none exists), but for the same soft alarm-integrity concern flagged in dimension 3: an always-delivered alert whose triggering condition is not demonstrably computable as specified is a soft precursor to false operator confidence, which is a safety-adjacent (not safety-gating) concern in an unattended-operation context, same category as round 1's original alarm-fatigue dock, now recurring in a different guise.

### 6. Efficiency / cost

Unchanged. All three signals remain cold-path, computed at the cycle digest (line 659), no new LLM calls, no complexity change from this round's edits. Held at 85.

### 7. Completeness

The two gaps round 2 closed (empty coverage-floor-set precondition, `τ_absorb` debounce) remain closed. The gap round 2 called "half-closed" — no concrete test strategy for the absorbed-rate derivation — is, per the Correctness finding, **still open**, and the new prose makes it read as closed when it is not, which is itself a completeness regression (a gap disguised as resolved is harder for a downstream implementer or reviewer to catch than a gap left visibly open). Docked from round 2's 82 to 78.

### 8. Consistency

**One round-2 defect is cleanly fixed:** the parameter-count drift (preamble said "three," §12 registered four) is resolved — the preamble now says "four" and names all four parameters, matching §12 (line 286) and the body (line 659) exactly. No drift found by direct comparison.

**A comparable-class defect reappears in a different place:** §20.10's claim about §6.1's "record-type" enumeration (line 659) is inconsistent with what DATA-LAYER.md's own schema (§5, line 146) and its own internal scoping text (§6.1, line 189) actually establish — the same *self-contradiction-with-cited-source* failure class flagged in round 1 (Correctness finding 1 / Consistency finding, the §5.2 mis-citation) and explicitly the kind of pre-submission defect `skills/spec-change-gate/SKILL.md`'s checklist exists to catch. Net movement: the closed parameter-count drift is offset by this reopened-in-kind (though not identical) consistency defect. Docked slightly from round 2's 80 to 78.

### 9. Calibration / honesty

This is where the round's net effect is worst. Two things pull in opposite directions, and the round's own framing states the negative one is resolved when it is not:

**What round 2 asked for, restated by the caller's brief for this round:** "the 'necessity, not assertion' framing for the whole chain is gone; each step now carries its own distinct grounding." Checked against the actual text: steps (i) and (iii) *are* independently grounded and verified correct in this review (Correctness above). Step (ii) is **not** independently grounded — it borrows confidence from a citation (§6.1's prose enumeration) that does not establish the claim, and states the result with *more* certainty than round 2's plainer, already-flagged-as-overconfident wording ("necessity, not assertion") did. Where round 2's Calibration finding said the prior wording was "a harder overclaim to catch on a skim... a reader... would come away more confident... than the base spec actually supports," this round's revision does not fix that — it sharpens the same effect by adding specific-sounding technical language (`record_type ‖ …`, "no new field," "distinct record types in §6.1's own enumeration") that reads as a settled implementation detail rather than the unresolved question it still is.

**What genuinely improved and should be credited:** the structure signal's "Honest scope" clause (line 657, unchanged from round 2, still correctly narrowing the claim to match the schema and naming ONT-6 as the undelivered distinction) remains a real, well-executed calibration example — precisely the discipline this round's step (ii) needed and did not apply.

Scored well below round 2 (55 vs 76): this round had one job on the calibration axis — reduce the gap between stated confidence and actual evidentiary support for the section's single most consequential claim — and, on direct verification, widened it instead while explicitly claiming to have closed it.

## Strongest adversarial objection

Across three rounds, the same objection has now survived three distinct forms of the same underlying claim, each time re-clothed rather than resolved: round 1 asserted absorbed-rate derivability outright; round 2 argued it "by necessity" and, on adversarial re-derivation, was shown to prove a narrower claim than advertised; round 3 restructures the argument into three discrete steps specifically to answer that finding, and this round's own adversarial check (run exactly as the brief requested) finds the same gap survives inside step (ii), now wearing the most concrete-sounding language of the three rounds ("§6.1's identity hash begins `record_type ‖ …`," "distinct record types," "no new field"). **The pattern itself is the finding:** each round narrows the rhetorical distance between the claim and its citation without closing the substantive distance between the claim and what the cited text actually establishes, and each narrowing makes the gap harder to see on a skim, not easier. A section whose founding purpose (line 649, 651) is to catch mechanisms that look wired but are not is, on its third revision, still asking its reviewer to catch exactly that failure inside its own flagship alert — and the fact that this review's specific brief ("adversarially verify... against §5.1's actual pseudocode... against §6.1's record-type text") was required to surface it, rather than a plain read of the prose, is itself evidence that the confident framing is doing real persuasive work independent of the underlying evidence. If a fourth round repeats this pattern — a still-more-specific-sounding argument for the same unclosed claim — that should be treated as a signal to stop iterating on the wording and instead force the honest-narrowing move (state 3 computes ordinary within-skill failure rate, not an absorption-specific rate, until DATA-LAYER names the missing field) rather than attempting a fourth reformulation of the same unsupported claim.

## Aggregate confidence

```
critical_floor  = min(66, 80, 88) = 66
weighted_mean   = (66*2 + 86 + 80*2 + 78 + 88*2 + 85 + 78 + 78 + 55) / 11
                = (132 + 86 + 160 + 78 + 176 + 85 + 78 + 78 + 55) / 11
                = 928 / 11
                = 84.36 → 84
overall         = min(66, 84) = 66
```

**Overall confidence: 66 / 100**

## Verdict

**needs-revision**

Overall confidence (66) is below the 80 bar, and Correctness (66, CRITICAL) is below the 70 threshold that independently trips the CRITICAL-dimension rule — this round fails on both triggers, where round 2 failed on only the aggregate-score trigger. This is a regression from round 2 (76 → 66), driven entirely by the adversarial verification this round's brief specifically requested on step (ii).

Blocking changes required to clear 80 (superseding round 2's item 1 and item 3, which this round's revision did not actually resolve despite addressing them):

1. **Resolve the absorbed-failure-rate ↔ `coherent_with`-absorption linkage for real, this time against a concrete schema location — not a further-reworded derivability argument.** Either (a) add (or point to an already-existing but uncited) concrete field/table in DATA-LAYER §5/§6.1 that records, per skill/cell, whether a given posterior-moving failure record arrived via `attribute(traj, s*)` (the `coherent_with` path) as opposed to a natively-targeted eval failure — and resolve the DATA-LAYER.md:170-vs-189 tension (which record classes actually move a posterior) explicitly as part of that fix; or (b) apply the same honest-narrowing move already proven to work for the structure signal (line 657): state plainly that the absorbed-failure-rate as specified computes ordinary within-skill failure rate, not an absorption-path-specific rate, rename/re-describe `test_absorbed_rate_derivable_from_evidence_keys` accordingly, and rewrite the Vulcan-pattern narrative (line 664) to match what is actually computable. A fourth round proposing a fourth version of the same unresolved derivability argument should not be treated as further progress.
2. **Do not present step (ii) as resolved until it is.** Whichever of (1)(a)/(1)(b) is chosen, state the section's confidence level in proportion to what is actually shown — the current "no new field" / "record-type distinction truth already carries" language should not survive into the next round unless a concrete field is named and verified.

Not blocking, confirmed genuinely resolved this round and should not be reopened without new evidence: the parameter-count drift (fix 2), the structure-signal honest-scope narrowing (round 2's fix, unchanged and re-verified here), the `τ_absorb` debounce (round 2's fix, unchanged), the empty-coverage-floor-set precondition (round 2's fix, unchanged), and step (iii)'s single-path control-flow claim (verified correct against §5.1's pseudocode this round).

Not blocking, carried forward as still-open (recommended, not required): name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's growth-event tally; distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test.
