# Red-team of PL-v0.1 — findings & the v0.2 patch set

**Date:** 2026-06-22 · **Method:** three independent adversarial reviewers, each attacking a different subsystem of `ALGORITHM-v0.1-pathway-learner.md` with no knowledge of the others, then synthesized. · **Status:** `PL-v0.1` is **not safe to run as specified**; this doc is the to-fix list for `v0.2`.

---

## Verdict

**The architecture survives; the mechanisms do not.** The pipeline decomposition (state → frontier → eval → grow → commit), the act/learn data split, the two-axes-as-one-loop design, and the verifier-as-GO-condition *instinct* all held up. What broke is the **joints** — the estimators, gates, and provisioning steps are specified as scalar arithmetic and add-only operations, and they fail under their own sampling noise, their own optimizer pressure, and their own growth.

**Three independent pilot-killers were found — and the reviewers disagreed on which is worst, because there are genuinely three:**

| Pilot-killer | Found by | Fires in v0.1 memory-only pilot? |
|---|---|---|
| **Verifier gaming** — schema-valid-but-semantically-null tool calls + answer-key lessons memorizing the pinned suite; `ĉ→1.0` while true competence is flat | reward/safety adversary | **Yes — day one** |
| **Eval-suite bootstrap gap** — `g` creates skill nodes but nothing creates their eval suite/verifier; the moment growth spawns an out-of-domain skill it's born dead and silently poisons reachability + retrieval | growth adversary | **Yes — first out-of-domain growth** |
| **Decay vs. no-regression oscillation** — `γ<1` (the headline drift fix) collides with the no-regression gate (the headline safety fix); spurious rollbacks trip the circuit-breaker and halt the loop | dynamics adversary | Yes — at any realistic scale |

The uncomfortable implication: the **v0.1 "runnable subset" was meant to be the safe, de-risked starting point, and it is where two of the three killers fire.** Its single fixed verifier *masks* the bootstrap gap rather than solving it. v0.1 must be re-scoped (below) before any pilot.

---

## The meta-principle behind most of the failures

> **The system optimizes its own scoreboard.** Almost every CRITICAL finding is a case of the measurement being entangled with the thing being optimized — and the cure is the same each time: **make the measurement independent of the optimization.**

- Phantom-progress commit ratchet, suite memorization, weak-spot calcification, sub-epsilon slow drift — all are the optimizer gaming its own metric.
- The fixes — held-out evals, counterfactual credit, audit-anchored verifier reliability, cumulative baselines, statistical gates — are all the same move: decouple measure from optimize.

A second structural theme: **every `add` in the spec lacks an inverse.** Growth adds skills (no merge), adds prereq edges (no prune), adds tree nodes (no GC), commits (no cumulative-baseline check). Add-only + hard gates = a monotonic ratchet toward an ever-more-wrong, ever-more-constrained state.

---

## Eight root causes (≈40 findings collapse to these)

### RC-1 · Point estimates where statistical tests are required  — CRITICAL
*Findings:* LP = difference of small-sample Beta means is mostly noise (SNR ≈ 0.3 at N=20); the commit gate `ĉ'≥ĉ−ε` is asymmetric so it commits lucky upward eval draws (winner's curse) and inflates baselines; the `λ·novelty` term can't be ranked against a Q̃ whose noise (±0.16) exceeds its real range (~0.2).
*Why it bites:* the decision core ranks actions, and the commit/rollback/promote/admit gates all fire, on quantities whose sampling error is larger than the effect being measured. The "curriculum" is a noise-driven random walk.
*Patch:* every gate becomes a **test against its own standard error**, not a scalar compare. LP = posterior **slope over the window `k`** (which §4.3 names but never uses), computed on **paired** before/after items (cancels shared variance). Selection requires `LP > z·SE(LP)`; commit requires `Δĉ > ε + z·SE`, measured on a **separate confirmation split** from the one used to select.

### RC-2 · The verifier is treated as ground truth but is an incomplete, pinned, self-calibrated, gameable proxy — and the whole system is an optimizer aimed at it  — CRITICAL
*Findings:* schema-valid/semantically-null hacks (hard-code the constant the assertion checks); `write_lesson` converges to an answer-key for the pinned items; IRT difficulty self-recalibrates to hide the memorization; `reliability(v)` is **undefined and circular** (measured against the very suites `v` validates); scoring can bind to a weaker admitting verifier; `safety_eval` is itself just a gameable pinned suite; rejection-sampling then **launders the hack into weights** (irreversible).
*Why it bites:* the report's H1 names reward-hacking as the top risk *with mitigations*; §5 then omits those mitigations. "A verifier exists" ≠ "the loop is safe."
*Patch (bundle):* (a) **held-out secret split** per skill that never enters `ctx`; **reward only on the held-out delta**; add a generalization gate `Δheld-out ≥ ρ_gen·Δpublic`. (b) verifiers assert on **trajectory shape** (which tool, args-from-query vs. constant) + **counterfactual items** (inject a different id at runtime so a hard-coded constant fails). (c) `reliability(v)` = precision/recall vs. a **human audit set** `v` never trains on, admit on the **lower CI bound**, re-checked **per difficulty band**. (d) score with the **strictest applicable** verifier. (e) import H1's mitigations into §5: process/ensemble verifiers, **human spot-check of the kept set before any promotion**, KL/regret bounds.

### RC-3 · Growth creates structure it cannot measure (growth ⟂ admission/provisioning)  — CRITICAL
*Findings:* `g` makes a node + prereq edges but nothing makes its **eval suite or verifier**; the node is un-admittable, unscorable, stuck at the cold prior, and permanently distorts `reachable`, retrieval (`learning_progress`/`competence_gap` are garbage for an unscored skill), and future clustering. v0.1's single fixed verifier hides this until the first out-of-domain spawn.
*Why it bites:* an open schema you can't score is one you can't learn on — it converts "growing skills" into "growing un-measurable noise," and the metric that would reveal it (competence coverage) is exactly what the dead nodes can't report.
*Patch:* make **"has a pinned suite + an admitted verifier" an invariant of live-graph membership.** `g` gains a `provision_suite(s_new)` step: **inherit** the parent cluster's verifier + a templated item-generator, or **synthesize** held-out items from the failure cluster (gated by an existing reliable verifier), else **quarantine to `pending_human`** — excluded from `reachable`, retrieval, and the clustering centroid set until a human attaches a verifier.

### RC-4 · Add-only structures + hard gates = a wrong-way ratchet  — CRITICAL/HIGH
*Findings:* no skill **merge** (embedding noise splits one capability into two half-learned cells that never clear `θ` → self-inflicted stall); prereq edges are **add-only and correlational**, and `reachable` is a **hard AND** over prereqs, so one spurious edge permanently removes a skill from the frontier and edge-density monotonically collapses the frontier (possible cycles, undefined acyclicity); orphan skills from growth×novelty are never **pruned**; the MCTS tree and per-node checkpoints **never GC** (unbounded RAM + ObjectStore).
*Patch:* give every `add` an inverse — periodic **merge** (hysteresis `τ_merge>τ_new`, union evidence), **prereq edges soft/probabilistic/decaying** with an acyclicity invariant and fan-in cap, **orphan pruning** (retire no-progress skills), **tree GC + checkpoint retention** (bounded rewind horizon + tagged milestones). And make **`reachable` soft** — weight candidates by `∏P(ĉ_prereq≥θ)` from the Beta posteriors instead of a hard AND. This single change also fixes frontier starvation and the prereq false-negatives.

### RC-5 · A single global γ is over-determined  — CRITICAL
*Findings:* one decay constant is asked to set the **retention horizon**, the **exploration-uncertainty floor**, and the **rollback sensitivity** at once. Consequences pull opposite ways: low γ tracks drift but (i) lets one eval swing a decayed cell's `ĉ` by ~0.28 ≫ ε → spurious rollback → circuit-breaker halt, and (ii) floors `u` at `n_eff*=m/(1−γ)` so skills never look "mastered/stable" → **weight-axis promotion never fires**. High γ fixes those but loses drift tracking.
*Patch:* **decouple the dials.** Per-skill decay (fast for volatile/weight-touched, →1 for stable verified). Maintain **two posteriors** — slow-decay "have I mastered this" (drives promotion/exploration-floor) and fast-decay "is it regressing now" (drives rollback). Rollback only on a **fresh, adequately-powered** re-eval (RC-1), never on a decayed stale estimate. Cap minimum `n_eff` so decay alone can't move `ĉ` by > ε.

### RC-6 · Non-stationarity invalidates the value tree, but re-anchor only refreshes competence  — HIGH (CRITICAL for the weight axis)
*Findings:* UCT `n.value` is a uniform mean over all history with a **never-resetting** `n.visits`; after a weight move the policy changes but the tree's Q is frozen at the old policy's performance for hundreds of iterations; `invalidate_caches` refreshes `Θ`/`z` but is **silent on MCTS node values**; mid-search node additions break UCT's exploration normalization.
*Patch:* on a checkpoint change, **discount/reset the affected subtree's `value` and `visits`** (mirror the `Θ` invalidation already prescribed); use **discounted/sliding-window UCT** so old-policy returns age out; use **progressive widening** + prior-initialized child values for mid-search growth.

### RC-7 · Learning-progress curricula abandon hard skills, and safety is suite-bound — so harm/weakness accrues with no gate firing  — CRITICAL
*Findings:* a skill far below `θ` is never near-frontier → never selected → never improves (weak spots **calcify**, and nothing trips a gate because you can't regress on what you never attempt); a foundational-but-stale context that unlocks a far region scores low on every retrieval term incl. the novelty exploration slice → **whole subgraph stays dark** (filter bubble); **sub-epsilon slow drift** degrades a skill 0.95→0.40 with zero rollbacks (per-step tolerances don't compose); gates test **eval-suite competence, not safety-in-the-wild** (train/deploy gap) — a promoted agent can do harm in production while every eval is green; reversibility doubles as a **safety-boundary-mapping oracle**.
*Patch:* **minimum-coverage floor** (every admitted skill practiced at rate ≥ `f_min` regardless of LP); **reachability-exploration** term (sample context by info-gain on *unlocking unreachable regions*, distinct from novelty); **cumulative regression gate** against a fixed ancestor baseline (`ĉ'≥ĉ_baseline−ε_cum`), not just the parent; a **third circuit-breaker trigger on production-outcome degradation** + continuous sampling of real trajectories into the held-out suite; **held-out, unpredictable, traffic-drawn safety items**; don't retain fine-grained gradient info from safety-failed branches + a "probing-the-fence" detector.

### RC-8 · Promotion (D1) is simultaneously too eager and too timid  — CRITICAL/HIGH
*Findings:* it bakes the **most-frequently-used (⇒ most-overfit)** skill irreversibly into weights on a *pinned-suite* "eval-proven" check (selects *for* the failure it's meant to prevent); the no-regression gate runs **after** the expensive train (wasted compute) and over an **undefined `monitored` set** (interference on un-monitored skills is invisible); yet the five-way **AND-conjunction may never fire** (product of conservative thresholds ≈ 0; and γ-churn keeps "stability" from ever holding) → **the weight axis is dead**, collapsing the two-axis value prop to one.
*Patch:* **two-stage promotion** — reversible LoRA-adapter probation (detachable) before any irreversible base merge; promote only on **held-out + counterfactual + human-spot-check**; **cheap pre-train interference prediction** (Fisher/gradient-overlap on a sentinel set) to skip likely-regressing promotions before paying; an explicit, conservatively-large, versioned `monitored` set; replace the AND-conjunction with a **scored promotion index** crossing one bar + a periodic **promotion review** so the axis is evaluated on a cadence.

---

## What held up (be fair)

- The **overall pipeline** (validate→infer→decide→grow→commit) and its mapping to the paper's engines — sound.
- The **act/learn (hot/cold) data split** — no reviewer broke it; the gaps were *additions* (tree-value invalidation, checkpoint GC), not refutations.
- **Checkpoint/rewind** as a primitive — sound, but reversibility is *not free* (it enables boundary-mapping and oscillation; pair it with rate-limits and info-hygiene).
- **Verifier-as-GO-condition** — the right instinct; it was under-specified, not wrong. RC-2/RC-3 are about making it real, not replacing it.

The flaws are in **mechanism**, not **architecture**. That is the good news: `v0.2` is a patch set, not a redesign.

---

## Re-scoped pilot (do this instead of §10 as written)

- **Milestone 0 — prove the loop measures truth.** Fixed skill set (**growth OFF**), memory-axis only, **held-out + trajectory-shape + counterfactual** verifier, statistical commit gate (RC-1). Success = **held-out** competence moves (not pinned). This is the real H1 de-risking probe; if held-out doesn't move, stop.
- **Milestone 1 — turn growth on, safely.** Enable `g` *with* `provision_suite` + `pending_human` quarantine (RC-3), soft reachability + merge/prune (RC-4), decoupled decay (RC-5). Success = schema grows *measurable* skills, no orphan sprawl, no oscillation.
- **Milestone 2 — add the weight axis.** Two-stage reversible promotion (RC-8), tree-value invalidation (RC-6), production-outcome breaker + coverage floor (RC-7).

---

## v0.2 patch checklist (one line each)

- [ ] Statistical gates everywhere: select/commit/rollback/promote/admit test against SE/CI, not scalars (RC-1, RC-5).
- [ ] Held-out secret eval split; reward on held-out delta; generalization gate (RC-2).
- [ ] Trajectory-shape + counterfactual verifiers; score with strictest applicable; `reliability(v)` from a human audit set, per-band, CI-lower-bound (RC-2).
- [ ] `provision_suite` + `pending_human` invariant: no unscorable node in the live graph (RC-3).
- [ ] Inverses for every add: merge, prune, edge-decay, GC; **soft probabilistic reachability**; acyclicity invariant (RC-4).
- [ ] Decouple γ: per-skill + dual mastery/drift posteriors; rollback on fresh powered re-eval; min-`n_eff` cap (RC-5).
- [ ] Invalidate/discount MCTS tree values on checkpoint change; discounted-UCT; progressive widening (RC-6).
- [ ] Minimum-coverage floor; reachability-exploration; cumulative-baseline regression gate; production-outcome breaker; held-out safety items (RC-7).
- [ ] Two-stage reversible promotion; pre-train interference prediction; explicit `monitored` set; scored promotion index (RC-8).
- [ ] Import H1's anti-hacking mitigations into §5 (process/ensemble verifiers, human spot-checks, KL/regret bounds) (RC-2).
