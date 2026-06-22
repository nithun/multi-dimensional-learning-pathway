# MDLP Layer 3 — Implementation Guide

**The pathway-learner (`PL-v0.2`), built as an opt-in Layer 3 inside turing-agents.**
Status: design → build. Scope: Milestones 0 → 1 → 2. Verifier domain: code changes verified by pytest/coverage.
Design sources (this folder): [`design/ALGORITHM-v0.2-pathway-learner.md`](design/ALGORITHM-v0.2-pathway-learner.md) (the spec), [`design/ALGORITHM-v0.1-redteam.md`](design/ALGORITHM-v0.1-redteam.md) (failure modes), [`design/REPORT-self-learning-agents.md`](design/REPORT-self-learning-agents.md) (go/no-go + evidence), [`design/PAPER-method-section.md`](design/PAPER-method-section.md) (the formal method).

---

## 0. Decisions locked for this build

| Decision | Choice | Why |
|---|---|---|
| Placement | **Opt-in Layer 3 package `mdlp/` at repo root** — its own deps, never imported by `app/`, never required to run | Honors **L-010** (file-native canonical; MDLP is an optional derived add-on) and keeps `app/` pure-stdlib |
| Substrate | The **canonical file logs** (`.claude/memory/{interactions,audit,evolution-log}.jsonl`) read **read-only**; `mdlp` writes only its own derived stores | L-010: "any database is a rebuildable projection on top" |
| Verifier domain (M0) | **Code change → run pytest → pass/fail = outcome.** The agent attempts a coding task; held-out tests score it | The one cheap, reliable verifier already in the repo; avoids the soft-judge NO-GO regime |
| Scope | Build through **M1/M2**, but each milestone is **gated** on the prior's acceptance test (esp. **B7**) | The design is un-verified; you cannot parallelize past a GO/NO-GO |
| Stores | Start minimal — **SQLite (truth) + a vector lib + networkx**, not the full 5-store | Report §7.4 / L-010 evidence-gate: don't stand up heavy infra without signal |

> **Hard invariant for the whole build:** nothing under `app/` imports `mdlp`, and `mdlp` never edits a project's source or its canonical logs. `mdlp` is a *reader + derived-store writer + opt-in surface*. If you ever need to break this, stop and raise it — it's the L-010 identity line.

---

## 1. Placement & package layout

```
turing-agents/
  app/                         # UNCHANGED — pure stdlib control plane
  mdlp/                        # NEW — Layer 3, opt-in, own deps, never required
    README.md
    requirements.txt           # core deps (M0/M1)
    requirements-weight.txt    # heavy M2 deps (torch/transformers/peft/trl/vllm) — optional extra
    pyproject.toml
    mdlp/
      __init__.py
      state.py                 # ProbabilisticState — dual Beta posteriors, decay, n_min, significant()
      graph.py                 # PathwayGraph — networkx; soft reachability
      decision.py              # DecisionEngine (π) — learning-gain objective, Thompson, coverage floor
      loop.py                  # EvolutionLoop — the main loop + composite commit/rollback gate
      growth.py                # GrowthRule g (M1) — provision_suite, merge/prune, quarantine
      eval/
        harness.py             # EvalHarness — held-out/public split, score()
        verifiers.py           # VerifierRegistry — PytestVerifier, reliability()
        suites.py              # eval-suite load/version/split
      memory/
        skills.py              # SkillLibrary — propose/validate/store/retrieve/retire
        retrieval.py           # recall→rerank, counterfactual credit, held-out-clean ctx
      weight/                  # M2
        curate.py              # rejection sampling from verified successes
        train.py               # TRL + PEFT/QLoRA
        promote.py             # two-stage reversible promotion
        rollout.py             # vLLM rollout
      stores/
        truth.py               # SQLite event log (source of truth) + lineage
        cache.py               # hot read-models (in-proc dict; Redis optional later)
        vectors.py             # vector index (M1)
        artifacts.py           # object store + model registry (M2)
      adapters/
        logs.py                # read canonical file logs (interactions/audit/evolution) read-only
        controlplane.py        # optional: enqueue eval tasks via app/core (turing_core)
      cli.py                   # `mdlp` CLI — opt-in surface (off by default)
    domain/
      tasks/                   # M0 coding-task corpus: prompt + public tests + held-out tests
      runner.py                # agent runner — attempts a task with retrieved ctx, returns a trajectory
    tests/                     # pytest for mdlp itself (dogfood — same verifier the system learns on)
```

**Dependencies (kept off `app/`).** `mdlp/requirements.txt`: `numpy` (Beta math), `networkx` (graph), an embeddings/vector lib (start with `scikit-learn` TF-IDF or `sentence-transformers` + `faiss-cpu`/`sqlite-vec`), `anthropic` (the agent runner's LLM). `sqlite3` is stdlib. `mdlp/requirements-weight.txt` (M2, optional, GPU): `torch transformers peft trl vllm bitsandbytes`.

**Opt-in wiring.** `mdlp` ships its own `mdlp` CLI. A `turing learn <project>` surface (a few lines in `app/cli/turing` + an MCP tool) may *shell out* to `mdlp` later, but `app/core` must not import it. Default state: **off**. A project runs identically whether or not `mdlp` is installed.

---

## 2. The substrate — reading the canonical logs

`mdlp.adapters.logs` is the only bridge to the framework. It reads, read-only:

- `.claude/memory/interactions.jsonl` — schema `{"id","date","intent","did","learned","actor"}`. Each line is a past episode.
- `.claude/memory/audit.jsonl` — per-teammate completed work (when populated).
- `.claude/memory/evolution-log.jsonl` — self-modifications.
- `skills/**/SKILL.md`, `.claude/memory/lessons.md` — the existing memory-level artifacts the learner will propose/refine.

```python
# adapters/logs.py
def read_interactions(project_root: Path) -> Iterator[Episode]: ...
def read_skills(project_root: Path) -> list[Skill]: ...      # parse skills/ + lessons.md
def watch(project_root: Path) -> Iterator[Episode]:           # tail new lines (optional, for live mode)
```

**Act/learn store split (the report's hot/cold architecture).** Source of truth = the file logs + `stores/truth.py` (SQLite append-only event log with full lineage: which data produced which eval result / checkpoint). Everything else — `stores/cache.py`, `stores/vectors.py` — is a **disposable projection rebuildable from truth**. This is what makes aggressive caching safe and satisfies L-010 ("rebuildable projection").

---

## 3. The domain & verifier (Milestone 0)

The learner is an **agent that makes code changes**; competence is **whether held-out tests pass**.

- **Skill** `s` — a category of coding task (e.g. `"write a pure function from a spec"`, `"fix a failing test"`, `"add input validation"`). M0 uses a **fixed** set of ~5–8 skills (growth OFF).
- **Eval item** — one self-contained task: a prompt + a reference solution + a **public** test split (may appear in the agent's context) and a **held-out** test split (never in context; scores the attempt). Items carry a difficulty `d`.
- **Episode** — `runner.run(task, ctx)`: the agent (Anthropic API) attempts the task with retrieved skills/lessons in `ctx`, producing a code patch + trajectory. The verifier runs pytest on the held-out split in a sandbox → `{passed, n_pass, n_total, trajectory}`.
- **Verifier** — `PytestVerifier`: runs the produced code against held-out tests in an isolated temp dir/subprocess. Asserts on **trajectory shape** too (did the patch actually implement the function, or hard-code the public test's expected value? — defeats the schema-valid/null hack) and on **counterfactual** items (a held-out variant with different inputs).

**Task corpus.** Seed `domain/tasks/` with ~40–80 small tasks across the fixed skills, each with public+held-out tests. Sources: hand-authored, or adapted from an existing function-level benchmark (e.g. MBPP/HumanEval-style) — but keep them *self-contained and locally runnable* so the verifier is deterministic and offline.

---

## 4. Module specification (interfaces map to `PL-v0.2`)

### 4.1 `state.py` — ProbabilisticState (spec §3)
```python
@dataclass
class Cell:                       # one (skill, difficulty)
    mastery: Beta                 # slow decay γ_slow → 1 as it stabilizes
    drift:   Beta                 # fast decay γ_fast — used only for rollback

class ProbabilisticState:
    def estimate(self, s, d) -> Posterior: ...           # mean + SE
    def update(self, s, d, k_pass, k_fail, *, paired_se): ...   # decayed Bayesian update, n_min floor
    def learning_progress(self, s, *, window) -> Posterior: ... # SLOPE over window, not a raw diff

def significant(delta, se, *, margin=0.0, z=2.0) -> bool:    # the gate primitive (used everywhere)
    return delta > margin + z * se
```
- Dual posterior + per-skill decay + `n_min` floor (red-team RC-1/RC-5). `significant()` is reused by select/commit/rollback/promote/admit.

### 4.2 `eval/` — the reward (spec §4; the linchpin)
```python
class EvalHarness:
    def score(self, attempt, s, d) -> Tuple[SuccessEstimate, SuccessEstimate]:   # (held_out, public)
        # held_out drives ALL rewards/gates; public is reproducibility-only
class VerifierRegistry:
    def admit(self, s, *, band) -> bool: ...             # reliability_lowerCI(v|band) ≥ ρ_min
    def strictest_for(self, s) -> Verifier: ...          # never silently downgrade
    def reliability(self, v, *, band) -> Interval: ...   # precision/recall vs a human audit set
class PytestVerifier(Verifier):
    def verify(self, attempt, item) -> bool:             # held-out pytest ∧ shape ∧ counterfactual
```
- Held-out/public split + generalization gate `Δheld_out ≥ ρ_gen·Δpublic` (RC-2). `reliability` anchored to a small labeled audit set, per band, lower-CI admission (RC-2).

### 4.3 `decision.py` — DecisionEngine / π (spec §3.6)
```python
class DecisionEngine:
    def choose(self, state, candidates, *, budget) -> Tuple[Action, Context]:
        # objective = expected LEARNING GAIN (not P(success)); Thompson-sampled;
        # z-normalized Q̃ + λ·reachability-infogain; cost as a HARD budget constraint;
        # coverage floor (every skill practiced ≥ f_min); LP enters only if significant().
```
Refutes `argmax P(success)`; normalized terms (RC-1/RC-4); coverage floor + reachability-exploration (RC-7).

### 4.4 `memory/` — SkillLibrary + retrieval (spec §3.3, §3.5)
```python
class SkillLibrary:
    def propose(self, episode) -> SkillDraft: ...
    def validate(self, draft) -> bool:                   # keep iff held-out competence improves (significant)
    def retrieve(self, state, task) -> list[Context]:     # recall(ANN) → rerank(state-aware) ⊕ exploration
    def retire(self, s): ...
def update_rerank_weights(ctx, r): ...                    # COUNTERFACTUAL credit (leave-one-out), L1 decay
```
- Held-out items never enter retrieved `ctx` (RC-2). Counterfactual credit, not shared-delta (RC-1). Reachability-exploration slice (RC-7/D1).

### 4.5 `graph.py` — PathwayGraph (spec §3.3)
```python
class PathwayGraph:                                       # networkx.DiGraph
    def reach_weight(self, s, state) -> float:            # ∏ P(c_prereq ≥ θ) — SOFT, never a hard AND
    def update_transition(self, a, b, r): ...
```
M0 is a fixed flat graph (reach_weight≈1); the soft machinery matters from M1.

### 4.6 `growth.py` — GrowthRule g (M1; spec §3.4)
```python
class GrowthRule:
    def step(self, child, F):                             # coherence-gated attribution; CRP new-table
        # provision_suite(s_new) OR quarantine→pending_human (INVARIANT: no unscorable node live)
        # maybe_merge (τ_merge>τ_new) · prune_orphans · decay_edges   (every add has an inverse)
    def provision_suite(self, s_new, cluster) -> bool: ...# inherit parent verifier OR synthesize held-out items
```

### 4.7 `weight/` — the parameter axis (M2; spec §3.8)
```python
class DataCurator:   def curate(self, trajectories) -> Dataset: ...   # rejection-sample VERIFIED successes
class Trainer:       def sft|dpo|grpo(self, dataset, base) -> Adapter: ...   # TRL + PEFT/QLoRA, KL-bounded
class PromotionController:
    def review(self, state):                              # scored index (not AND); pre-train interference check
        # stage 1: train detachable LoRA adapter (reversible)
        # stage 2: merge to base ONLY after sustained held-out + human spot-check + no MONITORED regression
class RolloutEngine: def generate(self, prompts, model): ...          # vLLM
```

### 4.8 `stores/` — truth + projections
```python
class TruthStore:    # SQLite, append-only: events, eval results, full data/checkpoint lineage (source of truth)
class Cache:         # hot read-models: materialized frontier, state vector (rebuildable from truth)
class VectorIndex:   # M1: embeddings for retrieval/clustering
class ArtifactStore: # M2: checkpoints + datasets + model registry (+ retention/GC)
```

### 4.9 `loop.py` — EvolutionLoop (spec §6)
```python
def tick(state, graph, lib, evaln, dec):
    a, ctx = dec.choose(state, graph.reachable(state), budget=B)        # 1 SELECT
    child  = apply(a, node, ctx)                                        # 2 EXPAND (clone for weight)
    r_secret, r_public = evaln.score(child, a.targets)                  # 3 EVALUATE (held-out)
    g.step(child, F)                                                    # 4 GROW (M1+)
    state.update(...); update_rerank_weights(ctx, r_secret)            # 5 BACKUP (dual posterior, discounted tree)
    if commit_gate(child, node, r_secret, r_public):                   # 6 COMMIT/ROLLBACK
        node = child; invalidate(node); promotion_review(node)         #    (statistical+cumulative+generalization+safety)
    else: rollback(node)                                               #    rate-limited; no info-retention on safety fails
```

### 4.10 `cli.py` / `adapters/controlplane.py`
`mdlp run --project <path> --milestone 0` etc. Optional: enqueue eval tasks onto a project's board via `app/core.task_add` (read the board, never the source).

---

## 5. Milestone 0 — prove the loop measures truth (growth OFF)

**Goal:** held-out competence rises vs. a no-learning baseline, on the pytest domain. This is the real H1 de-risking probe. **If B7 fails, stop here.**

| Step | Build | Done when |
|---|---|---|
| B0 | Scaffold `mdlp/` package, deps, `pyproject`, CI hook; `adapters/logs.py` reads interactions.jsonl | `mdlp --version`; logs parse in a test |
| B1 | `eval/` — `PytestVerifier` (sandboxed), held-out/public split, trajectory-shape + counterfactual checks, `reliability()` vs a tiny audit set | a known-good patch scores 1.0 held-out; a hard-coded-constant patch scores 0 (shape check) |
| B2 | `state.py` — dual Beta, decay, `n_min` floor, `significant()`, LP-as-slope | property tests: one eval can't move ĉ > ε; LP SE shrinks with paired items |
| B3 | `domain/tasks/` — fixed 5–8 skills, ~40–80 items, public+held-out splits; `domain/runner.py` (Anthropic) | corpus loads; runner returns a scored trajectory offline |
| B4 | `memory/` — SkillLibrary propose/validate/retrieve; recall→rerank; **held-out-clean ctx**; counterfactual credit | retrieved ctx never contains held-out items (test) |
| B5 | `decision.py` — learning-gain π, Thompson, coverage floor, significance gate | π never selects a mastered skill when a learnable one exists (test) |
| B6 | `loop.py` — tick + commit/rollback gate (statistical + cumulative + generalization) | a memorizing patch (public↑, held-out flat) is **rejected** by the generalization gate (test) |
| **B7** | **Evaluation harness:** run N ticks; compare held-out competence trajectory vs. a frozen no-learning baseline; ablate (no-validation-gate, no-retrieval) | **held-out competence rises significantly over baseline, on held-out items** — the GO/NO-GO |

**Acceptance (B7):** a documented run showing held-out pass-rate improving beyond `z·SE` over the no-learning baseline, with the memorization and verifier-gaming probes failing as designed. Record it in `docs/mdlp/results/M0.md`.

---

## 6. Milestone 1 — open the schema (gate: B7 passed)

| Step | Build | Done when |
|---|---|---|
| C0 | **Re-red-team the v0.2 design** against the M0 implementation before adding growth (catch what survived the patches) | findings logged in `docs/mdlp/design/` |
| C1 | `growth.py` — `g.step`: coherence-gated attribution, CRP new-table (region-adaptive τ_new), `provision_suite` **invariant**, `pending_human` quarantine | a novel out-of-coverage failure → quarantine, **not** a silent dead node (test) |
| C2 | Inverses — `maybe_merge` (hysteresis), `prune_orphans`, `decay_edges` | duplicate skills merge; orphan skills retire (tests) |
| C3 | `graph.py` soft reachability over a real graph; `stores/vectors.py` (embeddings + ANN) | reach_weight is continuous; one wrong prereq dampens but doesn't delete a skill (test) |
| C4 | Per-skill decay, reachability-exploration term | a foundational-but-stale unlock context is reachable (filter-bubble test) |
| C5 | **Evaluation:** schema grows *measurable* skills (all live nodes scorable), no orphan sprawl, no commit/rollback oscillation over a long run | `docs/mdlp/results/M1.md` |

---

## 7. Milestone 2 — the weight axis (gate: M1 passed; needs GPU)

| Step | Build | Done when |
|---|---|---|
| D0 | Install `requirements-weight.txt`; `stores/artifacts.py` (checkpoints + registry + retention/GC) | a checkpoint round-trips through the registry |
| D1 | `weight/curate.py` — rejection-sample **verified** successful trajectories into a dataset | dataset contains only held-out-passing trajectories (test) |
| D2 | `weight/train.py` — TRL SFT (then DPO/GRPO), PEFT/QLoRA, KL/regret bound; `weight/rollout.py` (vLLM) | a 7B QLoRA SFT runs on one GPU; eval delta measured |
| D3 | `weight/promote.py` — scored promotion index, **pre-train interference check**, **two-stage reversible** promotion, explicit `MONITORED` set | promotion is detachable at stage 1; merges only after held-out + human spot-check + no MONITORED regression (test) |
| D4 | Discounted/invalidated MCTS tree values on checkpoint change; tree GC | tree values discount on a new checkpoint (test) |
| D5 | Production-outcome breaker; deployment-drawn safety items; **Evaluation** | a promotion improves held-out competence without regressing MONITORED; `docs/mdlp/results/M2.md` |

---

## 8. Testing strategy

`mdlp` is tested with **pytest** — the same verifier it learns on (dogfood). Add `mdlp/tests/` to the repo's pytest run (extend `pytest.ini` `testpaths`/`pythonpath`, or give `mdlp` its own `pytest.ini` so the stdlib `app/` suite stays dependency-free). Every red-team failure mode gets a regression test (e.g. `test_generalization_gate_rejects_memorization`, `test_growth_quarantines_unscorable`, `test_decay_cannot_swing_below_nmin`). CI: run `app/` tests (stdlib, always) and `mdlp/` tests (in the `mdlp` venv) as separate jobs.

---

## 9. Opt-in, safety, L-010 compliance

- **Opt-in:** nothing in `app/` imports `mdlp`; default off; a project runs identically without it. The `mdlp` stores are derived and rebuildable from the canonical logs.
- **Reversibility:** memory-axis edits are git commits (the framework already does this); weight-axis is checkpoint + two-stage detachable promotion. Reversibility is rate-limited and safety-failed branches retain no fine-grained info (RC-7/F4).
- **Circuit-breaker:** reuse/extend `.claude/memory/circuit-breaker.json` lanes; trip on consecutive rollbacks, eval-variance spikes, **production-outcome degradation**, and fence-probing.
- **L-010 line:** `mdlp` never edits a project's source or canonical logs; it reads + writes its own derived stores + offers an opt-in surface. Don't cross this without raising it.

---

## 10. Risks & gates (read before building)

1. **Verifier reliability is the whole game.** If `PytestVerifier` is gameable (hard-coded constants), the loop learns to game it — hence the trajectory-shape + counterfactual checks in B1. Treat B1 as the highest-risk module.
2. **B7 is a real gate, not a formality.** If held-out competence doesn't beat baseline, the loop is unproven — fix the verifier/state before M1.
3. **Re-red-team before M1 and M2 (C0/D-pre).** The v0.2 fixes are designed, not verified; adversarially test the *implementation*.
4. **M2 needs a GPU and real budget** (report §4.3: SFT ~$ tens, RL ~$ hundreds–thousands). Don't start D2 without it.
5. **Soft-judge skills stay out.** Only skills with a reliable verifier (`admit`) enter autonomous learning; framework meta-learning (skills/lessons judged by an LLM) is *not* in scope — it's the NO-GO regime.

---

## 11. Task list & ownership

Mirrored on the board (`tasks/BOARD.md`). The project squad is currently empty, so the near-term owners are `@you` + two specialists to be built by `agent-smith`:

- **`pathway-builder`** — owns the `mdlp/` modules (state, decision, loop, memory, growth, stores).
- **`eval-harness-builder`** — owns `eval/` + `domain/` (the verifier, task corpus, B7 evaluation). *Highest-risk; build first.*

| Phase | Tasks | Owner |
|---|---|---|
| Decide/scaffold | A1 ADR (this doc), A2 verifier pinned (pytest), B0 scaffold | @you / pathway-builder |
| **M0** | B1 (eval/verifier) → B7 (GO/NO-GO) | eval-harness-builder (B1,B3,B7) · pathway-builder (B2,B4,B5,B6) |
| M1 | C0 re-red-team → C5 | pathway-builder · @you (C0 review) |
| M2 | D0 → D5 | pathway-builder · @you (GPU/budget, human spot-check) |

**Sequencing rule:** B1 first (the verifier), then B2–B6 in parallel, then B7. Do **not** start M1 until B7 is documented as passed.
