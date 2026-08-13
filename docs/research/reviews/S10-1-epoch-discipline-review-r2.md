# 360 Review: S10-1-epoch-discipline — 2026-08-13 (round 2)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` (uncommitted delta vs. committed baseline `HEAD`) |
| Proposed change | RAF-3 round 2: new §10.1 "Epoch discipline" (four staleness sites unified), `κ_reval` **kept** byte-identical (round-1 retirement reverted), §17.6/§21 amendments, PR-10 admitted via §21.3's modified-with-argument path, §12 registry row |
| Round 1 | `docs/research/reviews/S10-1-epoch-discipline-review.md` — 50/100, needs-revision, six required changes |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 76 | weak |
| 2 | Design faithfulness | 85 | pass |
| 3 | Red-team resistance (CRITICAL) | 84 | pass |
| 4 | Implementability | 73 | weak |
| 5 | Safety / integrity (CRITICAL) | 76 | weak |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 76 | weak |
| 8 | Consistency | 65 | weak |
| 9 | Calibration / honesty | 78 | weak |

## Findings by dimension

### 1. Correctness

- **Required change #1 is genuinely resolved and independently verified.** Comparing the diff's removed (`-`) lines — which are `HEAD`'s committed text, confirmed identical via `git show HEAD:docs/research/ALGORITHM-v0.2-pathway-learner.md | sed -n '480,502p'` — against the added (`+`) lines at `ALGORITHM-v0.2-pathway-learner.md:525`, the trip condition is unchanged in both: `significant(Δ, SE)` fires at `κ_reval · z` while `revalidation=pending`, `κ_reval` default 0.5, in both the committed baseline and the new text. The round-1 "earlier draft" that swapped this to the standard `z·se` margin is not in the current diff at all — the retraction is real, not asserted. `git diff` byte-comparison confirms `κ_reval · z` survives unchanged; only prose around it changed.
- **The §12 clamp is correctly stated and consistent with §10.1's rule text.** `κ_reval ∈ (0, 1]` at `ALGORITHM-v0.2-pathway-learner.md:303` (registry) matches "`κ_reval`'s ceiling is 1.0 by its §12 registration" at `ALGORITHM-v0.2-pathway-learner.md:280`. Guarded by `test_kappa_reval_never_looser_than_standard` (`ALGORITHM-v0.2-pathway-learner.md:285`). No arithmetic defect found here.
- **A new correctness defect of the same class round 1 flagged for §19.1 (asserting an artifact "exists" without demonstrating it) recurs at `ALGORITHM-v0.2-pathway-learner.md:283`.** The in-body PR-10 quote cites `` `test_stale_fleet_read_no_discount` (§18.7, existing) `` as an already-existing test. It is not. `grep -n "test_" ` on §18.7's own Checks bullet (`ALGORITHM-v0.2-pathway-learner.md` §18.7, "New parameters & checks") lists exactly six tests — `test_fleet_of_one_equals_single_agent`, `test_no_cross_agent_state_read`, `test_transfer_revalidated_on_receiver_heldout`, `test_fleet_coverage_spreads_frontier`, `test_coverage_floor_dominates_fleet_discount`, `test_fleet_self_modify_cannot_collectively_capture_verifier` — none of which is `test_stale_fleet_read_no_discount`. `git show HEAD:...` confirms this test name does not appear anywhere in the committed baseline either. The test is real behavior (§18.2's `φ=1` conservative-staleness rule, `ALGORITHM-v0.2-pathway-learner.md` §18.2) but it has never actually been named as a check anywhere in the document — "(§18.7, existing)" is a false citation, not a stylistic shorthand. This is a direct recurrence of round 1's "asserted, not demonstrated" defect (round 1 Correctness finding #3), now inside the very passage that argues PR-10's guards are "already in the spec."
- The core unification claim (checkpoint_id already in the identity hash, zero schema delta) still checks out, unchanged from round 1's finding — `ALGORITHM-v0.2-pathway-learner.md:272`, `docs/research/DATA-LAYER.md:173,175,146`.

### 2. Design faithfulness

- The additive-unification framing, Raft/KIP-101/KIP-595 provenance, and "names what already exists, no schema delta" pattern are unchanged from round 1 and remain faithful to house style (`ALGORITHM-v0.2-pathway-learner.md:272`).
- The B2-AmendA `weight`-precedent overclaim round 1 flagged (§17.6's `κ_reval` was a *consumed* dial vs. B2's *never-consumed* field) is now moot — since `κ_reval` is kept rather than retired, the precedent citation no longer needs to carry that weight, and the current text does not lean on it for the retirement (it isn't retired). Non-issue in this round.
- §19.1 mischaracterization is now withdrawn explicitly (`ALGORITHM-v0.2-pathway-learner.md:278`: "the claim is withdrawn"), removing round 1's design-faithfulness objection about inventing a mechanism inside an already-gated section.

### 3. Red-team resistance

- **The core RC-6 regression round 1 identified is closed.** Round 1's finding: "a restored (reactivated) artifact that *is* regressing now takes 2× the evidence to be caught" no longer applies — the trip margin is verified byte-identical (Correctness, above), so the §17.3 post-promotion monitor's sensitivity on the serve-marked population is unchanged from the pre-RAF-3 baseline. RC-6 ("a restored artifact is never trusted against a moved world without fresh evidence," `docs/research/ALGORITHM-v0.1-redteam.md:59`) is not reopened.
- **The rollback-branch gap is now closed with a concrete rule.** `ALGORITHM-v0.2-pathway-learner.md:279`: a judgment from a since-reverted span gets "mandatory invalidate-or-absent, never serve-marked," guarded by `test_reverted_span_never_serve_marked` (`ALGORITHM-v0.2-pathway-learner.md:285,708`). This directly forecloses a plausible RC-5/RC-6 interaction (a drift-rolled-back judgment being read as legitimately serve-marked) that round 1 left as an open question.
- Residual: the guard-list inconsistency (Consistency, below) means a reader relying on the in-body quote at line 283 alone would believe two of the seven guards — `test_serve_marked_monitor_tightened` and `test_reverted_span_never_serve_marked` — don't exist for PR-10, understating the actual protection. This is an audit-trail gap, not a reopened attack surface: the guards are real and are correctly listed at `ALGORITHM-v0.2-pathway-learner.md:285,708`.

### 4. Implementability

- `test_kappa_reval_never_looser_than_standard`, `test_serve_marked_monitor_tightened`, `test_reverted_span_never_serve_marked`, `test_cache_invalidated_on_checkpoint_change` are all concretely specified with clear pass conditions (`ALGORITHM-v0.2-pathway-learner.md:285`).
- **Round 1's implementability gap #2 (which `checkpoint_id` represents a scaffold candidate's "generation" for the §17.6 site) is not addressed in this round.** It was not one of round 1's six required changes, so this is not a new blocker, but it remains open: `scaffold_versions` (`ALGORITHM-v0.2-pathway-learner.md:509-521`) still has no direct `checkpoint_id` field, and the indirection via `gate_ref` → eval row → `checkpoint_id` is still not spelled out. A developer implementing `test_generation_comparison_is_lineage_ancestry` for the §17.6 site will still need to reverse-engineer which of several plausible checkpoint references counts.
- The false "(§18.7, existing)" citation (Correctness, above) is also an implementability defect: a developer told to write "the guards already in the spec" for PR-10 will not find `test_stale_fleet_read_no_discount` anywhere and will have to invent it fresh despite the text implying it's a lookup, not a write.

### 5. Safety / integrity

- **The headline safety regression from round 1 is fixed and verified.** §17.3's post-promotion monitor (`ALGORITHM-v0.2-pathway-learner.md:482`, unchanged by this diff) keeps its tuned sensitivity on the serve-marked population; the property-impact statement now correctly states "PR-5 preserved (the §17.3 monitor's sensitivity is unchanged...)" (`ALGORITHM-v0.2-pathway-learner.md:272`) — an accurate claim this time, unlike round 1's silent-on-the-regression version.
- **The PR-10 admission's own stated bar is undermined by the guard-list defect.** §21.3's admission rule requires a new property's "maintaining mechanism *and* guards **already in the spec**" (`ALGORITHM-v0.2-pathway-learner.md:719`, unchanged). The modified-with-argument case for PR-10 is built at `ALGORITHM-v0.2-pathway-learner.md:281` and the property is then stated with its own "Guarded by" list at line 283 — but that list is both **incomplete** (4 of the 7 actual guards, missing `test_serve_marked_monitor_tightened`, `test_cache_invalidated_on_checkpoint_change`, `test_reverted_span_never_serve_marked`) and **contains a false existence claim** (`test_stale_fleet_read_no_discount`, "§18.7, existing" — not in the spec anywhere; see Correctness). A property admitted on the strength of "guards already in the spec" should not have its own canonical guard-list citation be wrong in the same breath. This does not reopen a gate or weaken enforced behavior (the real guards at `ALGORITHM-v0.2-pathway-learner.md:285,708` are sound), but it means the admission's *procedural* bar — audit-checkable "already in the spec" — is not yet cleanly met at the passage that argues it.
- The κ_reval never-loosen clamp (`κ_reval ∈ (0,1]`, `ALGORITHM-v0.2-pathway-learner.md:303`) is a genuine, well-specified safety improvement over round 1 (no such clamp existed before), correctly guarded.

### 6. Efficiency / cost

- No new LLM calls; the synthetic in-generation eval is still a re-description of pre-existing dispatch behavior (`ALGORITHM-v0.2-pathway-learner.md:525`, unchanged from round 1's assessment). Zero schema delta holds. No hot-path complexity change. Unchanged from round 1's 88.

### 7. Completeness

- **Guard coverage across the four sites is now genuinely present** — `test_tree_stats_invalidated_on_checkpoint_change` (§7), `test_cache_invalidated_on_checkpoint_change` (§10), `test_stale_fleet_read_no_discount` (§18.2/§18.7), and the §17.6 tests are all cited in the canonical §21.1 table row (`ALGORITHM-v0.2-pathway-learner.md:708`) — resolving round 1's completeness gap, modulo the false "existing" tag on one of them (Correctness).
- **Rollback-branch edge case: resolved** (`ALGORITHM-v0.2-pathway-learner.md:279`, guarded by `test_reverted_span_never_serve_marked`) — round 1's gap closed.
- **Second-epoch-change-mid-revalidation edge case: still not addressed.** Round 1 asked whether a second generation change while a reactivated fallback's synthetic eval is still running (within `w_promo`) invalidates that in-flight evidence or not. Nothing in this round's diff speaks to it. Not one of the six required changes, so non-blocking this round, but still an open, foreseeable gap (§10.1's own machinery — two "different generation" events close together — makes it a realistic case, not a hypothetical one).

### 8. Consistency

- **Round 1's headline consistency defect is fixed.** §21.4's RC-6 row now reads "→ **PR-10** (admitted 2026-08-13 via §10.1; the §21.3 bullet that held it pending is superseded, original preserved there verbatim)" (`ALGORITHM-v0.2-pathway-learner.md:733`), agreeing with the amended §21.3 (`ALGORITHM-v0.2-pathway-learner.md:721`). No remaining "pending RAF-3" contradiction found; independently swept via `grep -n "PR-10\|RC-6"` across the file.
- **A new, independently-discovered instance of the same defect class (L-013: "a co-dependent location left stale and now contradicts the fix," `.claude/memory/lessons.md:37`) exists between `ALGORITHM-v0.2-pathway-learner.md:283` and `:708`.** Both are "Guarded by" lists for the identical property (PR-10 — Epoch Coherence), one inline in §10.1's own body, one in the canonical §21.1 figure — and they disagree:
  - Line 283 (§10.1 body, in-line PR-10 quote): 4 tests — `test_no_consumer_reads_pending_fallback_as_validated`, `test_reactivation_dispatches_synthetic_eval_immediately`, `test_stale_fleet_read_no_discount`, `test_tree_stats_invalidated_on_checkpoint_change`.
  - Line 708 (§21.1 table, the canonical figure): 7 tests — the same 4 plus `test_serve_marked_monitor_tightened`, `test_cache_invalidated_on_checkpoint_change`, `test_reverted_span_never_serve_marked`.
  The author's grep sweep (cited in the task framing as finding "zero" five-site/RETIRED remnants) evidently checked for those two specific stale symbols but not for guard-list synchronization between a property's in-body statement and its table row — the same blind spot round 1's §21.4 finding exposed, recurring in a new location within the same commit.
- §19.1 is now consistently characterized as withdrawn everywhere checked (`ALGORITHM-v0.2-pathway-learner.md:272,278`) — no stray "five sites" or "fifth site" language found by independent `grep -n -i "five site\|five place\|fifth site"`, which returns zero hits. No stray "RETIRED"/retirement language for `κ_reval` found either (`grep -n -i "RETIRED"` returns only unrelated `status ∈ {..., retired}` state-machine hits, none about `κ_reval`).

### 9. Calibration / honesty

- **Round 1's sharpest honesty critique is substantively answered.** The original §21.3 admission-bar sentence is now preserved **verbatim** (`ALGORITHM-v0.2-pathway-learner.md:721`) rather than elided — checked word-for-word against the diff's removed line and found to match exactly, including the exact phrase "It becomes PR-10 only if the queued epoch-discipline delta (RAF-3) closes it; until then, claiming it would violate this section's own admission rule." A reader can now audit the supersession from the live document alone, without `git log`.
- **The modified-with-argument reasoning is explicit, self-flagged, and invites rejection** ("A reviewer who rejects this argument rejects the admission," `ALGORITHM-v0.2-pathway-learner.md:281`) — this is the honest form round 1 asked for.
- **Ruling on the argument's merits (this round's central judgment call): the semantic core is accepted, the procedural execution is not yet clean.** The reinterpretation of "closes it" as "becomes truthfully statable as always-true" is a legitimate reading of §21.3's actual admission rule text ("properties describe what **is** enforced, never what **should be**," `ALGORITHM-v0.2-pathway-learner.md:719`) — PR-10 as worded ("no judgment is *trusted*...") is true by construction once "trusted" is defined to exclude serve-marked, the same way PR-8 (Bounded Claims) and PR-7 (Truth Canonicity) are definitional-completeness guarantees rather than empirical claims about absence of harm. This is a defensible admission in spirit, and materially different from — and more honest than — simply asserting the residual is gone. However, the admission rule's other leg — "mechanism **and guards already in the spec**" — is not cleanly met at the passage making the argument: the guard list attached to the property statement itself (line 283) is stale and contains a false "existing" citation (Correctness/Safety, above). An admission that argues its way past a semantic gate should not simultaneously misstate the mechanical gate (guards on record) it also needs to clear. **Ruling: the argument for reinterpreting "closes" is accepted; the claim that PR-10's guards are cleanly "already in the spec" as stated at line 283 is not yet accurate and should be treated as a required fix, not folded into the admission's honesty score as settled.**
- The false "(§18.7, existing)" citation is itself a calibration miss — claiming test coverage that doesn't exist, even though the underlying behavior (§18.2's `φ=1` rule) is real and correctly described in prose.

## Strongest adversarial objection

**The passage that argues PR-10 is legitimately admitted is the same passage whose own evidence for that argument is wrong.**

§21.3's admission rule is two-legged: (1) the property must be truthfully statable as always-true, and (2) its "maintaining mechanism *and* guards" must already be in the spec (`ALGORITHM-v0.2-pathway-learner.md:719`). Round 2's revision makes a genuine, well-argued case for leg (1) — the trusted/serving distinction is real and the argument is transparent about its own reinterpretation. But leg (2) is asserted at the exact same location (`ALGORITHM-v0.2-pathway-learner.md:283`, the PR-10 property quote itself) with a guard list that is (a) three guards short of what the section's own Checks bullet two lines later (`:285`) and the canonical §21.1 table (`:708`) actually specify, and (b) cites one guard, `test_stale_fleet_read_no_discount`, as "§18.7, existing" when no such test exists anywhere in the document, committed or uncommitted. A reviewer checking the admission's second leg exactly where the document tells them to look (the property statement itself) would conclude PR-10 is under-guarded and partly guarded by a fabricated citation — the opposite of what "guards already in the spec" is supposed to establish. This is not a reopened attack surface (the real guards are sound and do exist two paragraphs later), but it is the precise failure mode §21.3 exists to prevent applied recursively to the very section arguing it has been satisfied: a submission narrating past its own gate rather than a reviewer finding it clears the gate, on the narrower but real question of "are the guards actually where the text says they are."

## Aggregate confidence

```
critical_floor  = min(Correctness=76, RedTeam=84, Safety=76) = 76
weighted_mean   = (76*2 + 85 + 84*2 + 73 + 76*2 + 88 + 76 + 65 + 78) / 11
                = (152 + 85 + 168 + 73 + 152 + 88 + 76 + 65 + 78) / 11
                = 937 / 11
                = 85.18 → 85
overall         = min(76, 85) = 76
```

**Overall confidence: 76 / 100**

## Verdict

**needs-revision**

Round 1's six required changes are substantively resolved — the κ_reval sensitivity regression is genuinely reverted and verified byte-identical, the §19.1 claim is withdrawn, §21.4 now agrees with §21.3, the rollback-branch edge case has a concrete rule and guard, and the original §21.3 admission-bar text is preserved verbatim rather than elided. This is real, verifiable progress (50 → 76), not narrative confidence. What remains, all narrow and fast to fix relative to round 1's scope:

1. Synchronize the "Guarded by" list in the in-body PR-10 quote (`ALGORITHM-v0.2-pathway-learner.md:283`) with the canonical §21.1 table row (`:708`) — add `test_serve_marked_monitor_tightened`, `test_cache_invalidated_on_checkpoint_change`, and `test_reverted_span_never_serve_marked`, or explicitly note the 283 list is a subset and why.
2. Fix the false "(§18.7, existing)" citation for `test_stale_fleet_read_no_discount` (`ALGORITHM-v0.2-pathway-learner.md:283,708`) — this test does not exist in §18.7 or anywhere else in the document; either add it to §18.7's Checks bullet as a real new test, or relabel it "named as a guard" (as `test_tree_stats_invalidated_on_checkpoint_change` is correctly labeled) rather than "existing."
3. Re-run the end-to-end sweep specifically for guard-list synchronization between a property's in-body statement and its §21.1 table row — this defect class (L-013) has now recurred within this same artifact across two consecutive rounds, in two different locations; the pre-submission checklist's grep step should be widened to check guard-list identity, not just symbol presence/absence.
4. (Non-blocking, carried from round 1, still open) State which `checkpoint_id` is authoritative for a scaffold candidate's "generation" at the §17.6 site — the `gate_ref` indirection through `scaffold_versions` is not spelled out.
5. (Non-blocking, carried from round 1, still open) Address the second-epoch-change-mid-revalidation case: does a live generation change during an in-flight synthetic eval invalidate that eval's evidence?
