# HANDOVER v3 — MDLP → turing-agents

**From:** the MDLP research project · **Date:** 2026-07-28 · **Supersedes:** HANDOVER-v2 (2026-06-26, updated 2026-07-02)
**Audience:** the turing-agents (TA) workspace — the reference implementation, built by the owner. This document crosses by hand (L-012: MDLP never writes into TA). Everything here is spec, review, or advisory; TA decides how to land it.
**Contents:** §1 third-person status review · §2 target picture and gaps · §3 the next milestone · §4 guide to building and testing it autonomously.

---

## 1. Current status — a third-person review

*(Written as an external reviewer would; every claim below is backed by the 2026-07 gate records in `docs/research/reviews/` or the 2026-07-28 read-only audit of TA at HEAD `949ed74`.)*

**The research side is specification-complete for its current horizon and unusually well-audited.** The spec of record (`ALGORITHM-v0.2-pathway-learner.md` §1–§19 plus §17.6) and the build specs (A1, A5, B1–B4, B3, R1, B2 Amendment A) have all cleared a two-stage adversarial gate (review-360 scoring → independent approver), most recently four changes on 2026-07-13 that took ~30 review rounds combined: **R1** (§16 companion: 5-mode retrieval dispatch + fusion reranker, 87/100), **§17.6** (scaffold-version log with FIX/DERIVE/CAPTURE operators and ancestry-checked CAPTURE, 84/100), **B2 Amendment A** (typed `part_of` edges, soft `τ_traverse` floor with `q_edge` inverse, `queue_rank` confirmation queue, 85/100), and the **DATA-LAYER §6.1/§6.2 write discipline** (occurrence-identity hashing via a dispatch→work-unit lifecycle, two-phase extract→merge projection writes, `RedactedTruthView` P1 boundary, 83/100 over twelve rounds). The gate demonstrably works: it caught, among others, an RC-4 closed loop, a Beta-posterior under-counting inversion, a silent work-merge hole, and an M0-reachable held-out leak before any shipped.

**The implementation (TA `mdlp/`) is real, honest, and narrower than the spec surface.** A four-way read-only audit (2026-07-28) found: the mathematical core is correct and verified (closed-form Beta EIG with the digamma recurrence done right; `significant()` used everywhere gating happens; 234 tests green, 6 gated skips); **held-out integrity genuinely holds** (quarantined ids, disjoint pools, reward and gate exclusively on held-out, memorization probes present — the property most often faked in this class of system holds up). The 5-store layer is complete on both tiers with clean ports-and-adapters discipline.

**Three structural caveats temper that picture.**
1. **Built-but-unwired:** several advertised constructs exist as correct, unit-tested primitives that no live path calls — A1's blended objective `U(a)` (deliberate: wiring it would invalidate the M0 GO), the §14 calibrator (not behind `estimate()`, so live `significant()` consumes raw SE), the drift posterior + `rollback_fires` + circuit breaker (the live loop is commit-only), the §4 shape+counterfactual verifier (live path scores with bare `exact_check`), and all of §16 retrieval (hermetic).
2. **Genuine bugs:** A5 warm-start *inverts* its RC-7 anti-bubble control (`agreement()` measures competence concordance, not feature diversity — a homogeneous cohort gets a *stronger* prior) and neither enforces nor documents the anchor-set embedding rule; `rebuild_all` fails to flush the Redis cache; truth-store writes are upsert-not-append (empty-id retries double-count); a latent reachability sign inversion in `decision.py` (`u = q·rw` misorders when `q<0`); B4's `S0` ignores mastery.
3. **The evidence base is a toy.** The M0 GO (held-out 0.495 vs 0.025, margin +0.47, artifact `b7-a33f906-n15x10-r1.json`) and all M1 live validation (B2 prereq diagnosis firing on real `claude`, §15 triggers, A5 head-start) are on invented cipher skills (ACME/NOVA). The representative coding corpus that the M0 GO itself flagged as "still ahead" **has never been built**. TA's own docs state this honestly; it remains the credibility ceiling.

**Positioning is now grounded.** The external study (2026-07-13) established that no open system — including HKUDS OpenSpace, the closest shipped relative — has probabilistic competence state, statistical gates, measurement independence, or calibration; OpenSpace is the natural paper baseline. The automaton study (2026-07-28) supplied the missing *liveness* patterns for unattended operation and independently vindicated MDLP's core stance (its prompt-text "constitution" is enforced by nothing; its self-mod has no revert). The small-models study mapped local model slots: six embedding consumers behind one unprovided interface, plus student/teacher/judge roles.

---

## 2. What we want to build, and the gaps

**The target picture (owner's stated goal): MDLP running fully autonomously.** A learner that runs unattended — selecting its own next learning action by expected competence gain, committing only through statistical gates on held-out evidence, resuming cleanly from any crash, degrading gracefully under budget pressure, observable enough that a human stays *passively* informed, and doing all of this on a **representative task corpus**, not a toy.

Gap map, from the current state to that picture:

| # | Gap | Source | Weight |
|---|---|---|---|
| G1 | Audit bugs (A5 RC-7 ×2, Redis rebuild flush, upsert-not-append, reachability sign, B4 S0) | 2026-07-28 audit | small each; A5 pair is safety-relevant |
| G2 | Approved spec deltas not yet adopted: DATA-LAYER §6.1/§6.2 (work-unit lifecycle, `AppendResult`, `GraphStore.merge`, two-bundle `RedactedTruthView`), B2 Amendment A, R1; §17.6 is M3-horizon | 2026-07-13 gate | §6.1/6.2 is the load-bearing one — audit confirmed it's an *additive refactor* (ports/DI already clean) and it retires two G1 bugs (upsert; no retire path) |
| G3 | Unwired constructs (calibrator, drift/rollback/breaker in live loop, full verifier on live path, `U(a)`) | audit | medium; wire-or-retract each |
| G4 | **Representative corpus** — real code+pytest tasks; the pre-registered cold→warm protocol exists (`M1-EVAL-PROTOCOL.md`) but has nothing to run on | M0 GO caveat | **the** credibility item |
| G5 | Autonomy layer — two-level loop, leased schedule table, wake-event queue, tier-based degradation, debounced terminal states, external supervisor + watchdog, layered stop conditions | automaton study (AUT-1..4) | the owner's headline want |
| G6 | Model providers — an `EmbeddingProvider` behind the six dark consumers (`embed-lite`=potion/Model2Vec, `embed`=MiniLM, upgrade=Qwen3-Embedding-0.6B); reranker optional; M2 student choice (Qwen3/SmolLM3) deferred with M2 | small-models study | enables B1/B3/§16/growth-merge; optional extras only |
| G7 | Observability/analytics roles (Langfuse / ClickHouse as opt-in full-tier backends, embedded defaults zero-infra) | automaton A2 + owner | required for *unattended* runs to be auditable |

Explicitly **not** in the next milestone: M2 (weight axis — deferred per NEXT-STEPS D3), M3 (§17/§18/§17.6 runtime), C1 (human-learning verifier), PyPI.

---

## 3. The next milestone: **M-R — representative, resumable, unattended**

One sentence: **a GO or honest NO-GO on a real coding corpus, produced by a run that no human supervised.**

Three acceptance clauses, all required:

1. **Representative (closes G4).** The learner runs the pre-registered `M1-EVAL-PROTOCOL.md` cold→warm two-phase protocol on a corpus of real Python tasks verified by pytest execution — not string-match ciphers. Primary gate unchanged from M0: held-out pass-rate vs frozen no-learning baseline beyond `z·SE`, paired and powered; warm-transfer gate secondary; token-cost ratio reported; results stratified per skill×difficulty cell. **A NO-GO is a publishable, milestone-satisfying outcome** — the milestone is the *run*, not the sign of the result.
2. **Resumable (closes G2-core + the resume half of G5).** The run executes on the adopted §6.1/§6.2 data layer: every eval run is a leased work unit minted from a dispatch row; kill -9 at any tick, restart, and the run completes with no double-counted and no lost evidence (`test_ack_loss_recovery_no_double_count` live, not just unit).
3. **Unattended (closes the loop half of G5).** The whole protocol executes under a two-level loop — infinite supervisor, bounded work cycles — with budget tiers, layered stop conditions, an external watchdog on last-completed-work-unit freshness, and every dispatch/gate decision observable after the fact. The human sees a report at the end and alerts in between; they touch nothing during.

---

## 4. Guide: building and testing M-R autonomously

*This section is written for TA's own agent loop to execute task-by-task. Each task has an acceptance test; a task is Done when its tests are green and its inverse (rollback) is possible. Order matters — earlier tasks de-risk later ones. TA's existing gate/review flow applies to its own commits as usual.*

### Phase 0 — Fix what's broken (G1) — ½ day equivalent, all test-first

| Task | Fix | Acceptance |
|---|---|---|
| 0.1 | A5 `agreement()` → spec's `div` = mean pairwise (1−cosine) over neighbour *features*; scale `n_eff_warm · max(div, div_floor)` | homogeneous cohort ⇒ **weak** prior (assert the direction, the bug was the sign) |
| 0.2 | A5 anchor-set: document + enforce — `Neighbor.features` must be the anchor response vector; add a policy-invariance test | embedding unchanged under a different selection policy |
| 0.3 | `decision.py` reachability: `u = q·rw` → rank-safe blend (penalize, never flip: e.g. `u = q − λ(1−rw)` or clamp q≥0 before scaling) | a less-reachable skill never outranks an otherwise-identical more-reachable one, incl. negative-q branch |
| 0.4 | B4 `S0 = max(S_unit·ĉ_m, S_min)` | mastered cell's first review lands later than a weak cell's |
| 0.5 | `rebuild_all` cache flush: full-flush semantics on every tier | after rebuild, a stale versioned key is unreadable (Redis-fake test) |

### Phase 1 — Adopt the approved write discipline (G2) — the enabling refactor

Land DATA-LAYER §6.1/§6.2 as specced (decision record `DL-write-discipline-decision.md`; its two advisories — `RedactedTruthView` write-method behavior, aggregation-granularity floor — must be resolved in code):
- 1.1 `schemas.py`: `identity_hash` + occurrence provenance (`agent_id, episode_id, checkpoint_id, attempt_idx`), `WorkUnit`, `AppendResult{id, deduped, rejected_reason}`, `UnknownIntentKey`, `dispatch`/`work_unit_opened`/`rejected_ingest` records.
- 1.2 `TruthStore`: `open_work_unit(agent_id, episode_id, suite_id, intent_key)` idempotent on a UNIQUE `intent_key` (= dispatch event id; `seq` discriminator assigned atomically in the dispatch append); `append_event`/`record_eval` become true appends with identity dedup and reference validation.
- 1.3 `GraphStore.merge(GraphDelta) -> MergeReport` as the only projection write path (adds, edges, `merges`, `retires`, `edge_updates`); `rebuild_graph` re-routed through it. This also gives RC-4 prune a store-level path (audit gap).
- 1.4 `build_stores() -> Bundles{judge, solve}`; solve bundle wraps truth in `RedactedTruthView` (held-out `item_ids`/content stripped; decide write-methods: **raise**).
- **Acceptance:** the spec's consolidated write-discipline test set (§6.2 end) implemented and green — the load-bearing ones: `test_repeat_measurement_not_deduped`, `test_ack_loss_recovery_no_double_count`, `test_distinct_dispatches_distinct_keys`, `test_rebuild_routes_through_merge`, `test_held_out_item_ids_not_solve_readable`.

Then B2 Amendment A (typed edges + `queue_rank` queue; its test list is in BUILD-SPECS) and R1 (mode dispatch + fusion `v`; its `test_defaults_reduce_to_approved_16` keeps it regression-safe). §17.6 is spec-adopted only (schema tables may land; no runtime until M3).

### Phase 2 — The representative corpus (G4)

- 2.1 **Corpus builder:** ~8–12 skills as families of small Python tasks (e.g. string transforms, parsing, dataclass manipulation, simple algorithms), each task = (prompt, hidden pytest suite), items generated parametrically so isomorphic variants are cheap (fresh operands/identifiers per draw — the anti-memorization requirement). Verifier = **run pytest in a sandboxed subprocess**; pass = suite green. Wire through the existing verifier-admission registry, and put the §4 probe battery on it (exact answer, prose-wrapped, wrong, glued — plus a hard-coded-constant patch probe).
- 2.2 **Skill notes must be learnable knowledge, not answers:** the committable artifact is a technique note (as today), never a held-out solution; held-out ids quarantined exactly as the cipher corpus does.
- 2.3 **Power check before the real run:** hermetic dry-run to estimate per-item pass variance → choose `n_held` and ticks so the primary gate is powered (M0 used n_held=15×10 ticks; real code will need ≥ that). Freeze corpus hash, splits, `n_held`, ticks, `z`, backbone version in the run artifact **before tick 1** (the pre-registration discipline).
- **Acceptance:** hermetic cold→warm run on the fake runner passes end-to-end; probes fail as designed; a seeded "cheat note" lifts public only and is rejected by the generalization gate.

### Phase 3 — The autonomy loop (G5, from the automaton study's adopt-list)

- 3.1 **Two-level loop:** outer supervisor `while True` (every exit path = timed sleep, never process exit); inner = the existing `LiveLearningRun` cycle, hard-capped (`maxTicksPerCycle` ~25). 
- 3.2 **Leased schedule + wake queue in truth:** schedule rows (cron/interval/next-run) + TTL leases via conditional UPDATE + full execution history; wake events as an atomic consume-queue, drained at loop entry; chunked sleep (≤30s poll).
- 3.3 **Budget tiers:** one pure `tier(spend, budget)` function; consumers: model routing (cheaper/skip), task suppression (`tier_minimum` per scheduled task), gate posture (no marginal commits when scarce), pause. **Debounce terminal states** — unknown ≠ zero, sentinel-cached reads on every path, terminal only after a continuous window.
- 3.4 **Layered stop conditions:** per-cycle tick ceiling, consecutive-error cap → forced sleep, no-progress backoff (exponential), budget-exhaustion as a *distinct terminal-for-cycle signal* (never a success-shaped object), plus the existing statistical breaker.
- 3.5 **Wire the dormant safety kit into the live loop** (G3, now load-bearing): `rollback_fires` + circuit breaker in the tick; calibrator behind `estimate()` (or explicitly retract the claim); the full §4 verifier (shape+counterfactual) on the live path — pytest execution makes the counterfactual check natural (run the candidate against a variant suite).
- 3.6 **Supervisor + watchdog, outside the process:** launchd/systemd unit with restart backoff; `uncaughtException`-equivalent handlers that log to truth and exit non-zero; a watchdog reading *last completed work-unit timestamp from truth* and alerting on staleness — the watchdog must not live inside the loop it watches. Alert channel: whatever TA already uses for digests. **Test the alarms fire on synthetic staleness** (automaton's fatal omission).
- 3.7 (Optional, G7) Observability: emit per-dispatch trace records (embedded: JSONL/truth events; full tier: Langfuse) and treat ClickHouse as a rebuildable analytics projection — config-selected, never default.
- **Acceptance:** a 2-hour hermetic soak: kill -9 the process at random 3×, supervisor restarts it, run completes, evidence counts exactly match an uninterrupted control run; watchdog fires on an induced stall; budget-tier downgrade observed under an induced low-budget condition.

### Phase 4 — The M-R run itself

- 4.1 Freeze the pre-registration artifact (Phase 2.3). Estimate cost ceiling; set the budget tiers so the worst case is bounded.
- 4.2 Launch under the supervisor. Human walks away.
- 4.3 The run produces: `mr-<sha>-<params>.json` (cold + warm + baseline arms, per-cell stratification, token ratio), the trace/audit trail, and the watchdog log. Provenance: git SHA + corpus hash inside the artifact, as with `b7-*.json`.
- 4.4 Post-run: paired significance on primary and warm gates; memorization probes re-run against the final library; honest scope caveats written into the artifact. **GO and NO-GO get identical write-ups.**

### Standing rules for the autonomous build itself

- **Test-first, one task per commit, its inverse always possible** (revert = git; every schema change ships with `rebuild` compatibility).
- **The JUDGE surface is not editable by anything autonomous:** verifier, held-out generator, gate constants, truth writer, watchdog. If a task seems to require touching them, it stops and surfaces.
- **P1/P2 checks run in CI on every commit:** held-out never in context; every add has an inverse. The red-team regression suite stays green throughout.
- **Every claim a TTL, every event a correlation id, every alarm a firing test.** (The three automaton epitaphs.)
- **Budgets on the builder too:** the autonomous build loop obeys the same layered stop conditions (cycle caps, error caps, spend ceiling) it is building for the learner.
- **When in doubt, NO-GO honestly.** The project's credibility asset is that its negative results are as auditable as its positive ones.

---

*Companion documents, in reading order: `M1-EVAL-PROTOCOL.md` (the pre-registered run design) · `DATA-LAYER.md` §6.1/§6.2 + `reviews/DL-write-discipline-decision.md` (the write discipline + its advisories) · `BUILD-SPECS.md` R1 + B2 Amendment A · `STUDY-automaton-autonomy.md` (autonomy patterns, adopt/avoid) · `STUDY-small-models-for-mdlp.md` (provider picks) · `STUDY-raganything-agentscope-openspace.md` (positioning). The 2026-07-28 audit findings are recorded in this repo's session memory (IX-040) with file:line specifics available on request.*
