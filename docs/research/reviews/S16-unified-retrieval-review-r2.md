# 360 Review: S16-unified-retrieval-r2 — 2026-06-27

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` |
| Proposed change | §16 "Unified retrieval — value-of-information over a typed action space" (§§16.1–16.8), revised to address round-1 six blocking items |
| Reviewer | review-360 |
| Date | 2026-06-27 |
| Round | 2 (round-1 score: 71 / needs-revision) |

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 82 | pass |
| 3 | Red-team resistance (CRITICAL) | 80 | pass |
| 4 | Implementability | 75 | pass |
| 5 | Safety / integrity (CRITICAL) | 84 | pass |
| 6 | Efficiency / cost | 82 | pass |
| 7 | Completeness | 78 | pass |
| 8 | Consistency | 82 | pass |
| 9 | Calibration / honesty | 83 | pass |

---

## Blocker resolution — per round-1 list

### Blocker 1: z-score normalization (§16.3) — RESOLVED

Round 1 cited the omission of `z(.)` from the §16.3 objective as a regression against A1's approved design (the λ/μ knife-edge of RC-1). The revised §16.3 now reads:

```
inner (over Q):   U_Q(retrieve) = z(EIG_Q) − cost(retrieve)
outer (over C):   U_C(a)        = (1−w)·z(E[ΔC | a]) + w·z(EIG_C(a))     ← A1, unchanged
```

The z-scoring is not merely added — it is explicitly flagged as mandatory with a direct RC-1 citation: "The z-scoring is mandatory — dropping it reopens v0.1's λ/μ knife-edge (RC-1)." The section now also states the exact reduction: "disable retrieval (Q empty, inner loop skipped) and the system is exactly A1 — U_Q never fires, U_C is A1 verbatim." Both requirements from blocker 1 are met.

### Blocker 2: Q representation (§16.2) — RESOLVED

The revised §16.2 specifies Q as "a Beta over P(current best answer correct | context retrieved so far). Binary by construction — it projects any output (plan, query, entity choice) onto the verifier's pass/fail — so EIG_Q reuses A1's closed-form Beta information gain verbatim." The section also addresses the multi-outcome concern from round 1 by explicitly scoping it out: "A richer multi-outcome Q is possible but out of scope; the correctness projection is what keeps EIG_Q closed-form." The representation is now a Beta(α,β) on a binary correctness projection, the lifecycle is stated ("initialised at goal start, updated by each retrieve, discarded at goal completion"), and the claim that EIG_Q reuses A1's closed form is now validly scoped to the binary-by-construction case.

### Blocker 3: §6 dispatch path (§16.1) — RESOLVED

The revised §16.1 gives a complete and honest dispatch specification. Key text: "`retrieve(store, query)` is not an outer action: it produces no child node and touches no gate. It is the inner loop inside EXPAND." It then names the two selection problems explicitly — inner `π_Q` (within EXPAND, per step, argmax z(EIG_Q) − cost) and outer `π_C` (across episodes, A1, unchanged) — and explains the "one policy" claim honestly as "one value-of-information rule dispatched at two cadences, not a single choose() over mixed action types." The round-1 adversarial objection — that calling these "one policy" obscures irreconcilable structural differences — is addressed directly. The dispatch path is now implementable without guessing.

### Blocker 4: Coverage-floor interaction (§16.7) — RESOLVED

The revised §16.7 addresses this structurally: "retrieve is inner-loop and coverage-floor-neutral (advances Q, never C), so a high-retrieval episode cannot erode the floor's quota of practice at weak skills." The structural reason is now explicit: because retrieve lives inside EXPAND and does not produce a C-action (no child node, no commit gate), it cannot consume the §5.3 coverage-floor quota, which governs outer C-actions. The floor interaction is resolved by the dispatch architecture, not patched by a guard. This is the correct and principled resolution.

### Blocker 5: §15.4 determinism caveat (§16.6) — RESOLVED

The revised §16.6 carries the §15.4 restriction forward verbatim: "Per §15.4, the within-episode search form applies only to replayable (deterministic / agent / code / sim) domains. For human learning the episode is not replayable, so the inner loop degrades to pre-step context assembly (retrieve-then-act once, same U_Q objective, no replay search) — the merge holds, the search does not." Both the restriction and the graceful degradation path are stated. The round-1 Calibration/honesty gap is closed.

### Blocker 6: EIG_Q estimation (§16.3) — RESOLVED

The revised §16.3 now states: "EIG_Q/EIG_C are A1's closed-form Beta entropy reduction computed from the current posterior at selection time — an expected gain, not a realised one. The realised held-out answer outcome at episode end is the training signal for the inner reranker (§16.5), not the per-step score." This directly resolves the round-1 gap: the expected/realised distinction is now explicit, the selection-time estimator is the A1 Beta closed form (already derived in BUILD-SPECS.md A1), and the training signal is correctly decoupled from the per-step score. A stub test is added for this in §16.8.

### Round-1 non-blocking items

- **Store-name mapping (§16.4):** The revised §16.4 maps all six modes to §10 store names explicitly (Vector, Graph, SQL, StateStore/Document, Redis, ObjectStore). The naming inconsistency is resolved.
- **"One belief" overclaim:** The revised §16 intro now reads "one objective, one substrate — two beliefs." The overclaim is corrected.
- **Check stubs (§16.8):** Three stubs are added: `test_reduces_to_A1_when_no_retrieval`, `test_retrieve_cannot_substitute_for_practice`, and `test_eig_q_expected_not_realized`. These match the three concerns from round 1 that most needed test anchors.

---

## Findings by dimension

### 1. Correctness

**Finding 1.1 — z-score normalization: resolved (see blocker 1).** The A1-faithful z-scored form is restored. The RC-1 regression is closed.

**Finding 1.2 — Q representation: resolved (see blocker 2).** The binary-by-construction Beta correctly licenses the A1 closed-form reuse. The round-1 concern about non-binary output spaces is addressed by scoping the richer case out of scope.

**Finding 1.3 — EIG_Q estimation: resolved (see blocker 6).** Selection-time expected gain (A1 Beta entropy formula) vs. episode-end realized training signal are now cleanly separated.

**Finding 1.4 — Exact reduction claim.** §16.3 states "disable retrieval and the system is exactly A1 — U_Q never fires, U_C is A1 verbatim." This is now exactly correct: the outer U_C is written as A1's formula unchanged, and with Q empty the inner U_Q never fires. The round-1 overstated-reduction objection (Finding 8.3 in round 1) is closed.

**Finding 1.5 — One residual precision gap (non-blocking).** §16.5 says the reranker is updated "under §5.2's counterfactual (leave-one-out) credit." This correctly inherits the §5.2 mechanism. However, the statement that the reranker's training signal is "the held-out answer outcome" (§16.7) and the phrasing "score the realised outcome at the held-out item level" leaves the held-out/episode-end timing slightly ambiguous for the reranker's gradient update (not for the per-step EIG_Q, which is now clear). This is a minor drafting imprecision, not a math error. It should be clarified in the build-spec companion but does not block the design section.

**Score rationale:** All six blockers are addressed; the math is now internally consistent and A1-faithful. The remaining item (finding 1.5) is a drafting nit at the build-spec level, not a design error. Score: **88**.

---

### 2. Design faithfulness

**Finding 2.1 — §6 dispatch path: resolved (see blocker 3).** `retrieve` is now specified as the inner loop inside EXPAND, not an outer action. The §6 pseudocode (lines 179–207 of ALGORITHM-v0.2) is unchanged; the "additive, no §6 changes" claim is now honest because the outer loop structure is untouched — retrieve runs inside one step, not as a competing step.

**Finding 2.2 — §5.2 hook: correctly cited.** The revised §16.5 still correctly inherits §5.2's counterfactual credit for the reranker. No regression.

**Finding 2.3 — §15.1 parallel: correctly cited.** The two-level framing (inner retrieve loop nested under outer commit loop) correctly parallels §15.4's two-level MCTS. The design faithfulness at the architecture level is solid.

**Finding 2.4 — ALGORITHM-INTEGRATIONS.md alignment.** §16 is already marked ✅ in the register ("Unified retrieval — the 5 stores as one RAG substrate... In v0.2 now"). The register's description matches the revised spec.

**Score rationale:** All gaps from round 1 are resolved. The inner-loop-inside-EXPAND framing is architecturally correct and consistent with both §6 and §15. Score: **82**.

---

### 3. Red-team resistance

**Finding 3.1 — RC-1 regression: resolved.** The z-scored objective is restored with an explicit RC-1 citation and the mandatory warning. The weights are now dimensionless fractions, not raw-scale scalars. RC-1 risk is closed.

**Finding 3.2 — RC-2 context gaming: substantially addressed, residual acknowledged.** The revised §16.7 addresses the residual attack explicitly: "Mitigation: score the realised outcome at the held-out item level (compatible with leave-one-out credit) and subject the reranker weights to the same generalization gate (§8) as any learned weight." Subjecting the reranker weights to §8's generalization gate (`Δheld-out ≥ ρ_gen · Δpublic`) is the correct defense against a reranker that correlates with held-out item format — it forces the reranker to generalize, not memorize eval patterns. Round-1's RC-2 residual is now mitigated by name with a concrete gate. A small residual remains (a reranker that game the generalization gate itself is theoretically possible but is a second-order attack already within §8's existing scope), which is acceptable.

**Finding 3.3 — RC-7 coverage floor: resolved (see blocker 4).** The structural prevention is now stated. A high-retrieval episode cannot erode the coverage floor because retrieve is inner-loop and C-neutral.

**Finding 3.4 — RC-3/RC-5/RC-6/RC-8: no regression.** Unchanged from round 1; no new interactions introduced.

**Finding 3.5 — New potential: RC-7 / starvation via U_Q dominance.** The inner `π_Q` runs `argmax z(EIG_Q) − cost`. If the EIG_Q of a cached result (near-zero cost) consistently dominates in a typical episode, the inner loop may exhaust the step budget on retrieval without executing an `apply`/`attempt`. This is bounded by the `cost` term in U_Q and the structural fact that the inner loop is inside EXPAND (it prepares context for one outer apply; it cannot replace the apply itself). This is not a new RC-7 attack — it is bounded by the architecture — but the spec could make the step-budget-within-EXPAND constraint explicit. Non-blocking.

**Score rationale:** RC-1 fully closed; RC-2 now has a concrete gate (generalization gate on reranker weights); RC-7 coverage floor structurally resolved. Residuals are second-order and within existing machinery. Score: **80**.

---

### 4. Implementability

**Finding 4.1 — §6 dispatch path: resolved.** A developer now knows: retrieve is the inner loop inside EXPAND, returns no child node, touches no gate, updates Q. The two selection problems (π_Q / π_C) and their cadences are clearly named.

**Finding 4.2 — Q representation: resolved.** Beta(α,β) on binary correctness projection; A1's closed-form EIG reused; lifecycle (init/update/discard) stated. Implementable.

**Finding 4.3 — Weight schedules.** U_Q uses `z(EIG_Q) − cost`. There is no separate w schedule for the inner loop — EIG_Q is the sole driver (beyond cost), which is actually simpler than A1's blended U_C. The outer U_C is A1 verbatim (fully specified in BUILD-SPECS.md A1 with u_ref default 0.15). This is now adequate.

**Finding 4.4 — Companion build-spec still required.** §16.8 adds check stubs but the section explicitly notes these are "design stubs for the companion build-spec." As a design section (matching §13–§15), this is appropriate. The design section itself is now implementable to the level of a design — a developer can proceed to write the companion build-spec without guessing the architecture.

**Finding 4.5 — Reranker update timing (minor).** §16.5 says the verifier signal "also trains the inner reranker." The exact hook (after episode end? after commit gate fires?) is not specified. This is a build-spec-level detail, not a design-section gap. The round-1 concern (Q representation unspecified) is resolved; this residual is at a finer level.

**Score rationale:** The three round-1 blocking gaps (§6 path, Q representation, weight schedule) are all resolved. Remaining items are build-spec details, appropriate to leave for the companion spec. Score: **75**.

---

### 5. Safety / integrity

**Finding 5.1 — §8 commit gate unchanged.** Retrieve produces no child node and triggers no gate. The commit gate is untouched. This is now explicit in §16.1 ("produces no child node and touches no gate").

**Finding 5.2 — §14 calibration unchanged.** The outer U_C uses EIG_C which consumes the §14-calibrated posterior (A1 verbatim). Q's calibration is not addressed explicitly — but Q is episode-scoped and discarded; a miscalibrated Q can only cause suboptimal retrieval within an episode, not a miscalibrated durable posterior. This is the same analysis as round 1; unchanged and correct.

**Finding 5.3 — RC-7 coverage floor: resolved.** Retrieve is structurally C-neutral; the floor governs outer C-actions only (§16.7 explicit). No safety concern remains.

**Finding 5.4 — Q→C leakage guard: stated.** "Q is discarded at goal completion; only verifier-gated outcomes touch C (§8)" — §16.7. Unchanged and correct.

**Finding 5.5 — Reranker weights under §8 generalization gate (new).** §16.7 explicitly subjects the reranker weights to §8's generalization gate. This is a safety-positive addition: the reranker now faces the same anti-memorization gate as any other learned weight. No integrity gate is weakened.

**Score rationale:** No gate or calibration layer is weakened. The coverage-floor concern from round 1 is structurally resolved. The generalization gate on reranker weights is a safety strengthening over round 1. Score: **84**.

---

### 6. Efficiency / cost

**Finding 6.1 — Hot-path cost remains bounded.** U_Q includes the cost term; §16.6 re-states the latency bound; §16.4 preserves the hot/cold split with cache as the "act fast" layer. No change from round 1.

**Finding 6.2 — EIG_Q computation.** With Q as a Beta(α,β) binary, EIG_Q is the A1 closed form — O(1) per step. No hot-path cost regression.

**Finding 6.3 — No new LLM calls.** Retrieve is a store query. Unchanged.

**Finding 6.4 — Inner loop cost accounting.** The inner loop fires inside EXPAND, which runs on a cloned checkpoint (§6 line: "weight actions run on a CLONED checkpoint"). Multiple retrieve steps per EXPAND call are bounded by the cost term in U_Q — a cache hit has near-zero cost and dominates; expensive multi-hop graph queries are penalized. The design is cost-aware.

**Score rationale:** Cost structure is sound and slightly better-specified than round 1 (the inner-loop-inside-EXPAND clarification makes the cost accounting cleaner). Score: **82**.

---

### 7. Completeness

**Finding 7.1 — Q lifecycle now fully specified.** Init, update (per retrieve step), discard (at goal completion). Complete.

**Finding 7.2 — Coverage floor interaction: resolved.** The structural answer (inner-loop / C-neutral) is stated. Complete.

**Finding 7.3 — EIG_Q estimation method: resolved.** A1 Beta entropy formula at selection time; realised outcome as training signal; distinction is explicit. Complete.

**Finding 7.4 — Check stubs added (§16.8).** Three stubs cover the three principal design claims: A1 reduction, coverage-floor non-substitution, and EIG_Q expected-not-realized. Adequate for a design section.

**Finding 7.5 — Remaining gap: step budget within EXPAND.** The number of retrieve steps the inner π_Q may take within a single EXPAND call is bounded by cost but not explicitly capped. A pathological scenario: EIG_Q is high for many sequential retrieves (each sharpens Q a little), and each retrieve has a near-zero cost (cached results). The inner loop could take many steps within one EXPAND call. The cost term and the cache's "act fast" design mitigate this in practice, but an explicit per-EXPAND retrieve budget (or a U_Q stopping rule when gain < threshold, analogous to §15.3's diminishing-returns floor) is a completeness gap. Non-blocking for a design section, but should be in the companion build-spec.

**Score rationale:** All six round-1 gaps resolved. One new non-blocking gap (step budget within EXPAND). Score: **78**.

---

### 8. Consistency

**Finding 8.1 — §15.4 determinism caveat: resolved.** §16.6 carries the restriction forward explicitly with the degradation path. The round-1 inconsistency is closed.

**Finding 8.2 — Store-name mapping: resolved.** §16.4 maps all six modes to §10 store names. The naming inconsistency is closed.

**Finding 8.3 — A1 reduction claim: resolved.** The outer U_C is now written as A1 verbatim; the reduction is exact (disable retrieval → U_Q never fires → U_C = A1). Round-1 Finding 8.3 is closed.

**Finding 8.4 — Two-level MCTS alignment.** §16.1 framing (inner π_Q / outer π_C, two cadences) correctly parallels §15.4's two-level structure. Consistent.

**Finding 8.5 — §5.3 coverage floor consistency.** §16.7 aligns correctly with §5.3: the floor governs `choose(n, cands)` (the outer select), retrieve operates inside EXPAND (downstream of select). No contradiction.

**Score rationale:** All three round-1 consistency gaps resolved. The section is now internally consistent with §§2–15. Score: **82**.

---

### 9. Calibration / honesty

**Finding 9.1 — "One belief" overclaim: resolved.** The intro now reads "one objective, one substrate — two beliefs." The revision is minimal but accurate. The spec body consistently distinguishes Q and C throughout.

**Finding 9.2 — §15.4 restriction omission: resolved.** §16.6 carries the caveat. The spec does not overclaim the within-episode search for human domains.

**Finding 9.3 — RC-2 residual: acknowledged.** §16.7 names the residual attack (reranker correlating with held-out item format) and proposes a concrete mitigation (generalization gate). The acknowledgment is honest and the mitigation is specified.

**Finding 9.4 — w_Q/w_L knob.** The round-1 observation (§16.7 calls it "a deliberate, logged knob, not a constant") is no longer relevant in the same form — the revised §16.3 drops the three-weight scalar form in favor of two separate U_Q and U_C objectives. There is no "w_Q/w_L" scalar anymore; the "solve-now vs learn" tradeoff lives "across the two loops (how much to retrieve before committing), never collapsed into one scalar." This is an honest and clean resolution.

**Finding 9.5 — EIG_Q expected-not-realized: explicitly stated.** The section now says "an expected gain, not a realised one" in §16.3, and this is the most important calibration claim (an implementer must not confuse the two). The check stub in §16.8 reinforces it.

**Score rationale:** All three round-1 calibration gaps resolved. The section's honesty level is now appropriate for a design section — it names what is delegated to the build-spec and what is left for empirical tuning. Score: **83**.

---

## Strongest adversarial objection

The round-1 adversarial objection (that calling retrieve "a first-class action" glosses an irreconcilable structural difference between Q-actions and C-actions) was the design's hardest problem, and the author resolved it correctly — by retiring the "one flat argmax" claim and naming the two distinct selection problems (π_Q / π_C) at two cadences. That was the right move.

The hardest objection remaining after all nine dimensions is this:

**The inner π_Q is described as `argmax z(EIG_Q) − cost`, but there is no stopping condition for the inner loop.** The outer loop has a rich termination structure (commit gate, circuit breaker, budget). The inner loop terminates only when cost forces it (the step budget is implicit in the cost term, not explicit). Unlike §15.3's revisit loop — which has four named termination conditions (significant gain fails, diminishing-returns floor, per-revisit budget, circuit breaker) — the inner retrieve loop has one: cost. In a hot-cache scenario (cost ≈ 0 for cached results), the inner loop could run to an arbitrary number of steps without a significant-gain check analogous to `significant(ΔH, SE)` in §15.3.

This is a design gap, not a fatal flaw — the cost term is the right lever and the cache structure bounds practical behavior — but the spec would be more rigorous if the inner loop had an explicit information-theoretic stopping rule (e.g. stop when `EIG_Q < threshold` analogous to §15.3's `significant(ΔH, SE) fails → assimilated → stop`). The companion build-spec should add this. It does not block the design section, but a future reviewer of the build-spec should check for it.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=88, RedTeam=80, Safety=84) = 80
weighted_mean   = (88×2 + 82 + 80×2 + 75 + 84×2 + 82 + 78 + 82 + 83) / 11
              = (176 + 82 + 160 + 75 + 168 + 82 + 78 + 82 + 83) / 11
              = 986 / 11
              = 89.6
overall         = min(80, 89.6) = 80
```

**Overall confidence: 80 / 100**

---

## Verdict

**ready-for-approval**

All six round-1 blocking changes are genuinely resolved, not just reworded. All three CRITICAL dimensions clear 70 (Correctness 88, Red-team resistance 80, Safety 84). The aggregate scores 80, meeting the threshold. The residual items (inner-loop stopping condition, reranker update timing) are build-spec-level details, not design-section blockers.

The companion build-spec should address:
1. An explicit stopping condition for the inner retrieve loop (analogous to §15.3's `significant(ΔH, SE) fails → stop`), particularly for the low-cost cached-result case.
2. The exact hook for the reranker gradient update (after episode end? after commit gate?) — a timing detail left open in §16.5.
3. A per-EXPAND retrieve step budget as an explicit parameter (not just an implicit cost floor).
