# 360 Review: S20-10-learning-liveness — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20.10 "Learning liveness — detecting absence, not just harm" (lines 647-669), plus its §12 parameter registration (line 286) |
| Proposed change | Add a JUDGE-side, observation-only absence-detection layer (LIV-1 + JMP-1): three signals (evidence/pinned-fraction, progress, structure), computed at each cycle digest, feeding a three-state (converged / stalled / absorbed-anomaly) distinguisher over zero-progress windows, delivered per §20.7's contract, touching no gate/selection/tier mechanism |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Proceeding as a normal (committable) review, not a proposal.

## Scope note

Per instruction, the working tree also carries an independent, unrelated uncommitted delta to `docs/research/DATA-LAYER.md` (§6.3 structural constraint table + its §5/§6.1 lines) and a new untracked `docs/research/IMPL-PROTOCOL.md`. Neither is part of this review; §6.3 already has its own in-flight review (`DL-constraint-table-review.md`, EV-113). This report scores only §20.10 against the DATA-LAYER baseline as of the *last commit* (§1–§12 through the approved §12 Conformance checker), not against the uncommitted §6.3 delta.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 70 | weak |
| 2 | Design faithfulness | 88 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 78 | weak |
| 5 | Safety / integrity (CRITICAL) | 88 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 68 | weak |
| 8 | Consistency | 74 | weak |
| 9 | Calibration / honesty | 80 | pass |

## Findings by dimension

### 1. Correctness

The three-state partition logic and the evaluation mechanics for the **evidence** and **progress** signals are correct as written:

- The competence×anomaly partition (line 661-664) is genuinely disjoint and exhaustive over the 2×2 space `{competence high, low} × {anomaly, no anomaly}`: state 1 = (high, no), state 3 = (high, yes), state 2 = catch-all for `¬high` regardless of anomaly. Both `{low, no}` and `{low, anomaly}` correctly collapse to state 2 without losing the anomaly signal, because the `τ_absorb` breach is independently always-delivered "at every evaluation, not only at zero progress" (line 659) — so a low-competence-and-anomalous cell still surfaces via the standalone anomaly alert even though its zero-progress window classifies as "stalled," not a third bucket. This is correctly reasoned, not merely asserted.
- `w_live ≥ k` is stated as a checked startup precondition (line 659), correctly avoiding a divide-by-zero/undersized-window class of bug.
- The pinned-fraction and progress-signal definitions reuse `n_min` (§3) and `significant()`/`k` (§2) exactly as declared, with no new statistic invented.

Two concrete inaccuracies, however, sit under the **structure signal** and the **anomaly (Vulcan-state) check** — the two least-verified but still load-bearing parts of the section:

- **Mis-citation on edge renewal (line 657):** "edges renewed by **intervention** evidence (§5.2's renewal — the causal channel, not co-occurrence)." §5.2 (ALGORITHM-v0.2-pathway-learner.md:143-156) is entirely about `reach_weight` and the *retrieval reranker* credit assignment (`update_w`, leave-one-out credit, `l1_decay` — "passive co-occurrence decays out" refers to retrieval weights, not prereq edges). Nothing in §5.2 discusses prereq-edge renewal. The only prereq-edge-renewal language in the whole spec is the unelaborated code comment at §5.1 line 133: `g.decay_edges() # prereq-edge confidence decays unless intervention evidence renews it` — which defines no distinction between "intervention" (causal) and "co-occurrence" evidence for edges at all. §20.10 imports a causal-vs-co-occurrence distinction that exists (for a *different* object, retrieval weights) in §5.2, cites it as if it applies to edge confidence, and treats "intervention evidence" as an already-operationalized, countable class of edge-renewal event when the base spec has never defined how a renewal event would be tagged as "interventional" vs. anything else. `GraphDelta.edge_updates: [(edge_id, confidence)]` (DATA-LAYER.md:223) carries no cause/type field to make this distinction from truth even in principle.
- **Absorbed-failure-rate ↔ `coherent_with` linkage is asserted, not shown (lines 649, 664, 668):** the section claims the per-cell absorbed-failure rate is "derivable from which posterior each failure record updated — no new logging" and that it "computes from existing failure-record → posterior-update keys; no new record kind exists" (`test_absorbed_rate_derivable_from_evidence_keys`). But `g.step`'s `attribute(traj, s*)` call (§5.1, ALGORITHM-v0.2-pathway-learner.md:121) — the mechanism that actually performs `coherent_with`-absorption — is pseudocode with no specified persistence: it is not evident whether "attribute" writes any record that lets a later reader distinguish "this cell's failure came from its own eval suite" from "this cell's failure was funneled in via wrong-cell absorption from `g.step`'s clustering pass." The `evals` table (DATA-LAYER.md:146) is scoped per `(skill, difficulty, item_ids)` and reports aggregate `n_pass/n_total`, which gives an ordinary per-skill failure rate trivially — but that is a *different, weaker* quantity than the `coherent_with`-absorption-specific rate the Vulcan-state narrative (line 664, citing `STUDY-llms-cant-jump.md` H1) is actually about. As written it is unclear whether the implementation would end up computing plain within-skill failure rate (available today, but not a Vulcan-pattern detector) or the absorption-specific rate (the intended signal, but not shown to be recoverable from any named field).

Neither issue touches a formula sign, a gate, or a decision path — both are citation/definitional gaps in the two data-derivation claims underpinning state 3 and the standalone `τ_absorb` alert, which are two of the section's three delivery-consequential outputs. Fixable with one clarifying paragraph each, but as submitted the "zero schema delta, recomputable from truth" claim (the section's own headline property, restated three times) is not demonstrated for these two sub-components. Scored at the acceptable/weak boundary rather than blocking, because the core three-signal architecture, the partition, and the evidence/progress signals are correct and the errors are local and non-gating.

### 2. Design faithfulness

Strong conformance to established conventions: additive placement under §20 (explicitly modeled on the §17.6-under-§17 precedent, line 649), JUDGE-side ownership stated (§20.1, line 659), reuse rather than duplication of `significant()`/`k`/`θ` (§2/§5.3), and the delivery classes map cleanly onto §20.7's existing always-delivered/suppressible taxonomy rather than inventing a parallel one. The section correctly identifies and generalizes §20.4's sustained-deferral alert (line 651) rather than treating it as unrelated — good architectural continuity. Docked modestly for the §5.2 mis-citation (dimension 1), which is itself a design-faithfulness lapse (citing the wrong mechanism as the basis for a new one) as well as a correctness defect.

### 3. Red-team resistance

Reads `docs/research/ALGORITHM-v0.1-redteam.md`'s eight root causes; none is reopened:

- **RC-1** (point estimates as gates): not applicable — the section gates nothing; where a statistical test is used (progress signal, `τ_absorb` trend) it correctly reuses `significant()`.
- **RC-2/RC-3** (gameable verifier / unscorable growth): not touched — no new verifier or provisioning path.
- **RC-4** (wrong-cell absorption, add-only ratchet): the section explicitly does *not* fix `coherent_with`'s known similarity-bound residual (already declared in `STUDY-llms-cant-jump.md` H1 and echoed in the RC-4 discussion) — it attempts to add visibility into it (state 3). It neither weakens the existing bound nor claims to close it, which is the honest framing. However, per Correctness finding 2 above, the visibility mechanism itself is not demonstrated to be computable as specified, which weakens (without reopening) the residual's mitigation value.
- **RC-5/RC-7** (decay masking, coverage floor): the pinned-fraction signal is explicitly framed as observing `n_min`'s known side effect (line 655) — this is squarely aligned with, not contradicting, the RC-5 fix; the coverage-floor set is used only as a read (line 661), never overridden, and `test_no_signal_touches_selection_or_gates` / `test_tier_posture_never_defers_coverage_floor` (pre-existing) jointly cover this.
- **RC-6/RC-8**: not applicable (no tree-value or promotion interaction).

No mechanism is weakened and no CRITICAL failure mode is reintroduced. Docked from a clean 90+ to 80 for two reasons not covered by the nine RCs directly but germane to red-team posture: (a) the `τ_absorb` breach alert has no stated debounce (see Completeness, and the Adversarial pass below) — an under-specified always-delivered channel that can be desensitized by volume is a soft precursor to the exact "looks alive, alarm ignored" pattern §20 exists to prevent; (b) the two Correctness gaps mean the section's flagship defense against a *named* residual attack surface (wrong-cell absorption) is asserted rather than demonstrated.

### 4. Implementability

Owner, cadence, and units are stated once and clearly (line 659: supervisor, JUDGE-side, per-cycle digest, `w_live` in cycles). Parameters (`w_live`, `τ_pin`, `τ_absorb`) are registered consistently in both the §20.10 preamble and the central §12 parameter line (line 286) — grep-verified, no drift between the two locations (this is exactly the class of defect `skills/spec-change-gate/SKILL.md`'s pre-submission checklist targets, and here it is done correctly). Eleven test stubs are named (line 668) covering fire-tests, exhaustiveness, and the surfacing-only property.

Gaps that would leave a developer guessing:
- No concrete algorithm is given for tallying "growth events per `w_live`" (event-count vs. replay-and-diff of the GraphStore projection at window boundaries — both are truth-derivable in principle via PR-7, but the section doesn't say which, and they have different implementation and cost profiles).
- No debounce/repeat-suppression rule for the standalone `τ_absorb` breach alert (contrast with §20.4's explicit `w_defer`/`n_defer` windowing for a structurally similar always-delivered condition).
- No stated handling for a degenerate/empty §5.3 coverage-floor set (see Completeness).

### 5. Safety / integrity

Clean. The section is explicitly and testably surfacing-only: `test_no_signal_touches_selection_or_gates` asserts `π`, `§8/§19` gate outcomes, and tier posture are bit-identical under maximally adverse signals (line 668). §14/§19.6's breakers are explicitly stated as untouched (line 666). No calibration-layer (§14) or verifier (`HUMAN-LEARNING-VERIFIER.md` is not implicated; this section is agent/execution-side liveness, not the human verifier) interaction exists. Docked from 92 to 88 only for the indirect, non-gate concern that an unbounded-volume `τ_absorb` channel risks degrading the human-in-the-loop response to real alerts over time (alarm fatigue is a safety-adjacent, not merely a UX, concern in an unattended-operation context) — soft, not a weakened gate.

### 6. Efficiency / cost

No new LLM calls. All three signals are computed cold-path, at the cycle digest step (line 659), off the §6 hot decision path — consistent with §20's own two-level-loop discipline. Per-cycle cost is bounded by live-cell count (evidence/progress signals) and by window-scoped growth-event volume (structure signal); no O(n²) addition to any hot path is introduced. Minor: unlike several sibling additions (e.g., §18.2's explicit "Cost (O(1), not O(N²))" callout), §20.10 states no complexity bound explicitly — a one-line statement would remove any ambiguity, particularly since the unspecified structure-signal computation method (event-tally vs. replay-diff) has different costs.

### 7. Completeness

Several distinct, concrete gaps, each independently minor but collectively below the "acceptable" bar:

- **Empty/near-empty coverage-floor set (raised in the task's adversarial angles):** the competence predicate is "`ĉ ≥ θ` across the §5.3 coverage-floor set" (line 661). If the floor set is empty (e.g., a fresh deployment before any skill is admitted `live`, or a growth-off configuration with a not-yet-populated skill set), this is a vacuous conjunction — trivially true — which would classify a learner that has done *nothing* as "Converged" (state 1, a suppressible report) on its very first eligible window. The section states the `w_live ≥ k` startup precondition but not an analogous `|floor set| > 0` precondition.
- **Cold-start vs. starved cells in the pinned-fraction signal:** a cell newly admitted mid-window has `n_eff` at (or near) the cold-start prior, indistinguishable in the stated definition from a cell whose evidence has genuinely dried up after a period of activity. The fire-test `test_pinned_fraction_counts_floor_cells` (line 668) only asserts the boundary at `n_min` itself, not this distinction.
- **No debounce on the `τ_absorb` breach alert** (see Implementability and the Adversarial pass) — asymmetric with `τ_pin`'s persistence-over-window design and §20.4's `w_defer`/`n_defer` windowing.
- **No explicit test strategy for the two under-specified derivations** (structure-signal edge-renewal counting; absorbed-failure-rate computation) beyond the general `test_signals_truth_derivable` / `test_absorbed_rate_derivable_from_evidence_keys` names, which assert the *property* without the report being able to verify the *mechanism* exists as claimed (see Correctness).

### 8. Consistency

Mostly consistent with the surrounding spec: the §12 parameter registration line and the §20.10 preamble agree verbatim on the three new parameters and their reuse of `k`/`θ` (no drift found by grep); the "§11's `score` rows as an optional convenience mirror, never a dependency" claim (line 649) accurately matches DATA-LAYER.md §11.3's "Canonical-record rule" (score() mirrors an existing Truth record for legibility; Truth remains canonical); the blanket "PR-1–PR-9 all preserved" property-impact statement follows the exact pattern used and already accepted for DATA-LAYER §12 (its own "PR-1–PR-9 preserved — no property statement, mechanism, or guard is touched" line), so this is not scored as a defect. The one real inconsistency is the §5.2 mis-citation (Correctness finding 1) — a direct contradiction between what §20.10 asserts about §5.2's content and what §5.2 actually contains, which is precisely the failure class (`skills/spec-change-gate/SKILL.md`'s pre-submission checklist, L-013) this project's own process exists to catch before submission.

### 9. Calibration / honesty

Generally honest: the section states plainly what it is not ("What this section deliberately is not: a breaker," line 666), correctly scopes itself against a named residual (RC-4/`coherent_with`, citing `STUDY-llms-cant-jump.md` H1 rather than overclaiming a fix), and does not claim to add a new PR-10 safety property (appropriately, since these are alerts, not invariants — consistent with §21.3's admission discipline). The "zero schema delta ... recomputable from truth" claim, however, is stated with more confidence than the underlying mechanisms (edge-renewal-by-intervention, absorbed-failure-rate) currently support (Correctness findings 1-2) — a real, if narrow, overclaim relative to the section's own evidentiary standard elsewhere.

## Strongest adversarial objection

This section exists to prevent exactly one failure class: a mechanism that looks operational but is not actually wired to fire (`STUDY-automaton-autonomy.md` A2, "shipped-but-inert observability" — cited as §20's own founding provenance, line 597, and echoed in §20.6's "a metric read by an alarm but never written anywhere is a build failure"). The section's own two most novel, most load-bearing outputs — the structure signal's "intervention-evidence" edge-renewal count and the absorbed-failure-rate that drives state 3 (the Vulcan alert) — are asserted to be truth-derivable but, on inspection, rest on a citation to a section (§5.2) that does not define what is claimed, and on an unspecified persistence contract inside `g.step`'s `attribute()` call respectively. If an implementer builds §20.10 literally as written, the two most interesting always-delivered alerts in the section (the standalone `τ_absorb` breach, and state 3) are at meaningful risk of either (a) never firing correctly, because the data they need was never actually logged with the required distinction, or (b) firing on a substitute quantity (plain within-skill failure rate) that doesn't detect what the section claims to detect (a *collectively patterned*, individually-coherent absorption signature, not a garden-variety high-failure skill). That would reproduce, inside the very mechanism written to catch "shipped-but-inert" alarms, the identical failure mode one level up — an ironic, and testably-avoidable, outcome if the two derivations are pinned down before this ships.

## Aggregate confidence

```
critical_floor  = min(70, 80, 88) = 70
weighted_mean   = (70*2 + 88 + 80*2 + 78 + 88*2 + 85 + 68 + 74 + 80) / 11
                = (140 + 88 + 160 + 78 + 176 + 85 + 68 + 74 + 80) / 11
                = 949 / 11
                = 86.27 → 86
overall         = min(70, 86) = 70
```

**Overall confidence: 70 / 100**

## Verdict

**needs-revision**

Overall confidence (70) is below the 80 bar (the automatic-revision rule triggers on this alone; no CRITICAL dimension is individually below 70, so the critical-dimension rule is not independently triggered, but both rules point the same direction here).

Blocking changes required to clear 80:

1. **Fix or retract the §5.2 citation for edge renewal (line 657).** Either define, in §5.1 (where `g.decay_edges()` actually lives), what makes a renewal event "interventional" as opposed to any other positive edge evidence, concretely enough that it is a truth-derivable distinction — or drop the "causal channel, not co-occurrence" framing and restate the structure signal's edge-renewal component using only what the base spec actually supports (a plain edge-confidence-increase count from `GraphDelta.edge_updates`).
2. **Demonstrate the absorbed-failure-rate ↔ `coherent_with` linkage concretely.** State exactly which existing field/record lets a reader compute, per cell, the rate of failures that were `coherent_with`-absorbed from elsewhere (as opposed to the cell's own native eval failures) — or honestly narrow the state-3 trigger to what is actually computable today (ordinary within-skill failure-rate trend), and adjust the Vulcan-pattern narrative and `test_absorbed_rate_derivable_from_evidence_keys`'s claim accordingly.
3. **Add a debounce/repeat-suppression rule for the standalone `τ_absorb` breach alert**, analogous to §20.4's `w_defer`/`n_defer` windowing, so a persistently-anomalous cell does not re-fire the always-delivered channel on every cycle-digest.
4. **State the competence predicate's behavior for a degenerate coverage-floor set** (empty or near-empty §5.3 floor set) — add an explicit precondition (alongside the already-stated `w_live ≥ k`) so a fresh or growth-off-before-first-admission deployment is not vacuously classified "Converged."

Recommended, not blocking: name the intended computation strategy (event-tally vs. truth-replay-and-diff) for the structure signal's "skills added/pruned" tally, and distinguish cold-start-never-evaluated cells from genuinely-starved cells in the pinned-fraction fire-test.
