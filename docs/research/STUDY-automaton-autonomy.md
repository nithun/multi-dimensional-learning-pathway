# Automaton study — what MDLP needs to run fully autonomously

**Date:** 2026-07-28 · **Subject:** Conway-Research/automaton (MIT, TS, v0.2.1, single squashed commit — a published snapshot, development moved internal). Deep source read (file:line-cited by the reviewing agent; ~67k LOC, ~1530 real tests, but CI converts test-suite hangs into passes).
**Status:** study document — ungated. The autonomy proposals at the end flow the L-010 gate before touching gated artifacts.
**Why:** the owner wants MDLP to run **fully autonomously**. MDLP has the *safety* half (statistical gates, breaker, budgets, JUDGE-owned orchestrator, resume-from-truth work units — §6.1 approved 2026-07-13); automaton is the first studied system built for the *liveness* half (continuous unattended operation). It also has instructive failures: its constitution is prompt-text enforced by nothing, its liveness watchdog can never fire, and its self-mod has no revert path.

## 1. What it is

A single-process "sovereign agent": infinite supervisor loop wrapping a bounded ReAct work cycle, an in-process cron daemon with DB-leased tasks, all state in one WAL SQLite file, a survival-tier budget state machine, self-modification with a frozen protected-file manifest, and child replication with hash-verified constitution propagation. The crypto/self-funding layer is irrelevant to MDLP; the autonomy engineering transfers.

## 2. ADOPT — ten patterns for MDLP's unattended loop (agent report M1–M10, distilled)

1. **Two-level loop.** Infinite supervisor (`index.ts:406-487` — never exits; every error path becomes a timed sleep) wrapping a bounded work cycle (≤25 turns, then mandatory sleep). MDLP's current finite n-tick run becomes the *inner* cycle unchanged; autonomy = adding the outer `while(true)`. A bug wastes one cycle, never the fleet.
2. **Schedule is a table; every unit of work is leased.** DB schedule + lease-by-conditional-UPDATE + TTL sweep + full execution history (`scheduler.ts`, `database.ts:1297-1324`). Crash recovery needs zero code (leases expire); double-run impossible; "when did X last run" is SQL. Recursive `setTimeout` + in-flight flag, never `setInterval`. MDLP: eval batches / posterior refreshes / retraining become leased tasks in truth.
3. **Wake events as an atomic queue** (`UPDATE…RETURNING`), consumed on a ≤30s poll during chunked sleep, **drained at loop entry** so backlogs don't cause instant re-wake. They migrated from a KV boolean flag — skip that mistake.
4. **One pure tier function, many independent consumers.** `getSurvivalTier()` (`credits.ts:38-44`) read by model routing, task suppression (`tierMinimum` column), agent state, and replenishment. MDLP: `tier(budgets)` → cheaper SOLVE model / skip low-priority scheduled work / raise the commit bar when scarce / pause.
5. **Debounce terminal states.** Cache last-known-good with an "unknown ≠ zero" sentinel; unknown ⇒ degrade, never die; terminal transitions require a *continuous* window (1h). Their own bug (H5): one read path skipped the cache, so a 1-hour API outage kills a fully-funded agent. MDLP: a budget-store read failure must never look like `b=0`.
6. **Replenish before you spend, with cooldowns** — inline pre-spend top-up (60s cooldown), plus startup and scheduled paths, each independently guarded.
7. **Freeze the enforcement code in the protected manifest** (`code.ts:37-79` includes the policy engine, injection defense, audit log, and the self-mod module itself) + **rate-limit modification frequency** (20/hr — orthogonal to per-change gates, catches gate-thrash) + **dry-run validator** (structured per-check pass/fail without burning a slot). Direct §17.1/§17.6 reinforcement.
8. **Reclaim work whose owner died** (`orchestrator.ts:530-548`, ~18 lines) — exactly MDLP's §6.1 resume-from-truth, independently invented. Their gap: inbox claims have no TTL and strand forever. **Rule: every claim gets a TTL or liveness probe, no exceptions** — audit every MDLP store for claimed-but-not-expirable state.
9. **Outcome + acknowledgement in one transaction** — and go beyond them: they persist *after* side effects, so a mid-turn crash loses the record of actions taken. MDLP's dispatch-intent-before-work + outcome-after (§6.1) is already the stronger form; keep it.
10. **Layer stop conditions; assume each fails.** Seven independent brakes, ending in a dumb hard ceiling whose in-code comment admits the smart heuristics are defeatable (`loop.ts:867-869`). MDLP: breaker + unconditional per-cycle work ceiling + escalation-when-warning-ignored + exponential backoff on no-op cycles.

## 3. AVOID — the eight failure modes (A1–A8, distilled)

1. **Conditionally-skippable safety gate** — their policy engine silently no-ops if an unrelated dependency isn't wired (`tools.ts:3320`). Gates fail closed and loudly.
2. **Inert observability** — 7 alert rules, 2 metrics ever written; the liveness watchdog *can never fire*; the audit log drops its correlation id at the sole call site. **Assert alarms fire on synthetic input; every event carries its correlation id or it isn't an event.**
3. **Self-mod with no revert** — static predicates only (no benefit evidence), no revert function in the repo, failed rebuild returns `success:true`. MDLP's statistical gate + §17.6 reactivation is the answer; automaton is the cautionary proof of why.
4. **Trust assigned by pipeline, not boundary** — stranger messages get tagged `source:"agent"` and inherit self-authority; sanitization covers 3 of the many external-content tools. Authority is assigned where bytes enter and re-checked at the tool boundary.
5. **Prompt text as enforcement** — `constitution.md` is "security layer #1" and no code evaluates any action against it. Invariants are code predicates on the execution path with a test that proves denial (MDLP's INVARIANTS-fence / JUDGE discipline, vindicated).
6. **No supervisor, no crash handlers** — one unhandled rejection permanently ends the "continuous" agent. Minimum: rejection handlers logging to truth + external supervisor with restart backoff + a freshness watchdog **outside the process** (a watchdog inside the thing it watches is not a watchdog).
7. **Budget exhaustion as silent spin** — budget denial returns a success-shaped object; the agent burns cycles forever looking alive. Denial must be a distinct terminal-for-this-cycle signal with a long backoff.
8. **Config through `any`-casts** — the fleet-size cap silently ignores configuration. Fleet caps (§18 `N`) must be typed, explicit, and tested-as-enforced.

## 4. Fleet notes (§18/B3)

Usable: the child lifecycle state machine + append-only lifecycle event log; **hash-verified artifact propagation** (store hash at source, re-verify at destination) — the cheap audit half of B3 transfer (MDLP's zero-trust re-validation remains the load-bearing half automaton lacks entirely — it has no selection, no mutation, no generation depth cap, and a config-ignoring width cap). Capacity-aware pool sizing (pending work vs idle agents vs cap) is a reasonable autoscaler skeleton.

## 5. Observability & analytics roles (the ClickHouse + Langfuse decision)

Automaton's single most instructive *failure* is A2: it shipped autonomy without working observability, so a stuck agent looks alive. This independently confirms the owner's instinct: **unattended MDLP needs an observability role and an analytics role.** The placement that preserves MDLP's zero-infra identity (L-010; `pip install mdlp` must still run with nothing):

- **`ObservabilityPort` (new role):** embedded default = the existing truth event log + a JSONL trace file; full tier = **Langfuse** (Apache-2.0, self-hosted). Every §6.1 `dispatch` = a trace; every model call = a span with cost/latency; every gate decision = a scored event. This is how a human stays *passively* informed instead of in-the-loop.
- **`AnalyticsStore` (new role):** embedded default = SQLite views over truth; full tier = **ClickHouse** (Apache-2.0) as **another rebuildable projection** of TruthStore (`rebuild_analytics(truth)`) — the "truth canonical, projections rebuildable" identity extends unchanged. Consumers: §19 calibration tuples, difficulty-stratified reporting, fleet dashboards. Note: self-hosted Langfuse v3 ships ClickHouse in its own stack — one deployment can serve both roles.
- **Not default.** Default stays zero-infra; an **autonomy deployment profile** turns both on. Same config-not-code pattern as Postgres/Neo4j.

## 6. Proposed next steps (each gated before touching gated artifacts)

- **AUT-1 — "§20 Continuous operation" spec** (ALGORITHM or a standalone gated doc): two-level loop, leased schedule table, wake-event queue, tier function + consumers, debounced terminal states, layered stop conditions, external supervisor + watchdog contract. Adopt-list items 1–6, 10; avoid-list 1, 6, 7 as invariants.
- **AUT-2 — DATA-LAYER delta:** `ObservabilityPort` + `AnalyticsStore` roles per §5 above (Langfuse/ClickHouse as full-tier backends; embedded defaults zero-infra).
- **AUT-3 — §17.5/§17.6 hardening delta:** freeze-the-enforcement-manifest named explicitly (JUDGE source, gate statistics, eval harness, truth writer), modification-frequency rate limit, dry-run validator. (Small; reinforces approved text.)
- **AUT-4 — claims audit:** verify every claimable state in the 5-store design carries a TTL/liveness probe (the §6.1 work-unit lifecycle already does; check caches, leases-to-be, B3 quarantine).

*Provenance: agent deep-read of the cloned snapshot, 58 tool calls; all file:line citations from that pass. Lessons cross to the turing-agents implementation only via the user (L-012).*
