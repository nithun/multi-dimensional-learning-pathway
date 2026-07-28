# Hermes-agent study — lessons for MDLP and TA

**Date:** 2026-07-28 · **Subject:** NousResearch/hermes-agent (MIT, v0.19.0, Python+TS). Two parallel deep source reads (learning loop; autonomy + training infra), all claims file:line-cited in the underlying agent reports (session record IX-044).
**Status:** ungated study document. Anything touching gated artifacts flows L-010; TA-side items cross via the user (L-012).
**Why it matters:** hermes is the third "self-improving agent" system studied (after OpenSpace, automaton) and the most production-hardened (2,403 test files, 8-way sharded CI, issue numbers past #73k, battle-scar guards documented in-code). It markets exactly MDLP's territory — "the only agent with a built-in learning loop." What it actually contains sharpens both MDLP's positioning and TA's build plan.

## 1. The headline verdict — MDLP's moat, confirmed a third time

Hermes's entire learning-quality control is **LLM judgment plus deterministic hygiene**. Verified across the whole loop: no success rates, no held-out anything, no A/B, no verifier ever gates a skill edit. "After complex tasks" = a dumb counter (≥10 tool iterations since the last skill write) firing an LLM fork whose prompt says "be ACTIVE — most sessions produce at least one skill update." Its usage telemetry records *occurrence, not outcome* — and hermes had to instruct its own curator **not to trust its own counters** ("use=0 is not evidence a skill is valuable; it's absence of evidence"). That instruction is the single most valuable sentence in the repo for MDLP's paper: a production system self-documenting why outcome-free counters are decision-useless. Across OpenSpace (point-rate counters, hardcoded thresholds), automaton (prompt-text constitution, no benefit evidence for self-mods), and now hermes (no counters worth trusting at all), **no shipped system measures whether its learning worked.** MDLP's dual-Beta + statistical gates remain unoccupied ground; hermes joins OpenSpace in the paper's related-work/baseline row.

## 2. The learning loop — what hermes adds beyond OpenSpace

- **Improvement during use:** a mid-session background fork patches the *currently-loaded* skill (preference ladder: patch loaded → patch umbrella → add support file → create new), vs OpenSpace's boundary-event evolution.
- **Cadence-counter nudges as the learning heartbeat:** cheap counters (10 user turns → memory review; 10 tool iterations → skill review) that **reset only on a genuine learning write**, hydrate across restarts, and fire *after* the response so learning never taxes the user's turn.
- **Session-search-as-memory:** the full transcript store is a memory tier — SQLite FTS5 + trigram, lineage dedup via parent-chain walk, cron sessions demoted below interactive, LLM-generated titles for browsability, **zero LLM calls in retrieval**. Proves plain FTS5+BM25 suffices for cross-session recall with no embedding infra.
- **Two-speed curator:** deterministic inactivity lifecycle (active → 30d stale → 90d archive, reactivate-on-use, grace floor for never-used) always-on; expensive LLM consolidation **opt-in-only with dry-run and a deferred first run**.
- **Autonomy fences OpenSpace lacks:** `created_by` provenance in a sidecar — autonomous editors refuse anything not provably agent-created (fail-closed, including missing-record ≡ null); **read-before-write** (the fork must have loaded the exact target file this turn — no editing from transcript inference); pin blocks autonomous writes; archive-never-delete.
- **What hermes lacks vs OpenSpace:** outcome-differentiated counters and a queryable lineage DAG. **What both lack vs MDLP:** statistics (§1).

## 3. Autonomy machinery — deltas beyond the automaton adopt-list

These extend/refine `STUDY-automaton-autonomy.md` (they don't repeat it):

1. **Attempt ledger ≠ retry queue.** Hermes separates the mutable schedule from an append-only attempt audit whose terminal states are immutable; ambiguous crashes are marked `unknown` **only after the exact owner pid+start-time is proved dead, and are never auto-retried.** For M-R this is load-bearing: re-running an ambiguous work unit would double-count held-out evidence. Adopt as a rule: *ambiguity resolves to `unknown` + human-visible, never to re-execution.*
2. **At-most-once by mutating the schedule before executing** (advance `next_run` / claim the dispatch *before* the side effect), and **collapse missed backlogs to exactly one catch-up fire** — a restart costs at most one occurrence, never a burst. Claims are age-bounded on both sides (future-dated claims = stale — clock-skew defense).
3. **Three liveness signals, not one:** "process alive" (heartbeat file), "loop progressing" (event-loop heartbeat), "last tick succeeded" (separate file) — plus an OS-thread watchdog that hard-exits a frozen loop so the external supervisor can revive it. Refines AUT-1's watchdog contract.
4. **Per-record containment in the dispatch scan:** one malformed row degrades to skip-this-unit, never aborts the scan; recurring jobs are never silently disabled on error (state=`error` instead).
5. **The passive-informing contract, complete and tested:** always archive output locally regardless of delivery; **always deliver failures**; explicit `[SILENT]` marker for suppress-when-nothing-happened (with an anti-false-positive matcher); delivery as a durable obligation ledger with honest "♻️ may be a duplicate" markers on crash-recovery redelivery. This is the spec for M-R's digest channel (G7).
6. **Self-preservation check at schedule-creation time:** reject any scheduled job whose content would restart/kill the runtime that executes it (their agent once scheduled a gateway restart → 10s SIGTERM respawn loop).
7. **Serverless hibernate/wake, two layers:** sandbox filesystem snapshot/stop-resume (work state persists at ~zero idle cost) + host-level scale-to-zero with a **pure, testable idle predicate** (no in-flight turn ∧ no inbound ∧ no background work) that only arms when an external wake target exists — "a suspended instance with no reachable wake target is a black hole." The cheap-always-on answer for M-R.
8. **SQLite lifecycle rule (TA embedded tier, immediately applicable):** `with sqlite3.connect(...)` commits but **never closes** — in WAL mode each leaked connection pins 3 fds (db/-wal/-shm) until `Errno 24` takes down unrelated components. Canonical fix: per-module `_transaction()` contextmanager (`with conn:` for tx, `close()` in `finally`, schema-init inside the try); regression-test with a close-counting proxy. Their postmortem found the same bug class in 6+ modules — it's a *class*, sweep for it.

## 4. The trajectory pipeline — a ready-made reference for MDLP's M2 lane

Hermes ships the exact "curriculum → fine-tune data engine" shape MDLP's F-register names, minus the statistics:

**prompt dataset (rows can pin per-task sandbox images) → real agent loop per prompt → success-flag rejection sampling (`completed`/`partial`; zero-reasoning trajectories discarded) → ShareGPT `<think>`+`<tool_call>` JSONL with schema-normalized per-row tool stats → semantic compression budgeted in the *student's* tokenizer.**

Transferable specifics:
- **Toolset-distribution sampling as a curriculum knob:** each trajectory samples its available-tool subset from a named probability distribution — MDLP's pathway learner can sample *skill availability* per generated trajectory identically.
- **Per-row `tool_error_counts`** = a per-sample difficulty/quality signal with no reward model.
- **Compression correctness constraints:** budget in the student's tokenizer; protect head + last-4 turns; **never split a `<tool_call>`/`<tool_response>` pair** (boundary snapping); refuse compression that doesn't net-save; insert the summary as a visible turn — deliberately teaching the student to *continue after a mid-conversation summary*, the same skill the runtime compactor exercises.
- **Two-stage discipline:** generate uncompressed, compress as a separate audited pass with its own metrics — the ratio/quality is itself measurable.
- Trajectories are generated with memory/context files **off** (no persona pollution in training data).

Where MDLP slots in: hermes has only a boolean `completed` where MDLP has held-out gates — the M2 data engine = this pipeline + MDLP's statistical selection (gate-passing episodes only, per §17.6 CAPTURE's ancestry discipline). This materially de-risks the M2 decision recorded in NEXT-STEPS D3.

## 5. Programmatic Tool Calling — the context-economy pattern (→ §16)

The LLM writes a Python script; a generated stub module RPCs each `_call(tool, args)` back to the parent over an authenticated UDS; **only the script's bounded stdout enters context** (50KB head/tail-truncated); the turn is *refunded* from the iteration budget. K tool invocations at O(1) context cost, inside a safety envelope (7-tool whitelist, token auth, max 50 calls, 300s). For §16's cost model this is an existence proof for distinguishing **decision-relevant** intermediates (must enter context, pay per pull) from **mechanically aggregable** ones (scriptable, pay once) — a candidate future refinement to R1's cost term, not a change to the approved spec.

## 6. Concrete borrowings (ranked, with destination)

**MDLP spec-side (gated when they touch artifacts):**
1. Positioning: hermes → LANDSCAPE/PAPER alongside OpenSpace (the "no shipped system measures learning" claim now has three legs). *(Ungated docs.)*
2. M-R/AUT-1 refinements: `unknown`-never-retried attempt semantics; mutate-schedule-before-execute; three liveness signals; per-record scan containment; the `[SILENT]`/always-archive/always-deliver-failures digest contract; schedule-time self-preservation check. *(Fold into AUT-1 when drafted.)*
3. M2 lane: adopt the trajectory-pipeline shape + compression constraints as the data-engine reference design. *(M2 design doc, when the trigger fires.)*
4. Spec note for pruning gates: "unexercised ≠ failing" — cite hermes's grace-floor + counter-distrust as the failure mode dual-Beta priors already prevent. *(Small lesson-shaped addition.)*

**TA implementation-side (cross via user):**
5. The SQLite `_transaction()` sweep (§3.8) — immediate, mechanical, high-consequence.
6. Read-before-write for all self-editing agents (retrospective/smiths patch only files loaded in the same turn) + `created_by` provenance fail-closed on framework artifacts.
7. Reset-on-genuine-use nudge counters for triage.sh (reset only when the real learning write happens; hydrate across restarts).
8. FTS5 over the transcript store as the curator's recall tier (BM25 + source demotion suffices; no embeddings needed).
9. Description-budget enforced at write time in skill-smith (the description *is* the retrieval index).
10. Two-speed curator split: deterministic bookkeeping always-on; LLM consolidation opt-in with dry-run default.
11. Isolation checklist if in-session background evolution ever runs (their "curator-takeover" regression: fork persistence leaking into the real session; compression races; tool whitelists; prompt-cache parity).

## 7. What NOT to copy

- LLM-judged skill quality with no outcome measurement (the core anti-pattern all three studies share).
- No versioning of skill edits (in-place atomic writes, archive-as-history only) — §17.6's version DAG is strictly stronger.
- "Be ACTIVE — most sessions produce at least one skill update" — a bias toward writing that MDLP's evidence thresholds exist to prevent.
- JSON-file schedule without a DB (hermes makes it safe with heroic locking; TA's truth-store schedule table is the cleaner design).

*Provenance: two agent deep-reads (IX-044), 92 tool calls total; the underlying reports carry file:line for every claim above. Companion studies: `STUDY-raganything-agentscope-openspace.md`, `STUDY-automaton-autonomy.md`, `STUDY-small-models-for-mdlp.md`.*
