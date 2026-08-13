# 360 Review: S20-10-learning-liveness — 2026-08-13 (round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20.10 "Learning liveness — detecting absence, not just harm" (lines 647-669), plus its §12 parameter registration (line 286) |
| Proposed change (this round) | Revision responses to round-1 findings: (1) fix the §5.2 mis-citation for the structure signal's edge-renewal count, honestly narrowing the claim to "counts renewals without cause"; (2) argue absorbed-failure-rate truth-derivability by necessity (PR-7) rather than assertion; (3) debounce the standalone `τ_absorb` alert with a new `n_absorb` parameter; (4) add an empty-coverage-floor-set precondition so cold start reports not-applicable, not Converged |
| Round 1 | `docs/research/reviews/S20-10-learning-liveness-review.md` — 70/100, needs-revision |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Proceeding as a normal (committable) review, not a proposal.

## Scope note

Per instruction, the working tree's separate `docs/research/DATA-LAYER.md` §6.3 delta and the untracked `docs/research/IMPL-PROTOCOL.md` remain out of scope for this review, exactly as in round 1. DATA-LAYER is read at its state through the approved §6.1/§6.2 (`▣ APPROVED`) content; §6.3 is in its own separate review track.

## Dimension scores

| # | Dimension | Score | Status | Δ vs round 1 |
|---|---|---|---|---|
| 1 | Correctness (CRITICAL) | 76 | weak | +6 |
| 2 | Design faithfulness | 92 | pass | +4 |
| 3 | Red-team resistance (CRITICAL) | 86 | pass | +6 |
| 4 | Implementability | 85 | pass | +7 |
| 5 | Safety / integrity (CRITICAL) | 91 | pass | +3 |
| 6 | Efficiency / cost | 85 | pass | 0 |
| 7 | Completeness | 82 | pass | +14 |
| 8 | Consistency | 80 | pass | +6 |
| 9 | Calibration / honesty | 76 | weak | −4 |

## Findings by dimension

### 1. Correctness

Two things were checked this round: the mis-citation fix, and — per this round's explicit brief — an adversarial re-derivation of the new PR-7 necessity argument.

**Fix 1 (structure signal, §5.2 mis-citation) — fully resolved, verified against ground truth.** §20.10 line 657 now reads: "edge-confidence renewals (§5.1 `g.decay_edges`' renewal path, visible in truth as `GraphDelta.edge_updates` entries, DL §6.2). **Honest scope:** the schema carries no *cause* field on an edge update, so this signal counts renewals without distinguishing intervention-driven from other renewal evidence..." I verified each cited fact directly:
- §5.1 line 133: `g.decay_edges() # prereq-edge confidence decays unless intervention evidence renews it` — the renewal comment is exactly here, correctly cited this round (not §5.2, as round 1 found).
- DATA-LAYER.md §6.2 line 223: `edge_updates: [(edge_id, confidence)], # g.decay_edges / renewal` — confirms the field, and confirms it carries no `cause`/type column (the tuple is `(edge_id, confidence)` only).
- The "ONT-6" citation for the undelivered causal distinction is not invented: `docs/research/STUDY-ontologies-for-mdlp.md:167` — "**ONT-6 — name the causal story and benchmark it.** State that edge confidence is an interventionally-maintained causal belief (`decay_edges` renewal + `q_edge`...)" — a real, already-scoped future-work item, correctly used as the boundary marker rather than as a fabricated authority.
This is a clean fix: the section no longer claims a distinction the schema cannot support, and the new test `test_structure_signal_counts_renewals_without_cause` (line 668) matches the narrowed claim exactly.

**Fix 2 (absorbed-failure-rate ↔ `coherent_with` linkage) — argued more rigorously, but the adversarial pass finds the core gap is narrowed, not closed.** The new text (line 659): "a failure record's attributed cell is whatever cell's posterior consumed it (§6.1's evidence-keyed updates) — and that attribution **must** be reconstructible from truth, because `rebuild_state` (DL §6) reproduces every posterior from truth alone (PR-7); the absorbed-rate computation reads exactly what rebuild reads, no more. A deployment in which rebuild works and this rate is uncomputable is a contradiction."

Taking the brief's instruction seriously ("is it actually sound, or does `rebuild_state` reproduce posteriors without exposing per-record attribution — aggregate replay?"):

- The **first half** of the necessity argument is sound and I can independently verify it, not merely accept it on faith. `rebuild_state(truth, state)` (DATA-LAYER.md:160) is annotated "replay evals → recompute Beta posteriors" — replay, not aggregate-and-collapse; and the `evals` table (DATA-LAYER.md:146) carries a `skill` field directly on every row. Combined with §10's "SQL is the single source of truth" discipline and §6.1's record-class boundary (DATA-LAYER.md:189, "StateStore Beta updates key only off eval/outcome records" — so *any* mechanism that moves a posterior, including whatever `attribute(traj, s*)` does, must do so via a schematized truth record, per-record, not an opaque aggregate), it is architecturally forced that **"which cell owns a given failure record" is per-record, truth-derivable** — this part is not "aggregate replay" and the necessity argument correctly rules that failure mode out for this specific, narrower claim.
- But the **quantity state 3 actually needs is not "which cell owns the failure"** — it is "which of a cell's failures arrived via the `coherent_with` cross-cell-absorption path (§5.1 lines 118-122) as opposed to being that cell's own natively-targeted eval failures." Re-reading §5.1's pseudocode: `attribute(traj, s*)` is called only when `coherent_with(traj, s*.success_items)` holds for a trajectory whose `nearest_admitted_skill` is `s*` — this is a distinct code path from the ordinary `Eval.score(child, a.target_skills)` → `update_posteriors(child, a, r_secret)` flow (§6, lines 189/195) that moves posteriors for the skill actually being attempted. Nothing in §5.1, §6, or the DATA-LAYER schema (`evals` carries `skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id...` — no origin/cause/attribution-path field) tells a reader whether `attribute()`'s effect is (a) recorded as an ordinary `evals`-shaped row indistinguishable from a natively-targeted failure for `s*`, (b) recorded some other way not shown, or (c) doesn't move a posterior at all (e.g., it only feeds `cluster(F)`/provisioning analysis). Whichever of these is true, the **specific "via-absorption" provenance is not exposed by any named field**, so it cannot be replayed out of truth even though the *coarser* "which cell" fact can be.
- The necessity argument's closing line — "A deployment in which rebuild works and this rate is uncomputable is a contradiction" — therefore proves a **narrower claim** (per-record cell ownership is truth-derivable) than the one it is offered in support of (per-record *absorption-path* is truth-derivable), and state 3's own text still conflates them: "derivable from which posterior each failure record updated" (line 664) is exactly the coarser, already-proven fact, not the finer one the Vulcan-pattern narrative is actually about. This is the same substantive gap round 1's Correctness finding 2 identified — better argued this round, and one layer of it (cell ownership) is now genuinely demonstrated rather than asserted, but the load-bearing layer (absorption-specific attribution) is still not shown, only implied by proximity to the now-solid argument next to it.

**A new, small but concrete inconsistency, introduced by this round's own fix 3.** §20.10's own preamble (line 649) still reads "three parameters registered in §12 (`w_live`, `τ_pin`, `τ_absorb`...)" — but this round adds a fourth, `n_absorb` (the debounce count), which **is** correctly added to the §12 registry (line 286: "`n_absorb` (consecutive-evaluation debounce on the `τ_absorb` alert, default 3)") and to the evaluation-mechanics prose (line 659) and the checks list (line 668) — just not to the preamble's own summary count. A grep-verifiable drift (`grep -c` over the parameter names in the preamble vs. §12 finds 3 vs. 4), of exactly the class this project's own `skills/spec-change-gate/SKILL.md` pre-submission checklist (cited approvingly in round 1's Implementability finding) exists to catch before submission — mildly ironic given it was introduced while fixing a debounce gap that round 1 raised for the same reason.

Net: one of the two round-1 correctness gaps is cleanly closed; the other is more carefully argued but the adversarial pass shows the argument proves a weaker claim than the one it is cited for; and a new, trivial-to-fix numeric drift was introduced by the same round's work. Scored above round 1's 70 (real progress, one clean fix, better argumentation on the other) but still short of "acceptable."

### 2. Design faithfulness

Unchanged from round 1 apart from the correction: additive placement under §20 (§17.6-under-§17 precedent, line 649), JUDGE-side ownership (§20.1), reuse of `significant()`/`k`/`θ`, and clean mapping onto §20.7's delivery taxonomy all still hold and were not touched this round. The round-1 dock ("citing the wrong mechanism as the basis for a new one is itself a design-faithfulness lapse") is resolved along with the correctness fix — §5.1 is now the correctly-cited source for a §5.1-owned mechanism. Raised from 88 to 92; not full marks only because the absorbed-rate claim (Correctness finding 2) still borrows more confidence from §5.1/PR-7's architecture than those sections, read plainly, currently supply.

### 3. Red-team resistance

Re-read `docs/research/ALGORITHM-v0.1-redteam.md`'s eight root causes; none is reopened, and two of round 1's non-RC-numbered docks are now closed:

- **RC-4** (wrong-cell absorption, add-only ratchet, redteam.md:51-53): still honestly framed as visibility-only, not a fix, and still doesn't weaken or claim to close the residual. The Correctness finding above (absorption-specific attribution not yet demonstrably derivable) means state 3's value as an RC-4 mitigation is still asserted more than shown — this residual concern carries forward from round 1, unresolved but also not worsened.
- **RC-1/2/3/5/6/7/8**: unchanged from round 1's analysis; still not applicable or still correctly aligned (no gate touched; `n_min`'s masking effect is observed, not overridden; `significant()` reused rather than reinvented).
- **The alarm-fatigue / desensitize-by-volume soft precursor round 1 flagged is now closed.** `n_absorb` (default 3, §12 line 286) debounces the standalone `τ_absorb` breach exactly per the §20.4 `n_defer` pattern (line 659: "persists for `n_absorb` consecutive evaluations... one noisy window is not a pattern"), with a dedicated fire-test (`test_absorb_alert_debounced`, line 668: "a single-evaluation breach does not deliver; `n_absorb` consecutive breaches do"). This was one of round 1's two red-team-adjacent docks and it is cleanly resolved.

Raised from 80 to 86: the debounce fix removes one of round 1's two soft red-team concerns outright; the other (RC-4's flagship mitigation resting on an argument that proves less than claimed) is narrowed but not eliminated, so this stops short of a clean 90+.

### 4. Implementability

Round 1 named three gaps. Two are now closed:
- **Debounce for the standalone `τ_absorb` alert** — closed (`n_absorb`, line 659, §12 line 286, test at line 668).
- **Degenerate coverage-floor-set handling** — closed (the new Precondition clause, line 661: "an empty §5.3 coverage-floor set... reports not-applicable and engages no state," `test_empty_floor_set_not_applicable` at line 668).
- **No stated algorithm for tallying "growth events per `w_live`" (event-count vs. replay-and-diff)** — round 1 listed this as a gap; it is unchanged this round (correctly out of scope, since the caller's brief scoped this round to the four listed fixes and a regression check, not new implementability work). Still a real gap for a developer to guess at, and still worth closing before build, but it was not part of what round 1 marked *blocking*.

Parameter registration remains grep-clean at the individual-parameter level (each of `w_live`, `τ_pin`, `τ_absorb`, `n_absorb` appears in both the §20.10 body and the §12 line) — only the preamble's *summary count* ("three parameters") drifted, per the Correctness finding above; that is a documentation-consistency defect, not a missing-registration one, so it does not re-open this dimension's core concern.

Raised from 78 to 85: two of three named gaps closed cleanly with fire-tests; the remaining gap is the same, non-blocking, previously-"recommended, not blocking" item.

### 5. Safety / integrity

Unchanged core: `test_no_signal_touches_selection_or_gates` still asserts bit-identical `π`/§8/§19/tier outcomes under maximally adverse signals (line 668); §14/§19.6 breakers untouched (line 666); no calibration-layer or verifier interaction. Round 1's sole dock here — the alarm-fatigue-as-safety-adjacent-concern from an undebounced always-delivered channel — is resolved by the same `n_absorb` fix credited in dimensions 3 and 4. Raised from 88 to 91 (not higher, because the underlying absorbed-rate detection this alert exists to serve is still not fully demonstrated to detect what it claims to, per Correctness — a soft, non-gating residual, not a weakened gate).

### 6. Efficiency / cost

Unchanged. All three signals remain cold-path, computed at the cycle digest (line 659), off the hot decision path, with no new LLM calls. The debounce counter (`n_absorb`) and the cold-start precondition check are O(1) additions with no complexity implications. Held at 85 — the round-1 minor note (no explicit complexity-bound callout, unlike §18.2's precedent) was not addressed this round and was never blocking.

### 7. Completeness

Round 1 named four gaps. Two are cleanly closed and a third is meaningfully strengthened:
- **Empty/near-empty coverage-floor set** — closed (Precondition clause + `test_empty_floor_set_not_applicable`, both cited above).
- **No debounce on the `τ_absorb` breach alert** — closed (`n_absorb` + `test_absorb_alert_debounced`).
- **No explicit test strategy for the two under-specified derivations** — half-closed: the structure-signal derivation now has both a correctly-scoped claim *and* a test that matches it exactly (`test_structure_signal_counts_renewals_without_cause`) — this half is fully resolved. The absorbed-rate derivation's test (`test_absorbed_rate_derivable_from_evidence_keys`, line 668) is unchanged in wording from round 1 and still asserts the *property* ("computes from exactly the records `rebuild_state` consumes") without a mechanism a developer could implement against, consistent with the unresolved half of Correctness finding 2.
- **Cold-start vs. starved cells in the pinned-fraction signal** — unaddressed this round (was "recommended, not blocking" in round 1; out of this round's stated scope).

Raised substantially, from 68 to 82: three of four gaps closed or half-closed with concrete tests; the remaining items were explicitly non-blocking in round 1 and remain so.

### 8. Consistency

The round-1 defect (§5.2 mis-citation, a direct self-contradiction between §20.10's claim and §5.2's actual content) is resolved. Checked again against the surrounding spec for regressions: the §12 parameter line and the §20.10 body still agree on `w_live`, `τ_pin`, `τ_absorb` reuse of `k`/`θ`; the "PR-1–PR-9 preserved" property-impact statement is unchanged and still follows the same pattern accepted for the DATA-LAYER §12 checker and §21.

One fresh, minor inconsistency, found on this round's regression pass and not present in round 1: the §20.10 preamble's "three parameters registered in §12" (line 649) undercounts by one against the actual four-parameter list in §12 (line 286) and the body's own use of `n_absorb` (line 659) — this round's own fix 3 added a parameter without updating the summary sentence that names the count. Concrete, one-line, and easy to fix, but it is a real drift as submitted (Correctness finding above; scored under both dimensions since it is simultaneously a factual inaccuracy and a self-contradiction within the section).

Net movement: +6 from round 1 (74 → 80) — the round-1 defect closing outweighs the small new one, which is far narrower in scope (a headcount word vs. a wrong section citation) but still keeps this short of the "strong" band.

### 9. Calibration / honesty

Mixed, and net slightly down from round 1's 80.

**Improved:** the structure signal's new "Honest scope" clause (line 657) is a genuine calibration improvement — it explicitly narrows the claim to match what the schema supports, names the specific undelivered distinction (ONT-6), and states plainly why ("zero-schema-delta means counting what the log holds"). This is exactly the discipline round 1's Calibration finding asked for, executed correctly.

**Newly introduced concern:** the absorbed-failure-rate paragraph's "**by necessity rather than assertion**" framing (line 659) is stated with *more* certainty than round 1's plainer assertion was, closing with a rhetorical proof-by-contradiction ("A deployment in which rebuild works and this rate is uncomputable is a contradiction"). Per the Correctness finding above, that framing is sound for a narrower claim than the one it is invoked to support — so the section now argues for the weak conclusion with unqualified confidence, which is a *harder* overclaim to catch on a skim than round 1's more hedged original wording, even though the underlying evidentiary support has only partially improved. A reader who accepts the "necessity" framing at face value (as it is written to invite) would come away more confident in the absorbed-rate mechanism than the base spec (§5.1, DATA-LAYER §6.1/§6.2) actually supports.

Net: one real, well-executed calibration fix; one new instance of confident language outrunning its evidentiary base on the section's single most important unresolved claim. Scored at 76 (down 4 from round 1's 80) because the second effect concerns the section's flagship, most consequential claim (state 3, the always-delivered Vulcan alert), while the first improvement concerns a secondary signal (structure freeze) — the weighting should reflect stakes, not just count of fixes.

## Strongest adversarial objection

The round-1 report's adversarial objection was: the section's own founding purpose (catching "shipped-but-inert observability," `STUDY-automaton-autonomy.md` A2) is at risk of being violated by its own two flagship, most novel outputs, because their truth-derivability was asserted rather than demonstrated. This round closes that objection for one of the two (the structure signal) and narrows it for the other (the absorbed-rate check / state 3) without closing it. The objection therefore still stands, in a sharper form: **state 3 — the one state the section calls out as its hardest case ("the one state where 'everything is green' is itself the finding," line 664) — is exactly the one whose truth-derivability remains unproven on the section's own submitted evidence.** If an implementer builds `test_absorbed_rate_derivable_from_evidence_keys` literally as named, the honest failure mode is not "the test fails" but "the test is unwritable as specified," because no field in the DATA-LAYER schema distinguishes a `coherent_with`-absorbed failure from a natively-targeted one — the implementer would have to either (a) silently substitute plain within-skill failure rate (the same substitution round 1 warned about, now dressed in language that makes it look resolved) or (b) discover mid-build that §5.1's `attribute()` needs a persistence contract the base spec never gave it, at which point this section's "zero schema delta" headline property (line 649) is false for exactly the one component that matters most. The round's "necessity, not assertion" framing is the most dangerous artifact of this round precisely because it reads as closure to anyone who does not re-derive it from the cited sections independently, which is what this review's brief asked for and what surfaces the gap.

## Aggregate confidence

```
critical_floor  = min(76, 86, 91) = 76
weighted_mean   = (76*2 + 92 + 86*2 + 85 + 91*2 + 85 + 82 + 80 + 76) / 11
                = (152 + 92 + 172 + 85 + 182 + 85 + 82 + 80 + 76) / 11
                = 1006 / 11
                = 91.45 → 91
overall         = min(76, 91) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

Overall confidence (76) is below the 80 bar, and Correctness (76, CRITICAL) remains below the 80 threshold that would let the score alone clear the bar (it is not below 70, so the independent CRITICAL-dimension trigger is not separately tripped, but the aggregate-score rule is). Real progress since round 1 (70 → 76): two of round 1's four blocking items are cleanly closed (debounce, cold-start precondition), one is cleanly closed at the citation level (structure signal), and one (absorbed-rate derivability) is better argued but not resolved.

Blocking changes required to clear 80:

1. **Close the absorbed-failure-rate gap for real, not by narrower-claim substitution.** Either (a) specify concretely how `attribute(traj, s*)` (§5.1) persists — name the record/event kind it writes and confirm it (or a companion field) distinguishes a `coherent_with`-absorbed failure from a natively-targeted one, so `test_absorbed_rate_derivable_from_evidence_keys` names a computable mechanism, not just a truth-derivable *property*; or (b) apply the same honest-narrowing move already used for the structure signal — state plainly that the "absorbed-failure-rate" as specified computes ordinary within-skill failure rate (a real, computable, but different and weaker quantity than the Vulcan-pattern-specific rate), and adjust state 3's narrative and test name/description to match what is actually built.
2. **Fix the parameter-count drift.** Update the §20.10 preamble (line 649) from "three parameters" to name all four (`w_live`, `τ_pin`, `τ_absorb`, `n_absorb`), matching §12's registration (line 286) and the body's own use of `n_absorb` (line 659). One-line, mechanical, and exactly the class of defect this project's spec-change-gate checklist exists to catch pre-submission.
3. **Soften the "necessity, not assertion" framing to match what it actually proves.** The argument correctly establishes truth-derivability of *which cell a failure record belongs to*; it does not establish truth-derivability of *whether that record arrived via `coherent_with` cross-cell absorption*. State the argument's actual scope explicitly (or fold this into fix 1's resolution) so the section's confidence tracks its evidence — this is a calibration fix, not just a correctness one, since as written it is more likely to read as settled than it is.

Not blocking, carried forward as still-open from round 1 (recommended, not required): name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's growth-event tally; distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test.
