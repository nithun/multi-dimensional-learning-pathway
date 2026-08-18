# TA implementation audit — 2026-08-18 (IX-064)

**Method:** read-only, three parallel auditors over `/Users/samyoga/dev/turing-agents` (L-012 honored — nothing written there; git reads, grep, file reads only). **Baseline:** the 2026-07-28 audit (IX-040, TA `949ed74`, fed HANDOVER-v3's G1–G7). **HEAD at audit:** `d9e78ac`, branch `build`, 2026-08-18 — **356 commits past baseline** (+42,334/−432 across 252 files; bursty: 110 commits on 08-12, 174 on 08-13). Working tree dirty (framework memory + untracked briefs/scripts). Tests: 143 files / ~2,164 test functions; **no live CI** (the README badge points at a workflow that does not exist; `pytest.ini` collects `tests/` only, so `mdlp/tests`' 41 files need a separate invocation).

## Executive verdict against HANDOVER-v3's gap map

| Gap | 2026-07-28 | **2026-08-18** | Movement |
|---|---|---|---|
| **G1** six audit bugs | open | **✅ ALL SIX FIXED** — verified in source, not commit messages | closed (W1.x series) |
| **G2** adopt §6.1/§6.2 | open | **✅ FULLY IMPLEMENTED, both tiers** + beyond-spec `CellDelta`/`StateStore.merge` | closed (W2.x + T-135) |
| **G3** wire-or-retract | open | **❌ 5/5 UNCHANGED** — nothing wired, nothing retracted; W4.7 never started | none |
| **G4** representative corpus | open | **❌ no coding corpus** — but a real-data *classification* corpus (B-041) exists at signed power; the MDLP track is FROZEN on two founder decisions | pivoted, blocked on owner |
| **G5** autonomy loop | open | **❌ absent** — no supervisor, no schedule table, no wake queue, no external watchdog; rung-0 propose-only | none |
| G6 model providers | open | not directly probed this pass (no provider modules appeared in the layout diff) | — |
| G7 observability | open | not directly probed; no ObservabilityPort adapters in the layout diff | — |

**M-R = representative + resumable + unattended:** resumable's substrate is now real (work units, leases-at-the-row-level via `open_work_unit`, true appends, `AppendResult`); representative and unattended have not moved and both sit behind named blockers — one of them **the owner's own pending decision** (below).

## G1 — all six fixed, with the receipts

- **A5 pair:** `agreement()` is gone; `warmstart.py:86` `diversity()` = mean pairwise `1−cosine` over *features*, sign un-inverted; lone-neighbor returns 0.0 (was 1.0); anchor set **enforced by default** (`_assert_anchor_set`, raises on ragged/1-D). Sole opt-out is a documented toy-harness path.
- **`rebuild_all` flush:** `stores/rebuild.py:148` `flush_all()` after rebuild, on both tiers; the inline comment names the original defect (invalidating an unregistered checkpoint id, which Redis correctly no-opped).
- **Upsert-not-append:** `INSERT OR IGNORE` / `ON CONFLICT DO NOTHING` on `append_event`/`record_eval`, both tiers; dedup surfaced via `AppendResult.deduped`. Surviving upsert only on `lineage` (posterior-inert, justified inline).
- **`decision.py` sign:** `reach_blend()` at `decision.py:42-56` — `q·rw` for `q≥0`, `q·(2−rw)` for `q<0`; docstring quantifies the old failure (fired ~half the time in cold start).
- **B4 `S0`:** `scheduler.py:57-67` `max(s_unit·mastery(skill), s_min)`, wired to the slow posterior at the live call site (`corpus.py:440`). Residual: `mastery=None` fallback reachable for standalone construction (documented).

## G2 — the write discipline is adopted, both tiers

All fourteen probed constructs present in production source: `intent_key`/`dispatch`+atomic `seq` · `open_work_unit`/`WorkUnit`/`UnknownIntentKey` · `AppendResult`/`rejected_reason` · `RedactedTruthView` (refusing writes and `open_work_unit`) · two-bundle `Bundles{judge, solve}` wired at `build_stores` · `GraphDelta`/`MergeReport`/`GraphStore.merge` (embedded + Neo4j) · rebuild routing through one coalesced `merge()` · `skill_merge` replay. Beyond spec: the state tier gained `CellDelta` + `StateStore.merge`, with `put()` docstring-narrowed to REBUILD-ONLY.

**Residual (report-grade):** `GraphStore.add_skill` survives as an unguarded second write path — zero production callers, guarded only by a negative-assertion test, no rebuild-only docstring. This is *exactly* the class DL §6.3's constraint table + §21's unproved-property rule exist to catch; when the 2026-08-13 wave crosses, `C-LIVENESS-SHAPE`/the sole-write-path property give it a name.

## G3 — the credibility gap has not moved, and TA knows it

The live path is `LiveLearningRun.run()` (`corpus.py:503-614`); its import surface is the whole story:

1. **§14 calibrator — hermetic.** Zero non-test importers; `estimate()` returns the raw posterior. Sharpest finding: **`scheduler.py:51` comments that the posterior is "§14-calibrated," which is false of the code** — a documentation claim contradicting the import graph. W4.7's own acceptance clause ("calibrator behind `estimate()` **or retract §14's claim**") is unmet in both branches.
2. **Rollback/breaker/drift — hermetic.** `corpus.py:43` imports *only* `commit_gate` from `loop` (the WBS's own acceptance grep, still failing verbatim). `drift_estimate()` is **written every tick and read by nothing** — a computed-and-discarded signal.
3. **Full §4 verifier — hermetic.** Live path is `exact_check` string matching; no shape check, no counterfactual, no variant producer; `VerifierRegistry.admit()` exists with only a test caller.
4. **A1 `U(a)` — hermetic**, and honestly self-declared: `decision.py:16-23` states in-code that the A1 objective "is NOT wired into `choose()`."
5. **§16 retrieval — fully hermetic** (now 5 modes; `artifact` mode removed 08-12). The live loop retrieves through the simpler `SkillLibrary.retrieve()`.

**TA's own retrospective filed this as L-044** ("built-but-unwired, in two unrelated tracks at once"), linking a 26KB merged-but-unregistered containment guard to "MDLP's G3 constructs [as] the same pathology." The pathology now has an internal name and an internal lesson — and five standing instances.

## G4 — the corpus energy went somewhere real, but not to MDLP's coding corpus

- **No pytest-verified coding corpus exists.** MDLP's live evidence remains the four cipher/toy skills; `docs/mdlp/results/` hasn't received a commit since 2026-07-02.
- **What exists instead: B-041** — 420 *real* commits harvested from TA's own history, 218 held-out / 202 public, at signed power (n*=417), RC-2 non-leak checked, duplication-audited (2.8%). But it is a **classification corpus** (label a commit's work area; exact-match grader) for TA's proof loop — *no agent writes a patch, no test suite runs*. The WBS's Finding D treats M1-EVAL-PROTOCOL's corpus and B-041 as the same build; as of HEAD they are not the same thing, and the difference is precisely "coding task with executable verifier."
- **The MDLP track is FROZEN on the board "until campaign," and the WBS names two HARD BLOCKs on the critical path that are the founder's:** W3.0 (corpus decision) and W3.7 (pre-registration signing). The two B-041 control runs from 08-13 are archived as `.invalid-*`.

**Relevance of this repo's IMPL-PROTOCOL (WP-C):** the spec-as-corpus design answers W3.0's shape exactly — real coding tasks, pytest-verified, available without new harvesting — and §21.2's conformance definitions are already its metric vocabulary. It is a candidate input to the W3.0 decision, not a substitute for it.

## G5 — autonomy remains a one-shot tick

No `while true` supervisor (the only one in the repo is an SSE keep-alive); the daemon is a launchd 25-minute one-shot with locks and watermarks; no schedule table or lease columns in the truth DDL (`events`,`evals`,`lineage`,`dispatches`,`dispatch_seq`,`work_units` — nothing more); no wake queue; **no external freshness watchdog** (the WBS's own gate for any unattended run); budget control is per-surface wall-clock **kill** caps — exactly the "budget exhaustion collapses into generic failure" shape §20.5.4 forbids. Autonomy is live but rung-0 propose-only (grants file absent, verified).

## Items that must cross via the owner (L-012 — both directions)

1. **Inbound to TA (not yet carried):** the entire 2026-08-13 spec wave — §21 safety properties, DL §12 conformance checker, DL §6.3 constraint table, §20.10 learning liveness, §10.1 epoch discipline, IMPL-PROTOCOL. **Zero trace in TA** (verified by name and content grep). §21/DL §12 would convert G3's five instances from audit findings into named, checkable non-conformances; §6.3 would catch the `add_skill` residual; IMPL-PROTOCOL feeds W3.0.
2. **Outbound from TA (waiting on the founder, recorded in TA's briefs):** an **A5 measurement-invalidation finding that corrects a claim in HANDOVER-v3 §1** — TA's 2026-08-10 session-handover states the corrected A5 head-start figure "only the founder can carry across." This repo's HANDOVER-v3 §1 is therefore known-stale on one A5 claim, pending that crossing.
3. **Decisions blocking TA's critical path:** W3.0 (corpus) and W3.7 (pre-registration signing) — the board freeze is waiting on these, not on engineering.

## Honest overall status

The **foundation half of M-R is built**: identity, idempotency, redaction, merge discipline — adopted beyond spec, with the six correctness bugs gone. The **credibility half has not moved**: the five unwired constructs of IX-040 are the same five, the corpus is still ciphers (for MDLP), and unattended operation lacks its first gate (the watchdog). The bottleneck has visibly shifted from *engineering* to *two founder decisions plus one hand-carry* — and the spec wave sitting un-crossed in this repo is the exact tooling TA's own L-044 pathology calls for.

*Auditors' full evidence (file:line citations throughout) is preserved in this audit's three source reports; facts here were compiled from them without re-derivation. Next audit should re-probe G6/G7, which this pass covered only via layout diff.*
