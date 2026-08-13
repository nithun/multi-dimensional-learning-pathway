# 360 Review: S20-10-learning-liveness — 2026-08-13 (round 5)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20.10 "Learning liveness — detecting absence, not just harm" (lines 647-669), plus its §12 parameter registration (line 286) |
| Proposed change (this round) | Revision responses to round-4's four blocking findings: (1) rewrite the Vulcan narrative so the residual-visible / explanation-hidden halves match the source; (2) cite DL §5 (not §2.1) for the predicate's fields; (3) make `split = held_out` explicit in the failure-rate formula; (4) retire "the Vulcan state" label from the three-state-distinguisher header |
| Round 1 | `docs/research/reviews/S20-10-learning-liveness-review.md` — 70/100, needs-revision |
| Round 2 | `docs/research/reviews/S20-10-learning-liveness-review-r2.md` — 76/100, needs-revision |
| Round 3 | `docs/research/reviews/S20-10-learning-liveness-review-r3.md` — 66/100, needs-revision (regression) |
| Round 4 | `docs/research/reviews/S20-10-learning-liveness-review-r4.md` — 78/100, needs-revision |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Proceeding as a normal (committable) review, not a proposal.

## Scope note

Per instruction, `docs/research/DATA-LAYER.md` §6.3 and `docs/research/IMPL-PROTOCOL.md` remain out of scope, as in rounds 1-4. DATA-LAYER is read at its state through the approved §6.1/§6.2/§12 content.

## Dimension scores

| # | Dimension | Score | Status | Δ vs round 4 |
|---|---|---|---|---|
| 1 | Correctness (CRITICAL) | 83 | pass | +5 |
| 2 | Design faithfulness | 87 | pass | +1 |
| 3 | Red-team resistance (CRITICAL) | 87 | pass | +3 |
| 4 | Implementability | 78 | weak | −3 |
| 5 | Safety / integrity (CRITICAL) | 90 | pass | 0 |
| 6 | Efficiency / cost | 85 | pass | 0 |
| 7 | Completeness | 81 | pass | +3 |
| 8 | Consistency | 75 | weak | 0 |
| 9 | Calibration / honesty | 69 | weak | +1 |

## Findings by dimension

### 1. Correctness

This round's brief asked for direct verification of all four r4 fixes, plus a sweep for remaining inconsistency and a final regression pass. Doing exactly that produces three clean closures and one **incompletely applied** fix, verifiable against the artifact's own two citation sites.

**Fix 1 — Vulcan narrative inversion, genuinely closed.** Line 664 now reads: "the **residual was visible** — Mercury's perihelion advance sat in the data while every summary called the model 10⁻⁹-precise — and the **explanation absorbing it was hypothesized and hidden** (the planet Vulcan)." Checked against the cited source (`STUDY-llms-cant-jump.md:17,42,44`): line 17 — "the one anomaly, Mercury's perihelion, was attributed to a hidden planet, Vulcan"; line 42 — "10⁻⁹ precision, one tiny anomaly, absorbed by a hypothesized hidden planet"; line 44 — "exactly as perihelion data kept being 'explained' by Vulcan." Both halves of the rewrite now match the source: the residual was present/visible in the data, and the absorbing explanation was a hypothesized, hidden channel (the planet). This is the exact opposite framing from r4's flagged text ("not a hidden channel, a tolerated one") and the inversion r4 found does not survive into this round. "This check detects the first half — the visible residual under a green summary — whatever hypothesized channel is absorbing it" is a logically sound restatement of the honest-scope clause at line 659 ("makes no claim about the failures' attribution channel"). No residual defect found here — this is real, verified progress.

**Fix 2 — citation fix, only half-applied; the artifact now internally disagrees with itself.** r4's blocking item 2 named **both** line 659 and line 668 explicitly ("Fix the §2.1 → §5 citation (lines 659, 668)"). Checking each independently:
- Line 659 (evaluation-mechanics prose): "...`(n_total − n_pass)/n_total` over the cell's `evals` rows with `split = held_out` in `w_live` — fields the DL **§5** truth schema defines today..." — **fixed**, correctly cites §5.
- Line 668 (`test_anomaly_rate_from_eval_rows`, the Checks list): "...the per-cell failure-rate anomaly computes from `evals` rows alone — the DL **§2.1** `EvalResult` fields as defined today, no new record kind or field..." — **not fixed**. This is the identical string r4 flagged, byte-for-byte unchanged.

Re-verified against DATA-LAYER.md:53-94 (§2.1, the `Protocol` ports block): it names `EvalResult` only once, in a method signature (`def record_eval(self, r: EvalResult, lineage: Lineage) -> AppendResult: ...`, DATA-LAYER.md:58), and defines no fields for it anywhere. The actual field list (`n_pass, n_total, skill, difficulty, split{public|held_out}, ...`) lives at DATA-LAYER.md:146 (§5). So the substance is still correct (those fields exist and are exactly what the check needs) but the citation at line 668 remains factually wrong, and — new this round — it now **contradicts** the correct citation nine lines above it at line 659, inside the same subsection, about the same fact. This is a smaller-scope defect than r4's (r4 had one uniform wrong citation in two places; this round has one right and one wrong, i.e. an internal contradiction rather than a uniform error), but it is not the closed item the round's revision-response claims.

**Fix 3 — `split = held_out`, genuinely closed.** Line 659's formula now reads "over the cell's `evals` rows with `split = held_out` in `w_live`," resolving r4's Implementability finding (a developer could previously build either an all-rows or held-out-only version). Checked against DATA-LAYER.md:146, `evals.split{public|held_out}` is an existing field — no schema delta, consistent with the section's zero-schema-delta claim (line 649). Clean.

**Fix 4 — header rename, genuinely closed.** Line 661 now reads "**The three-state distinguisher (JMP-1) — done, stuck, and the anomaly-pattern state.**" — matching state 3's name, "Converged-with-anomaly-pattern" (line 664). Grepped the full document for "the Vulcan state": zero remaining occurrences. Clean, no leftover naming anywhere else in the file.

**Net assessment.** Three of four fixes are cleanly and fully verified; the fourth (citation) was explicitly requested at two named line numbers and only one was actually changed, leaving a fresh, small, internal contradiction where a uniform error used to be. Because the correct citation sits immediately above the wrong one in the same subsection, the practical harm to a reader working top-to-bottom is lower than r4's version of this defect — but the defect is real, independently verifiable, and not the "citation fixed" outcome asserted for this round. Scored above r4 (83 vs 78) because the more consequential defect (the Vulcan inversion, r4's "new, more consequential defect") is genuinely gone and the flagship derivability claim (closed in r4) remains closed and unregressed — held below "strong" because a specifically-named, two-location fix instruction was only half-executed.

### 2. Design faithfulness

Unchanged architectural elements from r3/r4 (additive placement, JUDGE-side ownership, `significant()`/`k`/`θ` reuse, §20.7 delivery-taxonomy mapping) remain intact — no regression. Raised from r4's 86 to 87: the Vulcan-narrative fix removes one of the two "borrowing more authority from a cited source than it grants" instances r4 docked here. Not raised further: the surviving line-668 citation is the same defect class in miniature (a Checks-list entry attributing its field grounding to a section that does not define those fields), now contradicting the correct citation nine lines earlier rather than repeating it.

### 3. Red-team resistance

Re-checked against `docs/research/ALGORITHM-v0.1-redteam.md`'s eight root causes; none newly reopened:

- **RC-4** (wrong-cell absorption, add-only ratchet, redteam.md:51): unchanged from r4 — the check's actual scope (visibility of the residual, not attribution-channel decomposition) is still honestly stated (line 659's "what this checks and what it doesn't" clause), and the Vulcan-narrative fix now correctly analogizes the historical case (hidden-channel absorption) to the mechanism it names (`coherent_with` absorption) rather than inverting it. This closes the narrative-level "looks-armed-but-isn't" concern r4 raised at dimension 3 — the check's own justification text no longer misdescribes the failure pattern it exists to catch.
- **RC-1/2/3/5/6/7/8**: unchanged; not applicable or correctly aligned, as in all prior rounds.
- Debounce (`n_absorb`) and the empty-floor-set precondition remain in place and unaffected.

Raised from r4's 84 to 87: the narrative-level residual concern is resolved. Not raised to 90+: the surviving line-668 citation is a small instance of the same "stated more confidently than verified" pattern this section exists to catch elsewhere, applied here to the section's own developer-facing test description rather than to its computation or its history-analogy — lower stakes than either prior instance, but not zero.

### 4. Implementability

- **Line 668 remains not directly actionable as a standalone reference.** A developer building `test_anomaly_rate_from_eval_rows` from the Checks list alone (line 668) would still be pointed at "the DL §2.1 `EvalResult` fields," which defines no such fields (Correctness above). The correct grounding is one paragraph away (line 659, §5) and would very likely be read first in practice — this materially lowers the real-world risk relative to r4's version of the same defect, where no correct citation existed anywhere in the section — but the Checks list is written and used as an implementation checklist in its own right, and as submitted it still needs an out-of-band correction to build against directly.
- **The `split = held_out` gap is closed** (Correctness, Fix 3) — this round's largest implementability improvement, since it was r4's most concrete new finding.
- **New, minor: no stated behavior for zero held-out `evals` rows in `w_live`.** The formula `(n_total − n_pass)/n_total` divides by `n_total`, and restricting to `split = held_out` (the fix just applied) narrows the eligible row set relative to the pre-fix "all `evals` rows" reading — for a cell with few or no held-out evaluations inside the window, `n_total = 0` is now a more reachable case than before the split filter was added. The section does not state whether such a cell is excluded from the anomaly check, treated as non-breaching, or otherwise guarded. This is a new-but-small edge case surfaced as a side effect of a fix that otherwise closed a real gap, not a defect present before this round's revision.
- **Carried forward, still non-blocking:** no stated algorithm for the structure signal's growth-event tally (event-count vs. replay-and-diff) — unchanged since round 1, out of every round's stated scope so far.

Docked slightly from r4's 81 to 78: the `split` fix is a genuine, larger closure than the newly-surfaced zero-denominator edge case is a new gap, but the line-668 citation — the specific item this round's brief said was fixed — remains a real, if now lower-stakes, speed bump for a developer working from the Checks list in isolation.

### 5. Safety / integrity

Core posture unchanged and clean across all five rounds: `test_no_signal_touches_selection_or_gates` (line 668) still asserts bit-identical `π`/§8/§19/tier outcomes under maximally adverse signals; §14/§19.6 breakers untouched (line 666); no calibration-layer or verifier interaction (`HUMAN-LEARNING-VERIFIER.md` and DATA-LAYER §6.3 confirmed not implicated — no `liveness`/`20.10` reference in either, consistent with rounds 1-4). Held at r4's 90: the Vulcan-narrative fix resolves the "narrative-level looks-armed-but-isn't" concern r4 scored safety-adjacent (not safety-gating) — a positive, but the surviving line-668 citation is a milder instance of the identical class, so the net movement on this specific axis is roughly neutral this round.

### 6. Efficiency / cost

Unchanged across all five rounds. All three signals remain cold-path, computed at the cycle digest (line 659), no new LLM calls. Adding the `split = held_out` filter is a row-filter on an already-computed query, not a new pass or a complexity change. Held at 85.

### 7. Completeness

- **r4's `split = held_out` gap is closed** (Correctness/Implementability above) — this round's largest completeness gain.
- **The Vulcan-narrative content gap (an inaccurate motivating example) is closed** — the section's third state now has an accurate historical grounding rather than a self-contradicting one.
- **New, minor gap: the zero-held-out-rows edge case** (Implementability above) is unaddressed, a side effect of the split-filter fix.
- **Not actually closed despite being addressed: the line-668 citation** remains a completeness hole in the Checks list's own self-sufficiency (Correctness above).
- **Carried forward, non-blocking, unaddressed across five rounds:** the structure signal's growth-event tally computation strategy; distinguishing cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction signal.

Raised from r4's 78 to 81: two real, larger gaps close (split filter, narrative accuracy); one small new gap opens (zero-denominator edge case) and one named gap remains open in the specific place it was supposed to close (line 668).

### 8. Consistency

**Two of r4's four requested sweeps are cleanly confirmed:** the header no longer says "the Vulcan state" (Fix 4, grep-verified zero remaining occurrences) and the four-parameter count (`w_live`, `τ_pin`, `τ_absorb`, `n_absorb`) remains unchanged and grep-clean between the preamble (line 649) and §12's registration (line 286) — unregressed since round 2.

**One sweep item is now internally contradictory rather than uniformly wrong.** Line 659 cites DL §5 for the predicate's fields; line 668 cites DL §2.1 for the same fields, nine lines later in the same subsection. A reader encountering both would have to resolve a disagreement the document itself introduces this round — a smaller-magnitude but structurally identical defect to the ones flagged in rounds 1 (§5.2 mis-citation), 3 (§6.1 mis-citation), and 4 (§2.1 mis-citation in both places): a citation that does not support what it is cited for, now compounded by disagreeing with its own sibling citation.

**The Vulcan-narrative contradiction with its cited source (r4's Correctness/Consistency finding) is fully resolved** — re-verified directly against `STUDY-llms-cant-jump.md:17,42,44` above; no remaining contradiction found.

Held at r4's 75: one long-standing contradiction (Vulcan-vs-source) closes cleanly, but a new, smaller-scope contradiction (§5-vs-§2.1, internal to the artifact rather than against an external source) opens in its place, in the same location this round's brief specifically asked to have swept.

### 9. Calibration / honesty

**Genuinely improved:** the Vulcan-narrative rewrite is no longer a confident misstatement of its own cited source — it is now an accurate, appropriately-scoped analogy ("this check detects the first half... whatever hypothesized channel is absorbing it"), matching the honest-scope discipline the structure signal's "Honest scope" clause modeled from round 2 onward. This closes the specific calibration failure that drove r4's score down to 68 (a confident claim stated as "read literally"/"the more careful reading" that was, on direct check, less accurate than what it replaced).

**What keeps this in the weak band rather than crossing into acceptable:** the round's own framing describes the citation item as "fixed," and a direct check shows it is fixed at one of the two locations r4 named and not the other — the artifact still asserts, at line 668, a specific factual claim (that DL §2.1 defines the `EvalResult` fields used) that a direct read of DATA-LAYER.md:53-94 does not support, immediately adjacent to a correct version of the identical claim. This is a smaller-magnitude instance of the exact pattern every prior round's Calibration/adversarial section has flagged: a claim of closure that does not fully survive a direct check. It is meaningfully less severe than r3's or r4's instances (the correct fact is stated nearby, in the same subsection, rather than absent or inverted), which is why this scores modestly above r4 rather than below it — but the round explicitly targeted this exact defect by line number and did not fully close it, which is itself the calibration-relevant fact.

Raised marginally from r4's 68 to 69: the larger of the two calibration problems (the Vulcan inversion) is genuinely and fully resolved; the smaller one (an explicitly-named, only-partially-applied fix) is a new but lower-severity instance of the same underlying pattern, holding the net movement small.

## Strongest adversarial objection

For five straight rounds, this review series has found the identical shape of defect: a round closes the specific gap the *previous* round named with concrete evidence, and in doing so leaves (or creates) a smaller instance of the same defect class one level over — round 1's §5.2 mis-citation became round 3's §6.1 mis-citation became round 4's §2.1 mis-citation (in two places) became, this round, a §5-vs-§2.1 **internal contradiction** between those same two places, because only one of the two named locations was actually edited. What makes this round's instance notable is not its severity — it is by a wide margin the smallest and lowest-impact version of the pattern across all five rounds, since the correct fact sits nine lines away in the same subsection — but its **mechanism**: r4's blocking item 2 named both line numbers explicitly ("Fix the §2.1 → §5 citation (lines 659, 668)"), which is as unambiguous a repair instruction as a spec-review process can issue, and the revision still only executed half of it. This is not a case where deeper investigation was needed to surface a gap (as with the Vulcan narrative in r4, or the record-type argument in r3) — the fix was named at the line-number level and a single grep (`grep -n "§2.1" ALGORITHM-v0.2-pathway-learner.md`) would have caught the omission before submission. The adversarial question this raises is not "was the narrative or the predicate correct" (both now are) but **"if a fix instruction that names exact line numbers is not fully executed, what confidence should a reviewer place in fixes described only in prose, with no line numbers to check against?"** Rounds 1-4 each needed source-level verification to catch their defects; this round's residual defect would have been caught by verifying the round's own stated fix list against a plain-text search of the document it modified — a lower bar than any previous round's adversarial pass required, and one this round's revision did not clear.

## Aggregate confidence

```
critical_floor  = min(83, 87, 90) = 83
weighted_mean   = (83*2 + 87 + 87*2 + 78 + 90*2 + 85 + 81 + 75 + 69) / 11
                = (166 + 87 + 174 + 78 + 180 + 85 + 81 + 75 + 69) / 11
                = 995 / 11
                = 90.45 → 90
overall         = min(83, 90) = 83
```

**Overall confidence: 83 / 100**

## Verdict

**ready-for-approval**

Overall confidence (83) clears the 80 bar and no CRITICAL dimension is below 70 (Correctness 83, Red-team 87, Safety 90). This is the strongest round to date (78 → 83, +5), driven by two fully-verified closures (the Vulcan-narrative inversion, the `split = held_out` ambiguity) and two of four requested items closing cleanly (header rename, parameter-count sweep). Note for `change-approver` and any implementer, not blocking this verdict but recommended as a trivial pre-implementation cleanup:

1. **Line 668's citation is still wrong and now disagrees with line 659.** `test_anomaly_rate_from_eval_rows`'s description cites "the DL §2.1 `EvalResult` fields" for the same fact line 659 (nine lines earlier) correctly cites as "the DL §5 truth schema." A one-line, mechanical edit (§2.1 → §5, matching the fix already applied at line 659) closes this — no further review round should be needed to confirm a `grep`-verifiable single-word change.

Not blocking, confirmed genuinely resolved this round and verified not to have regressed: the Vulcan-narrative accuracy (fully re-verified against `STUDY-llms-cant-jump.md:17,42,44`), the `split = held_out` explicit filter, the header naming (no "Vulcan state" label survives anywhere in the document), the four-parameter count consistency, the absorbed-failure-rate predicate's core derivability (r4's flagship fix, unchanged), the `τ_absorb` debounce, the empty-coverage-floor-set precondition, the structure signal's "Honest scope" narrowing, and the three-state partition's disjointness/exhaustiveness.

Not blocking, carried forward as still-open (recommended, not required): name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's growth-event tally; distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test; state the zero-held-out-rows-in-window behavior for the failure-rate anomaly predicate (a new, small edge case surfaced by this round's `split` fix).
