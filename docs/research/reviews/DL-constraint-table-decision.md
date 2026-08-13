# Decision: APPROVED — DL-constraint-table

**Date:** 2026-08-13
**Approver:** change-approver
**Review source:** docs/research/reviews/DL-constraint-table-review-r2.md (round 2; round 1 at docs/research/reviews/DL-constraint-table-review.md, 52/100, needs-revision)

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 82 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 82 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 82 | >= 70 | PASS |
| G2: Safety floor | Safety score | 85 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**

All three gates pass on the r2 review's own numbers. G1: overall confidence 82 clears the >80 threshold. G2: all three critical-dimension floors clear >=70 (Correctness 82, Red-team resistance 82, Safety 85). G3: r2's own verdict is "ready-for-approval" — all five of round 1's numbered blocking items (MergeReport/severity-conveyance contradiction, single-family predicate schema, C-RETIRE-PROVENANCE anchor mismatch, unwired warning-surfacing promise, C-FANIN-CAP false-registration claim) are verified fixed against the text, and round 2 leaves zero items tagged blocking — the two residuals it surfaces (round 1 item 6: atomic `table_version` assignment + node/edge collection scope; a newly-found `constraint_flag` emission durability gap) are explicitly scored and labeled non-blocking by the reviewer ("does not push any CRITICAL dimension below 70... not upgraded to a root-cause reopening," review r2 lines 39-41, 72, 102, 125-127).

**Check-on-the-checker:** scanned r2's findings body for any item tagged critical/blocking/must-fix/severity>=HIGH. None found — the two residuals are explicitly framed as "narrower," "residual watch item," and "not blocking at this score" by the review itself, consistent with the headline 82. No miscalibration detected.

**Post-review disposition (verified, not a re-review).** Both r2 residuals were independently addressed after r2 was filed, each along the line the review itself specified as the fix path, and I verified both passages directly in `docs/research/DATA-LAYER.md` §6.3 as of this decision:
1. **Emission-durability gap (r2 adversarial pass, lines 39, 72, 102, 127) — closed.** DATA-LAYER.md:251 now reads: "`constraint_flag` ids are deterministic — `hash(\"constraint_flag\" ‖ merge_report_ref ‖ constraint_id ‖ target_id)` — and the merge report itself is archived with the cycle outcome (§20.7(a)), so the recovery scan re-derives and re-emits any flags lost between `merge()` returning and the appends landing; re-emission dedupes by identity (`test_flag_emission_crash_recoverable`)." This matches the caller's disposition claim: deterministic flag ids, archived merge report per §20.7(a), identity-dedupe recovery, new named test.
2. **Round 1 item 6 (r2 lines 41, 64-65, 82-83, 126) — closed.** DATA-LAYER.md:246 now states: "**Evaluation scope by target:** `node`-target entries evaluate over `delta.adds`, `edge`-target over `delta.edges` and `delta.edge_updates`, `delta`-target over the whole delta... `table_version` is assigned atomically in the registration append's own transaction — the §6.1 `seq` pattern, no second counter mechanism." This matches the caller's disposition claim: per-target collection scope defined (node→adds, edge→edges+edge_updates, delta→whole), atomic `table_version` assignment via the §6.1 seq pattern.

Neither residual was load-bearing for this decision's G3 (the review itself did not classify them as blocking), but their closure is a genuine strengthening beyond what r2 scored, and is recorded here for the audit trail rather than left implicit.

**Advisory (non-blocking) items the implementer should still be aware of**, carried over from r2 and not superseded by the disposition above:
- The "PR-6 strengthened" property-impact summary line (DATA-LAYER.md:241/§21.3) remains a blanket claim, while the underlying `C-LIVENESS-SHAPE` entry correctly self-scopes to the suite-presence half only (calibration note, r2 §2/§9, carried from round 1, non-blocking).
- No stated growth/retention bound for `constraint_table` version history, unlike the explicit 30-day bound on `w_rejected` (r2 §7, Completeness).
- `C-FANIN-CAP`'s cost claim doesn't call out that its check reads existing incoming edges (proportional to current fan-in, not literally O(|delta|)) (r2 §6, Efficiency, non-blocking, carried over).
- The gate-free amendment path still lets a JUDGE-side operator remove a `warning`/`info` entry (including `C-RETIRE-PROVENANCE`) unilaterally with only a self-supplied rationale string (r2 §3, Red-team resistance, watch item — not a root-cause reopening).

## Next step

**Authorized for commit.** This decision record authorizes the change described in `DL-constraint-table-review-r2.md` (DATA-LAYER.md §6.3, plus its co-dependent §5 event-kind deltas, the §6.1 exemption-list line, and the §6.2 `MergeReport` schema line) to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit. The advisory items listed above are non-blocking and do not require a re-review round, but should be tracked (e.g. in `docs/evolution/backlog.md`) for a future light follow-up delta if they recur or grow in cost.
