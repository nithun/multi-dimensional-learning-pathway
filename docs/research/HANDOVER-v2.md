# Implementation Handover v2 — MDLP `mdlp` (the pathway-learner) → turing-agents

**For:** the turing-agents build team (Claude Code build agents + `@you`)
**Mode:** build — the research + specs are done and gate-approved; this is implementation toward the **v2 release**
**From:** the MDLP research project · **Date:** 2026-06-26 · **Status:** open at **Phase A (make M0 real)** — the inherited gate is still unmet
**Supersedes:** [`HANDOVER.md`](HANDOVER.md) (v1) and folds in [`IMPROVEMENT-NOTE-turing-agents.md`](IMPROVEMENT-NOTE-turing-agents.md). Both remain as historical record.
**Scope rule:** this doc lives in the MDLP repo; the turing-agents repo is managed separately. File/line refs point into `turing-agents/mdlp/`; board IDs into `turing-agents/tasks/BOARD.md`. Act on it there — nothing here edits turing-agents.

---

## 0. One-paragraph mission

v1 built and unit-tested the v0.2 **machinery** in `turing-agents/mdlp`. v2 turns that machinery into a **real, capability-rich, released learner**: (A) prove the loop measurably improves *true held-out* competence on a real corpus — the gate v1 never actually cleared — (B) implement the six **gate-approved capabilities** (A1, A5, B1, B2, B3, B4) on top, and (C) cut an **installable v2 release** per [`RELEASE-PLAN-v2.md`](../RELEASE-PLAN-v2.md). The identity constraints are unchanged: opt-in Layer 3, `app/` stays pure-stdlib, reward only on held-out, gates are statistical. Faithful, gated implementation — never skip a gate.

---

## 1. Honest status — read this before anything (the reframe)

The single most important fact for v2: **M0 is not actually passed.** Per [`IMPLEMENTATION-REVIEW.md`](IMPLEMENTATION-REVIEW.md) + the improvement note, the build is a faithful, well-tested implementation of the v0.2 *machinery*, but **no result yet shows real learning**:

| What looks done | The reality |
|---|---|
| `docs/mdlp/results/M0.md` reports held-out "+0.487", "B7 GO" | That number is a **constant baked into the synthetic domain** (`domain.py` `held_rate = base + gain·n`) — it proves plumbing, not learning. |
| A `ClaudeRunner` / live runner exists | It's **unwired** (`adapters/runner.py`); the live held-out B7 — the gate the whole design rests on — has **never been run on a real corpus**. |
| `DecisionEngine` is unit-tested | It is **absent from the end-to-end loop** — `LearningRun.run` hard-codes round-robin (`domain.py`), so MDLP's differentiator (learning-gain selection) is not in the demonstration. |

**Therefore v2 starts at Phase A, not at "add features."** Building capabilities on an unproven loop would be building on sand. *If held-out doesn't move under the live runner, stop and fix the verifier before anything else — that is the design's own rule.*

---

## 2. Read first, in this order

| # | Artifact | Why |
|---|---|---|
| 1 | [`IMPROVEMENT-NOTE-turing-agents.md`](IMPROVEMENT-NOTE-turing-agents.md) + [`IMPLEMENTATION-REVIEW.md`](IMPLEMENTATION-REVIEW.md) | **The current-state truth** — exactly what's real vs. baked, with file/line evidence. Phase A is its P0/P1. |
| 2 | `turing-agents/mdlp/` `IMPLEMENTATION.md` | The build guide — package layout, module interfaces, milestone steps. Day-to-day reference. |
| 3 | [`ALGORITHM-v0.2-pathway-learner.md`](ALGORITHM-v0.2-pathway-learner.md) | The source of truth for what each component must do (§1–§15). |
| 4 | [`BUILD-SPECS.md`](BUILD-SPECS.md) | **The v2 capability backlog** — A1/A5/B1/B2/B3/B4 as implementable code-with-tests, each gate-approved. Phase B builds these. |
| 5 | [`RELEASE-PLAN-v2.md`](../RELEASE-PLAN-v2.md) | What v2 ships and the three maturity tiers / cut line. Phase C. |
| 6 | [`ALGORITHM-v0.1-redteam.md`](ALGORITHM-v0.1-redteam.md) | The 8 root causes; §8 below is the regression checklist — don't reintroduce them. |

Don't start Phase A coding until you've read 1–3; don't start Phase B until you've read 4.

---

## 3. Locked decisions (carry-forward + v2 additions)

Unchanged from v1: placement (`mdlp/` at repo root, never imported by `app/`), read-only substrate over the canonical logs, verifier domain (coding task → pytest on held-out), gated milestones, the two principles (P1 measurement-independence, P2 every `add` has an inverse).

**New for v2:**

| Decision | Choice |
|---|---|
| **Housing** | The build **stays in `turing-agents/mdlp`** (where the code is; the site install points there). This resolves `RELEASE-PLAN-v2` **[D-2]** toward turing-agents — the v2 artifact is cut from there, not relocated into the MDLP repo. |
| **v2 scope** | The six approved capabilities are **in scope**, tiered by maturity (`RELEASE-PLAN` §4): A1 + calibration = working core; A5/B1/B2/B4/B3 = experimental. **C1 (human verifier) is tag-only** — a named future-direction marker, no v2 deliverable; the **Frappe/ERPNext instantiation is deferred (too much for v2)**. M2 = design sketch. |
| **Cut line [D-3]** | v2.0 ships **Tier ① validated + Tier ② present-but-experimental + Tier ③ documented**. Do not block the release on Tier ② end-to-end validation (that's the M1 gate). |
| **Versioning [D-1]** | Tag `v2.0.0`; `mdlp` package = `2.0.0`; keep the algorithm/library version distinct from the Turing Agents framework's own line. |

---

## 4. Non-negotiable constraints (the identity — do not break)

1. **`app/` stays pure-stdlib.** Nothing under `app/` imports `mdlp`.
2. **`mdlp` is opt-in and never required.** A project runs identically with or without it.
3. **`mdlp` never edits a project's source or canonical logs** — reader + rebuildable-derived-store writer only.
4. **Verifier precondition.** Only skills with a reliable verifier (`admit`) enter autonomous learning; soft-judge skills are the NO-GO regime.
5. **Reward only on held-out (P1).** Held-out items never enter the agent's context.
6. **Gates are statistical, not scalar** — every commit/rollback/promote/admit tests a delta against its SE via `significant()`.

If a task seems to require breaking one of these, stop and raise it.

---

## 5. The v2 work — three gated phases

```
PHASE A  ── make M0 REAL (the inherited gate; nothing else counts until this clears)
   A0 wire ClaudeRunner on a real held-out code corpus (retire the baked domain)
   A1 put DecisionEngine.choose (learning-gain π) IN the end-to-end loop  ← also lands BUILD-SPEC A1
   A2 calibration (§14) on the live posterior · same-held-out-sample gate (fix the n_trial≠n_eval inflation)
   A3 relabel the old M0 as a wiring check; write the real M0 result
   ★ GATE: held-out competence beats a frozen no-learning baseline beyond z·SE on REAL tasks,
     and the hard-code / memorization probes fail as designed.  FAIL → stop, fix verifier/state. Do NOT start Phase B.

PHASE B  ── the approved capability suite (only after Phase A clears)
   C0 re-red-team the implementation (gate before opening growth) — inherited P2.1
   then implement, each to its approved spec + test list (see §6 map):
     A1 (full EIG blend) · A5 warm-start · B4 spacing · B1 misconceptions · B2 prereq-gap · B3 fleet transfer
   growth-provisioning invariant (RC-3, provision_suite) lands with the schema-opening specs.

PHASE C  ── package & release (RELEASE-PLAN-v2)
   embedded-tier default (pip install + run, no infra) · README/site repoint to standalone if/when relocated
   CHANGELOG split · VERSION/pyproject = 2.0.0 · tag v2.0.0 · red-team regression suite green in CI
```

**Sequencing rule:** Phase A is the whole game; B and C are sequencing. Never skip the Phase-A gate or C0.

---

## 6. BUILD-SPECS → implementation map

Each spec is gate-approved with a parameter set and a test list in [`BUILD-SPECS.md`](BUILD-SPECS.md); implement to that, not from memory.

| Spec (score) | Module (`turing-agents/mdlp/`) | Store(s) | Phase / Tier | Lands |
|---|---|---|---|---|
| **A1** info-gain selection (85) | `decision.py` (§13.1) | state | A → ① | π's objective `U(a)=(1−w)z(E[Δc])+w·z(EIG)`; closed-form Beta EIG (digamma recurrence). Basic LP-π in Phase A; full EIG blend in Phase B. |
| **A5** warm-start (82) | `state.py` / `memory/` init | vector | B → ② | `warm_prior=Beta(α0+n_eff·μ_knn, …)`, MMR diversity, influence decays as `n_own` grows. Needs the vector index (M1). |
| **B4** spacing (82) | new `scheduler` | cache, state | B → ② | `R(t)=exp(−t/S)`, due at `r*`; `S` grows on spaced pass, contracts on lapse; review-budget cap `ρ_rev`. |
| **B1** misconceptions (82) | `memory/` + `graph.py` | vector, graph | B → ② | cluster error traces → admit only on `significant(lift−ρ_M, SE)` held-out → link to prereq → remediate; retire/merge inverse. |
| **B2** prereq-gap (83) | `graph.py` + `eval/` | graph, state | B → ② | backward walk gated by `significant(θ−ĉ[P], SE)`; confirm before redirect; post-redirect outcome feeds `decay_edges`. |
| **B3** fleet transfer (82) | new `transfer` | (per-agent) state | B → ② | zero-trust (no cross-agent `StateStore` read), isomorphic-variant validation, quarantine behind the §8 commit gate. |

**Human verifier (C1) is tag-only in v2** — a named future-direction marker on the roadmap, not a build or design deliverable. The **Frappe/ERPNext instantiation is out of v2 scope (too much now)** — deferred to a later version; its research docs ([`HUMAN-LEARNING-VERIFIER.md`](HUMAN-LEARNING-VERIFIER.md), [`HUMAN-LEARNING-M0-FRAPPE.md`](HUMAN-LEARNING-M0-FRAPPE.md)) stay as reference only. The **M2 weight axis** remains a design sketch.

---

## 7. Red-team regression tests (carry-forward + v2 additions)

Keep every v1 guard (`test_verifier_rejects_hardcoded_constant`, `test_generalization_gate_rejects_memorization`, `test_growth_quarantines_unscorable`, `test_decay_cannot_swing_below_nmin`, `test_pi_avoids_mastered_skill`, `test_retrieval_credit_is_counterfactual`, `test_promotion_is_reversible_then_gated`). Add, per the approved specs:

- `test_eig_peaks_at_uncertain_not_thinnest` (A1 — EIG must not chase the thinnest cell off-frontier).
- `test_warmstart_influence_decays_with_own_evidence` + `test_warmstart_mmr_avoids_filter_bubble` (A5).
- `test_misconception_admitted_only_on_significant_lift` + `test_stale_misconception_retired` (B1, RC-1/RC-4).
- `test_prereq_confirmed_before_redirect` + `test_failed_redirect_decays_edge` (B2).
- `test_spacing_probe_bounds_inflation` + `test_reviews_dont_starve_coverage_floor` (B4).
- `test_transfer_zero_trust_no_cross_state_read` + `test_transfer_quarantined_until_gate` (B3).

Every red-team failure that ships without a guarding test is a regression waiting to happen.

---

## 8. Acceptance / definition of done (v2)

- **Phase A done** = `docs/mdlp/results/M0.md` rewritten to document a **live-runner** run where held-out pass-rate rises beyond `z·SE` over a frozen no-learning baseline **on a real code corpus**, with π in the loop and the adversarial probes failing as designed. *(A NO-GO here is a valid, documentable v2 outcome — it bounds where the approach applies; report it, don't paper over it.)*
- **Phase B done** = each Tier-② spec is implemented to its approved spec + test list, importable, marked `experimental`, with its red-team guards green; C0 re-red-team recorded.
- **Phase C done** = `mdlp` installs (embedded default, zero infra), opt-in with `app/` untouched and pure-stdlib; CHANGELOG `[2.0.0]`; tag `v2.0.0`; full regression suite green in CI.

---

## 9. Ownership & the board (turing-agents)

Tasks live on `turing-agents/tasks/BOARD.md`. Specialists: `pathway-builder`, `eval-harness-builder` (build them first if absent — `agent-smith`).

| Work | Owner | Note |
|---|---|---|
| A0 live runner + real corpus | `eval-harness-builder` | **highest priority — the gate** |
| A1 π in the loop | `pathway-builder` | the differentiator must be in the demonstrated path |
| A2/A3 calibration + same-sample gate + honest relabel | `eval-harness-builder` | |
| ★ Phase-A GO/NO-GO | `eval-harness-builder` + `@you` | inherited B7 |
| C0 re-red-team | `@you` | gate before Phase B |
| A1-EIG / A5 / B4 / B1 / B2 / B3 | `pathway-builder` | one task per spec; map §6 |
| Phase C release | `@you` | tag + CI |

---

## 10. Environment & handover-back

- **Repo:** `/Users/samyoga/dev/turing-agents`; branch, one logical change per commit; `mdlp` in its own venv (`app/` stays dependency-free); two CI jobs (`app/` always, `mdlp/` in its venv). Live runner needs `ANTHROPIC_API_KEY`; keep the corpus offline/deterministic.
- **Delivered when:** Phase A is documented as passing its gate (at minimum), the red-team regression suite is green, the six specs are implemented to their tier, the package is installable + opt-in, `docs/mdlp/results/` records the evidence, and `v2.0.0` is tagged. A failing Phase-A gate is an acceptable, documented outcome.

---

## Appendix — quick reference

- **Current-state evidence (what's baked vs real):** `IMPLEMENTATION-REVIEW.md`; ordered fixes: `IMPROVEMENT-NOTE-turing-agents.md` (Phase A = its P0/P1).
- **Capability specs + params + tests:** `BUILD-SPECS.md` (A1, A5, B1, B2, B3, B4).
- **Release scope / tiers / cut line:** `RELEASE-PLAN-v2.md`.
- **The identity line (L-010):** file-native is canonical + required; MDLP is an optional, derived, rebuildable add-on — never required to run.
- **The precondition:** the loop is only as good as the verifier. If a trustworthy live `PytestVerifier` run doesn't move held-out competence, the project is NO-GO at Phase A — surface it rather than shipping a gameable loop.
