# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–506), marked "added 2026-07-13, revised r3" |
| Proposed change | Round-3 rewrite of §17.6 addressing round-2's 2 blockers + 2 secondary findings: `τ_sm`/`w_prune` now claimed registered in §12; the reactivation fix reframed around an orthogonal `revalidation` field with a concurrently-launched shadow check and explicit "narrows, does not close" honesty language; `w_prune`'s prune criterion redefined from "selections" to JUDGE-logged "invocations"; `selfmod_rejected` flooding bounded by charging `b_sm` at submission |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Round-2 item resolution scorecard

| # | Round-2 item | Claimed status (caller) | Verified status | Evidence |
|---|---|---|---|---|
| 1 | `τ_sm`/`w_prune` registered in §12 | Addressed | **Genuinely resolved** | §12 line 286 now reads "…`w_promo` (Stage-2 rollback window), `τ_sm` (§17.6 DERIVE-dedup similarity bar), `w_prune` (§17.6 DERIVE orphan-prune window)" — both identifiers present, matching §17.6 line 505's claim. Grep-verified. |
| 2 | Reactivation claim made honest + mechanism tightened | Addressed | **Genuinely resolved, with a new implementability defect in the fix itself** | Line 504: orthogonal `revalidation ∈ {n/a, pending, passed, failed}`, concurrent shadow launch, explicit "narrows… does not close" (line 504). The honesty and sequencing objections from round 2 (C-2/Ca-2) are cleanly closed. **But** see C-1 below — `revalidation` is never added to the schema block it is described as belonging to. |
| 3 | `w_prune`'s "no selections" well-defined | Addressed | **Substantially resolved** | Reframed from "selection" to "zero logged invocations… logged to truth by the §6 orchestrator" (line 502) — sidesteps round 2's objection that discrete per-episode "selection" is undefined for coexisting scaffold components, since "invocation" doesn't require exclusivity. Residual: the logging mechanism itself is asserted, not tied to any previously-specified plug-point (see I-1 below). |
| 4 | `selfmod_rejected` flood bounded | Addressed | **Genuinely resolved** | Line 499: `b_sm` now explicitly charged "at submission, before admission checks" — closes round 2's ambiguity over whether rejected proposals are throttled at all; `test_rejected_proposals_consume_budget` (line 506) added. |

Additionally, two round-2 findings the caller did **not** claim were addressed remain open, unchanged:

- **Round-2 C-3/I-3/Co-2 (`source_ref` → gate-pass join path unspecified)** — line 503's text is verbatim-equivalent to round 2's; DATA-LAYER.md's `evals` schema (line 137: `id, ts, skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id`) still has no explicit gate-pass flag, and no join path is named. **Still open.**
- **Round-2 Cs-3 (DATA-LAYER.md schema delta never registered)** — grep of DATA-LAYER.md for `17.6`, `self_modify`, `scaffold`, `version_id`, `source_ref`, `gate_ref`, `revalidation` returns nothing. §18.1 (line 512) explicitly flags its own schema addition as "a DATA-LAYER schema delta"; §17.6 still does not, for either the `version` DAG or the new `revalidation` field. **Still open, and now compounded by finding C-1 below.**

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 68 | weak |
| 2 | Design faithfulness | 84 | pass |
| 3 | Red-team resistance (CRITICAL) | 72 | pass |
| 4 | Implementability | 66 | weak |
| 5 | Safety / integrity (CRITICAL) | 74 | pass |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 68 | weak |
| 8 | Consistency | 64 | weak |
| 9 | Calibration / honesty | 78 | pass |

## Findings by dimension

### 1. Correctness

**Score: 68 — weak**

**C-1. NEW: the `revalidation` field is asserted in prose as part of the `version` record but is absent from the section's own "concrete schema" block.** The formal schema definition (lines 484–497, the code block this section's title promises: "concrete schema & mutation operators") lists exactly ten fields: `version_id, component_id, parents[], operator, source_ref, snapshot, diff, gate_ref, status, created_ts` (lines 485–496). `revalidation` is not among them. Yet line 499 states as fact: "A separate orthogonal field `revalidation ∈ {n/a, pending, passed, failed}` tracks post-rollback re-validation (below) without overloading `status`" — grammatically and semantically presented as an actual field of the `version` row, immediately below the schema block that omits it. Line 504 then uses concrete field-values (`revalidation=pending`, `revalidation=failed`) as if the field is already part of the persisted record, and the test stub `test_reactivated_fallback_revalidated_concurrently` (line 506, "`revalidation=pending` tightens the monitor") depends on it existing. This is a directly grep-verifiable, non-interpretive inconsistency: the schema block and the prose describing the schema disagree about what fields the schema has. **This is the identical defect class flagged in round 1 (`CAPTURE`'s missing `source_ref`, since fixed by adding it to the schema block) and round 2 (`τ_sm`/`w_prune` claimed-but-absent from §12) — recurring for a third time, now inside the section's own code block rather than a cross-reference to another section.** See the adversarial pass.

**C-2. Round 2's C-1 (`τ_sm`/`w_prune` §12 registration) is cleanly fixed.** §12 line 286 now lists both parameters exactly as §17.6 line 505 claims. Verified by direct read, not inference.

**C-3. Round 2's C-2 (reactivation sequencing not delivering its own claim) is substantially resolved.** The mechanism no longer claims the reactivated component is simultaneously `live` and Stage-1 `shadow` under one status value — the concurrent "shadow run" (line 504) is explicitly a separate, ephemeral, scored-not-acted-on replica that "needs no status of its own," while the `version` row's `status` field stays honestly `live` throughout. This resolves the schema self-contradiction round 2 identified. The residual exposure (reactivated fallback serves traffic before its current fitness is reconfirmed) is now accurately described as "narrows… does not close" (line 504) rather than the round-2 overclaim "closes." This is a genuine correctness improvement — the claim now matches the mechanism.

**C-4. Unresolved, unchanged: `source_ref`'s admission check presumes a cross-table join not specified anywhere (line 489–490, 503).** Same finding as round 2's C-3 — DATA-LAYER.md's `evals` row (line 137) has no `gate_passed`/`committed` flag; whether `test_capture_requires_gated_success` (line 506) is assertable against the documented schema remains unclear. Text is unchanged from round 2 verbatim on this point.

**C-5. NEW, minor: the "tightened rollback threshold" (line 504) applied during `revalidation=pending` names no parameter and no quantification.** Compare `§19.3`'s per-knob clamps (`z ∈ [z_8, 2·z_8]`, etc.) or `§17.5`'s named `w_promo` — every other threshold-tightening mechanism in the document is either a named, bounded parameter or a stated formula. Here, "tightened" is an adjective with no operational definition, and no new parameter is added to line 505's list to carry it. A developer cannot implement `test_reactivated_fallback_revalidated_concurrently`'s "tightens the monitor" clause without inventing a number the spec doesn't supply.

**Summary:** 2 of round 2's correctness findings (C-1, C-2 in that report) are now genuinely fixed, and the fixes hold up under direct verification. But the very mechanism built to fix C-2 (the `revalidation` field) introduces a new defect of comparable severity (C-1 above), and one round-2 finding (source_ref join) is carried forward unaddressed. Net: modest improvement over round 2's 64, but still below the 70 floor.

---

### 2. Design faithfulness

**Score: 84 — pass**

**DF-1. `DERIVE`'s growth analogy (line 502) remains faithful** and is now backed by a genuinely operable inverse (`w_prune`'s invocation-count criterion), fully honoring P2's "every add has an inverse" (line 9) in a way that is actually measurable — an improvement over round 2's DF-2 concern (which flagged the inverse as specified-but-not-operable).

**DF-2. The `revalidation`-as-orthogonal-field design is the right architectural choice**, faithful to the document's general pattern of adding narrowly-scoped fields rather than overloading an existing enum (mirrors how §19 added distinct per-clause knobs rather than overloading a single `z`). The idea is sound; only its rendering into the schema block is incomplete (Correctness C-1).

**DF-3. Attribution to OpenSpace (line 481) is unchanged and remains accurate.** No overclaim of novelty.

**DF-4. Minor:** the reactivation mechanism (concurrent shadow-check + tightened monitor + escalation) is conceptually the code-axis analog of §7's RC-6 fix (discounted UCT + checkpoint invalidation) but §17.6 never draws that connection explicitly, missing an opportunity to show the pattern is a deliberate, precedented design choice rather than an ad hoc patch.

---

### 3. Red-team resistance

**Score: 72 — pass**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8 and the prior `S17-S18-selfmod-fleet-review*.md` / `S17-6-lineage-schema-review*.md` series.

**RT-1. Round 2's RT-2 (RC-4 unbounded `DERIVE` coexistence, measurability half) is now genuinely closed.** Reframing the prune trigger from "selection" to "invocation" (line 502) removes the definitional gap round 2 identified — a component that is always composed into every attempt is trivially never zero-invocation (correctly never pruned, since it's in active use), and a component that is never used is trivially zero-invocation (correctly pruned) — the criterion is now well-defined regardless of whether scaffold dispatch is discrete-per-episode or ensemble-composed.

**RT-2. Round 2's RT-3 (`selfmod_rejected` flood/DoS) is now genuinely closed.** Charging `b_sm` at submission (line 499) ties rejected-proposal volume to the same budget that bounds admitted candidates — an adversarial or buggy proposer cannot grow the event sink faster than a legitimate proposer could grow the version DAG. This removes the specific RC-2-adjacent gaming surface round 2 flagged.

**RT-3. Round 2's RT-6 (RC-6 stale-fallback, residual) remains open in the same narrowed form, now honestly labeled rather than overclaimed.** RC-6 (`ALGORITHM-v0.1-redteam.md` lines 59–61) is "non-stationarity invalidates the value tree, but re-anchor only refreshes competence." §17.6's reactivation still allows the fallback to serve live traffic for up to `w_promo` before `revalidation` clears, mitigated by a tightened monitor and a freeze-and-escalate path on double failure. This is a genuine, bounded improvement over "no re-validation at all" (round 1) — the score credits that — but it is not a closure, and the section says so itself (line 504).

**RT-4. NEW, RC-2-adjacent: the mechanism meant to narrow RT-3/RC-6 is not itself auditable as specified, because its state field doesn't exist in the schema (Correctness C-1).** RC-2's root pattern is a stated safety check with no enforcement/audit artifact behind it (the same pattern round 1 found for `CAPTURE`'s missing provenance field, and round 2 found for the false `τ_sm`/`w_prune` cross-reference). Here it recurs a third time: the claim "while `pending`, the monitor applies its tightened threshold" (line 504) and the escalation trigger "`revalidation=failed`… ⇒ freeze + escalate" cannot be replayed or audited from the `version` table as currently defined, because the field that would carry this state isn't declared. Narrower than a full reopening of RC-2 (the *design* is sound; only the schema rendering is incomplete), but it is the same species of gap RC-2 names.

**RT-5. Round 2's RT-4 (`CAPTURE` admission audit) and RT-5 (status-machine ambiguity) remain resolved, unchanged.**

**Summary:** two of round 2's three open red-team items (RT-2 measurability, RT-3 flood) are now solidly closed; the third (RT-6/RC-6) is unchanged in substance but no longer overclaimed; one new RC-2-adjacent gap (RT-4) is introduced by the round's own headline fix. Net improvement crosses into the "acceptable" band, but only marginally.

---

### 4. Implementability

**Score: 66 — weak**

**I-1. Round 2's I-4 (§12 registration) and the ambiguity half of I-5 (reactivation sequencing) are cleanly resolved** — §12 now carries both parameters (Correctness C-2), and line 504 states unambiguously that the shadow check runs concurrently with the (already-live) reactivated component, not before it.

**I-2. NEW: `revalidation` cannot be implemented from the schema as literally specified (Correctness C-1).** A developer building the `version` table from the code block at lines 484–497 will not create a `revalidation` column; they would have to notice, and correctly infer from prose elsewhere in the same bullet list, that a field the schema doesn't declare is nonetheless required. This is exactly the kind of guess the "concrete schema" was written to eliminate.

**I-3. NEW: the "tightened" rollback threshold (Correctness C-5) has no implementable definition.** No multiplier, no formula, no clamp — unlike every other threshold-adjustment mechanism in the document (§19.3's per-knob clamps, §17.3's `significant(Δ,SE)` itself).

**I-4. Substantially improved but not fully closed: the invocation-logging locus for `w_prune` (round 2's I-2) is now named as "the §6 orchestrator" (line 502) but the actual mechanism — how the orchestrator observes which SOLVE sub-component a live SOLVE process dispatched to, given SOLVE controls its own dispatch config — is not described anywhere in §17.1–§17.6.** This is a real improvement in specificity over round 2 (which had no locus at all) but the plug-point itself remains undefined, unlike the dedup check one clause earlier, which explicitly says the comparison "runs in the orchestrator's JUDGE-side admission path" (line 502) with no analogous statement for invocation logging.

**I-5. Unresolved, unchanged: `source_ref`'s join-path (round 2's I-3).**

**Summary:** genuine closure on two of four round-2 implementability gaps, partial progress on a third (I-4 above), and one round-2 gap carried forward unaddressed (I-5) — offset by two new gaps of comparable concreteness (I-2, I-3) introduced by this round's own fixes.

---

### 5. Safety / integrity

**Score: 74 — pass**

**S-1. No named gate, budget enforcer, or partition is weakened.** §17.1/§17.3/§17.5 text is unchanged (confirmed by direct read against the pre-r3 text); the `self_modify` budget enforcer remains JUDGE-owned (§17.1 line 455).

**S-2. Genuine safety improvement: the reactivation window is now monitored (tightened threshold) and equipped with an explicit escalation path** ("freeze + escalate to the §14 breaker/human," line 504) where round 1 had neither. This is a real, structural addition, not just better wording.

**S-3. The improvement in S-2 is undercut by two gaps that limit confidence it is *implemented as claimed*:** (a) the `revalidation` field the monitor/escalation logic depends on is not in the schema (Correctness C-1) — a safety-relevant control that cannot currently be audited from the persisted record; (b) the "tightened" threshold's magnitude is unspecified (Correctness C-5), so there is no way to verify the monitor is actually stricter by any bounded, checkable amount during the exposure window. Both are implementability/completeness gaps with direct safety consequence — a control that can't be audited or its strength verified is a weaker control in practice than the prose implies.

**S-4. `CAPTURE`'s admission property remains a real, checked control** (line 503, unchanged from round 2), modulo the still-open join-path ambiguity (C-4), which is a narrower implementability residual, not a weakening.

**S-5. The `selfmod_rejected` flood/DoS concern (round 2's S-4) is resolved** by the submission-time budget charge (line 499).

**Summary:** no structural gate is weakened, and the reactivation safety story is a genuine improvement in design intent — the score moves from round 2's 68 into the "acceptable" band — but it stops short of a stronger score because the specific mechanism that would let an auditor verify the improvement (the `revalidation` field, and a quantified tightening factor) is not actually present in the artifact as written.

---

### 6. Efficiency / cost

**Score: 76 — pass**

**E-1. Unchanged from round 2: `w_prune`'s eviction bound remains soft** — a component invoked even once per window persists indefinitely; no cap `M_max` on the live-component count is stated. Same residual as round 2's E-1, neither better nor worse.

**E-2. Unchanged from round 2: `selfmod_rejected` events remain an unbounded-with-time (though now rate-bounded) cold-path write sink**, with no stated retention/GC policy distinct from `scaffold_retention`'s blob-only scope. The rate is now bounded (RT-2 above), but total accumulated volume over the system's lifetime is still unaddressed — consistent with the document's general silence on `events`-table retention, not a new problem, but still unresolved.

**E-3. No hot-path change.** `self_modify` remains episodic (§17.2 line 460, unchanged); the new `revalidation`-tracking and concurrent shadow-run are cold/monitoring-path additions.

---

### 7. Completeness

**Score: 68 — weak**

**Co-1. NEW: `revalidation` missing from the formal schema block** (Correctness C-1) — the round's most consequential completeness gap, since it undermines the round's own flagship fix.

**Co-2. NEW: no quantification for the "tightened" rollback threshold during `revalidation=pending`** (Correctness C-5).

**Co-3. Resolved: round 2's Co-1 (selection/usage-tracking mechanism)** is substantially closed by the invocation reframing, modulo the residual instrumentation-locus gap (I-4 above).

**Co-4. Resolved: round 2's Co-4 (retention/GC policy or bounding justification for `selfmod_rejected`)** — now bounded via the submission-time budget charge, closing the unbounded-flood half even though the "how long do old rejected-rows live" half (E-2) is still open by the document's general silence on event retention, not a §17.6-specific gap.

**Co-5. Resolved: round 2's Co-5 (reactivation sequencing ambiguity)** — now explicit (concurrent, not gating).

**Co-6. Unresolved, unchanged: round 2's Co-2 (`source_ref` → gate-pass join path)** and **Co-7. Unresolved, unchanged: round 2's Cs-3 (DATA-LAYER.md schema delta never registered)** — now doubly relevant since the `revalidation` field also isn't registered as a schema delta anywhere.

**Co-8. Positive:** the test-stub list (line 506) is extended appropriately (`test_rejected_proposals_consume_budget`, `test_reactivated_fallback_revalidated_concurrently`) and each maps to a specific prose claim — good hygiene, undercut by the preconditions gaps above (a developer cannot fully implement `test_reactivated_fallback_revalidated_concurrently` without first inventing the `revalidation` column and the tightening factor the spec omits).

---

### 8. Consistency

**Score: 64 — weak**

**Cs-1. Resolved: round 2's Cs-1 (`τ_sm`/`w_prune` §12 mismatch) is cleanly fixed** — §12 line 286 and §17.6 line 505 now agree.

**Cs-2. NEW, and the single most concrete inconsistency in this revision: §17.6's own prose (line 499, 504) attributes a field, `revalidation`, to the `version` record that the section's own schema block (lines 484–497) does not declare.** This is not a cross-section inconsistency (like round 2's Cs-1) but an intra-section one — the same bullet list that opens with "Schema:" (line 483) and renders it as a code block goes on, two bullets later, to describe an additional field of that same record without amending the block. A reader following only the code block would build a `version` table that cannot support the reactivation mechanism the prose describes three paragraphs later.

**Cs-3. Unresolved, unchanged: round 2's Cs-3 (the `version` DAG and now also `selfmod_rejected`/`revalidation` are not registered as DATA-LAYER.md schema deltas)**, despite DATA-LAYER.md's "Record schemas" section (line 137) being the document's stated single point of truth and §18.1 (line 512) modeling the correct practice ("a DATA-LAYER schema delta") for a comparably-sized schema addition.

**Cs-4. `DERIVE`'s growth-analogy relabeling (line 502) remains consistent with §5.1 and P2**, carried forward from round 2's DF-1/Cs-2 resolution.

---

### 9. Calibration / honesty

**Score: 78 — pass**

**Ca-1. Major, genuine improvement: the reactivation overclaim from round 2 ("closes the stale-fallback gap") is now replaced with accurately-scoped language** — "this narrows RC-6's stale-fallback exposure to the concurrent-check window under a tightened monitor — it does not close it" (line 504), and further: "the residual is the price of never serving zero validated SOLVE." This is exactly the calibrated, non-overclaiming register the document practices at its best (e.g., §16 line 450, §17.3's own honest scoping of `CAPTURE`, line 503) and exactly what round 2's Ca-2 asked for.

**Ca-2. Resolved: round 2's Ca-3 (the false "registered in §12" claim) is now a true claim**, verified by direct read.

**Ca-3. Mild, new calibration gap: calling the monitor "tightened" (line 504) implies a quantified, verifiable strengthening of the safety property, but no quantification exists (Correctness C-5)** — a softer version of the same overclaim pattern round 2 flagged for "closes," now applied to a smaller, adjective-level claim rather than a headline one. Less severe than round 2's Ca-2/Ca-3 because it doesn't misstate what the mechanism *is* (concurrent monitoring is real), only how *strong* it is.

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (line 481)** — verified true.

**Summary:** this is the round's clearest dimension of genuine, verified improvement — the two most citable round-2 honesty defects are both closed, and closed correctly (not just reworded around the objection). The residual (Ca-3) is real but comparatively minor.

---

## Strongest adversarial objection

**Across all three rounds, this section has committed the identical class of defect — asserting that a schema, registration, or cross-reference exists when it does not — three times in a row, each time in the exact place the previous round's fix was supposed to land; the pattern, not any single instance of it, is the real finding.**

Round 1 found `CAPTURE`'s admission invariant ("no capturing lucky runs") had no field in the schema to anchor it — `source_ref` did not exist. Round 2's fix added `source_ref` and closed that instance, but in the same revision introduced a *new* instance of the identical defect shape: `τ_sm` and `w_prune` were asserted as "registered in §12" (line 505) when §12 (line 286, prior to this round) did not contain them. Round 3's fix closes *that* instance — §12 now genuinely lists both parameters — but in the same revision, fixing round 2's *other* flagship finding (the reactivation mechanism) introduces a third instance of the same defect shape: `revalidation` is described in prose (line 499, 504) as a field of the `version` record, used concretely in the mechanism's own escalation logic, and depended on by a named test stub (line 506) — yet it is absent from the section's own "concrete schema" code block (lines 484–497), the literal artifact the section's title promises to deliver.

Three rounds, three literally-distinct instances, one recurring root cause: when this section's authors fix a *substantive* problem (a missing provenance link, a false cross-reference, an under-specified reactivation), they reliably update the *narrative* claim (the prose that asserts the fix exists) without a corresponding pass to reconcile it against the section's own most load-bearing artifact — the schema block, or in round 2's case, §12's registry. This is not a coincidence of three independent slips; it is evidence of a process gap in how this section gets revised: prose-level fixes are not being checked against the concrete, checkable artifacts (schema fields, parameter registries) they reference, even though this section exists specifically to be the concrete artifact. A reviewer should weight this pattern, not just the current instance, when deciding whether "genuinely resolved, narrow residual" is the right frame for round 3's remaining gaps — the base rate established by rounds 1–3 suggests a fourth round is likely to repeat the shape somewhere else in the same bullet list unless the authoring process itself changes (e.g., a closing pass that diffs every new field/value mentioned in prose against the schema block before submission).

## Aggregate confidence

```
critical_floor  = min(Correctness=68, RedTeam=72, Safety=74) = 68
weighted_mean   = (68*2 + 84 + 72*2 + 66 + 74*2 + 76 + 68 + 64 + 78) / 11
                = (136 + 84 + 144 + 66 + 148 + 76 + 68 + 64 + 78) / 11
                = 864 / 11 = 78.5 → 79
overall         = min(68, 79) = 68
```

**Overall confidence: 68 / 100**

## Verdict

**needs-revision**

Genuine, verified progress: all 4 items the caller flagged as addressed (τ_sm/w_prune §12 registration, the reactivation honesty + sequencing fix, w_prune's invocation-based prune criterion, and the selfmod_rejected flood bound) are confirmed genuinely resolved on direct inspection — this is a real improvement over round 2, most visibly in Calibration/honesty (62→78) and Red-team resistance (66→72). But the score does not clear 80 and the critical floor (68) sits just under 70, because:

1. **Add `revalidation` to the formal `version` schema block** (lines 484–497), not just to the surrounding prose — the field is used concretely (`revalidation=pending`, `revalidation=failed`) and depended on by `test_reactivated_fallback_revalidated_concurrently` (line 506), but does not exist in the section's own "concrete schema." (Correctness C-1, Consistency Cs-2, Implementability I-2, Completeness Co-1, Red-team RT-4)
2. **Quantify the "tightened" rollback threshold applied during `revalidation=pending`** — name a parameter (with a default and a bound, in the style of §17.5/§19.3) or a formula relating it to the existing `significant(Δ,SE)` test, and register it alongside `τ_sm`/`w_prune` in §12. (Correctness C-5, Implementability I-3, Completeness Co-2, Calibration Ca-3)
3. **Specify the `source_ref` → gate-pass join path** (which table/field determines "this episode's outcome passed `commit_gate`") — carried forward unresolved from round 2. (Correctness C-4, Implementability I-5, Completeness Co-6)
4. **Register the `version` DAG, `selfmod_rejected`, and `revalidation` as an explicit DATA-LAYER.md schema delta**, per the precedent §18.1 (line 512) sets for its own `agent_id` key — carried forward unresolved from round 2, now covering one more undeclared field. (Consistency Cs-3, Completeness Co-7)
5. **Name the plug-point by which the §6 orchestrator observes per-component SOLVE invocation** (line 502's "every invocation is logged to truth"), analogous to how the same bullet already names the dedup-check's enforcement locus one clause earlier. (Implementability I-4)

If a round 4 is commissioned, the authors should additionally run a closing pass that diffs every field/value introduced in this section's prose against its own schema block and against §12 — the adversarial pass above documents that this specific category of self-referential omission has now recurred in all three rounds.
