# 360 Review: S20-continuous-operation — round 3 — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20 "Continuous operation — the unattended loop" (marked *revised r3*, lines 595–645), + its §12 registration (line 286), + `docs/research/DATA-LAYER.md` §5 schema delta (line 145: `schedule`, `wake_events`, `work_unit_closed`, `owner`/`lease_expires_at` on `work_unit_opened`, `schedule_id?` on `dispatch`) |
| Proposed change | Round-3 fix set: (1) the recovery predicate restated as a four-way rule (RESUME / `unknown` / LEAVE / no-op) with an explicit exhaustiveness partition and a supervisor-singleton lease closing the restart race; (2) `h_lease`/`g_lease` (heartbeat cadence + proved-dead grace, default `2·h_lease`) registered in §12 and §20.9; (3) tier-posture deferral scope enumerated (`self_modify`, growth splits, B3 transfers only — §5.3 floor and due B4 reviews never deferred); (4) non-eval scheduled jobs given a reserved `suite_id="maintenance"` + empty `item_ids` path with administrative-only outcomes |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Prior rounds | `docs/research/reviews/S20-continuous-operation-review.md` (round 1, overall 58/100) → `docs/research/reviews/S20-continuous-operation-review-r2.md` (round 2, overall 75/100, all criticals ≥70, needs-revision) |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Direct review-report write is permitted (not proposal mode).

## Round 1–2 closure ledger (verified against the r3 text)

| # | Item (source round) | Status at r3 | Evidence |
|---|---|---|---|
| 1 | Fourth reachable recovery state — owner determinately alive, no disposition (r2 blocking #1) | **Substantially closed, one residual textual gap** | ALGORITHM-v0.2-pathway-learner.md:608–613 states a four-way, "disjoint AND exhaustive by construction" rule; bullet 3 (line 611, LEAVE) and `test_owner_alive_left_running` (line 645) give the alive state a disposition and a test. See Correctness §1 below for the residual: the operative bullets (609–612), read literally, are **not** manifestly disjoint for the `alive ∧ ¬reconstructable` cell — only the compressed partition sentence (613) resolves it, and it does so by unstated precedence. |
| 2 | Two unparameterized safety-relevant quantities: lease-expiry grace, heartbeat cadence (r2 blocking #2) | **Closed for the named quantities; a new, larger instance of the same defect introduced by this round's own fix** | `h_lease`/`g_lease` now registered in both §20.9 (line 644) and §12 (line 286), with `g_lease` defaulted to `2·h_lease`. But the round's own new mechanism — **the supervisor singleton lease** (line 611) — is itself an unparameterized claim with no named TTL, no schema, and no renewal cadence anywhere in §20.9, §12, or DATA-LAYER §5. See Correctness §1 / Safety §5 / adversarial pass. |
| 3a | Tier-posture deferral scope vs. §5.3 coverage floor (r2 half-closed) | **Closed, cleanly** | ALGORITHM-v0.2-pathway-learner.md:622, "Scope (r3)": `self_modify` (§17), growth splits (§5.1), B3 transfers only; "the §5.3 coverage floor and due B4 reviews are never deferred by tier posture" — consistent with §5.3 (line 161, `enforce_coverage_floor` runs inside ordinary `choose`, not a distinct expansion action) and with B4's own design (BUILD-SPECS.md:110–136, due reviews merged into the Tutor's `choose`, not a `schedule` row) and with the §18.2 floor-dominance phrasing it explicitly echoes (line 530, "Floor dominates (RC-7)"). `test_tier_posture_never_defers_coverage_floor` added (line 645). No gap found. |
| 3b | Non-eval scheduled jobs without a `suite_id` (r2 half-closed) | **Closed for the mechanism; one minor collision-guard gap remains** | Line 607: reserved `suite_id = "maintenance"`, empty `item_ids`, administrative-only outcomes, §6.1 record-class boundary unchanged; `test_maintenance_units_move_no_posterior` added. `suite_id` in `dispatch`/`work_unit_opened` (DATA-LAYER.md:145) remains a plain string field, so no schema change was needed — a legitimate minimal-surface fix. Gap: nothing reserves the literal string `"maintenance"` against collision with a real eval suite name (see Implementability). |
| 4 | Idle-backoff counter `k`'s reset condition (r2 Implementability, not in the round-3 task's "left" list but still an open r2 finding) | **Not addressed, not explicitly deferred** | ALGORITHM-v0.2-pathway-learner.md:627 is textually unchanged from r2 (`s_idle·2^k`, capped at `s_idle_max`) — no statement of what resets `k` to 0. Carried over silently. |
| 5 | Test for `owner{pid, started_at}` PID-reuse guard (r2 Verdict item 5) | **Not addressed, not explicitly deferred** | No test in the line-645 list references `started_at`/PID-reuse; `test_owner_alive_left_running` and `test_supervisor_singleton` are new but neither exercises a reused-`pid`-with-mismatched-`started_at` case. Carried over silently. |
| — | Tier enum not declared as an explicit ordered type (r2 Implementability) | **Not addressed, not explicitly deferred** | Line 622 still presents `tier(budget_state) ∈ {ample, degrade, critical, dead}` as a set with ordering only implied by "above/below the current tier." |
| — | Digest content: LLM call or templated? (r2 Implementability) | **Not addressed, not explicitly deferred** | Line 638 unchanged. |

**Net:** the three items the round-3 task frames as "ALL now addressed" (fourth state, lease parameters, tier-scope + non-eval-jobs) are genuinely, substantively closed for the *named* gaps — this is real progress, and 3a in particular is a clean, well-grounded fix. But (a) the fourth-state fix's own mechanism (the supervisor singleton lease) reintroduces an unparameterized-claim defect of the same *kind* as item 2, at a larger scope (no schema at all, vs. merely no named default); (b) two of round 2's five originally-blocking items (idle-backoff reset, PID-reuse test) remain neither closed nor explicitly deferred — they are silently absent from this round's scope, and the round's own framing ("ALL are now addressed") overstates closure against the full r1/r2 record, not just the three items it chose to re-litigate.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 75 | pass |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 74 | pass |
| 4 | Implementability | 66 | weak |
| 5 | Safety / integrity (CRITICAL) | 72 | pass |
| 6 | Efficiency / cost | 79 | pass |
| 7 | Completeness | 76 | pass |
| 8 | Consistency | 74 | pass |
| 9 | Calibration / honesty | 70 | pass |

## Findings by dimension

### 1. Correctness

**The core r2 gap is genuinely improved.** Lines 608–613 now state a four-way rule and, unusually, back the disjointness claim with an explicit partition-membership sentence (line 613): "terminal ⇒ 4; alive ⇒ 3; proved-dead ∧ reconstructable ⇒ 1; anything else ⇒ 2." Checking this against the full space of non-terminal states {alive, proved-dead, undeterminable} × {reconstructable, unreconstructable} (6 cells) plus the terminal axis: this partition **is** exhaustive and disjoint as a compressed table — `proved-dead ∧ unreconstructable` correctly falls into "anything else ⇒ 2" (`unknown`), and `alive ∧ unreconstructable` is correctly assigned to bucket 3 (LEAVE) by this summary sentence's unconditional "alive ⇒ 3" rule. Both specific cells the round asked me to check are covered *by the summary table*.

**But the operative prose the rule is actually presented as (lines 609–612) does not itself establish this disjointness — it is only rescued by line 613's separate, compressed restatement.** Bullet 2 (line 610, `unknown`) reads: "owner liveness **undeterminable** … **∨ the unit is unreconstructable**" — the second disjunct is stated with no qualification on owner liveness at all. Bullet 3 (line 611, LEAVE) reads: "the lease is being heartbeat-refreshed and the owner answers its liveness probe ⇒ the unit is *running*" — also unqualified on reconstructability. Read as an unordered disjunction (which is how "every open work unit resolves to exactly one of:" at line 608 presents the four bullets — no stated precedence), the cell `alive ∧ ¬reconstructable` satisfies **both** bullet 2's "unreconstructable" disjunct and bullet 3's "alive" condition. The rule is only single-valued if bullet 3 (or "alive" as a category) is read as taking silent precedence over bullet 2 — which is exactly what line 613's compressed table asserts, but that precedence is never stated as a rule in the four bullets themselves. This is a narrower, second-order instance of the same defect class round 1 and round 2 both found: **the artifact's summary claim of exhaustiveness/disjointness is correct, but the literal specification a developer would implement from is not manifestly disjoint without inferring an evaluation order that is stated only in the summary, not the rule.** A literal, order-naive implementation of bullets 1–4 could resolve `alive ∧ ¬reconstructable` to `unknown` (closing a work unit whose owner is still actively running it) rather than LEAVE — the opposite of the intended, safe behavior, and a case `test_owner_alive_left_running` (line 645) does not obviously exercise, since that test's own description ("an alive-owner unit is untouched by the scan") does not specify whether the fixture also has a corrupted/unreconstructable dispatch row.

**New: §20.1 and §20.2 make an unreconciled, contradictory claim about supervisor exit behavior.** Line 602 (§20.1, unchanged since round 1): "Every failure path becomes a timed sleep and re-entry — **the supervisor never exits** (process death only, and that is the external supervisor's problem, §20.6)." Line 611 (§20.2, new in r3): the supervisor singleton lease — "a starting instance that cannot acquire it does not run cycles (**waits for expiry or exits**)." These two sentences, three sections apart in the same document, make incompatible universal-vs-particular claims: §20.1 states an unconditional design invariant ("never exits… process death only"), while §20.2's new fix explicitly offers "exits" as one of two normal, non-crash behaviors for a losing supervisor instance. Neither sentence scopes itself against the other (e.g., "except at singleton-lease acquisition, which is pre-loop and not a 'failure path'"). This is a genuine, citable internal contradiction introduced by the r3 fix itself, not a restatement of a prior finding.

Unaffected from prior rounds and re-verified sound: `w_dead` continuous-zero debounce (line 623), `s_idle·2^k` backoff form (line 627), `g_lease = 2·h_lease` default (line 644) — no sign error or malformed inequality found in any restated formula.

### 2. Design faithfulness

The three closed items (recovery predicate, tier scope, maintenance jobs) are faithful, minimal-surface extensions in the same idiom as r2's well-regarded fixes (reuse of `suite_id` rather than a schema change for maintenance jobs; reuse of the §5.3/§18.2 "floor dominates" phrasing for tier scope). One new divergence: §20.2 states, as a design principle, "**No second lease system**" (line 607, referring to schedule fires reusing the §6.1 work-unit lease rather than inventing a parallel timer/lease mechanism) — but the very same section's fourth-state fix (line 611) introduces exactly that: a **second, structurally distinct lease** (protecting the supervisor process itself, not a work unit), with no stated relationship to the §6.1 `work_unit_opened.owner/lease_expires_at` pattern, no TruthStore row, and no schema delta. This is not a large divergence, but it is a real one: the fix does not follow the "no second lease system" discipline the surrounding prose asserts as a virtue, and does not explain why the supervisor lease is exempt from that discipline.

### 3. Red-team resistance

- **RC-1 / measurement-independence reasoning (resolved in r2) is unaffected and still sound** — the RESUME-safe-because-of-identity / `unknown`-conservative-because-of-side-effects distinction (lines 609–610) is untouched by r3.
- **RC-7 scoping (half-closed in r2) is now fully closed and well-grounded** (line 622, tier-scope enumeration verified against §5.3 and B4 above) — real progress, no residual RC-7 exposure found in the deferral mechanism itself.
- **New: the unparameterized supervisor lease reintroduces, at a different layer, the "claimed-but-unexpirable state" class the section's own claims-rule invariant exists to forbid.** Line 635 (unchanged text): "every claim, lease, or in-flight marker in the system carries a TTL or a liveness probe — no claimed-but-unexpirable state, ever. (§6.1 work units and §20.2 schedules satisfy it; the rule binds all future additions.)" The supervisor singleton lease is a brand-new lease/claim, introduced two paragraphs earlier in the very same round, and it is **not named among the invariant's satisfying examples**, has no described TTL, and has no described storage (TruthStore row, Redis lock, file lock — unstated). This is precisely the failure category `STUDY-automaton-autonomy.md:52` ("AUT-4 — claims audit: verify every claimable state … carries a TTL/liveness probe") was adopted to close, and the invariant's own text ("the rule binds all future additions") makes this lease a **counter-example to a rule this very section states as binding on itself**, in the same revision that adds the lease.
- **RC-4-adjacent (no retention/GC for `schedule`/`wake_events`):** unchanged from rounds 1–2, still open, still non-blocking.
- What holds, reconfirmed: JUDGE immutability extended correctly (line 641), gate-posture monotonicity preserved and tested (`test_gate_posture_defers_never_loosens`), self-preservation check unchanged (line 616, matches `STUDY-hermes-agent.md:29`'s adopted anti-pattern).

### 4. Implementability

Real, closed wins alongside a comparably-sized new gap.

- **Closed:** tier-posture scope (line 622) and the maintenance-job dispatch path (line 607) are both now concrete enough to build without guessing.
- **New gap, larger than what it replaces:** the supervisor singleton lease (line 611) is described in one clause — "a starting instance that cannot acquire it does not run cycles (waits for expiry or exits)" — with **no answer to any of**: where does the lease live (a new TruthStore table? a Redis/file lock? an existing table reused)? what is its TTL, and is it heartbeat-refreshed like `lease_expires_at` (line 609), or a fixed duration? does a losing instance retry on a poll cadence (`s_poll`, line 619) or a separate one? does "waits" vs. "exits" depend on a stated condition, or is it implementation's free choice? None of these are answered, and none of `c_max`/`s_cycle`/`s_poll`/`e_max`/`s_err`/`s_idle`/`s_idle_max`/`w_dead`/`t_replenish`/`τ_stale`/`w_defer`/`n_defer`/`h_lease`/`g_lease` (the full §20.9 parameter list, line 644) names anything for it.
- **Still open from round 2, silently carried over (see closure ledger):** idle-backoff reset condition, tier enum not declared as an ordered type, digest-content LLM-call question.
- **New, minor:** `suite_id = "maintenance"` (line 607) is a reserved literal string with no stated enforcement preventing a real eval suite from being named `"maintenance"` — no namespace guard, no admission check analogous to the ones §17.1/§17.6 apply elsewhere in this document for reserved identifiers.
- **Minor:** `test_recovery_predicate_three_way`'s name and its own inline description at line 645 ("proved-dead+reconstructable ⇒ resume … undeterminable-or-unreconstructable ⇒ `unknown` … terminal ⇒ no-op") still describe only **three** outcomes and were not renamed/updated to reflect the section's new "one four-way rule" framing (line 608) — the fourth (LEAVE) outcome is covered by the separately-added `test_owner_alive_left_running` instead, so functionally nothing is untested, but the two tests' names/descriptions no longer match the section's own self-description of a single four-way rule.

### 5. Safety / integrity

**CRITICAL.** Mixed: the three named fixes are real safety improvements, but the fix that was supposed to finally close the concurrent-executor risk introduces a new, unmechanized safety-critical claim.

- **Improved:** RESUME/`unknown`/terminal are now joined by an explicit LEAVE disposition with a test (`test_owner_alive_left_running`), closing the worst reading of round 2's gap (an alive owner's unit being silently eligible for a second dispatch).
- **New concern, safety-relevant:** the mechanism stated to be the actual closer of the supervisor-restart race — "the supervisor itself holds a singleton lease" (line 611) — is the **sole named barrier** against two supervisor processes running cycles over the same work concurrently, and it is specified with less rigor than the mechanism it supersedes (the §6.1 `owner{pid, started_at}` + `lease_expires_at` pattern, which has a schema, a heartbeat parameter, and a grace parameter). A safety property whose only textual support is "a starting instance that cannot acquire it does not run cycles" — with the lease's own TTL, storage, and renewal entirely unstated — is asserted, not demonstrated, in a section whose own invariant (line 635) requires exactly the opposite: that every claim carry a stated TTL or probe.
- **Also safety-relevant:** the Correctness §1 finding that the *operative* bullets (609–612), read without appeal to line 613's summary, could route `alive ∧ ¬reconstructable` to `unknown` (forced closure) rather than LEAVE — an implementation following the letter of 609–612 over the compressed 613 formula could closed a work unit whose owner is still writing to it, which is exactly the double-terminal/evidence-corruption risk category the whole recovery-predicate mechanism exists to prevent.
- Unaffected, reconfirmed: §20.8's JUDGE-ownership statement (line 641) and `test_solve_cannot_write_schedule_or_closures` remain adequate; the coverage-floor-never-deferred guarantee (line 622, `test_tier_posture_never_defers_coverage_floor`) is a genuine, testable safety improvement over r2.

### 6. Efficiency / cost

No new LLM calls. The singleton-lease check is an O(1) claim-acquisition test at supervisor startup, consistent with the section's orchestration-only cost profile. The `suite_id="maintenance"` path adds no new write pattern (reuses `dispatch`/`work_unit_opened`/`work_unit_closed`). No new complexity class introduced anywhere in the r3 delta.

### 7. Completeness

Four new tests genuinely close four gaps: `test_owner_alive_left_running`, `test_supervisor_singleton`, `test_tier_posture_never_defers_coverage_floor`, `test_maintenance_units_move_no_posterior` (all line 645). Residual and new gaps:

- No test for the supervisor lease's own TTL/expiry behavior (only for the mutual-exclusion property — `test_supervisor_singleton` verifies "a second supervisor instance acquires no cycles while the first's lease is live," not what happens when the first's lease should have but did not expire, or how quickly a waiting instance re-polls).
- No test for the `alive ∧ ¬reconstructable` cell identified in Correctness §1.
- No test for `owner{pid, started_at}` PID-reuse guarding (carried over from r2, unaddressed).
- No test/policy for idle-backoff reset (carried over, unaddressed).
- No retention/GC test for `schedule`/`wake_events` (carried over from rounds 1–2, still non-blocking).
- No test guarding the `suite_id="maintenance"` reserved-string namespace against collision with a real eval suite.

### 8. Consistency

- **New contradiction:** §20.1 ("the supervisor never exits… process death only," line 602) vs. §20.2 ("a starting instance … waits for expiry **or exits**," line 611) — see Correctness §1.
- **New gap:** the claims-rule invariant (line 635) explicitly lists its own satisfying examples ("§6.1 work units and §20.2 schedules satisfy it") but was not updated to include the supervisor singleton lease introduced two lines earlier in the same section — the invariant's own text ("the rule binds all future additions") is now inconsistent with the fact that its most recent addition is not shown to satisfy it.
- **New gap:** `test_recovery_predicate_three_way`'s name/description (line 645) still describes a three-way rule, inconsistent with the section's own "one four-way rule" framing (line 608) introduced in this same revision.
- §12 (line 286) vs. §20.9 (line 644) remain consistent term-for-term for every *named* parameter — but the supervisor lease is absent from both, so the lists are consistent with each other while both being incomplete relative to the mechanism as specified (the same shape of gap r2 found for `grace`/heartbeat cadence, now recurring one layer up).
- Otherwise consistent with §10, §6.1/§6.2 write discipline, and §11's ObservabilityPort framing (line 638) — the tier-scope fix (line 622) is a genuine consistency improvement, correctly cross-referencing §5.3 and §18.2's existing "floor dominates" language rather than inventing new terminology.

### 9. Calibration / honesty

Positive: the section continues r2's good habit of naming its own regression history inline — `test_owner_alive_left_running` is explicitly annotated "the r3 fourth-state regression" (line 645), and `test_supervisor_singleton` and `test_tier_posture_never_defers_coverage_floor` are each tied to a specific concern. This is honest, useful self-documentation and continues the pattern noted favorably in round 2.

Docked for two reasons, one carried over and one new:
- (a) **Carried over:** the "one four-way rule … disjoint AND exhaustive by construction" framing (lines 608, 613) is stated with more certainty than the operative prose (609–612) actually establishes without appeal to unstated precedence — the same overclaim pattern round 2 flagged in the three-way framing recurs, in the same location, one round later.
- (b) **New:** the supervisor-restart race is declared "closed one level up" (line 611) with the confident, resolved-sounding language the section reserves for its actually-mechanized fixes (e.g., the §6.1 identity argument) — but the mechanism backing this specific claim is a single under-specified sentence, not a demonstrated, parameterized, schema-backed construct like everything else the section is proud of. Asserting a race is "closed" by a mechanism that itself doesn't satisfy the document's own claims-rule invariant is the calibration failure this review most wants to flag: it is the same shape of overclaim round 1 and round 2 both found in this exact recovery-predicate mechanism, recurring a third time. Additionally, the round-3 framing that "ALL" of round 2's items are now addressed (per the task's own summary) does not hold against the full r1/r2 record — the idle-backoff-reset and PID-reuse-test items are neither closed nor flagged as deferred; a calibrated summary would have said so explicitly.

## Strongest adversarial objection

**Of every mechanism §20 introduces, the supervisor singleton lease is the only one with zero TruthStore footprint — which means it is the only failure mode in this entire section that cannot be diagnosed from Truth, in a section whose central design discipline is "no in-memory timers as source of truth" (line 605) and "every cycle and scheduled run archives its outcome durably" (line 637).**

Grant, for the sake of argument, every fix in this round exactly as intended: the four-way predicate is unambiguous, the singleton lease reliably prevents two supervisors from running cycles concurrently, and no implementer misreads bullet 2 as covering the alive state. Even then, the fix trades a (hypothetical, low-probability) double-execution risk for a **new, unbounded-and-unobservable single point of unavailability**: if the winning supervisor instance dies hard (the exact scenario §20.6 exists to handle — external supervisor restart with backoff, line 632), nothing in the text says how promptly, or via what stated cadence, a second instance re-attempts to acquire the now-releasable lease. It might use `s_poll` (line 619, 30s default — but that queue is `wake_events`, a *different* mechanism); it might busy-loop; it might sleep for an unstated, arbitrary duration. Whichever it is, that behavior is never logged to Truth, because — unlike `schedule` rows, `wake_events`, `work_unit_opened`/`work_unit_closed`, `dispatch`, `selfmod_rejected`, `component_invoked`, and every other claim or lease named in DATA-LAYER §5 (line 145) — the supervisor lease has **no row, no event kind, and no field anywhere in the schema**. The one existing alarm that would eventually notice a stalled system — the external freshness watchdog reading "last-completed-work-unit timestamp from Truth" past `τ_stale` (line 633) — would fire, but only after `τ_stale`'s window elapses, and it would tell a human only "the system is stale," not "no supervisor could acquire the lease" versus "an owner died" versus any other cause the rest of §20 goes to considerable lengths to distinguish (three separate liveness signals, line 630; a distinct four-way recovery predicate; a distinct budget-exhaustion signal, line 627). The section that most prides itself on making every failure mode nameable, testable, and Truth-auditable has, in this very round, added the one mechanism now solely responsible for its core safety property while exempting that mechanism from all three disciplines.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(75, 74, 72) = 72
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (75*2 + 80 + 74*2 + 66 + 72*2 + 79 + 76 + 74 + 70) / 11
                = (150 + 80 + 148 + 66 + 144 + 79 + 76 + 74 + 70) / 11
                = 887 / 11
                = 80.6 → 81
overall         = min(72, 81) = 72
```

**Overall confidence: 72 / 100**

## Verdict

**needs-revision**

Round 2's 75 → round 3's 72 reflects a genuinely mixed outcome, not a regression in effort: the three items the round set out to fix (fourth recovery state, lease parameters, tier-posture scope, non-eval scheduled jobs) are substantively and, in the case of tier-posture scope, cleanly closed. But the mechanism introduced to close the single hardest of those items — the supervisor singleton lease — is specified with markedly less rigor than the rest of the section (no schema, no TTL, no renewal cadence, no TruthStore footprint, not named among the claims-rule invariant's own satisfying examples), and it introduces a direct textual contradiction with §20.1's "never exits" invariant. That, plus two of round 2's five originally-blocking items (idle-backoff reset, PID-reuse test) being silently carried over rather than closed or explicitly deferred, keeps every CRITICAL dimension (Correctness 75, Red-team 74, Safety 72) below 80 and the overall score below the 80-point bar. Blocking changes required to clear 80:

1. **Specify the supervisor singleton lease as a first-class, schema-backed claim**: state where it lives (TruthStore row, or an explicit non-Truth mechanism with its own stated durability argument), its TTL/expiry, whether and how it is heartbeat-refreshed, and what a losing instance's retry/poll cadence is — then register the new parameter(s) in §12/§20.9 alongside `h_lease`/`g_lease`, and add it to the claims-rule invariant's list of satisfying examples (line 635).
2. **Reconcile §20.1's "the supervisor never exits… process death only" with §20.2's "a starting instance… waits for expiry or exits"** — either scope §20.1's invariant to exclude pre-loop lease acquisition, or restate §20.2 so a losing instance never exits (only waits), and state which.
3. **Restate the recovery predicate's four bullets (609–612) so they are disjoint as literally written**, not only in the compressed partition sentence (613) — e.g., by making bullet 3 (LEAVE) explicitly first-checked/highest-precedence, or by re-deriving bullet 2's second disjunct as "unreconstructable **∧ not alive**." Add a test for the `alive ∧ ¬reconstructable` cell specifically (distinct from `test_owner_alive_left_running`, which does not evidently cover a corrupted-dispatch-row-but-alive-owner fixture).
4. **Either close or explicitly defer, with a stated reason and target milestone, the two round-2 items silently dropped this round:** the idle-backoff counter's reset condition (§20.5.3), and a test for the `owner{pid, started_at}` PID-reuse guard.
5. **Add a namespace guard for the reserved `suite_id="maintenance"`** (an admission check rejecting a real eval suite named literally `"maintenance"`), and reconcile `test_recovery_predicate_three_way`'s name/description with the section's own "four-way rule" framing (rename or fold it into a single test list matching line 608's stated rule count).

Items 1–3 are load-bearing (they touch the section's core safety mechanism directly and would most affect Correctness/Safety/Red-team); items 4–5 are narrower but were explicitly in scope for "all rounds 1–2 items closed or deferred" and are currently neither.
