# Implementation Handover — MDLP Layer 3 (the pathway-learner) for turing-agents

**For:** the build team (Claude Code build agents + `@you`)
**Mode:** build (the research is done; this is implementation)
**Owner:** nithun@turing.ae · **Date:** 2026-06-22 · **Status:** ready to start at Milestone 0
**Scope of this doc:** how to pick up the build cold — what to read, what's decided, what you must not break, where to start, and how you'll know you're done.

---

## 0. One-paragraph mission

Build a **self-learning loop** for turing-agents as an **opt-in Layer 3** (`mdlp/`) that makes the agents measurably better over time. It models each learner as a probabilistic competence state, picks the next learning action by **expected learning gain**, and commits a change only when a **held-out verifier** confirms it helped. Ship it in **milestones gated on evidence** — prove the loop measurably improves *true* (held-out) competence before adding the open schema, and before the parameter (fine-tuning) axis. Do not touch `app/` (it stays pure-stdlib); do not edit any project's source or canonical logs. The full design is settled and adversarially stress-tested; your job is faithful, gated implementation.

---

## 1. Read first, in this order

| # | Artifact | Why |
|---|---|---|
| 1 | `docs/mdlp/IMPLEMENTATION.md` | **The build guide** — package layout, module interfaces, per-milestone steps with acceptance tests. Your day-to-day reference. |
| 2 | `docs/mdlp/design/ALGORITHM-v0.2-pathway-learner.md` | The hardened algorithm spec. The source of truth for *what each component must do*. |
| 3 | `docs/mdlp/design/ALGORITHM-v0.1-redteam.md` | The 8 root-cause failure modes the design fixes. **Read this so you don't reintroduce them.** §6 below is the checklist. |
| 4 | `ARCHITECTURE.md` (repo root) + lesson **L-010** (`.claude/memory/lessons.md`) | Why this is Layer 3 / opt-in / never required. The non-negotiable identity line. |
| 5 | `docs/mdlp/design/REPORT-self-learning-agents.md` | Feasibility, cost envelopes, the reward-signal precondition (skim). |

Don't start coding until you've read 1–3.

---

## 2. Locked decisions (do not relitigate)

| Decision | Choice |
|---|---|
| **Placement** | New top-level package `mdlp/` at repo root. Its own deps. **Never imported by `app/`.** |
| **Substrate** | Reads the canonical file logs (`.claude/memory/{interactions,audit,evolution-log}.jsonl`, `skills/`, `lessons.md`) **read-only**; writes only its own derived stores. |
| **Verifier domain (M0)** | A coding task → the agent produces a patch → **pytest on held-out tests** = the outcome. The one reliable verifier already in the repo. |
| **Scope** | Build through M1/M2, **gated**: each milestone blocks on the prior's acceptance test (esp. **B7**). |
| **Stores** | Start minimal: SQLite (truth) + a vector lib + networkx. Not the full 5-store. |
| **Two principles** | (P1) measurement independent of optimization; (P2) every `add` has an inverse. Every module obeys these. |

---

## 3. Non-negotiable constraints (the "do not break these")

1. **`app/` stays pure-stdlib.** Nothing under `app/` imports `mdlp`. No pip deps leak into the control plane. (L-010, README.)
2. **`mdlp` is opt-in and never required.** A project runs identically whether or not `mdlp` is installed. Default state: off.
3. **`mdlp` never edits a project's source or its canonical logs.** It is a reader + derived-store writer + opt-in surface. Derived stores must be rebuildable from the file logs.
4. **The verifier precondition.** Only skills with a reliable verifier (`admit`) enter autonomous learning. Soft-judge / LLM-graded skills are **out of scope** — that's the NO-GO regime.
5. **Reward only on held-out (P1).** Held-out eval items never enter the agent's context. The public split is for reproducibility, never for reward.
6. **Gates are statistical, not scalar.** Every commit/rollback/promote/admit decision tests a delta against its standard error, not a bare threshold.

If a task seems to require breaking one of these, stop and raise it — these are the identity of the design.

---

## 4. Where to start (the first PR)

**Start with the verifier — it's the highest-risk module and everything depends on it.**

1. **B0 — scaffold `mdlp/`** (package, `requirements.txt`, `pyproject`, `adapters/logs.py` reading `interactions.jsonl`, a `mdlp` CLI stub). Acceptance: `mdlp --version` runs; a test parses the logs.
2. **B1 — `eval/` (the linchpin):** `PytestVerifier` that runs a produced patch against held-out tests in a sandboxed subprocess, plus **trajectory-shape** and **counterfactual** checks, the held-out/public split, and `reliability()` vs a tiny audit set.
   - **Adversarial acceptance (must pass before B1 is "done"):** a correct patch scores 1.0 held-out; a patch that **hard-codes the public test's expected value** scores **0** (the shape check catches it); a memorizing change that lifts the public split but not held-out is rejected by the generalization gate. If these three don't hold, the whole loop is unsafe — do not proceed.

Then B2–B6 (state, memory/retrieval, decision, loop) can proceed in parallel, converging on **B7**.

---

## 5. The build plan (gated)

```
M0  prove the loop measures truth (growth OFF, memory axis, held-out verifier)
    B0 scaffold → B1 verifier → B2 state → B3 task corpus+runner → B4 memory/retrieval
       → B5 decision π → B6 loop+gate → ★B7 GO/NO-GO★
    GATE B7: held-out competence beats a no-learning baseline beyond z·SE, probes fail as designed.
             If B7 fails, STOP and fix the verifier/state. Do not build M1.

M1  open the schema (only if B7 passed)
    C0 re-red-team the implementation → C1 growth g + provision_suite invariant + quarantine
       → C2 inverses (merge/prune/edge-decay) → C3 soft reachability + vector index → C4 per-skill decay + reachability-exploration
    GATE C5: schema grows measurable skills; all live nodes scorable; no orphan sprawl; no oscillation.

M2  the parameter axis (only if M1 passed; needs a GPU + budget)
    D0 artifact store/registry → D1 rejection-sampling curator → D2 TRL/QLoRA train + vLLM rollout
       → D3 two-stage reversible promotion + interference check → D4 discounted/invalidated tree → D5 production breaker
    GATE D5: a promotion improves held-out competence without regressing the monitored set.
```

**Sequencing rule:** verifier first (B1), then parallelize, then gate. Never skip a gate.

---

## 6. Failure modes to guard against (from the red-team — keep these as regression tests)

The v0.1 design had three pilot-killers and ~40 findings; v0.2 fixes them but the *implementation* can reintroduce them. Add a named test for each:

- **Verifier gaming** → schema-valid/hard-coded patches must score 0 (B1 shape + counterfactual checks). `test_verifier_rejects_hardcoded_constant`.
- **Suite memorization** → public↑/held-out-flat must be rejected (generalization gate). `test_generalization_gate_rejects_memorization`.
- **Unscorable growth** → a novel out-of-coverage skill is quarantined, never a silent dead node. `test_growth_quarantines_unscorable`.
- **Decay/rollback oscillation** → one eval can't move ĉ past ε; rollback fires only on a fresh powered re-eval. `test_decay_cannot_swing_below_nmin`.
- **Frontier starvation** → soft reachability; π never spins on mastered skills when a learnable one exists. `test_pi_avoids_mastered_skill`.
- **Retrieval lock-in** → counterfactual (leave-one-out) credit, not shared-delta. `test_retrieval_credit_is_counterfactual`.
- **Promotion baking in overfit** → two-stage reversible; merge only after held-out + human spot-check + no monitored regression. `test_promotion_is_reversible_then_gated`.

Every red-team failure that ships without a guarding test is a regression waiting to happen.

---

## 7. Acceptance criteria (definition of done per milestone)

- **M0 done** = `docs/mdlp/results/M0.md` documents a run where **held-out** pass-rate rises beyond `z·SE` over a frozen no-learning baseline, the three adversarial probes (§4, §6) fail as designed, and H2 (learning-gain objective vs. greedy) is measured. This is the real go/no-go.
- **M1 done** = `docs/mdlp/results/M1.md`: schema grows, 100% of live nodes scorable, bounded orphan/duplicate rates, no commit/rollback oscillation over a long run; preceded by a fresh adversarial review (C0).
- **M2 done** = `docs/mdlp/results/M2.md`: a promotion improves held-out competence without monitored regression, under the two-stage reversible procedure.

Each milestone's tests are added to CI before it's called done.

---

## 8. Ownership & the board

Tasks are on `tasks/BOARD.md` (T-001…T-012). The project squad is empty today, so the first task builds the specialists.

| Task | Owner | Note |
|---|---|---|
| T-001 build specialists | `agent-smith` | author `pathway-builder` + `eval-harness-builder` agent defs |
| T-002 B0 scaffold | `pathway-builder` | start here |
| T-003 B1 verifier | `eval-harness-builder` | **highest risk — build first** |
| T-004–T-008 (state, memory, decision, loop) | `pathway-builder` | parallel after B1 |
| T-005 B3 corpus+runner | `eval-harness-builder` | |
| T-009 B7 GO/NO-GO | `eval-harness-builder` | the gate |
| T-010 C0 re-red-team | `@you` | gate before M1 |
| T-011 M1, T-012 M2 | `pathway-builder` | gated; M2 needs GPU/budget (`@you`) |

Move tasks through `Backlog → Assigned → In Progress → Review → Done` on the board as you go; the curator audits stale rows.

---

## 9. Environment & workflow

- **Repo:** `/Users/samyoga/dev/turing-agents`. Work on a branch (not `main`); one logical change per commit.
- **Isolation:** create a **separate venv for `mdlp`** (`python -m venv mdlp/.venv`); install `mdlp/requirements.txt` there. Do **not** add deps to the repo-root environment that `app/` uses.
- **Tests:** `app/` tests run as today (stdlib, `pytest`). Give `mdlp` its own `pytest` config (or extend `pytest.ini` carefully) so the stdlib `app/` suite stays dependency-free. CI: two jobs — `app/` (always) and `mdlp/` (in its venv).
- **The runner** (`domain/runner.py`) calls an LLM to attempt coding tasks → needs `ANTHROPIC_API_KEY` in the `mdlp` env. Keep the corpus offline/deterministic so the verifier is reproducible.
- **Reflect-after:** after a meaningful task, `scripts/capture.sh "<intent>" "<did>" "<learned>"` (the framework's own loop — dogfood it).

---

## 10. Handover-back criteria (when is this "delivered")

The build is delivered when: M0 is documented as passing its gate (at minimum), the red-team regression tests are green in CI, the `mdlp` package is installable and opt-in with `app/` untouched and still pure-stdlib, and `docs/mdlp/results/` records each milestone's evidence. M1/M2 are delivered as their gates pass. A failing **B7** is an acceptable, documentable outcome — it bounds where the approach applies; report it, don't paper over it.

---

## Appendix — quick reference

- **Package layout, interfaces, milestone steps:** `docs/mdlp/IMPLEMENTATION.md` §1, §4, §5–7.
- **`interactions.jsonl` schema:** `{"id","date","intent","did","learned","actor"}` (one JSON object per line).
- **Canonical logs:** `.claude/memory/{interactions,audit,evolution-log}.jsonl`; existing memory artifacts: `skills/**/SKILL.md`, `.claude/memory/lessons.md`.
- **The identity line (L-010):** file-native is canonical + required; MDLP is an optional, derived, rebuildable add-on — never required to run.
- **The precondition:** the loop is only as good as the verifier. If you can't build a trustworthy `PytestVerifier`, the project is NO-GO — surface it rather than shipping a gameable loop.
