# Rox study — crossing brief for the TA workspace (2026-08-19)

**To:** the TA workspace agent/operator. **From:** the MDLP research repo, carried by the founder (L-012: this file and the study it names arrived by the founder's hand; nothing was pushed). **Copy this file and `STUDY-rox-agent-swarm.md` to `docs/briefs/` / `docs/mdlp/` on arrival.** This brief travels with the H4 crossing package (`2026-08-19-mdlp-h4-crossing-brief.md`) but is independent of the patches — you can act on it before or after applying the series.

**What this is:** the research side deep-read `docs.rox.com/development` (~26 vendor engineering pages: Agent Swarm layer, evaluation, reliability, knowledge graph, governance) and wrote `STUDY-rox-agent-swarm.md`. That study is MDLP-spec-focused; **this brief is the TA cut** — Rox is the first *commercial production* agent swarm studied, and its engineering patterns map directly onto your own gap map (HANDOVER-v3 G1–G7, as re-audited in AUDIT-TA-2026-08) and your WBS. Source-class caveat applies throughout: vendor-described mechanisms, not source-verified — adopt the *shapes*, never cite the capability claims.

---

## 1. The one fact to internalize first

Rox — funded, multi-tenant, with a real eval team — **self-admits in its docs that its agents don't learn**: "LLM systems are stagnant — they're built once"; memory, adaptability, and feedback-driven adjustment are all filed as future work. That is the fourth production system in a row without learning measurement, and the first to write it down. **Implication for TA:** the thing you are building (an MDLP implementation that statistically measures whether learning worked) has no commercial precedent to copy — and that is the point. When a Rox pattern below conflicts with an MDLP invariant, the invariant wins.

## 2. Mapping onto YOUR ledger (G-map / WBS / M-R)

### G5 / W4.1–W4.6 (autonomy block, watchdog first) — the most directly useful material

Rox's Framework for Reliable Task Execution is a production-shaped reference for exactly the block you build next after the founder decisions. Adopt-list, composing with (not replacing) the hermes adoptions you already hold:

- **Idempotent executors + explicit ack** (delete-on-success) + **visibility-timeout redelivery** — same family as the hermes attempt-ledger rule already adopted for M-R. Keep the MDLP-specific sharpening: ambiguity resolves to `unknown` + human-visible, **never** re-execution (double-counting held-out evidence is the harm class Rox doesn't have).
- **Dead-letter queue as a first-class terminal state** — your work-unit substrate (`open_work_unit`, `AppendResult`) has leases but no documented "unrecoverable, parked, human-visible" bucket. Cheap to add at the schema level; prevents poison work units from cycling.
- **Task-level isolation:** one malformed unit degrades to skip, never aborts the scan (hermes said this too — two independent production confirmations now).
- **Fair queuing per group** — single-tenant TA doesn't need tenant fairness, but the *shape* (per-skill or per-fleet-member message groups so one hot skill can't starve the rest) is worth one line in the W4 design doc.
- **Their monitoring split** (queue depth / success rates / executor spans as separate signals) corroborates the hermes three-liveness-signals rule: never collapse "alive", "progressing", and "last tick succeeded" into one flag.

### G3 / W4.7 (wire-or-retract) — closed by the H4 series; Rox explains *why* it mattered

Rox's eval evaluates **exact tool calls and pipeline shapes**, which is only possible because their infrastructure **auto-logs and versions every module's I/O before any eval needs it**. That is the general form of what the H4 series learned the hard way: `shape_ok` had to be retracted for prompt-only runners because no trajectory is captured (patch 0005). The spec-side fix (**ROX-1**: §4.2 trajectory-capture precondition, runner adapters declare their capture surface) flows MDLP's gate first — **do not action it locally** (§4 below). What you *can* do now, cheaply and without any spec dependency: when you next touch the runner adapter, log what surface it actually captures (outputs-only today) so the future ROX-1 conformance clause lands on recorded fact instead of archaeology.

### G4 / W3.0–W3.7 (corpus, founder-blocked) — one corroborating input

Rox's "production issues become new test cases" loop and their sandbox suite (~200 real queries against mocked service contracts) are the commercial version of what `IMPL-PROTOCOL.md` (in the H4 package) proposes for W3.0: real tasks, executable verification, accumulated from actual work. This is *input to* the founder's W3.0 decision, not a preemption of it — same status the H4 brief already gave IMPL-PROTOCOL.

### G6 (model providers) — one pattern, when you get there

Rox's model-reliability layer is pre-qualified primary→backup **model mappings** validated for output quality before they're ever needed, not ad-hoc fallback at failure time. If/when TA grows provider redundancy, qualify the backup *offline* first. Low priority; G6 wasn't even probed in the last audit.

### G7 (observability) / cycle digest — corroboration only

Their per-module `offline_evaluator`/`online_evaluator` convention is the engineering-discipline form of what DL §11 (ObservabilityPort) + §20.10 liveness (patch 0008) already give you with statistics attached. Nothing to adopt that the spec wave doesn't already carry; noted so you don't mistake their version for something missing.

### Orchestration (dispatcher / squads) — a warning worth keeping

Rox **abandoned specialized sub-agents and a query-decomposing routing layer** ("frontier models handle planning well") and reports "simple linear pipelines perform best in practice"; engineering moved to the data and action layers. Independent commercial evidence for TA's existing instinct: don't grow orchestration cleverness; grow data discipline and measurement. If a future W-stream proposes a planner/router layer, this is the citation against it.

## 3. Feature checklist (suggested board tasks, your numbering)

| Priority | Item | Where it lands |
|---|---|---|
| when W4 opens | DLQ/parked terminal state for work units | work-unit schema + W4 design doc |
| when W4 opens | per-group fairness note + skip-don't-abort scan rule | W4 design doc |
| cheap, any time | runner adapter logs its capture surface (outputs-only today) | one line + one test |
| when G6 opens | offline-qualified backup model mapping | provider module design |
| none (read-only) | orchestration-retreat citation | keep in docs/briefs/, cite when relevant |

## 4. Do-not list

- **Don't action ROX-1 locally.** It is a spec-side delta (ALGORITHM §4.2 + §18 adapter contract) that must flow MDLP's L-010 gate first, then cross — same discipline as the six H4 findings.
- **Don't adopt Rox's evaluation *criteria*** (LLM-judge rubrics, subjective "earned your trust" bars, developer labeling as ground truth). Their eval *infrastructure* shapes are good; their measurement philosophy is exactly what MDLP exists to replace. P1 stays the wall.
- **Don't cite Rox capability claims** ("immune to prompt injection", "millisecond failover") in any TA design doc — vendor-described, unverified.
- **Don't treat this brief as new scope.** Nothing here unblocks W3.0/W3.7 or jumps the T4 queue; it sharpens work already planned.

## 5. What crosses back (via the founder — you cannot push it)

Nothing is *required* back from this brief. If, when you wire the W4 block, you find the DLQ/fairness shapes conflict with the work-unit substrate as built, that's a finding worth a line in your next outbound crossing (the HANDOVER-v4 §H4-1 reconciliation slot remains the vehicle — and your A5 measurement-invalidation item is **still waiting to cross out**; remind the founder again).

*Provenance: every Rox claim traces to `STUDY-rox-agent-swarm.md` (which cites the specific docs.rox.com pages); every TA claim traces to `AUDIT-TA-2026-08.md` (file:line evidence) or the H4 series README. Built 2026-08-19; this workspace was not read or written for this brief.*
