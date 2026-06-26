# 360 Review: S17-S18-selfmod-fleet — 2026-06-27

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` — §17 "The self-modification axis" + §18 "Multi-agent populations" |
| Proposed change | Add `self_modify` as a third learning axis (§17) behind an immutability wall, and co-evolving multi-agent populations on the shared 5-store substrate (§18), together framed as a Darwin-Gödel evolutionary search (§18.5) |
| Reviewer | review-360 |
| Date | 2026-06-27 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 62 | weak |
| 2 | Design faithfulness | 75 | pass |
| 3 | Red-team resistance (CRITICAL) | 52 | weak |
| 4 | Implementability | 68 | weak |
| 5 | Safety / integrity (CRITICAL) | 45 | blocking |
| 6 | Efficiency / cost | 72 | pass |
| 7 | Completeness | 60 | weak |
| 8 | Consistency | 72 | pass |
| 9 | Calibration / honesty | 65 | weak |

---

## Findings by dimension

### 1. Correctness

**Score: 62 — weak**

**C-1. The "additivity" claim for §17 is partially falsified (§17 line 446–448).**
§17 opening states: "No change to §1–§16 mechanisms; it adds an action type and an architectural boundary." This is true for most of §1–§16, but §17.1 (ALGORITHM-v0.2 line 451) says `self_modify` is "gated by the existing §8 commit + §9 two-stage promotion." The §9 two-stage promotion (`train_LoRA → merge_to_base`) is specified for *weight* promotion of a *learned skill*, not for a *code change*. Applying it unchanged to scaffold code is a semantic category error: LoRA adapter training presupposes a model weight space to perturb; a scaffold code diff has no equivalent of a "detachable adapter" in the §9 sense. The claim that §17 re-uses §9 unchanged is therefore either incorrect (the mechanism needs modification) or underspecified (a distinct analogous two-stage process for code should be stated explicitly). **This is a correctness flaw, not just an implementation gap.**

**C-2. §18.2 fleet-coverage term: no formula given; "constant at |fleet|=1" claim is asserted not derived (§18 line 488).**
The spec says the fleet-coverage term "discounts" an action's value where collective fleet competence is high, and "with |fleet|=1 the term is constant and the objective is exactly §13.1." Without a formula, this cannot be verified. If the discount term is defined as `(1 − collective_competence / fleet_size)`, it is trivially 1 when fleet_size=1 only if the other agent's competence is zero — not in general. If it is defined differently, the degeneracy claim requires proof. The claim is plausible but unverified because the formula is absent. **Blocking for an approved build-spec; acceptable at the current "design sketch promoted to §" level only if labelled tentative.**

**C-3. §18.5 Darwin-Gödel framing: "Gödel" inheritance claim is not derived (§18 line 497).**
The spec asserts: "variation = `self_modify`; selection = held-out competence; inheritance = B3 transfer." This is an evocative analogy but the Gödel Machine original (Schmidhuber) requires formal proofs of improvement before self-edits execute; §17's §8-gate is a statistical test, not a formal proof. Calling this "Darwin-Gödel made safe" mischaracterizes what safety is being claimed. The phrase may mislead implementers about the theoretical guarantee. Not a fatal error; a calibration issue, but noted here because it propagates incorrect claims about the theoretical foundation.

**C-4. §17.1 scaffold versioning: "versioned like §3 state" (line 451) — §3 state is per-cell Beta posteriors, not code versions. The claim conflates two distinct versioning concepts.** The intent (keep a frozen last-good scaffold) is sound; the formalism cited is wrong. An explicit code-versioning mechanism must be stated.

**Summary:** No sign errors in the formulas cited from §§2–15. The correctness issues are in the new mechanisms: the §9 analogy for code promotion (C-1, the most serious), the missing fleet-coverage formula (C-2), and two incidental mislabellings (C-3, C-4).

---

### 2. Design faithfulness

**Score: 75 — pass**

**DF-1. §17 architecture — correctly positioned as outer §6 action (§17.1, line 451).** The placement of `self_modify` as a normal outer-loop action producing a child that passes `commit_gate` is faithful to the §6 loop structure. The claim that it is "outer, not inner" (unlike §16's `retrieve`) is consistent with §6's layout.

**DF-2. §18 shared substrate — consistent with §10's design (DATA-LAYER.md §1).** Running §6 per agent over the shared 5-store substrate is entirely consistent with §10's port-based architecture. The `StateStore` per-agent identity (DATA-LAYER.md §5, `cell{skill, difficulty, context, …}`) supports per-agent competence naturally.

**DF-3. §17.2 wall vs. §6 structure — a minor tension.** The §6 loop lists `COMMIT` as step 6, using `commit_gate(child, node)`. The immutability wall (§17.2, line 454) says the agent may never "modify or route around" §8/§9. But §6 already shows the gate as code the loop itself calls — the agent in the spec is not writing §6, it is _running_ inside §6. The spec does not clearly distinguish between (a) the agent's own scaffold (mutable) and (b) the orchestrating loop (immutable). This ambiguity is a faithfulness concern: where exactly does the boundary between "the agent's scaffold" and "the algorithm's orchestrator" lie? It is not defined.

**DF-4. §18 does not appear in ALGORITHM-INTEGRATIONS.md (checked: G section lists "Self-modification axis" as 🔭 frontier, no §18 entry).** The addition of §18 promotes a design-sketch to a full algorithm section without an ALGORITHM-INTEGRATIONS.md update. Acceptable under "additive" discipline only if the integrations register is intended to be retroactively consistent; flagged as a minor gap.

**DF-5. §§13–16 established pattern of including a "Reduction to A1" or "single-agent case" test.** §18 provides `test_fleet_of_one_equals_single_agent` (§18.7), which follows the pattern. §17 does not have an analogous baseline check ("test_self_modify_off_equals_no_axis_change"). Consistent with prior sections' completeness discipline to add this.

---

### 3. Red-team resistance

**Score: 52 — weak**

Evidence sourced from ALGORITHM-v0.1-redteam.md root causes RC-1 through RC-8.

**RT-1. RC-2 (gameable verifier) — the wall's most dangerous gap: scaffold that constructs held-out tasks (CRITICAL).**
§17.2 (line 454) lists what is outside the writable surface: "the eval harness + verifier (§4) and the held-out set (§4.1)." However, in many real-world implementations the *item generation* code — the component that synthesizes held-out suite items from failure clusters (§5.1 `provision_suite`, line 135–140) — lives in the scaffold layer, not the eval layer. If `provision_suite` is scaffold-writable, an optimizer can edit how items are generated to produce a held-out set that is trivially solvable. The spec does not name `provision_suite` as immutable. **This is a concrete RC-2 attack vector the immutability wall does not demonstrably close.**

**RT-2. RC-2 — indirect verifier influence through the `TeacherAdapter` (§13, line 296).**
The spec (§13) states that a Teacher choice is "just another Action" evaluated by the same held-out gate. `self_modify` can edit the `TeacherAdapter`. A sophisticated scaffold optimization that systematically chooses a TeacherAdapter which narrows the distribution of tasks presented to learners is an indirect held-out contamination path. The §17.2 wall does not mention TeacherAdapters.

**RT-3. RC-7 (abandoned skills/suite-bound safety) — fleet-scale coverage floor not extended.**
§18.2 introduces a fleet-coverage term that nudges agents to distinct frontiers. But §18 says "no change to §3/§5/§8 gates." The §5.3 per-agent coverage floor (`f_min`) is designed for a single-agent system. In a fleet where the fleet-coverage term drives agents to non-overlapping frontiers, individual agents may have near-zero coverage floor at most skills (they are assigned to a narrow frontier partition). The per-agent `f_min` is not shown to compose correctly with the fleet-coverage discount: they can pull in opposite directions, and the spec does not address which wins or how they interact. This is a partial RC-7 regression at fleet scale.

**RT-4. RC-8 (promotion misfire) — no two-stage analogue for scaffold code is specified.**
As noted in C-1, §17 claims to use §9's two-stage promotion. §9 is explicitly about LoRA adapter (reversible) → base merge (irreversible). Code promotion has no adapter analogue. Without specifying what "Stage 1 / Stage 2" means for code, the RC-8 mitigation is stated but not realized for this new action type.

**RT-5. RC-1 (point estimates) — fleet-coverage objective lacks statistical gate.**
§18.2 says an action's value is "discounted where the fleet's collective competence at that cell is already high." Without a formula or SE, this discount is a scalar compare — exactly the RC-1 pattern. Whether the fleet-coverage discount passes through `significant()` before influencing action selection is not stated.

**Summary:** RT-1 (item-generation-code attack) and RT-4 (no code promotion two-stage) are the most serious gaps. RT-2 (Teacher pathway) and RT-3 (floor/fleet tension) are secondary. RC-3, RC-4, RC-5, RC-6 regressions appear structurally absent. The wall's principle is sound; its boundary is under-drawn.

---

### 4. Implementability

**Score: 68 — weak**

**I-1. The "mutable scaffold" is never defined.** §17.1 says `self_modify(component)` proposes a code edit to the agent's "mutable scaffold." §17.2 says the wall is at "the problem-solving scaffold." Neither section names the specific modules, interfaces, or files that constitute the mutable surface. A developer cannot implement access control without a manifest of writable vs. immutable components.

**I-2. No diff on what changes in the codebase.** Prior approved build-specs (A1, A5, B3) each identify a specific `plug-point` (e.g., `mdlp/decision.py :: DecisionEngine.choose`). §17 and §18 have no plug-point section. §17.5 lists test stubs, but `test_self_modify_cannot_touch_verifier` requires a defined access control model to be testable — which does not exist.

**I-3. §18 fleet instantiation: how do per-agent `C_a` stores coexist in the shared StateStore?** DATA-LAYER.md §5 shows the `Cell` schema as `{skill, difficulty, context, …}` with no agent-ID field. Per-agent competence in a shared StateStore requires an `agent_id` key, which is currently absent from the schema. No schema delta is proposed.

**I-4. §17.1 "sandboxed trial" (line 467) — the sandbox mechanism is unspecified.** For code-executing agents the sandbox is a major engineering surface. No container/subprocess/capability-restriction model is given.

**I-5. §18.2 fleet-coverage term has no formula (see C-2), so it cannot be implemented.**

**I-6. §17 and §18 lack a milestone mapping.** §§11 (re-scoped pilot) names M0/M1/M2. §17 and §18 do not state which milestone they extend. Given that §17 is the third learning axis (weight axis = M2), a natural reading is that both depend on M2, but this is not stated.

---

### 5. Safety / integrity

**Score: 45 — blocking**

Safety is scrutinized hardest per the review mandate.

**S-1. The immutability wall (§17.2) is not enforcement-complete: the item-generation layer is unprotected (RT-1 elaborated).**
The four protected surfaces listed in §17.2 (lines 454–458): eval harness+verifier, held-out set, commit/rollback/safety gates, circuit breaker/calibration, and competence posterior `C`. Missing from the list: `provision_suite` (§5.1 line 135–140) which synthesizes held-out items from failure clusters. If this function is writable, an agent can corrupt the measurement at the data-generation stage, before the verifier operates. This is a **structural safety gap in the wall itself** — not a theoretical risk, but a concrete code path.

**S-2. §14 (calibration layer / circuit breaker) protection — the wall lists "circuit breaker / calibration (§14)" as immutable, but §17.4 (line 468) lists "§14 breaker" as a gate against unbounded self-editing. These are the same mechanism playing two roles (protection and limit), and the spec does not confirm that the `self_modify` budget enforcer is itself outside the writable scaffold. If the budget counter is in the scaffold, a self-modifying agent can raise or zero its own budget — a classic ratchet vulnerability.**

**S-3. §18.4 per-agent held-out independence — the A5 prior leakage path.**
§18.4 (line 494) states: "Cross-agent evidence enters only as a prior (A5 warm-start, influence decaying as B's own evidence arrives) or a transfer candidate (B3, re-validated on B's own held-out) — never as direct competence credit."
A5 (BUILD-SPECS.md line 67–76) injects `n_eff_warm · μ_knn` into the Beta prior. The `μ_knn` is derived from agents that were themselves optimized against their held-out sets. At fleet scale, with many self-modifying agents, the A5 prior aggregates the competence of a population whose held-out sets may not be provably independent (the pools are described as "per-agent" but the item bank is often shared — §B3 validation uses "isomorphic variants" precisely because the bank is shared). **A5 warm-start from a fleet of agents on a shared item bank re-introduces a diluted but non-zero P1 violation** that §18.4 does not demonstrate is bounded below significance.

**S-4. §18's shared pathway graph and shared validated skill library are both outside any agent's writable surface (§18.4, line 494), but §17.2's wall only explicitly protects per-agent components.** An agent running `self_modify` that edits its scaffold's graph-reading or graph-writing code could modify how it interacts with the shared graph — not modifying the graph itself, but changing how it interprets the shared structure. The wall as written (§17.2) says the agent may not "modify" those surfaces; it does not say the agent may not modify the code that reads/interprets them, which is functionally equivalent.

**S-5. No safety analysis of §17 × §18 interaction — the evolutionary combination.**
§18.5 frames the combination as "a Darwin-Gödel archive made safe" because "no member can capture the shared judge." But the risks compound: a population of self-modifying agents, all optimizing against held-out scores, exerts a collective optimization pressure on the shared verifier indirectly (through the shared graph, through A5 priors derived from one another's results, through B3 skill transfer). A single self-modifying agent's pressure on the verifier is limited by its own compute budget. A fleet of N self-modifying agents, each attempting scaffold edits, exerts N times the pressure — and the spec presents no analysis of whether the immutability wall + B3 zero-trust together bound this collective attack surface.

**S-6. §17.5 check `test_self_modify_cannot_touch_verifier` is circular.** The test name implies a static check against the §17.2 manifest, but the manifest is incomplete (S-1). A test against an incomplete manifest is not a safety proof.

**Summary:** Blocking issues are S-1 (unprotected item-generation layer), S-2 (budget enforcer may be in scaffold), S-3 (A5 prior leakage at fleet scale), and S-5 (no collective optimization pressure analysis). S-4 is secondary. The safety architecture's principle is sound; its boundary definition is incomplete and untested at the boundaries that matter most.

---

### 6. Efficiency / cost

**Score: 72 — pass**

**E-1. §17: `self_modify` as an outer §6 action is correctly classified — it does not add to the hot path.** The hot path (`SELECT → EXPAND`) is unchanged; `self_modify` is episodic, not per-step. No O(n²) addition identified.

**E-2. §18.2 fleet-coverage term: computing "the fleet's collective competence at that cell" at decision time requires reading all agents' StateStores for that cell.** At fleet size N this is O(N) per candidate action per agent — i.e., O(N² × |candidates|) fleet-wide per tick. This is noted in §18 only obliquely ("nudging agents to distinct frontiers") with no complexity analysis. For large fleets this is a hot-path concern if the fleet-coverage score is computed synchronously. The spec does not state whether this is async/cached or per-step.

**E-3. §17 sandboxed trial (§17.4): the cost of running a scaffold candidate on held-out tasks is unspecified.** For code-editing agents this could be significant; for prompt-editing agents it is a fixed LLM-call overhead. No estimate or budget cap is given beyond "a `self_modify` budget."

**E-4. §18 multi-agent scaling: no discussion of B3 transfer volume at fleet scale.** B3 proposes cross-agent transfer; at fleet size N each agent can potentially trigger N-1 transfer checks. The B3 spec (BUILD-SPECS.md line 219–245) was designed for pairwise agent interaction, not fleet-wide broadcast. A fleet-level B3 policy (who initiates, how often) is unspecified.

---

### 7. Completeness

**Score: 60 — weak**

**Co-1. Mutable scaffold manifest: absent.** The single most critical completeness gap — everything else in the safety analysis depends on knowing what "mutable scaffold" means precisely.

**Co-2. §18 held-out independence guarantee is asserted not proven.** "Per-agent held-out independence" (§18.4, line 493) is stated as a policy rule, but the item bank sharing problem (see S-3) is not resolved. A completeness requirement would be a proof or bound that A5 warm-start + B3 isomorphic-variant validation together keep shared-bank leakage below significance threshold.

**Co-3. No hyperparameters for §17 or §18 listed in §12 (open parameters).** §12 (ALGORITHM-v0.2 line 282) is the canonical hyperparameter register. §17 introduces at minimum: `self_modify` action budget, sandbox trial cost cap, scaffold version retention window. §18 introduces: fleet size `N`, fleet-coverage discount weight, inter-agent B3 trigger frequency. None appear in §12.

**Co-4. No test for the §17 × §18 compound.** §17.5 and §18.7 each have checks; there is no test for the combined evolutionary loop. Given §18.5 explicitly claims the combination is safe, at least one compound test (`test_fleet_self_modify_cannot_collectively_capture_verifier`) is expected.

**Co-5. Milestone mapping absent** (also I-6): which of M0/M1/M2/M3 does §17 first appear in? Given its dependency on the weight axis (M2) and its own complexity, it should be explicitly positioned as a future M3.

**Co-6. §17's "two-stage reversible promotion" for code (analogous to §9) is gestured at but not specified.** What is Stage 1 for code (a sandboxed trial run? a shadow-deploy?), what is Stage 2 (hot-swap), and what is the promotion gate? These are §9-level completeness requirements that §17 never supplies.

---

### 8. Consistency

**Score: 72 — pass**

**Cs-1. §17 vs. ALGORITHM-INTEGRATIONS.md §G (BUILD-SPECS.md line 261):** BUILD-SPECS.md §G lists "G1 self-modification axis" as a frontier direction requiring a "scope decision" and "safety budget" before proceeding. §17 promotes this to a full algorithm section without noting that the go-decision was made and what the decision was. The inconsistency is visible: BUILD-SPECS.md's final status line (line 267) reads "G design-sketched (scope decisions, await owner go)" — which §17 implicitly overrides without a change-approver decision record.

**Cs-2. §18 vs. BUILD-SPECS.md B3 (line 215–245):** B3 was approved as "agent-side" fleet transfer with zero-trust. §18 extends this to a full co-evolution regime. B3's approved scope was pairwise (single source agent A, single recipient agent B). §18 extends to N-agent population dynamics. The extension is consistent in mechanism but not in scope — B3's approval should not be read as approving population-level fleet behavior.

**Cs-3. §17.3 claims "the two dominant risks — verifier gaming (RC-2) and promotion misfire (RC-8) — are exactly the ones §17.2's wall and §9's two-stage promotion already close."** This claim is inconsistent with the correctness finding C-1 (§9 two-stage promotion is not specified for code) and the red-team finding RT-1 (the wall does not close the item-generation attack path for RC-2). The self-referential safety justification is internally inconsistent.

**Cs-4. §18.4 "§17.2's wall extends to the fleet: the shared verifier and graph-gates are outside every agent's writable surface."** This is stated as a consequence of §17.2, but §17.2 was written for a single agent. Extending it to the fleet is assumed without proof of transitivity. The extension is plausible but needs an explicit argument.

**Cs-5. DATA-LAYER.md StateStore schema (line 135) has no `agent_id` field.** §18.1 requires per-agent competence stores. This is a schema inconsistency that must be patched in DATA-LAYER.md before §18 can be considered consistent with the data layer.

---

### 9. Calibration / honesty

**Score: 65 — weak**

**Ca-1. "Verifier capture (RC-2) is impossible by construction" (§17.2, line 461; §17.3, line 463; §17.4, line 467).** The word "impossible" and "by construction" appear three times. Given the item-generation attack path (S-1, RT-1), this claim is overconfident. "Structurally constrained in the named surfaces" would be accurate; "impossible" is not.

**Ca-2. "Darwin-Gödel archive made safe" (§18.5, line 497).** The Gödel Machine reference implies formal guarantees that §17/§18 do not provide. The spec should disclaim this is an analogy, not a formal equivalence.

**Ca-3. "No change to §1–§16 mechanisms" (§17, line 446) is largely correct but the §9 re-use is non-trivial (C-1). The zero-change claim is overstated.**

**Ca-4. §18.2 "Degrades to the single-agent algorithm at fleet size 1" is asserted without formula (C-2). This should be labelled "claimed, pending formula".**

**Ca-5. The scientific basis for self-modifying code agents being safe under a statistical gate alone is not thin — the DGM literature exists — but the spec does not cite it and does not acknowledge the significant open research questions (does §8's statistical gate converge under self-modification? does the held-out set remain a valid estimator when the scaffold being modified includes the context assembly for held-out items?). The uncertainty is insufficiently surfaced.**

---

## Strongest adversarial objection

**The immutability wall is topologically incomplete: the boundary it draws is between "eval harness" and "scaffold," but in a system that synthesizes its own held-out items (`provision_suite`, §5.1), that boundary does not track the causal graph of how held-out scores are produced.**

In more detail: RC-2 is not "can the agent edit the verifier file?" — it is "can the agent cause verifier outcomes to diverge from true competence?" The list in §17.2 protects the *verifier process* and the *held-out set at rest*, but it does not protect the *process that generates held-out items*. An optimizer with write access to `provision_suite` can generate held-out items that are trivially solvable (e.g., items with zero variance — always pass), without ever touching the verifier or the held-out set that exists at time T. The items generated at time T+1 are outside the set that existed at time T; the wall, as drawn, does not prevent this.

This attack is not subtle: it is the standard data-poisoning variant of verifier gaming, applied to a system that auto-generates its own data. The wall as specified is necessary but not sufficient to prevent RC-2. No amount of gate strengthening or statistical rigor elsewhere closes this gap — it requires explicitly protecting item-generation code as immutable (or sandboxing it in a way that the scaffold cannot influence its output distribution). The entire "made safe by construction" claim stands or falls on this point, and the spec does not address it.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=62, RedTeam=52, Safety=45) = 45
weighted_mean   = (62*2 + 75 + 52*2 + 68 + 45*2 + 72 + 60 + 72 + 65) / 11
                = (124 + 75 + 104 + 68 + 90 + 72 + 60 + 72 + 65) / 11
                = 730 / 11 = 66
overall         = min(45, 66) = 45
```

**Overall confidence: 45 / 100**

---

## Verdict

**needs-revision**

The following blocking changes are required to clear 80:

1. **Define the mutable scaffold manifest explicitly** (§17.2 blocker). Name every module/interface that is writable vs. immutable. Without this, the wall cannot be implemented or tested, and every safety argument is unverifiable. At minimum, `provision_suite` and the `TeacherAdapter` selection code must appear in this manifest with explicit writable/immutable designations.

2. **Add `provision_suite` and item-generation code to the §17.2 immutability wall, or demonstrate that the scaffold has no write path to it.** The item-generation layer is the primary RC-2 attack surface under self-modification. "Impossible by construction" must become true by construction — not just by policy.

3. **Specify the two-stage promotion analogous to §9 for scaffold code** (§17.1). What is Stage 1 (a time-bounded shadow run? a held-out-only trial?), what is Stage 2 (hot-swap into the running agent), and what are the gate conditions? Reusing §9 verbatim is semantically incorrect for code.

4. **Provide the fleet-coverage term formula** (§18.2) and prove the |fleet|=1 degeneracy. Without a formula the claim is unverifiable and the term is unimplementable.

5. **Bound the A5 prior leakage under fleet self-modification** (§18.4 + S-3). Demonstrate that A5 warm-start from a fleet of agents on a shared item bank keeps cross-agent influence below significance, or replace the warm-start policy at fleet scale with one that is provably P1-safe.

6. **Add §17/§18 hyperparameters to §12** (the open-parameters register): `self_modify` budget, sandbox cost cap, scaffold version retention, fleet size `N`, fleet-coverage discount weight, B3 inter-agent trigger frequency.

7. **Resolve the BUILD-SPECS.md G1 go-decision gap**: either record that the scope decision was made and by whom, or align §17 status with BUILD-SPECS.md's current "scope decision, await owner go" annotation.

8. **Add a compound fleet × self-modify safety test** (`test_fleet_self_modify_cannot_collectively_capture_verifier`) with a stated mechanism — the combination is the riskiest configuration and has no dedicated gate test.
