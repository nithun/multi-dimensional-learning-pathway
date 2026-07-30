# 360 Review: S20-continuous-operation — round 2 — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §20 "Continuous operation — the unattended loop" (marked *revised r2*, ALGORITHM-v0.2-pathway-learner.md:595-644), + its §12 registration, + `docs/research/DATA-LAYER.md` §5 schema delta (`schedule`, `wake_events`, `work_unit_closed`, `owner`/`lease_expires_at` on `work_unit_opened`, `schedule_id?` on `dispatch`) |
| Proposed change | Round-2 fix set: (1) a single three-way recovery predicate (RESUME / `unknown` / no-op) replacing the ambiguous rule from round 1, schema-backed by `owner{pid, started_at}` + heartbeat-refreshed `lease_expires_at`; (2) sustained gate-posture deferral made a reportable, always-delivered alert; (3) `agent_id` added to `schedule`/`wake_events`; (4) two new invariant tests (`test_gate_posture_defers_never_loosens`, `test_solve_cannot_write_schedule_or_closures`); (5) `schedule_id?` column on `dispatch` specifying the schedule→dispatch mapping |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Prior round | `docs/research/reviews/S20-continuous-operation-review.md` — overall 58/100, needs-revision, 6 blocking items |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Direct review-report write is permitted (not proposal mode).

## Round-1 closure ledger (verified against the current text)

| # | Round-1 blocking item | Status | Evidence |
|---|---|---|---|
| 1 | Ambiguity-rule vs. resume-from-truth conflict; no schema for "owner proved dead" | **Substantially closed, one residual gap found** | ALGORITHM-v0.2-pathway-learner.md:608-612 states one three-way predicate; DATA-LAYER.md:145 adds `owner{pid,started_at}` + `lease_expires_at` to `work_unit_opened`. See Correctness §1 below for the residual (a fourth, uncovered observable state). |
| 2 | Test for the boundary | **Closed** | `test_recovery_predicate_three_way`, ALGORITHM-v0.2-pathway-learner.md:643 |
| 3 | §5.3 coverage-floor scope vs. gate-posture deferral unstated; no alertable signal for suppressed growth | **Alerting half closed; scoping half still unstated** | ALGORITHM-v0.2-pathway-learner.md:620 adds the always-delivered sustained-deferral alert + `test_sustained_deferral_surfaced` (line 643); but "expansion actions" is still never explicitly defined to include/exclude §5.3's floor-driven practice (§5.3, ALGORITHM-v0.2-pathway-learner.md:158-173) — see Red-team §3 and adversarial pass below. |
| 4 | Missing tests: gate-posture-never-loosens, SOLVE-cannot-write-schedule/closures | **Closed** | `test_gate_posture_defers_never_loosens`, `test_solve_cannot_write_schedule_or_closures`, ALGORITHM-v0.2-pathway-learner.md:643 |
| 5 | `schedule_id` → `dispatch` mapping unspecified | **Closed for the mapping itself; the non-eval-job sub-question from the same item is still open** | `dispatch{…, schedule_id?, …}`, DATA-LAYER.md:145; but whether infrastructural scheduled jobs without a natural `suite_id` are in scope for "ordinary §6.1 `dispatch`" is still unaddressed — see Implementability below. |
| — | (from Consistency, not separately numbered in round 1's verdict) `agent_id` missing on `schedule`/`wake_events` | **Closed** | `schedule(schedule_id, agent_id, …)`, `wake_events(id, agent_id, …)`, DATA-LAYER.md:145 |

Net: 4 of 6 items fully closed, 2 items half-closed (the alert/mapping half done, the scoping/edge-case half not). This is real, substantive progress — the two hardest items (the contradiction and its missing schema) are the ones most cleanly fixed.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 77 | pass |
| 2 | Design faithfulness | 86 | pass |
| 3 | Red-team resistance (CRITICAL) | 79 | pass |
| 4 | Implementability | 65 | weak |
| 5 | Safety / integrity (CRITICAL) | 75 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 73 | pass |
| 8 | Consistency | 83 | pass |
| 9 | Calibration / honesty | 72 | pass |

## Findings by dimension

### 1. Correctness

**The round-1 contradiction is genuinely resolved.** ALGORITHM-v0.2-pathway-learner.md:608-611 now states one predicate with three exhaustive-looking branches keyed off checkable schema fields (`owner{pid, started_at}`, `lease_expires_at` — DATA-LAYER.md:145): (1) RESUME iff proved-dead (`pid` gone OR lease expired past grace) ∧ reconstructable; (2) `unknown` iff undeterminable (predicate not evaluable, e.g. unreachable host with unexpired lease) ∨ unreconstructable; (3) terminal record ⇒ no-op. This is a materially better artifact than round 1's: the schema now backs the predicate (closing the "no mechanism makes 'owner proved dead' checkable" gap), and §20.2's claim that RESUME "inherits resume-from-truth wholesale" (line 607) is no longer in tension with the `unknown` rule, because the `unknown` rule is now scoped to a *disjoint* condition (undeterminable-or-unreconstructable) rather than overlapping "no terminal record," which is what created round 1's identical-observable-state clash.

**The evidence-integrity vs. operational-safety distinction is now coherent (this directly answers the round-1 follow-up question).** Line 609: RESUME is safe "because of identity" (§6.1 dedup — landed records dedupe, unlanded ones are first-time appends). Line 610: the `unknown` branch's justification explicitly *concedes* "even though identity would dedupe its evidence" and instead grounds the refusal-to-retry in "a second executor would burn budget and interleave side effects." This is a real, non-circular distinction: §6.1 identity protects the *evidence ledger* (what gets posterior-credited) unconditionally; it does **not** protect *operational* cost or *non-evidence* side effects (spend, external API calls, resource provisioning) from being duplicated by two live executors. That is a genuinely different failure mode from double-counted evidence, and the text is honest that it is the reason for the conservative `unknown`/no-retry choice, not a second evidence-integrity concern dressed up as one. This is the single best piece of new reasoning in the r2 revision.

**Residual gap: the "one three-way rule … no overlap" framing claims disjointness, but not exhaustiveness — and a fourth, uncovered state exists.** Consider an open work unit with no terminal record where the owner's liveness *can* be evaluated and evaluates to **alive** (`pid` exists, `started_at` matches, `lease_expires_at` not yet expired) — e.g., a race between an external supervisor (§20.6, line 630: "restart with backoff") launching a fresh process before the old one (frozen but not yet reaped, exactly the scenario the §20.6 OS-thread watchdog at line 629 exists to eventually kill) has actually exited. This state is:
- Not RESUME (fails "proved dead").
- Not `unknown`'s first disjunct — the text defines that disjunct as "the predicate **cannot be evaluated**" (line 610), but here it *can* be evaluated, and evaluates to "alive," which is a third truth value the text never names (dead / alive / undeterminable — only two of three get a named disposition).
- Not `unknown`'s second disjunct (unreconstructable) if the row is intact.
- Not the terminal-record no-op case.

So the "three-way, no overlap" claim (ALGORITHM-v0.2-pathway-learner.md:608) is disjoint as far as it goes, but it is **not shown to be exhaustive**, and I can construct a reachable state it doesn't cover. The likely-intended resolution — "if the owner is determinately alive, this is not an orphan at all; leave it alone, no-op, the real owner will close it" — is a safe and plausible default, but it is nowhere stated, and it matters precisely because `owner{pid, started_at}` was added *specifically* to make this predicate decidable (the pairing with `started_at` is clearly a PID-reuse guard) — the schema now supports distinguishing "alive" from "dead" from "undeterminable" as three distinct values, but the prose only assigns dispositions to two of them. This is a smaller, narrower version of round 1's gap (an edge case within an edge case, and one existing single-process/external-supervisor discipline makes low-probability) rather than a repeat of it, but it is a real incompleteness in a section whose central pitch is "one three-way rule … no overlap."

Also unresolved: `w_dead` (continuous-zero debounce, line 621), `s_idle·2^k` backoff (line 625), and the tier thresholds remain arithmetically sound as checked in round 1 — no new sign error found in any restated formula.

### 2. Design faithfulness

Unaffected by the fixes in a way that would newly diverge — the round-2 changes are additive refinements within the same §17.1/§6.1 pattern already assessed in round 1 as faithful (JUDGE-extension via §20.1/§20.8, no second lease system, reuse of §6.1 identity). The `owner`/`lease_expires_at` addition to `work_unit_opened` (DATA-LAYER.md:145) is a minimal, in-place schema extension rather than a new table or parallel mechanism — consistent with §20.2's own stated design principle ("no second lease system," line 607). The `schedule_id?` nullable FK on `dispatch` (DATA-LAYER.md:145) is the same minimal-surface move. No divergence found from §§2–15 layering or naming conventions.

### 3. Red-team resistance

- **The RC-1/measurement-independence class objection from round 1 is resolved on its own terms.** The fix doesn't just assert the ambiguity is gone — it explains *why* resume is safe (identity dedup) and *why* `unknown` is still conservative despite that safety (budget/side-effect risk, not evidence risk), which is exactly the kind of decoupled-measurement reasoning RC-1's patch pattern calls for (ALGORITHM-v0.1-redteam.md:36-39, "make the measurement independent of the optimization" — here, evidence correctness independent of operational cost). Good.
- **RC-7-adjacent risk: half-closed.** The always-delivered sustained-deferral alert (line 620, `test_sustained_deferral_surfaced`) substantially defuses the worst-case version of round 1's concern — even under the least charitable reading of "expansion actions" (one that includes §5.3's coverage-floor-driven practice, ALGORITHM-v0.2-pathway-learner.md:161,171), a human is now guaranteed to be notified that the system has sat in `degrade`/`critical` for `w_defer`/`n_defer`, regardless of whether that state is actually harming learning. But the section still never states the scope of "expansion actions" itself (ALGORITHM-v0.2-pathway-learner.md:620 is unchanged on this point since round 1) — so whether §5.3's RC-7 floor is protected from deferral, or merely eventually reported as deferred, remains prose-ambiguous. A careful reading of §5.3 (ALGORITHM-v0.2-pathway-learner.md:161, "`cands = enforce_coverage_floor(cands)`" runs inside ordinary SELECT, not as a distinct "expansion" action) supports the charitable reading that floor-driven practice is untouched by §20.4(c)'s deferral — but this is an inference from a different section, not an assertion in §20 itself, and it was flagged as exactly this in round 1 without being fixed.
- **RC-4-adjacent (no inverse/retention for `schedule`/`wake_events` rows):** unchanged from round 1 — still no GC/retention policy stated for either table (DATA-LAYER.md:145). This was noted in round 1 as non-blocking and remains non-blocking, but it is still an open gap relative to the section's own "no add without an inverse" framing elsewhere in the spec.
- What holds, reconfirmed: JUDGE immutability extended correctly (§20.8, line 639, "SOLVE has no write-path"), gate-posture monotonicity preserved and now tested (`test_gate_posture_defers_never_loosens`), self-preservation check unchanged (line 614).

### 4. Implementability

Mixed — one clean win, several round-1 gaps still open, and two new small gaps introduced by the fix itself.

- **Closed:** the `schedule_id` → `dispatch` mapping (round-1 Implementability finding #1) is now concrete: `dispatch{…, schedule_id?, …}` (DATA-LAYER.md:145). A developer no longer has to invent where the correlation lives.
- **Still open from round 1, unchanged:**
  - Non-eval infrastructural scheduled jobs (maintenance sweeps, digest emission) that lack a natural `suite_id`/`action_fingerprint` — §20.2 still doesn't say whether they route through the same `dispatch` schema (which still shows `suite_id` as a plain, non-optional field, DATA-LAYER.md:145) or need a documented exception.
  - The tier enum's ordering (`ample > degrade > critical > dead`, implied by "above/below the current tier," line 620) is still not declared as an explicit, machine-checkable ordered enum.
  - The idle-backoff counter `k`'s reset condition (line 625, `s_idle·2^k`) is still unstated — does one successful cycle reset it to 0?
  - Whether §20.7's digest content requires an LLM call or is purely templated is still unaddressed (line 636).
- **New, introduced by this round's own fix:**
  - **"Past grace" (line 609) is a new, load-bearing, unparameterized quantity.** The RESUME/`unknown` split now hinges on "`lease_expires_at` … has expired **past grace**" — but "grace" (a buffer against clock skew / heartbeat jitter before treating an expired lease as proof of death) appears nowhere in §20.9's parameter list (ALGORITHM-v0.2-pathway-learner.md:642: "`c_max` · `s_cycle` · `s_poll` · `e_max` · `s_err` · `s_idle`, `s_idle_max` · `w_dead` · `t_replenish` · `τ_stale` · `w_defer`/`n_defer` · per-deployment tier thresholds · per-kind lease TTLs" — no `grace` term, distinct from "lease TTLs" themselves). A developer has to invent both the value and its bound.
  - **The heartbeat-refresh cadence for `lease_expires_at` (line 609, 612) is unparameterized.** "Heartbeat-refreshed while the owner runs" implies a refresh interval, which is a new periodic write not named as a parameter anywhere in §12/§20.9's list, unlike every other timing constant in the section (`s_cycle`, `s_poll`, `s_err`, …).

### 5. Safety / integrity

**CRITICAL.** Substantially improved from round 1 — the section's single most safety-relevant mechanism (the recovery predicate) is now schema-backed and its two branches are individually defensible, closing round 1's core integrity concern (an undefined boundary in the mechanism that exists specifically to prevent evidence double-count / uncontrolled concurrent side effects). §20.8's JUDGE-ownership sentence (line 639, "SOLVE has no write-path") plus the new `test_solve_cannot_write_schedule_or_closures` (line 643) together give this an enforceable boundary, addressing round 1's Safety finding about the missing explicit no-write-path statement for the new tables (a stylistic nit remains: DATA-LAYER's own schema prose for `schedule`/`wake_events`/`work_unit_closed`, DATA-LAYER.md:145, doesn't repeat the JUDGE-ownership sentence the way §17.6's `scaffold_versions` prose does at DATA-LAYER.md:483 — the statement lives in ALGORITHM §20.8 instead, which is adequate but inconsistent in placement).

Score held at 75 (pass, not strong) for two reasons directly tied to safety: (a) the residual fourth-state gap in Correctness §1 above is itself a safety question — an implementation that defaults ambiguously on "owner determinately alive" could reintroduce exactly the concurrent-executor risk the `unknown` branch exists to prevent; (b) the newly-unparameterized "grace" buffer (Implementability, above) is a safety-relevant magnitude, not a cosmetic one — too short a grace risks declaring a genuinely-alive, merely-slow owner "dead" and triggering a concurrent resume; too long a grace delays legitimate recovery. Leaving it undefaulted and unbounded in a section whose own claims-rule invariant (line 633) demands "every claim … carries a TTL … no claimed-but-unexpirable state, ever" is a gap in the very invariant §20.6 states this mechanism satisfies.

### 6. Efficiency / cost

No new LLM calls introduced by the fix itself — the added schema fields (`owner`, `lease_expires_at`, `schedule_id?`) are plain columns, not new inference paths. One new, small, previously-nonexistent cost path: periodic heartbeat writes to refresh `lease_expires_at` while a work unit's owner runs (line 609, 612) — cheap and bounded, consistent with the section's orchestration-only framing, but its cadence is unparameterized (see Implementability) so its aggregate write volume cannot currently be bounded or reasoned about quantitatively. The pre-existing open question (whether §20.7 digest generation needs an LLM call) is unchanged from round 1 and still the largest unaccounted-for cost risk if it turns out to require one.

### 7. Completeness

Four new tests directly close four of round 1's five test gaps: `test_recovery_predicate_three_way`, `test_sustained_deferral_surfaced`, `test_gate_posture_defers_never_loosens`, `test_solve_cannot_write_schedule_or_closures` (all at ALGORITHM-v0.2-pathway-learner.md:643) — a genuinely responsive fix to round 1's Completeness finding. Residual gaps, some carried over and some newly exposed by the fix:
- No test for the fourth state identified under Correctness §1 (owner determinately alive at scan time) — the "three-way, no overlap" test name (`test_recovery_predicate_three_way`) tests the three named branches, not the completeness of the partition itself.
- No test for the `owner{pid, started_at}` pair's actual purpose (guarding against PID-reuse false positives) — nothing verifies that a reused `pid` with a mismatched `started_at` is correctly treated as "not the same owner."
- No retention/GC test or policy for `schedule`/`wake_events` rows (carried over from round 1, non-blocking).
- No test or stated bound for the idle-backoff reset condition (carried over from round 1).
- No test for the newly-introduced `grace` buffer or heartbeat cadence (new gap — untestable until parameterized).
- No test for the non-eval/no-`suite_id` scheduled-job case (carried over from round 1).

### 8. Consistency

- **`agent_id` inconsistency (round 1 finding) is closed.** `schedule(schedule_id, agent_id, …)` and `wake_events(id, agent_id, …)` (DATA-LAYER.md:145) now match the fleet-scoping convention every other post-§17.6 delta follows.
- **The wholesale-resume vs. ambiguity-rule tension (round 1 finding) is now much better reconciled** — see Correctness §1. One small residual tension remains: the claim "one three-way rule … no overlap" (line 608) is a disjointness claim presented with the rhetorical weight of a completeness claim, and the fourth-state gap means the section is not fully consistent with its own framing of itself as an exhaustive partition.
- §12 vs. §20.9 parameter registration remains consistent term-for-term (ALGORITHM-v0.2-pathway-learner.md:286 vs. 642) — but both lists are now *incomplete* relative to the mechanism as specified, since neither names `grace` or the heartbeat-refresh interval (see Implementability). This is a fresh, mechanical (not narrative) inconsistency: the artifact's own convention is "every new timing constant appears in §12/§20.9," and two new timing-relevant quantities introduced by this very round's fix don't.
- Otherwise consistent with §10, §6.1/§6.2 write discipline, and §11's ObservabilityPort framing (line 636).

### 9. Calibration / honesty

One genuinely good sign: the new test name `test_recovery_predicate_three_way` is annotated in-line as covering "the r2 contradiction regression" (ALGORITHM-v0.2-pathway-learner.md:643) — an unusually candid, self-referential acknowledgment that this specific mechanism has a documented history of getting the boundary wrong, embedded directly in the artifact rather than only in review history. That is the right instinct and better calibration than round 1 found elsewhere in the document.

Docked below "strong" for two reasons: (a) the "one three-way rule … no overlap" framing (line 608) asserts a stronger completeness property than the text actually establishes (see Correctness §1) — this is a small but real instance of overclaiming resolved-ness in the exact mechanism whose prior version was already caught overclaiming; (b) round 1's suggested honest-scope caveat (an explicit sentence flagging that the owner-proved-dead boundary is the least battle-tested part of the section and should be stress-tested before M-R, modeled on §17.6's own honest-scope paragraph, DATA-LAYER.md:508: "this narrows RC-6's stale-fallback exposure … it does not close it") was not added. Given this exact mechanism was the round-1 blocking finding, a brief acknowledgment of residual risk would have been the calibrated thing to write, and its absence is a missed opportunity rather than a fabrication.

## Strongest adversarial objection

**The fourth-state gap (Correctness §1) is not just a completeness nit — it recreates, in miniature, the exact class of risk the round-1 finding was about, inside the fix that was supposed to close it.**

The round-1 finding's core defect was: an implementer facing an unstated boundary condition has to *invent* a resolution, and either invented resolution has a failure mode (silently override resume-from-truth, or silently disable recovery for ordinary restarts). The r2 fix closes that for the *stated* three branches — but it reintroduces the identical structural problem one level down, for the *unstated* fourth branch (owner determinately alive, unit non-terminal, at scan time). An implementer who takes the "one three-way rule … no overlap" framing at face value (line 608) has no textual guidance for this state, and will invent one of two resolutions:

1. **Treat "not proved dead" as falling through to `unknown`'s "undeterminable" branch** (a plausible but literal misreading, since the text defines that branch as "cannot be evaluated," which is false here — it *can* be evaluated, to "alive"). This is the safe direction (no auto-resume), but it's an implementer's guess, not a specified behavior, and the resulting code would not match the prose it's supposedly implementing.
2. **Treat "not proved dead" as "leave alone, no-op"** (the answer this review believes is intended, and the safe one) — but this is also unstated, and a less careful implementation might instead treat any non-terminal, non-`unknown`-eligible unit as eligible for a *second* dispatch (since neither branch 1 nor branch 2 of the stated rule claims it), which is precisely the concurrent-executor / budget-burn / side-effect-interleaving scenario the `unknown` branch's own justification (line 610) was written to prevent.

The realistic trigger for this state is not exotic: it is exactly the external-supervisor-restart-before-the-old-process-fully-exits race that §20.6 (line 629-630) already names as a known risk category ("an independent OS-thread watchdog hard-exits the process on frozen loop-progress" — implying the watched process is *not instantly* dead when frozen, only eventually; "External supervisor … required for any unattended deployment" — implying restarts are a normal, expected event, not a rare one). So the very mechanism (§20.6) that makes this race plausible is adjacent, in the same section, to the recovery predicate (§20.2) that doesn't name a disposition for it. This is the strongest objection because it shows the r2 fix, while a real and substantive improvement, did not fully finish the job it set out to do — it moved the undefined boundary rather than eliminating the category of undefined boundary.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(77, 79, 75) = 75
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (77*2 + 86 + 79*2 + 65 + 75*2 + 78 + 73 + 83 + 72) / 11
                = (154 + 86 + 158 + 65 + 150 + 78 + 73 + 83 + 72) / 11
                = 919 / 11
                = 83.5
overall         = min(75, 83.5) = 75
```

**Overall confidence: 75 / 100**

## Verdict

**needs-revision**

Round 1's overall score of 58 → 75 is real, substantive progress: the ambiguity that made round 1 blocking is genuinely resolved, with a coherent, non-circular safety argument behind it, and 4 of the 5 missing tests are now present. The remaining distance to 80 is narrower and more localized than round 1's, but the formula still caps the score below 80 because every CRITICAL dimension (Correctness 77, Red-team 79, Safety 75) sits in the 75-79 band rather than ≥80 — each has at least one concrete, unresolved item tied to it. Blocking changes required to clear 80:

1. **State the disposition for the fourth state** identified in Correctness §1 / the adversarial pass: an open, non-terminal work unit whose owner is *determinately alive* (pid exists, `started_at` matches, lease not expired) at recovery-scan time. State explicitly that this is a no-op (left for its actual owner to close), add this as a fourth named case (or fold it into a restated, genuinely-exhaustive two-axis truth table: {dead, alive, undeterminable} × {reconstructable, unreconstructable}), and add a test (e.g. `test_owner_alive_at_scan_is_noop`) so the boundary is enforceable, not just prose — mirroring exactly what round 1 asked for the original contradiction.
2. **Parameterize `grace`** (the buffer applied to `lease_expires_at` before treating an expired lease as proof of death) and the **heartbeat-refresh cadence** for `lease_expires_at` — register both in §12/§20.9 alongside the other timing constants, with defaults and bounds, since both are now load-bearing for the safety-critical recovery predicate.
3. **State explicitly whether "expansion actions" (§20.4c) includes or excludes §5.3's coverage-floor-driven practice** — the alert now surfaces sustained deferral regardless, which closes the worst-case silence, but the underlying scope question from round 1 is still open prose-level ambiguity in the same sentence it was found in.
4. **Resolve the two carried-over Implementability gaps that remain load-bearing:** the idle-backoff counter's reset condition (§20.5.3), and whether non-`suite_id` infrastructural scheduled jobs are in scope for "ordinary §6.1 `dispatch`" reuse (§20.2) or need a documented exception.
5. **Add a test for the `owner{pid, started_at}` pair's PID-reuse-guard purpose** — nothing currently verifies that a reused `pid` with a mismatched `started_at` is treated as a *different*, non-matching owner rather than a false "still alive" signal.

Items 1 and 2 are the load-bearing ones (they alone would likely lift Correctness/Safety into the 80s and clear the critical floor); items 3-5 are narrower carry-overs and would primarily move Implementability/Completeness.
