# 360 Review: S16-unified-retrieval — 2026-06-27

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` |
| Proposed change | Add §16 "Unified retrieval — value-of-information over a typed action space" which merges a 5-store RAG into the learner by making `retrieve` a first-class typed action scored by the same value-of-information objective as learning. |
| Reviewer | review-360 |
| Date | 2026-06-27 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 72 | weak |
| 2 | Design faithfulness | 74 | weak |
| 3 | Red-team resistance (CRITICAL) | 71 | weak |
| 4 | Implementability | 62 | blocking |
| 5 | Safety / integrity (CRITICAL) | 76 | pass |
| 6 | Efficiency / cost | 80 | pass |
| 7 | Completeness | 65 | blocking |
| 8 | Consistency | 71 | weak |
| 9 | Calibration / honesty | 78 | pass |

---

## Findings by dimension

### 1. Correctness

**Finding 1.1 — Missing z-score normalization in §16.3 objective (RC-1-adjacent, non-trivial).**
The approved A1 objective (`BUILD-SPECS.md` A1) reads:
```
U(a) = (1-w)·z(E[Δcompetence|a]) + w·z(EIG(a))
```
where `z(.)` is the candidate-set z-score, explicitly included because the two terms have different natural scales and must be commensurable before weighting. §16.3's "generalisation of A1" drops `z(.)`:
```
U(a) = w_L · E[ΔC | a] + w_Q · EIG_Q(a) + w_C · EIG_C(a) − cost(a)
```
`E[ΔC]` is a competence delta (range ~ 0–1 in Beta-posterior units); `EIG_Q` and `EIG_C` are information-gain quantities whose scale depends on prior entropy and episode length. Without normalization, the three weights `w_L, w_Q, w_C` are unit-specific scalars rather than dimensionless fractions. Tuning them becomes model-dependent in a way that A1's z-scored form avoids. This is not merely a notational gap — it reopens the commensurate-scale problem A1 closed (see A1 review notes: "kills v0.1's λ/μ knife-edge").

**Finding 1.2 — EIG_Q type assumption underspecified.**
§16.3 claims `EIG_*` terms "reuse A1's closed-form Beta information gain." A1's closed-form applies to a Beta(α,β) binary-outcome cell. `Q`, defined in §16.2 as "the posterior over the correct action/output," is not guaranteed to be binary. For structured outputs (multi-step plans, entity selections, SQL queries), modeling `Q` as a single Beta is an approximation that may not hold. The section does not constrain `Q` to a binary form, so the claim "reuse A1's closed-form" is only correct for binary answer domains; for richer output spaces it requires justification or qualification. Line of concern: §16.2 and §16.3 together.

**Finding 1.3 — Correct claims (no error found):** The Q→C boundary in §16.2 and §16.7 (Q discarded at goal completion, only verifier-gated outcomes touch C) is logically consistent. The counterfactual credit inheritance from §5.2 for retrieval reranking (§16.5) correctly reuses leave-one-out credit without modification.

**Score rationale:** Finding 1.1 is a substantive math gap (not a sign error or impossibility, but a regression against an already-approved design choice). Finding 1.2 is a domain-coverage limitation. Neither is a proof of incorrectness, but both require explicit resolution. Score: **72**.

---

### 2. Design faithfulness

**Finding 2.1 — retrieve not integrated into §6 loop pseudocode.**
§16.1 states "`retrieve(store, query)` joins `apply`/`attempt`, `practice`, `revisit`, and `grow` as a typed action." The §6 main loop pseudocode (ALGORITHM-v0.2, lines 179–207) has one path: SELECT → EXPAND (`apply(a, node, ctx)`) → EVALUATE (`Eval.score`) → GROW → BACKUP → COMMIT. All actions in §6 produce a `child` node (a new checkpoint candidate) that passes through `commit_gate`. `retrieve` does not produce a child checkpoint; it populates `Q` (episode-scoped) without creating a new node or triggering `commit_gate`. §16 claims it is "additive, no §1–§15 mechanism changes," but it introduces an action type whose execution path differs fundamentally from §6's uniform `apply → child` structure. The section does not specify at which step of the §6 loop `retrieve` is dispatched, nor how the loop handles an action that modifies `Q` rather than advancing the node graph.

**Finding 2.2 — §5.2 hook exists and is correctly cited.**
`ALGORITHM-v0.2` §5.2 (lines 148–156) already defines `retrieve(n, task)` with state-conditioning, hold-out exclusion, and counterfactual credit. §16 cites this correctly as the existing hook it elevates. The claim "no §1–§15 mechanism changes" holds for §5.2's implementation, but the gap is at §6 integration, not §5.2 reuse.

**Finding 2.3 — §15.1 hook exists and is correctly cited.**
§15.1 introduces `revisit(D)` as a first-class action chosen by the §13.1 objective. §16's typing of `retrieve` as a parallel action riding the same selection rule is design-faithful at the objective level.

**Score rationale:** The conceptual hooks all exist (§5.2, §13.1, §15.1, §10), and the section correctly identifies them. The gap is a missing integration spec at §6 level — where exactly in the main loop does `retrieve` execute, and how does the loop handle the Q-path? This is architectural incompleteness rather than a faithfulness violation, but it means the "additive, no §6 changes" claim is not fully supported. Score: **74**.

---

### 3. Red-team resistance

**Finding 3.1 — RC-1 regression risk from dropped z-score (re-cited from Dim 1).**
A1 was specifically designed to kill the "λ/μ knife-edge" of v0.1 (RC-1, BUILD-SPECS.md A1 review notes). §16.3's three-weight objective without z-normalization reintroduces a version of this: `w_L, w_Q, w_C` must be tuned against raw-scale quantities, and if their natural scales differ by an order of magnitude, the policy collapses to whichever term dominates — exactly the failure mode A1's normalization was designed to prevent.

**Finding 3.2 — RC-2 residual: retrieval-context correlation with held-out eval patterns.**
§16.7 correctly cites P1 (held-out scoring) and §5.2 counterfactual credit as mitigations for retrieval hacking. A residual attack remains: a learned retriever could encode, in its rerank weights, correlation with held-out evaluation *format* (not the answers themselves, but the type of items the evaluator tends to test). This is a context-level RC-2 attack on Q rather than a direct verifier-gaming attack on C. The held-out oracle for Q is the final answer outcome — measured after goal completion — so within-episode retrieval steps that nudge Q toward a good held-out outcome without genuinely solving the problem could inflate EIG_Q estimates. This is addressed partially but not fully: §16.7 does not discuss whether the held-out answer outcome is measured at the item level (compatible with counterfactual credit) or only at goal completion.

**Finding 3.3 — RC-7 coverage floor interaction.**
§16.3 notes `w_Q` ("solve now") vs `w_L` ("learn") as "the §13.1 exploration knob, never averaged into one scalar." However, if `retrieve` actions consistently score high on `EIG_Q` in typical deployments, they could crowd out `practice`/`attempt` actions in the policy without violating any gate — because `retrieve` modifies Q, not C, it does not consume any coverage-floor quota. A learner that mostly retrieves and rarely practices could satisfy the §5.3 coverage floor only in letter (the floor counts practice actions at skills; retrieve actions are neutral). §16 does not address whether `retrieve` actions are excluded from coverage-floor accounting or whether they count toward it for the accessed skill.

**Finding 3.4 — RC-3/RC-5/RC-6/RC-8: No regression found.** The `Q`→`C` boundary (§16.2/§16.7) prevents retrieved context from contaminating the durable competence posterior. Retrieval does not interact with promotion (RC-8), tree invalidation (RC-6), or growth provisioning (RC-3). No regression on these.

**Score rationale:** Three meaningful residual attack surfaces (RC-1 scale regression, RC-2 context-level gaming, RC-7 coverage-floor bypass). None is a full re-opening of a root cause at the level the red-team defined (a catastrophic day-one failure), but RC-1 is structurally the same class of error A1 was built to close. Score: **71**.

---

### 4. Implementability

**Finding 4.1 — §6 dispatch path unspecified.**
A developer cannot implement `retrieve` as a §6 action without knowing: (a) whether it runs as an alternate branch of the SELECT → EXPAND → EVALUATE → GROW → BACKUP → COMMIT loop, or as a sub-step within EXPAND, or as a pre-SELECT hot-path step; (b) what the return type of `retrieve` is in the loop context (it cannot be a `child` node since it doesn't update `C`); (c) how the loop handles the fact that a `retrieve` decision does not need to go through `commit_gate`. Without this, the claim that `retrieve` is a "first-class action" that `π` selects alongside `practice`/`attempt` has no implementable form in §6.

**Finding 4.2 — Q belief representation unspecified.**
§16.2 defines Q as "the posterior over the correct action/output." No representation is given: is Q a Beta(α,β) over a binary correct/incorrect? A categorical distribution? A scalar confidence? A vector embedding? The representation is load-bearing because `EIG_Q` must be computable from it, and the "discard at goal completion" rule requires a clear lifecycle. Without a representation, `EIG_Q` cannot be implemented.

**Finding 4.3 — w schedule for w_L/w_Q/w_C unspecified.**
A1 gives a fully specified `w` schedule (mean frontier uncertainty / u_ref, with default u_ref = 0.15). §16.3 introduces three independent weights `w_L, w_Q, w_C` with no schedule, no coupling constraint (they need not sum to 1), and no default values. How `w_Q` varies with goal progress, retrieved context quality, or learner state is unspecified.

**Finding 4.4 — No acceptance tests.**
§13–§15 each include no tests either, matching the pattern of design-only sections. §16 is also design-only. Compared against approved build-specs (A1–B3), which all carry detailed test suites, §16 lacks tests at the level needed to gate an implementation. This is acceptable for a design-only section but means it cannot be implemented without a companion build-spec.

**Score rationale:** Three substantial gaps that would require a developer to make major architectural decisions without guidance. Score: **62**.

---

### 5. Safety / integrity

**Finding 5.1 — §8 gate not weakened.**
The key safety boundary is that only verifier-gated held-out outcomes touch `C` (§16.2/§16.7). The `commit_gate` (§8) is unchanged; `retrieve` does not bypass it. No safety gate is weakened.

**Finding 5.2 — §14 calibration not bypassed.**
`EIG_C` (the diagnostic term in §16.3) is the same as A1's EIG, which consumes the §14-calibrated posterior. If §16 is implemented consistently, `EIG_C` and `E[ΔC]` both use calibrated SE, so §14's protection is inherited. `EIG_Q` is a new term whose calibration requirement is not stated, but since it acts only on Q (episode-scoped) and not on C, a miscalibrated `EIG_Q` cannot harm the durable competence posterior directly — it can only lead to suboptimal retrieval choices within an episode.

**Finding 5.3 — RC-7 coverage-floor interaction (re-cited from Dim 3).**
The one safety-relevant gap: if `retrieve` actions can satisfy the spirit of "action budget" without advancing the coverage floor, a high-`w_Q` policy could calcify weak skills. This is a learning-safety concern, not an integrity-gate concern. The §8/§14/§5.3 gates are not changed; the risk is behavioral (policy degeneracy) rather than mechanism compromise.

**Finding 5.4 — Anti-gaming on Q correctly anchored.**
§16.7 anchors `EIG_Q` against held-out answer outcome (P1) and §5.2 counterfactual credit. The Q→C leakage guard is correctly stated. No §4 verifier weakening found.

**Score rationale:** No gate or calibration layer is weakened or bypassed. The one concern (coverage floor interaction) is a policy-effectiveness risk, not a safety-mechanism regression. Score: **76**.

---

### 6. Efficiency / cost

**Finding 6.1 — Hot-path retrieval cost is bounded.**
§16.3 includes `−cost(a)` in the objective; §16.6 explicitly notes the latency term bounds per-step retrieval; §16.4 cites the cache store as the "act fast" layer. Multi-store retrieval (vector + graph + truth + state + cache) could be expensive if all five are queried per decision, but §16.4 implies `π` learns which store to call — not all five are queried per action. No O(n²) or worse addition is introduced.

**Finding 6.2 — EIG_Q computation cost.**
A1's `EIG_cell` is O(1) per cell via the Beta closed form. If `EIG_Q` is also Beta (binary Q), it is O(1). If Q is over a structured space, cost is higher but unspecified (see Dim 1 Finding 1.2). Under the binary assumption, no hot-path cost regression.

**Finding 6.3 — No new LLM calls introduced.**
`retrieve` is a store query, not an LLM inference call. No new LLM calls.

**Score rationale:** Cost is well-bounded under the stated design. The main unknown is EIG_Q computation for non-binary Q, but the section hedges this with the latency cost term. Score: **80**.

---

### 7. Completeness

**Finding 7.1 — Q belief representation and lifecycle not specified** (see Dim 4). This is a completeness gap — without Q's representation, edge cases like "goal completion during retrieval," "retrieve with empty context," and "multiple retrieve calls per episode" cannot be reasoned about.

**Finding 7.2 — Coverage floor interaction not resolved** (see Dim 3.3). Whether `retrieve` actions count toward `f_min` is unspecified.

**Finding 7.3 — w_L/w_Q/w_C schedule and defaults missing** (see Dim 4). No defaults, no coupling constraint.

**Finding 7.4 — §16.3 EIG_Q measurement timing.** §16.7 says `EIG_Q` is scored against the held-out answer outcome. `EIG_Q(a)` at decision time is an *expected* gain, not a realized one — the realized gain is only known at episode end. The section does not specify how the expected gain is estimated (empirically from past episodes? analytically from Q's current distribution?). Without this, `EIG_Q` is not computable at the time `π` needs to choose.

**Finding 7.5 — No test strategy.** Accepted for design-only sections (§13–§15 also lack tests), but two critical regression tests are missing even as design stubs: one that checks `retrieve` does not substitute for `practice` (coverage-floor) and one that checks the objective reduces to A1 when `w_Q = 0`.

**Score rationale:** Multiple open-interface and open-parameter gaps. Score: **65**.

---

### 8. Consistency

**Finding 8.1 — Two-cadence claim partially inconsistent with §15.4.**
§16.6 states retrieve runs "hot, within-episode (over Q, ms)." The two-cadence framing cites §15.4's two-level MCTS. However, §15.4 explicitly limits within-episode search to "deterministic domains only" (ALGORITHM-v0.2, line 375: "Where an episode is replayable (agents in code/sim domains)"). §16.6 applies the within-episode framing universally — including human-learning domains where, as §15.4 notes, "the episode is not replayable; revisit degrades to re-reading the record." For human-learning deployments, the within-episode retrieval hot loop may not be coherent. §16 does not carry §15.4's restriction forward.

**Finding 8.2 — Store count discrepancy.**
§10 (ALGORITHM-v0.2, line 266) defines five stores: `{Redis, Graph, Vector, SQL, ObjectStore+Registry, Document}` — that is six names, grouped as three hot + three cold. §16.4 enumerates six retrieval modes: vector, graph, truth, state, cache, artifact. The mapping is not one-to-one obvious: "state" in §16.4 corresponds to StateStore/Document in §10; "artifact" to ObjectStore+Registry; "cache" to Redis/CacheStore. This is not a correctness error but a naming inconsistency that could confuse implementation.

**Finding 8.3 — §16.3 objective vs A1 reduction.**
§16.3 claims it "generalizes A1." If `w_Q = 0` and `w_C` maps to `w`, and `w_L` maps to `(1-w)`, the reduction is structurally: `U(a) = w_L·E[ΔC] + w_C·EIG_C − cost` vs A1's `(1-w)·z(E[Δc]) + w·z(EIG)`. The z-scoring discrepancy (Finding 1.1) means the reduction is not exact. The claim of strict generalization is overstated.

**Score rationale:** One genuine inconsistency (§15.4 determinism restriction not carried forward), one naming issue, one overstated reduction claim. Score: **71**.

---

### 9. Calibration / honesty

**Finding 9.1 — The "one algorithm, one belief, one substrate" claim is aspirational.**
§16 opens with: "the RAG system and the learner become one algorithm, one belief, one substrate — no second system to keep in sync." This is true conceptually but overstated for a design section. Q and C are maintained separately (§16.2 calls them "two-belief state"); the unified *objective* selects between them, but they are distinct data structures with different lifecycles. The "one belief" framing is a helpful conceptual compression, but the spec itself requires two beliefs.

**Finding 9.2 — RC-2 residual risk is acknowledged partially.**
§16.7 lists four risks, addresses three concretely. The context-level RC-2 attack (context encoding held-out eval format) is the one gap (see Dim 3). The section acknowledges "retrieval hacking" as a risk and names a mitigation; the mitigation is partial.

**Finding 9.3 — Honest about determinism restriction? No.**
§15.4's determinism restriction is not surfaced in §16.6, which could leave a reader believing the hot-path retrieve loop applies universally. The section should carry §15.4's caveat explicitly.

**Finding 9.4 — Uncertainty about w_L/w_Q/w_C schedule honestly admitted? Partially.** §16.7 calls `w_Q/w_L` "a deliberate, logged knob, not a constant," which is an honest admission that no schedule is known yet. This partially acknowledges the gap.

**Score rationale:** The "one belief" framing is a mild overclaim; the §15.4 restriction omission is a concrete honesty gap. Otherwise the section is reasonably calibrated. Score: **78**.

---

## Strongest adversarial objection

**The section's central claim — that retrieval and learning are "the same operation on two beliefs" unified by one policy — is not realized by the design, and the gap is not cosmetic.**

The §6 loop is a graph-search over checkpoint nodes; every action `a` produces a child node that advances (or is rolled back from) the node graph. `retrieve` does not advance the node graph — it populates Q within an episode. This means `retrieve` cannot actually run "as" a §6 action in the sense the section claims; it must run *inside* an episode step, subordinate to whatever §6 action owns that step. The "one policy π" that selects among `retrieve`, `practice`, `attempt`, `revisit`, and `grow` is stated but not structured: `π` runs at different timescales for Q-actions (within-episode, ms) and C-actions (across-episode, gate-clocked), and the selection problem is different in each regime (what context to fetch vs. which skill to practice next). Calling them "one policy" is conceptually appealing but glosses the structural difference that makes them hard to unify in a single `choose()` call. A developer asked to implement "one policy that selects among all five typed actions" would immediately face this and have to resolve it without guidance from the spec. The strongest objection is: **the spec names the unification it cannot yet specify, and the naming may make the design feel closed when the hardest design decision — how the §6 loop dispatches Q-actions vs. C-actions — remains entirely open.**

---

## Aggregate confidence

```
critical_floor  = min(Correctness=72, RedTeam=71, Safety=76) = 71
weighted_mean   = (72×2 + 74 + 71×2 + 62 + 76×2 + 80 + 65 + 71 + 78) / 11
              = (144 + 74 + 142 + 62 + 152 + 80 + 65 + 71 + 78) / 11
              = 868 / 11
              = 78.9
overall         = min(71, 78.9) = 71
```

**Overall confidence: 71 / 100**

---

## Verdict

**needs-revision**

The overall score (71) falls below 80 and both Correctness and Red-team resistance are in the 71–72 range (below 80, though above the 70 hard threshold for CRITICAL dimensions). The design is architecturally coherent and the conceptual contribution is sound — this is a weak but fixable set of gaps, not a fundamental flaw.

### Blocking changes required to clear 80

1. **Restore z-score normalization in §16.3** (or explicitly justify why raw-scale weighting is correct). The approved A1 objective uses `z(.)` to make terms commensurable; §16.3 must either inherit that normalization or explain why the three new weights are dimensionally compatible without it. State the explicit reduction from §16.3 to A1 when `w_Q = 0`.

2. **Specify Q's representation** (§16.2). State what probability model Q uses (Beta binary? categorical? scalar?) so that EIG_Q is computable in closed form and the Beta-EIG reuse claim from A1 is either validated or qualified to binary domains.

3. **Specify the §6 dispatch path for `retrieve`** (§16.1/§16.6). State explicitly at which step of the §6 loop `retrieve` executes: is it a pre-EXPAND hot step, a sub-step within EXPAND, or a separate loop at a finer timescale? Clarify how a `retrieve` decision differs from a `practice` decision in the policy's call signature (no child node, no commit gate, Q-update instead of C-update).

4. **Resolve the coverage-floor interaction** (§16.3/§5.3). State whether `retrieve` actions count toward the §5.3 `f_min` coverage floor for any skill, and if not, add a guard that prevents high `w_Q` from allowing the policy to retrieve rather than practice weak skills, thereby bypassing the coverage floor.

5. **Carry §15.4's determinism restriction into §16.6**. Add a caveat that the within-episode retrieval hot loop applies to replayable (deterministic/agent) domains; for human-learning domains, within-episode retrieve degrades to a pre-step context assembly, not a search.

6. **Specify the EIG_Q estimation method** (§16.3/§16.7). Clarify that `EIG_Q(a)` at selection time is an *expected* gain estimated from Q's current distribution (e.g. analogously to A1's Beta entropy formula), not a realized gain available only at episode end. Provide the estimator or cite the model it requires.
