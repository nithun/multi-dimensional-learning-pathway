# MDLP H4 crossing brief — for the TA workspace (2026-08-19)

**To:** the TA workspace agent/operator. **From:** the MDLP research repo, carried by the founder (L-012: nothing was written into this repo from outside; this file and everything it names arrived by the founder's hand). **Copy this file to `docs/briefs/` verbatim on arrival.**

**What this is:** the MDLP research side audited this workspace at `d9e78ac` (read-only, 2026-08-18 — report: `AUDIT-TA-2026-08.md`, crossing with this brief), then built the entire buildable half of its HANDOVER-v4 task list as a **verified patch series against that exact commit**. This brief tells you what's arriving, how it maps onto your own WBS and board, what changed behaviorally, and what still waits on the founder.

---

## 1. What's arriving (three things)

1. **The H4 patch series** — 9 patches, `git am`-ready, base `d9e78ac` (your `build` at audit time). Built and test-verified in an isolated clone: your `mdlp/tests` suite green **plus 48 new tests**, and your repo-root `tests/` suite (102 files) verified unbroken. Full per-patch detail and apply commands: `README.md` beside this brief.
2. **The 2026-08-13 MDLP spec wave** (zero trace here pre-crossing): ALGORITHM now §1–§21 (incl. §10.1 epoch discipline, §20.10 learning liveness, §21 safety properties PR-1..PR-10), DATA-LAYER incl. §6.3 constraint table and §12 conformance checker, plus `IMPL-PROTOCOL.md` (a pre-registered implementability study). File these under `docs/mdlp/` and update `LINKAGE.md`.
3. **`AUDIT-TA-2026-08.md` + `HANDOVER-v4.md`** — the evidence base and the task list this series executed. HANDOVER-v4 supersedes v3; note v3 §1 is known-stale on one A5 claim (see §5 below).

## 2. Mapping onto YOUR ledger (WBS / board / lessons)

- **W4.7 ("wire the dormant safety kit, closes G3") — CLOSED by this series.** Your own acceptance greps now pass: `corpus.py` imports more than `commit_gate`; `calibration.py` has non-test importers; `drift_estimate` has a live reader. Your L-044 ("built-but-unwired, two tracks at once") gets its mechanical detector in patch 0006: the conformance checker's manifest reproduces the audit's G3 findings synthetically, then retires them.
- **G3's five constructs, disposition:** calibrator **wired** (SE half; see finding 1) · rollback/breaker/drift **wired** · §4 verifier **wired** (admission + counterfactual; shape_ok retracted-with-reason) · A1 **wired opt-in** (`a1_w`, byte-identical M0 path at 0) · §16 **formally parked** post-M-R with un-park steps + a guard test (your live loop is storeless; wiring a 5-store dispatch into it would be fake integration).
- **Board tasks to mint (suggested, your numbering):** (a) apply + verify the series on a branch; (b) rebase `mdlp-h4` onto current `build` (see §4); (c) wire `learning_liveness()` into your cycle digest/autopilot reporting (it is surfacing-only by design); (d) run the conformance checker at the end of your next real run and file its report.
- **W3.0 / W3.7 stay founder-blocked** (your board's FROZEN state is correct). Note for the W3.0 decision: `IMPL-PROTOCOL.md` is a ready-made candidate corpus design (real coding tasks, pytest-verified, exists today) — flagged as *input to* the decision, not a preemption of it. **W4.1–W4.6 (autonomy, watchdog first) is the next engineering block after those decisions** — ALGORITHM §20 is now the full build spec for it.

## 3. Behavioral changes you should know before rebasing

- **`LiveLearningRun` now REFUSES to start if the corpus grader fails admission** (§4.3; reliability lower-CI ≥ ρ_min). Small hermetic corpora (< ~20 tasks) pass `require_admission=False` — the documented non-production opt-out; several of your existing tests were updated to use it.
- **Deterministic verifier call counts changed** (counterfactual probes re-run passing held-out items): the b7 hermetic counts moved from `{learn: 72, base: 24}` to `{learn: 84, base: 27}` — updated in-test with rationale.
- **`MergeReport` gains an additive `flags` field**; merge() now evaluates the DL §6.3 constraint table (embedded tier). One genuine semantic fix rode along: **absorption no longer leaves self-loops** (a→b redirected to a→a on `maybe_merge` — a skill as its own prerequisite; contraction semantics now drop internal edges).
- **The §14.3 miscalibration breaker trigger is plumbed but DISARMED** at the live call site, with three demonstrated failure modes documented in-code. Do not arm it until MDLP §14 defines the separating statistic (finding 2 below). Arming is a one-word change, deliberately.
- **New modules:** `mdlp/liveness.py`, `mdlp/stores/conformance.py`, `mdlp/stores/constraints.py`, `mdlp/stores/epoch.py`. All surfacing/validation — none can halt, defer, or modify learning.

## 4. Rebase guidance (your `build` has moved past the base)

The series is pinned at `d9e78ac`; your tree was dirty and `build` active at audit time. Apply on a branch from the base first (clean verification), then rebase onto `build` with `git am -3` / normal rebase. **Likely conflict surfaces:** `mdlp/mdlp/corpus.py` (the series' biggest mover) and `mdlp/mdlp/stores/embedded/backends.py` — if your W-streams touched the same regions since 2026-08-18, resolve in favor of keeping BOTH behaviors and re-run `mdlp/tests/test_h4_wiring.py` + `test_constraints.py` + `test_conformance.py` + `test_liveness.py` as the acceptance bar. The 48 new tests are the contract; if they pass post-rebase, the wiring survived.

## 5. What crosses BACK to the research side (via the founder — you cannot push it)

- **Six research findings** (series README, findings 1–6): pooled-band mean-remap harms per-skill reads · the miscalibration separating-statistic gap · per-item floor mis-scaling · **the Zeno-slope problem** (asymptotic LP stays "significant" forever; §20.10 needs `ε_lp`) · self-loop contraction semantics for §6.2 · store-vs-algorithm-layer acyclicity. These become gated MDLP spec deltas; you'll see them in a future crossing.
- **Your A5 measurement-invalidation is STILL waiting to cross out** (your `2026-08-10-session-handover.md:117` — "only the founder can carry it across"). HANDOVER-v4 §H4-1 is the reconciliation slot. Remind the founder.

## 6. First-ten-minutes verification checklist

```bash
git checkout -b mdlp-h4 d9e78ac
git am <crossing-dir>/*.patch                 # 9 patches apply cleanly
python -m pytest mdlp/tests --ignore=mdlp/tests/integration -q   # 0 failed (48 new tests)
python -m pytest tests -q                     # repo-root suite unbroken
grep -c "from .loop import CircuitBreaker, commit_gate, rollback_fires" mdlp/mdlp/corpus.py  # 1 — W4.7's grep
```

## 7. Do-not list

- Don't re-derive what the audit already verified (G1 fixed, G2 adopted — your work, confirmed source-level).
- Don't arm the miscalibration trigger (§3 above).
- Don't treat the §16 park as retirement — it has stated un-park steps and a guard test.
- Don't action the six findings locally — they are spec-side deltas that must flow MDLP's gate first (both repos' shared discipline: the spec of record moves through review-360 → change-approver, then crosses).

*Provenance: every claim here traces to `AUDIT-TA-2026-08.md` (file:line evidence), the series README, or a gate-approved MDLP spec section with its decision record in `docs/research/reviews/`. Built 2026-08-18/19 in an isolated clone; this workspace was never written to before this crossing.*
