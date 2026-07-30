# 360 Review: S20-continuous-operation — round 4 — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20 "Continuous operation — the unattended loop" (marked *revised r4*, lines 595–646), + its §12 registration (line 286), + `docs/research/DATA-LAYER.md` §5 schema delta (line 145: adds `supervisor_lease(agent_id, holder{pid, started_at}, lease_expires_at)` alongside the r2/r3 `schedule`, `wake_events`, `work_unit_closed`, `owner`/`lease_expires_at` on `work_unit_opened`, `schedule_id?` on `dispatch`) |
| Proposed change | Round-4 fix set: (1) `supervisor_lease` given a real, schema-backed TruthStore footprint (TTL, heartbeat, grace, named in the claims-rule's satisfying examples); (2) a "holder vs candidate" reading that resolves the §20.1/§20.2 "never exits" vs "waits or exits" contradiction; (3) a normative, sequential evaluation order over the four-way recovery predicate, making the bullets disjoint as literally specified, not only via the r3 summary sentence; (4) an explicit reset condition for the idle-backoff counter `k`; (5) a PID-reuse test (`test_pid_reuse_not_mistaken_for_owner`) |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Prior rounds | round 1 (58/100) → round 2 (75/100) → round 3 (`docs/research/reviews/S20-continuous-operation-review-r3.md`, 72/100, needs-revision) |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Direct review-report write is permitted (not proposal mode).

## Rounds 1–3 closure ledger (audited fresh against the r4 text)

| # | Item (originating round) | Status at r4 | Evidence |
|---|---|---|---|
| R1-1 | Ambiguity-rule vs. resume-from-truth conflict; no schema for "owner proved dead" | **Closed** (progressively, r2→r3→r4) | ALGORITHM:608–613; DATA-LAYER:145 `owner{pid,started_at}`/`lease_expires_at`. r4's own contribution is the normative evaluation order (line 613), see Correctness §1. |
| R1-2 | Test for the recovery boundary | **Closed** | `test_recovery_predicate_three_way`, `test_owner_alive_left_running` (line 646) |
| R1-3 | §5.3 floor vs. deferral scope + alertable signal | **Closed** | Alert: r2 `test_sustained_deferral_surfaced`; scope: r3 "Scope (r3)" (line 622) |
| R1-4 | Missing tests: gate-posture-never-loosens, SOLVE-cannot-write | **Closed** | r2, unchanged since |
| R1-5 | `schedule_id`→`dispatch` mapping; non-`suite_id` job path | **Closed** | mapping r2 (`dispatch.schedule_id?`); non-eval path r3 (`suite_id="maintenance"`, line 607) |
| R1-6 | `agent_id` missing on `schedule`/`wake_events` | **Closed** | r2 |
| R2-1 | Fourth reachable state (owner alive) undisposed | **Closed** | r3 LEAVE bullet + `test_owner_alive_left_running`; r4 evaluation order removes the residual ambiguity r3 itself flagged in that same fix (see Correctness §1) |
| R2-2 | `grace`/heartbeat cadence unparameterized | **Closed** | r3: `h_lease`/`g_lease` in §12 (line 286) and §20.9 (line 646) |
| R2-3 | "expansion actions" scope vs. §5.3 floor | **Closed** | r3 "Scope (r3)" (line 622) |
| R2-4a | Idle-backoff `k` reset condition | **Closed, this round** | Line 627: "the counter `k` resets on the first cycle that makes progress (a gated commit or new evidence lands — the same progress definition, so the reset cannot be triggered by idle work)"; `test_idle_backoff_resets_on_progress` (line 646) |
| R2-4b | Non-`suite_id` scheduled-job scope | **Closed** | r3, `suite_id="maintenance"` path |
| R2-5 | PID-reuse test for `owner{pid,started_at}` | **Closed, this round** | `test_pid_reuse_not_mistaken_for_owner` (line 646): "a recycled `pid` with a different `started_at` is NOT the owner — proved-dead fires; the pair, never the pid alone, identifies the owner" |
| R3-1 | Supervisor singleton lease: schema, TTL, renewal, claims-rule membership | **Closed, this round — the round's central fix** | `supervisor_lease(agent_id, holder{pid,started_at}, lease_expires_at)` (DATA-LAYER:145); heartbeat at `h_lease`, expiry past `g_lease` (reuses r3's own parameters rather than inventing new ones — a clean, minimal-surface fix); named in the claims-rule's satisfying examples (ALGORITHM:635, "§6.1 work units, §20.2 schedules, and the §20.2 supervisor singleton lease satisfy it"); `test_supervisor_lease_has_truth_footprint` (line 646). **But see Correctness/Completeness/adversarial pass below: a losing instance's retry/poll cadence and the acquisition mechanism's atomicity are still unstated — a narrower residual of the same "unparameterized claim" defect class, one layer down.** |
| R3-2 | §20.1 "never exits" vs. §20.2 "waits or exits" contradiction | **Closed on its own terms — but see new finding below** | Line 611, "Holder vs candidate (resolves the §20.1 tension): §20.1's 'never exits' binds the *lease-holding* supervisor; an instance that cannot acquire the lease is a *candidate*, not the supervisor — it may wait for expiry or terminate, both legal for a non-holder." The literal textual contradiction is gone. **New finding: this same fix creates an unreconciled interaction with the pre-existing §20.6 OS-thread watchdog — see Correctness §1, Red-team §3, and the adversarial pass.** |
| R3-3 | Recovery predicate's operative bullets (609–612) not manifestly disjoint without appeal to the summary sentence (613) | **Closed** | Line 613 is now stated as **normative**, not merely descriptive: "Evaluation order is normative (r4), which makes the dispositions disjoint as written: check in sequence — terminal? ⇒ 4 · owner determinately alive? ⇒ 3 (reconstructability not consulted) · proved-dead ∧ reconstructable? ⇒ 1 · else ⇒ 2." A sequential if/elif/else reading is now the specified reading, not an inference. `test_owner_alive_left_running`'s own description now explicitly says "even if unreconstructable" — the specific cell r3 flagged as untested (`alive ∧ ¬reconstructable`) is now named in the test's own annotation. Verified logically exhaustive and disjoint by construction over `(terminal?, liveness ∈ {alive, proved-dead, undeterminable}, reconstructable?)` — see Correctness §1 for the derivation check. |
| R3-4 | Close/defer idle-backoff reset + PID-reuse test | **Closed, this round** | Both fixed directly (see R2-4a, R2-5 above) |
| R3-5 | Namespace guard for `suite_id="maintenance"`; reconcile `test_recovery_predicate_three_way`'s name/description with the section's own "four-way rule" framing | **NOT closed, NOT explicitly deferred — silently carried a second consecutive round** | Line 607's `suite_id="maintenance"` text is byte-identical to r3's; no admission check or reserved-string guard added anywhere. `test_recovery_predicate_three_way` (line 646) is still named and described exactly as in r3 ("proved-dead+reconstructable ⇒ resume … undeterminable-or-unreconstructable ⇒ `unknown` … terminal ⇒ no-op") — still a three-outcome description, unreconciled with line 608/613's explicit "one four-way rule" framing. This is the same discipline lapse r3's own Calibration finding named ("a calibrated summary would have said so explicitly") — it has now recurred, on the exact item r3 flagged, one round later. |
| — | Tier enum not declared as an explicit ordered type (open since round 1) | **Still open, not addressed, not deferred** | Line 622 unchanged: `tier(budget_state) ∈ {ample, degrade, critical, dead}`, ordering only implied by "above/below the current tier." Fourth consecutive round carrying this. |
| — | Digest content: LLM call or templated? (open since round 1) | **Still open, not addressed, not deferred** | Line 639 unchanged. Fourth consecutive round carrying this. |
| — | No retention/GC policy for `schedule`/`wake_events` rows (open since round 1, consistently flagged non-blocking) | **Still open, consistently non-blocking** | Unchanged. |

**Net:** the task's claim that "ALL FIVE" of the round-3-targeted items are addressed is accurate for the five items it explicitly enumerates (supervisor lease, holder/candidate split, evaluation order, idle-backoff reset, PID-reuse test) — this is real, substantive, well-executed progress, and the two hardest items (the lease's schema footprint and the recovery predicate's normative evaluation order) are cleanly closed with concrete tests. But r3's own fifth blocking item (namespace guard + test-naming reconciliation) is silently absent from this round's scope for the second consecutive round, and three round-1-vintage items (tier-enum ordering, digest LLM-call question, schedule/wake_events retention) are now on their fourth consecutive round of silent carryover. More significantly, the round's two headline fixes (the lease, and the holder/candidate split) each leave a **new**, narrower residual of the exact defect class they were introduced to close — see Correctness/Red-team/adversarial pass below.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 80 | pass |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 76 | pass |
| 4 | Implementability | 74 | weak |
| 5 | Safety / integrity (CRITICAL) | 78 | pass |
| 6 | Efficiency / cost | 79 | pass |
| 7 | Completeness | 72 | weak |
| 8 | Consistency | 76 | pass |
| 9 | Calibration / honesty | 68 | weak |

## Findings by dimension

### 1. Correctness

**The r3 disjointness gap is now genuinely, cleanly fixed.** Line 613 upgrades the r3 summary sentence from descriptive to **normative**: "check in sequence — terminal? ⇒ 4 · owner determinately alive? ⇒ 3 (reconstructability not consulted) · proved-dead ∧ reconstructable? ⇒ 1 · else ⇒ 2." Checked as an if/elif/else chain against the full state space `(terminal?, liveness ∈ {alive, proved-dead, undeterminable}, reconstructable?)`: terminal is checked first and short-circuits; among non-terminal units, "alive" (line 611's conjunctive definition: lease heartbeat-refreshed **and** liveness probe answers) is checked second and, per the stated rule, is not further conditioned on reconstructability; only among the remainder (not alive) does the proved-dead∧reconstructable test apply; everything else falls to `unknown`. This is a proper sequential partition — each cell of the space maps to exactly one bullet, and no cell is reachable by two branches. This closes the specific defect r3 raised (the operative bullets 609–612, read as an unordered disjunction, could double-satisfy `alive ∧ ¬reconstructable`). No sign error or malformed inequality found in any of the restated arithmetic (`s_idle·2^k`, `w_dead`, `g_lease = 2·h_lease`, the reset condition below).

**The idle-backoff reset condition (line 627) is now stated and internally consistent.** "No-progress cycles (no gated commit **and** no new evidence recorded)" and "the counter `k` resets on the first cycle that makes progress (a gated commit or new evidence lands — the same progress definition...)" use the same predicate (De Morgan-consistent: ¬(no commit ∧ no evidence) = commit ∨ evidence) on both the trigger and the reset side. No gap found.

**New finding: the "holder vs candidate" fix (line 611) is not reconciled against the pre-existing §20.6 watchdog text, and the interaction is logically underdetermined.** §20.6 (line 631, unchanged since round 1): "an independent OS-thread watchdog hard-exits the process on frozen loop-progress." This was written, and is still worded, for a process that is *running the §6 loop* — both provenance studies name it exactly that way (`STUDY-hermes-agent.md:26`: "an OS-thread watchdog that hard-exits a frozen loop so the external supervisor can revive it"; `STUDY-automaton-autonomy.md:31`: "one unhandled rejection permanently ends the 'continuous' agent"). Round 4 introduces, for the first time in this section's four-round history, a **pre-loop, non-holder process state** — the "candidate" — whose sanctioned behavior is to "wait for expiry" (line 611) without acquiring the lease and therefore without running cycles or advancing the loop-progress heartbeat. The text never states whether the loop-progress watchdog is scoped to "once holding the lease" (in which case a waiting candidate is correctly exempt) or applies process-wide from start (in which case a legitimately-waiting candidate — which by definition is not "advancing" anything — is indistinguishable from "frozen" and would be self-terminated by its own safety mechanism, converting the sanctioned "wait" option into an involuntary, watchdog-triggered "exit" almost immediately). Neither of the two stated candidate behaviors — "wait" or "terminate" — is actually free of this ambiguity, because if "wait" always resolves to a watchdog-forced exit in practice, the two options collapse to one, silently. This is a **correctness gap in the interaction between two named mechanisms**, not merely a missing detail: the round-4 fix asserts "both legal for a non-holder," but whether "wait" is *actually* legal under the concurrently-operating watchdog is not decidable from the text as written.

### 2. Design faithfulness

Strong, genuine improvement over r3's central design-faithfulness finding. Round 3 flagged that the supervisor lease's under-specification meant it did not follow the section's own stated "no second lease system" discipline (line 607) with the same rigor as the work-unit lease it parallels. Round 4's fix reuses the *identical* schema shape (`owner{pid,started_at}`/`lease_expires_at` on `work_unit_opened` vs. `holder{pid,started_at}`/`lease_expires_at` on `supervisor_lease`) and the *same* named parameters (`h_lease`, `g_lease`) rather than inventing new ones — a faithful, minimal-surface extension of an established pattern (DATA-LAYER:145). This is the right move and closes the worst of r3's design-faithfulness gap.

One residual, unaddressed tension, carried since r3 without acknowledgment: the section still asserts "**No second lease system**" as a design principle (line 607, in the context of schedule fires reusing the work-unit lease) while the very same section now demonstrably contains **two structurally distinct lease mechanisms** — the per-occurrence work-unit lease (grain: `occurrence_id`) and the per-agent supervisor singleton lease (grain: `agent_id`) — operating at different grains for different purposes. That these are legitimately different (and that "no second lease system" was only ever meant to forbid a *parallel scheduling mechanism*, not to forbid the supervisor lease) is a plausible reading, but it is never stated as such; the text simply doesn't address why the supervisor lease is an exception to a principle it states elsewhere in the same section.

### 3. Red-team resistance

- **The round-3 "claimed-but-unexpirable state" defect (a direct RC-4-adjacent/claims-rule violation) is closed for the named mechanism.** The supervisor lease now has a TTL (`g_lease`), a heartbeat (`h_lease`), a TruthStore row, and is explicitly listed among the claims-rule's satisfying examples (line 635) — the invariant's own text ("the rule binds all future additions") is now honored by its own most recent addition, unlike in r3. This is a real, substantive closure.
- **New instance of a related failure class, narrower in scope: the candidate's own claim-acquisition behavior is unparameterized.** Nothing states the retry/poll cadence a losing candidate uses to re-attempt acquisition after the lease expires (not `s_poll` — that governs `wake_events` draining, a different mechanism, line 619 — and not named as a new parameter anywhere in §20.9's list). If multiple candidate instances exist simultaneously (a legitimate deployment shape for redundancy/HA, which is exactly what `test_supervisor_singleton`'s framing — "a **second** supervisor instance" — implies is anticipated, not merely an artifact of a restart race), an unspecified retry cadence with no stated jitter/backoff is a **thundering-herd risk on `supervisor_lease` at every expiry**, and, in the "terminate" branch, a risk that all losing candidates give up simultaneously and leave **zero** processes contending for the lease until the external OS-level supervisor's own restart-backoff (§20.6, line 632) eventually re-spawns one — a gap the text never connects explicitly (the safety of "terminate is legal" implicitly depends on the external supervisor's restart loop, but this dependency is never stated).
- **New instance, same class, larger stakes: the candidate/watchdog interaction (Correctness §1) is itself a red-team-relevant gap** — a mechanism whose entire purpose is guaranteeing liveness (§20.6's watchdog) may, under a plausible reading, defeat the very sanctioned behavior ("wait") the round's other headline fix just introduced. This is precisely the class of defect RC-1's patch pattern (`ALGORITHM-v0.1-redteam.md:36-39`, "make the measurement independent of the optimization") generalizes to catch when two safety mechanisms are added independently without checking their composition — here, two *liveness* mechanisms (lease acquisition and the frozen-loop watchdog) whose composition is unchecked.
- **RC-1/RC-7/RC-4 findings resolved in r2/r3 remain unaffected and sound** — the resume-safe-because-of-identity distinction, the tier-scope closure, and the coverage-floor-dominance argument are all untouched by this round's delta.
- What holds, reconfirmed: JUDGE immutability (line 641), gate-posture monotonicity (`test_gate_posture_defers_never_loosens`), the self-preservation check (line 616, still matching `STUDY-hermes-agent.md:29`'s adopted anti-pattern).

### 4. Implementability

Genuine wins, alongside a comparably sized new gap and several old ones carried a fourth round.

- **Closed, this round:** the idle-backoff reset condition is now concrete and testable; the PID-reuse guard's semantics are now explicit and tested; the supervisor lease's storage/TTL/heartbeat are now concrete enough to build without inventing a schema.
- **New gap:** neither the candidate's retry/poll cadence after a failed acquisition or lease expiry, nor the acquisition mechanism's own atomicity guarantee, is specified with the rigor the parallel `open_work_unit` mechanism gets (DATA-LAYER.md:183 spells out an atomic `INSERT … ON CONFLICT` / transactional check-and-insert pattern for work-unit identity; no equivalent sentence exists for `supervisor_lease` acquisition). A developer has to invent both the retry cadence and the concurrency-safety mechanism for the one row this round declares to be the sole barrier against two supervisors running cycles concurrently.
- **Still open, fourth consecutive round, unaddressed and undeferred:** the `suite_id="maintenance"` namespace-collision guard (no admission check rejects a real eval suite literally named `"maintenance"`); `test_recovery_predicate_three_way`'s name/description still describes three outcomes, not four; the tier enum's ordering is still implied, not declared as a machine-checkable type; whether §20.7's digest generation requires an LLM call is still unaddressed.
- **Minor, new:** `test_supervisor_singleton`'s description ("a second supervisor instance acquires no cycles while the first's lease is live," line 646) was not updated to use the round's own new "candidate" terminology, a small self-consistency slip within the same revision that introduces that term.

### 5. Safety / integrity

**CRITICAL.** Net improvement, with a residual concern of the same shape as the mechanism it replaces.

- **Improved, substantively:** the supervisor lease — the sole named barrier against two supervisor processes running cycles concurrently — now carries the same rigor (schema, TTL, heartbeat, grace) the rest of the section holds itself to, closing r3's Safety finding directly. The recovery-predicate's normative evaluation order (Correctness §1) closes the other r3 Safety finding (the risk that a literal implementation of bullets 609–612 could route `alive ∧ ¬reconstructable` to `unknown`, force-closing a unit its still-running owner is writing to).
- **New, safety-adjacent concern:** per Correctness §1 and Red-team §3, whether a "waiting" candidate is exempt from the loop-progress watchdog is undetermined. If it is not exempt, "wait" is not actually a stable, sanctioned state — it collapses to an involuntary exit almost immediately, which is not catastrophic (the external supervisor, line 632, is designed to restart a dead process) but does mean the round's own claim that "wait" and "terminate" are "both legal for a non-holder" overstates the candidate's actual available behavior space. This is a genuine, if narrower, safety-adjacent gap: an under-specified interaction between two mechanisms whose sole job is guaranteeing the system keeps running.
- Unaffected, reconfirmed: §20.8's JUDGE-ownership statement, `test_solve_cannot_write_schedule_or_closures`, `test_tier_posture_never_defers_coverage_floor` all remain adequate.

### 6. Efficiency / cost

No new LLM calls. Lease acquisition/heartbeat is O(1) per cycle, consistent with the section's orchestration-only cost profile. One new, small, unquantified cost concern (Red-team §3): an unparameterized candidate retry cadence, in a multi-candidate deployment, could produce an unbounded (though almost certainly small in absolute terms) polling load against the `supervisor_lease` row at every expiry — bounded by the lease's own TTL cadence in practice, but not stated or bounded in the spec itself. Not blocking.

### 7. Completeness

Three new tests genuinely close three concrete gaps: `test_supervisor_lease_has_truth_footprint`, `test_idle_backoff_resets_on_progress`, `test_pid_reuse_not_mistaken_for_owner` (all line 646). Residual and new gaps:

- No test for the candidate/watchdog interaction identified in Correctness §1 — untestable until the interaction itself is specified.
- No test for the supervisor lease's acquisition atomicity (only `test_supervisor_singleton`'s mutual-exclusion property is tested, not the concurrency mechanism that guarantees it, e.g. a concurrent-acquisition race analogous to `test_same_intent_concurrent_open` for work units).
- No test or stated cadence for candidate retry/poll behavior.
- `suite_id="maintenance"` namespace-collision guard: still untested, still unspecified, fourth-round carryover.
- Tier-enum ordering, digest-LLM-call question: still untested, unspecified, fourth-round carryover.
- No retention/GC test for `schedule`/`wake_events` (carried since round 1, consistently non-blocking).

### 8. Consistency

- **The §20.1/§20.2 contradiction (r3's Correctness/Consistency finding) is resolved as literally stated** — "never exits" is now explicitly scoped to the lease-holder, and "waits or exits" is now explicitly scoped to a non-holding candidate. No remaining textual contradiction between the two sentences.
- **The claims-rule invariant (line 635) is now internally consistent with its own text** — its "binds all future additions" clause is honored by naming the supervisor lease among its own satisfying examples, closing r3's specific consistency gap here.
- **New consistency gap:** §20.6's watchdog language (line 631) was not updated to reflect, or exclude, the new pre-loop "candidate" state this round introduces — a genuine textual inconsistency between an old, unedited mechanism and a new one added elsewhere in the same section, of the same general shape (two adjacent-but-unedited-together mechanisms) as the §20.1/§20.2 contradiction r3 found and this round fixed.
- **Carried, unaddressed a second consecutive round:** `test_recovery_predicate_three_way`'s name/description (line 646) still contradicts the section's own "one four-way rule" framing (line 608/613) introduced in r3 and reaffirmed in r4.
- §12 (line 286) vs. §20.9 (line 646) remain consistent term-for-term for every parameter that IS named — the supervisor lease correctly reuses `h_lease`/`g_lease` rather than requiring new registrations, which is a genuine improvement in list-completeness over r3 (where the lease was entirely absent from both lists). No new parameter-registration gap found for the lease itself, though the (unnamed) candidate retry cadence is a fresh omission of the same shape.
- Otherwise consistent with §10, §6.1/§6.2 write discipline, and §11's ObservabilityPort framing.

### 9. Calibration / honesty

Positive, continued: the section keeps its good habit of naming tests after the specific regression they close (`test_owner_alive_left_running`'s annotation now reads "the r3/r4 fourth-state regression," honestly tracking its own two-round history).

Docked for two reasons, one recurring and one new:

- (a) **Recurring, and now itself a pattern worth naming explicitly:** this is the **third consecutive round** in which at least one item explicitly identified as blocking in the immediately prior review's verdict is silently absent from the round's stated scope rather than closed or flagged as deferred (r2→r3 dropped two items silently; r3→r4 drops one — the namespace guard/test-naming item — silently). Round 3's own Calibration finding named this exact behavior and said "a calibrated summary would have said so explicitly" — the recurrence of the identical lapse, on the exact item that finding discussed, one round after being named, is a stronger calibration concern than a first occurrence would be. The task framing this round ("ALL FIVE are now addressed") is accurate for the five items it enumerates but does not acknowledge that a sixth item from the same prior round's verdict (the namespace guard + test-rename) was left out.
- (b) **New:** the round's two headline claims — "the supervisor lease... has full TruthStore footprint" (line 611) and "resolves the §20.1 tension" (line 611) — are each stated with the section's most confident, resolved-sounding language, but each, on inspection, leaves a narrower residual of the same defect class it closes (the lease's own acquisition/retry mechanism is unparameterized; the holder/candidate split is not reconciled against the pre-existing watchdog). Neither residual is acknowledged with an honest-scope caveat, unlike the precedent the document itself sets elsewhere (§17.6, DATA-LAYER.md:508: "Honest scope: this narrows RC-6's stale-fallback exposure to the concurrent-check window under a tightened monitor — it does not close it"). A one-sentence caveat of that shape for either fix would have been the calibrated thing to write, and its absence — for the second time in two consecutive rounds, on this exact recovery-predicate/lease mechanism — is the clearest single instance of overclaiming resolved-ness in this review.

## Strongest adversarial objection

**The "holder vs candidate" fix, introduced specifically to make a losing supervisor instance's behavior legal and well-defined, does not check its own composition with the pre-existing frozen-loop watchdog — and depending on how an implementer resolves that gap, "wait" is either not actually available to a candidate, or the watchdog has to be silently re-scoped in a way the text never states.**

Grant every fix in this round exactly as intended: the lease is schema-backed and race-free, the recovery predicate is unambiguous, and no implementer misreads any of the four dispositions. Even then, §20.6's watchdog (line 631) is textually unconditional: "an independent OS-thread watchdog hard-exits the process **on frozen loop-progress**." Both studies this section cites as its adopted-pattern provenance describe this exact mechanism as applying to a process that is, in the normal case, always running the loop (`STUDY-hermes-agent.md:26`, `STUDY-automaton-autonomy.md:31`) — neither study has a multi-instance singleton-lease candidacy model, because neither system was designed for redundant supervisor instances. Round 4 is the first point in this section's four-round history to introduce a legitimate, sanctioned, non-crash state — "candidate, waiting" — in which the process is, by definition, not advancing loop progress (it hasn't acquired the lease and isn't running cycles). The text gives this candidate two legal options ("wait for expiry or terminate") but never states whether the loop-progress watchdog's stall-detection window applies during candidacy or only after lease acquisition. Two readings are both plausible and neither is written down:

1. **The watchdog applies process-wide, from process start.** Then a legitimately-waiting candidate will, after the watchdog's (unstated, but presumably shorter than `g_lease`) stall threshold elapses, be hard-exited by its own safety mechanism — which silently converts "wait" into "terminate" in every real deployment, making the round's "both legal for a non-holder" framing describe a choice that doesn't actually exist in practice. This also means the watchdog — a mechanism whose entire job is keeping the system alive — would be the proximate cause of killing a process that is behaving exactly as designed, which is the opposite of its intended function.
2. **The watchdog is implicitly scoped to "after lease acquisition" (i.e., only monitors the running loop, not the pre-acquisition candidacy phase).** This is probably what was intended, and it's a coherent design — but it requires the watchdog's own trigger condition to be re-read as "frozen loop progress **while holding the lease**," a scoping change to an unedited, pre-existing mechanism (§20.6) that this round's fix silently depends on without stating it, self-relying on the same authors' correct inference of an unwritten precedence rather than making the precedence explicit (structurally the same category of gap round 3 found in the recovery predicate's own bullets, now recurring in the interaction between two *different* subsections).

The realistic trigger is not exotic: it is precisely the scenario the supervisor lease exists to handle (§20.1/§20.2's own stated motivation — an external-supervisor-managed restart racing against a not-yet-reaped old process). Every time that race occurs, a newly-spawned instance becomes a candidate and, per the text, may "wait" — and whether that candidate survives long enough to actually acquire the lease once it expires depends entirely on an interaction the spec never checked.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(80, 76, 78) = 76
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (80*2 + 84 + 76*2 + 74 + 78*2 + 79 + 72 + 76 + 68) / 11
                = (160 + 84 + 152 + 74 + 156 + 79 + 72 + 76 + 68) / 11
                = 921 / 11
                = 83.7 → 84
overall         = min(76, 84) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

Round 3's 72 → round 4's 76 is real, substantive progress: the two headline fixes (the supervisor lease's schema footprint, and the recovery predicate's normative evaluation order) are both cleanly executed, well-tested, and reuse existing patterns/parameters rather than inventing new unparameterized ones — genuinely the section's best round of fixes so far on a like-for-like basis. But every CRITICAL dimension (Correctness 80, Red-team 76, Safety 78) still sits below 80, driven by one new finding this round surfaced (the candidate/watchdog interaction) plus one item from round 3's own verdict silently carried a second time. Blocking changes required to clear 80:

1. **State whether the §20.6 OS-thread watchdog's frozen-loop-progress trigger is scoped to "while holding the supervisor lease" or applies from process start.** If scoped to post-acquisition, say so explicitly and reconcile the wording at line 631. If it applies process-wide, state what stall-threshold a waiting candidate is exempt from (or concede that "wait" is not durably available and restate the candidate's actual behavior). Add a test exercising a candidate in the "wait" state under the watchdog.
2. **Specify the candidate's retry/poll cadence** after a failed acquisition attempt or after observing the lease's `lease_expires_at`, and name it as a parameter (reusing `s_poll` explicitly, or introducing a new named constant) in §12/§20.9 — the same discipline already applied to `h_lease`/`g_lease`.
3. **State the supervisor-lease acquisition mechanism's atomicity guarantee** with the same rigor DATA-LAYER.md:183 gives `open_work_unit` (an explicit transactional check-and-claim pattern), so a multi-candidate acquisition race cannot double-claim the lease by construction rather than by assumption.
4. **Close or explicitly defer, with a stated reason, the round-3 item silently dropped this round:** the `suite_id="maintenance"` namespace-collision guard, and reconciling `test_recovery_predicate_three_way`'s name/description with the section's own four-way framing.
5. **Add an honest-scope caveat for at least one of this round's two headline fixes**, in the style of §17.6's precedent (DATA-LAYER.md:508) — e.g., naming the candidate/watchdog interaction as an acknowledged, not-yet-closed residual — so the round's framing does not read as more fully resolved than the mechanism composition actually is.

Items 1–3 are load-bearing (they touch the section's core liveness/safety mechanism directly and would most affect Correctness/Red-team/Safety); items 4–5 are narrower but were explicitly named in round 3's verdict and this round's own calibration record, and remain neither closed nor deferred.
