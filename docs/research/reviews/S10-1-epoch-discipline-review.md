# 360 Review: S10-1-epoch-discipline — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` (uncommitted delta vs. committed baseline) |
| Proposed change | RAF-3: new §10.1 "Epoch discipline" unifying five staleness sites under one rule, retiring `κ_reval`, admitting PR-10 (Epoch Coherence) via §21.3's stated supersession path |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 58 | weak/blocking |
| 2 | Design faithfulness | 68 | weak |
| 3 | Red-team resistance (CRITICAL) | 50 | blocking |
| 4 | Implementability | 68 | weak |
| 5 | Safety / integrity (CRITICAL) | 52 | blocking |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 55 | weak |
| 8 | Consistency | 45 | blocking |
| 9 | Calibration / honesty | 55 | weak |

## Findings by dimension

### 1. Correctness

- **The core unification claim (checkpoint_id already in the identity hash, zero schema delta) checks out.** `ALGORITHM-v0.2-pathway-learner.md:272` claims "the stamp already exists." DATA-LAYER confirms: `id = hash(record_type ‖ semantic_payload ‖ occurrence_provenance)` with `occurrence_provenance = episode/trace id + checkpoint_id + attempt index` (`docs/research/DATA-LAYER.md:173,175`), and the `evals` row schema already carries `checkpoint_id` (`docs/research/DATA-LAYER.md:146`). The zero-schema-delta claim is correct for posterior-moving records.
- **The safety argument for retiring `κ_reval` is quantitatively wrong as stated.** `significant(Δ, se, margin=0, z=2): return Δ > margin + z·se` (`ALGORITHM-v0.2-pathway-learner.md:43-44`). Under the retired mechanism, the pending-fallback trip condition was `Δ > κ_reval·z·se = 0.5·2·se = 1·se` (`ALGORITHM-v0.2-pathway-learner.md:279`, pre-diff text at the same location). Under the new rule the same fallback is monitored at the **standard** multiplier, `Δ > z·se = 2·se` (`ALGORITHM-v0.2-pathway-learner.md:279,524`). Verified arithmetically: this is a **2× increase** in the evidence margin required to trip rollback-to-freeze on a fallback the spec itself still calls "unproven against the current world" and "unvalidated-in-generation." The submission's framing — "the special case deleted with its dial," "the Ousterhout trade" (`ALGORITHM-v0.2-pathway-learner.md:279`) — treats this as pure simplification. It is not: the deleted "special case" was doing real work (faster detection during an admittedly elevated-risk window), and its removal is a substantive change in monitor sensitivity, not merely a naming/legibility change. The argument that "status becomes rule-defined rather than monitor-compensated" (`ALGORITHM-v0.2-pathway-learner.md:272`) conflates two orthogonal things: whether the fallback's status is *labeled* honestly (epistemic correctness — unaffected either way, since the old text already treated `pending` as unvalidated) and how *fast* a regression in that fallback is *detected* (operational safety — demonstrably worsened). This is a real correctness defect in the change's own justification, not a stylistic quibble.
- **One of the "five sites" does not match the text it cites.** `ALGORITHM-v0.2-pathway-learner.md:278` asserts "§19.1's `w_obs` re-observation = *invalidate* at the meta-gate." §19.1's actual text (`ALGORITHM-v0.2-pathway-learner.md:578`) defines `w_obs` purely as "an observation window `w_obs`" for measuring the post-commit regression rate `r̂` used to calibrate gate thresholds — there is no "re-observation" concept, no invalidation action, and no mention of checkpoint-generation crossing anywhere in §19 (confirmed by `grep -n "re-observation" ALGORITHM-v0.2-pathway-learner.md`, which returns only the two §10.1 self-citations). This "site" is asserted, not demonstrated, and appears to be included to round the "five places" narrative to five rather than because §19.1 actually implements a generation-staleness check.
- **The "ancestry order" framing for generation-comparison is underspecified for the case it needs to handle.** The core rule only needs `g_old ≠ g_now` (simple `checkpoint_id` inequality) to trigger the three-move test (`ALGORITHM-v0.2-pathway-learner.md:276`), yet the text specifies "the §10 lineage ancestry order" (`ALGORITHM-v0.2-pathway-learner.md:276`). Ancestry order matters only when a rollback has created a branch (a checkpoint "whose commit was later **reversed**… is off the current ancestry path," `ALGORITHM-v0.2-pathway-learner.md:523`) — exactly the case where a judgment's origin checkpoint is not simply "older" but **invalidated by design** (drift-driven rollback, RC-5), which arguably warrants stricter treatment (mandatory invalidate) than an ordinary superseded-but-uncontested generation. §10.1 does not distinguish these two cases; it treats "different generation" as one undifferentiated bucket. See Completeness and the adversarial pass below.

### 2. Design faithfulness

- The additive-unification framing, the citation discipline (Raft/KIP-101/KIP-595), and the "names what already exists, no schema delta" pattern match this project's established style (cf. §17.6's own provenance note at `ALGORITHM-v0.2-pathway-learner.md:497`, and B2 Amendment A's "field kept, consumed by nothing" precedent, `BUILD-SPECS.md:221`, cited at `ALGORITHM-v0.2-pathway-learner.md:302,525` as "the B2-AmendA `weight` precedent"). Note the precedent is not an exact match — B2's `weight` field was *reserved and never consumed* (`BUILD-SPECS.md:221`: "no approved mechanism consumes it"), whereas `κ_reval` was *consumed, then retired* — a materially different situation (a working safety dial being removed vs. a field that was never load-bearing). The citation borrows the pattern's mechanics ("row stays, consumed by nothing") without acknowledging this is a different kind of change.
- The §19.1 mischaracterization (Correctness, above) is also a design-faithfulness problem: it invents a mechanism in an already-approved, already-gated section (§19, gate-approved per `ALGORITHM-INTEGRATIONS.md:33`) that section's own text does not contain.
- The §21.3 supersession otherwise follows the stated procedure (property-impact statement present, guard list attached, list held at the stated bound of ten) — see the adversarial pass for whether the supersession is *legitimate* under §21.3's own bar, as distinct from whether it is *procedurally formatted* correctly.

### 3. Red-team resistance

- §17.6's rollback/reactivation machinery is explicitly the "code-axis analog of §7's RC-6 fix" (`ALGORITHM-v0.2-pathway-learner.md:524`) — RC-6 is "Non-stationarity invalidates the value tree… a restored artifact is never trusted against a moved world without fresh evidence" (`docs/research/ALGORITHM-v0.1-redteam.md:59`, and quoted almost verbatim in the ALGORITHM text). The `κ_reval` retirement (Correctness, above) weakens exactly this protection: a restored (reactivated) artifact that *is* regressing now takes 2× the evidence to be caught during the window it is served unvalidated. This does not reopen RC-6's original failure mode wholesale (tree-value staleness itself, §7, is untouched), but it does create a new, quantifiable instance of RC-6's underlying pattern — "trust a stale artifact against a moved world with less scrutiny than before" — inside the one mechanism this spec calls RC-6's own code-axis analog.
- It also brushes against RC-7's meta-pattern — "harm/weakness accrues with no gate firing" (`docs/research/ALGORITHM-v0.1-redteam.md`, RC-7 summary) — because the effect of doubling the evidence margin is precisely that a real regression in the serving fallback can persist longer before the gate trips.
- The residual is bounded (still `w_promo`-windowed, still eventually caught) and the spec is honest that a residual exists at all — this is not a full reopening, which is why the score is not 0. But per the dimension's own instruction ("score based on the residual attack surface otherwise"), the attack surface genuinely widened relative to the pre-diff baseline, and the submission's narrative obscures rather than surfaces that widening.

### 4. Implementability

- Concrete: schema fields, test names, and the dispatch mechanism ("an ordinary §6.1 work unit," `ALGORITHM-v0.2-pathway-learner.md:279`) are specified. `test_kappa_reval_retired` and `test_generation_comparison_is_lineage_ancestry` (`ALGORITHM-v0.2-pathway-learner.md:284`) are buildable.
- Gap: the text never states *which* `checkpoint_id` represents a scaffold candidate's "generation" for the §17.6 site. `scaffold_versions` (`ALGORITHM-v0.2-pathway-learner.md:501-515`) has no `checkpoint_id` field; the connection to a checkpoint generation is only inferable indirectly via `gate_ref` → the referenced eval row → that row's `checkpoint_id` (`docs/research/DATA-LAYER.md:146`). §10.1 asserts "the stamp already exists" without spelling out this indirection, leaving a developer to reverse-engineer which of several plausible checkpoint references (proposal time, Stage-1 eval time, Stage-2 promotion time, reactivation time) is the one that counts as "the generation this validation belongs to."
- Gap: "ancestry order" vs. simple equality (Correctness, above) is not resolved into an implementable predicate for the rollback-branch case.

### 5. Safety / integrity

- This is the dimension the κ_reval finding hits hardest. §17.3's post-promotion monitor (`ALGORITHM-v0.2-pathway-learner.md:481`, unchanged by this diff) is a named safety gate; §10.1/§17.6 change its effective sensitivity on the one population (reactivated, pending-revalidation fallbacks) it was specifically tuned for, without the property-impact statement (`ALGORITHM-v0.2-pathway-learner.md:272`: "PR-5 strengthened… PR-10 admitted") flagging any weakening anywhere. Per §21.3's own rule, "a change that weakens a property without argument fails on that ground in review" (`ALGORITHM-v0.2-pathway-learner.md:718`) — no property is labeled *modified-with-argument* for this change, yet a real sensitivity reduction occurred. Even if no single named property (PR-1…PR-10) is technically violated by the letter of its wording, the *substance* the properties exist to protect (fast, reliable detection of a regressing served-but-unvalidated artifact) is weaker after this change.
- Secondary concern: PR-10's enforcement is comparatively soft next to its neighbors. PR-1 (`test_solve_candidate_cannot_import_unredacted_truth`) and PR-2 (`test_no_write_path_SOLVE_to_JUDGE`) are backed by *static* dataflow/capability-isolation checks (`ALGORITHM-v0.2-pathway-learner.md:473`). PR-10's guard, `test_no_consumer_reads_pending_fallback_as_validated` (`ALGORITHM-v0.2-pathway-learner.md:282,707`), is a behavioral test over the read paths that exist *today* — it cannot structurally prevent a future consumer from reading `revalidation=pending` and treating it as validated the way the SOLVE/JUDGE wall structurally prevents a write. The property is admitted at the same confidence level as PR-1/PR-2 in the figure, without disclosing this difference in enforcement strength.

### 6. Efficiency / cost

- No new LLM calls. The "synthetic in-generation eval… dispatched as an ordinary §6.1 work unit" (`ALGORITHM-v0.2-pathway-learner.md:279`) is a re-description of behavior that already existed pre-diff — the old text already had the shadow check running "immediately and concurrently" (`ALGORITHM-v0.2-pathway-learner.md:524`, pre-diff wording preserved in the diff's unchanged clause) — so this is a naming/implementation-routing clarification, not new work. No O(n²) additions to any hot path. Zero schema delta is correct (Correctness, above). Score reflects a genuinely low-cost change.

### 7. Completeness

- **Guard coverage gap.** The "five sites" preamble (`ALGORITHM-v0.2-pathway-learner.md:272,278`) lists §7, §10, §17.6, §18.2, §19.1. PR-10's "Guarded by" list (`ALGORITHM-v0.2-pathway-learner.md:282,707`) names four tests covering only three of the five: `test_tree_stats_invalidated_on_checkpoint_change` (§7), `test_stale_fleet_read_no_discount` (§18.2/§18.7), and the two §17.6 tests. **No guard is cited for §10's own cache invalidation** (the `Θ`/`z` cache-on-checkpoint-change behavior described at `ALGORITHM-v0.2-pathway-learner.md:266`), and **no guard exists for the §19.1 site at all** — consistent with that site not being a real instance of the rule (Correctness, above).
- **Rollback-branch edge case not addressed.** The CAPTURE bullet already acknowledges that a "checkpoint whose commit was later reversed… is off the current ancestry path" (`ALGORITHM-v0.2-pathway-learner.md:523`). §10.1 never states how the epoch-discipline rule treats a judgment produced during a since-reverted checkpoint span — whether it is simply "old" (ordinary supersession, any of the three legal moves apply) or categorically different (a discarded/invalidated branch, arguably requiring mandatory *invalidate*, never *serve-marked*, since the branch itself was judged unsafe to continue on). This is a real, foreseeable case (RC-5 drift-driven rollback is a named, expected mechanism) left as an open question.
- **No handling of a second epoch change mid-revalidation.** If the live checkpoint generation changes again while a reactivated fallback's synthetic in-generation eval is still running (within `w_promo`), does that eval's evidence still count toward "current generation," or does the fallback need to restart against yet another new generation? Not addressed.

### 8. Consistency

- **§21.4 is not updated and now contradicts §21.3.** `ALGORITHM-v0.2-pathway-learner.md:732` (untouched by this diff): "**RC-6** (stale value tree) → the **named non-property** in §21.3 (mechanism-covered; property pending RAF-3)." But §21.3 itself, as amended by this same diff, no longer treats epoch coherence as pending — it has been superseded and admitted as PR-10 (`ALGORITHM-v0.2-pathway-learner.md:720`), and the PR-10 row (`ALGORITHM-v0.2-pathway-learner.md:707`) is live in §21.1. §21.4's RC-6 row should now read "→ PR-10," not "pending RAF-3." This is a same-document, same-commit self-contradiction: two sections of the file, both touched by RAF-3's stated scope (§21 "amendments via §21's own stated path" per the task description), actively disagree about whether the property is pending or admitted. This is exactly the class of defect L-013 exists to catch ("a co-dependent location… left stale and now contradicts the fix," `.claude/memory/lessons.md:37`) — and the submission's own pre-submission process note claims an "end-to-end κ_reval sweep found and fixed three co-dependent locations" (the caller's task description), but that sweep evidently did not extend to the RC-6↔PR-10 cross-reference, which is a different symbol (`RC-6`, not `κ_reval`) than the one that was swept.
- §19.1's mischaracterization (Correctness, above) is also a consistency defect: §10.1's description of §19.1 does not match §19.1's own text.

### 9. Calibration / honesty

- Genuinely honest in places: the preamble concedes RAF-3 "bounds and names the §17.6 residual rather than closing it" (`ALGORITHM-v0.2-pathway-learner.md:272` restated at `279`), and does not claim the serving-window risk is eliminated.
- Not honest enough about the κ_reval retirement: the property-impact statement (`ALGORITHM-v0.2-pathway-learner.md:272`) reports only "preserved," "strengthened" (PR-5), and "admitted" (PR-10) — no line acknowledges that a real, quantifiable (2×) reduction in monitor sensitivity occurred on the served-fallback population. §21.3's own honesty standard — "properties describe what **is** enforced, never what **should be**" (`ALGORITHM-v0.2-pathway-learner.md:719`) — cuts against PR-10's overall framing, since the "always true" wording is true only in the weak, definitional (trusted-vs-serving) sense, and the section that could have disclosed the tradeoff plainly (rather than filing it under "the Ousterhout trade") does not.
- The claim "PR-5 strengthened" (`ALGORITHM-v0.2-pathway-learner.md:272`) is not obviously wrong — PR-5 is about the *existence* of an inverse, and that still holds — but placing "strengthened" immediately next to the unstated sensitivity reduction reads as if the whole reactivation mechanism got safer, when the operative monitor got measurably slower to react.

## Strongest adversarial objection

**The PR-10 admission itself may not be legitimate under §21.3's own stated bar, and the live document no longer preserves the text needed to check that.**

The original (pre-diff) §21.3 bullet set an explicit, narrow admission condition: "It becomes PR-10 only if the queued epoch-discipline delta (RAF-3) **closes** it; until then, claiming it would violate this section's own admission rule" (recovered from the diff hunk against `ALGORITHM-v0.2-pathway-learner.md:720`, since the phrase does not survive in the current file). RAF-3's own preamble concedes it does **not** close the residual: "the serving window… still exists, bounded by `w_promo`… this rule does not close it" (`ALGORITHM-v0.2-pathway-learner.md:279`). The submission's route around this is to argue that the *property as worded* ("no judgment is *trusted* across a generation change") is satisfiable by definitional fiat — a served-marked judgment is, by construction, never "trusted" — so the property can be "always true" without the underlying residual being closed. That is a genuine reinterpretation of what "closes it" meant in the original bar: the most natural reading of the original bullet (which is explicitly about *epoch coherence*, i.e., the underlying exposure, not about a wording trick) was that the residual itself needed to be eliminated, not that the property could be phrased narrowly enough to dodge it.

Two things compound this into the strongest objection in the submission:

1. **The document's own historical record of the bar has been elided, not preserved.** The new §21.3 text renders the original bullet as `~~**A known non-property, named honestly:** *epoch coherence*…~~` (`ALGORITHM-v0.2-pathway-learner.md:720`) — a strikethrough followed by an ellipsis. The one sentence that actually mattered for judging this supersession's legitimacy — "It becomes PR-10 only if… RAF-3 closes it; until then, claiming it would violate this section's own admission rule" — is **not** in the live document. A reader auditing this section on its own (the entire point of §21, per its preamble: "the small set of invariants… therefore the list any modification… must preserve," `ALGORITHM-v0.2-pathway-learner.md:692`) cannot check whether the admission condition was actually met; they would have to go to `git log`/`git diff` to recover it. The task description's framing — "history retained" — overstates what is actually preserved: a fragment and an ellipsis is not history, it is a redaction.
2. **This is precisely the failure mode §21.3's own rule exists to prevent** — "properties describe what **is** enforced, never what **should be**" (`ALGORITHM-v0.2-pathway-learner.md:719`). A submission that (a) concedes it hasn't closed the gap the property was gated on, (b) reinterprets the gating word to mean something weaker than the residual's closure, and (c) truncates the very sentence a reviewer would use to check the reinterpretation, is the textbook shape of an author narrating their own change past a gate rather than a reviewer finding it clears the gate. That does not mean PR-10 is wrong to admit — the trusted/serving distinction may well be a legitimate, useful property — but it means the admission should have been filed as *modified-with-argument* (per §21.3's own three-way vocabulary, `ALGORITHM-v0.2-pathway-learner.md:718`) with an explicit argument for why "closes it" is satisfied by the weaker reading, not folded into "admitted" as if the original bar were met on its own terms.

## Aggregate confidence

```
critical_floor  = min(Correctness=58, RedTeam=50, Safety=52) = 50
weighted_mean   = (58*2 + 68 + 50*2 + 68 + 52*2 + 88 + 55 + 45 + 55) / 11
                = (116 + 68 + 100 + 68 + 104 + 88 + 55 + 45 + 55) / 11
                = 699 / 11
                = 63.55 → 64
overall         = min(50, 64) = 50
```

**Overall confidence: 50 / 100**

## Verdict

**needs-revision**

1. Quantify and disclose the `κ_reval` retirement's effect on monitor sensitivity in the property-impact statement (currently silent on it); either restore an equivalent (or argued-sufficient) protection for the pending-fallback window, or explicitly file the change as *modified-with-argument* against PR-5/PR-10 with a stated, defended tradeoff — not as pure hygiene ("the Ousterhout trade").
2. Fix or drop the §19.1 "site" — either point to actual generation-crossing text in §19 (add it there first, under its own gate, if it doesn't exist) or remove it from the "five sites" claim and adjust the "one rule instantiated everywhere" framing to four sites.
3. Update §21.4's RC-6 row (`ALGORITHM-v0.2-pathway-learner.md:732`) to reflect PR-10's admission — it currently still says "property pending RAF-3," contradicting the amended §21.3.
4. Add guards (or an explicit acknowledgment of the gap) for the two unguarded sites in PR-10's "Guarded by" list: §10 cache invalidation and (pending resolution of #2) §19.1.
5. Resolve the rollback-branch edge case: state explicitly whether a judgment from a since-reverted (drift-rolled-back) checkpoint span is treated identically to an ordinarily-superseded generation, or must be mandatorily invalidated.
6. Either preserve the original §21.3 admission-bar sentence in full (not elided) so the supersession is self-auditable from the live document, or explicitly restate the reinterpreted admission criterion and argue it is equivalent to the original — per §21.3's own *modified-with-argument* path.
