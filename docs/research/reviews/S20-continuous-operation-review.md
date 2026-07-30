# 360 Review: S20-continuous-operation — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20 (+ its §12 registration), `docs/research/DATA-LAYER.md` §5 schema delta (`schedule`, `wake_events`, `work_unit_closed`) and §6.1 exemption-list addition |
| Proposed change | Add §20 "Continuous operation — the unattended loop": a two-level supervisor/inner-cycle loop, a truth-backed schedule table reusing §6.1 dispatch/work-unit identity, an ambiguity rule that closes dead-owner attempts as `unknown` and never retries them, one pure budget-tier function with four consumers, layered stop conditions, three liveness signals + external watchdog, and a passive-informing reporting contract — all additive, all JUDGE-side. |
| Reviewer | review-360 |
| Date | 2026-07-30 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Direct review-report write is permitted (not proposal mode).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 58 | weak |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 58 | weak |
| 4 | Implementability | 66 | weak |
| 5 | Safety / integrity (CRITICAL) | 66 | weak |
| 6 | Efficiency / cost | 80 | pass |
| 7 | Completeness | 60 | weak |
| 8 | Consistency | 62 | weak |
| 9 | Calibration / honesty | 72 | pass |

## Findings by dimension

### 1. Correctness

**Blocking-grade ambiguity: the "owner proved dead ⇒ `unknown`, never retried" rule and §6.1's "no terminal record ⇒ resume" rule fire on the identical observable state, with no stated predicate separating them.**

- ALGORITHM §20.2, ALGORITHM-v0.2-pathway-learner.md:607: "each fire is an ordinary §6.1 `dispatch` → `open_work_unit` — the schedule machinery inherits occurrence identity, idempotent minting, and **resume-from-truth wholesale**."
- The very next bullet, ALGORITHM-v0.2-pathway-learner.md:608: "an attempt whose owner is proved dead **with no terminal record** is closed as `unknown` — and is **never auto-retried**."
- DATA-LAYER.md:184 (§6.1 step 3, "Recover by reading truth, never by re-deriving"): "on restart, the orchestrator scans truth for both kinds of orphan: **work units with no terminal eval record (resume: same `occurrence_id`, same pinned items)** and `dispatch` rows with no `work_unit_opened` row yet."

Both rules key off exactly "a work unit with no terminal record." §6.1 says: resume it. §20.2 says: if the owner is dead, close it `unknown` and never resume it. The text never states the predicate that routes a given orphaned work unit to one path or the other — e.g. "the same restarting process may resume its own orphans; only an *externally detected* dead owner triggers the ambiguity rule" is a plausible reconciliation, but it is nowhere written, and nothing in the schema encodes "same process" vs. "externally detected foreign owner." This is exactly the load-bearing double-count-protection boundary (§20.2 calls the ambiguity rule itself "load-bearing"), so an implementer has to *invent* the missing predicate, and either choice they invent has a failure mode: read it narrowly (only cron/scheduled fires get the ambiguity treatment, ordinary §6 loop work units always resume) and you've silently introduced a second, undocumented rule; read it broadly (any dead-owner orphan, scheduled or not, goes to `unknown`) and you've quietly *overridden* §6.1's resume-from-truth for the general case, contradicting §20.2's own "inherits … resume-from-truth wholesale."

**No schema mechanism backs "owner proved dead."** The DATA-LAYER §5 delta gated under §20 adds `schedule`, `wake_events`, and the `work_unit_closed` event kind — it does **not** add any TTL, heartbeat, or claim-timestamp column to `work_unit_opened` (DATA-LAYER.md:145: `work_unit_opened(occurrence_id, agent_id, episode_id, suite_id, attempt_idx, intent_key UNIQUE, item_ids, ts)` — unchanged). Yet §20.6 (ALGORITHM-v0.2-pathway-learner.md:629, the claims rule) asserts: "§6.1 work units and §20.2 schedules **satisfy it** [carry a TTL or a liveness probe]." No field or mechanism in the reviewed delta makes that true at the work-unit grain; the "liveness probe" can only plausibly be the *process*-level three-signal mechanism (§20.6), which would mean "owner proved dead" is a property of the whole supervisor process, not of an individual claim — a materially different (and unstated) semantics than "every claim … carries a TTL."

This is fixable with one clarifying paragraph plus (if the process-level reading is intended) an explicit statement that work-unit "ownership" is inherited from the owning process's liveness signal, not a per-row field — but as written it is a genuine logical gap in the single most safety-critical new mechanism in §20.

Everything else checked — the exponential backoff `s_idle·2^k` (ALGORITHM-v0.2-pathway-learner.md:621), the `w_dead` continuous-zero debounce (line 617), the tier-thresholds-as-a-total-function framing (line 616), the missed-backlog collapse-to-one-catchup (line 606) — is internally consistent arithmetic/logic; no sign error found there.

### 2. Design faithfulness

Genuinely additive in structure and matches the established §13/§14/§15/§17/§19 pattern (opening italic disclaimer stating "no §1–§19 mechanism changes," provenance line, JUDGE-extension via §17.1 rather than a new boundary). ALGORITHM-v0.2-pathway-learner.md:597 correctly states "§6 inner loop, the §8/§19 gates, and every §17.1 JUDGE boundary are consumed as-is." §20.1 (line 602) explicitly places "the supervisor shell … JUDGE-side (§17.1 extension, §20.8)" — the same extension move §19.4 used ("JUDGE, not SOLVE," ALGORITHM-v0.2-pathway-learner.md:572). The §20.2 decision to route scheduled work through the existing §6.1 `dispatch`/`open_work_unit` machinery rather than invent a parallel lease system is the correct, minimal-surface design choice and is stated as a deliberate rejection of "a second lease system" (line 607) — consistent with P2 (don't duplicate a mechanism that already does the job). No divergence found from the §§2–15 layering or naming conventions.

Minor deduction: unlike every other DATA-LAYER delta since §17.6/§18.1 (which explicitly add a constant-valued `agent_id` fleet key to new tables in anticipation of M3, e.g. DATA-LAYER.md:145 `lineage(checkpoint_id, parent, dataset_id, eval_run_id, agent_id)`), the new `schedule` and `wake_events` tables carry **no** `agent_id` column at all — a departure from the convention the project itself established (see Consistency, below).

### 3. Red-team resistance

- **New instance of the RC-1/measurement-independence failure class (not a numbered RC, but the same family the §6.1 write-discipline gate was built to close).** The Correctness finding above is precisely a double-count/evidence-integrity ambiguity — the exact defect class the DL-write-discipline gate caught twice in its own history ("a Beta-posterior under-counting inversion, a silent work-merge hole," per HANDOVER-v3.md:13). Resolving the ambiguity in either direction risks either double-counting held-out evidence (if an implementer treats a genuinely-dead foreign owner's orphan as safely resumable) or perpetual manual-escalation starvation (if every ordinary restart is conservatively routed to `unknown`, defeating "unattended").
- **RC-7-adjacent risk, not fully closed: gate-posture deferral vs. the §5.3 coverage floor.** §20.4(c) (ALGORITHM-v0.2-pathway-learner.md:616): "at `degrade` or below, the learner *defers* marginal self-modification/expansion actions." §5.3's coverage floor (ALGORITHM-v0.2-pathway-learner.md:161,171) is the RC-7 fix for weak-spot calcification ("every admitted skill is practiced at rate ≥ `f_min` regardless of learning progress"). §20 never states whether "expansion actions" is scoped to exclude §5.3's floor-driven practice — a charitable reading (expansion = §5.1 growth / §17 self-modify only) is plausible but not asserted, and §20.5's layered stop conditions (line 620) do not include a check for "has floor-driven practice been suppressed by sustained low tier." Not a reintroduction of RC-7 as written, but an unclosed path to one under a plausible reading.
- **RC-4-adjacent, minor: no inverse for the new `schedule` table.** P2 requires every `add` to have an inverse (merge/prune/decay, §5.1; retention windows, §6.1/§17.6/§10). §20.2 gives schedule rows an `enabled`/`state` flag but no retirement/GC path or retention window for stale/one-shot-completed rows, nor for `wake_events` (no analog of `rejected_ingest`'s `w_rejected` retention). Small in absolute terms (admin rows are cheap and the project's convention is "rows permanent, blobs prunable" — DATA-LAYER.md:192,227) but it is a gap relative to the section's own P2 framing elsewhere in the spec.
- What holds: JUDGE immutability is correctly extended (§20.8), the gate-posture rule is explicitly monotone ("the §8/§19 bars themselves never move; scarcity postpones, never loosens," line 616) which correctly forecloses RC-1-style gate self-relaxation, and the self-preservation check (line 610) directly closes the automaton study's cautionary example.

### 4. Implementability

- The `dispatch` event schema (DATA-LAYER.md:145) requires `(agent_id, episode_id, suite_id, action_fingerprint, seq)`. §20.2 says a schedule fire is "an ordinary §6.1 `dispatch`" but never states how a `schedule_id` (a schedule row's own identity) maps onto that tuple — no `schedule_id` field exists anywhere in the `dispatch` schema, yet DATA-LAYER §11.2's own correlation-id invariant (DATA-LAYER.md:319) names `schedule_id` as a first-class correlation key alongside `occurrence_id`/`checkpoint_id`. A developer has to invent where `schedule_id` is carried (folded into `action_fingerprint`? a new payload field?) — not specified.
- Non-eval scheduled jobs (maintenance sweeps, retraining triggers, digest emission) may have no natural `suite_id`/`action_fingerprint` the way an ordinary §6 SELECT/EXPAND action does. §20.2 doesn't address this mapping gap for infrastructural (non-learning) scheduled work.
- The tier enum `{ample, degrade, critical, dead}` (line 616) is compared via "above/below the current tier" (schedule suppression, line 616(b)) without ever stating it as an explicitly ordered, machine-checkable enum — implied but not declared.
- The exponential idle-backoff counter `k` (line 621, `s_idle·2^k`) has no stated reset condition — does a single successful cycle reset `k` to 0, or does it decay? This materially changes post-scarcity recovery behavior and is left to the implementer.
- §20.7's passive-informing contract doesn't state whether generating the human-facing digest content requires an LLM call (a new, unbudgeted inference cost) or is purely templated from structured event data — ambiguous, and the section is otherwise careful about cost (§16, §17 name budgets explicitly for their own new calls).

### 5. Safety / integrity

No existing gate is weakened: §8's four-clause conjunction, §14's calibration layer, §19's self-calibrating gate, and the §17.1 JUDGE partition are all explicitly untouched, and §20.4's gate-posture consumer is stated as monotone-only ("never loosens"). The supervisor/scheduler/tier-enforcer/watchdogs/delivery ledger are correctly placed in JUDGE (§20.8, line 634).

Score held below the CRITICAL 70 bar because the Correctness finding is itself an integrity question: §20.2's ambiguity rule exists *specifically* to protect the evidence-integrity invariant DATA-LAYER §6.1 was built and re-gated many times to establish (no double-counted held-out evidence). A new mechanism whose own boundary condition is undefined is a genuine, not cosmetic, integrity gap — the exact category this dimension exists to catch. Additionally: `work_unit_closed` is stated to be "written only by the recovery scan after the owner is proved dead" (DATA-LAYER.md:188) and §20.8 places "the supervisor shell, scheduler, budget/tier enforcer, watchdogs, and delivery ledger" in JUDGE, but unlike §17.6's version log ("It is JUDGE-owned: SOLVE has no write-path (§17.1)," DATA-LAYER.md between lines 483–501) there is no equivalent explicit sentence stating `schedule`/`wake_events`/`work_unit_closed` have no SOLVE write-path, nor a named test for it (see Completeness).

### 6. Efficiency / cost

No new LLM calls are introduced by the mechanism itself (schedule scan, wake-event polling at `s_poll` = 30s default, tier computation) — this is pure orchestration over existing stores, consistent with the section's framing as liveness machinery, not a learning mechanism. No O(n²) additions to the hot path; the schedule scan and wake-queue drain are bounded by row count and drained-at-entry (line 613), matching the automaton study's adopted pattern. The one open question (digest-content generation possibly requiring an LLM call, noted under Implementability) is the only unaccounted-for cost path; if it turns out to require one, it's unbudgeted in §12/§20.9's parameter list.

### 7. Completeness

- No test in §20.9's list (ALGORITHM-v0.2-pathway-learner.md:638-639) verifies the load-bearing "gate posture never loosens the §8/§19 bars" claim (line 616), unlike the direct precedent §19.7's `test_each_knob_only_stricter_than_§8` (line 590) for the analogous self-calibrating-gate invariant. Also missing: a test for tier-function purity/totality, and a test for the replenish-cooldown (`t_replenish`) behavior.
- No test analogous to §17.5's `test_self_modify_cannot_write_JUDGE` exists for the new JUDGE surfaces — nothing verifies SOLVE cannot write `schedule`, `wake_events`, or `work_unit_closed`.
- No retention/GC policy stated for `schedule` or `wake_events` rows (see Red-team, RC-4-adjacent finding).
- The idle-backoff counter's reset condition (Implementability) is an edge case left unhandled.
- Positive: the checks that do exist are well-targeted and each is backed by mechanism text in §20.1–§20.8 (verified one-by-one: `test_supervisor_never_exits_on_error` ← §20.1; `test_at_most_once_crash_costs_one_occurrence`/`test_missed_backlog_single_catchup` ← §20.2; `test_unknown_read_degrades_not_dies`/`test_dead_requires_continuous_window` ← §20.4; `test_budget_exhaustion_distinct_signal` ← §20.5; `test_wake_drained_at_entry` ← §20.3; `test_watchdog_fires_on_synthetic_stall`/`test_every_claim_has_ttl_or_probe` ← §20.6; `test_failure_always_delivered`/`test_silence_marker_no_false_positive` ← §20.7). No orphan tests found.

### 8. Consistency

- **§12 vs. §20.9 parameter registration: consistent.** §12's added-section line (ALGORITHM-v0.2-pathway-learner.md:286: "§20 `c_max` (cycle tick ceiling), `s_cycle`, `s_poll`, `e_max`, `s_err`, `s_idle`/`s_idle_max`, `w_dead` …, `t_replenish`, `τ_stale` …, per-deployment tier thresholds, per-kind lease TTLs. … §20 dials at M-R.") matches §20.9's parameter list (line 638) exactly, term for term. No missing registrations.
- **Schema convention break:** every other DATA-LAYER delta since §17.6/§18.1 threads a fleet-scoping `agent_id` column through new tables even when currently a constant (DATA-LAYER.md:145, e.g. `lineage(…, agent_id)`, `dispatch{agent_id, …}` — explicitly justified as "mirroring §18.1's per-agent StateStore keying; single-agent default is a constant"). The new `schedule(schedule_id, kind, expr, next_run_at, tier_minimum, enabled, state)` and `wake_events(id, payload, ts, consumed_ts)` tables carry **no** `agent_id` column at all (DATA-LAYER.md:145) — an inconsistency with the project's own established forward-compatibility discipline, one that will require a schema migration when M3/fleet (§18) lands, exactly the kind of cost the `agent_id`-everywhere convention was adopted to avoid.
- **The wholesale-resume vs. ambiguity-rule tension** (Correctness §1) is also, at bottom, an internal-consistency defect: two adjacent sentences in the same subsection (§20.2) make claims that are hard to reconcile without an unstated distinguishing predicate.
- Otherwise consistent with §10 (data architecture), §6.1/§6.2 write discipline, and §11 (ObservabilityPort graceful degradation, correctly cited at line 632).

### 9. Calibration / honesty

Provenance is stated cleanly and honestly: "the liveness patterns are the verified adopt-lists of two studied production systems … including their failure modes as explicit anti-requirements; the measurement discipline is ours" (ALGORITHM-v0.2-pathway-learner.md:597) — appropriately modest, doesn't overclaim originality. The section states plainly what it does and doesn't change. Docked below "strong" because, unlike §17.6 (which includes an explicit "Honest scope" paragraph naming the residual risk of its own reactivation-and-revalidation mechanism: "this narrows RC-6's stale-fallback exposure to the concurrent-check window … it does not close it — the residual is the price of never serving zero validated SOLVE," DATA-LAYER-adjacent text in ALGORITHM-v0.2-pathway-learner.md), §20 offers no equivalent caveat for its own least-settled mechanism (the ambiguity rule / owner-proved-dead boundary) — the section reads as fully resolved where a genuine open question exists. A brief "the owner-proved-dead predicate and its interaction with ordinary restart-resume needs stress-testing before M-R" sentence would have been the honest, in-house-precedented thing to write.

## Strongest adversarial objection

**A sustained mid-tier budget state creates a new "looks alive, silently stopped learning" failure mode that none of §20.5's layered stop conditions is positioned to catch.**

Suppose the budget signal sits in `degrade` or `critical` indefinitely — never reaching the continuous-zero `w_dead` window that would trigger the `dead` tier and its explicit escalation (§20.4, line 617), but never recovering to `ample` either (a very plausible steady state under a tight but non-zero budget). Under §20.4(c) (line 616), the gate-posture consumer "defers marginal self-modification/expansion actions" for as long as the tier stays low. If "expansion" is read to include §5.1's growth step `g.step` (the natural reading — HANDOVER-v3.md:38 literally calls this gap "the autonomy layer … tier-based degradation" and treats growth/self-modification as the things degraded), then the system could run forever with heartbeats green, no errors, and even "progress" in the narrow sense that existing skills keep getting practiced (so the §20.5.3 no-progress backoff never fires, since it triggers only on "no gated commit *and* no new evidence recorded" — ordinary practice commits still happen) — while never provisioning a new skill, never running a self-modify candidate, and never exercising §9's promotion review. This is invisible to every stop condition in §20.5: `c_max` and `e_max` don't apply (no errors), the no-progress backoff doesn't fire (ordinary commits are still landing), budget-exhaustion-as-distinct-signal doesn't fire (the budget isn't exhausted, just chronically thin), and the §14/§19.6 breakers watch calibration and gate-regression, not growth cadence. The three liveness signals (§20.6) would all report healthy. The result is exactly the class of failure the automaton study's avoid-list A2 warned about ("a stuck agent that looks alive") and the passive-informing contract (§20.7) is not designed to surface, because nothing in §20 treats "growth/self-modification has been suppressed for N cycles by gate posture" as a distinct, loggable, alertable condition — there is no `growth_suppressed_ts` analog to `last-success stamp`. This sits one level below every dimension scored above: it isn't a bug in any single mechanism, it's an emergent gap in the *composition* of the tier function's gate-posture consumer with the layered-stop-conditions list, and it would only surface in a long unattended run — exactly the scenario M-R (the milestone §20 exists to serve) is designed to run.

## Aggregate confidence

```
critical_floor  = min(58, 58, 66) = 58
weighted_mean   = (58*2 + 84 + 58*2 + 66 + 66*2 + 80 + 60 + 62 + 72) / 11
                = (116 + 84 + 116 + 66 + 132 + 80 + 60 + 62 + 72) / 11
                = 788 / 11
                = 71.6
overall         = min(58, 71.6) = 58
```

**Overall confidence: 58 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to lift all CRITICAL dimensions ≥ 70):

1. **Resolve the ambiguity-rule / resume-from-truth conflict (§20.2).** State explicitly the predicate that routes an orphaned work unit to "resume" (§6.1) vs. "close as `unknown`, never retry" (§20.2) — e.g., own-process restart vs. externally-detected dead owner — and reconcile it with the "inherits resume-from-truth wholesale" claim in the same subsection. Add the schema/mechanism that makes "owner proved dead" checkable (a TTL/heartbeat field on `work_unit_opened`, or an explicit statement that ownership liveness is inherited from the process-level three-signal mechanism in §20.6, not a per-row field).
2. **Add a test for the boundary in (1)** — something like `test_own_restart_resumes_vs_foreign_dead_owner_marks_unknown` — so the distinction is enforceable, not just prose.
3. **State explicitly whether §20.4's gate-posture deferral scope includes or excludes §5.3's coverage-floor practice**, and add a distinct, loggable/alertable signal for "growth/self-modification suppressed by gate posture for N cycles" so a sustained mid-tier budget state cannot silently starve learning while every existing liveness/stop-condition check reports healthy (the adversarial-pass finding).
4. **Add the missing `agent_id` column to `schedule` and `wake_events`** (DATA-LAYER §5), matching the forward-compatibility convention every other post-§17.6 delta follows, to avoid a forced schema migration at M3.
5. **Add tests for the two other untested load-bearing invariants:** gate-posture-never-loosens, and SOLVE-has-no-write-path to `schedule`/`wake_events`/`work_unit_closed` (parallel to `test_self_modify_cannot_write_JUDGE`).
6. **Specify the `schedule_id` → `dispatch(action_fingerprint, seq)` mapping** for scheduled fires, and state whether non-eval infrastructural scheduled jobs (that lack a natural `suite_id`) are in scope for §20.2's "ordinary §6.1 dispatch" reuse or need a documented exception.
