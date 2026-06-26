# 360 Review: S17-S18-selfmod-fleet — 2026-06-27 (Round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` — §17 "The self-modification axis" + §18 "Multi-agent populations" |
| Proposed change | Add `self_modify` as a third learning axis behind a SOLVE/JUDGE partition (§17) with a code-specific two-stage promotion, and co-evolving multi-agent populations with a significance-gated fleet-coverage formula (§18), both as M3, owner go-decision recorded 2026-06-27 |
| Round-1 report | `docs/research/reviews/S17-S18-selfmod-fleet-review.md` (overall 45/100, 8 blockers) |
| Reviewer | review-360 |
| Date | 2026-06-27 |

---

## Blocker-by-blocker resolution audit (8 round-1 blockers)

The following traces each of the eight required changes from round-1 against the revised text.

**Blocker 1 — Mutable-scaffold manifest.**
Round-1 finding I-1: "The mutable scaffold is never defined — neither section names the specific modules, interfaces, or files that constitute the mutable surface."
Resolution: §17.1 now establishes an explicit SOLVE/JUDGE partition at lines 453–457. SOLVE is defined as "solve-prompts, tool-wiring, decision heuristics, retrieval config (which stores/queries, §16), and how the agent reads/interprets the shared graph and skills — everything affecting how a task is attempted." JUDGE is enumerated as nine named items: eval harness + verifier, held-out set and its generator, TeacherAdapter task-distribution, commit/rollback/safety gates, two-stage promotion, circuit breaker + calibration, `self_modify` budget enforcer, competence posterior `C` and its update path, and the §6 orchestrator loop. **This is a genuine manifest, not a restatement.** Resolved.

**Blocker 2 — Item-generation layer protected.**
Round-1 findings S-1, RT-1: `provision_suite` (§5.1) and the TeacherAdapter task-distribution were absent from the immutability wall — the primary RC-2 attack vector.
Resolution: §17.1 explicitly names both "the held-out set (§4.1) and its generator (`provision_suite` / item-synthesis, §5.1 — the primary RC-2 surface)" and "the TeacherAdapter task-distribution that decides which items a learner faces" as JUDGE members (line 455). The wall invariant states "a captured verifier (RC-2) — including the data-poisoning variant via item generation — is structurally prevented on the partitioned surfaces" (line 457). **The round-1 strongest adversarial objection is directly and explicitly closed.** Resolved.

**Blocker 3 — Code two-stage promotion.**
Round-1 findings C-1, RT-4, Co-6: §9's weight-only two-stage promotion was incorrectly cited for code; Stage 1/Stage 2 for code were never specified.
Resolution: §17.3 now specifies the code analog explicitly. Stage 1 is "shadow/sandbox — the candidate SOLVE runs in a sandbox (isolated subprocess, no write access outside SOLVE) on the held-out suite + a monitored live subset, in shadow (scored, not acted on). Promote only if held-out Δcompetence clears §8's four gates and the monitored subset shows no regression." Stage 2 is "hot-swap, fallback retained — the candidate replaces the running SOLVE; the frozen last-good SOLVE is retained; a post-promotion monitor triggers instant rollback on regression." The §9 analogy is now correctly labeled as the code analog rather than a verbatim reuse. **Resolved.**

**Blocker 4 — Fleet-coverage formula.**
Round-1 findings C-2, RT-5, I-5: the fleet-coverage term had no formula; the |fleet|=1 degeneracy and significance-gate were asserted not derived.
Resolution: §18.2 provides the explicit formula `φ(k) = 1 − ρ_fleet · 1[∃ j≠self : significant(ĉ_j(k) − θ, SE_j)]` (line 493). The |fleet|=1 case is now derived: "the j≠self set is empty ⇒ φ ≡ 1 ⇒ the objective is exactly §13.1 (degeneracy proven, not asserted)" (line 495). The significant() gate (RC-1) is explicitly present. The floor-dominates note (RC-7) states "the discount is soft (on the objective); the §5.3 hard coverage floor f_min is applied after and never overridden" (line 497). The O(1) cost is addressed via a "cached fleet-competence projection" (CacheStore, async-updated) rather than a synchronous fleet scan (line 498). **Resolved.** (An efficiency note on the async-update's freshness is surfaced below in Dimension 6, but it is not a blocker.)

**Blocker 4b — Budget enforcer in JUDGE (ratchet S-2).**
Resolution: §17.1 explicitly lists "the `self_modify` budget enforcer" in JUDGE (line 455). §17.4 confirms "Budget ratchet (an agent raises its own `self_modify` budget) → the budget enforcer is in JUDGE (§17.1), unwritable" (line 470). **Resolved.**

**Blocker 5 — A5 prior leakage bound.**
Round-1 finding S-3: the A5 warm-start from a shared item bank at fleet scale was a diluted P1 violation with no bound below significance.
Resolution: §18.4 now argues the prior contributes `n_eff_warm` pseudo-counts (default 3) with influence `≈3/(5+n_own)` decaying to negligible as the receiver's own evidence grows. "The §8 gate credits only the receiver's own held-out Δ, so the prior biases the starting estimate but cannot supply gated competence." To prevent shared-item-bank leakage, "warm-start neighbours contribute trajectory-shape on held-out-disjoint / isomorphic items (B3's isomorphic requirement) — no answer-specific signal crosses." The net cross-agent influence claim is "bounded below significance" (line 505). **Substantially resolved;** residual analysis follows in Dimension 5.

**Blocker 6 — §17/§18 parameters in §12.**
Round-1 finding Co-3: §17/§18 hyperparameters were absent from §12.
Resolution: §12's "Added-section parameters" paragraph now explicitly lists "§17 `b_sm` (`self_modify` budget), `sandbox_cost_cap`, `scaffold_retention` · §18 `N` (fleet size), `ρ_fleet` (fleet-coverage discount), `f_xfer` (inter-agent transfer frequency). §17/§18 dials are tuned at M3." (line 286). **Resolved.**

**Blocker 7 — Go-decision in BUILD-SPECS.**
Round-1 finding Cs-1: BUILD-SPECS G1 listed "await owner go" while §17 implicitly overrode it.
Resolution: BUILD-SPECS.md §G now records "owner go-decision 2026-06-27. Designed as ALGORITHM-v0.2 §17 (self-modification behind the SOLVE/JUDGE partition + code two-stage promotion) and §18 (multi-agent co-evolution on the shared substrate), targeting milestone M3. In the review→approve gate." (line 261). §17's header similarly states "Owner go-decision recorded 2026-06-27 (supersedes BUILD-SPECS G1 'await go')" (line 448). **Resolved.**

**Blocker 8 — Compound fleet × self-modify safety test.**
Round-1 finding Co-4: no test for the combined evolutionary loop despite §18.5 claiming the combination is safe.
Resolution: §18.7 now lists `test_fleet_self_modify_cannot_collectively_capture_verifier` as a named check stub: "N self-modifying agents cannot move held-out generation — JUDGE immutable for all" (line 519). §17.5 separately lists `test_self_modify_cannot_write_JUDGE` (incl. `provision_suite`, TeacherAdapter, budget enforcer) and `test_no_write_path_SOLVE_to_JUDGE` (static dataflow) (line 477). **Resolved.**

**Calibration/honesty fixes (8 listed items):**
- "Impossible by construction" → revised to "structurally prevented on the partitioned surfaces" (§17.1, line 457). The word "impossible" has been replaced. **Resolved.**
- Darwin-Gödel labeled an analogy: §17 intro states "An evolutionary analogy, not a formal Gödel-machine proof" (line 450); §18.5 states "an evolutionary archive (analogy, not a formal Gödel guarantee)" (line 509). **Resolved.**
- Code versioned in scaffold-version log: §17.2 states the candidate is "a scaffold version kept in an immutable append-only scaffold-version log (lineage like §10, *not* §3 cell-posteriors)" (line 460). **Resolved; the §3-conflation flaw C-4 is closed.**
- `agent_id` schema delta noted: §18.1 explicitly states "each agent keeps its own posterior `C_a` in a StateStore keyed by `agent_id` (the schema delta)" (line 488). **Resolved.**
- M3 milestone stated: §17.5 states "Milestone: §17 is M3, gated on the M2 weight axis" (line 476); §18 header also states "M3, with §17" (line 483). **Resolved.**

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 82 | pass |
| 2 | Design faithfulness | 83 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 79 | pass |
| 5 | Safety / integrity (CRITICAL) | 80 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 78 | pass |
| 8 | Consistency | 83 | pass |
| 9 | Calibration / honesty | 83 | pass |

---

## Findings by dimension

### 1. Correctness

**Score: 82 — pass**

**C-1 (Round-1, blocking) — §9 analogy for code: RESOLVED.**
§17.3 now specifies a distinct two-stage promotion for code with Stage 1 (sandbox/shadow) and Stage 2 (hot-swap + retained fallback). The incorrect claim that §9 is reused verbatim is replaced by an explicit code-specific procedure that is semantically correct — code has no "detachable adapter" but does have a "frozen fallback," which is the correct reversibility analog.

**C-2 (Round-1, blocking) — Fleet-coverage formula: RESOLVED.**
The formula `φ(k) = 1 − ρ_fleet · 1[∃ j≠self : significant(ĉ_j(k) − θ, SE_j)]` is now given. The |fleet|=1 degeneracy: when the `j≠self` set is empty, the indicator `1[...]` is `false` (no qualifying `j` exists), so `φ(k) = 1 − ρ_fleet · 0 = 1`, and the objective reduces to exactly §13.1. This is now derived, not asserted. **The derivation is mathematically correct.**

**C-3 (Round-1, calibration) — Darwin-Gödel analogy: RESOLVED.** Explicitly labeled an analogy.

**C-4 (Round-1, mislabeling) — Scaffold versioning in §3: RESOLVED.** Now correctly placed in an append-only scaffold-version log, not §3 posteriors.

**Remaining correctness note:**
The §18.4 "bounded below significance" claim for A5 prior leakage rests on the argument that warm-start neighbours contribute trajectory-shape on held-out-disjoint / isomorphic items. This argument is sound for the case where B3's isomorphic variant requirement is enforced: isomorphic items by definition use different operands/context-IDs, so no answer-specific signal crosses. The influence-decay formula `≈3/(5+n_own)` is the same as the approved A5 formula (BUILD-SPECS.md line 74), so the arithmetic is pre-verified. **No new correctness issues identified in the revised text.**

---

### 2. Design faithfulness

**Score: 83 — pass**

**DF-1 — §17 architecture: confirmed.**
`self_modify` is positioned as a normal outer §6 action producing a child and passing `commit_gate` (§17.2, line 460). This is consistent with the §6 loop structure (SELECT → EXPAND → EVALUATE → GROW → BACKUP → COMMIT).

**DF-2 — §18 shared substrate: confirmed.**
Per-agent `C_a` in a StateStore keyed by `agent_id` (§18.1) is consistent with DATA-LAYER.md §5's schemaless `Cell` structure (the `agent_id` is an additive schema key, not a restructuring). The schema delta is now explicitly noted.

**DF-3 (Round-1) — Ambiguity between "agent's scaffold" and "orchestrating loop": RESOLVED.**
§17.1 now explicitly places "the §6 orchestrator loop that runs SOLVE and calls JUDGE" in JUDGE (line 455). The agent runs inside §6; §6 itself is immutable for the agent. The boundary is now defined.

**DF-4 (Round-1) — ALGORITHM-INTEGRATIONS.md §G entry: RESOLVED.**
BUILD-SPECS.md §G1 now records the go-decision and references §17/§18. ALGORITHM-INTEGRATIONS.md §G still uses the 🔭 symbol but the text has been updated with the go-decision (BUILD-SPECS line 261). This is acceptable — ALGORITHM-INTEGRATIONS.md is a register that may lag the spec; the primary source (BUILD-SPECS §G) is accurate.

**DF-5 (Round-1) — Baseline test for §17: RESOLVED.**
§17.5 now includes `test_self_modify_off_equals_baseline` (line 477), the analog of `test_fleet_of_one_equals_single_agent`.

**New DF note:**
The §17.1 wall invariant states "checked as an import/dataflow constraint before any `self_modify` candidate is admitted." The §6 loop (now in JUDGE) is what admits candidates — so the dataflow check runs inside an immutable component. This is architecturally sound: the checker cannot itself be modified. No design-faithfulness concern.

---

### 3. Red-team resistance

**Score: 80 — pass**

Evidence sourced from ALGORITHM-v0.1-redteam.md root causes RC-1 through RC-8.

**RT-1 (Round-1, CRITICAL) — RC-2 item-generation attack: RESOLVED.**
`provision_suite` and item-synthesis are now explicitly in JUDGE (§17.1, line 455). The wall invariant states the data-poisoning variant via item generation is "structurally prevented on the partitioned surfaces." The round-1 strongest adversarial objection is closed.

**RT-2 (Round-1) — RC-2 TeacherAdapter indirect verifier influence: RESOLVED.**
The TeacherAdapter task-distribution is now explicitly in JUDGE (§17.1, line 455). A scaffold edit cannot change which items a learner faces.

**RT-3 (Round-1) — RC-7 fleet-scale coverage floor interaction: RESOLVED.**
§18.2 now explicitly states "the §5.3 hard coverage floor `f_min` is applied after and never overridden — an agent always samples its own weak skills regardless of fleet coverage" (line 497). The priority ordering (floor dominates discount) is now unambiguous.

**RT-4 (Round-1) — RC-8 code promotion two-stage: RESOLVED.**
§17.3 specifies the code-specific two-stage promotion (shadow/sandbox → hot-swap + fallback). The RC-8 mitigation is now realized for this action type.

**RT-5 (Round-1) — RC-1 fleet-coverage discount lacks significance gate: RESOLVED.**
The formula now passes through `significant(ĉ_j(k) − θ, SE_j)` before discounting — a thin/uncertain other-agent estimate does not discount (line 493–496).

**Residual red-team consideration:**
The wall invariant enforces "no write-path and no output-influence into JUDGE." The spec states this is "checked as an import/dataflow constraint before any `self_modify` candidate is admitted" (§17.1, line 457). This check is sound in principle. A residual attack: a sufficiently sophisticated SOLVE edit might attempt to influence JUDGE through side channels not captured by an import/dataflow analysis — e.g., by writing to a shared mutable data structure that JUDGE also reads. The spec's "no output-influence" clause is intended to cover this, and the companion test `test_no_write_path_SOLVE_to_JUDGE` (static dataflow) gates it. The residual is real but is mitigated by the test and is an inherent limitation of static analysis applied to Turing-complete code, not a specific architectural gap. Score deducted 5 points (from 85) for this irreducible residual — but this is not blocking.

RC-3, RC-4, RC-5, RC-6 regressions remain structurally absent (the §5 meta-functions, §3 state model, and §7–§8 backup/commit/gate machinery are explicitly unchanged per the §17/§18 additive framing).

---

### 4. Implementability

**Score: 79 — pass**

**I-1 (Round-1, blocking) — Mutable scaffold manifest: RESOLVED.**
The SOLVE/JUDGE partition is now a named manifest. Developers know exactly which surfaces are writable.

**I-2 (Round-1) — No plug-point section: PARTIALLY ADDRESSED.**
§17 and §18 do not have an explicit plug-point section in the BUILD-SPECS.md format (with `mdlp/module.py :: Class.method` style). The spec is written as an algorithm section, not a BUILD-SPECS item. However, §17.5 and §18.7 include named check stubs with enough specificity to drive implementation. The wall invariant is implementable via the stated "import/dataflow constraint" check. This remains a gap relative to the BUILD-SPECS A1/B3 standard — but §17/§18 are algorithm-spec sections, not yet BUILD-SPECS items; the spec notes they are "in the review→approve gate" (BUILD-SPECS line 267). No BUILD-SPECS item exists yet; the algorithm section is the design-level artifact under review. Deducted 3 points; not blocking.

**I-3 (Round-1, blocking) — agent_id key absent from StateStore schema: RESOLVED.**
§18.1 explicitly notes the `agent_id` key as "the schema delta" and DATA-LAYER.md §5's schemaless Cell structure accommodates it.

**I-4 (Round-1) — Sandbox mechanism unspecified: PARTIALLY ADDRESSED.**
§17.3 Stage 1 specifies "isolated subprocess, no write access outside SOLVE" as the sandbox model. This is more concrete than round-1 but still at the design level — specific container/capability-restriction technology is not named. Acceptable for an algorithm spec; a BUILD-SPECS item for §17 would need to specify the subprocess isolation mechanism. Deducted 2 points.

**I-5 (Round-1, blocking) — Fleet-coverage term has no formula: RESOLVED.**
Formula given and |fleet|=1 degeneracy derived.

**I-6 (Round-1) — No milestone mapping: RESOLVED.**
§17 is M3, gated on M2 (§17.5 line 476); §18 is also M3 with §17 (§18 header line 483).

**New implementability note:**
The `test_fleet_self_modify_cannot_collectively_capture_verifier` test stub (§18.7, line 519) is stated as "N self-modifying agents cannot move held-out generation — JUDGE immutable for all." This is a system-level integration test whose setup (N concurrent self-modifying agents) requires significant test infrastructure. The test stub is correctly identified; its implementation complexity is a build-spec concern, not an algorithm-spec concern.

---

### 5. Safety / integrity

**Score: 80 — pass**

Safety is scrutinized hardest per the review mandate.

**S-1 (Round-1, blocking) — Item-generation layer unprotected: RESOLVED.**
`provision_suite` / item-synthesis is explicitly in JUDGE (§17.1, line 455). The primary RC-2 attack surface is now inside the immutability wall.

**S-2 (Round-1, blocking) — Budget enforcer ratchet: RESOLVED.**
The `self_modify` budget enforcer is explicitly in JUDGE (§17.1, line 455). An agent cannot raise or zero its own edit budget. §17.4 confirms this under "Budget ratchet" (line 470).

**S-3 (Round-1, blocking) — A5 prior leakage at fleet scale: SUBSTANTIALLY RESOLVED.**
§18.4 argues: the prior contributes `n_eff_warm` (default 3) pseudo-counts; influence decays as `≈3/(5+n_own)`; the §8 gate credits only the receiver's own held-out Δ; neighbours contribute trajectory-shape on held-out-disjoint / isomorphic items (B3's isomorphic requirement). The argument is logically consistent with the approved A5 spec (BUILD-SPECS.md line 74 — influence at 9 own obs ≈21%, at 27 own obs <10%). The shared-bank attack is closed by the isomorphic-variant requirement. **Net cross-agent influence on gated competence is bounded below significance.** Residual: the isomorphic variant requirement relies on B3's enforcement — a transfer that bypasses B3's validation step would reopen this. B3 is an approved spec with an enforced invariant (`test_no_source_statestore_read` + `test_shared_bank_uses_variants`). The chain of dependencies is sound.

**S-4 (Round-1) — Graph-read code interpretation path: ADDRESSED.**
§17.1 states SOLVE includes "how the agent reads/interprets the shared graph and skills." §17.4 notes "an agent may edit how it reads the shared graph (SOLVE), but graph writes go through the immutable §8 gate; misreading only lowers its own held-out → rejected" (line 471). This is the correct analysis: a SOLVE edit that causes the agent to misinterpret the graph harms only the agent's own held-out performance, triggering rejection. Functionally equivalent to graph manipulation is not possible because the graph itself is not modified — the agent's distorted reading applies only to its own action selection, which is subject to the same held-out gate.

**S-5 (Round-1, blocking) — N×0 collective optimization pressure: RESOLVED.**
§18.5 argues: "collective optimization pressure on the JUDGE surface is N × 0, because JUDGE is immutable for every agent (§17.1's partition is per-agent; the shared JUDGE has no agent's write-path)." The A5 prior chain is addressed in §18.4. B3 transfer is zero-trust. The compound `test_fleet_self_modify_cannot_collectively_capture_verifier` is now a named check. The analysis is sound.

**Residual safety note (informational, not blocking):**
The SOLVE/JUDGE partition's enforcement relies on a runtime/static "import/dataflow constraint" check. This check is itself code that must be correct — a bug in the static analysis tool could produce false clearances. The spec's mitigation is that this check runs within JUDGE (the §6 orchestrator is immutable), so the checker cannot be modified by SOLVE. This is the correct architectural response. The residual is implementation correctness of the static analysis, which is an inherent limitation of the spec stage. It is not a structural gap in the architecture but an implementation risk properly belonging to the companion BUILD-SPECS item's acceptance tests (specifically `test_no_write_path_SOLVE_to_JUDGE`). This residual does not reduce Safety below 80; it is recorded for the implementer.

**Gates integrity survey:**
- §4 eval harness + verifier: in JUDGE ✓
- §4.1 held-out set + generator: in JUDGE (explicitly including `provision_suite`) ✓
- §8 commit/rollback/safety gates: in JUDGE ✓
- §9 / §17.3 two-stage promotion: in JUDGE ✓
- §14 circuit breaker + calibration: in JUDGE ✓
- `self_modify` budget enforcer: in JUDGE ✓
- §3 competence posterior C and update path: in JUDGE ✓
- §6 orchestrator loop: in JUDGE ✓
- TeacherAdapter task-distribution: in JUDGE ✓

All nine gate/calibration surfaces from the round-1 list are now accounted for.

---

### 6. Efficiency / cost

**Score: 76 — pass**

**E-1 — `self_modify` on the hot path: confirmed absent.**
`self_modify` is an episodic outer §6 action; it does not add to the per-step hot path.

**E-2 (Round-1) — Fleet-coverage term O(N) cost: ADDRESSED.**
§18.2 now states the cost is O(1) via a "cached fleet-competence projection (CacheStore, async-updated)" (line 498). This avoids the synchronous O(N²) fleet scan identified in round-1. Residual: the async-updated cache introduces a staleness window — an agent making a fleet-coverage decision may act on an outdated `ĉ_j(k)`. This is not a safety issue (the §5.3 floor dominates) and is a standard cache-consistency tradeoff. The spec should acknowledge the staleness bound in a BUILD-SPECS item; acceptable at the algorithm spec level.

**E-3 (Round-1) — Sandbox trial cost: ADDRESSED.**
§17.5 names `sandbox_cost_cap` as a parameter registered in §12 (line 475). The cost is bounded; its calibration is deferred to M3 empirical tuning.

**E-4 (Round-1) — B3 transfer volume at fleet scale: ADDRESSED.**
§18.7 names `f_xfer` (inter-agent transfer frequency) as a registered parameter (line 517). The pairwise B3 design is bounded by this frequency cap. For large N the total transfer volume at steady state is O(N × f_xfer) — bounded, not O(N²), under the frequency cap. Acceptable.

**New efficiency note:**
Stage-1 shadow/sandbox (§17.3) runs the candidate SOLVE on "the held-out suite + a monitored live subset." The cost of this shadow run is proportional to the size of the held-out suite. For large suites this could be significant. `sandbox_cost_cap` gates this; the implementation should ensure the shadow run is bounded and async with respect to the live agent's operation. No spec-level gap; an implementation concern.

---

### 7. Completeness

**Score: 78 — pass**

**Co-1 (Round-1, blocking) — Mutable scaffold manifest absent: RESOLVED.** SOLVE/JUDGE partition is a full manifest.

**Co-2 (Round-1) — Held-out independence guarantee asserted not proven: SUBSTANTIALLY ADDRESSED.**
§18.4 provides the bounding argument (isomorphic items, decaying influence, gate credits only receiver's own Δ). The argument is logically complete; a formal proof is not required at the spec stage.

**Co-3 (Round-1, blocking) — §17/§18 parameters absent from §12: RESOLVED.**
§12's "Added-section parameters" paragraph now covers all six new dials.

**Co-4 (Round-1, blocking) — No compound fleet × self-modify test: RESOLVED.**
`test_fleet_self_modify_cannot_collectively_capture_verifier` is now a named check in §18.7.

**Co-5 (Round-1) — Milestone mapping absent: RESOLVED.**
§17 = M3, §18 = M3 with §17.

**Co-6 (Round-1, blocking) — Code two-stage promotion unspecified: RESOLVED.**
§17.3 now specifies Stage 1 (shadow/sandbox) and Stage 2 (hot-swap + frozen fallback + instant rollback).

**Remaining completeness notes:**
1. §17.3 Stage 2 states "a post-promotion monitor triggers instant rollback on regression." The trigger condition for this monitor is not specified — what metric, what threshold, over what window constitutes "regression"? The round-1 §9 spec uses `significant(drop, SE)` with the cumulative gate; §17.3 does not explicitly inherit this or specify an analog. This should be clarified in the companion BUILD-SPECS item but is not blocking at the algorithm-spec level.
2. The compound test `test_fleet_self_modify_cannot_collectively_capture_verifier` is a stub with a stated mechanism ("N self-modifying agents cannot move held-out generation — JUDGE immutable for all") but no stated test setup, preconditions, or success criteria beyond the mechanism claim. Acceptable as a stub; the BUILD-SPECS item will need to operationalize it.

---

### 8. Consistency

**Score: 83 — pass**

**Cs-1 (Round-1) — BUILD-SPECS G1 go-decision gap: RESOLVED.**
BUILD-SPECS §G1 now records the go-decision and references §17/§18 under M3, in the review→approve gate.

**Cs-2 (Round-1) — §18 vs. B3 approved scope: ADDRESSED.**
§18 builds on B3's approved pairwise mechanism and extends it to N-agent population dynamics under the same zero-trust + re-validation invariant. The extension is consistent in mechanism. B3's approval is correctly not treated as approving population-level behavior; §18 is the new section under review. No inconsistency.

**Cs-3 (Round-1) — "RC-2 is closed" internal inconsistency: RESOLVED.**
The §17.3 claim now reads against the specific partition surfaces (§17.1), which now include `provision_suite` and the TeacherAdapter. The internal consistency is restored.

**Cs-4 (Round-1) — §17.2 wall extended to fleet assumed without proof: ADDRESSED.**
§18.5 provides the argument: "§17.1's partition is per-agent; the shared JUDGE has no agent's write-path." The transitivity argument is now explicit: each agent's SOLVE is partitioned from each agent's JUDGE interface; the shared JUDGE structure is the union of those interfaces and is unreachable by any agent's SOLVE. This is sound.

**Cs-5 (Round-1) — StateStore schema lacks agent_id: RESOLVED.**
§18.1 calls it "the schema delta" and DATA-LAYER.md §5's schemaless Cell accommodates it. Technically DATA-LAYER.md §5's table still shows the Cell schema without `agent_id`, but the §18.1 delta notice is the correct way to record a schema extension in a design spec without editing the data-layer doc. Acceptable.

**New consistency check — §17 "additive" claim:**
§17 states "the §1–§16 mechanisms are unchanged." The changes are: (a) `self_modify` added as a new outer §6 action type — additive, not a change to the loop logic; (b) SOLVE/JUDGE partition introduced as a new architectural boundary — additive; (c) scaffold-version log added to the data layer — additive. No §1–§16 mechanism is altered. The claim is consistent with the text.

---

### 9. Calibration / honesty

**Score: 83 — pass**

**Ca-1 (Round-1, blocking) — "Impossible by construction" overstatement: RESOLVED.**
The phrase is replaced by "structurally prevented on the partitioned surfaces" (§17.1, line 457). The language now accurately describes what the partition achieves — prevention on the named surfaces — rather than a global impossibility claim.

**Ca-2 (Round-1) — Darwin-Gödel formal guarantee implied: RESOLVED.**
Both §17 (line 450) and §18.5 (line 509) explicitly label the Gödel Machine reference as an analogy, not a formal equivalence.

**Ca-3 (Round-1) — "No change to §1–§16" overstated re §9: RESOLVED.**
§17.3 now specifies a distinct code-promotion procedure rather than claiming §9 applies verbatim. The §17 framing remains "§1–§16 mechanisms are unchanged" but this is now accurate because §9 is not cited as the code mechanism — §17.3 is.

**Ca-4 (Round-1) — "Degrades to single-agent at |fleet|=1" claimed without formula: RESOLVED.**
Derived from the formula.

**Ca-5 (Round-1) — Insufficient acknowledgment of open scientific questions: PARTIALLY ADDRESSED.**
§17 labels the approach an analogy to the Gödel Machine and notes §8 is "a statistical gate, not a theorem-prover." The open question of whether the held-out set remains a valid estimator when the scaffold being modified includes context assembly code is not explicitly surfaced. However, §17.1's answer is structural: context assembly for held-out items is in JUDGE (eval harness + verifier, line 455), so the scaffold cannot modify how held-out items are assembled. This closes the specific open question by construction rather than by acknowledgment. Acceptable.

**New calibration note:**
§18.5 states "the compound is bounded: collective optimization pressure on the JUDGE surface is N × 0." The "N × 0" claim is correct as stated — each agent's JUDGE write-access is zero, so the product is zero. But this formulation could mislead readers into thinking the *total* system pressure scales with N×0=0 for all forms of pressure. The actual claim is narrower: collective *write*-pressure on JUDGE is N×0. Other fleet-scale effects (monoculture, shared A5 priors, B3 transfer volume) scale with N and are addressed separately in §18.4/§18.6. The §18.5 framing is locally accurate but could be more careful. A 2-point deduction from 85; not blocking.

---

## Strongest adversarial objection

The round-1 adversarial objection (data-poisoning via `provision_suite`) has been directly and explicitly closed by the revised §17.1. A new adversarial pass is required.

**The strongest remaining objection: the SOLVE/JUDGE enforcement mechanism is self-referential in a way the spec does not fully analyze.**

The enforcement chain is: before any `self_modify` candidate is admitted, the JUDGE (specifically, the §6 orchestrator, which is in JUDGE) runs an "import/dataflow constraint" check on the candidate. This check verifies the candidate has no write-path or output-influence path into JUDGE. The security of the entire partition rests on the correctness of this check.

The objection: the spec defines JUDGE as containing "the §6 orchestrator loop that runs SOLVE and calls JUDGE" (§17.1). The orchestrator is immutable — `self_modify` cannot edit it. The dataflow checker runs inside this immutable orchestrator. This is architecturally sound. But the checker is specified at the level of "import/dataflow constraint" without naming the analysis technology (static import graph? AST analysis? type system?) or bounding what class of influence paths it can detect.

A sufficiently clever SOLVE edit could influence JUDGE through a path the static analysis does not capture — for example, through a shared module-level mutable object (not an import, but a runtime reference) or through a side channel that manifests only at runtime (e.g., exhausting a shared resource). These are attacks against the completeness of static analysis, not against the architecture. The companion tests `test_no_write_path_SOLVE_to_JUDGE` and `test_self_modify_cannot_write_JUDGE` are the correct mitigations — but they are stated as design stubs and must be implemented with a sound static analysis tool.

This objection is real but is of a different character from the round-1 objection: it is an implementation correctness risk (the static analysis must be sound), not a structural gap in the architecture (the architecture is correctly designed). It does not block the design-spec approval but must be addressed in the companion BUILD-SPECS item as a first-class acceptance criterion: the static analysis tool must be named, its completeness class stated, and its coverage of runtime side-channel paths demonstrated.

No further structural objection found beyond this and the nine dimension findings above.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=82, RedTeam=80, Safety=80) = 80
weighted_mean   = (82*2 + 83 + 80*2 + 79 + 80*2 + 76 + 78 + 83 + 83) / 11
                = (164 + 83 + 160 + 79 + 160 + 76 + 78 + 83 + 83) / 11
                = 966 / 11 = 87.82 → 88
overall         = min(80, 88) = 80
```

**Overall confidence: 80 / 100**

---

## Verdict

**ready-for-approval**

All eight round-1 blocking changes are verified resolved. No CRITICAL dimension falls below 70. The overall score clears 80 exactly, driven by the critical floor (Safety = 80, Red-team = 80).

**Pre-implementation notes for the companion BUILD-SPECS item (non-blocking, required before code):**

1. **Static analysis tool must be named and its completeness class stated.** The SOLVE/JUDGE enforcement via "import/dataflow constraint" is the load-bearing safety mechanism. The BUILD-SPECS item must specify: (a) which static analysis tool or technique performs the check; (b) what class of influence paths it covers (import graph only? AST dataflow? runtime reference tracking?); (c) how runtime side channels (shared mutable state, resource exhaustion) are handled. `test_no_write_path_SOLVE_to_JUDGE` must be operationalized against this specific tool.

2. **Stage-2 post-promotion rollback trigger must be specified.** §17.3 states "a post-promotion monitor triggers instant rollback on regression" but does not specify the regression metric, threshold, or observation window. The BUILD-SPECS item should inherit §8's `significant(drop, SE)` + the cumulative gate, or define an explicit analog.

3. **Fleet-competence cache staleness bound should be stated.** §18.2's O(1) cost relies on an async-updated `CacheStore` projection. The BUILD-SPECS item should specify the maximum allowed staleness (in terms of agent-actions or wall-clock time) and how stale reads interact with the §5.3 coverage floor guarantee. Staleness does not affect safety (the floor dominates) but affects the quality of the fleet-coverage objective.
