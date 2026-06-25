# The Landscape of Self-Learning AI Agents (2023–2026)

**A survey for positioning MDLP.** Produced by the `deep-research` harness: 5 search angles → 24 primary sources fetched → 116 claims extracted → **25 verified by 3-vote adversarial check (25/25 confirmed, 0 killed)** → synthesized. Date: 2026-06-25.
**Calibration:** **[E]** established (primary peer-reviewed / official repo) · **[P]** plausible (recent, self-reported, or pre-peer-review) · **[S]** speculative.
Companion: `REPORT-self-learning-agents.md` (the earlier prior-art pass), `ALGORITHM-v0.2-pathway-learner.md` (MDLP's design).

---

## 1. Executive summary

The field splits cleanly into **two mechanism classes**, and a **third has emerged in 2025–2026**:

1. **Context/memory-level learning** (weights frozen) — the *established, dominant* paradigm. Agents improve via skill libraries, natural-language memory, and verbal reflection. Canonical 2023 systems: **Voyager, Reflexion, Generative Agents**. **[E]**
2. **Weight-level learning** — matured in 2025 into **"Agentic RL,"** formally distinguished from earlier preference fine-tuning and organized around six agentic capabilities. **[E]**
3. **Self-modification & self-evolution** (the 2025–2026 frontier) — agents that **rewrite their own code** (Darwin Gödel Machine) and **generate their own curriculum/training data** to fine-tune without human labels (Absolute Zero, R-Zero, ALAS, EigenData). **[E/P]**

**The headline for this project:** the agentic-RL survey *itself* names the open frontier as **"meta-learning for adaptive reflection"** — a learned **meta-policy that chooses the *form* of learning per task by expected gain** — and states the reflection process today "remains largely handcrafted and static." **No surveyed system was found that selects the next learning action by expected learning gain through a held-out verifier.** That is precisely MDLP's design locus. The field treats MDLP's core idea as an *open, unattempted frontier* — strong evidence the white space is real (though MDLP's own efficacy remains unproven). **[E** that the frontier is named open; **P** that MDLP is the right fill.**]**

---

## 2. Context/memory-level learning — the established paradigm  [E]

Improvement without any weight update, the most mature and widely-deployed form.

- **Voyager** (arXiv 2305.16291, NeurIPS 2023) — "the first LLM-powered embodied **lifelong learning** agent in Minecraft… without human intervention," explicitly bypassing "model parameter access and explicit gradient-based training or finetuning." Three weight-free mechanisms: (1) a **skill library** = a vector DB of verified executable code keyed by the embedding of its NL description, retrieved for reuse; (2) iterative prompting with **self-verification**; (3) an **automatic curriculum** proposing progressively harder tasks from the agent's exploration frontier. **[E]**
- **Reflexion** (arXiv 2303.11366, NeurIPS 2023) — reinforces agents "not by updating weights, but instead through linguistic feedback": the agent **verbally reflects** on task feedback and stores it in an episodic memory buffer. Learning is **per-task iterative across trials** (memory resets per problem) — *not* lifetime-continuous. **[E]**
- **Generative Agents** (Park et al., UIST 2023, DOI 10.1145/3586183.3606763) — an LLM + **memory stream** + **reflection** (synthesizing observations into higher-level insights) + dynamic retrieval, no weight updates. Ablations showed observation, planning, and reflection each contribute critically; agents accumulate experience **online** over simulated days, producing emergent coordination. **[E]**
- **DSPy** (github.com/stanfordnlp/dspy) — *programs* (not prompts) LM pipelines and **optimizes prompts and weights against a metric** — but **offline against a fixed dataset+metric**, not online by per-action expected gain. A key contrast point for MDLP (§7). **[E]**

These map onto MDLP's **memory axis** and are subsumed by it as choices of the "validate" gate (cf. `REPORT-self-learning-agents.md` §3).

---

## 3. Weight-level learning — "Agentic RL" formalized in 2025  [E]

**"The Landscape of Agentic Reinforcement Learning for LLMs: A Survey"** (arXiv 2509.02547, submitted Sep 2 2025; published TMLR Jan 2026) is the field's reference framing:

- It formally models prior **preference-based fine-tuning (PBRFT)** as a *degenerate single-step MDP* (horizon T=1, deterministic transition), versus **Agentic RL** as a **temporally-extended, partially-observable POMDP** (T>1, dynamic transitions, step-wise rewards combining sparse task + dense sub-rewards). **[E]**
- It proposes a **capability-centered taxonomy** of six capabilities RL optimizes: **planning, tool use, memory, reasoning, self-improvement, perception** — RL being "the critical mechanism for transforming these capabilities from static, heuristic modules into adaptive, robust agentic behavior." **[E]**
- **Self-improvement** is a *spectrum*: from **ephemeral inference-time verbal self-correction** with no gradient updates (Reflexion, Self-Refine, CRITIC, Chain-of-Verification — "improvements are ephemeral and confined to a single session") up to **RL-internalized self-correction** that bakes reflective feedback into model weights for durable capability. **[E]**

This is MDLP's **weight axis**, and the spectrum is exactly MDLP's memory→weight **promotion** continuum.

---

## 4. The 2025–2026 frontier — self-modification & self-evolution

### 4.1 Code-level self-modification: the Darwin Gödel Machine  [E, self-reported metrics P]
**DGM** (arXiv 2505.22954; UBC / Vector / Sakana AI; accepted ICLR 2026) is "a self-referential, self-improving system that **writes and modifies its own code** to become a better coding agent," editing its own Turing-complete Python codebase — improving agent *design* (tools, workflows) **around FROZEN foundation models**, not retraining them. Unlike Schmidhuber's original Gödel Machine (which required *formal proofs* of beneficial self-rewrites — "impossible in practice"), DGM **accepts a self-edit on empirical benchmark evidence**. It uses **open-ended archive evolution**: a growing archive, parent selection ∝ performance and ∝ 1/(#children), archived agents as stepping stones — "substantially different from hill-climbing" (a hill-climbing ablation stalled at 23%). Reported: **20.0%→50.0% on SWE-bench** and **14.2%→30.7% on Polyglot** over 80 iterations. *(Authors' own numbers; not independently replicated — treat as claimed.)* **[E** design **/ P** numbers**]**

### 4.2 "Self-evolving AI agents" named as a paradigm  [E]
**arXiv 2508.07407** ("A Comprehensive Survey of Self-Evolving AI Agents," Aug 2025, 15 authors) names and surveys the paradigm, motivated by the problem that "most existing agent systems rely on manually crafted configurations that remain **static after deployment**." It abstracts the self-evolution loop into **four components: System Inputs, Agent System, Environment, Optimisers.** A parallel survey (**arXiv 2507.21046**, "A Survey of Self-Evolving Agents") corroborates the "frozen once deployed" framing. **[E]**

### 4.3 Continuous self-evolution via self-generated curriculum/data  [E existence / P mechanism details]
A class of systems now **generates its own tasks/data and fine-tunes without human labels** (named in 2509.02547):
- **Absolute Zero** (arXiv 2505.03335) — proposes its own tasks, solves them, **verifies via execution**, refines policy on outcome reward. **[E]**
- **Self-Evolving Curriculum** (arXiv 2505.14970) — frames **problem selection as a non-stationary bandit** to maximize learning gains over time. *(Closest in spirit to MDLP's learning-gain selection — but over training problems, not over learning-action *forms*.)* **[E]**
- **R-Zero** (arXiv 2508.05004, ICLR 2026) — a **Challenger–Solver RL self-play** co-evolution from zero human data. ⚠️ **Correction:** the agentic-RL survey mischaracterizes R-Zero as "MCTS actor-critic" — it is **not** MCTS; do not repeat that detail. **[E** that it self-evolves; survey's mechanism label is wrong**]**
- **ALAS** (arXiv 2508.15805) — crawls web data, distills training signals, continuously fine-tunes without manual curation. **[P]**

### 4.4 Verifier-grounded self-evolution (the nearest neighbor to MDLP)  [P — very recent]
**EigenData** (arXiv 2601.22607, Jan 30 2026) unifies **self-evolving synthetic-data generation with verifiable-reward RL** for tool-using agents: a hierarchical multi-agent engine synthesizes tool-grounded multi-turn dialogues *together with executable per-instance checkers*, then applies **GRPO-style RL** on the self-generated data. Its data-gen stage self-modifies its own prompts/workflow (a Reflect/Judge module) — context-level, not weight-level. **Crucially: verification here is *executable checking of generated instances*, NOT a held-out verifier gating which learning action to take next.** This is the closest verifier-grounded system found, and it still does *not* occupy MDLP's locus. **[P** — edge-of-window, self-reported on τ²-bench**]**

---

## 5. Continuous/online vs. one-shot/offline — keep the distinction honest

"Continuous/online" is used in **two distinct senses** that the literature routinely flattens — preserve them:

| Sense | What it means | Examples | True lifetime online? |
|---|---|---|---|
| **Within-session experience accumulation** | memory/skills grow during a run, weights frozen | Voyager, Generative Agents | Yes, but **context-level only** |
| **Cross-round iterative fine-tuning** | discrete rounds of self-generated-data → fine-tune | Absolute Zero, R-Zero, ALAS, DGM | **No — offline/iterative**, not lifetime-online |

**Finding:** genuine *lifetime online weight-level* learning is essentially absent. Weight-level self-evolution is overwhelmingly **offline, in discrete rounds**; continuous accumulation is **context-level**. Reflexion is *per-task iterative*, not lifetime. **[E]**

---

## 6. Where MDLP sits — the named-but-unfilled white space

The agentic-RL survey's own prospective section, **"Meta Evolution of Reflection Ability,"** states the reflection process "remains largely handcrafted and static" and names the **next frontier** as *meta-learning for adaptive reflection*: an agent learning **"a meta-policy that governs its own reflective strategies"** that could **"dynamically choose the most appropriate form of reflection for a given task — deciding whether a quick verbal check is sufficient or if a more costly, execution-guided search is necessary."** **[E]**

That is, almost verbatim, **MDLP's shared decision core**: one core that picks the **next learning action** (verbal reflection vs. skill acquisition vs. fine-tune) by **expected learning gain**, gated by a **held-out verifier**. The mapping:

| Dimension | Surveyed field | **MDLP** |
|---|---|---|
| Choosing the *form* of learning per task | named **open** ("handcrafted and static") | a learned, probabilistic **frontier policy** (`argmax E[Δcompetence]`) |
| Verification | outputs verified (DGM: benchmark; EigenData: per-instance checkers) | a **held-out verifier gates *action selection*** (not just outputs) |
| Curriculum-by-learning-gain | Self-Evolving Curriculum (over *problems*, bandit) | over **learning-action forms**, the same learning-gain principle generalized |
| Openness | DGM archive evolution (code) | open **competence graph** that grows from data |

**Bottom line:** MDLP's core idea is the field's *stated* open frontier, and **no surveyed system fills it** — its closest neighbors verify *outputs on training data* (DGM, EigenData) or select *training problems* (SEC), but none uses a **held-out verifier to choose among learning actions by expected gain.** The white space is real. **[E** that it's unoccupied; **P** that MDLP fills it well — MDLP is unbuilt/unproven.**]**

---

## 7. Candid gaps in MDLP vs. the field

Held up against the systems above, MDLP has real gaps — in three forms: it is *unproven*, it is *missing capabilities* the frontier has, and several of its *claims are softer than they look*.

**Validation — the dominant gap.** MDLP is unbuilt and unproven; every system here reports gains, MDLP reports none. The whole approach rests on **Milestone-0** (does held-out competence beat a no-learning baseline?), which has not run. The v0.2 hardening is **designed, not re-verified**, and several of its mechanisms (counterfactual credit assignment, trajectory-shape verification, pre-train interference prediction) are themselves open research problems. Until M0 runs, every gap below is secondary to this one.

**Capabilities the frontier has and MDLP lacks.**
- **No self-modification axis.** DGM rewrites its own scaffold/code *around frozen models* — high-leverage and cheaper than fine-tuning. MDLP has a memory axis and a weight axis but **no axis for the agent modifying its own decision/retrieval/loop design.** The field found large wins exactly where MDLP has no action type.
- **No task/curriculum generation.** Absolute Zero and R-Zero **generate their own problems from zero human data**; MDLP is *reactive* — it grows skills from observed failures and needs provisioned eval suites (the bootstrap gap) — and cannot propose novel challenges to train on.
- **No co-evolution.** R-Zero / EigenData use **multiple co-evolving agents** (a Challenger that manufactures the frontier); MDLP is single-learner and its growth rule is not adversarial.

**Claims softer than they look.**
- **The decision core overlaps Self-Evolving Curriculum (2505.14970)**, which already frames problem selection as a *non-stationary learning-gain bandit* — MDLP's frontier policy, minus verifier-gating and over *problems* rather than *learning-action forms*. MDLP's genuine novelty is the **action space** (choosing the *form* of learning) + the **held-out verifier** — not the learning-gain bandit itself. Position against SEC explicitly rather than claiming the idea wholesale.
- **π is hand-designed, not learned.** The survey's frontier is a *learned* meta-policy ("learning how to self-correct more effectively over time"). MDLP's π selects by a learning-gain *objective* but the controller itself is **meta-designed** (Thompson + hand-set λ/μ — the red-team's knife-edge). MDLP only **half-fills** the frontier it claims; to truly occupy it, π would need to adapt from experience.
- **Unoccupied ≠ valuable.** MDLP shows no one gates action-selection by a held-out verifier — not that doing so *helps*. The space may be empty because it is hard or low-value.
- **Continuous-online weight learning may be impractical.** The field does weight-level self-evolution in **discrete offline rounds** for non-stationarity/cost reasons MDLP also faces (cf. red-team RC-5/RC-6).

**Scoping limits — deliberate, but name them.** Verifier-gating bounds MDLP to domains with a cheap reliable check (the field's *universal* bottleneck) — inapplicable to most open-ended agent work. And MDLP's safety machinery is untested against the self-evolution pathologies the frontier now exhibits (reward hacking, archive collapse, objective drift).

**What would change MDLP's standing, in order:** (1) **run Milestone-0** — until then every other critique is moot; (2) decide whether to **add a self-modification axis + a task generator**, or consciously scope them out and say so; (3) **reconcile π with SEC and let the meta-policy *learn*** — otherwise the "we fill the learned-meta-policy frontier" claim is only half-true.

---

## 8. Calibration & caveats (read before quoting)

- **Self-reported benchmarks.** DGM (20→50% SWE-bench) and EigenData (τ²-bench gains) are **authors' own numbers, not independently reproduced.** Treat absolute figures as *claimed, not replicated*.
- **Inherited error — do not repeat:** the agentic-RL survey calls R-Zero "MCTS actor-critic"; R-Zero (2508.05004) is actually **Challenger–Solver RL self-play**. The self-evolution thesis still holds; the MCTS label is wrong.
- **Edge-of-window sources.** Jan–Mar 2026 arXiv items (EigenData 2601.22607; a 2603.x preprint) are pre/early-peer-review — flagged **[P]**.
- **MDLP's efficacy is unverified here.** This survey establishes the *positioning* (genuine white space), **not** that MDLP works. That still requires the Milestone-0 held-out evaluation.
- **Two senses of "continuous"** (§5) — don't flatten them.

---

## 9. Open questions (the smallest things that would change the conclusion)

1. Has *any* system implemented a **learned meta-policy that selects the form of learning action by expected gain** — or is MDLP's shared-decision-core design genuinely unoccupied as of mid-2026?
2. Do the headline self-improvement numbers (DGM, EigenData, Absolute Zero, R-Zero) **hold under independent reproduction**, and how do gains **decay/plateau** beyond the reported iterations?
3. Among self-evolving systems, does any use a **held-out verifier to gate next-action selection** (vs. verifying only outputs on self-generated/training data)?
4. Is there a principled **scaling/safety boundary** for code-level self-modification (reward hacking, archive collapse, objective drift) — and does verifier-grounding mitigate it relative to MDLP's expected-learning-gain framing?

---

## 10. Primary sources

**Surveys / framing:** 2509.02547 (Agentic RL, TMLR) · 2508.07407 (Self-Evolving AI Agents) · 2507.21046 (Survey of Self-Evolving Agents).
**Memory/context-level:** 2305.16291 (Voyager) · 2303.11366 (Reflexion) · UIST 2023 / DOI 10.1145/3586183.3606763 (Generative Agents) · github.com/stanfordnlp/dspy (DSPy).
**Self-modification / self-evolution:** 2505.22954 (Darwin Gödel Machine) · 2408.08435 (ADAS) · 2505.03335 (Absolute Zero) · 2505.14970 (Self-Evolving Curriculum) · 2508.05004 (R-Zero) · 2508.15805 (ALAS) · 2601.22607 (EigenData).
**Limits / verification:** 2504.13837 · 2507.11662 · openreview ikrQWGgxYg.

*Every finding above rests on a primary arXiv paper or official repo; 25/25 verified claims passed 3-0 adversarial verification (one passed 2-1, reflecting the R-Zero mechanism error, not doubt about existence).*
