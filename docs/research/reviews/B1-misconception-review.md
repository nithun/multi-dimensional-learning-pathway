# 360 Review: B1-misconception — 2026-06-26 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` §"B1 · Misconception clustering → graph-linked remediation" |
| Proposed change | Round-3 revision: (1) minimum arm size ≥ 20 per side added as pre-condition for the lift gate; (2) lift-gate `z` relaxed to **1.0** (so small-cohort moderate misconceptions are not silently rejected); (3) lift estimated on the **§4 held-out split** (explicit item-split provenance); (4) retirement window defaulted to **50 evals**. |
| Reviewer | review-360 |
| Date | 2026-06-26 |
| Round | 3 (Round 1: 65/100 needs-revision · Round 2: 78/100 needs-revision) |

---

## Round-3 scope

Round 2 identified three blocking items plus one structural adversarial objection (arm-size imbalance), all now addressed:

- **Blocker 1 (adversarial — arm-size / z-value):** minimum arm size ≥ 20 per side now stated; lift-gate `z` explicitly set to **1.0** (relaxed from the §2 default of 2), with the rationale that §14 calibration governs confidence and a small-cohort moderate misconception should not be silently rejected by a tight z-bar.
- **Blocker 2 (RC-2 item split, Findings 3.4 / 5.4):** "lift is estimated on the **§4 held-out split**" is now stated explicitly in step 3.
- **Blocker 3 (retirement window default, Finding 4.2):** "retirement window (50 evals)" now in the Parameters table.
- **Blocker 4 (τ_merge scope, Finding 2.2):** *(see Finding 2.2 below — this one remains partially unresolved but at reduced severity).*

This review re-scores all nine dimensions from scratch against the revised text and re-runs the adversarial pass.

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 87 | pass |
| 2 | Design faithfulness | 85 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 76 | pass |
| 5 | Safety / integrity (CRITICAL) | 86 | pass |
| 6 | Efficiency / cost | 77 | pass |
| 7 | Completeness | 78 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 78 | pass |

---

## Findings by dimension

### 1. Correctness

**Score: 87 — pass. The three round-2 correctness residuals are resolved or downgraded. No new correctness errors found.**

**Finding 1.1 — Arm-size floor resolves the near-vacuous-SE problem (adversarial objection resolved).**
`BUILD-SPECS.md` step 3: "minimum arm size ≥ 20 per side." At n=20 with p≈0.6, SE(p̂) ≈ sqrt(0.6·0.4/20) ≈ 0.110; SE_lift ≈ sqrt(0.110² + 0.110²) ≈ 0.155. With z=1.0, the gate bar is `lift > 0.2 + 1.0·0.155 = 0.355`. That is a plausible bar for a moderate misconception: the asymptotic Normal approximation for a proportion test holds reasonably at n=20 (the standard rule-of-thumb is np ≥ 5 and n(1−p) ≥ 5; both satisfied here). The arm-size floor makes the z=1.0 gate computable and non-vacuous.

**Finding 1.2 — z=1.0 override rationale is sound but requires the §14 dependency to be load-bearing.**
The spec relaxes z from the §2 default of 2 to 1.0 with the justification that "§14 calibrates." This is a design judgment, not a correctness error. Its validity depends on §14 actually being live at the point B1 admission runs — if B1 is deployed before §14 is operational, the z=1.0 gate has no calibration backstop. The spec is silent on this ordering dependency. It is a completeness concern (Dimension 7), not a correctness error, but it is noted here as load-bearing.

**Finding 1.3 — SE_lift estimator is now implicitly defined by the arm-size floor (adequate).**
With n₁ ≥ 20 and n₂ ≥ 20, the standard two-proportion SE formula `sqrt(p̂₁(1−p̂₁)/n₁ + p̂₂(1−p̂₂)/n₂)` is the natural and only reasonable estimator. The spec does not state this formula but the floor makes the derivation unambiguous. A developer can implement this correctly. This is acceptable for a spec of this level of detail.

**Finding 1.4 — `τ_coh` aggregate type still undefined (non-blocking residual from round 1).**
The Parameters table lists "`τ_coh` coherence" with no default and no statement of whether it is a mean-pairwise, min-pairwise, or silhouette-based aggregate. This makes `test_recurring_error_clustered_and_named` under-specified at the cluster-coherence check. It does not affect the admission gate correctness (which is now well-specified) but remains a developer uncertainty. It is a weak, non-blocking concern.

---

### 2. Design faithfulness

**Score: 85 — pass. The retirement step correctly mirrors §5.1; the τ_merge scope ambiguity is partially reduced.**

**Finding 2.1 — Step 6 remains consistent with §5.1's add-with-inverse discipline.**
Unchanged from round 2: the retire/merge pattern mirrors `g.prune_orphans()` + `g.maybe_merge()` exactly. The explicit labeling ("Same add-with-inverse discipline as §5.1 skills — no add-only ratchet") is design-faithful.

**Finding 2.2 — τ_merge scope still not stated, but the severity is reduced.**
Round-2 Blocker 4 asked for a statement of whether τ_merge in step 6 is the §5.1 global parameter or a B1-specific one. The revised spec still does not state this. However, the Parameters table now lists `τ_merge duplicate-merge cosine` without a default, which is consistent with either interpretation. The ambiguity remains — a developer building the `Misconception` component cannot determine from the spec whether to use the §5.1 `τ_merge` value or define a new one. This is a weak finding (one sentence in the spec would resolve it) but does not block implementation since the question has a small, bounded answer space.

**Finding 2.3 — GraphStore `misconception→prereq` edge type still not in DATA-LAYER.md §5 schema.**
Carried from rounds 1 and 2. `DATA-LAYER.md` §5 Graph schema lists: `nodes {skill, status: live|pending_human, suite_ref}`; edges `prereq{weight, confidence}`, `transition{visits, value}`; `mcts{node, visits, value, checkpoint_gen}`. A `misconception→prereq` edge type is not present. Step 4 of B1 writes one. This schema gap is a consistency concern (Dimension 8) handled there, but the design point is that the `GraphStore.add_skill` interface as specified (`add_skill(s, prereqs, *, status)`) does not expose a path to add a `misconception` edge — B1 needs either a new `add_misconception_edge()` method on `GraphStore` or a `kind` discriminator. The plug-point paragraph still does not mention this. It is non-blocking (a small interface extension) but a genuine design-faithfulness gap.

---

### 3. Red-team resistance

**Score: 82 — pass. The round-2 RC-2 item-split gap is now resolved. The incremental coherence degradation concern is the main residual.**

**Finding 3.1 — RC-2 item-split gap resolved.**
Step 3 now reads: "lift = P(err|M-flagged) − P(err|¬) on the **§4 held-out split**." This closes the round-2 Finding 3.4 / 5.4 gap. The lift gate can no longer be inflated by public-item overlap. This is the most significant red-team improvement in round 3.

**Finding 3.2 — RC-1 gate remains correct; z=1.0 is a calibrated relaxation, not a regression.**
The gate form `significant(lift − ρ_M, SE_lift)` with explicit z=1.0 and arm-size floor ≥ 20 remains a genuine statistical test against its own standard error. The z relaxation is a tuning choice, not a removal of the RC-1 fix. RC-1 is not reintroduced.

**Finding 3.3 — RC-4 retirement mechanism: retirement window (50 evals) is now defaulted.**
The retirement window "50 evals" gives the mechanism a concrete trigger cadence. A misconception is now evaluated for retirement every 50 error evaluations. This is implementable. The round-2 concern that the retirement mechanism was unimplementable is resolved.

**Finding 3.4 — Incremental coherence degradation: partially addressed, not fully closed (residual).**
Round-2 Finding 3.3: a growing cluster that absorbs off-target traces can degrade coherence without triggering the lift-based retirement condition. This is not addressed in round 3. The retirement condition remains lift-based ("lift decays below ρ_M significantly"), not coherence-based. A misconception cluster can silently deteriorate in semantic precision while its aggregate lift stays above ρ_M. This is a residual attack surface at reduced severity — the lift gate still provides a meaningful filter, and the 50-eval cadence means re-evaluation is regular. It does not block approval at this stage but is flagged as a known open risk.

**Finding 3.5 — No new RC openings.**
The relaxation of z to 1.0 and the addition of the arm-size floor do not open any new failure modes. Specifically: (a) the z=1.0 gate still rejects clusters whose lift does not clear its own SE, so RC-1 is not reintroduced; (b) the arm-size floor is a pre-condition that prevents the gate from firing on insufficient data rather than a softening of the gate itself.

---

### 4. Implementability

**Score: 76 — pass. Three of the five round-2 implementability gaps are resolved; two non-blocking ones remain.**

**Finding 4.1 — Retirement window default (50 evals) resolves Finding 4.2.**
The Parameters table now reads "retirement window (50 evals)." A developer knows to re-evaluate each admitted misconception every 50 incoming error traces. The round-2 blocker is resolved.

**Finding 4.2 — Arm-size floor and z=1.0 resolve the gate parameterization gaps.**
The minimum arm size ≥ 20 and z=1.0 are now explicit parameters. A developer can implement the gate without deriving the threshold from first principles.

**Finding 4.3 — Held-out split provenance resolves the item-split ambiguity.**
"on the §4 held-out split" in step 3 tells the developer exactly which item set to use for lift estimation. Round-2 Finding 4.4 (item split ambiguity) is resolved.

**Finding 4.4 — Plug-point still not a file:line specification (non-blocking residual).**
Round-2 Finding 4.3 is unresolved: the plug-point is still "A `Misconception` component over `VectorStore` + `GraphStore` + the Tutor + `EvalHarness`." Compare A1 (`mdlp/decision.py :: DecisionEngine.choose`) and A5 (`mdlp/state.py :: ProbabilisticState.cell()`). A developer exploring the turing-agents codebase must discover the entry point. This is a minor friction point; the component-list description is sufficient for spec-level work.

**Finding 4.5 — `τ_coh` default still absent (non-blocking residual).**
Noted in Correctness 1.4. Blocks the `test_recurring_error_clustered_and_named` test from being written with a concrete threshold; a developer will need to pick a value (e.g. 0.75). This is weak and non-blocking.

**Finding 4.6 — Retirement "active or suspended?" edge case now partially implied by the 50-eval cadence.**
Round-2 Finding 7.3 asked: is an under-evaluation misconception still active (routing learners) during its retirement evaluation window? The 50-eval cadence implies misconceptions remain active until explicitly pruned, but the spec does not say so. A sentence ("a misconception remains active until pruned") would close this.

---

### 5. Safety / integrity

**Score: 86 — pass. RC-2 split closure strengthens the admission gate. No gate weakening anywhere in round 3.**

**Finding 5.1 — §4 held-out split on lift estimation significantly strengthens the admission gate.**
This is the most important safety improvement in round 3. Previously, a spurious misconception could achieve an inflated lift estimate by using items the learner had been exposed to during instruction. Locking lift estimation to the §4 held-out split eliminates this path. The admission gate is now as independent of the optimization path as the main commit gate (§8).

**Finding 5.2 — §8 commit gate for remediation preservation unchanged.**
Step 5: "kept only if the held-out error rate on M-items drops (the commit gate §8)." No change. Intact.

**Finding 5.3 — z=1.0 relaxation is calibrated, not a safety weakening.**
A lower z admits more misconceptions at a higher false-positive rate. This is a precision-recall trade-off, not a safety failure, because: (a) a false positive misconception that does not actually predict future errors will be retired after 50 evals when its lift fails the retirement gate; (b) §14 calibration monitors over-confident admission; (c) the §8 commit gate still governs whether a remediation Teacher is kept. The retirement mechanism provides the self-correcting inverse that makes z=1.0 safe.

**Finding 5.4 — Ordering dependency on §14 (implicit, non-blocking).**
Noted in Correctness 1.2: z=1.0 is justified in part by §14 calibration being live. If B1 is deployed without §14 operational, the calibration backstop is absent. The spec implicitly assumes the full system stack is deployed together. This is a deployment concern, not a spec error.

**Finding 5.5 — No `pending_human` analog for pre-statistical misconceptions (carried residual).**
Round-2 Finding 5.3: a cluster that clears N_min and τ_coh but cannot yet satisfy the arm-size pre-condition (< 20 M-flagged learners) is silently discarded rather than queued. The `pending_human` discipline from §5.1 is not applied. This is conservative (discarding is safer than admitting) but loses information. Non-blocking.

---

### 6. Efficiency / cost

**Score: 77 — pass. No new hot-path costs; retirement cadence now bounded.**

**Finding 6.1 — Retirement cadence (50 evals) bounds the cold-path re-evaluation cost.**
Each misconception is re-evaluated every 50 error traces. At any given time the cold-path cost is O(M · cost_of_lift_estimation) per 50-eval batch where M is the number of admitted misconceptions. This is a bounded, predictable cost profile. The round-2 concern about unbounded retirement re-evaluation cadence is resolved.

**Finding 6.2 — Per-attempt embedding cost still unacknowledged (carried).**
Round-2 Finding 6.3: every incorrect attempt triggers an embedding call. The spec still does not acknowledge this cost. At scale with a large cohort this is a continuous stream of embedding calls. This is a known cost driver that should be noted in Honest risks. Non-blocking.

**Finding 6.3 — No additional hot-path costs introduced.**
The round-3 changes (arm-size pre-condition, z=1.0, held-out split, retirement window) are all cold-path admission and retirement checks. No new hot-path operations are added. Efficiency is maintained.

---

### 7. Completeness

**Score: 78 — pass. Retirement default and arm-size floor fill two major gaps; several minor residuals remain.**

**Finding 7.1 — Retirement window default fills the "unimplementable retirement" gap.**
Round-2 Finding 4.2 is resolved. "Retirement window (50 evals)" is a concrete default. The `test_stale_misconception_retired` test is now fully specifiable.

**Finding 7.2 — Three round-2 missing tests are still absent.**
Round-2 Finding 7.2 identified:
- `test_cluster_does_not_absorb_off_target_errors` — still not present.
- A targeted gate test (`test_lift_gate_marginal_high_se_rejected`) verifying that a marginal cluster with high SE fails while a low-SE cluster at the same nominal lift passes — still not present. (The existing `test_noise_errors_rejected` exercises the gate but does not explicitly verify the SE-sensitivity of the gate at a fixed nominal lift value.)
- `test_no_misconception_path_without_signal` — still not present.
These are non-blocking for approval (the existing test suite is adequate for the critical paths) but would improve confidence in the gate behavior.

**Finding 7.3 — Arm-size pre-condition behavior on the boundary case is unspecified.**
What happens when arm sizes are below 20? The spec says the lift gate requires ≥ 20 per side but does not say what happens to a candidate misconception that has ≥ N_min cluster traces but < 20 M-flagged learners. Does it wait (accumulate)? Is it discarded? Is it quarantined? A one-sentence default ("accumulate until the arm-size floor is met, then evaluate") would complete the spec. Non-blocking.

**Finding 7.4 — §14 deployment dependency not stated as a precondition.**
If z=1.0 relies on §14 calibration for safety (as argued in 5.3), the spec should note "requires §14 to be operational." This is a completeness gap, not a correctness error.

**Finding 7.5 — Multi-prereq misconception edge case still unhandled (carried).**
Round-1 Finding 7.1: a cluster implicating more than one prereq has no defined behavior. The graph schema supports at most one `misconception→prereq` edge per misconception. Non-blocking but a known limitation.

---

### 8. Consistency

**Score: 84 — pass. Round-3 changes are consistent with all referenced specs. The schema gap in DATA-LAYER.md persists.**

**Finding 8.1 — Held-out split is now consistent with §4's P1 principle.**
"lift estimated on the §4 held-out split" directly instantiates §4.1's P1 rule: "Make the measurement independent of the optimization." The round-3 revision closes the consistency gap between B1's admission gate and the rest of the system's held-out discipline.

**Finding 8.2 — z=1.0 override is consistent with §2's gate primitive.**
`§2 significant(Δ, se, margin=0, z=2)` specifies z=2 as a *default*, not an invariant. The spec is explicit that z is a caller-specified parameter. B1's z=1.0 is a valid instantiation of the same gate primitive, not a violation of §2.

**Finding 8.3 — GraphStore schema gap persists (carried from rounds 1 and 2).**
`DATA-LAYER.md` §5 Graph schema does not include a `misconception` edge type. B1 step 4 writes one. This remains a consistency gap requiring a schema extension. Non-blocking for B1's spec approval (the schema extension is a bounded follow-on), but it must be tracked.

**Finding 8.4 — Retirement window "50 evals" is consistent with N_min = 30 in scale.**
A 50-eval cadence for retirement is plausible relative to a 30-trace admission floor: a misconception admitted at 30 traces will have its first retirement check at the 50th incoming error trace. The cadence is small enough to catch false positives quickly and large enough to avoid thrashing. Consistent with the stated design intent.

---

### 9. Calibration / honesty

**Score: 78 — pass. Improved from round 2 (75). The z=1.0 rationale adds honest calibration framing; ρ_M empirical basis still absent.**

**Finding 9.1 — z=1.0 rationale adds honest calibration framing.**
The spec now explicitly acknowledges that z=1.0 is a relaxed gate designed for small cohorts, with the qualification "(a small-cohort moderate misconception shouldn't need `lift>0.5`; §14 calibrates)." This is an honest acknowledgment of a design trade-off with its backstop named. It is a calibration improvement over round 2.

**Finding 9.2 — ρ_M = 0.2 still lacks empirical basis (carried from rounds 1 and 2).**
Round-1 Finding 9.3: the default ρ_M = 0.2 is given without any basis in human-learning literature or prior cohort data. The spec's §14 calibration and "Honest risks" section do not acknowledge this. A sentence noting that ρ_M is a pilot-tunable parameter (like §12's open parameters) would be more honest. Non-blocking.

**Finding 9.3 — "Highest-differentiation human-ed app" claim is appropriately contextualized.**
The spec says "Highest user-visible impact; gated on C1's signal existing." The conditional qualification is appropriate. Unchanged from round 2.

**Finding 9.4 — Embedding model's ability to separate misconceptions still unacknowledged.**
Round-1 adversarial objection: sparse error corpora for non-mainstream skills and high surface variability make cluster coherence fragile. The "Honest risks" section does not acknowledge this scope condition — that B1 works well in high-traffic, low-surface-variability domains and is fragile in sparse, high-variability ones. Non-blocking but a calibration gap.

---

## Strongest adversarial objection

**The z=1.0 gate with a ≥ 20 arm-size floor creates a time-to-admission asymmetry that may structurally delay the detection of misconceptions in low-prevalence skills, which are precisely the skills most in need of misconception detection.**

Consider a skill with a low base error rate — say 15% of learners make a systematic error. With N_min = 30 cluster traces, by the time 30 traces are collected, only ~4–5 learners will be M-flagged (0.15 × 30 = 4.5). The arm-size pre-condition of ≥ 20 M-flagged learners cannot be met until the cluster has grown to approximately 133 traces (20 / 0.15). A misconception in a low-prevalence skill will not be admitted for 4× the cluster-formation time.

During this waiting period, the misconception is known to exist (the cluster is coherent and large enough by N_min) but cannot be gated because the arm is too small. The spec says nothing about what happens to learners matching the cluster during this gap — they are silently not remediated. The "Honest risks" and "Completeness" sections do not acknowledge this latency-prevalence trade-off.

This is not a correctness error (the arm-size floor is the right statistical pre-condition), but it is a consequential design property: B1's ability to help learners with low-prevalence misconceptions is structurally delayed relative to high-prevalence ones, and the delay can be large (4× N_min at 15% prevalence; 10× N_min at 6% prevalence). The spec does not acknowledge this or offer a mitigation (e.g., a provisional remediation path for high-confidence pre-statistical clusters, or a graduated arm-size floor that scales with prevalence).

No finding in the nine dimensions above surfaces this specific latency-prevalence interaction. It is the strongest remaining objection to the spec as written.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=87, RedTeam=82, Safety=86) = 82

weighted_mean   = (87*2 + 85 + 82*2 + 76 + 86*2 + 77 + 78 + 84 + 78) / 11
              = (174 + 85 + 164 + 76 + 172 + 77 + 78 + 84 + 78) / 11
              = 988 / 11
              = 89.8

overall         = min(82, 90) = 82
```

**Overall confidence: 82 / 100**

---

## Verdict

**ready-for-approval**

Overall score 82 ≥ 80, and no CRITICAL dimension is below 70 (Correctness 87, Red-team 82, Safety 86). All three round-2 blocking items are resolved. The one structural adversarial objection (low-prevalence admission latency) is noted and acknowledged as a known design property, not a blocking flaw.

**Non-blocking items recommended for a subsequent spec pass:**

1. State that `τ_merge` in step 6 is either the §5.1 global parameter or a B1-specific one (e.g., "B1-specific `τ_merge_M`, default 0.9 — tighter than §5.1's skill-merge threshold"). One sentence.
2. Add a sentence on the arm-size-below-floor behavior ("accumulate until ≥ 20 M-flagged; misconception remains candidate-pending, not active").
3. Note the low-prevalence admission latency in "Honest risks" — that at low base error rates (< 15%) the arm-size floor delays admission significantly; consider a provisional remediation flag for high-coherence pre-statistical clusters.
4. Default `τ_coh` (e.g., mean pairwise cosine ≥ 0.75).
5. Add `τ_cal` §14 as a stated deployment dependency of the z=1.0 relaxation.
6. Extend `DATA-LAYER.md` §5 Graph schema to include a `misconception{prereq_ref, admitted_ts, lift, n_m_flagged}` edge type.
7. Add `test_lift_gate_marginal_high_se_rejected` — verify that a cluster with nominal lift ≥ ρ_M but SE_lift > (lift − ρ_M) fails admission.
