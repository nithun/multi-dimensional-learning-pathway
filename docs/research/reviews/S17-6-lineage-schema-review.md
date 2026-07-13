# 360 Review: S17-6-lineage-schema — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` — §17.6 only, "The scaffold-version log — concrete schema & mutation operators" (lines 479–501), reviewed for consistency with the gate-approved §17.1–§17.5 |
| Proposed change | Concretize §17.2's abstract "immutable append-only scaffold-version log" into a version-DAG schema (`version_id, component_id, parents[], operator, snapshot, diff, gate_ref, status, created_ts`) and name three `self_modify` operator sub-types — `FIX` / `DERIVE` / `CAPTURE` — each behind §17.3, plus a permanent-rows/prunable-blobs retention split |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` as of last update 2026-07-03. Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 58 | weak |
| 2 | Design faithfulness | 68 | weak |
| 3 | Red-team resistance (CRITICAL) | 62 | weak |
| 4 | Implementability | 62 | weak |
| 5 | Safety / integrity (CRITICAL) | 66 | weak |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 58 | weak |
| 8 | Consistency | 65 | weak |
| 9 | Calibration / honesty | 65 | weak |

## Findings by dimension

### 1. Correctness

**Score: 58 — weak**

**C-1. `CAPTURE`'s stated admission condition cannot be checked from the schema it defines (line 488, line 498).** Line 488 fixes `CAPTURE`'s `parents[]` at `0` ("0 parents, new `component_id`"). Line 498 then requires `CAPTURE` be "admissible **only** from episodes whose outcome passed the §8 gate." But the schema (lines 484–494) has no field that records *which* episode/lineage-row justified the capture — `parents[]` is forced empty, `gate_ref` (line 491) is documented as "the §17.3 Stage-1/Stage-2 eval artifacts" (i.e., the artifacts from evaluating *this* candidate, not a pointer back to the antecedent episode that supposedly authorized minting it). So the one invariant §17.6 states as the safety condition for `CAPTURE` ("no capturing lucky runs into the scaffold") has no place to live in the persisted record. This is not a nice-to-have — the accompanying test stub `test_capture_requires_gated_success` (line 500) is unimplementable as specified: there is nothing in a `version` row to assert against. A `source_episode_ref` / `source_lineage_ref` field (pointing into the TruthStore `lineage`/`evals` tables, DATA-LAYER.md line 135) is missing from the schema.

**C-2. `diff (unified, vs parents[0])` is undefined for `CAPTURE` (line 490 vs. line 498).** `CAPTURE` has 0 parents by definition, so `parents[0]` does not exist; the schema's single `diff` field (documented uniformly, not conditioned on `operator`) has no defined semantics for this operator. Minor on its own, but it compounds with C-1: `CAPTURE` rows are under-specified on two of the schema's non-optional-looking fields.

**C-3. `DERIVE` is mislabeled as "the scaffold analog of §5.1 merge" (line 497), but its primary operation is the opposite of merge.** §5.1's `maybe_merge()` (line 131) *reduces* duplicate structures — "union evidence of duplicate skills (inverse of split)" — it is explicitly one of P2's *inverses*. `DERIVE` as specified (line 497) *adds* a new `component_id` while "parents stay live (coexistence)" — that is structurally §5.1's `new_skill` growth step (lines 124–129), not `maybe_merge`. Only the dedup-rejection half-sentence in the same bullet ("a candidate near-identical to a live component … is rejected pre-gate") is actually merge-like (hysteresis against duplicates). Calling the whole operator a "merge analog" overstates the parallel and could mislead an implementer into modeling `DERIVE` as evidence-reducing when it is evidence/component-increasing.

**C-4. The `status ∈ {candidate, shadow, live, retired}` state machine has an unresolved timing/coverage gap (line 483, line 492).** Line 483 says entries are appended "when a candidate is admitted to Stage 1." §17.3 (line 464) defines Stage 1 as running the candidate "in shadow" immediately. If the row is only created at that moment, it is unclear when — or whether — `status=candidate` is ever actually observed (as opposed to the row being born directly at `shadow`). Neither §17.3 nor §17.6 states the transition table. See Completeness (Co-3) and the adversarial pass for the compounding gap.

**Summary:** no arithmetic/formula errors (§17.6 introduces no new formulas), but the schema's self-referential invariants (C-1, C-4) and one mislabeled analogy (C-3) are concrete, citable correctness defects in what the section asserts about its own artifacts.

---

### 2. Design faithfulness

**Score: 68 — weak**

**DF-1. Correct positive: reuses the established store split and idempotency pattern.** "Rows in TruthStore lineage, blobs in ArtifactStore" (line 483) is exactly §10's cold-store split (line 264–266) and DATA-LAYER.md's `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` (DATA-LAYER.md line 135). `version_id = content-hash of the SOLVE-component snapshot` (line 485) correctly reuses the content-hash-identity pattern DATA-LAYER.md §6.1 just established for evidence idempotency (DATA-LAYER.md line 158). Good, faithful reuse rather than a bespoke new mechanism.

**DF-2. Tension with P2, the document's own second organizing principle (line 9): "Every `add` has an inverse."** `FIX` supplies an inverse (parent retired on promotion, line 496). `DERIVE`'s dedup rejection supplies a *partial* inverse (no duplicate accumulation), but `DERIVE`'s primary effect — a new coexisting component that never merges or prunes — has no analog to §5.1's `g.prune_orphans()` (line 132, "retire live skills with no progress after a budget"). Nothing in §17.6 gives scaffold `DERIVE` components an eventual orphan-prune path. This is a faithfulness gap against the section's own two-principle framing, not just a style nit (elaborated under Red-team, RT-2).

**DF-3. Consistent framing of the borrow vs. the original contribution.** Line 481's "the schema pattern is validated in the wild … the gating statistics remain ours" is an honest, correctly-scoped attribution to `STUDY-raganything-agentscope-openspace.md` §3 (OpenSpace's `FIX/DERIVED/CAPTURED` + lineage DAG, confirmed in that study at lines 56–57). No overclaim of novelty for the schema shape itself.

---

### 3. Red-team resistance

**Score: 62 — weak**

Evidence sourced from `ALGORITHM-v0.1-redteam.md` RC-1 through RC-8, and from the round-1 finding in `S17-S18-selfmod-fleet-review.md` (the `provision_suite` item-generation data-poisoning hole).

**RT-1. The specific round-1 hole (unprotected item-generation write-path) is not reopened here.** §17.6's write-path claim — "entries are appended by the §6 orchestrator … never by SOLVE code" (line 483) — concerns the version log, not `provision_suite`/held-out item generation (which round-1 flagged and rounds 2–3 closed via the §17.1 static-analysis + capability-isolation wall, confirmed still in force at §17.1 line 455–457, unmodified by §17.6). The *append operation itself* is correctly JUDGE-side. This specific concern (task item (a)) is adequately closed for the literal write path.

**RT-2. RC-4 (add-only ratchet) partially reopens at the scaffold layer.** `DERIVE`'s "parents stay live (coexistence)" (line 497) with no stated prune/GC path for scaffold components mirrors exactly the failure pattern RC-4 named for the memory axis before §5.1's fix ("orphan skills from growth×novelty are never pruned," redteam line 52). §5.1 closed this with `g.prune_orphans()`; §17.6 gives `DERIVE` no equivalent. Left as specified, an agent (or fleet, §18) running `self_modify` over a long horizon can accumulate an unbounded number of live-but-unused `DERIVE`d scaffold components — the RC-4 pattern, transplanted to code.

**RT-3. RC-2-adjacent: `CAPTURE`'s unauditable admission criterion (C-1) is a residual gaming surface.** RC-2's root pattern is "the system optimizes its own scoreboard" via a criterion that looks like a check but isn't actually verifiable. §17.6 states `CAPTURE` requires a gated-success episode as its "no capturing lucky runs" defense, but supplies no schema field linking the captured version to that episode (C-1). Whether the orchestrator enforces this at admission time and simply doesn't record the linkage, or doesn't enforce it at all, is unresolved — the invariant as written can't be replayed/audited after the fact, which is the same "unverifiable check" shape RC-2's `reliability(v)` circularity had before §4.3 fixed it with an audit-anchored definition. This is narrower than round-1's hole (it doesn't touch held-out items or the verifier itself) but is the same *species* of gap: a stated safety rule with no enforcement artifact behind it.

**RT-4. Task item (c) — `DERIVE`'s pre-gate dedup rejection is a new, unaudited rejection path.** The dedup check (line 497: "content-hash match, or similarity ≥ the §5.1 `τ_merge` analog … rejected pre-gate") happens *before* Stage 1, so a rejected candidate produces no `version` row (rows are created "when a candidate is admitted to Stage 1," line 483) and no `gate_ref`. Unlike §5.1's `τ_new`/`τ_merge` precedent (an accepted existing pattern for a non-competence admission decision), §17.6 doesn't say **who computes and enforces** the similarity check. If this comparison is not explicitly located in JUDGE (the orchestrator/admission path), a sufficiently capable `self_modify` proposer could in principle influence its own dedup self-assessment; the section doesn't foreclose that reading. It also creates a silent-rejection path with zero audit trail, in tension with the section's own claim two bullets later that "the audit trail never thins" (line 499) — that claim is true only for candidates that ever reach a `version` row, which pre-gate-rejected `DERIVE`s never do.

**RT-5. Task item (e) — status-machine ambiguity is itself a residual attack surface.** If "failed Stage-1 trial" and "currently in Stage-1 shadow trial" are not distinguishably represented (see C-4), an operator inspecting the log cannot reliably tell an abandoned/failed scaffold candidate from an active one — a monitoring/observability gap that weakens the human-spot-check and audit disciplines the rest of §17 relies on.

**Summary:** the round-1 hole this review was specifically asked to check for (a) is closed. Two new, narrower residuals are opened: an unbounded-DERIVE-coexistence RC-4 echo (RT-2) and an unauditable CAPTURE admission criterion (RT-3), plus an unspecified enforcement locus for the new DERIVE-dedup rejection path (RT-4).

---

### 4. Implementability

**Score: 62 — weak**

**I-1. No enforcement locus named for the `DERIVE` dedup check (line 497).** A developer cannot tell whether this comparison must run in the orchestrator/JUDGE path (as it must, to be trustworthy — see RT-4) or could be computed by SOLVE-side proposal code. This needs an explicit statement, analogous to how §17.1 (line 457) explicitly places the wall check "before any `self_modify` candidate is admitted."

**I-2. No schema field for `CAPTURE`'s justifying episode (C-1).** `test_capture_requires_gated_success` (line 500) cannot be implemented without one; a developer would have to invent a field the spec doesn't name (risk: two different implementations invent two different, incompatible fields).

**I-3. No status-transition table (C-4).** A developer implementing the version-DAG store needs an explicit state diagram: what triggers `candidate→shadow`, `shadow→live`, `live→retired`, and — critically — what status (if any) a version gets when Stage 1 simply fails to clear the bar (neither promoted nor rolled back from `live`, since it was never `live`).

**I-4. `diff` semantics unspecified for `CAPTURE` (C-2).** Is it null, empty, or diffed against some synthetic empty parent? Left to implementer judgment.

**I-5. Reasonable positives:** the schema fields themselves (`version_id`, `component_id`, `snapshot`, `gate_ref`, `created_ts`) are concrete and directly map to existing store primitives (DATA-LAYER.md `ArtifactStore`/`TruthStore` ports); `FIX`'s "1 parent, same `component_id`; parent retired on promotion" is fully actionable as stated; the six new test stubs (line 500) are well-named even where (I-2, I-3) their preconditions are incomplete.

---

### 5. Safety / integrity

**Score: 66 — weak**

**S-1. Task item (a), resolved: the append write-path is airtight for the literal act of writing.** "Never by SOLVE code" (line 483) is a true, checkable claim about *who calls the append*; it does not reopen the round-1 `provision_suite` hole (that surface is unchanged and still inside §17.1's JUDGE list, line 455).

**S-2. `CAPTURE`'s stated safety property ("no capturing lucky runs into the scaffold," line 498) is asserted, not enforced by anything visible in the artifact.** This repeats the shape of the round-1 finding this review was asked to watch for, at smaller scope: a safety-relevant admission rule with no enforcement artifact in the schema (C-1/RT-3). Until a `source_episode_ref` (or equivalent) exists and is checked at admission, this is a policy statement, not a structural guarantee — the same distinction the round-1 review drew between "impossible by construction" and "impossible if the boundary is correctly implemented."

**S-3. Permanent lineage rows are a safety *positive*, not a conflict (task item d).** "Lineage rows are permanent … `scaffold_retention` bounds pruning of blobs only" (line 499) is consistent with — not in tension with — §10's existing split (line 266: checkpoints/tree get retention/GC; DATA-LAYER.md's TruthStore is "canonical and append-only," §6 line 146). No privacy constraint exists elsewhere in the reviewed docs that this could conflict with (§17 concerns agent SOLVE code, not human-learner PII, which is scoped separately under `HUMAN-LEARNING-VERIFIER.md`). This strengthens auditability, which is the right direction for a self-modifying-code axis. No safety weakening found here.

**S-4. Rollback-as-reactivation (line 499) is a clean, sound realization of §17.3's "retained frozen fallback," with one unaddressed non-stationarity risk** — elaborated in the adversarial pass below, since it is not covered by any of the other eight dimensions.

**Summary:** no gate, budget, or partition is weakened by §17.6 (§17.1/§17.3/§17.5 text is verified unchanged). The score sits below 70 because of S-2 — a stated safety invariant (`CAPTURE`'s gated-success requirement) that the schema, as written, cannot verify or audit after the fact.

---

### 6. Efficiency / cost

**Score: 78 — pass**

**E-1. No hot-path addition.** `self_modify` remains an episodic outer-§6 action (confirmed unchanged, §17.2 line 460); version-log appends are cold-path writes to TruthStore/ArtifactStore, matching §10's cold-store cadence.

**E-2. `DERIVE`'s dedup similarity check has an implicit, unbounded cost that compounds with RT-2.** Comparing a new candidate against "a live component" (line 497, singular in the text but presumably meaning the relevant set of live components) is not bounded in the spec. If `DERIVE` accumulates coexisting components without pruning (RT-2), the per-candidate dedup-check cost grows with the unpruned live-component count over the life of the system. Not hot-path, but unbounded-with-time is still worth a parameter/complexity note (e.g., a bound `M_max` on live scaffold components, or restricting the comparison to a nearest-neighbor index as VectorStore already provides).

**E-3. Content-hash computation and immutable-blob storage are standard-cost, well-understood operations** — no concern.

---

### 7. Completeness

**Score: 58 — weak**

**Co-1. Missing: CAPTURE provenance field** (C-1) — the most consequential gap; blocks the stated test stub.
**Co-2. Missing: `diff` semantics for `CAPTURE`** (C-2).
**Co-3. Missing: explicit status-transition table** for `{candidate, shadow, live, retired}` (C-4) — including what status (if any) a Stage-1-rejected candidate receives.
**Co-4. Missing: enforcement locus for the `DERIVE` dedup check** (I-1).
**Co-5. Missing: an orphan-prune/GC path for `DERIVE`-created scaffold components** (RT-2/DF-2) — the section supplies inverses for `FIX` (retire-on-promote) but not for `DERIVE`'s primary coexistence-growth effect.
**Co-6. Missing: any record of pre-gate-rejected `DERIVE` attempts** (RT-4) — even a lightweight `events` entry (§10's general event log, distinct from the `version` DAG) would close this; the section is silent on whether one exists.
**Co-7. Positive:** the six test stubs (line 500) are a reasonable extension of §17.5's existing stub list and correctly named for what they intend to check, even where their preconditions are incomplete (Co-1/Co-3 above).

---

### 8. Consistency

**Score: 65 — weak**

**Cs-1. Consistent:** store split (TruthStore rows / ArtifactStore blobs) matches §10 and DATA-LAYER.md exactly (DF-1); "no change to §17.1/§17.3/§17.5" is verified true by direct comparison of those sections' text against the pre-2026-07-13 approved version.
**Cs-2. Inconsistent:** `DERIVE` labeled "the scaffold analog of §5.1 merge" (line 497) when its primary semantics is §5.1's growth/`new_skill` step, not `maybe_merge` (C-3) — a terminology clash with an already-approved, precisely-defined section.
**Cs-3. In tension with P2** (line 9, "Every `add` has an inverse") — `DERIVE`'s missing prune path (DF-2/Co-5) is a partial exception to a principle the document itself calls out as one of only two organizing principles for the entire spec.
**Cs-4. Internally inconsistent claim:** "lineage rows are permanent (the audit trail never thins)" (line 499) is true only for candidates that reach a `version` row; pre-gate-rejected `DERIVE`s (Co-6) fall outside that guarantee, and the section does not flag the exception.

---

### 9. Calibration / honesty

**Score: 65 — weak**

**Ca-1. Honest, correctly-scoped attribution** of the schema pattern to OpenSpace with an explicit disclaimer that "the gating statistics remain ours" (line 481) — appropriately modest, and consistent with the discipline the prior round-3 review praised (no repeat of the earlier "impossible by construction" overclaim pattern from `S17-S18-selfmod-fleet-review.md` Ca-1).
**Ca-2. Overclaim: `CAPTURE`'s "no capturing lucky runs into the scaffold" (line 498)** is stated as an achieved property. As specified (no provenance field, C-1), it is at best an *intended* property that the orchestrator may or may not actually enforce and cannot currently audit. The honest phrasing would be "intended to admit only from gated episodes — enforcement mechanism and provenance record TBD."
**Ca-3. Mild overclaim:** calling `DERIVE` a "merge analog" (C-3) implies a stronger structural parallel to an already-vetted, evidence-reducing mechanism than the operator, as specified, actually has.
**Ca-4. Accurate:** "no change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (line 481) — verified true by direct text comparison; no drift-by-stealth found.

---

## Strongest adversarial objection

**Reactivation-as-rollback assumes the frozen fallback is still valid the moment it is needed, but §17.6 never requires re-validating a reactivated component against the *current* held-out distribution before it goes live again — this is RC-6's stale-value-tree failure mode, transplanted to code.**

§17.6 (line 499) specifies rollback as a pure status flip: "parent `retired→live`, promoted candidate `live→retired`," made safe by byte-exact snapshot immutability. That guarantees the *bytes* reactivated are identical to what once passed Stage 1/Stage 2 — but it says nothing about whether the *conditions* under which they passed are still the conditions the agent now operates under. RC-6 (`ALGORITHM-v0.1-redteam.md` lines 59–61) found exactly this failure for the MCTS value tree: "after a weight move the policy changes but the tree's Q is frozen at the old policy's performance" — and v0.2's fix (§7, lines 213–214) was to *discount/invalidate*, not just keep, old state on a checkpoint change. §17.6's rollback has no analogous invalidation step: a scaffold component that was frozen as "last-good" at time T, then superseded by one or more later `FIX`/`DERIVE` promotions, may sit `retired` for an arbitrary duration while the competence posteriors, held-out item distribution (rotating sample, §4.1 line 81), and skill graph all continue to evolve. When it is reactivated at time T+Δ, §17.3's Stage-2 rollback trigger (`significant(Δ,SE)` over `w_promo`, confirmed sound by `S17-S18-selfmod-fleet-review-r3.md` C-R3-1) only tells you the *replacing* candidate regressed — it says nothing about whether the *thing being reactivated* is still fit for current conditions. Neither §17.3 nor §17.6 mandates even a cheap Stage-1-style shadow re-check of the reactivated component against current held-out data before it resumes live traffic. In a long-running self-modification axis (M3, potentially fleet-scale per §18), this gap could let an agent oscillate back into a scaffold state that was correct once but is now stale relative to a drifted skill graph or competence distribution — precisely the class of harm the rest of the spec goes to unusual lengths to prevent (§7's discounted UCT, §14's calibration, §19's self-calibrating gate). This objection is not raised in any of the nine dimensions above and is not addressed by the approved §17.1–§17.5 text either — §17.6 was the opportunity to close it (since it is the section that defines what "reactivation" concretely means) and does not.

## Aggregate confidence

```
critical_floor  = min(Correctness=58, RedTeam=62, Safety=66) = 58
weighted_mean   = (58*2 + 68 + 62*2 + 62 + 66*2 + 78 + 58 + 65 + 65) / 11
                = (116 + 68 + 124 + 62 + 132 + 78 + 58 + 65 + 65) / 11
                = 768 / 11 = 69.8 → 70
overall         = min(58, 70) = 58
```

**Overall confidence: 58 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to lift all three CRITICAL dimensions above 70):

1. **Add a `CAPTURE` provenance field** (e.g., `source_episode_ref` / `source_lineage_ref` pointing into TruthStore's `lineage`/`evals` records) so the stated invariant "admissible only from episodes whose outcome passed the §8 gate" is actually checkable, and so `test_capture_requires_gated_success` (line 500) has something to assert against. (C-1, S-2, RT-3, Co-1)
2. **Name the enforcement locus for `DERIVE`'s pre-gate dedup check** — state explicitly that the similarity/content-hash comparison against live components runs in the orchestrator/JUDGE admission path, not in SOLVE-proposed code, mirroring how §17.1 (line 457) explicitly places the wall check "before any `self_modify` candidate is admitted." (I-1, RT-4, Co-4)
3. **Specify a status-transition table** for `{candidate, shadow, live, retired}`, including what status a Stage-1-rejected candidate receives, and reconcile it with "entries are appended … when admitted to Stage 1" (line 483) so it is clear whether `candidate` is ever actually a persisted state. (C-4, I-3, Co-3)
4. **Give `DERIVE` a pruning/orphan-retirement path** (the scaffold analog of `g.prune_orphans()`, §5.1 line 132) so unbounded coexisting-but-unused derived components don't reopen RC-4 at the scaffold layer, and either relabel `DERIVE` as the analog of §5.1's growth step (with only its dedup half as the merge-like inverse) or add the missing inverse to justify the "merge analog" framing. (C-3, DF-2, RT-2, Co-5, Cs-2, Cs-3, Ca-3)
5. **Record pre-gate-rejected `DERIVE` attempts somewhere** (even a lightweight `events` row distinct from the `version` DAG), or explicitly state they are intentionally not logged and reconcile that with the "audit trail never thins" claim (line 499). (RT-4, Co-6, Cs-4)
6. **Require a re-validation step before a reactivated (rolled-back) component resumes live traffic** — at minimum a bounded Stage-1-style shadow check against current held-out data — to close the RC-6-adjacent stale-fallback gap raised in the adversarial pass.
7. **Define `diff` semantics for `CAPTURE`** (0 parents ⇒ no `parents[0]` to diff against). (C-2, I-4, Co-2)
8. **Soften the `CAPTURE` safety claim** ("no capturing lucky runs into the scaffold," line 498) to reflect that it is enforced only once item 1 above exists — an intended property, not yet a verifiable one. (Ca-2)
