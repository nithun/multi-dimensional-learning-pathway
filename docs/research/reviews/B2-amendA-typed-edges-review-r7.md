# 360 Review: B2-amendA-typed-edges (round 7) — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md:213-262` (Amendment A to the approved B2, round 7 — "typed hierarchy edges + derived traversal order") |
| Proposed change | Round-7 revision: collapses the two competing ordering formulas into one explicit role split — `priority()` orders traversal only (confidence-inclusive, "a walk is a search"); `queue_rank()` governs every queue decision (both `Q_max` eviction *and* `n_conf`-floor confirmation order), with a dedicated regression test `test_one_ordering_rule_for_queues` (`:228`, `:247`); consolidates the Parameters line's aging entries into one bounded mechanism (`:238`); rewrites the worked capacity example to state an explicit arrival assumption (`≤3 new candidates/trigger`, "one per distinct failing skill," attributed to the `n_trigger≥3` filter) and an explicit degradation mode under higher arrival ("triage... never silent drops," `:234`) |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Filing as a full review report (not a proposal).

Scope note: fresh re-review of Amendment A (`BUILD-SPECS.md:213-262`) against round 6 (`docs/research/reviews/B2-amendA-typed-edges-review-r6.md`, overall 78, needs-revision, 4 numbered blocking items + 1 adversarial finding), with an explicit audit of every numbered item accumulated across rounds 1–6. The approved B2 base (`BUILD-SPECS.md:182-211`) and `B2-prereq-gap-decision.md` are fixed context.

## Full cross-round item audit

### Rounds 1–4's 25 items (20 from rounds 1-3 + 5 from round 4) — spot-checked against the round-7 text

None of round 7's edits (`:228`, `:234`, `:238`, `:247`) touch the `Edge` schema (`:219`), the `weight` reservation (`:221`), the union acyclicity mechanism (`:235`), the `hard`-tie-break (`:236`), the degenerate-frontier fallback (`:227`), the `q_edge` soft-floor re-admission channel (`:222`), or `gap_z`'s definition (`:230-231`, unchanged formula, now folded into `queue_rank`). Spot-checked at their cited lines: all remain closed, unaffected. **25/25 remain closed, no regression.**

### Round 5's 5 blocking items + 1 adversarial finding — re-verified status (all previously closed by round 6, checked for regression)

Items 1–3, 5 (arrival-damping retargeting, `q_edge` sampling unit, explicit `queue_rank` formula, quota-parity test) and the round-5 adversarial finding (unbounded aging, closed for the occupancy queue via `A_cap`) all remain closed and unaffected by round 7's edits — the formulas involved (`queue_rank`, `gap_z`, `age`, `A_cap`) are byte-identical to round 6's. Item 4 (worked-example arrival assumption) is round 6's own item 4, tracked below.

### Round 6's 4 blocking items + 1 adversarial finding — checked against the round-7 text

| # | Round-6 required change | Status in r7 |
|---|---|---|
| 1 | Resolve the floor-allocation-ordering contradiction: state plainly whether confirmation-budget floor allocation is ordered by `priority(e→P)` or `queue_rank(c)` | **Closed, cleanly.** `:228`'s new lead sentence states it in one place, unambiguously: "Two formulas, two disjoint jobs — **`priority()` orders traversal only**... **`queue_rank()` governs every queue decision** — both `Q_max` eviction *and* the order in which candidates take the `n_conf` confirmation floor." The "confidence-ranked ordering bias" language round 6 found contradicting this (present in round 6's `:228` and `test_confirmation_floor_and_aging`'s description) is gone from both the prose and the test description (`:246` now reads "floor allocation follows descending `queue_rank`"). Verified: no remaining occurrence of confidence-inclusive floor-allocation language anywhere in the amendment. |
| 2 | State explicitly whether `A_cap` bounds the confirmation-budget aging bump, not only the occupancy queue's `age(c)` term; fix the Parameters line's two-separate-bullets framing | **Closed.** Because `queue_rank()` — a single formula containing `min(age(c), A_cap)` — now literally *is* what orders both the eviction queue and the confirmation-floor queue (item 1, above), the `A_cap` bound applies identically to both by construction; there is no longer a second, uncapped aging mechanism to ask about. The Parameters line (`:238`) now reads one consolidated bullet: "`A_cap` aging cap (3 z-units; age enters only via `queue_rank`, +1 z-unit per skipped trigger, persisted across evictions)" — the two-separate-bullets problem round 6 flagged is gone. |
| 3 | Add a test that pins down the resolved ordering | **Closed.** `test_one_ordering_rule_for_queues` (`:247`): "confirmation-floor order and eviction order are both `queue_rank`; `priority()` affects traversal only (the round-6 contradiction regression)." Directly targets the exact defect. |
| 4 | State an explicit arrival-rate assumption for the worked capacity example, or relabel its numeric conclusions as illustrative | **Nominally closed, but the closure introduces a new, genuine defect — see Correctness/Consistency/Calibration below.** `:234` now states: "assuming arrival ≤ 3 new candidates per trigger (one per distinct failing skill; the `n_trigger ≥ 3` filter makes higher sustained rates a pathology, not a norm)." This satisfies the *letter* of round 6's ask (an explicit assumption is now stated, replacing three silent rounds of an unstated one) — a genuine, real step the amendment had avoided since round 3 (R3-7). **But the assumption offered is not supported by, and appears to directly contradict, the amendment's own design and its own test** (see below) — this is not "still open," it is a new defect in what was offered as the fix. |
| Adv. | Round 5/6's adversarial finding: unbounded aging could produce an unbounded priority inversion at the confirmation-budget layer even if the occupancy layer is capped | **Closed, cleanly, as a direct consequence of item 1/2 above.** Since `queue_rank` (with its `min(·,A_cap)` term) is now the *only* formula ordering both queues, the algebraic bound proven in round 6 for the occupancy queue (a fresh candidate whose `gap_z` exceeds an aged candidate's by more than `A_cap` always outranks it — reverified below, Correctness) applies identically, by the same formula, to the confirmation-floor queue. The half-closure round 6 flagged is now a full closure. |

**Net for round 7: all 4 of round 6's numbered blocking items, and its adversarial finding, are addressed by name. 3 of the 4 (items 1–3, plus the adversarial finding as a corollary of items 1–2) are genuine, clean, verifiable closures — the best same-round closure rate this amendment has produced since round 1. Item 4 is addressed in the form round 6 demanded (an explicit assumption now exists) but the assumption's own stated justification is incorrect and appears to contradict the amendment's own test — a new defect, not a residual of the old one. See below.**

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 79 | weak |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 87 | pass |
| 4 | Implementability | 80 | pass |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 81 | pass |
| 7 | Completeness | 70 | weak |
| 8 | Consistency | 70 | weak |
| 9 | Calibration / honesty | 58 | weak |

## Findings by dimension

### 1. Correctness

- **The single-ordering-rule fix is algebraically sound and closes round 6's contradiction cleanly.** `queue_rank(c) = gap_z(c) + min(age(c), A_cap)` (`:230-232`) now governs both eviction (lowest `queue_rank` evicted, `:234`, "temporary eviction is by lowest `queue_rank`") and confirmation-floor allocation (`:228`, "in descending `queue_rank` until `b_conf` is exhausted"). Re-verified the priority-inversion bound directly: for a fresh candidate `f` (`age=0`) and an aged candidate `a`, `f` outranks `a` in *either* queue decision iff `gap_z(f) − gap_z(a) > min(age(a), A_cap)`; since `min(age(a),A_cap) ≤ A_cap = 3`, a fresh candidate whose `gap_z` exceeds an aged candidate's by more than 3 z-units always wins **both** the eviction comparison and the confirmation-floor comparison — because they are now literally the same comparison. No sign error, no scale mismatch.
- **New, load-bearing defect: the worked capacity example's arrival-rate assumption is not supported by, and appears to directly contradict, the amendment's own mechanism and its own test.** `:234`: "assuming arrival ≤ 3 new candidates per trigger (one per distinct failing skill; the `n_trigger ≥ 3` filter makes higher sustained rates a pathology, not a norm)." `n_trigger ≥ 3` (`BUILD-SPECS.md:187`, base B2 Mechanism 1) is a **per-skill re-triggering threshold** — it bounds how often the *same* skill `S` can re-enter diagnosis (it must re-accumulate 3 failures), but it says nothing about, and cannot bound, how many **candidate root gaps a single skill's own backward walk yields in one trigger**. That count is governed by branch fan-out and type coverage within one walk, which this very amendment was written to *widen*, not narrow: `:222` states "**the walk collects across both types — no type short-circuit**... **Edge type never drops a candidate:** a composite with both a weak constituent (`part_of`) and a more-severe independent prereq gap yields **both** as candidates" — and `test_both_types_reach_candidacy` (`:244`) is a regression test built specifically to guarantee that a **single failing skill, in a single trigger**, yields ≥2 candidates. A composite skill with three weak constituents plus an independent prereq gap yields 4 from one trigger under the amendment's own stated rule, with nothing capping it. So the claim "(one per distinct failing skill... higher sustained rates [are] a pathology, not a norm)" is not merely unproven — it is inconsistent with a design property (no type short-circuit, multi-candidate composite diagnosis) and a specific regression test this same amendment introduces and still lists. This is a genuine derivation/attribution error in a stated, numbered claim, not a stylistic nit — but its blast radius is narrow: no test encodes the false premise as a code invariant (`test_queue_bounded_under_sustained_arrival`, `:248`, is correctly unconditional on arrival composition), and the sentence's own final clause ("under adversarially higher arrival the guarantees degrade to the stated triage order, never to silent drops") is true and does not depend on the flawed assumption — the actual safety-relevant guarantee (`Q_max` + eviction + capped aging bounds the backlog and never silently drops a candidate, regardless of arrival rate) holds independently of whether the ≤3/trigger assumption is correct. Scored as a real but non-load-bearing Correctness defect, not a blocking one.
- All previously-verified formulas (`priority(e→P)`, `gap_z`, `queue_rank`, the `q_edge` Bernoulli re-admission latency `~1/q_edge`) remain unchanged and correct, reverified against round 6's algebra with no new discrepancy.

### 2. Design faithfulness

- The `queue_rank`/`priority` role split is, if anything, a *stronger* fit to the amendment's own founding provenance note (`:215`, "hardcoded traversal bias fossilizes") than round 6's version: separating "which edge is visited next" (a search heuristic, explicitly non-gating, `:227`) from "which candidate gets scarce confirmation budget" (a resource-allocation decision) is a cleaner instance of the "ranking-only, never gating" discipline the amendment has held itself to since round 1.
- Carried, non-blocking (unchanged since round 5): the `§19.1` `q_explore` citation at `:222` remains an imprecise analogy — `q_explore` is an isolated, non-decision-affecting shadow mechanism (`ALGORITHM-v0.2-pathway-learner.md:562`, "outcomes are recorded only"), while `q_edge` is a live, decision-affecting quota. `§5.3`'s `reachability_exploration`/R1's `ε_ret`, cited in the same sentence, are the accurate analogs.
- Carried, non-blocking (unchanged since round 2): `priority(e→P)`'s unweighted 1:1 additive combination has no `λ` analog of `§5.3`'s explicit, registered weight (`ALGORITHM-v0.2-pathway-learner.md:165`).
- Carried, non-blocking (unchanged since round 3): no explicit authoring-API sentence for Teacher-created `part_of`/`hard` edges; the Plug-point (`:237`) still only strongly implies the write path via `GraphStore.merge()`.

### 3. Red-team resistance

- **RC-4's closed-loop reopening remains genuinely closed** (soft floor + `q_edge`, unaffected by this round).
- **RC-1 (masking at candidacy/confirmation) remains closed** — `no type short-circuit` + `n_conf` floor + evidence-only expiry, unaffected.
- **The round-5/6 adversarial finding (unbounded aging → unbounded priority inversion) is now fully closed, not merely "substantially" closed as in round 6.** Because a single formula (`queue_rank`) now orders both the occupancy queue and the confirmation-floor queue, the `A_cap` bound proven for the occupancy queue in round 6 applies to both by construction — there is no longer a second, ungoverned queue where an old, moderate candidate could unboundedly outrank a far-more-severe fresh arrival. This closes the exact residual round 6's Strongest-adversarial-objection section named.
- **New, narrower residual:** the worked-example's flawed arrival assumption (Correctness, above) does not reopen any of the 8 root causes — the actual backlog-bound mechanism (`Q_max`+eviction+aging) is arrival-composition-independent by design, and the sentence's own fallback clause ("degrade... to triage, never silent drops") is correct regardless of whether the ≤3/trigger premise holds. This is scored under Correctness/Consistency/Calibration rather than Red-team because no failure mode from `ALGORITHM-v0.1-redteam.md` is reintroduced by it.
- RC-4 (mixed-type cycles, authored edges), RC-4 inverse (hard-edge density) — remain closed, unaffected.

### 4. Implementability

- **Genuine improvement:** a developer now implements exactly **one** comparator (`queue_rank`) for every queue decision, and a second, separate formula (`priority`) purely for traversal order — no ambiguity, no need to guess which governs which. This closes round 6's central implementability gap cleanly.
- **New, minor implementability wrinkle:** a developer sizing test fixtures or capacity-planning off the worked example's "≤3 candidates/trigger" assumption (Correctness, above) would build an assumption the amendment's own `test_both_types_reach_candidacy` contradicts — worth flagging so an implementer doesn't accidentally under-provision `b_conf`/`Q_max` test coverage for multi-candidate-per-skill scenarios. Non-blocking: no test currently encodes the flawed premise as a build target.
- Carried, non-blocking (unchanged since round 3): no explicit authoring-API sentence for Teacher-created edges.

### 5. Safety / integrity

- The §8 commit gate, §14 calibration layer, and the verifier (`HUMAN-LEARNING-VERIFIER.md`) remain untouched.
- Base B2's integrity hinge ("confirm before redirect + verify the redirect helped," `:211`) is unaffected by this round's edits — confirmation still gates every redirect regardless of which formula orders the confirmation queue or whether the worked example's arrival assumption is sound; the ordering only affects *when* a candidate is confirmed, never *whether*.
- No new gate weakening introduced. The single-ordering-rule fix, if anything, slightly strengthens the integrity story versus round 6, since it removes the ambiguity over whether an aged low-severity candidate could unboundedly monopolize the scarcer confirmation-budget resource ahead of a genuinely more urgent (more severe) one.

### 6. Efficiency / cost

- No new LLM calls. `queue_rank`'s consolidation is a pure refactor of existing O(1)-per-candidate bookkeeping (`gap_z` + capped `age`) into one comparator used in two places — no new asymptotic cost, unchanged from round 6's assessment.

### 7. Completeness

- **Genuine new coverage:** `test_one_ordering_rule_for_queues` (`:247`) targets exactly the round-6 contradiction and is well-scoped.
- **Still no test verifies the worked capacity example's numeric claims** ("drains at steady state," "waits ≈2 triggers"), and this round the underlying assumption offered to justify them is itself unsupported (Correctness, above) — a genuine completeness gap that is, if anything, more consequential than round 6's silent omission, because a wrong justification is now presented as settled rather than left open.
- No test exercises the amendment's own stated *contradiction case* directly — i.e., no fixture confirms what happens when a single trigger yields more than 3 candidates (the composite-with-multiple-weak-constituents scenario `test_both_types_reach_candidacy` already gestures at with 2), which is exactly the scenario the worked-example's arrival assumption dismisses as "a pathology, not a norm" without evidence.

### 8. Consistency

- **The round-6 internal contradiction (floor-allocation ordering) is fully resolved** — verified across all three previously-conflicting passages (`:228`'s lead sentence, `:234`'s eviction/expiry description, and `test_confirmation_floor_and_aging`'s updated description at `:246`), all now say the same thing.
- **A new internal inconsistency is introduced in its place, arguably more direct than the one it replaced.** `:234`'s "(one per distinct failing skill... higher sustained rates [are] a pathology, not a norm)" is in tension with `:222`'s "the walk collects across both types — no type short-circuit... Edge type never drops a candidate" and the amendment's own `test_both_types_reach_candidacy` (`:244`), which is a standing regression test asserting that ONE failing skill in ONE trigger yields ≥2 candidates by design. The two passages describe incompatible pictures of how many candidates one trigger can produce, within the same amendment, and unlike round 6's contradiction (which needed cross-referencing three separate passages to surface), this one is directly checkable by comparing one design bullet + one test name against one worked-example clause.
- `DATA-LAYER.md:76,141,213` citations remain accurate; the `q_explore`-analogy imprecision (Design faithfulness, above) recurs here as a minor, unchanged citation-accuracy issue.

### 9. Calibration / honesty

- **Genuine, substantial improvement on the specific pattern this review has tracked since round 2.** Round 6's floor-allocation-ordering overclaim/contradiction — a real instance of "the text asserts a fix with more precision than it delivers" — is, for the first time in this amendment's seven-round history, closed by a plain, single, unambiguous restatement (`:228`'s "two formulas, two disjoint jobs") rather than a partial reword or a relocation. This is the cleanest same-round resolution this series has produced.
- **But the meta-pattern itself has not stopped — it has recurred in a fifth location.** Round 2 (`weight`/`reach_weight` conflation), round 3 ("starvation-proof" framing), round 4 (`τ_traverse` "not a structural override"), round 5/6 (arrival-damping misattribution to `τ_traverse`/`q_edge` instead of `Q_max`) each showed "a cited mechanism is credited with a guarantee it does not actually provide." Round 7's `n_trigger≥3` arrival-assumption claim (Correctness/Consistency, above) is a new instance of the identical failure mode, one round after the *previous* instance of it was finally, genuinely fixed — this time crediting `n_trigger≥3` (a per-skill re-trigger threshold) with bounding intra-walk candidate fan-out, something it structurally cannot do and something the amendment's own test contradicts.
- **A partial, honest improvement within this same defect:** round 7 quietly drops round 5/6's more specific, equally unfounded numeric claim ("floor-allocated by its 4th trigger") rather than defending it further, and explicitly states the correct fallback behavior under a violated assumption ("degrade... to triage, never silent drops") — this is a genuinely more honest framing than rounds 5–6 offered for the same passage, even though the new premise it substitutes is itself unsound. Net assessment: real progress on honesty of framing, no progress on the underlying pattern of the specific claim being checked against the amendment's own contradicting evidence before being asserted.

## Strongest adversarial objection

Look at the *process*, not just this round's specific defect. Across seven rounds, this amendment has now produced five separate instances (rounds 2, 3, 4, 5/6, and 7) of the same species of error: a passage states, with apparent confidence, that mechanism X delivers guarantee Y, when a careful trace of X's actual definition shows it does not — and each time, the fix for the *previous* round's instance is delivered cleanly, only for a *new* instance to appear in the very passage being rewritten to close the old one. Round 6 fixed round 5's arrival-damping misattribution and, in doing so, introduced the floor-allocation-ordering contradiction that dominated round 6's report. Round 7 fixes that contradiction cleanly — and in the very same edit (rewriting the worked capacity example to add the arrival-rate assumption round 6 demanded), introduces a new misattribution of the identical species (crediting `n_trigger≥3` with bounding something it does not bound, contradicted by the amendment's own `test_both_types_reach_candidacy`). This is not "the amendment has a residual bug"; it is a demonstrated property of how this specific passage (`:228`/`:234`, the confirmation-budget/backlog paragraph) gets edited: every fix to it, so far, has introduced a new but different overclaim in the same paragraph. A reviewer who only checks "was round N's numbered item addressed" (as this review, `is by design, is required to do) will keep finding "yes, closed" indefinitely, one round at a time, without the paragraph as a whole ever converging to a version with zero live overclaims — because the fixing process appears to trade one unexamined claim for another rather than deriving the passage from first principles once. The concrete, checkable version of this objection for round 7: the ≤3/trigger assumption should be either (a) derived from an actual structural bound this amendment states elsewhere (there is none — `d_max` bounds depth, not per-trigger candidate count; the base `n_trigger` bounds skill-level re-entry, not intra-walk fan-out), or (b) explicitly acknowledged as unbounded, with the worked example relabeled as depending on a stipulated, not derived, arrival rate. Neither is done — the assumption is presented as *justified* ("attributed... to the `n_trigger≥3` filter") when it demonstrably is not, in the same rhetorical register the last four rounds' now-fixed overclaims used. This is not raised in full in any of the nine dimensions above (Correctness/Consistency/Calibration each note the textual/mechanism-level defect; this is the compound, cross-round-process-level observation that the paragraph's editing history itself is evidence the closure loop for this specific paragraph has not yet terminated).

## Aggregate confidence

```
critical_floor  = min(Correctness=79, RedTeam=87, Safety=85) = 79
weighted_mean   = (79*2 + 80 + 87*2 + 80 + 85*2 + 81 + 70 + 70 + 58) / 11
                = (158 + 80 + 174 + 80 + 170 + 81 + 70 + 70 + 58) / 11
                = 941 / 11
                = 85.5 → 86
overall         = min(79, 86) = 79
```

**Overall confidence: 79 / 100**

## Verdict

**needs-revision**

Round 7 delivered the cleanest same-round closure rate this amendment has produced in seven rounds: all 4 of round 6's numbered blocking items are addressed, and 3 of the 4 — plus the round-5/6 adversarial finding as a direct corollary — are genuine, algebraically-verified, unambiguous closures. The floor-allocation-ordering contradiction that dominated round 6's report is resolved with a single explicit rule (`priority()` for traversal, `queue_rank()` for every queue decision), a matching Parameters-line consolidation, and a dedicated regression test (`test_one_ordering_rule_for_queues`). All three CRITICAL dimensions clear 70 (79/87/85).

The score does not clear 80 because round 7's fix for round 6's fourth item — stating an explicit arrival-rate assumption for the worked capacity example — introduces a new, genuine defect rather than a clean closure: the stated justification ("`n_trigger≥3` filter makes higher sustained rates a pathology, not a norm") misattributes a per-skill re-triggering threshold as a bound on intra-walk candidate fan-out, which it structurally cannot provide, and which the amendment's own design principle ("no type short-circuit... edge type never drops a candidate," `:222`) and its own regression test (`test_both_types_reach_candidacy`, `:244`) directly contradict by construction (one skill, one trigger, ≥2 candidates already demonstrated). This is the fifth instance across seven rounds of the same "cited mechanism credited with a guarantee it doesn't deliver" pattern this review has tracked since round 2 — each instance closed cleanly the following round, only for a new instance to appear in the same edit. The actual safety-critical guarantee (`Q_max` + eviction + capped `age` bounds the backlog and degrades to triage, never silent drops, under any arrival composition) does not depend on the flawed assumption and remains sound — which is why this does not reopen any of the three CRITICAL dimensions below 70. Specific blocking changes required to clear 80:

1. **Fix or retract the worked capacity example's arrival-rate justification (`:234`).** Either derive the `≤3 new candidates per trigger` bound from an actual structural property of the amendment (none currently exists — `d_max` bounds depth, not per-trigger candidate count; `n_trigger≥3` bounds skill-level re-entry, not intra-walk fan-out), or explicitly relabel the arithmetic as a stipulated illustrative scenario rather than one "attributed" to `n_trigger≥3`.
2. **Resolve the direct contradiction between `:234`'s "one [candidate] per distinct failing skill" framing and `:222`'s "no type short-circuit... edge type never drops a candidate" design principle, corroborated by `test_both_types_reach_candidacy`.** These cannot both be true of the same mechanism; state which one governs.
3. **If the ≤3/trigger assumption is retracted or relabeled, confirm (or add a note conceding) that the worked example's downstream numeric claims ("drains at steady state," "waits ≈2 triggers") are illustrative only** — the load-bearing safety guarantee (bounded backlog + triage-not-silent-drops under any arrival) does not require them to be true, and the text should not imply otherwise.
