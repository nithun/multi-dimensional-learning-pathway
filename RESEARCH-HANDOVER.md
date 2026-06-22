# Research Handover — A Generic Self-Learning Layer for Managed Agents

**For:** Claude Code (autonomous research mode)
**Mode:** Pure research brief — produce a report, **do not build**
**Owner:** nithun@turing.ae
**Date:** 2026-06-22
**Status:** Ready to execute

---

## 0. One-paragraph mission

Investigate the feasibility, prior art, and reference design for a **generic, Python-first "self-learning agents" layer** that sits **on top of an existing managed-agents control plane (Multica)** and makes the agents it manages measurably better over time along **two independent axes**:

1. **Memory/context-level learning** — the agent accumulates skills, lessons, and memory; **weights never change**. Cheap, fast, reversible, debuggable.
2. **Weight-level learning** — fine-tuning / RL actually updates parameters. Durable and more powerful, but expensive, slow, and the student is non-stationary.

The intellectual core is the attached concept paper's **probabilistic multi-dimensional learning-pathway engine** — reframed so the "learner" is an **agent** rather than a human student. Deliver a research report with a clear **go / no-go**, a recommended reference architecture, a **layer-vs-replace** recommendation for Multica, and an annotated bibliography. **No implementation in this engagement.**

---

## 1. Background & context (read these first)

| Artifact | What it is | Where | Why it matters |
|---|---|---|---|
| Concept paper | "A Multi-Dimensional Learning Pathway Inference and Evolution Framework…" | `uploads/` (attached PDF) | The probabilistic state + transition-graph + decision-engine algorithm to generalize from students → agents |
| Turing Agents v0.2.0 | Self-evolving, team-organized agent framework (this repo) | workspace root / `nithun/turing-agents` @ `v0.2.0` | **Already a working memory-level learner** — its `reflect → evolve` loop *is* the paper's "pathway evolution loop" |
| Multica | Open-source managed-agents **control plane** (Go + Next.js monorepo: board, squads, autopilots, reusable skills, unified runtimes, multi-workspace) | `github.com/multica-ai/multica` | The orchestration substrate to layer onto. It *manages* agents but has **no learning loop** — that gap is the opportunity |

### The thesis to test

> A generic learning layer can wrap a managed-agents platform (starting with Multica) and improve the agents it runs along both the memory and weight axes, using the paper's probabilistic-pathway engine as a single shared **decision core** — the same algorithm that picks a human learner's next activity picks an agent's next skill, lesson, curriculum task, or fine-tune step.

### The core conceptual mapping (validate or refute it)

The paper's machinery, with the education vocabulary stripped out, is: *probabilistic learner-state model + transition graph + decision engine choosing `A* = argmax P(success | S, A)`, with transition probabilities updated online.* That is structurally a **teacher–student / automated-curriculum-learning** system. The reframe:

| Paper (human student) | Agent equivalent |
|---|---|
| skill / mastery | agent competence per task-type (directly measurable via evals) |
| contextual difficulty | task difficulty the controller selects |
| temporal progression | training / experience steps |
| engagement | mostly N/A; possibly repurpose as an exploration term |
| `A* = argmax P(success \| S, A)` | a contextual-bandit / RL controller choosing the next learning action |
| pathway evolution loop | the controller updating its model as the agent improves |
| hybrid multi-store (SQL/Mongo/Vector/Graph/Redis) | same stores, but state = agent capability + skill library + trajectory memory |

---

## 2. Research questions (the heart of the brief)

Answer each with evidence, citations, and an explicit confidence level. Flag where the literature is thin or contested.

### A. Conceptual mapping & state model
- A1. Does the paper's probabilistic-pathway framework generalize cleanly from human learners to agents? Where does the analogy break (e.g., engagement, hidden vs. observable state, checkpoint/rewind)?
- A2. What are the right **state dimensions** for an *agent* learner, and how should each be estimated? (Candidate: per-skill mastery via **Item Response Theory / Bayesian Knowledge Tracing** over eval items.)
- A3. Is a single probabilistic "decision core" genuinely reusable across *both* learning axes, or do memory-level and weight-level need different controllers?

### B. Memory/context-level learning (weights frozen)
- B1. Survey the state of the art: skill libraries, lesson/memory accumulation, reflection, and **prompt/program optimization** as learning. (Anchor on: Voyager skill library, Reflexion, Generative-Agents memory, MemGPT/Letta, DSPy, TextGrad, and Turing Agents' own reflect→evolve loop.)
- B2. How does Turing Agents' approach compare to these? What is genuinely novel vs. reinventable?
- B3. Specify the **reusable memory-level algorithm**: how skills/lessons are proposed, validated, retrieved, scored, retired, and harvested — mapped onto the paper's validation + inference + decision + evolution engines.

### C. Weight-level learning — fine-tuning a small LLM as an agent
- C1. Confirm feasibility and current best practice for **fine-tuning small (≈1–8B) LLMs into agents** (tool/function calling, ReAct loops, format adherence). Anchor on: **FireAct, AgentTuning / AgentLM, Lumos, ToolLLM, Gorilla, Toolformer, Salesforce xLAM / APIGen**. Verify exact, current results before citing.
- C2. **Data generation:** what produces good agentic trajectory data? Assess distillation-from-a-strong-model + **rejection sampling** (keep only successful trajectories), synthetic task generation, and human traces. What volume/quality threshold matters?
- C3. **Methods & cost:** SFT vs. preference/RL (DPO, GRPO); LoRA/QLoRA vs. full fine-tune; tooling (TRL, Unsloth, Axolotl, PEFT, vLLM for rollout). Give realistic compute/cost envelopes for a single-GPU and a small-cluster scenario.
- C4. The **"small teacher for bigger student"** sub-case: when does a small model usefully supervise a larger one? Establish the boundary — pedagogical/verification/routing signal works; backward knowledge distillation does not.

### D. Unifying the two axes
- D1. When should the system **promote** a memory-level skill to a weight-level fine-tune (and when not)? Define the trigger/economics.
- D2. Can both axes share one reward/eval signal (`P(success | S, A)`)? What does a unified **eval-in-the-loop** harness look like?
- D3. How is **non-stationarity** handled — the student changing under the controller (fast for weights, slow for memory)?

### E. Integration with Multica (layer vs. replace)
- E1. Map Multica's extension surface: agent lifecycle hooks, board/issue events, autopilots, skills, runtimes, WebSocket event stream, CLI/daemon. Where can a learning layer attach **without forking** the Go/TS core?
- E2. Evaluate **three integration postures** and recommend one: (a) **layer/plugin on top of Multica** (chosen starting hypothesis); (b) **full replacement** with a Python-native control plane (the user's original framing); (c) **hybrid** — Multica for orchestration, new Python service for learning.
- E3. The user selected "layer on top of Multica" but originally said "replace Multica." Resolve this explicitly: does layering suffice, or does the learning loop demand control Multica can't cede? Give the decision and the tradeoffs.

### F. Python-first build feasibility (assess, don't build)
- F1. Propose the **library shape** for the reusable core: e.g. `ProbabilisticState` (IRT/BKT), `PathwayGraph` (networkx), `DecisionEngine` (contextual bandit / Thompson sampling), `EvolutionLoop` (online updates), and pluggable `LearnerAdapter`s (`HumanLearnerAdapter`, `AgentLearnerAdapter`).
- F2. Identify the data/infra stack (the paper's SQL/Mongo/Vector/Graph/Redis), the ML stack (HF Transformers, PEFT, TRL, vLLM), and the serving/eval stack.
- F3. Surface dependency, licensing, and maintenance risks for an open-source release.

### G. Positioning & competition
- G1. Who else is building "agents that learn" platforms or self-improving-agent frameworks? Differentiate.
- G2. What is the defensible, novel contribution here vs. existing curriculum-learning / agent-tuning work?

### H. Risks & open problems
- H1. The **reward-signal bottleneck** (no cheap reliable verifier → garbage loop). Is it tractable for the target domains?
- H2. Safety/guardrails for self-modifying and self-fine-tuning agents (reversibility, circuit-breakers, eval gates).
- H3. Cost, reproducibility, and evaluation rigor.

---

## 3. Prior art to survey (starting set — expand as needed)

Group, read, and verify currency for each. Do **not** assert results from memory; confirm against primary sources.

- **Curriculum / teacher–student:** automatic curriculum learning, teacher–student curriculum learning, PAIRED, POET / unsupervised environment design.
- **Agent fine-tuning (small models):** FireAct, AgentTuning / AgentLM, Lumos, ToolLLM / ToolBench, Gorilla, Toolformer, xLAM / APIGen, NexusRaven, Hermes function-calling.
- **Reward / self-improvement:** RLAIF, self-rewarding language models, process reward models, Constitutional AI, rejection-sampling fine-tuning (e.g. STaR-style self-taught reasoning).
- **Memory-level learning:** Voyager (skill library), Reflexion, Generative Agents (memory stream), MemGPT / Letta, DSPy, TextGrad, automatic prompt optimization.
- **Tuning methods & infra:** LoRA / QLoRA / PEFT, DPO, GRPO, TRL, Unsloth, Axolotl, vLLM.
- **Managed-agents platforms (for positioning):** Multica, plus any open-source peers (compare control-plane features and any learning capability).

---

## 4. Feasibility dimensions — score each axis

Fill this rubric (qualitative + evidence) for **memory-level** and **weight-level**, then synthesize:

| Dimension | Memory-level | Weight-level |
|---|---|---|
| Reward / eval signal needed | | |
| Cost per improvement cycle | | |
| Speed (latency to improvement) | | |
| Durability of gains | | |
| Reversibility / safety | | |
| Data requirements | | |
| Non-stationarity exposure | | |
| Observability / debuggability | | |
| Maturity of OSS tooling | | |

Then: a **layer-vs-replace decision matrix** for Multica (integration effort, control needed, blast radius, time-to-first-value, long-term ceiling).

---

## 5. Required deliverable (what to hand back)

A single research report — `docs/research/REPORT-self-learning-agents.md` — containing:

1. **Executive summary** with a one-line **go / no-go** and the headline recommendation.
2. **Conceptual analysis** — does the pathway framework generalize to agents? (answers §2.A).
3. **Memory-level findings** (§2.B) and **weight-level findings** (§2.C), each with the §4 rubric filled in.
4. **Unification model** (§2.D) — the shared decision core + eval-in-the-loop design, or a reasoned rejection of unification.
5. **Multica integration analysis** (§2.E) — extension-point map + the **layer / replace / hybrid** recommendation with rationale.
6. **Recommended reference architecture** — a diagram (Mermaid) + the Python library shape (§2.F). *Design, not code.*
7. **Risk register** (§2.H) with severity, likelihood, and mitigations.
8. **Competitive positioning** (§2.G).
9. **Annotated bibliography** — every source with a one-line takeaway and a confidence flag.
10. **Open questions & recommended next experiments** — the smallest experiments that would de-risk a build decision.

Keep claims **calibrated**: separate "established," "plausible," and "speculative." Where evidence is missing, say so.

---

## 6. Method (suggested workflow for Claude Code)

1. Read the three artifacts in §1 (PDF, this repo's `CLAUDE.md` + `.claude/`, the Multica repo already cloned to a temp path or re-clone `github.com/multica-ai/multica`).
2. Fan-out web/literature search across the §3 groups; fetch primary sources; **adversarially verify** every quantitative claim before using it.
3. Fill the §4 rubrics from evidence.
4. Map Multica's extension surface from its source (`server/`, autopilots, skills, CLI/daemon, WS events).
5. Synthesize the report per §5; draw the architecture diagram; write the go/no-go.
6. Self-review for calibration and unsupported claims before finalizing. Consider a verification pass via a subagent for the quantitative prior-art claims.

The repo's `deep-research` skill is a good harness for steps 1–3 and 6.

---

## 7. Ground rules / constraints

- **Research only — do not implement, scaffold, or fine-tune anything.** The output is a report.
- **Python-first** for all proposed designs (ML ecosystem is Python-native).
- **Vendor-neutral and open-source-minded** (Multica is MIT; assume the new work is too — verify license compatibility).
- **Cite everything**; prefer primary sources; flag uncertainty honestly.
- Treat the user's original "replace Multica" and the selected "layer on top of Multica" as a genuine open question to resolve, not a settled fact.
- The framework **never edits the user's source code** during research; it only writes the report and supporting docs.

---

## 8. Acceptance criteria

- [ ] Every §2 research question answered with evidence + confidence.
- [ ] Both §4 rubrics filled for both axes.
- [ ] A defended **layer / replace / hybrid** recommendation for Multica.
- [ ] A clear **go / no-go** with the reasoning.
- [ ] A reference-architecture diagram + Python library shape (design only).
- [ ] Annotated bibliography with calibrated confidence flags.
- [ ] No code written; no claims asserted from memory without source verification.

---

## Appendix — key links

- Concept paper: attached PDF (`A_Multi-Dimensional_Learning_Pathway…pdf`)
- Turing Agents: `https://github.com/nithun/turing-agents` (this project, @ `v0.2.0`)
- Multica: `https://github.com/multica-ai/multica`
- Decision-core target equation (from the paper): `A* = argmax_A P(success | S, A)`
