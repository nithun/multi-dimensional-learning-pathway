# External-repo deep study: RAG-Anything · AgentScope 2.0 · OpenSpace → MDLP improvements

**Date:** 2026-07-13 · **Method:** three parallel source-code deep-reads of the cloned repos (file/line-cited) + a 102-agent web-research harness (20 sources fetched, 95 claims extracted, 25 adversarially verified 3-vote, 24 confirmed / 1 refuted). Source-code citations are to the repos as cloned 2026-07-12 (RAG-Anything v1.3.1, AgentScope v2.0.4, OpenSpace v0.1.0).

**Status:** study document — findings + *proposed* spec deltas. Nothing here modifies a gated artifact; each proposal that touches `ALGORITHM-v0.2` / `BUILD-SPECS` flows the L-010 gate (`review-360` → `change-approver`) before any edit.

---

## 0. TL;DR

| Repo | What it is | License | Learning loop? | Statistical rigor? | Chief value to MDLP |
|---|---|---|---|---|---|
| **HKUDS/RAG-Anything** (+ LightRAG under it) | Multimodal RAG: dual-graph KG indexing + hybrid vector-graph retrieval | MIT | **None** — static index-and-retrieve | None (benchmark self-reports) | §16/§10 build patterns: retrieval modes, fusion ranking, incremental graph merge, content-hash dedup |
| **agentscope-ai/agentscope 2.0** | Production agent runtime (ReAct, async, middleware memory, task DAG) | Apache-2.0 | Memory write-back only; RL is roadmap | None | `mdlp` library engineering: packaging, state model, storage ABC vs message bus, judge-as-schema |
| **HKUDS/OpenSpace** | **Self-evolving skill layer for LLM agents** (MCP server, `SKILL.md` skills, experience counters, gated skill evolution, lineage DAG, cloud sharing) | MIT | **Yes — the whole point** | **No** — point-rate counters, hardcoded thresholds, LLM-judge patch | The closest living relative: validates MDLP's thesis, supplies working mechanisms to formalize, and is the natural baseline to beat |

**The strategic headline:** across all three (plus LightRAG), **nobody has probabilistic competence state, statistical gates, or calibrated self-modification**. OpenSpace *wants* exactly what MDLP formalizes — its authors ship point-estimate success rates with admittedly "relaxed" hardcoded thresholds and paper over the noise with an LLM confirmation call. MDLP's dual-Beta + `significant()` + §19 self-calibrating gate is a strict, publishable upgrade over the best open implementation in this space. The niche is real and currently empty.

---

## 1. RAG-Anything (HKUDS) — findings

A thin multimodal orchestration layer on **LightRAG** (`lightrag-hku<1.5` dep); parsing (MinerU/Docling), per-modality VLM captioning, and a multimodal-aware insert/query path. All KG machinery is LightRAG's (`extract_entities`, `merge_nodes_and_edges` imported from `lightrag.operate`).

- **Dual-graph indexing** (paper arXiv:2510.12323): a cross-modal KG from VLM descriptions of images/tables/equations + a text KG from entity/relation extraction, fused by entity-name alignment into one index `I=(G,T)` (graph + embedding table). *[verified 3-0, paper + code]*
- **`belongs_to` hierarchy edges:** every entity extracted *inside* a figure/table gets an edge to the modal-entity node, keywords `belongs_to,part_of,contained_in`, **hardcoded weight 10.0** (`modalprocessors.py:766-799`, `processor.py:1397-1451`) to bias traversal. Structure is right; the constant weight is the naive part.
- **Retrieval:** LightRAG modes `local / global / hybrid / naive / mix(default) / bypass` passed as one `QueryParam` (`query.py:110`); **multi-signal fusion ranking** = structural importance (graph topology) + semantic similarity + query-inferred modality preference. *[verified 3-0]*
- **Two-stage VLM query path:** fetch retrieval context *without answering* (`only_need_prompt=True`, `query.py:391`), transform (inject images, security-gate paths), then generate — a retrieve → gate → answer sandwich.
- **Idempotency:** content-hash doc IDs (`processor.py:202-237`) + mdhash `chunk-/ent-/rel-` IDs → re-ingesting identical content dedupes and merges instead of double-counting.
- **Incremental graph updates** (LightRAG): new data indexed to a local graph then **set-merged** (`V∪V'`, `E∪E'` with entity/relation dedup) — no full re-index. *[verified 3-0]*
- **No learning loop, confirmed:** no feedback, no usage counters, no weight adaptation, no decay. Eval = author-reported DocBench 63.4% / MMLongBench 42.8%, no SE, no held-out gating.
- Maturity: MIT, PyPI, CI (3.10–3.12 matrix), ~24 unit-test files.

## 2. AgentScope 2.0 (Alibaba Tongyi Lab) — findings

Full 2.0 rewrite (the 1.x `pipeline`/`msghub`/`evaluate` subsystems are gone or roadmap). One unified async `Agent` class (`agent/_agent.py:92`) with a streaming event bus, HITL interrupts, and context compression before every reasoning step.

- **State:** everything persistable is one Pydantic `AgentState` (`state/_state.py:143`) → free serialize/validate; the service layer splits a **hot-path `update_session_state`** from full `upsert_session` (`app/storage/_base.py:235,176`).
- **Memory = middleware family:** `AgenticMemoryMiddleware` (frontmatter-tagged Markdown memories, bounded index, cheap frontmatter scan → structured-LLM selection ≤5 → **hallucination-filter against the real file set**, `_middleware.py:558-620`); `Mem0Middleware`; `ReMeMiddleware` (auto write-back per reply). Dual control modes (framework-invoked vs agent-invoked-as-tools). *[verified 3-0]*
- **Multi-agent:** storage ABC (keyed `user/agent/session`) kept strictly separate from the live **MessageBus** (drain-queue inbox / replay-log / transient pub-sub; in-memory + Redis). Leader/worker "Agent Team" tools; sequential and fanout pipelines. *[verified 3-0]*
- **Tasks:** persisted `Task` DAG with `blocks` / `blocked_by` edges (`state/_task.py:11`) — a dependency graph in state, not recomputed.
- **Tooling:** declarative `Toolkit` with groups; `is_concurrency_safe` drives sequential-vs-parallel batching; `ResetTools` meta-tool = agent self-scopes its active tool groups by declaring the desired final state through one audited path.
- **Judging:** only `generate_structured_output(schema)` — verdicts as validated objects, no statistics. **No eval toolkit, no RL, no experience replay in-tree** (roadmap: Tinker backend, "tune on run history"). *[confirmed in code + roadmap.md:67-111]*
- Maturity: Apache-2.0, Beta, 103 test files, 9 CI workflows, exemplary optional-extras packaging (nested extras, e.g. `models = ["agentscope[ollama]", …]`).

## 3. OpenSpace (HKUDS) — findings ★ the important one

**Identity (established from source; web footprint too thin for the verification harness):** a **self-evolving skill layer for LLM agents**, shipped as an MCP server (`execute_task / search_skills / fix_skill / upload_skill`) that plugs into Claude Code / Codex / Cursor via the `SKILL.md` format. Tagline "Make Your Agents: Smarter, Low-Cost, Self-Evolving" (`README.md:7`). Same HKU lab as LightRAG; builds on their AnyTool + ClawWork. v0.1.0, MIT, actively developed (last commit 2026-06-03), **zero automated tests**.

Mechanisms, mapped to their MDLP counterparts:

| OpenSpace mechanism (file:line) | MDLP counterpart | Verdict |
|---|---|---|
| Four experience counters per skill: `selections/applied/completions/fallbacks` → `applied_rate`, `completion_rate`, `effective_rate`, `fallback_rate` (`types.py:366-398`) | §3 dual-Beta competence | **Degenerate point-estimate version of MDLP's state — no variance, no `significant()`** |
| Evolution triggers: hardcoded thresholds (fallback>0.4, completion<0.35…, `evolver.py:106-110`) + **LLM confirmation gate** (`_llm_confirm_evolution`, `evolver.py:588`) | §2 gate primitive, §8 four-clause gate | Their two-stage "cheap wide screen → expensive judge" shape is right; the screen is unprincipled. MDLP's z·SE replaces both the magic numbers *and* most LLM-judge cost |
| Skill evolution modes **FIX / DERIVED / CAPTURED** (`types.py:26-29`), multi-parent DERIVED composition | §17 `self_modify`, GROW | A ready operator vocabulary for scaffold/skill mutation |
| **Lineage DAG**: per-version full content snapshot + unified diff, `.skill_id` sidecar identity, deactivate-parent / `reactivate_record` rollback (`types.py:69-127`, `store.py:519`) | §17.2 scaffold-version log | A concrete, working schema for exactly what §17 specifies abstractly |
| Tool-degradation **cascade**: failing tool → batch-evolve all dependent skills; `critical_tools` vs soft deps (`evolver.py: process_tool_degradation`) | §15 downstream-failure trigger, B2 | Structural twin of prerequisite-gap diagnosis; corroborates the design |
| Anti-thrash via **data freshness**: evolved skill resets to `selections=0`, needs ≥5 fresh points before re-eval (`evolver.py:450-460`) | `n_min` floor, §15.3 stops | Corroborates evidence-count (not wall-clock) cooldowns |
| Rolling last-100 window, penalty∈[0.2,1.0], **<3-calls cold-start free pass** (`quality/types.py:89-140`) | B4 recency/decay, A5 warm-start | Their recency hack ↔ MDLP's drift posterior; cold-start allowance ↔ warm-start prior |
| **Quality-weighted retrieval**: BM25+embedding hybrid rank, then the LLM selector sees per-skill quality metrics (`skill_ranker.py:107`, `tool_layer.py:712-735`) | §16 reranker | Retrieve by relevance × demonstrated reliability — a candidate feature for §16.5's learned reranker |
| Post-execution **LLM analyzer** labels each trajectory → per-skill judgments (`analyzer.py`; edit-distance fix for hallucinated skill IDs) | verifier → Beta update credit assignment | The credit-assignment step MDLP's agent-side adapters need; theirs is unverified LLM opinion, MDLP's is held-out outcome |
| **GDPVal two-phase benchmark**: Phase-1 cold (skills accumulate) → Phase-2 warm rerun, fixed backbone LLM, ClawWork LLM-evaluator with a 0.6 "payment cliff"; reported 4.2× income, 45.9% tokens (`gdpval_bench/`) | M0/M1 frozen-baseline gate | The cold→warm protocol on a **real occupational task set** is directly adoptable for M1's representative corpus |
| Cloud skill community: upload/download evolved skills with lineage | B3 transfer | **Weaker than MDLP**: no zero-trust re-validation on the receiver — a poisoned-skill vector B3 already closes |

**Why this matters:** OpenSpace is an existence proof (demand + a working end-to-end loop), a mechanism donor (lineage schema, operator vocabulary, cascade trigger, benchmark protocol), and the obvious **baseline for the paper** — "MDLP replaces OpenSpace's hardcoded thresholds and LLM-judged evolution with calibrated posteriors and statistical gates; here is the held-out delta."

---

## 4. What none of them have (MDLP's moat, confirmed)

1. **Probabilistic competence state** — best-in-class is OpenSpace's point rates; no posteriors, no variance, anywhere.
2. **Statistical gating** — no z·SE, no held-out-vs-frozen-baseline anywhere; evals are benchmark self-reports or LLM judges.
3. **Measurement independence (P1)** — no repo separates the optimization signal from the measurement set.
4. **Calibration (§14) / self-calibrating thresholds (§19)** — absent everywhere; OpenSpace's thresholds are static magic numbers.
5. **Curriculum** — nobody chooses *what to learn next*; OpenSpace evolves what breaks, it never plans learning progress.

---

## 5. Prioritized improvement proposals (spec-level)

Each proposal names its target artifact and lands only through the L-010 gate. Ordered by (evidence strength × MDLP-milestone relevance ÷ blast radius).

### P1 — §16 build-spec concreteness: retrieval-mode taxonomy + fusion features *(target: new BUILD-SPECS item for §16; closes part of the "§16 hermetic-only" gap)*
Adopt as the §16 companion build-spec's API surface: (a) a **mode enum** in the LightRAG shape — `skill-local / curriculum-global / hybrid / episode-naive / mix` — as the typed dispatch over the 5 stores (§16.4), one entry point + `mode` + params, exactly the `QueryParam` idiom; (b) the **multi-signal fusion feature set** for the §16.5 learned reranker: structural importance (graph topology), semantic similarity, state-conditioned preference (against `C`), *and* — from OpenSpace — **demonstrated source reliability** (each source's counterfactual lift history is itself a feature). Verified 3-0 that this fusion design is what ships in the closest published analogue. *Effort: small spec; high leverage for the eventual live §16.*

### P2 — Graph-store write discipline: incremental set-merge + content-hash dedup *(target: DATA-LAYER.md §5/§6 + GraphStore/VectorStore ports)*
Specify (a) **extract → transactional merge** as two decoupled stages (RAG-Anything's 7-stage pipeline; `merge_nodes_and_edges` separate from extraction) with set-merge semantics `V∪V'`, `E∪E'` + dedup — never full re-index in continual operation; (b) **content-hash IDs** for skills/lessons/evidence so re-ingested identical evidence merges instead of double-counting — this is not cosmetic: **duplicate evidence biases Beta posteriors**, so idempotent upsert is a correctness requirement for §3, not a storage nicety. *Effort: small; prevents a real inference bug.*

### P3 — §17 scaffold-version log: adopt the OpenSpace lineage schema *(target: §17.2 detail / future M3 build-spec)*
Concretize the abstract "immutable append-only scaffold-version log" as: version DAG with multi-parent edges, per-version **full content snapshot + unified diff**, portable sidecar identity, deactivate-parent on promote and `reactivate` as the §17.3 Stage-2 rollback primitive. Also adopt **FIX / DERIVED / CAPTURED** as the named `self_modify` operator vocabulary (refine-in-place / specialize-compose / capture-novel-success) — DERIVED's multi-parent composition is the skill-graph analog of learning composite skills. *Effort: medium; M3-horizon but cheap to spec now while the reference is fresh.*

### P4 — M1 evaluation: cold→warm two-phase protocol on a real task corpus *(target: HANDOVER-v2 / M1 plan; no algorithm change)*
Adopt the GDPVal design for the representative coding+pytest corpus M0 flagged as "still ahead": Phase-1 cold run (learning on), Phase-2 warm rerun of the *same held-out tasks* with the accumulated skill library, **fixed backbone model**, frozen no-learning baseline — reporting both the competence delta (MDLP's gate) and the **token-cost delta** (OpenSpace's 45.9% result shows cost is a headline metric reviewers respond to). Difficulty-stratified reporting (pass-rate per difficulty bucket — RAG-Anything's length-stratified tables) falls out of MDLP's `skill×difficulty` cells for free and shows *where* gains concentrate. *Effort: protocol-only; strengthens the paper.*

### P5 — `mdlp` library engineering patterns *(target: IMPLEMENTATION-v2 / RELEASE-PLAN-v2; informs the user's turing-agents build — crosses only via the user, L-012)*
From AgentScope, four adoptions: (a) **nested optional-extras** packaging (`mdlp[stores]` ⊂ `mdlp[full]`) — already planned, their `pyproject` is the reference implementation; (b) **one serializable root state model** with a hot-path "posteriors-only" write vs full snapshot (maps to StateStore vs TruthStore cadences); (c) for §18: keep the durable skill-store ABC and the **live coordination bus as separate interfaces** (their storage/message-bus split) — matches §18.2's cached fleet-projection design; (d) **judge-verdicts as schema-validated objects** (`passed, evidence, effect_size, confidence`) composing with — never replacing — the statistical gate. Plus AgentScope's memory-selection guard for §16: **validate retrieved IDs against the actual store** before use (their hallucination filter). *Effort: documentation deltas.*

### P6 — B2 edge semantics: typed hierarchy edges with inferred (not constant) weights *(target: B2 build-spec, minor)*
Add a `part_of`/`belongs_to` **typed hierarchy edge** alongside `prereq` for skill decomposition (composite skill ⊂ constituent skills), and record explicitly that traversal bias comes from the **dual-Beta-derived edge confidence**, never a constant — RAG-Anything's hardcoded 10.0 is the cautionary tale; OpenSpace's `critical_tools` vs soft deps corroborates B2's hard-vs-soft prerequisite distinction. *Effort: tiny.*

### P7 — Positioning: OpenSpace into the landscape + paper *(target: LANDSCAPE-self-learning-agents.md, PAPER.md related work; ungated docs)*
Add OpenSpace as the closest-relative row (self-evolving skill layer; point-estimate counters; LLM-gated evolution; no statistics; no tests) and frame MDLP's contribution against it: *the statistical brain the existing skill-evolution layer is missing*. Its MCP/`SKILL.md` surface is also a plausible future **integration target** for the `mdlp` library (an `mdlp`-scored OpenSpace-style skill store) — noted as 🔭 aspirational, not queued.

**Explicitly rejected after study:** adopting LightRAG/RAG-Anything as a dependency for §16 (its stores lack MDLP's lineage/versioned-state requirements and it brings a heavy LLM-extraction pipeline MDLP doesn't need); OpenSpace's LLM-confirmation gate as a *replacement* for statistical screens (it's their patch for missing statistics); cloud skill sharing without B3 zero-trust re-validation (a poisoning vector MDLP already closes).

---

## 6. Licenses
RAG-Anything **MIT** · LightRAG **MIT** · AgentScope **Apache-2.0** · OpenSpace **MIT** (all confirmed from LICENSE files in-tree). Pattern-borrowing is unrestricted; any future code vendoring needs only attribution.

## 7. Sources
- Cloned source (2026-07-12): `HKUDS/RAG-Anything` v1.3.1, `agentscope-ai/agentscope` v2.0.4, `HKUDS/OpenSpace` v0.1.0 — file:line citations inline above.
- Papers: arXiv:2510.12323 (RAG-Anything), arXiv:2410.05779 (LightRAG, EMNLP 2025), arXiv:2508.16279 (AgentScope 1.0).
- Docs: doc.agentscope.io (memory, pipelines), github.com/hkuds/lightrag README, OpenSpace `gdpval_bench/README.md`.
- Verification: 25 claims 3-vote adversarially verified (24 confirmed, 1 refuted — an AgentScope 1.x memory-backend claim that doesn't hold on the 2.0 tree); AgentScope 1.x-vs-2.0 API churn flagged throughout (this study cites the 2.0 tree).
