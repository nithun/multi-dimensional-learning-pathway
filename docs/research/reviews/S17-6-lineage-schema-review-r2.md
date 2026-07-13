# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–506), marked "added 2026-07-13, revised r2" |
| Proposed change | Round-2 rewrite of §17.6 addressing all 8 round-1 blockers: `CAPTURE.source_ref` provenance field; JUDGE-side `DERIVE` dedup enforcement; a total `{candidate,shadow,live,retired}` status machine; `DERIVE` reframed as the §5.1 growth analog with a `w_prune` orphan-retirement inverse; `selfmod_rejected` TruthStore events for pre-gate rejections; a bounded post-rollback shadow re-validation; defined `CAPTURE` diff semantics; and a softened, checked-admission framing of `CAPTURE`'s safety claim |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Round-1 blocker resolution scorecard

| # | Round-1 blocker | Status | Evidence |
|---|---|---|---|
| 1 | `CAPTURE` provenance field | **Resolved** | `source_ref` REQUIRED field, line 489–490; admission check line 503 |
| 2 | `DERIVE` dedup enforcement locus | **Resolved** | "runs in the orchestrator's JUDGE-side admission path" line 502 |
| 3 | Status-transition table | **Resolved** | Total status machine, line 498–499 |
| 4 | `DERIVE` orphan-prune inverse | **Resolved, with a new measurability gap** | `w_prune` bullet, line 502; see C-5/Co-1 below |
| 5 | Record pre-gate-rejected attempts | **Resolved, with a new flood/GC gap** | `selfmod_rejected` events, line 483, 499; see RT-3/E-1 below |
| 6 | Reactivation re-validation | **Partially resolved — sequencing gap remains** | Line 504; see the adversarial pass |
| 7 | `CAPTURE` diff semantics | **Resolved** | Line 492–493 |
| 8 | Soften `CAPTURE` safety claim | **Resolved** | Line 503, "checked admission property" framing |

Six of eight round-1 blockers are cleanly closed. Two (#4, #6) are genuinely improved but leave a narrower residual, and the revision introduces two **new** defects not present in round 1: a false internal cross-reference (§12 registration, see C-1 below) and an unaddressed `selfmod_rejected` flood/retention gap (see RT-3/E-1).

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 64 | weak |
| 2 | Design faithfulness | 82 | pass |
| 3 | Red-team resistance (CRITICAL) | 66 | weak |
| 4 | Implementability | 68 | weak |
| 5 | Safety / integrity (CRITICAL) | 68 | weak |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 66 | weak |
| 8 | Consistency | 60 | weak |
| 9 | Calibration / honesty | 62 | weak |

## Findings by dimension

### 1. Correctness

**Score: 64 — weak**

**C-1. NEW, verified false claim: §17.6 asserts `τ_sm`/`w_prune` are "registered in §12," but they are not there.** Line 505: "**New parameters (extends §17.5):** `τ_sm` (DERIVE dedup similarity bar) · `w_prune` (DERIVE orphan-prune window) — registered in §12 alongside §17.5's." §12's actual "Added-section parameters" paragraph (line 286) reads: "§17 `b_sm` (`self_modify` budget), `sandbox_cost_cap`, `scaffold_retention`, `w_promo` (Stage-2 rollback window) · §18 …" — `τ_sm` and `w_prune` are absent. A repo-wide grep confirms these two identifiers occur **only** at line 502 and line 505 of the whole document; nowhere in §12. This is not an interpretation question — it is a directly falsifiable claim about the document's own state, and it is false as of this revision. (Compare: §17.5, the section §17.6 explicitly extends, made the *same* kind of claim for `b_sm`/`sandbox_cost_cap`/`scaffold_retention`/`w_promo` at line 475, and that one *is* borne out at line 286 — so the convention is real and §17.6 breaks it for its own two new parameters.)

**C-2. The reactivation fix does not, as literally sequenced, deliver the property it claims to deliver.** Line 504: "Rollback stays **instant**… — but a reactivated component then **must pass** a bounded Stage-1-style shadow check against *current* held-out within `w_promo`… (closes the stale-fallback gap…)." The status machine (line 495, 498–499) has exactly one `status` field with four mutually exclusive values; "rollback stays instant" is realized as an immediate status flip "parent `retired→live`" (line 504) — i.e., the reactivated component is placed into the traffic-serving `live` state *before* the "Stage-1-style shadow check" (which, per §17.3 line 464, means "scored, not acted on") begins or completes. A component cannot simultaneously be `status=live` (acted on) and in genuine Stage-1 `shadow` (not acted on) under this schema. So the mechanism as specified does not *prevent* a window in which an unrevalidated-against-current-conditions component serves live traffic — it only *bounds* that window's length (`w_promo`) and adds a detection-and-escalate path if the check subsequently fails. Calling this "closes the stale-fallback gap" (line 504) overstates what the sequencing, as written, actually achieves. See the adversarial pass for the full argument.

**C-3. Minor: the `source_ref` admission check presumes a cross-table join that isn't specified.** Line 489–490, 503: `source_ref` points at "the TruthStore eval/lineage ids of the §8-gated episode(s)," and admission "verifies… every referenced episode's outcome passed the §8 gate." DATA-LAYER.md's `evals` schema (`id, ts, skill, difficulty, split, n_pass, n_total, verifier, item_ids, checkpoint_id`, DATA-LAYER.md:135) has no `gate_passed`/`committed` field — whether an eval's outcome actually cleared `commit_gate` (§8, lines 222–227) is a fact that lives with the commit decision, not the eval row itself. §17.6 doesn't say which table (or join) the admission check reads to determine gate-pass status, so `test_capture_requires_gated_success` (line 506) is directionally well-specified but not fully assertable against the schema as currently documented.

**Summary:** Four of the four round-1 correctness defects (C-1..C-4 in the round-1 report) are cleanly fixed. But this revision introduces one outright false cross-reference (C-1 above) and the flagship reactivation fix (item 6 from round 1, the one this round was specifically commissioned to re-verify) does not fully deliver on its own stated claim (C-2). That is enough to keep this dimension below the 70 floor.

---

### 2. Design faithfulness

**Score: 82 — pass**

**DF-1. `DERIVE` is now correctly and faithfully mapped to §5.1 growth, resolving round-1's C-3/Cs-2/Ca-3.** Line 502: "`DERIVE` is the scaffold analog of §5.1 **growth**, and it carries growth's full add-with-inverse obligation (P2/RC-4) in both halves." This correctly distinguishes `DERIVE`'s coexistence-growth semantics from §5.1's `maybe_merge` (line 131, "union evidence of duplicate skills"), and pairs dedup-at-admission with `w_prune` as the two required halves — a faithful, non-overclaiming analogy this time.

**DF-2. P2's "every add has an inverse" (line 9) is now honored structurally for `DERIVE`.** The `w_prune` orphan-retirement bullet (line 502b) is the direct scaffold analog of `g.prune_orphans()` (line 132). Good faithfulness to the document's own organizing principle — modulo the measurability gap raised in Completeness (Co-1) and Red-team (RT-2), which is about whether the inverse is *operable*, not whether it was specified in the right place.

**DF-3. Consistent, honest attribution retained.** Line 481's OpenSpace attribution is unchanged from round 1 and remains accurate against `STUDY-raganything-agentscope-openspace.md` §3 (the `FIX/DERIVED/CAPTURED` + lineage DAG table, and P3's proposal text). No overclaim of novelty for the schema shape.

**DF-4. Minor faithfulness gap:** §17.6 introduces a new persisted artifact (`selfmod_rejected` events) without stating how it composes with §17.1's JUDGE enumeration (line 455) — is the *event writer* itself JUDGE-owned the same way the version-log appender is (line 483, "appended by the §6 orchestrator")? The text implies yes by proximity but doesn't say so as explicitly as it does for the version-log append path.

---

### 3. Red-team resistance

**Score: 66 — weak**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8 and the prior `S17-S18-selfmod-fleet-review*.md` series.

**RT-1. Round-1's RT-1 (item-generation write path) remains closed** — unchanged, §17.1's wall/capability-isolation (lines 456–457) is untouched by §17.6.

**RT-2. Round-1's RT-2 (RC-4 unbounded `DERIVE` coexistence) is resolved in *name* but has a new measurability gap.** The `w_prune` prune criterion is "no selections and no held-out contribution over `w_prune` evaluation windows" (line 502). For §5.1 skills, "selection" is a well-defined, already-specified event — `choose()` (line 160–168) picks a discrete skill/action per step, so a per-skill selection count is a first-class, already-existing signal. §17.1's SOLVE components (line 454: "solve-prompts, tool-wiring, decision heuristics, retrieval config… how the agent *reads/interprets*…") are not selected the same way — a scaffold component (e.g., a solve-prompt template or a retrieval-config module) may be part of every attempt's composed configuration rather than picked discretely per episode. Nothing in §17.1–§17.6 defines a **selection/dispatch mechanism** for `DERIVE`d, coexisting scaffold components analogous to `choose()`'s skill selection — so "no selections" is not obviously measurable for a component that is one of several coexisting, always-in-play scaffold pieces. If, in the eventual implementation, "coexistence" in practice means all `DERIVE`d siblings are composed into every SOLVE attempt rather than routed per-context, the orphan-prune criterion has nothing to count. This is a genuine residual of the RC-4 pattern: the *inverse exists on paper* but its trigger condition is undefined for the axis it's being applied to.

**RT-3. NEW — `selfmod_rejected` is an unrate-limited, ungoverned event sink.** Line 483/499 adds `selfmod_rejected{reason, proposal_hash, ts}` for every admission failure (wall/static check, budget, dedup). Neither §17.5 nor §17.6 states whether `b_sm` (the `self_modify` budget, §17.5) is charged on **proposal/selection** or only on **admitted** actions. If it is the latter (the more natural reading of "`self_modify` budget," i.e. it throttles the actions the agent actually takes, not every attempt), then admission-rejected proposals are not obviously bounded by `b_sm` at all, and each rejected attempt permanently appends a TruthStore event — "lineage rows are permanent" (line 504) generalizes, by the section's own framing, to this new event type too (nothing in §17.6 scopes `scaffold_retention`, which "bounds pruning of blobs only" line 504, to cover `selfmod_rejected` rows, nor does it say this event type is exempt from the permanence claim). DATA-LAYER.md's occurrence-identity hashing (§6.1, lines 156–167) does **not** help here — it dedupes *retries of the same occurrence* (same episode/attempt id), not *repeated distinct occurrences* of the same rejected proposal resubmitted across many episodes, each of which is a legitimately new occurrence-id and hence a new, non-deduped row. This is a residual RC-2-adjacent surface (the audit mechanism designed to make rejections honest and auditable is itself an unbounded write sink an adversarial or buggy SOLVE-side proposer could use to grow TruthStore without bound) that §8's circuit breaker (lines 231–235) does not obviously catch: none of its four named triggers (`K` consecutive rollbacks, eval-variance spike, production-outcome degradation, near-safety-boundary probing) is stated to fire on a high rate of pre-admission rejections.

**RT-4. Round-1's RT-3 (`CAPTURE` unauditable admission) is substantially resolved**, modulo the join-path ambiguity in Correctness C-3 above — a narrower, implementability-flavored residual, not a re-opening of RC-2.

**RT-5. Round-1's RT-5 (status-machine ambiguity) is resolved** by the total status machine (line 498–499).

**RT-6. NEW/residual — the reactivation window is a narrowed but not closed instance of RC-6.** RC-6 (`ALGORITHM-v0.1-redteam.md` lines 59–61) is "non-stationarity invalidates the value tree, but re-anchor only refreshes competence" — the general pattern of trusting an old artifact's validity without checking it against the *current* world. §17.6's rollback (line 504, and Correctness C-2 above) reactivates a byte-exact snapshot into `live` status and only *then* subjects it to a bounded current-held-out check. This is a real improvement over round 1 (which had **no** re-validation step at all — a full instance of RC-6) but, as sequenced, still allows the reactivated component to serve live traffic for up to `w_promo` before its current fitness is confirmed. Per the dimension's own scoring instruction ("score 0 if it reopens a known failure mode; score based on residual attack surface otherwise") — this is judged as a **residual**, not a full reopening, because detection + escalation now exist where none did before. But it is real enough to keep this dimension out of the "pass" band; elaborated fully in the adversarial pass.

**Summary:** 4 of 5 round-1 red-team findings genuinely closed (RT-1, RT-4, RT-5, and RT-2's naming half); one (RT-2's measurability half) and one carried-forward item (RT-6, reactivation) remain open in narrower form; one new surface (RT-3) is introduced by the round-1 fix itself.

---

### 4. Implementability

**Score: 68 — weak**

**I-1. Round-1's I-1–I-4 are resolved:** dedup enforcement locus named (line 502), `CAPTURE` provenance field named (line 489), status-transition table given (line 498–499), `CAPTURE` diff semantics defined (line 492–493).

**I-2. NEW — no selection/dispatch mechanism specified for coexisting scaffold components (blocks `test_derive_orphan_pruned`, line 506, and RT-2 above).** A developer cannot implement "no selections… over `w_prune` evaluation windows" (line 502) without a defined notion of what counts as a "selection" of a specific `DERIVE`d component when multiple live siblings coexist. This needs the same kind of explicit statement §17.1 gives the wall check (line 457) or §17.6 now gives the dedup locus (line 502) — i.e., where in the orchestrator this per-component usage signal is recorded and what "used" means for a scaffold artifact.

**I-3. NEW — `source_ref` verification join path unspecified (blocks `test_capture_requires_gated_success`, line 506).** See Correctness C-3. A developer implementing the admission check needs to know which store/table actually carries "did this episode's outcome pass `commit_gate`," since `evals` (DATA-LAYER.md:135) does not carry that flag directly.

**I-4. NEW — the §12 registration gap (Correctness C-1) is a direct implementability defect, not just a documentation nit.** §12's own framing (line 280–284): "These are the dials a Milestone-0/1 empirical pass tunes. None is guessed in the spec; all are explicit." A developer or a future calibration pass reading §12 as the canonical parameter register (as its text instructs) will simply miss `τ_sm` and `w_prune` — two safety-relevant thresholds (a dedup similarity bar and an orphan-prune window) — because they are not there, despite §17.6 line 505 asserting they are.

**I-5. NEW — reactivation sequencing ambiguity (Correctness C-2) is also an implementability gap:** a developer cannot tell from the text whether the Stage-1-style shadow check gates the `retired→live` status flip (i.e., runs first, in true non-serving shadow) or runs concurrently with the component already serving traffic. The two produce materially different system behavior and neither is ruled out by the current wording.

**Summary:** the four round-1 gaps are closed, but four new-or-carried gaps of comparable concreteness (I-2 through I-5) replace them — the round nets out to genuine but incomplete progress on implementability.

---

### 5. Safety / integrity

**Score: 68 — weak**

**S-1. No named gate, budget enforcer, or partition is weakened.** §17.1/§17.3/§17.5's text is unchanged (confirmed by direct read); `self_modify` budget enforcer remains JUDGE-owned and unwritable (§17.1 line 455, §17.4 line 470) — consistent with the prior `S17-S18-selfmod-fleet-review-r2.md` line 34 finding.

**S-2. `CAPTURE`'s admission property is now a real, checked control** — a genuine safety improvement over round 1 (line 503), modulo the join-path ambiguity (C-3) which is an implementability gap, not a weakening.

**S-3. The reactivation window (RT-6/C-2) is the dimension's main residual concern.** This is precisely the class of harm the rest of the document goes out of its way to prevent structurally rather than just detect (§7's discounted UCT + checkpoint-invalidation, §8's four-clause gate, §14's calibration breaker) — here, a component whose current fitness is *unconfirmed* can serve live production traffic for up to `w_promo` before the shadow check either clears it or triggers the escalation path. The escalation path itself (line 504, "freeze + escalate to the §14 breaker/human") is well-formed and consistent with §14.3's existing breaker-trigger design (line 350–351) — the gap is upstream of that, in the window before escalation is even possible.

**S-4. The `selfmod_rejected` flood (RT-3) is a milder, second safety-adjacent concern:** not a gate weakening, but an availability/integrity concern on the canonical TruthStore (DATA-LAYER.md line 146: "TruthStore is canonical and append-only") that has no stated bound and is not obviously caught by any of §8's four breaker triggers (lines 231–235).

**Summary:** no structural gate is weakened; the two residuals (S-3 primarily, S-4 secondarily) are real but narrower than round 1's fully-open gaps, keeping this dimension just under the 70 pass line rather than clearly below it.

---

### 6. Efficiency / cost

**Score: 76 — pass**

**E-1. Round-1's E-2 (unbounded `DERIVE` dedup-check cost) is substantially addressed** by `w_prune`'s eventual eviction of unused components (line 502b), bounding the live-component set over time — though the bound is soft (see I-2/RT-2: eviction only fires on "no selections… no held-out contribution," so a component with thin-but-nonzero, evenly-spread usage could persist indefinitely without a stated cap `M_max` on live components; this is a softer version of round 1's concern, not a new one).

**E-2. NEW, minor — `selfmod_rejected` events are an unbounded, cold-path write sink** (RT-3/S-4) with no stated retention/GC policy, distinct from `scaffold_retention`'s blob-only scope (line 504). Not hot-path, and consistent with the general (pre-existing, doc-wide) silence on `events` table retention — but §17.6 is the section that introduces this specific new high-frequency-potential event type, so the gap is newly surfaced here even if not newly created.

**E-3. No hot-path change.** `self_modify` remains an episodic outer-§6 action (§17.2 line 460, unchanged); version-log and event appends are cold-path, matching §10's cadence.

---

### 7. Completeness

**Score: 66 — weak**

**Co-1. Missing: a defined "selection"/usage-tracking mechanism for coexisting scaffold components**, needed to make `w_prune`'s "no selections" criterion operable (RT-2/I-2).

**Co-2. Missing: the `source_ref` → gate-pass join path** across `evals`/`lineage`/commit-decision records (C-3/I-3).

**Co-3. Missing: `τ_sm` and `w_prune` are not actually present in §12** despite §17.6 line 505 claiming they are registered there (C-1/I-4) — an incomplete edit, not just a documentation slip, since §12 is the canonical tuning register.

**Co-4. Missing: retention/GC policy (or an explicit "unbounded by design" statement) for `selfmod_rejected` events** (RT-3/E-2).

**Co-5. Missing: explicit sequencing of the reactivation status-flip vs. the shadow re-validation** — does `retired→live` wait on the check, or run concurrently with it? (C-2/I-5).

**Co-6. Positive:** round-1's Co-1 through Co-6 are all closed — `CAPTURE` provenance, diff semantics, the status-transition table, the dedup enforcement locus, the `DERIVE` prune path, and the pre-gate-rejection audit trail are all now present in the text, even where (Co-1 through Co-5 above) their operational details are incomplete.

**Co-7. Positive:** the extended test-stub list (line 506) is well-scoped and each new stub maps to a specific claim in the prose — good test-strategy hygiene, undercut only by the preconditions gaps above.

---

### 8. Consistency

**Score: 60 — weak**

**Cs-1. Direct, verifiable inconsistency: §17.6 line 505 vs. §12 line 286.** See Correctness C-1. This is the single most concrete inconsistency in the revision — not an interpretive question, a grep-verifiable fact.

**Cs-2. `DERIVE`'s relabeling as the growth analog (line 502) is now consistent with §5.1 and P2** — resolves round-1's Cs-2/Cs-3.

**Cs-3. NEW — the `version{...}` schema (line 484–496, 10 fields including `source_ref`, `diff`, `gate_ref`) is still not reflected as a schema delta in DATA-LAYER.md's "Record schemas" section (DATA-LAYER.md §5, lines 133–141), despite that section being the document's own stated single point of truth for "what lives where."** DATA-LAYER.md's existing `lineage` table (line 135: `lineage(checkpoint_id, parent, dataset_id, eval_run_id)`) has entirely different fields from the `version` row §17.6 defines — so "rows in TruthStore lineage" (§17.6 line 483) is, at best, a loose reuse of the word "lineage," not the same table. §18.1 (line 512) explicitly flags its own schema addition as "a DATA-LAYER schema delta" in its section summary; §17.6 does not do the same for either the `version` DAG or the new `selfmod_rejected` event subtype, despite both being genuinely new schema surface.

**Cs-4. The "audit trail never thins" claim (line 504, carried from round 1) is now better supported** by `selfmod_rejected` (resolves round-1's Cs-4) but trades that fix for a new, unaddressed permanence-vs-retention tension for the new event type itself (Co-4/E-2).

---

### 9. Calibration / honesty

**Score: 62 — weak**

**Ca-1. Genuine improvement: `CAPTURE`'s safety framing is now honestly scoped.** Line 503's "checked admission property… residual honesty: it verifies the episodes were gated, not that the distilled pattern caused their success" is exactly the kind of calibrated, non-overclaiming language round 1 asked for (round-1 Ca-2) — a model instance of the discipline this document otherwise practices well (e.g., §16's "not a formal Gödel-machine proof," line 450).

**Ca-2. Overclaim: the reactivation fix's "(closes the stale-fallback gap…)" (line 504) is not fully earned by the mechanism as sequenced.** See Correctness C-2 / the adversarial pass. The honest framing would be "narrows the stale-fallback window to `w_promo` and adds detection + escalation on double-failure" — which is a real, worthwhile improvement, just not a closure.

**Ca-3. Overclaim (or at minimum, an unverified claim): "registered in §12 alongside §17.5's" (line 505) is stated as fact and is false.** This is the most clear-cut honesty defect in the revision because it requires no interpretation — it's directly checkable and fails the check.

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (line 481)** — verified true by direct comparison of those sections' text against the pre-2026-07-13 approved version.

---

## Strongest adversarial objection

**The reactivation fix trades "no re-validation at all" (round 1's gap) for "re-validation that runs after the component is already back in `live`, traffic-serving status" — which is a narrower version of the exact RC-6 pattern round 1 flagged, not a closure of it, and the round-2 text's own language ("closes the stale-fallback gap") overstates what was actually fixed.**

Walk the mechanism precisely. §17.3 Stage-2 defines rollback's payload as reactivating "the frozen last-good SOLVE" (line 465). §17.6 (line 504) realizes this as an immediate status flip: "parent `retired→live`, promoted candidate `live→retired`." The text calls this instant flip a *safety feature* — "Rollback stays instant (safety dominates: the fallback is last-known-good and the regressing candidate must stop acting immediately)" — which is correct as far as it goes: you cannot leave a regressing candidate live while you deliberate. But the same sentence continues, "— but a reactivated component then must pass a bounded Stage-1-style shadow check against *current* held-out within `w_promo`." The word "then" is doing a lot of work: it means the shadow check happens *after* the status flip, i.e., *after* the reactivated component is already `status=live` and (per the status enum's own semantics, line 495, and the general system architecture) already serving real traffic. Calling this a "Stage-1-style shadow check" borrows §17.3's Stage-1 vocabulary — where "shadow" specifically means "scored, not acted on" (line 464) — but applies it to a component that is, at the very same moment, `status=live` (acted on). Those two states cannot both be true of one component under the schema's own single-valued `status` field (line 495). So one of two things is true, and §17.6 doesn't say which: either (a) the "shadow check" is not really Stage-1-style at all — it's a live-serving component being monitored post-hoc, which is a materially weaker guarantee than the label suggests, or (b) there's an unstated additional state (a true, non-serving shadow trial that must clear before the status flip happens) that the four-value status enum doesn't have room for and the prose doesn't describe. Either way, the round-2 text asserts a closure ("closes the stale-fallback gap") that the specified sequencing does not deliver: for up to `w_promo`, the *only* SOLVE component available to serve traffic is one whose fitness against the *current* held-out distribution is, by construction, not yet confirmed — precisely RC-6's "old-value trusted past the point the world moved" pattern, now applied to code rather than the value tree. The mitigation is real (a bounded window, plus a "both versions bad → freeze + escalate" fallback, line 504) — but "bounded and monitored" is a different, weaker claim than "closed," and the gap between those two claims is exactly what a hostile reader should press on, since it is the single item this round of review was explicitly commissioned to re-verify.

## Aggregate confidence

```
critical_floor  = min(Correctness=64, RedTeam=66, Safety=68) = 64
weighted_mean   = (64*2 + 82 + 66*2 + 68 + 68*2 + 76 + 66 + 60 + 62) / 11
                = (128 + 82 + 132 + 68 + 136 + 76 + 66 + 60 + 62) / 11
                = 810 / 11 = 73.6 → 74
overall         = min(64, 74) = 64
```

**Overall confidence: 64 / 100**

## Verdict

**needs-revision**

Genuine progress: 6 of round 1's 8 blockers are cleanly closed (`CAPTURE` provenance, `DERIVE` dedup locus, the status-transition table, `CAPTURE` diff semantics, the softened `CAPTURE` claim, and — largely — the pre-gate-rejection audit trail). The remaining gap is narrower than round 1's, but not yet clear of the 80-point / no-CRITICAL-below-70 bar. Blocking changes required to clear 80:

1. **Fix the false cross-reference:** either actually add `τ_sm` and `w_prune` to §12's "Added-section parameters" list (line 286), or correct §17.6 line 505 to not claim they are registered there. (C-1, I-4, Co-3, Cs-1, Ca-3)
2. **Resolve the reactivation sequencing ambiguity precisely:** state whether the post-rollback Stage-1-style shadow check must clear *before* the `retired→live` status flip (true non-serving shadow, requiring an additional transient state or a documented exception to the four-value status enum), or whether the reactivated component serves live traffic *during* the check (in which case, replace "closes the stale-fallback gap" with an honest "bounds and monitors" framing, and state the maximum acceptable exposure explicitly). (C-2, S-3, RT-6, Ca-2, and the adversarial pass)
3. **Define the selection/usage-tracking mechanism for coexisting `DERIVE`d scaffold components** that `w_prune`'s "no selections" criterion depends on — analogous to how §5.1's skills have a well-defined per-skill selection count via `choose()`. (RT-2, Co-1, I-2)
4. **Specify the `source_ref` → gate-pass join path** (which table/field determines "this episode's outcome passed `commit_gate`") so `test_capture_requires_gated_success` is actually assertable against the documented schema. (C-3, Co-2, I-3)
5. **State a retention/GC policy (or an explicit "intentionally unbounded, cold-path, low-rate" justification) for `selfmod_rejected` events**, and clarify whether `b_sm` throttles proposal attempts or only admitted actions — closing the flood/DoS residual on TruthStore. (RT-3, S-4, Co-4, E-2)
6. **Register the `version` DAG schema (and the `selfmod_rejected` event subtype) as an explicit DATA-LAYER.md schema delta**, the way §18.1 does for its `agent_id` key, rather than an informal "rows in TruthStore lineage" reference to a table whose actual fields (DATA-LAYER.md:135) don't match. (Cs-3)
