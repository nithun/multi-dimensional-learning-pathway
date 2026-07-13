# Decision: APPROVED — DL-write-discipline

**Date:** 2026-07-13
**Approver:** change-approver
**Review source:** docs/research/reviews/DL-write-discipline-review-r12.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 83 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 85 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 83 | >= 70 | PASS |
| G2: Safety floor | Safety score | 84 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**

All three gates pass. G1: overall confidence is 83, clearing the >80 bar for the first time in this artifact's twelve-round gate history. G2: all three CRITICAL dimensions clear the 70 floor with margin — Correctness 85, Red-team resistance 83, Safety/integrity 84 — none below 80 for the first time across all twelve rounds. G3: round-12's own independent audit re-verifies, item by item, that all five of round 11's numbered blocking items are genuinely closed with no fresh regression in the same mechanisms: (1) the two-bundle architecture (`Bundles{judge, solve}`) is now wired into both of `DATA-LAYER.md`'s own worked examples (§4 `build_stores()` at `:132-136`, §8 `EvolutionLoop` DI at `:255-262`), resolving the document-internal contradiction round 11 flagged; (2) `RedactedTruthView` now appears in the canonical §2.1 `Protocol` block (`:59-60`) and the §6.1 Port-delta line (`:197`), not only in prose; (3) the full-tier `seq` counter's first-creation race is closed via a named atomic upsert (`:179`) with a matching test (`test_first_dispatch_upsert_race`); (4) the round-11 adversarial objection — no stated mechanism preventing a `self_modify` candidate from acquiring an unredacted read reference — is answered with a named, separate admission check plus a sandbox backstop and an explicit M3-only scope (`:187`, `test_solve_candidate_cannot_import_unredacted_truth`); (5) the `UnknownIntentKey` inline-comment gap, carried three rounds, is closed (`:53`).

Check-on-the-checker: I scanned the review body, not just the summary table, for any item tagged critical, blocking, must-fix, or severity >= HIGH. The review's "Strongest adversarial objection" (the aggregation-granularity gap on `RedactedTruthView`'s `n_pass`/`n_total` pass-through) is discussed in serious terms — it sits on the same P1 measurement-independence boundary this section exists to protect — but the reviewer explicitly and consistently frames it as non-blocking throughout the report ("neither blocking at 83/100," "reserved for the adversarial pass," "does not rise to the severity of a numbered blocking item"), and — decisively — the reviewer already priced it into the Safety score, capping Safety at 84 ("acceptable") rather than scoring higher, with the finding named as the explicit reason for that cap. This is the opposite of the miscalibration pattern the override rule targets: a miscalibrated review buries a critical finding while the headline score ignores it. Here the finding is surfaced prominently (as the report's own designated "strongest adversarial objection") and is reflected in the dimension score that would carry it. There is no numbered blocking item left open, no tag of critical/must-fix/HIGH severity anywhere in the report, and the score-vs-finding relationship is internally consistent rather than contradictory. I therefore do not override to REJECT.

I also independently weighed whether the objection's substance — a live-remaining channel through which a SOLVE-side component's arbitrarily narrow retrieval filter could turn a small work unit's aggregate `n_pass/n_total` into a de facto item-level signal, reopening RC-2's memorization concern on the exact P1 boundary this section exists to protect — should be treated as a de facto blocker regardless of the reviewer's label. Two things keep it on the advisory side of the line for this round: (a) it is explicitly a newly-surfaced, narrower finding from this round's own added precision, not one of round 11's required items nor a regression in an already-fixed mechanism; and (b) the exploit path is conditional ("in principle," "presumably," dependent on filter-shape assumptions not established in either document) rather than a demonstrated, concrete break of a stated guarantee — consistent with the S16/R1/S17-6/B2-amendA precedent of carrying similarly-scoped non-blocking residuals as advisories into implementation rather than forcing another gate round.

## Advisories carried forward (non-blocking, per S16/R1/S17-6/B2-amendA precedent)

1. **`RedactedTruthView`'s write-method contract is implicit, not explicit.** The class body (`:59-60`) shows a docstring but no method overrides; a literal reading (inheriting `TruthStore`'s `...`-bodied stubs) defaults to silent no-op/`None`-return rather than raise or an enforced pass-through-only contract. Architecturally unreachable-from-SOLVE given the wiring shown, but the type itself does not say so. A one-line addition (e.g., "write methods raise `NotImplementedError`") would close this.
2. **No stated floor on aggregate granularity for `RedactedTruthView`'s pass-through `n_pass`/`n_total` fields.** A sufficiently narrow retrieval filter (by `checkpoint_id`/`attempt_idx`/difficulty band) could in principle isolate a single small work unit's aggregate as a de facto item-level signal without ever surfacing an `item_id`, touching the same P1 boundary (measurement independence from optimization) RC-2 exists to protect. Naming a minimum-`n_total` floor for pass-through aggregates, or a query-shape restriction on the redacted view, would close this residual attack surface.

## Next step

**Authorized for commit.** This decision record authorizes the additive design change described in
`docs/research/reviews/DL-write-discipline-review-r12.md` — `DATA-LAYER.md` §6.1 ("Idempotent evidence — occurrence-identity hashing"), §6.2 ("Two-phase projection writes"), and their §2.1/§5/§8 schema-and-port deltas — to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit, and should carry both advisories above into the implementation phase (or a future documentation pass) rather than treating them as closed.
