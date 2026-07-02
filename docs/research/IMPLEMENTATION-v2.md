# MDLP v0.2 — Full Implementation Document (for turing-agents)

**For:** the turing-agents build team (Claude Code build agents + `@you`)
**From:** the MDLP research project · **Date:** 2026-06-27 · **Status:** build-ready; open at **M0**
**Scope:** the complete current algorithm — the hardened core (§1–§12) **plus** every additive layer (§13 Tutor, §14 Calibration, §15 Re-visiting, §16 Unified retrieval, §17 Self-modification, §18 Multi-agent, §19 Self-calibrating gate) **plus** the six gate-approved build-specs (A1, A5, B1, B2, B3, B4).
**Relationship to existing docs:** extends [`IMPLEMENTATION.md`](IMPLEMENTATION.md) (the original M0–M2 core module guide) and is sequenced by [`HANDOVER-v2.md`](HANDOVER-v2.md) (phases + locked decisions). Spec of record: [`ALGORITHM-v0.2-pathway-learner.md`](ALGORITHM-v0.2-pathway-learner.md); approved capability specs + params + tests: [`BUILD-SPECS.md`](BUILD-SPECS.md). Where this doc and the spec disagree, **the spec wins** — file an issue.
**Scope rule:** authored in the MDLP repo; the turing-agents repo is managed separately. All file/line refs are into `turing-agents/mdlp/`; board IDs into `turing-agents/tasks/BOARD.md`.

---

## 0. How to read this document

1. Read [`HANDOVER-v2.md`](HANDOVER-v2.md) §1–§5 first — current honest status (M0 not yet real), the locked decisions, the non-negotiables.
2. Then this doc §1 (milestones) to see what lands when, §3 (package layout) for the map, §5 (the verifier — the linchpin), then the module sections you're assigned.
3. Keep [`BUILD-SPECS.md`](BUILD-SPECS.md) open for the exact params/tests of A1/A5/B1/B2/B3/B4 — this doc gives the integration points and signatures; BUILD-SPECS gives the gate-approved constants.

**The one rule that governs all of it:** every accept/reject/commit/admit/promote decision is a **statistical** test on **held-out** evidence (P1), and every `add` has an **inverse** (P2). If a module you're writing can't express its decision as `significant(Δ, SE)` on held-out data, stop and raise it.

---

## 1. Milestones — the gated arc

Build in milestones, each **blocked on the prior's acceptance gate**. Never parallelize past a gate.

| Milestone | Lands | Spec | Gate to exit |
|---|---|---|---|
| **M0** | core loop measures *real* learning: state, the verifier, the Tutor with **A1** info-gain in the loop, §14 calibration, embedded stores | §1–§12, §13, §13.1/A1, §14 | **Held-out competence beats a frozen no-learning baseline beyond `z·SE` on a real corpus, and the memorization/hard-code probes fail as designed.** (NO-GO is a valid, documented outcome.) |
| **M1** | open schema + the capability suite: growth `g`, **B1** misconceptions, **B2** prereq-gap, **B4** spacing, **A5** warm-start, **§15** re-visiting, **§16** unified retrieval | §5.1, §15, §16, B1/B2/B4/A5 | schema grows, 100% live nodes scorable, bounded orphan/oscillation; a fresh adversarial re-review (C0) precedes it |
| **M2** | the weight axis: artifact store, rejection-sampling curator, QLoRA/TRL train, vLLM rollout, two-stage promotion | §9 | a promotion raises held-out competence with no monitored regression, under the two-stage reversible procedure |
| **M3** | self-modification + fleet: §17 SOLVE/JUDGE, code two-stage promotion, §18 multi-agent + **B3** transfer, §19 self-calibrating gate | §17, §18, §19, B3 | self-mod raises held-out under the partition + code-promotion; fleet co-evolves without a P1 break; §19 holds `r̂ ≤ α_gate` without ever dropping below the §8 floor |

**Why this order:** M0 proves the premise (it learns). M1 opens the schema and adds the human-relevant capabilities. M2 is optional/expensive (GPU). M3 is the frontier — only meaningful once M0/M1 are solid. §19 (self-calibrating gate) *may* be prototyped at M1 in shadow (it only needs logged decisions) but is not load-bearing until M3.

---

## 2. Non-negotiable constraints (carry-forward — do not break)

1. **`app/` stays pure-stdlib.** Nothing under `app/` imports `mdlp`. `mdlp` is **opt-in**, never required; a project runs identically without it.
2. **`mdlp` never edits a project's source or canonical logs** — reader + rebuildable-derived-store writer only.
3. **Reward only on held-out (P1).** Held-out items never enter the agent's context. Public split is for reproducibility, never reward.
4. **Gates are statistical, not scalar** — `significant(Δ, SE)` (§2), never a bare threshold.
5. **Every `add` has an inverse (P2).** Growth ↔ prune/merge/decay; promote ↔ rollback; transfer ↔ quarantine-evict; misconception admit ↔ retire.
6. **The verifier precondition.** Only skills with a reliable verifier (`admit`) enter autonomous learning. Soft-judge skills are the NO-GO regime.
7. **(M3) The SOLVE/JUDGE partition (§17.1)** — once self-modification exists, the measurement+safety core is immutable to the agent. See §11 below for the concrete manifest.

---

## 3. Package layout (`turing-agents/mdlp/`)

Extends `IMPLEMENTATION.md §1`. New M1–M3 modules marked `←`.

```
mdlp/
  __init__.py
  cli.py                      # `mdlp` CLI (version, agents, link, run)
  pyproject.toml
  requirements.txt            # core: numpy, networkx, scikit-learn/sentence-transformers, anthropic
  requirements-weight.txt     # M2 GPU extras: torch transformers peft trl vllm bitsandbytes

  state.py                    # ProbabilisticState — dual Beta, n_min, significant()  (§2,§3)  +A5 warm-start
  eval/                       # the reward (the linchpin)                              (§4)
    __init__.py
    verifier.py               # PytestVerifier + trajectory-shape + counterfactual
    reliability.py            # admission by precision lower-CI vs audit set
    splits.py                 # public/held-out, isomorphic variants
  decision.py                 # DecisionEngine / π — learning-gain + A1 info-gain       (§5.3,§13.1,A1)
  tutor.py                    # Tutor strategist + Teacher selection + LearnerAdapter   ← §13
  teachers/                   # pluggable TeacherAdapters (teaching strategies)         ← §13
  adapters/
    logs.py                   # read canonical jsonl logs (read-only)
    runner.py                 # ClaudeRunner (live) + FakeRunner (tests)
    learner.py                # AgentLearnerAdapter; HumanLearnerAdapter (C1, design)   ← §13/C1
  graph.py                    # PathwayGraph — soft reachability, prereqs               (§5.2) +B2
  growth.py                   # GrowthRule g — provision_suite, merge/prune/decay        (§5.1) +B1
  calibration.py              # Calibrator — ECE/Brier, isotonic, n_eff                  ← §14
  revisit.py                  # surprise loop — revisit(D), info-gain trigger/stop       ← §15
  retrieval.py                # unified retrieval — (C,Q) belief, U_Q, multi-store        ← §16
  scheduler.py                # forgetting-aware spacing                                  ← §B4
  calibgate.py                # self-calibrating gate — per-clause attribution           ← §19
  selfmod/                    # self-modification axis                                    ← §17 (M3)
    partition.py              # SOLVE/JUDGE manifest + static no-write-path check
    promote_code.py           # two-stage code promotion (shadow → hot-swap)
  fleet/                      # multi-agent populations                                  ← §18 (M3)
    coverage.py               # fleet-coverage term
    transfer.py               # B3 zero-trust cross-agent transfer
  loop.py                     # the main MCTS loop + commit/rollback gate                (§6,§7,§8)
  gate.py                     # the four-clause commit gate (statistical∧gen∧cum∧safe)   (§8)
  weight/                     # the parameter axis                                       (§9, M2)
    curator.py  train.py  rollout.py  promote.py
  stores/                     # 5-store data layer (ports + adapters)                    (§10)
    ports.py  config.py  rebuild.py  schemas.py
    embedded/  full/          # SQLite/networkx/local-vec  |  pg/mongo/qdrant/neo4j/redis/s3
  domain/
    runner.py                 # task runner (LLM attempts coding tasks)
    tasks/                    # M0 corpus: prompt + public tests + held-out tests
  tests/                      # unit (hermetic) + integration (live tier) + redteam/
```

---

## 4. The substrate — canonical logs (read-only)

`adapters/logs.py` reads `.claude/memory/{interactions,audit,evolution-log}.jsonl`, `skills/**/SKILL.md`, `lessons.md`. **Read-only.** All derived state (`stores/`) is rebuildable from these. `interactions.jsonl` schema: `{"id","date","intent","did","learned","actor"}`, one JSON object/line.

---

## 5. The verifier & domain (M0 — the linchpin)

Everything rests on this. Build it first and prove it adversarially before anything else.

**`eval/verifier.py :: PytestVerifier`**
```python
class PytestVerifier:
    def score(self, attempt: Attempt, item: Item) -> Outcome:
        # run the produced patch against item.heldout_tests in a sandboxed subprocess
        # returns Outcome(passed: bool, n_pass, n_total, shape_ok, counterfactual_ok)
```
- **Held-out reward (P1):** `item` has `public_tests` (may appear in context) and `heldout_tests` (drive the posterior, never shown). `score` uses **held-out only**.
- **Trajectory-shape (§4.2):** reject schema-valid/hard-coded patches — for the live runner, inspect *which tools ran and whether args derived from the query vs a constant* (do **not** ship the harness boolean `derived_from_query` flag; that was flagged in the implementation review — replace with real trajectory inspection).
- **Counterfactual (§4.2):** the genuinely strong defence — a leave-one-out probe; keep leaning on it.
- **Reliability/admission (`eval/reliability.py`, §4.3):** a verifier is `admit`ted for a skill only if precision lower-CI ≥ `ρ_min` against a small human audit set.

**Adversarial acceptance — the verifier is not "done" until all three hold:**
- `test_verifier_rejects_hardcoded_constant` — a patch hard-coding the public expected value scores **0** held-out.
- `test_generalization_gate_rejects_memorization` — public↑/held-out-flat is rejected.
- `test_counterfactual_credit` — credit is leave-one-out, not shared-delta.

**Domain (`domain/`):** M0 uses a fixed set of ~5–8 coding skills (growth OFF). The runner (`domain/runner.py` / `adapters/runner.py::ClaudeRunner`) calls the LLM to attempt tasks; needs `ANTHROPIC_API_KEY`; keep the corpus offline/deterministic so the verifier is reproducible.

---

## 6. Core module specs (§1–§12, §14)

### 6.1 `state.py` — ProbabilisticState (§2, §3) + A5
- **Dual Beta** per `(skill, difficulty)` cell: a slow `mastery` posterior (decay `γ_slow`) and a fast `drift` posterior (decay `γ_fast`).
- `update(n_pass, n_total)` — Bernoulli evidence; **bulk-update** path (the loop updates in bulk — add a bulk-regime `n_min` test, per the improvement-note nit).
- `n_min` floor — no cell is "trusted" below the effective-sample floor.
- `significant(delta, se, z) -> bool` — the gate primitive (`Δ > margin + z·SE`). **Used everywhere.**
- `estimate() -> Cell(mastery_mean, mastery_var, drift_mean, …)`.
- **A5 warm-start (BUILD-SPECS A5):** `warm_prior = Beta(α0 + n_eff_warm·μ_knn, β0 + n_eff_warm·(1−μ_knn))`; `n_eff_warm=3` scaled by `max(div, div_floor=0.2)`; influence `3/(5+n_own)` decays as the learner's own evidence arrives; kNN over competence trajectories with **MMR diversity** `λ_div=0.5` (anti filter-bubble). Cold-start prior `(α0,β0)`.

### 6.2 `eval/` — see §5.

### 6.3 `decision.py` — DecisionEngine / π (§5.3, §13.1) + A1
- `choose(frontier, budget) -> Action` — selects by **expected learning gain**, NOT greedy `P(success)`.
- **A1 info-gain objective (BUILD-SPECS A1):**
  `U(a) = (1−w)·z(E[Δcompetence|a]) + w·z(EIG(a))` s.t. `cost ≤ budget`.
  Closed-form Beta EIG: `H(α,β)=ln B(α,β) − (α−1)ψ(α) − (β−1)ψ(β) + (α+β−2)ψ(α+β)`; `EIG_cell = H(α,β) − [p·H(α+1,β) + (1−p)·H(α,β+1)]`, `p = α/(α+β)`. Implement `digamma` ψ via recurrence-up-to-`x≥6`-then-asymptotic. `w = clip(mean_frontier_uncertainty / u_ref, 0, 1)`, `u_ref=0.15`. **z-score both terms** (commensurability — RC-1).
- **Coverage floor** `f_min` (§5.3) — no learnable skill is abandoned; a hard constraint applied *after* any soft discount.
- **CRITICAL (improvement-note P0.2):** `π` must be **in the end-to-end loop** at M0 — `LearningRun.run` must call `DecisionEngine.choose`, not round-robin. This is MDLP's differentiator; M0 is not valid without it.

### 6.4 `graph.py` — PathwayGraph (§5.2) + B2
- Soft reachability: `reach(s) = ∏ P(prereq mastered)` — compositional; one weak prereq dampens, never deletes. Acyclicity invariant + depth cap `d_max`.
- State-conditioned retrieval + **counterfactual credit** for rerank weights (§5.2) — the seed §16 generalizes.
- `decay_edges()` — the P2 inverse for edges; consumed by B2's post-redirect feedback.
- **B2 prereq-gap (BUILD-SPECS B2):** on `n_trigger=3` held-out failures at `S` (not explained by a B1 misconception), BFS **backward** while `significant(θ − ĉ_mastery[P], SE[P])`; stop per-branch at the first significantly-mastered prereq; **confirm** the candidate root with targeted held-out items before redirect; the **post-redirect outcome** over `n_post=5` held-out attempts on `S` feeds `decay_edges()`. `d_max=4`.

### 6.5 `growth.py` — GrowthRule g (§5.1) + B1
- **provision_suite invariant (RC-3):** *no node enters the graph until it can be scored* — spawning a skill provisions its eval suite, or the node is quarantined (never a silent dead node).
- Inverses (RC-4): `merge` (cosine ≥ `τ_merge`), `prune`, `edge-decay`.
- **B1 misconceptions (BUILD-SPECS B1):** embed *error traces* (the produced answer/working) into VectorStore; cluster (reuse §5.1) into a candidate when ≥ `N_min=30` coherent traces (intra-cluster cosine ≥ `τ_coh`); **admit** only if `significant(lift − ρ_M, SE_lift)` on the §4 held-out split (`ρ_M=0.2`, min arm ≥ 20/side, lift-gate `z=1.0`); attach a `misconception→prereq` edge in GraphStore; remediate via the §13 Teacher, kept only if the held-out error rate on M-items drops (§8). **Retire/merge** when predictive lift decays below `ρ_M` significantly over a 50-eval window (the P2 inverse).

### 6.6 `gate.py` / `loop.py` — the loop + four-clause gate (§6–§8)
- `loop.py`: `SELECT(π) → EXPAND(apply) → EVALUATE(Eval) → GROW(g) → BACKUP → COMMIT(gate)`. MCTS over the competence graph. Non-stationarity handling (§7): stale-tree discount/invalidation (RC-6).
- `gate.py :: commit_gate(child, node) -> bool` — the **four-clause conjunction**: `statistical ∧ generalization ∧ cumulative ∧ safe`. Each clause is a `significant()` test:
  - statistical: held-out Δ clears `z·SE`;
  - generalization (`ρ_gen`): `Δheldout ≥ ρ_gen·Δpublic`;
  - cumulative (`ε_cum`): no cumulative regression beyond tolerance;
  - safe: the safety/suite check.
- **Same-sample (improvement-note P1.3):** score the gate's SE and the competence update on the **same held-out sample** (don't compute gate SE from `n_trial=200` while competence updates on `n_eval=20`).

### 6.7 `calibration.py` — Calibrator (§14)
- Per skill-difficulty **band** (across learners): ECE/Brier monitor; isotonic point-recalibration; **`n_eff` deflation** (the mirror of `n_min`) → honest SE that every gate inherits for free.
- Miscalibration is a **5th circuit-breaker trigger**.
- Plugs in behind `ProbabilisticState`/`EvalHarness` ports — **no §1–§13 mechanism changes**.

---

## 7. The Tutor layer (§13)

**`tutor.py :: Tutor`** — the generic strategist (the decision core wrapped).
- `choose(learner, frontier, budget) -> Action` — delegates to `DecisionEngine` (A1), then picks a **Teacher** for the chosen skill.
- **Teacher selection:** Teachers (`teachers/`) are teaching strategies; admitted/kept only by **held-out gain** (a Teacher is "just another Action" under the §8 gate).
- **LearnerAdapter (`adapters/learner.py`):**
  - `AgentLearnerAdapter` — `posterior(skill)` from §3; `verify(skill)` = execution/pytest.
  - `HumanLearnerAdapter` (C1, **design-only / tag for v2**) — `posterior` updated by the behavioural-signal likelihood; `verify` = IRT-scored held-out + isomorphic variants admitted by predictive validity. Ships as the interface stub + docs; not implemented in v2 (see `HUMAN-LEARNING-VERIFIER.md`).
- **§13.1 info-gain mode** = A1 (above). The "bias-free = fastest = exploration are the same action" principle is realized by `U(a)`.

---

## 8. Unified retrieval (§16) — `retrieval.py`

Merges the "5-DB RAG" into the learner as the **inner loop of EXPAND**.
- **Two beliefs:** `C` (durable competence, §3) and `Q` (episode-scoped **answer-correctness Beta** over `P(current answer correct | context-so-far)`; binary-by-construction so `EIG_Q` reuses A1's closed form; discarded at goal completion).
- **Inner policy `π_Q`** (within `EXPAND`, hot path): `argmax z(EIG_Q) − cost(retrieve)`. **Stop** (mirrors §15.3) when `significant(EIG_Q, SE)` fails, budget `b_ret` spent, or `K` low-gain pulls.
- **Multi-store retrieve:** vector (semantic), graph (multi-hop/prereq), truth (provenance), state (state-conditioned vs `C`), cache (hot working set), artifact (blobs). `π_Q` learns which store to call by contribution.
- **Self-improving reranker:** trained **across-episode (cold path)** at goal completion by the realized held-out answer outcome, under §5.2 counterfactual credit; the reranker weights pass the §8 generalization gate like any learned weight.
- **Outer loop unchanged:** `retrieve` produces **no** checkpoint and touches **no** §8 gate (contrast `self_modify`, §11, which does).
- Params: `b_ret`, `K`, `(α_Q0,β_Q0)`. **Determinism caveat:** within-episode *search* only for replayable (agent/code) domains; human-learning degrades to pre-step assembly.

---

## 9. Re-visiting / surprise loop (§15) — `revisit.py`

- `revisit(D)` is a typed action (alongside `apply`); chosen by the §13.1 info-gain objective `E[ΔH | D, state]`.
- **Trigger:** model moved since last visit, a new input is vector-close to `D`, a downstream failure walks back (graph) to `D`, or spacing says forgetting is near.
- **Stop:** realized gain `significant(ΔH, SE)` fails, a diminishing-returns floor (`K` low-gain visits), a per-revisit budget, or the breaker. "Infinity bounded by information, not enumeration."
- **Two-level MCTS** (deterministic domains): replay one fixed `D` under different actions before committing.
- **Storage:** generative not enumerative — store `D` (truth) + checkpoint-versioned state; materialize only high-surprise insights (clearing the §2 gate) into the skill library + a graph derivation edge.

---

## 10. The self-calibrating gate (§19) — `calibgate.py`

Makes the §8 thresholds **learn their own strictness** from realized outcomes. **Lives in JUDGE** (§11) — never writable by a self-modifier.
- **Signal:** primary = the **post-commit regression rate among accepts** `r̂` (fully observable, over window `w_obs`); secondary = a `q_explore` shadow-canary quota for *borderline* rejects (margin `δ_border`), **isolated by invariant** (shadow never touches live competence/users).
- **Per-clause attribution:** each regressed accept is attributed to the §8 clause it passed most marginally; §19 tightens **that** clause's knob — `z` (statistical), `ρ_gen` (generalization), `ε_cum` (cumulative); the **safe** clause is hard, never tuned.
- **Moves:** a knob is raised on `significant(r̂_clause − α_clause, SE)` by bounded step `η_gate`; lowered (within the safe region) only when `r̂` is significantly under target AND `q_explore` shows over-rejection (SE **including the sampling fraction**).
- **Hard floor (load-bearing):** each knob clamped so it can only get **stricter than §8, never looser** — `z ∈ [z_8, 2·z_8]`, `ρ_gen ≥ ρ_gen⁸`, `ε_cum ≤ ε_cum⁸`. §19 can **never** admit a change §8 would block.
- **Cold start:** below `n_cal` per clause → fixed §8 dials (per-band).
- **§19 breaker:** knob saturated at a clamp, or `r̂ > α_gate` at max strictness → freeze at the strict end + **escalate to a human**.
- Params: `α_gate, w_obs, q_explore, δ_border, η_gate, [z_8,2·z_8]/ρ_gen⁸/ε_cum⁸, n_cal`, per-source cap.
- **Advisory (decision record):** specify the marginal-clause **normalization** (fractional excess per clause) before coding attribution.

---

## 11. Self-modification (§17, M3) — `selfmod/`

**`selfmod/partition.py` — the SOLVE/JUDGE manifest (the load-bearing safety artifact).** Make it a **machine-readable** file (per the §17/§18 decision advisory) with a defined update governance.
- **SOLVE (writable by `self_modify`):** `tutor.py` solve-heuristics, `teachers/`, `retrieval.py` config (which stores/queries), prompt templates, tool-wiring, graph *read/interpret* code.
- **JUDGE (immutable — no SOLVE write-path, ever):** `eval/` (verifier + held-out), **`growth.py::provision_suite` / all item-generation**, the `TeacherAdapter` *task-distribution* path, `gate.py`/`loop.py` commit machinery, `weight/promote.py` (§9), `calibration.py` + the breaker, **`calibgate.py` (§19)**, the **`self_modify` budget enforcer**, `state.py` `C` and its update path, the §6 orchestrator.
- **Invariant (static + runtime):** the static no-write-path check is **sound/conservative** (reject any candidate not *proven* free of a SOLVE→JUDGE write-path); SOLVE may not use reflection/`eval`/dynamic import; **runtime backstop = capability isolation** (JUDGE in a separate address space, no SOLVE-held handle).

**`selfmod/promote_code.py` — two-stage code promotion (RC-8 for code).**
- Stage 1 (shadow/sandbox): candidate SOLVE runs sandboxed on held-out + a monitored live subset, **scored not acted on**; promote only if held-out Δ clears §8 + no monitored regression.
- Stage 2 (hot-swap): replace running SOLVE; **retain the frozen last-good**; post-promotion monitor rolls back on `significant(Δ, SE)` drop over `w_promo`.
- Params: `b_sm`, `sandbox_cost_cap`, `scaffold_retention`, `w_promo`.

---

## 12. Multi-agent / fleet (§18, M3) — `fleet/`

- **Schema delta:** `stores/schemas.py` `Cell` gains an `agent_id` key — per-agent competence `C_a` in a shared StateStore.
- **`fleet/coverage.py` — fleet-coverage term:** `value'(a→k) = value(a→k)·φ(k)`, `φ(k) = 1 − ρ_fleet·1[∃ j≠self : significant(ĉ_j(k) − θ, SE_j)]`. `|fleet|=1 ⇒ φ≡1 ⇒ exactly §13.1`. `ĉ_j(k)` read from a **cached fleet projection** (CacheStore, async, staleness `τ_cache`; stale ⇒ `φ=1`). The §5.3 hard floor **dominates** this soft discount.
- **`fleet/transfer.py` — B3 zero-trust (BUILD-SPECS B3):** **no `A.StateStore` read**; a transferred skill is validated on the *receiver's* held-out via **isomorphic variants** (`sim_bar=0.8`, MMR `λ_div=0.5`), **quarantined** (provision_suite) behind the full §8 gate; `n_transfer=5`. The P2 inverse = quarantine-evict on failure.
- **Measurement independence at scale (§18.4):** per-agent held-out independence; cross-agent evidence enters only as an A5 prior (bounded, decaying, isomorphic-disjoint) or a B3 transfer candidate (re-validated) — **never** as direct competence credit.
- **Safety (N×0):** JUDGE is immutable for **every** agent → collective verifier-capture pressure is `N×0`. Per-source calibration caps (§19) bound input-distribution gaming.

---

## 13. The build-specs — index → integration

Each is gate-approved with exact params + tests in [`BUILD-SPECS.md`](BUILD-SPECS.md). Implement to **that**, not from memory.

| Spec | Module | Milestone | Key gate-approved constants |
|---|---|---|---|
| **A1** info-gain selection | `decision.py` | M0 | `u_ref=0.15`; Beta EIG closed form; digamma recurrence |
| **A5** warm-start | `state.py` / `memory` | M1 | `n_eff_warm=3`, `div_floor=0.2`, MMR `λ_div=0.5`, influence `3/(5+n_own)` |
| **B1** misconceptions | `growth.py` + `graph.py` + VectorStore | M1 | `N_min=30`, `ρ_M=0.2`, min arm ≥20, lift-`z=1.0`, retire window 50 |
| **B2** prereq-gap | `graph.py` + `eval/` | M1 | `n_trigger=3`, `d_max=4`, `n_post=5`, `significant(θ−ĉ,SE)` |
| **B4** spacing | `scheduler.py` + CacheStore | M1 | `r*=0.85`, `a=1.0`, `b=0.5`, `S_min=0.1`, `p_probe=0.1`, `ρ_rev=0.5` |
| **B3** fleet transfer | `fleet/transfer.py` | M3 | zero-trust, `sim_bar=0.8`, `λ_div=0.5`, `n_transfer=5`, quarantine |

---

## 14. Data layer (§10) — `stores/`

- **Ports** (`ports.py`): `TruthStore` (canonical event log/evals/lineage), `StateStore` (competence field, +`agent_id`), `VectorStore` (embeddings/clustering, B1/A5), `GraphStore` (prereqs/MCTS, B2), `CacheStore` (frontier/spacing B4/fleet projection), `ArtifactStore` (M2 checkpoints).
- **Two tiers** (`config.py`): **embedded** (SQLite + networkx + local vector index — *required for M0, no infra*: `build_stores()` with no config) → **full** (postgres/mongo/qdrant/neo4j/redis/s3) flipped per-role under the M1/scale evidence gate. Backends import lazily.
- **Source of truth + rebuild** (`rebuild.py`): TruthStore is canonical; `rebuild_state`/`rebuild_all` replay the event log into projections. Lets you repoint any store and replay; also makes M0 tests run against embedded while a nightly job runs the same suite against full.

---

## 15. Red-team regression suite (`tests/redteam/`)

Encode every root cause as a **named, CI-green** test. A red-team failure shipping without a guard is a regression waiting to happen.

| Guard | Asserts |
|---|---|
| `test_verifier_rejects_hardcoded_constant` (RC-2) | hard-coded patch scores 0 held-out |
| `test_generalization_gate_rejects_memorization` (RC-2) | public↑/held-out-flat rejected |
| `test_growth_quarantines_unscorable` (RC-3) | a novel out-of-coverage skill is quarantined, never a dead node |
| `test_decay_cannot_swing_below_nmin` (RC-1/RC-5) | one eval can't move ĉ past ε; rollback needs a powered re-eval |
| `test_pi_avoids_mastered_skill` (RC-7) | π never spins on mastered when a learnable exists |
| `test_retrieval_credit_is_counterfactual` (RC-4) | leave-one-out credit, not shared-delta |
| `test_promotion_is_reversible_then_gated` (RC-8) | two-stage; merge only after held-out + spot-check + no monitored regression |
| **§16:** `test_reduces_to_A1_when_no_retrieval`, `test_retrieve_cannot_substitute_for_practice` | retrieve is inner-loop, coverage-floor-neutral |
| **§17:** `test_self_modify_cannot_write_JUDGE`, `test_no_write_path_SOLVE_to_JUDGE`, `test_frozen_fallback_always_runnable` | the partition holds |
| **§18:** `test_no_cross_agent_state_read`, `test_transfer_revalidated_on_receiver_heldout`, `test_fleet_self_modify_cannot_collectively_capture_verifier` | N×0 |
| **§19:** `test_each_knob_only_stricter_than_§8`, `test_regression_attributed_to_marginal_clause`, `test_shadow_admits_never_touch_live_competence`, `test_saturation_freezes_and_escalates` | the gate can only get stricter |

---

## 16. Acceptance criteria (definition of done per milestone)

- **M0** = `docs/mdlp/results/M0.md` documents a **live-runner** run where **held-out** pass-rate rises beyond `z·SE` over a frozen no-learning baseline **on a real corpus**, with π in the loop; the three adversarial probes fail as designed; H2 (learning-gain vs greedy) is measured. *(A NO-GO is a valid, documented outcome — report it.)*
- **M1** = `docs/mdlp/results/M1.md`: schema grows, 100% live nodes scorable, bounded orphan/duplicate/oscillation; B1/B2/B4/A5/§15/§16 each pass their BUILD-SPECS test list; preceded by a fresh adversarial review (C0).
- **M2** = `docs/mdlp/results/M2.md`: a promotion raises held-out competence with no monitored regression, under two-stage reversible promotion.
- **M3** = `docs/mdlp/results/M3.md`: self-mod raises held-out under the SOLVE/JUDGE partition + code-promotion; the fleet co-evolves without a P1 break; §19 holds `r̂ ≤ α_gate` without ever dropping a clause below its §8 floor.

Each milestone's tests are added to CI **before** it is called done.

---

## 17. Build order, ownership & the board

Tasks on `turing-agents/tasks/BOARD.md`. Specialists: `pathway-builder`, `eval-harness-builder` (build them first via `agent-smith` if absent).

```
M0:  B0 scaffold mdlp/ → B1 verifier (eval-harness-builder, HIGHEST RISK)
     → B2 state → B3 corpus+live runner → B4 memory/retrieval seed
     → B5 decision π + A1 → B6 loop+gate + §14 → ★B7 GO/NO-GO★
M1:  C0 re-red-team (@you) → growth g + provision_suite → B1 → B2 → B4 → A5 → §15 → §16
M2:  weight axis (needs GPU + budget; @you gates)
M3:  §17 selfmod (partition first) → §18 fleet + B3 → §19 self-calibrating gate
```
Move tasks `Backlog → Assigned → In Progress → Review → Done`; the curator audits stale rows.

---

## 18. Companion-build-spec advisories (from the gate decision records)

Resolve these before coding the relevant module (they were recorded as non-blocking at design approval):
- **§16:** collect `b_ret`/`K`/`(α_Q0,β_Q0)` into a params block; pin "gated like §8" to the **generalization** sub-clause specifically.
- **§17/§18:** the **JUDGE boundary** must be a **machine-readable artifact** with an update-governance process (how SOLVE modules are classified as they're added). Name the static-analysis tool + its completeness class; specify the Stage-2 rollback metric/window; state the fleet-cache staleness bound.
- **§19:** specify the marginal-clause **normalization** (fractional excess per clause) before coding attribution.

---

## 19. Environment & CI

- **Repo:** `/Users/samyoga/dev/turing-agents`; branch (not `main`); one logical change per commit.
- **Isolation:** `mdlp` in its own venv; `app/` stays dependency-free. Two CI jobs: `app/` (stdlib, always) + `mdlp/` (its venv) — plus a `redteam/` job that must be green to merge.
- **Secrets:** the live runner needs `ANTHROPIC_API_KEY`; keep the corpus offline/deterministic.
- **Dogfood:** after a meaningful task, `scripts/capture.sh "<intent>" "<did>" "<learned>"`.

---

## Appendix — parameter register (all dials, §12 + added)

Core (§12): `γ_slow, γ_fast, n_min, z, ε, ε_cum, ρ_gen, ρ_min, τ_new, τ_merge, θ, λ, f_min, topK, m, l1_decay, (α0,β0), promotion bar, interference tol, K (breaker), k (LP window)`.
§14: `n_eff`, ECE/Brier band thresholds. §16: `b_ret, K, (α_Q0,β_Q0)`. §17: `b_sm, sandbox_cost_cap, scaffold_retention, w_promo`. §18: `N, ρ_fleet, f_xfer, τ_cache`. §19: `α_gate, w_obs, q_explore, δ_border, η_gate, [z_8,2·z_8]/ρ_gen⁸/ε_cum⁸, n_cal, per-source cap`. Build-specs A1/A5/B1/B2/B3/B4: see [`BUILD-SPECS.md`](BUILD-SPECS.md).

*None is guessed in the spec; all are explicit, and all are tuned by the M0/M1 empirical pass (M3 dials at M3).*
