# 360 Review: DL-conformance-checker — round 2 — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §12 "Conformance checker — replaying truth against ALGORITHM §21" (uncommitted working tree), plus co-dependent deltas: §5's two new event kinds, §6.1's exemption-list entry, §2's `conformance.py` layout line, §11's bookkeeping status flip (all re-verified this round except as revised) |
| Proposed change | Round 2 of RAF-1b: predicate-table checkability downgrades (PR-5(i), PR-6(i), PR-8(iii), PR-9), cursor redaction mechanism, corrected event-kind count, `Port delta: none` + inline manifest content, §21.2 reconciliation for the always-fires/conditional bifurcation |
| Prior round | `docs/research/reviews/DL-conformance-checker-review.md` — 58/100, needs-revision, six required changes |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"`. Filing as a direct review report (not a proposal).

## Round-1 required-change disposition (summary before scoring)

| # | Required change | Verified this round |
|---|---|---|
| 1 | Downgrade/fix PR-8(iii) | **Done, verified correct.** `DATA-LAYER.md:388` now states the heartbeat-gap signature is not a trace predicate, cites the mutated (not append-only) `lease_expires_at` column, and routes it to guard territory. Checked against `lease_expires_at`'s definition at `DATA-LAYER.md:146` ("heartbeat-refreshed") and `ALGORITHM-v0.2-pathway-learner.md:609,611,614` — the column is indeed a single mutated field with no historical trail. No RC-numbered root cause covers heartbeat-gap detection (grepped `ALGORITHM-v0.1-redteam.md` RC-1..RC-8), so narrowing this to guard territory (`test_every_claim_has_ttl_or_probe`, §20.6 live probes) reopens nothing. |
| 2 | Downgrade PR-5(i)/PR-6(i) | **Done, verified correct.** `DATA-LAYER.md:385` splits PR-5(i) into the eval-row-shaped clauses (`sustained_heldout`, `MONITORED` no-regression — confirmed as ordinary `evals`-row checks against `ALGORITHM-v0.2-pathway-learner.md:253,259`) staying `full`, and the `human_spotcheck` conjunct downgraded to `conditional` (confirmed: no truth event kind named anywhere in §5 or §9's pseudocode for a spot-check). `DATA-LAYER.md:386` splits PR-6(i) identically — the split-check stays `full`, verifier-admission (`ρ_min`) downgraded to `conditional` (confirmed against `ALGORITHM-v0.2-pathway-learner.md:103,137`: `admit()`/`reliability_lowerCI(v)` are computed functions, not logged truth records). Both downgrades correctly follow the PR-3 pattern this round-1 review asked for. |
| 3 | Define/remove PR-9's window | **Done, verified correct.** `DATA-LAYER.md:389` flags the missing enforcement window as an ALGORITHM-side gap out of scope and makes the horizon an explicit maintenance-job argument, `not_trace_checkable` absent one. Confirmed against `ALGORITHM-v0.2-pathway-learner.md:158-183` (§5.3): no trailing window is named there for `f_min`. |
| 4 | Redaction mechanism for `cursor` | **Done, substantively.** `DATA-LAYER.md:146` adds a schema-level "Cursor redaction rule" restricting `cursor` to aggregate watermarks and explicitly stating PR-1's cursor holds only its scan high-water mark. `DATA-LAYER.md:368` extends the guarantee to "every field of both event kinds." This closes round 1's core Safety finding (a real mechanism, not just a test). Residual: `test_report_redacted` (`:410`) is textually scoped to "report field" / "any report field," not explicitly to `conformance_manifest`'s fields — low-risk since manifest content structurally carries no item data, but the stated "both event kinds" guarantee isn't mirrored by an equally explicit test for the manifest kind. |
| 5 | Preamble event-kind count | **Done, verified correct.** `DATA-LAYER.md:356` now reads "two administrative event kinds (`conformance_report` and `conformance_manifest`)." |
| 6 | Non-blocking items | **Partially done — one item reopens a contradiction.** `Port delta: none` statement added (`:369`), enumerating `schemas.py` additions and stating manifest content travels inline, removing the `ArtifactStore` blob dependency. **But `DATA-LAYER.md:398` was not updated to match** — see Correctness/Consistency finding below, this is the headline new defect. The §21.2 reconciliation is added (`:395`, see Design faithfulness). The Register scope note is added (`:406`), mirroring §11.4 exactly. PR-1(ii)'s complexity bound is stated (`:370`): `O(records_in_scope × payload_size)`, one pass, hash-set membership — correct and appropriately scoped to `incremental` vs `full`. |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 74 | pass |
| 2 | Design faithfulness | 78 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 64 | weak |
| 5 | Safety / integrity (CRITICAL) | 86 | pass |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 72 | pass |
| 8 | Consistency | 58 | weak |
| 9 | Calibration / honesty | 70 | pass |

## Findings by dimension

### 1. Correctness

The systemic round-1 pattern (four predicates claiming `full` checkability against evidence the schema doesn't establish) is genuinely fixed — verified independently against the cited ALGORITHM sections for all four (see table above). That was the dominant round-1 defect and it is resolved.

A new, citable self-contradiction was introduced by an incomplete edit of required change #6:

- **`DATA-LAYER.md:398`**: "A manifest version is registered by the administrative `conformance_manifest` event (§5: version + content hash; **the content itself is an ArtifactStore blob keyed by that hash**)…"
- This directly contradicts **`DATA-LAYER.md:146`** (the §5 schema entry): "`content` is the manifest **inline** — it is a small declarative entry table, so **no blob store is involved and no `ArtifactStore` method is added**" — and **`DATA-LAYER.md:369`** (§12.1's Port delta paragraph): "the manifest content travels **inline** in `conformance_manifest.content` (a small declarative table), so **no `ArtifactStore` involvement exists at all**."

Three places in the same delta say "inline, no ArtifactStore"; one place — §12.3, the section that actually describes how the manifest is registered and cited — still says "ArtifactStore blob keyed by that hash." This is not a stylistic inconsistency: it is a factual claim about a mechanism (does registering a manifest version require an `ArtifactStore.put_blob`-equivalent method that does not exist in the `ArtifactStore` Protocol at `DATA-LAYER.md:90-93`, or not?) stated two contradictory ways in one document. A developer implementing §12.3 as literally written builds exactly the missing-method gap round 1 flagged as blocking under Implementability — the fix that was supposed to remove it is undermined by the one paragraph that actually specifies the manifest's registration mechanism in most detail.

### 2. Design faithfulness

Placement, scheduling, and administrative-class treatment remain faithful (unchanged from round 1's finding, re-verified).

The §21.2 reconciliation added at `DATA-LAYER.md:395` is a good-faith, reasonably argued fix to round 1's finding, but its conclusion overstates what it shows. §21.2's audit rule (`ALGORITHM-v0.2-pathway-learner.md:672`) defines live-path-reachability as: "the mechanism **executes during the canonical protocol run**… under default configuration, evidenced by that run's truth records." DL's conditional-mechanism class substitutes **fire-test evidence** — synthetic-trigger `trace` rows emitted when `test_checker_fires_on_synthetic_violation`-style tests run, explicitly *not* part of the canonical run (`DATA-LAYER.md:396`: "Synthetic rows are `trace`-class… they move no posterior by construction, so fire-tests can run against a live system without touching evidence"). A synthetic fire-test is not "the mechanism executing during the canonical protocol run under default configuration" by §21.2's own words — it is a different, and weaker, evidentiary standard for exactly the mechanisms that (by DL's own admission) never fire in a canonical run. The fix is defensible as engineering (round 1 correctly noted a literal reading would make every conditional mechanism perpetually non-conformant), and §21.2 itself anticipates RAF-1b will have to operationalize reachability concretely ("until the RAF-1b checker exists, the interim procedure is…" — `ALGORITHM-v0.2-pathway-learner.md:672`). But the claim "**No §21 norm is added, weakened, or reinterpreted**" (`DATA-LAYER.md:395`) is not accurate as stated — it is a reinterpretation of §21.2(b)'s literal evidentiary standard for one mechanism class, argued but not conceded as such.

### 3. Red-team resistance

No RC-1..RC-8 mechanism is reintroduced or newly exposed. PR-8(iii)'s removal as a trace predicate correctly reduces scope rather than silently weakening anything — the actual claim/lease-liveness protection stays in `test_every_claim_has_ttl_or_probe` and §20.6's live probes, both untouched by this delta. The predicate-table honesty fixes (PR-5(i), PR-6(i), PR-9) reduce, not increase, the shipped-but-inert-detector risk (`STUDY-automaton-autonomy.md` A2) that round 1 flagged as the adjacent hazard of overclaiming `full` checkability — an implementer building against the honestly-scoped table can no longer stub a missing-evidence sub-clause to a default `True` believing it's specified as checkable. This is a genuine improvement over round 1's 68.

### 4. Implementability

The `Port delta: none` paragraph (`:369`) is a real improvement — `schemas.py` additions are now enumerated in prose (though still not as a field-by-field dataclass listing matching §6.1's/§6.2's convention) and the intent to remove the `ArtifactStore` dependency is stated. But because `:398` was not updated to match, the delta as a whole gives an implementer two contradictory build instructions for the same mechanism — this reopens round 1's blocking implementability finding (no `ArtifactStore` method exists for a generic content-hash-addressed blob store; `ArtifactStore` at `:90-93` exposes only `put_checkpoint`/`register`/`gc`) rather than closing it, for exactly the reader who reads §12.3 (where the manifest's actual registration is described) rather than §12.1's summary paragraph.

Unchanged from round 1, and not addressed by any of the six required changes: `cursor: {predicate_id → opaque_state}`'s per-predicate continuation-state shape is stated for only 2 of 9 properties (PR-4(ii) seq continuity, PR-5(iii) row monotonicity, per `:372`). The new schema-level redaction *rule* (`:146`) constrains what `cursor` may contain but does not specify what it *does* contain for the other seven predicates — a developer still has to invent PR-1's, PR-2's (n/a), PR-3's, PR-6's, PR-7's, PR-8's, and PR-9's incremental-state shapes from the prose describing their predicates.

### 5. Safety / integrity

Round 1's central Safety finding — redaction stated only for `violation_refs`, `cursor` unaddressed — is now closed with an actual mechanism: `DATA-LAYER.md:146`'s schema-level "Cursor redaction rule" (aggregate watermarks only; PR-1's cursor holds its scan high-water mark, never the held-out id set) plus `:368`'s extension of the guarantee to every field of both event kinds. This is exactly the "mechanism, not just the test" fix round 1 asked for, and it is now schema-enforced rather than test-only.

No gate, calibration layer, or verifier is weakened; the checker remains report-only (§12.4, re-verified). Residual, non-blocking: `test_report_redacted` (`:410`) names "report field" specifically; there is no equally explicit test asserting `conformance_manifest.content` carries no held-out-derived data, though the manifest's declarative shape (mechanism/§-anchor/expected-record-kinds/class/evidences) makes this a low-probability gap in practice, not a demonstrated one.

### 6. Efficiency / cost

Round 1's only gap — PR-1(ii)'s unstated complexity bound — is closed: `DATA-LAYER.md:370` states `O(records_in_scope × payload_size)`, one pass, hash-set membership, explicitly bounded by scope (the reason incremental scope exists). Correct and consistent with the document's own convention (§6.2's stated complexity bound, `:228`).

### 7. Completeness

Register scope note (`:406`) now mirrors §11.4's exactly, closing that round-1 gap. The `Port delta` paragraph closes the schema-enumeration gap in intent, though not consistently in text (see Correctness/Consistency). The per-predicate `cursor` shape gap (7 of 9 unspecified) remains, as does the manifest-field redaction test-coverage asymmetry noted under Safety.

### 8. Consistency

This is where round 2's one substantive new defect lives. `DATA-LAYER.md:398` ("the content itself is an ArtifactStore blob keyed by that hash") directly contradicts `DATA-LAYER.md:146` and `DATA-LAYER.md:369` (both: "inline… no ArtifactStore involvement"). This is precisely the class of defect the round-2 task's adversarial angle #4 asked to check for ("regression-check the revisions for internal contradictions") — found, and load-bearing (it bears on whether `Port delta: none` is actually true).

Round 1's preamble undercount (claiming one schema addition when the diff adds two) is correctly fixed at `:356` — re-verified, no residual issue.

The §21.2 reconciliation (see Design faithfulness) is a second, smaller consistency concern: it asserts consistency with §21.2's literal text more strongly than the text supports.

### 9. Calibration / honesty

The predicate-table calibration fixes are the strongest part of this round: PR-5(i), PR-6(i), PR-8(iii), and PR-9 are now downgraded by the identical, correctly-applied PR-3 pattern the round-1 review asked for, each verified against its cited ALGORITHM section rather than merely asserted. This is genuine, demonstrated improvement in the document's own founding discipline (`ALGORITHM-v0.2-pathway-learner.md:672`'s "a predicate's existence is not the property's truth" lesson, cited at `DATA-LAYER.md:377`).

Two overclaims survive, both smaller than round 1's but real: (a) the round's own change-list claim that "the ArtifactStore blob dependency is deleted entirely" is not true of the artifact as written (`:398`); (b) §12.3's "No §21 norm is added, weakened, or reinterpreted" (`:395`) understates the degree to which fire-test evidence is a substituted, not merely operationalized, standard for conditional mechanisms relative to §21.2(b)'s literal text.

## Strongest adversarial objection

**PR-5(i)'s `human_spotcheck` gap compounds with §10's retention horizon into a permanently unauditable hole on the one irreversible operation in the entire spec.** This goes beyond the Correctness/Calibration finding above (that the checkability downgrade is honestly stated) to a sharper point: `merge_to_base` — the Stage-2 base merge that §21.1's PR-5 (`ALGORITHM-v0.2-pathway-learner.md:663`) names as "the **sole declared irreversibility**" in the whole system — is gated in §9's own pseudocode (`ALGORITHM-v0.2-pathway-learner.md:253`) by `sustained_heldout(adapter) ∧ human_spotcheck(kept_set) ∧ no_cum_regression(MONITORED)`. RAF-1b's PR-5(i) can verify the first and third conjuncts from truth, but not `human_spotcheck` — and that conjunct is not merely hard to check *now*, it becomes **permanently unauditable** for any merge whose adapter checkpoint later passes §10's retention-horizon GC: at that point neither the pre-merge checkpoint (data) nor any spot-check record (which the schema never required to exist) survives to be checked, ever, by anything — the checker included, once built. So the one property this whole section names as protecting the system's single irreversible action has an unenforceable-by-trace conjunct sitting exactly on the boundary where irreversibility becomes absolute. A compromised or buggy §9 implementation that silently skips `human_spotcheck` before merging would show `conditional`/`not_trace_checkable` in every RAF-1b report — indistinguishable, from the report alone, from an honest deployment that simply never wired spot-check logging. This is not raised by recommending logging (`:385`'s "recommended, not mandated") — recommending logging for *future* merges does nothing for merges that already happened and whose evidence window has closed. No dimension finding above states this compounding argument; it is the section's highest-stakes residual gap.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(74, 82, 86) = 74
weighted_mean   = (74*2 + 78 + 82*2 + 64 + 86*2 + 88 + 72 + 58 + 70) / 11
                = (148 + 78 + 164 + 64 + 172 + 88 + 72 + 58 + 70) / 11
                = 914 / 11
                = 83.09
overall         = min(74, 83.09) = 74
```

**Overall confidence: 74 / 100**

## Verdict

**needs-revision**

Progress from round 1 (58 → 74) is real and substantial — the dominant round-1 defect (four predicates overclaiming `full` checkability) is genuinely fixed, and the cursor-redaction mechanism and complexity bound close two more required changes cleanly. What remains below 80 is one new, narrow, easily-fixable defect plus two smaller residuals:

1. **Fix the `DATA-LAYER.md:398` self-contradiction.** Either update it to state the manifest content is inline (matching `:146` and `:369`, and removing "ArtifactStore blob keyed by that hash" entirely), or — if an `ArtifactStore` blob really is intended for larger manifests in the future — reconcile all three locations and add the missing `ArtifactStore` method to the Port delta rather than claiming "Port delta: none."
2. **Soften or substantiate the §21.2 reconciliation claim** (`:395`). Either state plainly that the always-fires/conditional bifurcation is a **declared clarification** of §21.2(b)'s reachability definition for conditional mechanisms (parallel to §21's own "two declared conformance clarifications" framing, `ALGORITHM-v0.2-pathway-learner.md:651`), rather than asserting no reinterpretation occurred, or argue specifically why fire-test evidence satisfies §21.2(b)'s "executes during the canonical protocol run under default configuration" language as literally written.
3. Non-blocking, should accompany the next round: specify the per-predicate `cursor.opaque_state` shape for the remaining seven predicates (only 2 of 9 are stated); extend `test_report_redacted`'s stated scope (or add a twin test) to explicitly cover `conformance_manifest` fields, not only `conformance_report`; consider whether PR-5(i)'s `human_spotcheck` gap (see adversarial objection) warrants a stronger disclosure than "recommended, not mandated" given its interaction with §10's retention horizon — at minimum, name the compounding risk in the predicate table or §12.4's discipline section rather than leaving it implicit.
