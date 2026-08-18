# H4 patch series — verified, apply-ready (L-012: the crossing is yours)

**Base:** TA commit `d9e78ac` (the AUDIT-TA-2026-08 HEAD, branch `build`). Built and **test-verified in an isolated clone** — TA itself was never touched. Baseline at `d9e78ac`: 400 passed / 24 skipped (`pytest mdlp/tests --ignore=mdlp/tests/integration`); after the full series: **all green including 14 new tests** (`mdlp/tests/test_h4_wiring.py`).

## Apply

```bash
cd /Users/samyoga/dev/turing-agents
git checkout -b mdlp-h4 d9e78ac
git am "/Users/samyoga/Documents/Claude/Projects/Multi-Dimensional Learning Pathway/patches/h4-series"/*.patch
python -m pytest mdlp/tests --ignore=mdlp/tests/integration -q
```

(If `build` has moved past `d9e78ac`, `git am -3` three-way-merges cleanly for these files unless the same regions changed; rebase `mdlp-h4` onto `build` afterward as usual.)

## The patches

| # | Task | What it does |
|---|---|---|
| 0001 | **H4-2** | Calibrator wired behind `estimate()` (the **uncertainty half** of §14.2: SE from deflated `n_eff`; served mean stays raw — see findings below); `LiveLearningRun` constructs and feeds it (decision-time p̂ vs realized held-out, logged pre-update per P1); `scheduler.py`'s false "§14-calibrated" comment made conditionally true; **plus a real bug fix found by wiring**: tied-prediction isotonic blocks now pool (previously `recalibrate` returned the first tied observation's outcome — e.g. 0.0 for a 50/50 stream at one p̂). |
| 0002 | **H4-3** | `corpus.py` imports `CircuitBreaker` + `rollback_fires` beside `commit_gate` (the W4.7 acceptance grep passes); live tick gains fixed per-skill baselines (RC-7), a rollback check powered by the **drift posterior** (previously written every tick, read by nothing), **per-skill rollback targeting** (a global LIFO retired an innocent skill's note — caught by the nova prereq test), and a halting breaker with recorded reasons. Miscalibration is a plumbed 5th trigger, **disarmed at the call site with three demonstrated failure modes documented in-code** (see findings). |
| 0003 | **H4-7** | `add_skill` docstring-fenced REBUILD-ONLY on the Protocol + both tiers, with docstring tests (the `put()` precedent). Closes the audit's new residual. |
| 0004 | **H4-5** | The A1 objective `U(a) = (1-w)·z(E[Δc]) + w·z(EIG)` wired into `choose()` behind `a1_w`; `a1_w=0` (default) takes the **byte-identical M0 code path** (tested: same rng stream, same choices), so the M0 GO stays valid; `LiveLearningRun(a1_w=…)` is the live call site. Resolves `decision.py`'s own in-code A1-status TODO. |

## Research findings carried back (for MDLP §14 — logged here so they cross with the code)

1. **Pooled per-band mean-remapping mis-serves per-skill reads.** Full §14.2 wiring (mean through the isotonic map) pulled an *unlearnable* skill's competence **up** because the band-pooled map was fitted mostly on learnable skills' trajectories (the `nova-chain` test caught it). Shipped: SE-deflation only; mean remap needs per-cell-homogeneous band granularity. §14 should state the granularity precondition.
2. **The §14.3 miscalibration trigger lacks a separating statistic.** Three in-run implementations each failed differently: cumulative-raw over-fires on genuinely-learning cold starts (the raw prior is *supposed* to be wrong at first); in-sample recalibrated ECE is degenerately ~0 (each PAV block bins at its own mean); fit-on-old/judge-new cannot distinguish learning nonstationarity from broken confidence and extrapolates badly out of range. The trigger ships plumbed + tested but disarmed; §14 owes the statistic that separates "still learning" from "mis-calibrated." (Candidate direction: judge only cells whose posterior is *stationary* by their own LP test.)
3. **Per-item observation floors mis-scale.** One 40-item tick clears a 20-observation floor instantly and judges binomial noise; `n_floor` semantics need a decision-point (tick) unit, not an item unit.

## Not yet in this series (remaining H4 tasks)

H4-4 (§4 verifier on the live path), H4-6 (§16 wire-or-park), H4-8..11 (spec-wave adoption: conformance checker, constraint table, learning liveness, epoch discipline), T3/T4 (founder-gated corpus + autonomy). The series is cumulative — later patches will extend it in this same directory.
