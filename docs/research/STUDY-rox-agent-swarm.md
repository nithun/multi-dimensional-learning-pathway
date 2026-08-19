# Rox study — a production agent swarm, and what its docs admit

**Date:** 2026-08-19 · **Subject:** `docs.rox.com/development` — Rox ("Revenue Operating System", Sequoia-backed, $50M raised): the Agent Swarm™ Layer, System of Context, evaluation + reliability engineering docs, governance engine, custom-agent product docs, and three engineering blogs. ~26 pages read via the site's own `llms.txt` index; three parallel deep-read extractions (session record IX-071). One page (`cost-management-with-insight-filtering`) is a confirmed 363-byte stub; noted where relevant.
**Status:** study document — **ungated**. Anything touching gated artifacts flows L-010; TA-side items cross via the user (L-012).
**Source class (L-015):** vendor engineering documentation of a closed-source production system. One notch below the source-verified class (OpenSpace/automaton/hermes were read at file:line): mechanisms here are **[P** vendor-described**]**, not **[E** source-verified**]** — *except* admissions against interest (a vendor conceding what its system lacks), which are the strongest evidence a vendor doc can carry. This study leans on those admissions and treats capability claims ("immune to prompt injection", "millisecond failover") as marketing until proven.
**Why it matters:** Rox is the first *commercial, funded, multi-tenant* agent swarm studied — the previous production systems were open-source frameworks. If the "nobody measures learning" pattern held only for OSS, a funded vendor with paying customers is where it would break. It doesn't break. It gets self-documented.

---

## 1. The headline — the fourth confirmation, and the first self-admission

The landscape claim (`LANDSCAPE-self-learning-agents.md`) stood at three-for-three from source: **no shipped self-improving agent measures whether its learning worked.** Rox makes it four — and upgrades the evidence class, because Rox says it *itself*, in its own evaluation-system doc:

> current "LLM systems are stagnant — they're built once"

with end-user feedback capture, judge-aligned auto-eval, and "dynamic adjustments that keep agents evolving alongside user needs" all explicitly filed as **future direction, not shipped**. The human-agent-interaction page independently lists "proactivity, adaptability, and **memory**" as future areas. The custom-agent product docs confirm it from the user's side: the improve-the-agent loop is **manual and pre-deployment-weighted** (test runs → breakpoint inspection → an "Active" toggle → per-item approve/reject), the tuning panel is **configuration, not learning** (signal-type checkboxes, notification frequency), and approve/reject **gates distribution — it trains nothing**. Their documented quality bar is subjective: whether the agent "earned your trust."

OpenSpace had counters without statistics; automaton had a constitution without benefit evidence; hermes told its own curator not to trust its own counters. Rox — with paying enterprise customers and a real eval team — writes the stagnation down as a known limitation. **A vendor admission against interest is stronger than an inferred absence.** MDLP's unoccupied ground (dual-Beta posteriors, significance gates, held-out verification of learning itself) stays unoccupied at the commercial tier too.

One near-exception, worth tracking: Rox runs **"offline evaluation agents"** doing "deep research runs that crawl outcome data, comparing what our agents recommended against what actually happened," with a stated long-term goal of tuning from **delayed, noisy business-outcome signals**. That is the closest thing in any studied system to measuring learning-relevant outcomes — but it is a *retrospective audit of recommendations*, not a loop that updates anything, and they say the tuning is a goal, not a mechanism. See §5.2.

## 2. What Rox actually is (the facts that matter)

Three layers: **System of Context → Agent Swarm Layer → Application Layer.**

**System of Context** — a warehouse-native knowledge graph. Fivetran/webhook ingestion into a lakehouse; a Spark pipeline does entity resolution (exact-ID lookup tables → fuzzy domain/email matching with TF-IDF weighting → source-priority conflict resolution, "Salesforce > Zendesk > Product Usage"); five entity types keyed by a `rox_id`, relationships in an `entity_link` table, a `graph` mapping table preserving source-system lineage. The graph is **rebuilt full-state every 30 minutes** (outer-join merge that drops vanished entities) rather than trusted to incremental mutation; serving is a Snowflake→PostgreSQL replication with acknowledged consistency windows at both hops. Opportunities are **deliberately not resolved** (their source of record is already controlled).

**Agent Swarm** — worker agents (focused prompt + curated tools), an orchestrator that assembles pipelines from the query, a pipeline engine managing flow, retries, and guardrails. Three tool classes: Data Tools, **Verifier Tools** ("validate temporary data before allowing agents to continue reasoning"), Instruction Fetching Tools. DAGs supported but **"simple linear pipelines perform best in practice."** Retrieval: an `AgentDataInterface` takes a natural-language information need + metadata filters; an **LLM-based parallel reranker scores every candidate** and returns a top-k "sized to the agent's remaining context budget." Notable retreat, from their agents blog: they **abandoned specialized sub-agents and a query-decomposing routing layer** because "frontier models handle [planning and context management] well" — engineering effort moved to the data and action layers.

**Evaluation** — the most substantive engineering: strict service-layer interface contracts isolate the "agent brain" so the whole stack runs in a **sandbox against mocked production-like services** (~200-query suite); grading is deterministic heuristics where ground truth exists + LLM-as-judge on developer-defined rubrics elsewhere; evals check **exact tool calls and pipeline shapes**, not just final text; every module declares an `offline_evaluator` and an `online_evaluator`; module I/O is **auto-logged and versioned** so changes replay against historical production data; pairwise comparison automates current-vs-legacy judgment; "production issues become new test cases." Ground truth comes from an internal developer labeling interface.

**Reliability** — model-level failover (pre-qualified primary→backup model mappings), and a classic SQS/ECS task system: idempotent executors, explicit ack, visibility-timeout redelivery, exponential backoff, DLQs, **fair queuing per message group so one tenant's surge can't starve others**, CPU-vs-I/O worker pools, 64+ task types. The same task framework runs the graph's sync jobs — data freshness inherits task-system reliability. No task-level checkpoints documented.

**Governance** — agents are **first-class security entities**: the "Pod" primitive groups "users, service accounts, or agents," and agent access resolves through the same formula as humans (`UNION(ownership, external_access, pod_access, sharing_rules, hierarchies) INTERSECT object_permissions`). "LLMs never get raw access — everything is mediated at the platform layer. Authentication and authorization always sit with the user, not the model." Every access decision emits a provenance trace; **attribution tokens** trace synthesized output back to sources. HITL: "all critical actions queued for human review and execution."

**Cost shape** — the insight pipeline is a funnel: high-volume ingestion → cheap vector prefilter (Turbopuffer cosine similarity against user-preference embeddings, dual exclusive/non-exclusive thresholds) → expensive GenAI scoring only on survivors. The dedicated cost post is unpublished, but the shape is explicit.

## 3. Convergences — where Rox independently arrived at MDLP's positions

These are validation, not harvest: a commercial team under production pressure landed on the same architecture MDLP's spec argues for. Each is one sentence of ammunition for the paper's design-rationale sections.

| Rox practice | MDLP position it confirms |
|---|---|
| Full-state graph **rebuild every 30 min**; never trust incremental mutation; deliberate non-resolution where the source is already controlled | DL's projection/rebuild stance: truth is append-only, projections are disposable (PR-4/PR-7, REBUILD-ONLY write fences — the exact discipline H4-7 just docstring-fenced in TA) |
| `graph` lineage table, `source_system`/`source_id` provenance, attribution tokens, per-decision access traces | §10 lineage; PR-10's ancestry-not-wall-clock; the DL exemption-list's insistence that provenance is a first-class column |
| Eval checks **tool calls and pipeline shapes**, not just final answers | §4.2's trajectory-shape verification — the thing worth checking is *how*, not only *what* (see §4.1 below for the gap this exposes) |
| "Verifying retrieval costs as much as retrieval itself"; retrieval has no natural failure signal ("if the agent pulls the wrong three transcripts… nothing fails") | P1's founding argument: without an independent measurement channel, silent retrieval failure is invisible — exactly why MDLP puts held-out verification outside the optimization loop |
| Cheap prefilter before expensive judge; reranker budgeted to remaining context | §16's EIG-per-cost retrieval objective (currently parked in TA, H4-6) — the funnel shape is the same, MDLP's version has a principled stop rule where Rox has thresholds |
| "Simple linear pipelines perform best in practice"; sub-agent orchestration abandoned | The M0 GO's minimalism and RAF-2's state-space-minimization instinct: complexity in orchestration didn't pay even for a funded team; the value concentrated in **data and measurement** — which is MDLP's entire footprint |
| "Production issues become new test cases" | The RC catalog → fire-test discipline; H4-8's conformance manifest reproducing audit findings synthetically, then retiring them |
| Idempotent executors; ambiguity never auto-resolved to re-execution | The hermes attempt-ledger rule already adopted for M-R (ambiguity → `unknown` + human-visible, never re-run — double-counting held-out evidence is the MDLP-specific harm) |

The orchestration retreat deserves emphasis: Rox moved engineering *away* from the layer most agent startups celebrate and *toward* data plumbing and verification. That is independent commercial evidence for where MDLP has placed its bet — measurement and data-layer discipline, not planner cleverness.

## 4. Gap analysis I — what Rox has that MDLP's spec lacks

Graded honestly: most of Rox's machinery is either already in MDLP in stronger form, or out of MDLP's scope (multi-tenant infra). Three genuine gaps survive.

### 4.1 Trajectory capture as a stated precondition (the real one) — **candidate proposal ROX-1**

Rox evaluates **pipeline shapes and exact tool calls** because its infrastructure **auto-logs and versions every module's I/O** — the instrumentation exists *before* the eval that needs it. MDLP's §4.2 names `shape_ok` (trajectory-shape verification) but is silent on what must be captured for it to be checkable. The consequence already bit: the H4 build had to **retract `shape_ok` for prompt-only runners** — no trajectory is captured, so there is nothing to check, and the honest move was to state that rather than fake it (patch 0005). Rox's docs show the missing clause: *shape verification is conditional on a declared capture surface; the runner adapter contract should state what it records (outputs only / tool calls / full trajectory), and `shape_ok` degrades to `not_trace_checkable` — the status H4-8's conformance checker already defined — when the surface is insufficient.*

- **Where:** §4.2 (one paragraph) + the runner-adapter contract line in §18.
- **Evidence bar (L-003):** met — one real friction instance in the H4 build *plus* an external production pattern; and the fix reuses an existing status word rather than inventing mechanism.
- **Disposition:** queue for the L-010 gate alongside the six H4 findings (it is finding-adjacent: same patch, same root cause). Not started here.

### 4.2 The dual offline/online evaluator as a uniform per-module discipline — **pattern note, no spec delta**

MDLP *has* both halves — held-out verification (offline) and the drift posterior + breaker (online) — but declares them per-mechanism, not as a uniform rule ("every module defines an `offline_evaluator` and an `online_evaluator`"). Rox's version is an engineering convention, not an algorithmic claim, and MDLP's spec already covers its two load-bearing instances. Recording the pattern in `patterns.md` territory is enough; a spec delta would be structure for structure's sake (L-004 class). **No proposal.**

### 4.3 Replay-on-historical-production-data at module granularity — **covered, one sentence of credit due**

Rox versions module I/O so any change replays against history. MDLP's PR-7 double-replay covers the store, and §18's harness covers the run — module-granular replay falls out of DL's event-sourced truth (any projection can be rebuilt at any code version). The capability is implied but never *named* as a use case. Worth one clause in DL §12's rationale next time it opens for other reasons; **not worth a gate round on its own** (L-019).

**Out of scope, recorded for completeness:** multi-tenant fair queuing, model failover, Pod-style access control, ZDR agreements — infrastructure concerns of a hosted product. MDLP is an algorithm spec; TA's M-R inherits the relevant subset (fairness/isolation) from the hermes study's autonomy adoptions already.

## 5. Gap analysis II — what MDLP has that Rox lacks (the research opportunity, sharpened)

1. **Any statistics at all.** Rox's grading is heuristics + LLM-judge on developer rubrics + an internal labeling UI. No posteriors, no significance gates, no held-out partition, no calibration check, no drift detection, no rollback of *learned* state (their rollback story is infrastructure retries). The subjective bar is written into the product docs: did it "earn your trust."
2. **Measurement independence (P1).** Rox's judge rubrics are developer-defined and evolve with the system they judge — judge and judged can drift together, and their own stated fix (auto-eval "highly aligned with user ratings") is alignment to another moving signal. MDLP's held-out channel is frozen by construction. Their offline evaluation agents crawling *actual outcomes* (§1) are groping toward exactly this — outcome data as the independent channel — which suggests P1 is not an academic nicety but the thing production teams reinvent under a vaguer name.
3. **A learning loop, at all** — self-admitted (§1). The delayed-outcome tuning goal is MDLP-adjacent: MDLP's held-out verification is *immediate* (same-run eval items); credit assignment from **delayed, noisy, real-world outcomes** is genuinely not in MDLP's spec either. This is the one place Rox's ambition exceeds MDLP's current scope. It maps onto the prospection direction (`NOTE-prospection-pathways.md` — pathways to a future timeline are exactly claims whose verification arrives late), so it is filed there as an input, not opened as a spec front. **NOTE-feed, not proposal.**
4. **An identity model for learning peers.** Rox's Pod primitive makes agents first-class security entities alongside humans — governance treats "who can act" uniformly. Peer learning (`NOTE-peer-learning-roles.md`, rotating teacher/student) will eventually need exactly this: role assignment as a *grant*, revocable, provenance-traced, rather than a hardcoded topology. Filed to that note as an input. **NOTE-feed, not proposal.**

## 6. Verdict

- **Landscape:** four production systems examined, four without learning measurement — and the fourth one says so itself. `LANDSCAPE-self-learning-agents.md` gets a Rox row (vendor-doc class, admission-against-interest flagged); the paper's related-work claim upgrades from "no OSS system measures learning" to "no studied system, commercial included, measures learning — one vendor documents the absence as a known limitation."
- **Harvest:** deliberately small — one gated candidate (**ROX-1**, §4.2 trajectory-capture precondition, queued with the H4 findings batch), two NOTE-feeds (delayed-outcome verification → prospection; agent identity/grants → peer learning), one pattern observation (dual evaluators), and eight convergence receipts for the paper.
- **Discipline check:** everything else Rox does well is infrastructure MDLP correctly doesn't spec, or a weaker form of machinery MDLP already has. Under-building holds (L-004): no new agents, no new skills, no spec sections opened from this study alone.

*Next crossings from this study: ROX-1 rides with the H4-findings gate batch; the LANDSCAPE row and NOTE-feeds are ungated edits made alongside this file.*
