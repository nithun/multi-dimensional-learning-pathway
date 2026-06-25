# Improvement Note → turing-agents (`mdlp` implementation)

**From:** the MDLP research project · **Date:** 2026-06-25
**Basis:** [`IMPLEMENTATION-REVIEW.md`](IMPLEMENTATION-REVIEW.md) (read-only review of the `mdlp` package) + the candid gap analysis in [`LANDSCAPE-self-learning-agents.md`](LANDSCAPE-self-learning-agents.md) §7.
**Status:** a hand-off note. This lives in the MDLP repo (the turing-agents repo is managed separately); pull it in or act on it there. File/line refs are into `turing-agents/mdlp/`. Board IDs reference `turing-agents/tasks/BOARD.md`.

> **One-line:** the implementation is a faithful, well-tested build of the v0.2 *machinery* — but no result yet shows real learning, because the domain and `FakeRunner` define the competence they measure and the decision core isn't in the end-to-end path. Everything below is ordered to fix that.

---

## P0 — Make the proof real (the only thing that matters for v1)

**P0.1 — Wire the live runner and run B7 for real.** `ClaudeRunner` exists (`adapters/runner.py`) but is unwired; the live held-out B7 is the gate the whole design rests on. Run it on a **real code corpus** (held-out unit tests), not the synthetic domain.
- *Why:* Review **C1** — the current "+0.487" is a constant baked into `domain.py:36-40` (`held_rate = base + gain·n`); it proves plumbing, not learning.
- *Done when:* held-out competence beats a frozen no-learning baseline **on real tasks**, the memorization/hard-coding probes fail as designed, and it's written up replacing the hermetic M0 number.
- *Board:* T-009 (B7), T-005 (live runner).

**P0.2 — Put `DecisionEngine` in the end-to-end loop.** `LearningRun.run` hard-codes round-robin (`domain.py:77`) and never calls `DecisionEngine.choose`, so MDLP's differentiator (learning-gain action selection) is absent from the demonstration.
- *Why:* Review **C2** — the novel core is unit-tested in isolation but unproven in the loop.
- *Done when:* the B7 run selects actions through `π` and the result holds with selection on.

---

## P1 — Close the demonstration gaps

**P1.1 — Relabel M0 honestly.** `docs/mdlp/results/M0.md` headline ("the learning loop measures truth", "B7 GO signal") will get quoted out of its own "Scope & honest limits". Re-title it a **machinery/wiring verification**; reserve "B7 GO" for P0.1.  *(Review C1.)*

**P1.2 — Real trajectory shape-analysis for the live verifier.** `eval.py:65` `shape_ok = attempt.derived_from_query and …` is a harness-set boolean. The **counterfactual probe** (`eval.py:66-69`) is the genuinely real defense; keep leaning on it. For the live runner, replace the `derived_from_query` flag with actual trajectory inspection (which tools ran, did args come from the query vs a constant).  *(Review C3.)*

**P1.3 — Score the gate and competence on the same held-out sample.** `domain.py:87-94` computes the gate's `se_secret` from `n_trial=200` while competence updates on `n_eval=20`, making the gate artificially confident. In the real domain, use the same held-out items for both.  *(Review M1.)*

---

## P2 — The pending v0.2 / red-team pieces (gates before M1/M2)

**P2.1 — C0: re-red-team the *implementation*.** The v0.2 fixes are designed; the implementation hasn't been adversarially re-tested. This is an explicit gate before opening the growth schema.  *(Board T-010.)*

**P2.2 — Implement the growth-provisioning invariant (RC-3).** `stores/provision.py` is service-detection, **not** the `provision_suite` "no unscorable node enters the graph" rule. That invariant — and the merge/prune/edge-decay inverses — must land with M1 growth.  *(Review M2; Board T-011.)*

---

## P3 — Close the competitive/frontier gaps (decide, then build or scope out)

From `LANDSCAPE-self-learning-agents.md` §7 — the field has these and `mdlp` doesn't:

**P3.1 — A self-modification axis.** DGM-style: the agent edits its own scaffold/decision/retrieval code *around frozen models* (high-leverage, cheaper than fine-tuning). `mdlp` has memory + (gated) weight axes but no "modify your own design" action type.

**P3.2 — A task/curriculum generator.** Absolute-Zero / R-Zero generate their own problems from zero data. `mdlp` is reactive (grows from observed failures, needs provisioned suites). Add a challenger that manufactures the frontier — or consciously scope it out.

**P3.3 — Make `π` learned, and position vs Self-Evolving Curriculum (arXiv 2505.14970).** SEC already does learning-gain bandit selection over *problems*; `mdlp`'s π selects by the same objective but is hand-designed. To genuinely occupy the "learned meta-policy" frontier the agentic-RL survey names, let π adapt from experience.

*(Each P3 item is a v1.x/v2 scope decision, not an M0 blocker — but they're the gaps that determine whether `mdlp` leads or trails the field.)*

---

## Nits (low priority)

- `AgentLearningLoop.can_learn()` (`adapters/learning.py:110-112`) is correct but relies on `and`/`or` precedence — add parens / refactor for readability. *(Review M3.)*
- `bench.py`'s `b7_margin` is a constant off the baked domain — drop it or label it non-diagnostic; the gate checks in the same report are real.
- `n_min` floor is tested on `update(1,0)` but the loop updates in bulk — add a bulk-update regime test.

---

## Sequencing

```
P0 (live B7 with π in the loop)  ──►  if held-out moves: proceed
                                       if not: stop, fix the verifier (the design's own rule)
P1 (honest relabel + real shape + same-sample gate)   ── in parallel with P0
P2 (C0 re-red-team → growth-provisioning)             ── gate before M1
P3 (self-mod axis / task-gen / learned π)             ── v1.x scope decisions
```

**The discipline the design already states:** *if held-out doesn't move under the live runner, stop and fix the verifier before building anything else.* P0 is the whole game; the rest is sequencing.

---

*Full findings and file/line evidence: [`IMPLEMENTATION-REVIEW.md`](IMPLEMENTATION-REVIEW.md). Competitive context: [`LANDSCAPE-self-learning-agents.md`](LANDSCAPE-self-learning-agents.md).*
