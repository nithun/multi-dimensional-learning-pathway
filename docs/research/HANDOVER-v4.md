# HANDOVER-v4 — task-list handover to TA (2026-08-18)

**Supersedes:** HANDOVER-v3 (2026-07-28). **Baseline:** `AUDIT-TA-2026-08.md` (TA `d9e78ac`, `build`, 356 commits past IX-040). **Crossing rule:** this document and every artifact it lists cross to TA **by the founder's hand only** (L-012). Task ids here are `H4-n`; map them onto TA's board (`T-xxx`) and WBS streams (`W*`) as they land.

**Known-stale note, carried honestly:** TA holds an **A5 measurement-invalidation finding that corrects a claim in HANDOVER-v3 §1** (TA brief `2026-08-10-session-handover.md:117`). v4 does not repeat v3 §1's A5 head-start figure; H4-1 reconciles it. Until then, cite TA's brief, not v3 §1, for A5 numbers.

## Status in one table (from the audit — details there, not repeated here)

| Gap | Status at TA `d9e78ac` |
|---|---|
| G1 six bugs | ✅ fixed, source-verified |
| G2 §6.1/§6.2 | ✅ adopted both tiers, beyond spec (`CellDelta`) |
| G3 wire-or-retract | ❌ 5/5 hermetic; W4.7 never started; TA's own L-044 names the pathology |
| G4 corpus | ❌ ciphers only for MDLP; B-041 (420 real commits, signed power) is classification-class; track frozen on W3.0/W3.7 |
| G5 autonomy | ❌ launchd one-shot; no supervisor/schedule/wake/watchdog; rung-0 |

## What crosses WITH this handover (the 2026-08-13 spec wave — zero trace in TA today)

Copy these eight files (plus their decision records under `docs/research/reviews/`, prefixes `S21-`, `DL-conformance-checker-`, `DL-constraint-table-`, `S20-10-`, `S10-1-`) into TA's `docs/mdlp/` reference set:

1. `ALGORITHM-v0.2-pathway-learner.md` — now §1–§21 incl. **§10.1** epoch discipline, **§20.10** learning liveness, **§21** safety properties (ten PR-1..PR-10)
2. `DATA-LAYER.md` — now incl. **§6.3** constraint table, **§12** conformance checker
3. `IMPL-PROTOCOL.md` — the pre-registered implementability study (feeds W3.0)
4. `AUDIT-TA-2026-08.md` — this handover's evidence base
5. `PLAN-harvest-2026-08.md` — context for why these exist
6–8. The three 2026-08 studies if TA wants provenance (`STUDY-ontologies-and-raft`, `STUDY-ontologies-for-mdlp`, `STUDY-llms-cant-jump`)

---

## The task list

### T0 — Reconciliation (first, cheap, unblocks the rest)

- **H4-0 · Register the crossing.** Land the files above in TA's `docs/mdlp/`; update `LINKAGE.md`. *Accept:* files present; LINKAGE row per artifact with its decision-record path.
- **H4-1 · A5 reverse-crossing.** Founder carries TA's corrected A5 figure back into MDLP (one paragraph appended to this file, marked reconciled, citing TA's brief). *Accept:* v4 carries the corrected number; v3 §1 marked superseded-on-A5.

### T1 — Wire-or-retract (G3 ≙ W4.7 — the credibility debt; five standing instances + one new)

*Every task below is now checkable by §21.2's rule: a mechanism is conformant only if the canonical run's truth trace evidences it. Do H4-8 first or in parallel — it makes these verdicts mechanical instead of grep-archaeology. Each task's own acceptance is the WBS's grep plus the checker's status flip (`unevidenced → conformant`). Per §21.3, each carries a property-impact statement; "retract" is a legitimate outcome and costs one honest doc line.*

- **H4-2 · §14 calibrator.** Behind `estimate()` — or retract §14's claim. Either way **fix `scheduler.py:51`**, which today falsely calls the posterior "§14-calibrated." *Accept:* `calibration.py` gains ≥1 non-test importer OR the claim is retracted in-code and in TA's `docs/mdlp/`; the false comment is gone in both branches.
- **H4-3 · Rollback / breaker / drift into the live tick.** `corpus.py` must import more than `commit_gate`; `drift_estimate()` must gain a reader (it is currently written every tick, read by nothing). *Accept:* WBS grep passes; §20.6 fire-test per alarm (synthetic drift trips rollback in a test harness).
- **H4-4 · Full §4 verifier on the live path.** Shape + counterfactual (a `variant_inp` producer) beyond `exact_check` — or retract to "output-assertion verifier" honestly in results docs. *Accept:* `DeterministicVerifier` (or successor) on the `LiveLearningRun` path with `VerifierRegistry.admit()` called; or retraction recorded.
- **H4-5 · A1 `U(a)` into `choose()`** — or retract A1's claim (resolving `decision.py:16-23`'s own honest TODO). *Accept:* `expected_info_gain` gains a live call site with A1's z-scored blend; or the in-code note becomes a formal retraction.
- **H4-6 · §16 retrieval.** Wire the 5-mode dispatch behind `SkillLibrary.retrieve()` — or formally park §16 as post-M-R (a retract-from-M-R, not a deletion). *Accept:* one of the two, recorded.
- **H4-7 · `add_skill` second write path (new, from this audit).** Docstring-narrow to REBUILD-ONLY (the `put()` precedent) or delete; zero production callers today. *Accept:* no unguarded structural write path outside `merge()` — which is exactly what H4-9's `C-LIVENESS-SHAPE` will then enforce mechanically.

### T2 — Adopt the spec wave (the tooling TA's L-044 calls for)

- **H4-8 · DL §12 conformance checker, MVP first.** `conformance.py` beside `rebuild.py`: the nine-property predicate table (honest statuses incl. `not_trace_checkable`) + the reachability manifest with always-fires/conditional classes. Run `incremental` at cycle end; `full` at milestone gates. *Accept:* a `conformance_report` event lands with all ten properties statused; the five G3 constructs show `unevidenced` **before** T1 and `conformant` **after** — the audit's finding, reproduced then retired by machine.
- **H4-9 · DL §6.3 constraint table.** Generalize `merge()`'s two hard-coded checks into the declared 7-entry table + `MergeReport.flags`. *Accept:* `test_migrated_acyclicity_identical` (rejection-set-identical) + one fire-test per entry.
- **H4-10 · §20.10 learning-liveness signals.** Three signals + three-state distinguisher in the cycle digest — cheap, zero schema delta, everything computes from truth TA already writes. *Accept:* the §20.10 check list's fire-tests; a stalled synthetic run alerts, a converged one reports.
- **H4-11 · §10.1 epoch discipline.** The κ_reval clamp registration, the synthetic in-generation eval at reactivation, the reverted-span ancestry rule. Mostly M3-horizon (§17.6 machinery) — land the clamp + the ancestry helper now, tag the rest M3. *Accept:* clamp test; ancestry comparison is lineage-walk, never wall-clock.

### T3 — The corpus (G4 ≙ W3.0/W3.7 — **founder-owned decisions**, this handover's recommendation)

- **H4-12 · Decide W3.0, with a concrete recommendation:** adopt **IMPL-PROTOCOL's spec-as-corpus as the G4 bridge** — real coding tasks (implement spec sections), pytest-verified via the stub bodies, existing today, pre-registered with frozen criteria. B-041 remains TA's proof-loop corpus; it is classification-class and does not satisfy "agent writes a patch, tests run." The two are complements, not competitors. *Accept:* a signed decision recorded in both repos (W3.7's signing covers the pre-registration).
- **H4-13 · If adopted: build the IMPL-PROTOCOL harness.** N=5 implementers, stub **bodies** held out (names public), frozen hashes before implementer 1, the driver executing §21.2's canonical run. This is the **representative leg of M-R**. *Accept:* IMPL-PROTOCOL §4's own gates (C-1..C-3); a GO admits the bridge corpus into the M1-EVAL slot; NO-GO ships the implementability map regardless.

### T4 — Autonomy (G5 ≙ W4.1–W4.6 — §20 is the build spec; sequence is load-bearing)

- **H4-14 · External freshness watchdog FIRST** (W4.1 — TA's own WBS gates any unattended run on it; §20.6: a separate process reading last-completed-work-unit from truth, alerting past `τ_stale`, with a fire-test).
- **H4-15 · Two-level supervisor + schedule table + wake queue** (§20.1–§20.3: outer `while true`, bounded inner cycle `c_max`, schedule rows + supervisor singleton lease in truth DDL, atomic consume-queue).
- **H4-16 · `tier()` replacing kill-only caps** (§20.4: pure total function, defer-never-loosen posture, budget exhaustion as a **distinct** signal — today a cap breach is an indistinguishable kill, the exact studied failure).

---

## Sequencing and the M-R restatement

```
T0 → (H4-8 ∥ T1) → T1 verified by checker
         T3 decision (founder) → H4-13 = representative leg
         T4 (watchdog first)   → unattended leg
M-R = T1 complete ∧ H4-13 run (GO or honest NO-GO) ∧ T4 complete — resumable leg already done (G2 ✓)
```

## What does NOT cross

RAF-2 / spec compression (parked on MDLP's [D-4], owner decision) · peer-learning and prospection notes (design directions, ungated) · anything in `.claude/` (framework-internal to each repo). TA's board numbering, estimates, and assignment remain TA's own.

*Provenance: every claim above traces to `AUDIT-TA-2026-08.md` (which carries file:line evidence) or to a gate-approved spec section with its decision record. Nothing here was written to TA; the crossing is the founder's act.*
