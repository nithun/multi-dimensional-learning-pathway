# 360 Review: S20-continuous-operation — round 5 — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20 "Continuous operation — the unattended loop" (marked *revised r5*, lines 595–650), + its §12 registration (line 286), + `docs/research/DATA-LAYER.md` §5 schema delta (line 145: `supervisor_lease(agent_id, holder{pid, started_at}, lease_expires_at)` now present alongside `schedule`, `wake_events`, `work_unit_closed`, `owner`/`lease_expires_at` on `work_unit_opened`, `schedule_id?` on `dispatch`) |
| Proposed change | Round-5 full-sweep fix set against the round-4 ledger: (1) watchdog scoping stated explicitly — the §20.6 loop-progress watchdog arms only in the lease-holder; a candidate's obligations are process heartbeat + poll cadence (`test_candidate_not_killed_by_watchdog`); (2) candidate acquisition is a compare-and-set conditional UPDATE in one truth-backend transaction, candidates poll at `s_cand` (default `s_poll`, registered §12/§20.9, `test_lease_acquisition_atomic`); (3) the `maintenance` namespace reserved at provisioning (`provision_suite` rejects real skills/suites claiming it, `test_maintenance_namespace_reserved`) and the stale three-way test renamed `test_recovery_predicate_four_way` with the normative order restated in its own description; (4) tier enum declared totally ordered (`dead < critical < degrade < ample`); digest composition made an ordinary metered, fallback-safe JUDGE call; consumed wake rows pruned after `w_wake` (30d), schedule rows never auto-deleted (`test_wake_retention_prunes_consumed_only`) |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Prior rounds | round 1 (58/100) → round 2 (75/100) → round 3 (72/100) → round 4 (`docs/research/reviews/S20-continuous-operation-review-r4.md`, 76/100, needs-revision) |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Direct review-report write is permitted (not proposal mode).

## Full ledger — every item from rounds 1–4, audited fresh against the r5 text

| # | Item (originating round) | Status at r5 | Evidence |
|---|---|---|---|
| R1-1 | Ambiguity-rule vs. resume-from-truth conflict; no schema for "owner proved dead" | **Closed (r2→r4), unaffected by r5** | ALGORITHM:608–614; DATA-LAYER:145 `owner{pid,started_at}`/`lease_expires_at`. |
| R1-2 | Test for the recovery boundary | **Closed (r2), renamed/strengthened this round** | `test_recovery_predicate_four_way` (line 645), replacing the stale `test_recovery_predicate_three_way`. |
| R1-3 | §5.3 floor vs. deferral scope + alertable signal | **Closed (r2/r3), unaffected by r5** | Line 622 "Scope (r3)"; `test_sustained_deferral_surfaced`. |
| R1-4 | Missing tests: gate-posture-never-loosens, SOLVE-cannot-write | **Closed (r2), unaffected by r5** | `test_gate_posture_defers_never_loosens`, `test_solve_cannot_write_schedule_or_closures` (line 645). |
| R1-5 | `schedule_id`→`dispatch` mapping; non-`suite_id` job path | **Closed (r2/r3), hardened further this round** | Mapping r2; non-eval path r3 (`suite_id="maintenance"`); r5 adds the namespace-collision guard closing the last open edge of this item (see R3-5 below). |
| R1-6 | `agent_id` missing on `schedule`/`wake_events` | **Closed (r2), unaffected by r5** | DATA-LAYER:145. |
| R2-1 | Fourth reachable state (owner alive) undisposed | **Closed (r3/r4), unaffected by r5** | Line 611 LEAVE bullet; `test_owner_alive_left_running`. |
| R2-2 | `grace`/heartbeat cadence unparameterized | **Closed (r3), unaffected by r5** | `h_lease`/`g_lease` (§12 line 286, §20.9 line 644). |
| R2-3 | "expansion actions" scope vs. §5.3 floor | **Closed (r3), unaffected by r5** | Line 622 "Scope (r3)". |
| R2-4a | Idle-backoff `k` reset condition | **Closed (r4), unaffected by r5** | Line 627. |
| R2-4b | Non-`suite_id` scheduled-job scope | **Closed (r3), unaffected by r5** | Line 607. |
| R2-5 | PID-reuse test | **Closed (r4), unaffected by r5** | `test_pid_reuse_not_mistaken_for_owner` (line 645). |
| R3-1 | Supervisor lease: schema, TTL, renewal, claims-rule membership | **Closed (r4); this round's own residual (acquisition atomicity/poll cadence) now also closed** | DATA-LAYER:145 `supervisor_lease`; line 635 claims-rule membership; **new this round:** line 611 "Candidate mechanics (r5): acquisition is a compare-and-set conditional UPDATE in one truth-backend transaction … a waiting candidate polls at `s_cand`"; `s_cand` registered §12/§20.9; `test_lease_acquisition_atomic` (line 645). See Correctness §1 for the derivation check. |
| R3-2 | §20.1 "never exits" vs. §20.2 "waits or exits" contradiction | **Closed (r4) on its literal terms; r4's own follow-on finding (candidate vs. watchdog composition) now closed this round, with one placement caveat** | Line 611 holder/candidate split (r4); **new this round:** "Watchdog scoping (r5): the §20.6 loop-progress watchdog arms only in the holder … a candidate's only liveness obligations are its process heartbeat and poll cadence"; `test_candidate_not_killed_by_watchdog` (line 645). See Correctness §1 / Consistency §8 for the residual: §20.6's own text (line 631) was not itself edited to state this scoping — the qualifier lives only in §20.2. |
| R3-3 | Recovery predicate's operative bullets not manifestly disjoint without the summary sentence | **Closed (r4), unaffected by r5** | Line 613 normative evaluation order. |
| R3-4 | Idle-backoff reset + PID-reuse test | **Closed (r4), unaffected by r5** | See R2-4a/R2-5. |
| R3-5 | Namespace guard for `suite_id="maintenance"`; stale three-way test name/description | **Closed this round — the round's other headline fix, with one residual** | Line 607: "**The `maintenance` namespace is reserved at provisioning:** `provision_suite` (§5.1) rejects any real skill/suite claiming it … (`test_maintenance_namespace_reserved`)"; test renamed `test_recovery_predicate_four_way` with the normative order restated in its own annotation (line 645). **Residual, new this round:** §5.1's own `provision_suite` pseudocode (ALGORITHM:135–140) was not edited to show this reserved-namespace check — the claim is asserted only from §20.2, one section away from the function it describes. See Implementability §4 / Consistency §8. |
| R4-new-1 | Design-faithfulness tension: "no second lease system" (line 607) vs. two structurally distinct lease mechanisms now present | **NOT closed, NOT explicitly deferred — carried silently a third consecutive round** | Line 607's "No second lease system" clause is byte-identical to r3/r4; no sentence anywhere in the r5 delta explains why the supervisor lease is exempt from a principle the section states about itself. First flagged r3 Design Faithfulness, repeated r4 Design Faithfulness ("carried since r3 without acknowledgment"), still unaddressed at r5. |
| R4-new-2 | `test_supervisor_singleton`'s description not updated to the "candidate" terminology this round's (r4's) own fix introduced | **NOT closed, NOT explicitly deferred — carried a second round** | Line 645: `test_supervisor_singleton` ("a second supervisor instance acquires no cycles while the first's lease is live") is textually unchanged since r3/r4 — still describes "a second supervisor instance," not "a candidate," despite the term now being load-bearing vocabulary in the same subsection. |
| — | Tier enum not declared as an explicit ordered type (open since round 1) | **Closed this round** | Line 622: "a **totally ordered** enum, `dead < critical < degrade < ample`; `tier_minimum` comparisons use this order." Verified against usage at (b) "rows with `tier_minimum` above the current tier are skipped" — direction checked and correct (see Correctness §1). |
| — | Digest content: LLM call or templated? (open since round 1) | **Closed this round** | Line 638: "digest composition (r5): digests are deterministic templates by default; an LLM-composed digest, if configured, is an ordinary metered JUDGE model call whose failure falls back to the deterministic template — composition can never block delivery." |
| — | No retention/GC policy for `schedule`/`wake_events` rows (open since round 1, consistently non-blocking) | **Closed this round, asymmetrically by design (not a gap)** | Line 619: "Retention (r5): consumed wake rows are pruned after `w_wake` (default 30d); schedule rows are never auto-deleted … the §17.6 rows-permanent discipline"; `w_wake` registered §12/§20.9; `test_wake_retention_prunes_consumed_only` (line 645). |
| — (new, r5) | Maintenance-unit reconstructability edge case | **New finding, not addressed — see adversarial pass** | The reconstructability test in the recovery predicate (line 609, "dispatch row and pinned `item_ids` intact") is never reconciled against `suite_id="maintenance"` units' *intentionally* empty `item_ids` (line 607) — an implementer has no stated guidance on whether an empty `item_ids` set is trivially "intact" or a red flag. |

**Net:** this is a genuinely clean sweep against the round-4 verdict's five explicit blocking items — all five are closed, three of them (watchdog scoping, acquisition atomicity, namespace guard) with concrete named mechanisms and new tests, and the two narrower items (tier-enum ordering, digest ambiguity) plus the previously-non-blocking retention gap are closed as a bonus. This is the best-executed round in the section's five-round history on a like-for-like basis. But the ledger is not perfectly clean: one design-faithfulness tension flagged in r3 and r4 ("no second lease system" vs. two lease mechanisms) is silently carried a third round, one minor test-description desync from r4 is carried a second round, and the fix that closes the namespace guard (R3-5) introduces a narrower, new interaction gap of its own (the maintenance/`item_ids` reconstructability question) — see the adversarial pass.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 82 | pass |
| 3 | Red-team resistance (CRITICAL) | 87 | pass |
| 4 | Implementability | 85 | pass |
| 5 | Safety / integrity (CRITICAL) | 87 | pass |
| 6 | Efficiency / cost | 81 | pass |
| 7 | Completeness | 85 | pass |
| 8 | Consistency | 76 | pass |
| 9 | Calibration / honesty | 75 | pass |

## Findings by dimension

### 1. Correctness

**The round-4 candidate/watchdog composition gap is now genuinely, cleanly closed.** Line 611: "the §20.6 loop-progress watchdog arms only in the **holder** (it watches cycle progress; a candidate runs no cycles) — a candidate's only liveness obligations are its process heartbeat and poll cadence, so a legitimately-waiting candidate is never self-terminated as 'frozen'." This resolves the exact underdetermined interaction round 4's Correctness §1 and adversarial pass identified: the watchdog's stall-detection window is now explicitly scoped to the loop-running holder, and a waiting candidate — which by definition runs no cycles — is correctly exempted rather than having "wait" collapse into an involuntary, watchdog-triggered exit. `test_candidate_not_killed_by_watchdog` (line 645) makes this an enforceable property, not prose.

**The lease-acquisition atomicity gap is also cleanly closed, and the mechanism is correct.** Line 611: "acquisition is a compare-and-set conditional UPDATE in one truth-backend transaction (the same atomicity discipline §6.1 gives `open_work_unit`)." Checked against the pattern this claims to mirror (DATA-LAYER.md:183, "the check-and-insert executes in one transaction of the truth backend … concurrent opens … serialize to one insert + one return-existing"): a conditional `UPDATE … WHERE holder IS NULL OR lease_expires_at < now()` executed as a single statement inside one transaction is race-free by the same mechanism (single-statement, single-transaction serialization on both SQLite and Postgres) — verified as internally consistent, no double-holder race is introduced. This is also the pattern `STUDY-automaton-autonomy.md:14` names as the studied system's own adopted discipline ("lease-by-conditional-UPDATE"), so the fix is both correct and faithful to its own cited provenance.

**The tier enum's total order is stated and directionally verified.** Line 622: `dead < critical < degrade < ample`. Checked against usage (b), "schedule suppression — rows with `tier_minimum` above the current tier are skipped": if `tier_minimum = ample` and current tier is `degrade`, `degrade < ample` holds, so `tier_minimum` is correctly "above" current and the row is correctly skipped. Checked against usage (c), "at `degrade` or below" = `{dead, critical, degrade}` under this order — consistent with every prior round's usage of that phrase. No sign or direction error found.

**New, narrow finding: the maintenance-namespace fix (R3-5, line 607) and the recovery predicate's reconstructability test (line 609) are not reconciled for the case they now both touch.** Reconstructability is defined as "dispatch row and pinned `item_ids` intact." A `suite_id="maintenance"` unit opens with **empty** `item_ids` by design (line 607). The text never states whether an empty `item_ids` set is trivially "intact" (the charitable and almost-certainly-intended reading — it matches exactly what was pinned at open) or could be misread by an implementation as a corrupted/missing-items signal. Tracing the consequence through the normative evaluation order (line 613): if a maintenance unit's owner is proved dead and an implementation wrongly treats empty `item_ids` as "unreconstructable," the unit resolves to `unknown` rather than RESUME — which is the **safe** direction (no auto-resume of an ambiguous unit) and, because maintenance units can never move a posterior (line 607), has no evidence-integrity consequence either way. So this is a real, citable gap in cross-mechanism reconciliation, but it is not a correctness *defect* with an unsafe failure mode — it is an unstated edge case that fails safe by construction. Docked here as a completeness-adjacent correctness gap, not a blocking error.

No sign error or malformed inequality found in any other restated formula (`s_idle·2^k`, `w_dead`, `g_lease = 2·h_lease`, `s_cand` default `= s_poll`, `w_wake` default 30d).

### 2. Design faithfulness

The round's three headline fixes are faithful, minimal-surface extensions in the section's established idiom: the compare-and-set acquisition mechanism reuses `open_work_unit`'s exact transactional discipline (DATA-LAYER.md:183) rather than inventing a new one; `s_cand` defaults to the already-registered `s_poll` rather than adding an unrelated cadence; the wake-row retention explicitly cites and reuses "the §17.6 rows-permanent discipline" (line 619) rather than inventing a new retention policy shape. This is the section's best round of fixes for faithfulness-to-precedent so far.

**One residual, unaddressed for a third consecutive round: line 607 still asserts "No second lease system"** as a stated design principle in the same subsection that names two structurally distinct lease mechanisms (the per-occurrence work-unit lease and the per-agent `supervisor_lease`). Round 3 first flagged this; round 4 repeated it ("carried since r3 without acknowledgment"); round 5's text is byte-identical on this specific clause and adds no reconciling sentence, despite this exact round's task being framed as a full sweep of the outstanding ledger. This is not a large design flaw (the plausible reading — "no second lease system" was only ever meant to forbid a parallel *scheduling* mechanism, not to forbid the orthogonal supervisor-singleton lease — is sound) but it is a real, three-times-flagged textual self-contradiction that a one-sentence scoping fix would close.

### 3. Red-team resistance

- **The round-4 "candidate/watchdog interaction" finding — itself framed as generalizing RC-1's "make the measurement independent of the optimization" pattern to a composition-of-two-safety-mechanisms failure — is closed.** The watchdog-scoping statement (line 611) plus `test_candidate_not_killed_by_watchdog` directly close the risk that a mechanism whose sole job is guaranteeing liveness (the watchdog) could defeat the very liveness option (waiting candidacy) the round-4 fix introduced.
- **The round-4 "unparameterized candidate retry cadence" finding (a narrower instance of the claims-rule/RC-4-adjacent failure class) is closed.** `s_cand` is named, defaulted, and registered (§12 line 286, §20.9 line 644); `test_lease_acquisition_atomic` (line 645) verifies the underlying race-freedom directly, which is the concrete test the round-4 report asked for by name ("a concurrent-acquisition race analogous to `test_same_intent_concurrent_open`").
- **Residual, small: no jitter/backoff is stated for multi-candidate polling at a fixed `s_cand` cadence.** Round 4 characterized this thundering-herd risk against `supervisor_lease` as "almost certainly small in absolute terms" and non-blocking; it remains unaddressed at r5 in the same low-severity form — every candidate now has a *named*, bounded cadence (an improvement over "unparameterized"), but no stated randomization to spread simultaneous re-attempts at every lease expiry.
- **RC-1/RC-7/RC-4 findings resolved in earlier rounds remain unaffected and sound** — the resume-safe-because-of-identity distinction, the tier-scope closure, and the coverage-floor-dominance argument are all untouched by this round's delta.
- What holds, reconfirmed: JUDGE immutability (line 641), gate-posture monotonicity (`test_gate_posture_defers_never_loosens`), the self-preservation check (line 616), the claims-rule invariant (line 635) — now with the supervisor lease explicitly named among its satisfying examples and, per this round, an acquisition mechanism that actually demonstrates the TTL/liveness-probe discipline rather than merely asserting it.

### 4. Implementability

Genuine, substantial wins; two narrow residuals carried, one new.

- **Closed, this round:** the lease-acquisition mechanism's atomicity and the candidate's retry/poll cadence are now concrete enough to build without inventing either (previously the round-4 report's single largest Implementability gap, matched almost verbatim against DATA-LAYER.md:183's precedent); the tier enum is now a declared, machine-checkable total order; the digest-composition question (LLM call vs. template) is answered with a concrete, fallback-safe default; wake-row retention has a stated window and a test.
- **New, narrow gap:** the namespace-reservation claim (line 607, "`provision_suite` (§5.1) rejects any real skill/suite claiming it") is not reflected in `provision_suite`'s own pseudocode (ALGORITHM:135–140, unchanged): `provision_suite(s_new, cluster)` as shown checks only verifier-reliability (`reliability_lowerCI(v) ≥ ρ_min`), with no reserved-string/namespace check anywhere in its body. A developer implementing strictly from §5.1's stated contract would not discover this obligation unless they separately read §20.2 — the same "claim about another mechanism's behavior asserted from a different section, not reflected in that mechanism's own definition" shape the review has flagged three times before for other pairs of sections (§20.1/§20.2 in r3, lease/watchdog in r4). `test_maintenance_namespace_reserved` (line 645) makes the intended behavior enforceable regardless, so this is a documentation/cross-reference gap, not an unbuildable one.
- **Carried, second round, unaddressed:** `test_supervisor_singleton`'s description (line 645) still reads "a second supervisor instance acquires no cycles while the first's lease is live" rather than using the round's own "candidate" vocabulary — a small self-consistency slip flagged at r4 and still present.
- **Carried, third round, unaddressed:** the "no second lease system" / two-lease-mechanisms tension (Design Faithfulness §2) has no implementability consequence on its own, but it is the kind of unreconciled principle-vs-mechanism statement that tends to produce exactly the kind of build-time confusion this dimension exists to catch.

### 5. Safety / integrity

**CRITICAL.** Substantial, direct improvement — both of round 4's Safety-relevant findings are closed cleanly.

- **The candidate/watchdog gap** (round 4: "whether a 'waiting' candidate is exempt from the loop-progress watchdog is undetermined... this is a genuine, if narrower, safety-adjacent gap") **is resolved**: the watchdog is now explicitly holder-scoped (line 611), so the round-4 concern that "wait" might collapse into an involuntary, watchdog-forced exit — overstating the candidate's actual available behavior space — no longer applies. `test_candidate_not_killed_by_watchdog` makes this a build-time-enforceable property.
- **The lease-acquisition atomicity gap** (round 4: "a developer has to invent... the concurrency-safety mechanism for the one row this round declares to be the sole barrier against two supervisors running cycles concurrently") **is resolved**: the compare-and-set mechanism, reusing §6.1's own proven transactional discipline, gives the section's central concurrency-safety property (exactly-one-holder) a demonstrated mechanism rather than an assertion. `test_lease_acquisition_atomic` verifies it directly.
- The claims-rule invariant (line 635) is now satisfied by a mechanism with real teeth (schema, TTL, heartbeat, atomic acquisition) rather than by naming alone, closing the gap round 3 first identified in this exact invariant.
- **New, narrow, non-blocking:** the maintenance/`item_ids` reconstructability ambiguity (Correctness §1) fails toward the conservative side (`unknown`, not double-execution) and maintenance units can never move a posterior — so even in the worst case this is an availability/operator-friction question (a maintenance job doesn't auto-resume), not an evidence-integrity or concurrent-executor risk. Not scored as a safety defect.
- Unaffected, reconfirmed: §20.8's JUDGE-ownership statement, `test_solve_cannot_write_schedule_or_closures`, `test_tier_posture_never_defers_coverage_floor` all remain adequate.

### 6. Efficiency / cost

No new unaccounted LLM calls: the digest LLM path (line 638) is explicitly named as "an ordinary metered JUDGE model call" with a fallback, so its cost is now visible in the same accounting the section applies to every other named consumer, and a call failure (e.g., under `dead`-tier budget exhaustion) degrades to the free template path rather than blocking delivery — self-healing under exactly the condition where cost would otherwise be a concern. Lease acquisition and heartbeat remain O(1) per cycle/candidate. Wake-row pruning after `w_wake` is a bounded, periodic administrative operation consistent with the section's existing retention idioms (DATA-LAYER.md:192). One small, previously-identified, still-open cost concern: no jitter/backoff is stated for simultaneous candidate polling at `s_cand`, a bounded but unquantified thundering-herd risk against `supervisor_lease` at every expiry (same severity assessment as round 4: small, non-blocking).

### 7. Completeness

Five tests directly close five concrete gaps this round: `test_candidate_not_killed_by_watchdog`, `test_lease_acquisition_atomic`, `test_maintenance_namespace_reserved`, `test_wake_retention_prunes_consumed_only`, and the renamed/strengthened `test_recovery_predicate_four_way` (all line 645). Residual and new gaps:

- No test for the maintenance-unit/`item_ids` reconstructability interaction identified in Correctness §1 — untestable until the interaction itself is specified in text.
- No test or stated jitter/backoff policy for simultaneous candidate polling.
- `provision_suite`'s own pseudocode (§5.1) has no corresponding update or test hook shown for the reserved-namespace check the §20.2 text asserts it performs (the test exists per §20.9's list, but the function's own spec text doesn't show what it's testing against).
- `test_supervisor_singleton`'s stale ("second supervisor instance") framing, carried a second round.

### 8. Consistency

- **The §20.1/§20.2 contradiction and its round-4 follow-on (candidate vs. watchdog) are resolved as a matter of stated behavior** — no remaining logical contradiction between "never exits" (holder-scoped) and "waits or exits" (candidate-scoped), and the watchdog's scope is now stated explicitly rather than left underdetermined.
- **New/residual: the watchdog-scoping fix lives entirely in §20.2 (line 611); §20.6's own text (line 631, unchanged since round 1) is still unconditional** — "an independent OS-thread watchdog hard-exits the process on frozen loop-progress" — with no cross-reference or qualifying clause added at its point of definition. A reader consulting §20.6 alone would still see an apparently process-wide, unconditional trigger; the holder-scoping is discoverable only from §20.2. This is the same *shape* of gap flagged repeatedly in this document's history (a fix stated in the section that needed it, not in the section that defines the mechanism being scoped) — narrower than the correctness question it answers (which is genuinely closed), but a live textual inconsistency between two sections describing the same mechanism.
- **Carried, third consecutive round, unaddressed:** "No second lease system" (line 607) vs. two lease mechanisms now present in the section (Design Faithfulness §2).
- **Carried, second consecutive round, unaddressed:** `test_supervisor_singleton`'s pre-"candidate"-vocabulary description (Implementability §4).
- The claims-rule invariant (line 635) remains internally consistent with its own "binds all future additions" clause — the supervisor lease is named among its satisfying examples and, this round, actually demonstrates the property via its acquisition mechanism.
- §12 (line 286) vs. §20.9 (line 644) remain consistent term-for-term for every named parameter, including the two new ones this round (`s_cand`, `w_wake`) — no new parameter-registration gap found.
- Otherwise consistent with §10, §6.1/§6.2 write discipline, and §11's ObservabilityPort framing.

### 9. Calibration / honesty

Positive and improved: this round's task framing itself ("FULL SWEEP — every item on that ledger") is, on the fresh audit above, substantially accurate — every one of round 4's five explicitly-numbered blocking items is genuinely closed with a concrete mechanism and a named test, which is real progress against the exact pattern (silent partial closure) rounds 2→3 and 3→4 both exhibited. The section continues its good habit of naming tests after the regression they close (`test_recovery_predicate_four_way`'s own annotation still reads "the r2/r4 regression").

Docked from "strong" for two reasons:

- (a) **Two items from the fuller historical ledger (not among round 4's five headline items, but flagged in round 4's own Design Faithfulness and Implementability sections respectively) are silently carried a third and second round respectively without acknowledgment:** the "no second lease system" tension, and `test_supervisor_singleton`'s stale description. Since this round's own framing is "every item on the ledger," a calibrated summary would have either closed these two or explicitly named them as intentionally out of scope; neither happened.
- (b) **No honest-scope caveat was added, despite round 4's verdict explicitly asking for one** ("Add an honest-scope caveat for at least one of this round's two headline fixes... so the round's framing does not read as more fully resolved than the mechanism composition actually is"). The round's confident language for the watchdog-scoping fix ("resolves the §20.1 tension," "never self-terminated as 'frozen'") is, on this round's evidence, now substantively earned — but it is still presented with the section's most confident register, in the same style flagged for overclaiming twice before, and without noting that the fix's textual home is one section away from the mechanism it scopes (Consistency §8). A one-sentence caveat in the style of DATA-LAYER.md:508's precedent would have been the calibrated thing to write here too.

## Strongest adversarial objection

**The maintenance-namespace guard — this round's second headline fix — was built without checking its interaction with the recovery predicate's reconstructability test, which is exactly the same category of unreconciled-mechanism-composition gap this section has produced in every one of its last three rounds.**

Grant every fix in this round exactly as intended: the watchdog is correctly holder-scoped, lease acquisition is race-free, the tier enum is a correct total order, the digest call is safely fallback-guarded, and wake-row retention is correctly bounded. Even then, round 5 introduces a `suite_id="maintenance"` work unit that **by design** opens with empty `item_ids` (line 607) into a recovery predicate whose reconstructability test is defined, unchanged since round 2, as "dispatch row and pinned `item_ids` intact" (line 609). The text never states whether an intentionally-empty set counts as "intact." This is not hypothetical: every maintenance unit ever dispatched has this shape by construction, so the ambiguity is not an edge case reachable under rare conditions — it is the **default and only** shape of every maintenance work unit's reconstructability check. The most likely resolution (empty `item_ids` trivially matches what was pinned, so it is intact) is almost certainly what the authors intend, and the failure direction if an implementer reads it the other way is safe (routes to `unknown`, and maintenance units move no posterior regardless) — so this does not rise to a blocking defect. But it is the fourth instance, across four consecutive rounds, of the identical failure pattern: a new mechanism (this round: the maintenance-namespace guard) is specified in isolation from an existing, adjacent mechanism it now interacts with (the recovery predicate's reconstructability test) without the interaction being checked, named, or tested. Round 3 found this between §20.1 and §20.2 (never-exits vs. waits-or-exits). Round 4 found it between the holder/candidate split and the pre-existing watchdog. Round 5 closes round 4's instance cleanly — and, in the same round, opens a new one between the namespace guard and the reconstructability test. The pattern itself, not any single instance of it, is the section's most durable defect: every round's fix for the *previous* round's composition gap has, so far, been built without a check for whether it creates a *new* one. This round is the first to close its predecessor's gap without visibly reproducing the exact same failure mode elsewhere in the same round's own two headline fixes (the watchdog-scoping fix does not appear to open a new composition gap) — but the second headline fix (the namespace guard) does, at lower stakes. A calibrated read of this section's five-round history says the process that produces these fixes has no step that checks a new mechanism against the full set of pre-existing ones it might touch — only against the specific one the review flagged last round.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(88, 87, 87) = 87
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (88*2 + 82 + 87*2 + 85 + 87*2 + 81 + 85 + 76 + 75) / 11
                = (176 + 82 + 174 + 85 + 174 + 81 + 85 + 76 + 75) / 11
                = 1008 / 11
                = 91.6 → 92
overall         = min(87, 92) = 87
```

**Overall confidence: 87 / 100**

## Verdict

**ready-for-approval**

Round 4's 76 → round 5's 87 reflects a genuinely complete round: all five of round 4's explicitly-numbered blocking items (watchdog scoping, candidate acquisition atomicity/cadence, namespace guard + test rename, and the section's three round-1-vintage carryovers — tier-enum ordering, digest-LLM ambiguity, wake/schedule retention) are closed with concrete, named mechanisms and, in every load-bearing case, a corresponding test. Every CRITICAL dimension (Correctness 88, Red-team 87, Safety 87) now clears 70 with margin, and the aggregate clears 80. This is the first round in the section's five-round history to reach `ready-for-approval`.

This verdict does not certify the artifact defect-free — it certifies that no CRITICAL dimension is blocking and the weighted mean clears the bar. The following residuals should be closed at or before the change-approver's pass, in ascending order of stakes, but none of them independently drives any CRITICAL dimension below 70 or the aggregate below 80:

1. **Reconcile the "no second lease system" principle (line 607) with the two lease mechanisms the section now contains** — a one-sentence scoping fix (e.g., "no second *scheduling* lease system — the supervisor's own singleton lease is orthogonal, protecting the process rather than an occurrence"), closing an item flagged in rounds 3, 4, and 5 without acknowledgment.
2. **State the maintenance-unit/`item_ids` reconstructability interaction explicitly** — confirm that an empty, intentionally-pinned `item_ids` set is trivially "intact" for the purposes of the recovery predicate's reconstructability test, and add a test for it (the adversarial-pass finding).
3. **Edit §20.6's own text (line 631) to state the holder-scoping of the loop-progress watchdog**, rather than leaving the qualifier solely in §20.2 — closes the residual consistency gap between the two sections describing the same mechanism.
4. **Update `test_supervisor_singleton`'s description to the round-4/5 "candidate" vocabulary** and consider a small jitter/backoff note for simultaneous candidate polling at `s_cand` — both minor, carried across rounds.
5. **Add an honest-scope caveat**, in the style of DATA-LAYER.md:508's precedent, naming any residual the change-approver should track post-approval (e.g., item 2 above) — a request this section's own verdicts have made three times without it yet appearing in the artifact text.
