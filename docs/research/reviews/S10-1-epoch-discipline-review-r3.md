# 360 Review: S10-1-epoch-discipline — 2026-08-13 (round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` (uncommitted delta vs. committed baseline `HEAD`) |
| Proposed change | RAF-3 round 3: §10.1's in-body PR-10 quote now defers to the §21.1 table row as the single canonical guard list (no duplicate list); `test_stale_fleet_read_no_discount` is redefined as newly-defined-by-this-delta with an honest provenance note, in both locations that cite it |
| Round 1 | `docs/research/reviews/S10-1-epoch-discipline-review.md` — 50/100, needs-revision, six required changes |
| Round 2 | `docs/research/reviews/S10-1-epoch-discipline-review-r2.md` — 76/100, needs-revision, two narrow required changes (guard-list desync; false "existing" citation) plus two non-blocking carried gaps |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 88 | pass |
| 3 | Red-team resistance (CRITICAL) | 87 | pass |
| 4 | Implementability | 74 | weak |
| 5 | Safety / integrity (CRITICAL) | 82 | pass |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 79 | weak |
| 8 | Consistency | 89 | pass |
| 9 | Calibration / honesty | 81 | pass |

## Findings by dimension

### 1. Correctness

- **Round 2 blocker #1 (guard-list desync) is genuinely fixed, not just reworded.** The in-body PR-10 quote (`ALGORITHM-v0.2-pathway-learner.md:283`) no longer enumerates its own guard names at all. It now reads *"Guarded by: **the seven guards enumerated in the §21.1 PR-10 row — that row is the single canonical guard list** (this passage deliberately does not duplicate it; a duplicated list is how guard sets desynchronize, as this section's own round-2 review demonstrated on this exact passage)."* Independently counted: the §21.1 table row (`:708`) lists exactly seven test names (`test_no_consumer_reads_pending_fallback_as_validated`, `test_serve_marked_monitor_tightened`, `test_reactivation_dispatches_synthetic_eval_immediately`, `test_stale_fleet_read_no_discount`, `test_tree_stats_invalidated_on_checkpoint_change`, `test_cache_invalidated_on_checkpoint_change`, `test_reverted_span_never_serve_marked`) — matching the "seven guards" claim exactly. There is no second list left anywhere to drift out of sync with it; the fix is structural (single source of truth), not cosmetic.
- **Round 2 blocker #2 (false "(§18.7, existing)" citation) is genuinely fixed.** `test_stale_fleet_read_no_discount` is now described identically and accurately in both places that name it: the in-body quote (`:283`, "**defined by this delta** (in §10.1's checks) — §18.2's conservative-staleness mechanism predated the guard convention and had no test until now") and the Checks bullet (`:285`, "**defined here, owned by §18.2's mechanism** ... §18.7's own checks predate the guard convention and did not cover it"). Independently re-verified against §18.7's own Checks bullet (`:569`): it lists six tests (`test_fleet_of_one_equals_single_agent`, `test_no_cross_agent_state_read`, `test_transfer_revalidated_on_receiver_heldout`, `test_fleet_coverage_spreads_frontier`, `test_coverage_floor_dominates_fleet_discount`, `test_fleet_self_modify_cannot_collectively_capture_verifier`) — `test_stale_fleet_read_no_discount` is correctly absent from that list, so "not existing there" is no longer misdescribed as "existing." The behavioral assertion attached to it — "a `ĉ_j(k)` read older than `τ_cache` or missing yields `φ = 1`, no discount" (`:285`) — is verified word-accurate against §18.2's own text: *"the cached `ĉ_j(k)` has a max age `τ_cache`; a stale/missing read is treated **conservatively as no discount** (`φ = 1`)"* (`:549`). No remaining defect here.
- **`κ_reval` byte-identity re-verified for round 3's prose changes.** The round-3 diff further rewords the §17.6 rollback paragraph (`:525`) around the trip condition, but the load-bearing formula is untouched: `significant(Δ, SE)` trip fires at `κ_reval · z`, `κ_reval` default 0.5, unchanged from both the committed `HEAD` baseline and round 2's verified text. Confirmed via direct comparison of the `-`/`+` diff hunk — only surrounding prose ("the fallback is unvalidated-in-generation by the §10.1 rule," "the tightened rollback threshold serve-marked status obligates") changed; the formula, its default, and its clamp (`κ_reval ∈ (0,1]`, `:303`) are byte-identical to round 2.
- **A new, narrower instance of the same defect class rounds 1 and 2 both flagged ("asserted, not demonstrated") is present at `ALGORITHM-v0.2-pathway-learner.md:708`.** `test_tree_stats_invalidated_on_checkpoint_change` is one of the seven guards the in-body quote now defers to as "the single canonical guard list." It appears **exactly once** in the entire document — at `:708` — and nowhere else: not in §10.1's own "Checks (this section's additions)" bullet (`:285`, which lists eight other tests but not this one), not in §7's text (`:211-217`, which describes the underlying mechanism in prose — `"invalidate(node) discounts/resets value and visits for the affected subtree"`, `:214` — but names no test), and not in the committed `HEAD` baseline (confirmed via `git show HEAD:... | grep`, zero hits — the name is entirely new to this diff). Unlike the fixed `test_stale_fleet_read_no_discount` case, this is **not a false citation** (nothing in the current text calls it "existing" or otherwise misattributes it), and the mechanism it names is real and accurately described elsewhere — so it is materially milder than round 2's blocker. But it is asserted as one of "the seven guards" without the same "defined by this delta" / provenance treatment its sibling `test_stale_fleet_read_no_discount` received in this exact round's fix, at the exact same table row. The round-2 review already flagged this specific test's citation style as acceptable ("`test_tree_stats_invalidated_on_checkpoint_change` (§7)... correctly labeled," round 2 §7 finding), so this is not a new regression this round introduced — but the round-3 fix, in symmetrically resolving the sibling problem for `test_stale_fleet_read_no_discount`, leaves this parallel gap conspicuously unaddressed in the same passage that argues "guards already in the spec."

### 2. Design faithfulness

- The single-source-of-truth fix is a genuinely good design move: it removes a structural duplication rather than papering over it, and it is self-aware about why — citing its own round-2 review as the demonstration (`:283`). This is faithful to the project's stated anti-ratchet/consolidation discipline (§21.3, `:719`: "a duplicated list is how guard sets desynchronize" is now stated as the section's own design rationale, not just a reviewer's complaint).
- The `test_stale_fleet_read_no_discount` fix correctly follows the precedent §21.2 set for §9 ("the same close-the-coverage-gap move §21.2 made for §9," `:283`) — closing test coverage for a pre-existing, pre-guard-convention mechanism is an established, faithful pattern in this document, not an ad hoc justification.
- Everything else verified unchanged from round 2 (Raft/KIP provenance, the four-site framing, the rollback-branch ancestry rule) — no design-faithfulness regressions found.

### 3. Red-team resistance

- **Both headline RC-6/RC-5 protections round 2 verified remain intact and unchanged.** `κ_reval` byte-identity (Correctness, above) means the §17.3 post-promotion monitor's sensitivity on the serve-marked population is unchanged from the pre-RAF-3 baseline — RC-6 ("a restored artifact is never trusted against a moved world without fresh evidence," `docs/research/ALGORITHM-v0.1-redteam.md:59`) stays closed. The rollback-branch rule (`:279`, "mandatory invalidate-or-absent, never serve-marked" for a since-reverted span) is unchanged and still guarded by `test_reverted_span_never_serve_marked`.
- **The guard-list-desync audit-trail gap round 2 flagged as a residual is now closed, tightening rather than loosening the attack surface.** Round 2 noted a reader relying on the stale in-body list would understate PR-10's actual protection (an audit gap, not a reopened exploit). With the in-body list removed in favor of the single canonical reference, that gap no longer exists — a reader checking PR-10's guards from either location now sees the same, complete, correct picture.
- The new `test_tree_stats_invalidated_on_checkpoint_change` finding (Correctness, above) is a documentation/provenance gap, not an attack-surface change — the underlying mechanism (§7's checkpoint-change invalidation) is unchanged and was never in question; only the traceability of its test citation is incomplete.

### 4. Implementability

- The single-source-of-truth guard list is a net implementability improvement — a developer building against PR-10 now has exactly one place to check rather than two disagreeing ones.
- **Both of round 2's non-blocking carried gaps remain fully open and untouched by this round's diff:** (a) which `checkpoint_id` is authoritative for a scaffold candidate's "generation" at the §17.6 site is still not spelled out — `scaffold_versions` (`:509-521`, unchanged) still has no direct `checkpoint_id` field, and the `gate_ref` indirection is still not stated explicitly; (b) whether a second live-generation change during an in-flight synthetic eval invalidates that eval's evidence is still unaddressed. Neither was required to clear round 2's bar, and neither is required by round 3's stated scope, but both remain real, foreseeable gaps a developer will hit.
- The new `test_tree_stats_invalidated_on_checkpoint_change` finding (Correctness, above) is also an implementability gap in miniature: a developer told to implement "the guards already in the spec" for PR-10 will have no assertion text to build this one test from and will have to invent its pass condition from the one line of §7 prose that describes the mechanism, the same reverse-engineering burden `test_stale_fleet_read_no_discount` carried before this round's fix.

### 5. Safety / integrity

- **The substantive safety regression this whole review thread has tracked (the κ_reval sensitivity question) stays fixed and re-verified this round** — no new weakening introduced. §17.3's monitor (`:482`, unchanged) keeps its tuned sensitivity on the serve-marked population.
- **The admission's procedural leg — "mechanism *and* guards already in the spec" (`:719`) — is now much closer to cleanly met than round 2, but not perfectly clean.** Six of the seven canonical guards are either newly and transparently defined in §10.1's own Checks bullet (`:285`) or (for `test_stale_fleet_read_no_discount`) explicitly and honestly marked as newly-defined-for-a-pre-existing-mechanism. The seventh, `test_tree_stats_invalidated_on_checkpoint_change`, is asserted at the exact passage that makes this claim (`:708`, cited by `:283`'s "canonical guard list" reference) without the same demonstration — a narrower recurrence of the exact gap this round otherwise closed. This does not reopen any enforced gate (the real mechanism, §7's checkpoint-change invalidation, is unchanged and functioning) but the admission's own audit trail is not fully self-consistent at the level of rigor the rest of this round's fix achieves.
- The κ_reval `(0,1]` clamp and its guard (`test_kappa_reval_never_looser_than_standard`, `:303,285`) remain a genuine, well-specified safety improvement, unchanged from round 2.

### 6. Efficiency / cost

- No change from round 2's assessment: no new LLM calls, zero schema delta holds, no hot-path complexity change. Score unchanged at 88.

### 7. Completeness

- **Round 2's two required-change items (guard-list sync, false citation) are both resolved** — verified above.
- **The new `test_tree_stats_invalidated_on_checkpoint_change` gap (Correctness/Safety, above) is a genuine, if narrow, completeness shortfall** — one of seven canonical guards is unexplained anywhere in the document.
- **Both of round 2's non-blocking carried gaps remain open** (checkpoint_id indirection for the §17.6 site; second-epoch-change-mid-revalidation case) — unchanged from round 2, not addressed by this round's narrower scope.

### 8. Consistency

- **Round 2's headline consistency defect (two disagreeing "Guarded by" lists for the same property) is structurally eliminated**, not patched — independently re-verified by counting guard names at both locations: `:283` now names zero guards directly (deferring entirely to `:708`), so there is nothing left to disagree.
- Independently swept for stray "five site"/"fifth site" language (`grep -n -i "five site\|five place\|fifth site"`) — zero hits beyond the deliberate, correctly-scoped withdrawal note at `:278`. Swept for stray `κ_reval`-retirement language (`grep -n -i "κ_reval.*retir\|retir.*κ_reval"`) — zero hits. Swept `ALGORITHM-INTEGRATIONS.md` and `BUILD-SPECS.md` for RAF-3/epoch-discipline references — none found, which is expected and correct: §10.1 is explicitly marked "IN GATE" (`:270`) and has not been approved or synced downstream yet.
- §21.4's RC-6 row (`:733`) and §21.3's supersession bullet (`:721`) remain mutually consistent, unchanged from round 2's verified fix.

### 9. Calibration / honesty

- The single-source-of-truth design decision is unusually transparent about its own motivation — citing its own round-2 review by name as the evidence for the fix (`:283`, "as this section's own round-2 review demonstrated on this exact passage"). This is an honest, auditable form of self-correction, not narrative confidence.
- `test_stale_fleet_read_no_discount`'s new provenance framing ("defined by this delta," "predated the guard convention and had no test until now") is calibrated correctly — it neither overclaims prior coverage nor hides that this is a new test being introduced for old behavior.
- **The unflagged `test_tree_stats_invalidated_on_checkpoint_change` gap (Correctness, above) is a calibration miss of the same shape as the one just fixed** — the passage projects "seven guards, one honestly disclosed as newly-defined" when in fact a second guard in the same list has no textual backing anywhere and receives no disclosure at all. This is not a new overclaim introduced this round (the test's citation style is literally unchanged from round 2), but the round's overall framing — "the guard list is single-sourced... no parallel list remains to drift" — reads as a completeness claim about the whole list, when one entry in that single canonical source remains as unelaborated as the entry that was just fixed.

## Strongest adversarial objection

**The fix pattern applied this round targeted the specific defect the reviewer named, not the defect class — and the document's own canonical guard list still contains an instance of exactly that class.**

Round 2's finding was general in principle ("guards already in the spec" is the admission bar; a guard name with no supporting assertion anywhere fails that bar) but was illustrated with one concrete example (`test_stale_fleet_read_no_discount`, flagged because it carried a *false* "(§18.7, existing)" tag). Round 3's revision fixes that example precisely and well — but a second guard in the identical seven-item canonical list, `test_tree_stats_invalidated_on_checkpoint_change`, sits in the same underlying condition (asserted, backed by real prose elsewhere, but never spelled out as a testable assertion anywhere in the document) and received no equivalent treatment. It escaped this round's fix specifically because it doesn't carry a *false* citation — it carries *no* citation at all, which is a narrower but not absent version of the same problem. A submission that resolves the letter of a review finding (the false "(existing)" tag) without generalizing to the principle behind it (every canonical guard should be traceable to an assertion somewhere) is the textbook shape of a targeted patch rather than a systematic audit. This does not reopen any enforced protection — §7's mechanism is real and unchanged — but it means a reviewer who re-reads the canonical list line by line, rather than trusting that "the guard-list problem is fixed," still finds one entry that cannot yet be checked against a spelled-out assertion. Given this defect class has now surfaced in three consecutive rounds (§19.1 in round 1, `test_stale_fleet_read_no_discount` in round 2, `test_tree_stats_invalidated_on_checkpoint_change` implicitly carried through all three rounds unaddressed), it is worth the next revision explicitly re-running the audit against all seven canonical guards, not just the one most recently named, before treating "guards already in the spec" as settled.

## Aggregate confidence

```
critical_floor  = min(Correctness=85, RedTeam=87, Safety=82) = 82
weighted_mean   = (85*2 + 88 + 87*2 + 74 + 82*2 + 88 + 79 + 89 + 81) / 11
                = (170 + 88 + 174 + 74 + 164 + 88 + 79 + 89 + 81) / 11
                = 1007 / 11
                = 91.5 → 92
overall         = min(82, 92) = 82
```

**Overall confidence: 82 / 100**

## Verdict

**ready-for-approval**

Round 2's two required blockers are both substantively and structurally resolved — the guard-list desync is eliminated at the root (single canonical source, not a re-synced duplicate) and the false "(§18.7, existing)" citation is corrected with accurate, honest provenance in both locations that reference it. No CRITICAL dimension is below 70; the aggregate clears the 80 bar.

This is a `ready-for-approval` verdict, not an approval — that decision belongs to `change-approver`. If a further round is elected before that gate, the following residual items would be worth closing (none of them blocking at the current score):

1. Add the same "defined by / owned by" provenance treatment `test_stale_fleet_read_no_discount` received in this round to `test_tree_stats_invalidated_on_checkpoint_change` (`ALGORITHM-v0.2-pathway-learner.md:708`) — it is currently the one guard among the canonical seven with no supporting assertion anywhere in the document (not in §10.1's own Checks bullet, not in §7's text).
2. (Non-blocking, carried from round 2, still open) State which `checkpoint_id` is authoritative for a scaffold candidate's "generation" at the §17.6 site.
3. (Non-blocking, carried from round 2, still open) Address the second-epoch-change-mid-revalidation case.
