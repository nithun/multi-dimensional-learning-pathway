# 360 Review: S20-10-learning-liveness — 2026-08-13 (round 4)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20.10 "Learning liveness — detecting absence, not just harm" (lines 647-669), plus its §12 parameter registration (line 286) |
| Proposed change (this round) | The honest-narrowing move taken in full: (1) the failure-rate anomaly predicate is redefined directly on schema fields — per-cell recent held-out failure rate `(n_total − n_pass)/n_total` over the cell's `evals` rows in `w_live`, no record-type/derivability claim; (2) an explicit "what this checks and what it doesn't" scoping clause naming the attribution-channel gap as out-of-scope; (3) state 3 renamed "Converged-with-anomaly-pattern" with its Vulcan narrative rewritten; (4) test renamed `test_anomaly_rate_from_eval_rows`; (5) §12 `τ_absorb` naming note + structure-freeze wording swept |
| Round 1 | `docs/research/reviews/S20-10-learning-liveness-review.md` — 70/100, needs-revision |
| Round 2 | `docs/research/reviews/S20-10-learning-liveness-review-r2.md` — 76/100, needs-revision |
| Round 3 | `docs/research/reviews/S20-10-learning-liveness-review-r3.md` — 66/100, needs-revision (regression) |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Proceeding as a normal (committable) review, not a proposal.

## Scope note

Per instruction, `docs/research/DATA-LAYER.md` §6.3 and `docs/research/IMPL-PROTOCOL.md` remain out of scope, as in rounds 1-3. DATA-LAYER is read at its state through the approved §6.1/§6.2/§12 content.

## Dimension scores

| # | Dimension | Score | Status | Δ vs round 3 |
|---|---|---|---|---|
| 1 | Correctness (CRITICAL) | 78 | weak | +12 |
| 2 | Design faithfulness | 86 | pass | 0 |
| 3 | Red-team resistance (CRITICAL) | 84 | pass | +4 |
| 4 | Implementability | 81 | pass | +3 |
| 5 | Safety / integrity (CRITICAL) | 90 | pass | +2 |
| 6 | Efficiency / cost | 85 | pass | 0 |
| 7 | Completeness | 78 | weak | 0 |
| 8 | Consistency | 75 | weak | −3 |
| 9 | Calibration / honesty | 68 | weak | +13 |

## Findings by dimension

### 1. Correctness

This round's brief asked for a direct check of the narrowed predicate against DL §2.1's `EvalResult` fields, a grep-style overclaim sweep, and a regression check of everything previously resolved. Doing all three produces a genuinely mixed but net-positive result: the three-round flagship gap is finally closed correctly, a small citation slip survives, and one **new** factual defect was introduced in the same revision.

**The flagship claim — closed, for real this time.** §20.10 line 659 now defines the anomaly predicate directly: "a cell's recent held-out failure rate (`(n_total − n_pass)/n_total` over the cell's `evals` rows in `w_live` ...) elevated (`> τ_absorb`) or `significant()`-positive-sloped while the cell's `ĉ` stays ≥ θ." Checked against DATA-LAYER.md:146, the `evals` table carries exactly `n_pass`, `n_total`, `skill`, `difficulty`, `split{public|held_out}` — every field this formula needs, with no invented record type, no record-type-distinction claim, and no `coherent_with`-provenance claim anywhere in the clause. Rounds 1-3's unresolved gap (whether "absorbed vs. natively-targeted" failure attribution is truth-derivable) is **not answered — it is correctly withdrawn**: the new "What this checks and what it doesn't" clause (line 659) states plainly that the check "computes only the rate, and makes no claim about the failures' attribution channel," and names the reason concretely: "Decomposing by channel... would require a failure-trace record kind the DATA-LAYER schema does not define — a pre-existing tension between §6.1's prose enumeration and the §5 schema, out of this section's scope." I independently re-verified this characterization against DATA-LAYER.md:170 ("failure traces... can move a posterior" — scope-setting prose, no schema entry) vs. DATA-LAYER.md:189 ("StateStore Beta updates key only off eval/outcome records") and DATA-LAYER.md:146 (no `failure_trace` table/event kind exists) — the tension is real and the characterization is accurate, unchanged from round 3's independently-verified finding. This is the correct exit round 3's own adversarial objection recommended, taken cleanly: no fourth reformulation of the unsupported claim, an honest narrowing instead. **This is real, structural progress and the single most important fact this round establishes.**

**A concrete, minor citation-location error survives.** §20.10 line 659 and the matching test description (line 668, `test_anomaly_rate_from_eval_rows`) both cite "the DL §2.1 `EvalResult` schema" / "the DL §2.1 `EvalResult` fields" as the source of the `n_pass`/`n_total` fields. Checked directly: DATA-LAYER §2.1 (DATA-LAYER.md:53-94) is the **ports/Protocol interface block** — it names `EvalResult` only once, as an unelaborated type in a method signature (`def record_eval(self, r: EvalResult, lineage: Lineage) -> AppendResult: ...`, DATA-LAYER.md:58). §2.1 defines **no fields** for `EvalResult` anywhere. The actual field list (`n_pass, n_total, skill, difficulty, split, verifier, item_ids, checkpoint_id, agent_id, episode_id, attempt_idx`) lives in **§5**'s `evals(...)` schema (DATA-LAYER.md:146), not §2.1. The substance of the claim is correct (those fields do exist, exactly as needed) — but the citation points to a section that does not contain what it is cited for, the same defect *class* flagged in round 1 (§5.2 mis-citation) and round 3 (§6.1 mis-citation), here in its mildest form: a one-line, mechanical section-number fix (§2.1 → §5), not a fabricated concept. Scored as a real but low-severity defect.

**A new, more consequential defect: the rewritten Vulcan narrative inverts its own cited source.** §20.10 line 664 (state 3, "Converged-with-anomaly-pattern") now reads: "This is the Vulcan signature read literally (`STUDY-llms-cant-jump.md` H1): Mercury's perihelion was a **visible, persistent residual under a model every summary called 10⁻⁹-precise** — not a hidden channel, a tolerated one." Checked directly against the cited source, `STUDY-llms-cant-jump.md:17,42,44`: "Newtonian gravity had no empirical crisis (equivalence verified to 10⁻⁹; the one anomaly, Mercury's perihelion, was **attributed to a hidden planet, Vulcan**)" (line 17); "10⁻⁹ precision, one tiny anomaly, **absorbed by a hypothesized hidden planet**" (line 42); "a systematically anomalous trace that is nonetheless coherent with an existing cell keeps being absorbed, exactly as perihelion data kept being 'explained' by Vulcan. **The residue MDLP would never see**... Nothing watches for that pattern" (line 44). The source is unambiguous on two points §20.10's rewrite gets backwards: (a) the 10⁻⁹ figure belongs to the **equivalence principle**, a separate measurement, not to "a model every summary called 10⁻⁹-precise" that included the perihelion residual; (b) the historical resolution was **explicitly a hidden-channel explanation** — an unseen, invented planet, searched for and never found — which the source repeatedly calls "absorbed" and "the residue MDLP would never see," i.e. the opposite of "tolerated" and "not a hidden channel." §20.10's own "Vulcan move" analogy (the reason state 3 is provenance-linked to H1 at all, line 649: "Provenance:... `STUDY-llms-cant-jump.md` H1 (the third state)") is precisely that `coherent_with` absorption is *structurally* the Vulcan hidden-channel patch. Asserting the opposite characterization of the historical case, in the sentence that is supposed to ground state 3's importance, is a factual claim that contradicts its own citation — verifiable directly, not a matter of interpretation. This is a **new** defect, introduced by this round's own item-3 rewrite, not present in rounds 1-3 (whose Vulcan narrative used the accurate "absorbed by a hidden planet" framing and was never challenged on this point).

**Net assessment.** The three-round flagship gap (absorbed-rate ↔ `coherent_with` derivability) is finally, honestly closed — the single biggest fact of this round, and real structural progress unlike rounds 2-3's re-arguments of the same unresolved claim. Against that: one low-severity citation-location slip (§2.1 vs §5, easily fixed) and one new, independently-verifiable factual inversion in the section's own motivating narrative (Vulcan-as-hidden-channel vs. Vulcan-as-tolerated-residual), introduced by this round's revision rather than inherited from a prior round. Scored well above round 3 (78 vs 66) because the load-bearing computational claim is now sound and demonstrated, not asserted — but held short of "acceptable-strong" because a fresh, verifiable citation-contradicts-source defect appeared in the very same revision whose job was to close exactly that failure class.

### 2. Design faithfulness

Unchanged from round 3's clean architectural elements: additive placement (§17.6-under-§17 precedent, line 649), JUDGE-side ownership (§20.1), reuse of `significant()`/`k`/`θ`, mapping onto §20.7's delivery taxonomy — all intact, no regression. Held at 86 (not raised, despite the flagship correctness fix) because the fresh §2.1 citation slip and the Vulcan-narrative inversion (Correctness above) are each, in their own way, instances of borrowing more authority from a cited source than that source actually grants — the same design-faithfulness lapse class docked in rounds 1 and 3, now smaller in magnitude but present in two places rather than one.

### 3. Red-team resistance

Re-checked against `docs/research/ALGORITHM-v0.1-redteam.md`'s eight root causes; none is newly reopened:

- **RC-4** (wrong-cell absorption, add-only ratchet, redteam.md:51): still honestly framed as visibility-only, and — for the first time across four rounds — the check's actual claimed scope now matches what it computes, closing the specific residual concern rounds 1-3 kept finding (a mitigation an operator is invited to trust that rests on an unproven derivation). This is a genuine, durable improvement over round 3's posture.
- **RC-1/2/3/5/6/7/8**: unchanged; not applicable or correctly aligned, as in all prior rounds.
- The round-2 debounce fix (`n_absorb`) remains in place and unaffected (line 659, `test_absorb_alert_debounced` at line 668).

Raised from round 3's 80 to 84: the core computational-mechanism concern that drove three rounds of docking is resolved. Not raised further, because the section's own founding purpose — catching mechanisms that "look armed but are not" (`STUDY-automaton-autonomy.md` A2, cited at §20.10's opening) — is now, on this round's finding, satisfied for the *mechanism* but not fully for the *narrative that motivates it*: an operator reading the Vulcan analogy as written would come away with an inverted mental model of what class of failure state 3 is meant to catch, which is a soft, narrative-level instance of the identical "looks-right-but-isn't" pattern this section exists to prevent — applied to the section's own justification text rather than to its computation.

### 4. Implementability

Two developer-facing gaps, one carried forward and one new:

- **New: the §2.1 citation is not actionable as written.** A developer told to build `test_anomaly_rate_from_eval_rows` against "the DL §2.1 `EvalResult` fields" would find no field list at §2.1 (Correctness above) — they would need to independently locate §5's `evals` table to proceed. A one-line fix (cite §5, or DL §6.1's discussion of the `evals` schema) removes the ambiguity entirely; as written it is a minor but real speed bump, not a blocker (the correct fields are locatable elsewhere in the same document).
- **New, more concrete: "held-out failure rate" does not state a `split` filter.** The formula (`(n_total − n_pass)/n_total` over "the cell's `evals` rows in `w_live`") never says whether rows are filtered to `split = held_out` before the ratio is computed. The signal is explicitly named "held-out failure rate," and DATA-LAYER's `evals.split ∈ {public, held_out}` column exists precisely to make that distinction (DATA-LAYER.md:146) — but the prose as written would let a developer legitimately build either "held-out-only failure rate" (the named intent) or "all-`evals`-rows failure rate" (a different, `public`-inflated quantity), and the two are not interchangeable given §6.1's public/held-out split is load-bearing elsewhere in the spec (§8's gate discipline). This is the section's own class of bug (a computed-quantity ambiguity a developer could resolve two different ways) that its sibling structure-signal fix (line 657's "Honest scope" clause) shows how to close, but this clause does not.
- **Carried forward, still non-blocking:** no stated algorithm for the structure signal's growth-event tally (event-count vs. replay-and-diff) — unchanged since round 1, out of every round's stated scope so far.

Two of round 3's closed items (debounce, degenerate-floor-set precondition) remain closed and unaffected. Raised from round 3's 78 to 81 — the flagship implementability blocker (an unwritable test) is now writable, offsetting the two new, smaller ambiguities named above.

### 5. Safety / integrity

Core posture unchanged and clean across all four rounds: `test_no_signal_touches_selection_or_gates` (line 668) still asserts bit-identical `π`/§8/§19/tier outcomes under maximally adverse signals; §14/§19.6 breakers untouched (line 666); no calibration-layer or verifier interaction (`HUMAN-LEARNING-VERIFIER.md` and DATA-LAYER §6.3 confirmed not implicated — no `liveness`/`20.10` reference in either). Raised slightly from round 3's 88 to 90: the soft alarm-integrity concern flagged in rounds 1 and 3 (an always-delivered alert whose triggering condition might not be demonstrably computable) is resolved now that the predicate is genuinely buildable — this was the concern's entire basis, and it no longer applies to the computational mechanism. Not raised further (not a clean 95+), because the Vulcan-narrative defect (Correctness) is a milder instance of the same underlying "looks-armed-but-isn't" risk class applied to operator-facing framing rather than to firing behavior — narrative miscalibration in an unattended-operation alert's own justification text is safety-adjacent, not safety-gating.

### 6. Efficiency / cost

Unchanged across all four rounds. All three signals remain cold-path, computed at the cycle digest (line 659), no new LLM calls, no complexity change from this round's edits. Held at 85 (the round-1 minor note — no explicit complexity-bound callout, unlike §18.2's precedent — remains unaddressed and non-blocking).

### 7. Completeness

- **Two of round 2's closed gaps remain closed:** the empty-coverage-floor-set precondition (line 661) and the `τ_absorb` debounce (`n_absorb`, line 659/668) are both unchanged and unaffected this round.
- **The absorbed-rate test-strategy gap is, for the first time, genuinely closed** — `test_anomaly_rate_from_eval_rows` (line 668) now names a concrete, buildable mechanism ("computes from `evals` rows alone... a synthetic log with known failure rates reproduces them exactly"), resolving the item every prior round left half- or un-closed.
- **New gap: the `split = held_out` filter is unspecified** (Implementability above) — a genuine completeness hole in the predicate's own definition, distinct from (and smaller than) the three-round derivability gap it replaces.
- **Carried forward, non-blocking, unaddressed across four rounds:** the structure signal's growth-event tally computation strategy; distinguishing cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction signal.

Held at 78 (round 3's score) — one major, long-standing gap closes and a new, smaller one opens; the two are of comparable size in this dimension's accounting, given the still-open carried-forward items keep this short of "acceptable-strong" regardless.

### 8. Consistency

**One clean regression-check pass:** the four-parameter count (`w_live`, `τ_pin`, `τ_absorb`, `n_absorb`) is unchanged and still grep-clean between the §20.10 preamble (line 649) and §12's registration (line 286) — round 2's drift stays fixed, no new drift on this axis. The §12 line's added clarifying note ("the name predates the check's honest narrowing and is kept for stability," line 286) accurately describes the situation and introduces no inconsistency. The structure-freeze sentence (line 659, "zero growth events and zero edge renewals") no longer references "intervention renewals," correctly matching the structure signal's own already-narrowed claim (line 657) — the requested sweep item.

**A small, new internal inconsistency: the subsection's own header still uses the old label the body just retired.** Line 661 opens: "**The three-state distinguisher (JMP-1) — done, stuck, and the Vulcan state.**" Three states later (line 664), the state is named "**Converged-with-anomaly-pattern**," not "the Vulcan state" — the rename applied to the enumerated item was not swept back into the sentence introducing it three lines earlier, so a reader encounters the retired name and the new name for the same state within one paragraph.

**The Vulcan-narrative inversion (Correctness) is also, independently, a consistency defect** in the classic sense used throughout this review series: a direct contradiction between what §20.10 asserts and what its own cited source (`STUDY-llms-cant-jump.md` H1) states, the same failure class flagged for §5.2 in round 1 and §6.1 in round 3.

Docked from round 3's 78 to 75: the parameter-count and structure-freeze sweeps the caller specifically requested are both confirmed clean, but two new, smaller inconsistencies (the header/body naming lag, and the narrative-vs-source contradiction, counted here alongside Correctness per this review's established practice of scoring one root defect under both dimensions) offset that.

### 9. Calibration / honesty

The most volatile dimension across all four rounds, and again this round — but for a different reason each time.

**What is now genuinely, durably fixed:** the flagship overclaim pattern of rounds 2-3 (asserting derivability of a quantity the schema cannot support, with rising confidence each round) is **gone**. The new predicate definition (line 659) and its "What this checks and what it doesn't" clause state the check's actual scope plainly, name the specific gap it cannot close (attribution-channel decomposition) and why (no failure-trace record kind), and explicitly flag the DATA-LAYER §170-vs-189 tension as "out of this section's scope and noted rather than papered over" — exactly the discipline the structure signal's "Honest scope" clause modeled in round 2 and this round finally applies to the section's other historically-overclaimed component. This is real, substantial calibration progress on the specific claim that mattered most.

**What is newly broken:** the Vulcan-narrative rewrite (Correctness, Consistency above) states, with unqualified confidence ("read literally," "the Vulcan signature"), a historical characterization that its own cited source directly contradicts. This is not a hedged, uncertain claim that turns out to be wrong — it is stated as the *more careful, literal* reading (explicitly framed as a correction/sharpening move) while being less accurate than the plainer original framing it replaces. A reader has no cue to doubt it; the confident phrasing invites acceptance exactly where round 2 and round 3's Calibration findings warned this pattern is most dangerous ("a harder overclaim to catch on a skim").

Net: this round genuinely closes the multi-round flagship calibration problem (the technical derivability overclaim) — a result better than round 3's 55 by a wide margin — but opens a new, narrower overclaim in the same subsection, on a claim now independently verified false rather than merely under-supported. Because both effects are real and roughly comparable in scale (one clean multi-round fix, one clean new defect), and because the Vulcan claim sits in the section's single most consequential state's motivating sentence, this is scored as still weak — meaningfully better than round 3 (55 → 68) but not yet in the acceptable band, since the section still asks a reader to trust a specific, checkable factual claim that a direct check falsifies.

## Strongest adversarial objection

Across four rounds, this review series has tracked one recurring pattern: **each fix closes the specific gap the previous round named, and each round's own new work opens a smaller instance of the identical defect class one level over.** Round 1's §5.2 mis-citation became round 3's §6.1 mis-citation; round 2's "necessity, not assertion" overclaim became round 3's "record-type distinction" overclaim, stated with rising confidence each time. This round is the first to break that specific chain on its primary axis — the absorbed-rate derivability claim is honestly withdrawn rather than re-argued, which is real, structural progress and should be credited as such without hedging. But the same reviewing discipline that caught the prior three instances, applied one level further out — to the section's own supporting narrative rather than its core mechanism — finds a fresh instance in exactly the place a reader would least expect to need to check it: a physics-history footnote, cited to a document already in the review's working set, that a direct read contradicts. The adversarial question this raises is not "is the mechanism sound" (it now is) but **"how many more layers does this pattern go, and has anyone checked the ones a review brief didn't specifically ask about?"** This round's brief asked for a "grep-style sweep for absorbed/attribution/record-type language" — a sweep for a *specific vocabulary* of overclaim — and that sweep would not have caught the Vulcan inversion, because it uses none of that vocabulary; it is a confident historical assertion in ordinary prose, not a technical derivability claim. If a fifth round fixes this and the sweep methodology does not change to include direct source-checking of every citation (not just the ones a round's brief names), there is no structural reason to expect the pattern has actually stopped rather than simply moved to the next unaudited sentence.

## Aggregate confidence

```
critical_floor  = min(78, 84, 90) = 78
weighted_mean   = (78*2 + 86 + 84*2 + 81 + 90*2 + 85 + 78 + 75 + 68) / 11
                = (156 + 86 + 168 + 81 + 180 + 85 + 78 + 75 + 68) / 11
                = 977 / 11
                = 88.82 → 89
overall         = min(78, 89) = 78
```

**Overall confidence: 78 / 100**

## Verdict

**needs-revision**

Overall confidence (78) is below the 80 bar; no CRITICAL dimension is below 70 (Correctness 78, Red-team 84, Safety 90), so only the aggregate-score trigger fires, not the independent CRITICAL-dimension trigger. This is the strongest round yet by a clear margin (66 → 78, +12), driven by a genuine, verified close of the three-round flagship correctness gap — but the round's own new work (the Vulcan-narrative rewrite, plus a minor citation-location slip) introduces enough fresh, independently-verifiable defect to keep the total just under the bar.

Blocking changes required to clear 80:

1. **Fix the Vulcan-narrative inversion (line 664).** The claim "Mercury's perihelion was a visible, persistent residual under a model every summary called 10⁻⁹-precise — not a hidden channel, a tolerated one" contradicts its own cited source (`STUDY-llms-cant-jump.md`:17,42,44), which states the anomaly was explicitly "attributed to a hidden planet, Vulcan" / "absorbed by a hypothesized hidden planet." Either restore the historically accurate framing (the Vulcan move *is* a hidden-channel patch, structurally analogous to `coherent_with` absorbing an anomalous trace into an existing cell without surfacing it) and build the "whatever the channel" honest-scope point on top of that accurate framing rather than by inverting it, or drop the specific "not a hidden channel, a tolerated one" claim and state the analogy at the level the check actually supports (a persistent residual under a confident summary, full stop, without asserting how history handled visibility).
2. **Fix the §2.1 → §5 citation (lines 659, 668).** "Fields the DL §2.1 `EvalResult` schema defines today" should cite DL §5 (the `evals` table, DATA-LAYER.md:146), which is where `n_pass`/`n_total`/`skill`/`split` are actually defined; §2.1 only names the `EvalResult` type in a Protocol method signature and defines no fields.
3. **State the `split` filter explicitly.** The failure-rate formula should say whether it is computed over `split = held_out` rows only (matching the signal's own name, "held-out failure rate") or over all `evals` rows regardless of split — these are different, non-interchangeable quantities given §6.1's public/held-out distinction is load-bearing elsewhere in the spec.
4. **Sweep the residual "Vulcan state" label out of line 661's header sentence**, matching the rename already applied to the enumerated state itself (line 664, "Converged-with-anomaly-pattern") — a one-line, mechanical fix, but a real internal inconsistency as submitted.

Not blocking, confirmed genuinely resolved this round and verified not to have regressed: the absorbed-failure-rate predicate's core derivability (now correctly narrowed rather than asserted or re-argued), the four-parameter count, the `τ_absorb` debounce, the empty-coverage-floor-set precondition, the structure signal's "Honest scope" narrowing (unchanged, re-verified), the structure-freeze wording sweep, and the three-state partition's disjointness/exhaustiveness (unchanged, re-verified against the same 2×2 competence×anomaly space as rounds 1-2).

Not blocking, carried forward as still-open (recommended, not required): name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's growth-event tally; distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test.
