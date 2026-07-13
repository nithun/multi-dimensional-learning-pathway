# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 4)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–510), marked "added 2026-07-13, revised r4" |
| Proposed change | Round-4 rewrite of §17.6 claiming closure of all round-3 items: `revalidation` added to the formal schema block; `κ_reval` (default 0.5) parameterizes the tightened rollback threshold, registered in §12 and §17.6; `source_ref` redefined to point at `checkpoint_id`(s) in the §10 lineage table, argued sound via "a committed checkpoint EXISTS iff its §8 gate passed"; DATA-LAYER §5's Truth line updated with `scaffold_versions(...)` and `selfmod_rejected`, flagged as a delta gated under §17.6 |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Round-3 item resolution scorecard

| # | Round-3 item | Claimed status | Verified status | Evidence |
|---|---|---|---|---|
| 1 | Add `revalidation` to the formal `version` schema block | Addressed | **Genuinely resolved** | `docs/research/ALGORITHM-v0.2-pathway-learner.md:498` — `revalidation ∈ {n/a, pending, passed, failed} (post-rollback check state, §below),` is inside the code block (lines 484–499), immediately after `status`. This closes round 3's C-1/Cs-2/I-2/Co-1/RT-4, and the same field now appears in DATA-LAYER's registered delta (`DATA-LAYER.md:137`, `...status, revalidation, created_ts`). Confirmed by direct read, not inference. |
| 2 | Quantify the "tightened" rollback threshold, name a parameter, register it | Addressed | **Genuinely resolved** | `ALGORITHM-v0.2-pathway-learner.md:508` — "`significant(Δ, SE)` trip fires at a reduced evidence margin `κ_reval · z` (`κ_reval` default 0.5 …)"; `:509` — "`κ_reval` (post-rollback tightened-monitor multiplier, default 0.5) — registered in §12 alongside §17.5's"; `:286` — §12's own list now reads "…`w_prune` (§17.6 DERIVE orphan-prune window), `κ_reval` (§17.6 post-rollback tightened-monitor multiplier) …". Named, bounded (default given), and registered in both places claimed. Closes round-3 C-5/I-3/Co-2/Ca-3. |
| 3 | Specify the `source_ref` → gate-pass join path | Addressed | **Not soundly resolved — see Correctness C-1/C-2 below** | `:489–492` redefines `source_ref` as `checkpoint_id`(s) in the §10 lineage table and asserts the admission check is a plain lineage-existence lookup. This does remove round 3's complaint that no join path was named. But (a) it directly contradicts the *separate, unedited* description of the same check in the `CAPTURE` bullet three lines later (`:507`, verbatim-unchanged from round 3: "the TruthStore eval rows are the check target"), and (b) the "exists in lineage ⇔ gate passed" biconditional is a fact about the moment of commit, not about current validity — see the adversarial pass. **The round-3 complaint's letter is closed; a new, arguably more serious soundness gap replaces it.** |
| 4 | Register the `version` DAG, `selfmod_rejected`, and `revalidation` as a DATA-LAYER.md schema delta | Addressed | **Genuinely resolved, modulo one field-name mismatch** | `DATA-LAYER.md:137` — "`scaffold_versions(version_id, component_id, parents, operator, source_ref, snapshot_ref, diff, gate_ref, status, revalidation, created_ts)` + event kind `selfmod_rejected{reason, proposal_hash, ts}` *(delta gated under ALGORITHM §17.6)*." This is a real, present delta line, following §18.1's precedent as instructed. **But** the field is named `snapshot_ref` in the registered delta, while §17.6's own schema block (`:493`) names the same field `snapshot` and describes it as "full component content — immutable" — a direct content/name mismatch between the section and the delta it claims to have shipped consistently with. See Consistency Cs-2. |

Additionally, one round-3 verdict item the caller did **not** claim was addressed this round, and which remains genuinely open, unchanged:

- **Round-3 item 5 (name the §6-orchestrator plug-point for per-component invocation logging, `I-4`)** — `:506`'s DERIVE prune-criterion text ("every invocation is logged to truth by the §6 orchestrator") is verbatim-unchanged from round 3. It is not mentioned in this round's cover note, and §17.6 itself gives no closing/deferral note for it (contrast the dedup-locus clause one sentence earlier, which does name its enforcement point explicitly). Per this round's own instruction to close-or-explicitly-defer every numbered item, this one is neither — it is silently carried forward.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 60 | weak |
| 2 | Design faithfulness | 78 | pass |
| 3 | Red-team resistance (CRITICAL) | 58 | weak |
| 4 | Implementability | 55 | weak |
| 5 | Safety / integrity (CRITICAL) | 62 | weak |
| 6 | Efficiency / cost | 76 | pass |
| 7 | Completeness | 58 | weak |
| 8 | Consistency | 52 | weak |
| 9 | Calibration / honesty | 62 | weak |

## Findings by dimension

### 1. Correctness

**Score: 60 — weak**

**C-1. NEW, most consequential: §17.6's own schema block and its own `CAPTURE` operator bullet describe two different, unreconciled admission mechanisms for the same check.** The `source_ref` field definition (lines 489–492) states: "a committed checkpoint EXISTS iff its §8 gate passed, so the admission check is a **lineage lookup** on existing schema, no new eval column needed." Three sentences later, the `CAPTURE` bullet (line 507, text carried over verbatim from round 3, per the r3 report's own note that "line 503's text is verbatim-equivalent to round 2's") states: "the orchestrator verifies at admission that every referenced episode's outcome passed the §8 gate (**the TruthStore eval rows are the check target** — `test_capture_requires_gated_success` asserts against exactly this)." These are not compatible descriptions of one mechanism: one names `lineage` as the join target and explicitly disclaims needing an eval column; the other names `evals` rows as "the check target." Neither text names the field that could reconcile them (`lineage.eval_run_id`, `DATA-LAYER.md:137`, which does point from a `checkpoint_id` to its originating `evals` row) — so even the charitable reading ("they mean the same join, just described loosely two different ways") is not actually written down anywhere. A developer implementing `test_capture_requires_gated_success` from this section alone has two contradictory specifications to choose from, sourced from the same three-bullet passage. This is the same defect *class* rounds 1–3 flagged three times running (a claimed artifact/mechanism that doesn't match the section's own other statements about itself) — recurring a fourth time, and this time as an outright self-contradiction rather than an omission.

**C-2. NEW, and the sharper of the two source_ref problems: "checkpoint EXISTS in lineage ⇔ its §8 gate passed" is true only as a fact about the instant of commit, and the document's own RC-5 mechanism establishes that committed state can later be invalidated without any corresponding change visible in the lineage schema.** Trace the chain: §3 (`:58, :67`) defines a fast-decay `drift` posterior whose stated, sole purpose is "drives rollback" ("`γ_fast` answers 'am I regressing' (drives rollback only)"). §8's rollback clause (`:229`) reads "rollback fires only on a FRESH, adequately-powered re-eval whose drop clears `significant(...)`" — language that is a direct, cited fix for the *original* v0.1 RC-5 failure mode (`ALGORITHM-v0.1-redteam.md:56`: "one eval swing a decayed cell's `ĉ` by ~0.28 ≫ ε → spurious rollback"), which was specifically about an **already-adopted** cell's competence being revised downward by later evidence, not about rejecting a not-yet-committed candidate. Read together, these establish that the memory-axis rollback mechanism is not limited to "discard the child before it is ever committed" (the only case the abbreviated §6 main-loop pseudocode literally shows, `:199–206`, where `rollback(node, …)` is called on rejection of `child` and `node` itself is left unchanged) — it also covers a **later** reversal of an already-adopted state once fresh evidence shows regression. Now check what the lineage schema records: `DATA-LAYER.md:137` — `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` — **no status, validity, or superseded/rolled-back field of any kind.** TruthStore is append-only and rows are never deleted or amended (`DATA-LAYER.md:146–148`, "canonical and append-only"; `ALGORITHM…§17.6:508`, "lineage rows are permanent"). So a checkpoint that passed `commit_gate` at time T, was adopted, and was **later** invalidated by a fresh-re-eval rollback at time T+k, still satisfies "EXISTS in lineage" **forever** — the schema has no way to distinguish it from a checkpoint that has never been challenged. §17.6's redefinition treats "exists in lineage" as a synonym for "currently valid," but the document's own architecture (append-only truth + no lineage status column + an explicit, cited rollback-on-fresh-evidence mechanism) makes those two properties diverge exactly in the case CAPTURE's admission check exists to prevent: **a distilled pattern drawn from episodes whose underlying checkpoint later turned out to be a fluke, "capturing a lucky run" one level removed** (the checkpoint was lucky, not just the episode). This is a substantive, evidence-backed correctness gap in the mechanism that round 4 was submitted specifically to validate.

**C-3. Round-3 items 1 and 2 (`revalidation` in the schema block; `κ_reval` quantified and registered) are both cleanly and correctly fixed** — see the scorecard above. Both are genuine, verified improvements, not narrative-only.

**C-4. Minor: the `κ_reval` formula itself checks out arithmetically.** `significant(Δ,SE)` trips when `Δ ≥ z·SE` (the standard form implied by §2's "one primitive… statistical test against sampling error," `:41`, and §8's `margin=ε` / `z·SE` framing, `:223`). Halving the multiplier to `κ_reval·z = 0.5z` lowers the trip bar, so a smaller `Δ` now counts as significant — correctly realizing "tightened" (more sensitive to regression) rather than accidentally loosening it. Verified by direct substitution, not just narrative trust.

**Summary:** two of round 3's most-cited defects (missing schema field, unquantified threshold) are genuinely and cleanly fixed, and the arithmetic behind the new `κ_reval` mechanism is sound. But the round's headline fix for the third item — the `source_ref` redefinition — introduces a direct self-contradiction with the section's own adjacent `CAPTURE` bullet, and rests on an equivalence ("lineage existence ⇔ gate passed") that the document's own non-stationarity/rollback machinery (RC-5, §3, §8) shows does not hold once time passes. This is a new instance of the persistent "claimed-but-unreconciled artifact" defect class, now with direct safety relevance rather than a mere completeness gap — keeping this dimension below the 70 floor.

---

### 2. Design faithfulness

**Score: 78 — pass**

**DF-1. The design *intent* behind the `source_ref` redefinition — reuse existing lineage schema rather than add a new eval column — is faithful to the document's stated MVP discipline** (`CLAUDE.md`'s "build only what current work needs" applies at the framework level; the algorithm doc's own §10/§17 pattern of citing existing tables before proposing new ones, e.g. `:483` "rows in TruthStore lineage, blobs in ArtifactStore — §10," is the same instinct). The idea of joining through an existing table instead of inventing a new column is the right kind of parsimony; it is the execution (Correctness C-1/C-2) that falls short, not the design principle.

**DF-2. `revalidation` and `κ_reval`'s designs remain faithful to the document's established idiom of orthogonal fields and named, bounded parameters** (mirrors §19.3's per-clause clamps and §17.5's parameter list) — carried forward correctly from round 3's DF-2.

**DF-3. Attribution to OpenSpace (line 481) is unchanged and remains accurate.** No overclaim of novelty for the schema shape.

**DF-4. Unchanged minor gap (round 3's DF-4):** the reactivation mechanism is still never explicitly connected to §7's RC-6 fix (discounted UCT + tree invalidation) as the code-axis analog of the same design pattern, a missed cross-reference opportunity, not a defect.

---

### 3. Red-team resistance

**Score: 58 — weak**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8 and the prior `S17-S18-selfmod-fleet-review*.md` / `S17-6-lineage-schema-review*.md` series.

**RT-1. Round-3's RT-1/RT-2 (`w_prune`'s invocation-based prune criterion, `selfmod_rejected` flood bound) remain resolved, unchanged** — no regression this round; `:502, :503` are unedited on these points and the round-3 verification stands.

**RT-2. NEW, RC-2-adjacent: Correctness C-1/C-2 reopen a narrow instance of "no capturing lucky runs" (the exact safety property `CAPTURE`'s admission check exists to enforce, `:507`).** RC-2 (`ALGORITHM-v0.1-redteam.md`, referenced throughout §17 as the surface this axis must not reopen) is about a captured/trusted signal turning out not to reflect the ground truth it is presumed to reflect. `CAPTURE`'s whole reason for requiring `source_ref` and checking it at admission is to prevent distilling a pattern from an episode whose apparent success wasn't real (`:507`: "'no capturing lucky runs' a *checked admission property*"). Correctness C-2 shows the check, as specified ("lineage lookup," `:492`), cannot detect the case where the underlying checkpoint's apparent success **was** real at commit time but was subsequently shown to be wrong by the document's own fresh-re-eval rollback mechanism (§3/§8/RC-5) — because the lineage schema carries no post-commit validity state and truth rows are permanent. This is narrower than RC-2's general form (it requires the specific sequence: commit → later rollback → a `CAPTURE` referencing the now-stale checkpoint before or regardless of that rollback) but it is a real, direct instance of the pattern, not merely adjacent to it, and it was introduced by this round's own fix.

**RT-3. Round-3's RT-3 (RC-6 stale-fallback residual, honestly labeled "narrows… does not close") remains open in the same form, unchanged and still honestly scoped** — no regression, no new overclaim on this specific point.

**RT-4. Round-3's item 5 (invocation-logging plug-point, RC-4-adjacent measurability) remains open, silently carried forward** (see the scorecard). Not reopened, but not closed either, and not flagged as deferred.

**Summary:** the two round-3 items claimed and verified fixed hold up; the reactivation residual (RT-3) is unchanged and still honestly framed. But this round's flagship fix creates a new, narrow-but-real RC-2-adjacent gap (RT-2) that the previous three rounds did not have in this specific form — net effect is a regression from round 3's 72 into the "weak" band, because a CRITICAL dimension score must reflect an actual reopened-in-part failure mode, not just an unclosed residual.

---

### 4. Implementability

**Score: 55 — weak**

**I-1. Round-3's I-4/I-3 (κ_reval quantification, revalidation schema presence) are cleanly resolved** — a developer can now build the `version` table and the tightened-monitor logic directly from the text without inventing anything (Correctness C-3/C-4).

**I-2. NEW, and the dimension's central defect: a developer cannot implement `source_ref`'s admission check from this section, because the section gives two incompatible instructions for the same check (Correctness C-1).** Building the `lineage`-lookup version (`:489–492`) and building the `evals`-row version (`:507`) are materially different implementations with different failure modes (the former never inspects outcome quality beyond "was a checkpoint produced at all"; the latter requires resolving which specific eval row(s) correspond to which checkpoint and does not exist as a stored boolean anywhere — `evals` carries `n_pass, n_total`, not a `gate_passed` flag, so "passed the §8 gate" still requires recomputing `commit_gate`'s five-clause conjunction from raw counts, which needs data — `ρ_gen`, `ĉ_baseline`, `safety_eval_heldout` — not all of which is re-derivable from the `evals` row alone). Neither reading is fully specified; both are asserted as fact in the same passage.

**I-3. NEW, minor: `test_capture_requires_gated_success` (`:510`) is unimplementable as a single well-defined test given I-2** — a test author must silently pick one of the two contradictory admission definitions to assert against, meaning the "test" cannot actually verify the section's own stated property until the contradiction is resolved.

**I-4. Unresolved, unchanged: the invocation-logging plug-point (round-3's I-4)** — see scorecard item 5. Still no described mechanism for how the §6 orchestrator observes per-component SOLVE dispatch, unlike the dedup-check's explicitly named locus one clause earlier (`:502`).

**Summary:** two of round 3's implementability gaps are genuinely closed, but the round's own headline fix (source_ref) introduces a implementation-blocking self-contradiction, and one round-3 gap (I-4) is carried forward without acknowledgment — net regression from round 3's 66.

---

### 5. Safety / integrity

**Score: 62 — weak**

**S-1. No named gate, budget enforcer, or partition is weakened by this round's edits.** §17.1/§17.3/§17.5 text is unchanged (confirmed by direct read); the `self_modify` budget enforcer remains JUDGE-owned (§17.1 line 455).

**S-2. The `revalidation`/`κ_reval` reactivation-monitoring mechanism is now fully specified and auditable** — a genuine, verified safety improvement over round 3, where the same mechanism existed in prose but not in the schema. This closes round 3's S-3(a)/(b).

**S-3. NEW, the dimension's main residual: `CAPTURE`'s admission property — the one control this section explicitly frames as a safety-relevant "checked admission property" (`:507`) preventing 'no capturing lucky runs' — cannot currently be trusted to catch the case where the source checkpoint's validity was reversed after commit (Correctness C-2/Red-team RT-2).** A control whose own specification is self-contradictory about which table it checks (Correctness C-1) is, in practice, a weaker control than the prose implies regardless of which reading an implementer picks — either it never notices post-commit invalidation at all (the lineage-only reading) or it requires inventing an eval-row-based gate-pass computation the schema doesn't support as a stored fact (the evals-row reading). Neither delivers the stated guarantee with confidence.

**S-4. The reactivation safety story (§S-2 above) and the `selfmod_rejected` flood bound (round 2/3, unchanged) remain solid, real improvements** — this dimension is not uniformly weak; the specific new gap (S-3) is what pulls the score down from round 3's 74.

**Summary:** no structural gate is weakened, and one specific safety mechanism (reactivation monitoring) is now fully auditable for the first time across all four rounds. But the round's central claimed fix (source_ref) leaves the section's own stated CAPTURE safety guarantee resting on an equivalence that doesn't hold across time, and on a specification with an internal contradiction — enough to keep this CRITICAL dimension below 70.

---

### 6. Efficiency / cost

**Score: 76 — pass**

**E-1. Unchanged from round 3: `w_prune`'s eviction bound remains soft** (no cap on live-component count); same residual, neither better nor worse.

**E-2. Unchanged from round 3: `selfmod_rejected` retention beyond rate-bounding remains open**, consistent with the document's general silence on `events` retention — not new, not worsened.

**E-3. No hot-path change; the `source_ref` lineage lookup is a cold-path admission check**, same complexity class regardless of which of the two contradictory readings (Correctness C-1) is eventually implemented — a single-row or small-join lookup either way. No efficiency regression from this round's edits.

---

### 7. Completeness

**Score: 58 — weak**

**Co-1. Resolved: round-3's Co-1/Co-2 (`revalidation` missing from schema; unquantified threshold)** — both now present (scorecard items 1, 2).

**Co-2. NEW: the `source_ref` admission mechanism is incompletely specified in a way stronger than a mere gap — it is specified twice, incompatibly** (Correctness C-1). Completeness ordinarily asks "is X specified"; here X is over-specified with two mutually exclusive answers, which is arguably worse for an implementer than a bare gap, since it invites picking the wrong one silently.

**Co-3. NEW: no field or process is described for detecting/marking a lineage row as later-invalidated** (Correctness C-2) — if the intended design really is "lineage lookup only, and that's fine because commits are never truly reversed in a way that matters for CAPTURE," that argument is never made; if the intended design is "and also check for a subsequent rollback," the mechanism for that (which table, which event type) is not described, unlike the deliberate detail given to, e.g., `selfmod_rejected`'s own schema.

**Co-4. Resolved: round-3's Co-6/Co-7 (DATA-LAYER.md schema delta never registered)** — now present (`DATA-LAYER.md:137`), modulo the `snapshot`/`snapshot_ref` naming mismatch (Consistency Cs-2).

**Co-5. Unresolved, unchanged, and not flagged this round: the invocation-logging plug-point** (round-3 item 5) — see scorecard.

**Co-6. Positive:** the test-stub list (`:510`) is unchanged from round 3 in scope but `test_capture_requires_gated_success` is now un-implementable as written (Implementability I-3) — a completeness regression on a previously "positive hygiene" item, since the stub's existence now masks rather than surfaces the ambiguity.

---

### 8. Consistency

**Score: 52 — weak**

**Cs-1. NEW, and the single most concrete self-contradiction in this revision: §17.6's `source_ref` field definition (`:489–492`, "a lineage lookup on existing schema, no new eval column needed") directly conflicts with §17.6's own `CAPTURE` operator bullet (`:507`, "the TruthStore eval rows are the check target") — two sentences of the same bulleted list, describing the same admission check, naming two different tables as the check's target, with no reconciling statement anywhere in the section.** This is not a cross-section inconsistency (like round 2's Cs-1, or round 3's Cs-2) — it is intra-section, between two bullets three lines apart, describing one mechanism.

**Cs-2. NEW: the schema block's `snapshot` field (`:493`, "full component content — immutable") does not match the DATA-LAYER.md delta's `snapshot_ref` field (`DATA-LAYER.md:137`) for the same table — a naming and, per the accompanying description, a semantic mismatch (content stored inline vs. a reference to an ArtifactStore blob) between §17.6's own "concrete schema" and the DATA-LAYER delta it claims to have shipped in lockstep with (`:501`, "DATA-LAYER schema delta ships with this section").** Note §17.6's own architecture sentence (`:483`, "rows in TruthStore lineage, blobs in ArtifactStore — §10") implies the intended design actually *is* a reference (matching DATA-LAYER's `snapshot_ref`), which would mean the schema block's own field name and description (`snapshot`, "full component content") are the stale ones — but neither file says so, and a reader comparing the two would reasonably conclude they disagree about what the table looks like.

**Cs-3. Resolved: round-3's Cs-3 (DATA-LAYER.md schema delta never registered)** is now closed in substance (Completeness Co-4) — the delta line exists, modulo Cs-2 above.

**Cs-4. `revalidation`/`κ_reval`'s presence is now consistent across §17.6's schema block, §17.6's prose, §12, and DATA-LAYER.md** — a genuinely fully-reconciled fix, in contrast to `source_ref`'s handling in the same round.

**Summary:** this round closes the prior rounds' most-cited consistency gap (DATA-LAYER registration) cleanly for `revalidation`/`κ_reval`, but introduces two new, directly grep-verifiable contradictions (Cs-1, Cs-2) in the process of "fixing" `source_ref` — the same net pattern as rounds 2 and 3 (fix one, introduce another), this time scored lower because Cs-1 is an intra-section self-contradiction rather than a cross-section omission, which is a more basic failure of the document to agree with itself.

---

### 9. Calibration / honesty

**Score: 62 — weak**

**Ca-1. Genuine, accurate claim: `κ_reval`'s "default 0.5 — half the normal multiplier" (`:508`) is stated with an actual number and a plain-language gloss** — no overclaim, matches Correctness C-4's verification.

**Ca-2. Overclaim: "a committed checkpoint EXISTS iff its §8 gate passed, so the admission check is a lineage lookup on existing schema, no new eval column needed" (`:490–492`) is presented as a settled, sufficient argument for admission-check soundness, when it is actually silent on the temporal dimension (Correctness C-2) that the document's own RC-5/§3/§8 rollback machinery makes load-bearing.** The claim is true in the narrow, literal sense stated (existence does correlate with a gate-pass event having occurred), but the surrounding sentence's confident, closing tone ("no new eval column needed") reads as "this fully resolves the join-path question," which overstates what has actually been shown — the harder question (does the checkpoint's gate-pass status still hold at CAPTURE-admission time?) is not addressed, and the honest framing this document uses elsewhere for exactly this kind of residual (e.g., `:508`'s "narrows… does not close," or `:507`'s own "residual honesty: it verifies the episodes were gated, not that the distilled pattern caused their success") is absent here.

**Ca-3. The round's cover claim ("ALL are now addressed… every claimed artifact has been grep-verified by the author before submission") is true of items 1, 2, and 4 (schema field, parameter, DATA-LAYER delta) but not fully true of item 3** — a grep for `source_ref` does find text at the claimed location, but a grep-level check would not have caught that the *adjacent* `CAPTURE` bullet (`:507`) says something different, because grep confirms presence, not internal agreement. The claim "every claimed artifact has been grep-verified" is calibrated to the wrong failure mode for this specific item — the round-1-through-3 pattern was "asserted but absent"; this round's failure mode is "asserted, present, but contradicted three lines later," which a presence-only check cannot catch.

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (line 481)** — verified true.

**Summary:** three of four claimed fixes are honestly and accurately described; the fourth (`source_ref`) is described with more confidence than its actual soundness supports, and the round's own verification methodology (grep-for-presence) is calibrated to catch the previous rounds' failure mode but not this round's — a real, if narrower, honesty gap than rounds 2–3's flat false claims.

---

## Strongest adversarial objection

**The round's own closing claim — "every claimed artifact has been grep-verified by the author before submission" — is true and yet insufficient, because this round's actual defect is not an absent artifact but a *contradiction between two present artifacts*, and no amount of grepping for presence would ever surface that.**

Walk the meta-pattern across all four rounds. Round 1's defect: an artifact (`source_ref`) was referenced but did not exist. Round 2's defect: artifacts (`τ_sm`, `w_prune`) were referenced as "registered in §12" but were not there. Round 3's defect: an artifact (`revalidation`) was used in prose and by a test stub but was missing from its own schema block. All three are **absence** defects, and a grep for the string in question — precisely the safeguard this round's cover note reports having run — would catch all three, because in each case the fix is "does the string appear where it's claimed to appear." This round runs exactly that check, on exactly that theory of what could go wrong, and it correctly confirms all four items are *present*. But `source_ref`'s round-4 fix has a different shape entirely: the string `source_ref` (and the concept it names) is fully present, in two places, both grep-findable, both textually confident — and they say different things about which table backs the admission check (Consistency Cs-1), and separately, the semantic claim behind the fix ("lineage existence ⇔ gate passed," Correctness C-2) is not challenged anywhere by anyone, including this review's caller-supplied framing, until the temporal dimension is traced through §3/§8/RC-5 by hand. A verification discipline built entirely around "confirm the claimed thing exists" — which is exactly what closed rounds 1–3's defects and exactly what this round's own submission note describes doing — is structurally blind to two artifacts that both exist but disagree, and to one artifact whose stated property is true only at a single instant the surrounding architecture doesn't preserve. If a round 5 is commissioned, "grep for presence" is not the closing-pass discipline that will catch the next instance of this defect class; the closing pass needs to (a) diff every claim about a shared mechanism against *every other place in the section* that describes the same mechanism, not just against the schema block, and (b) for any claim of the form "X ⇔ Y," explicitly check whether the document's own other mechanisms (here, RC-5's rollback machinery) can make X true while Y has since become false, or vice versa.

## Aggregate confidence

```
critical_floor  = min(Correctness=60, RedTeam=58, Safety=62) = 58
weighted_mean   = (60*2 + 78 + 58*2 + 55 + 62*2 + 76 + 58 + 52 + 62) / 11
                = (120 + 78 + 116 + 55 + 124 + 76 + 58 + 52 + 62) / 11
                = 741 / 11 = 67.4 → 67
overall         = min(58, 67) = 58
```

**Overall confidence: 58 / 100**

## Verdict

**needs-revision**

Genuine, verified progress: 3 of the 4 items the caller flagged as addressed (`revalidation` in the schema block, `κ_reval` quantified and registered in both §12 and §17.6, DATA-LAYER §5's delta line) are confirmed genuinely resolved on direct inspection, continuing this section's real improvement trend across rounds 2→3→4 on those specific items. But the round's fourth and most consequential claimed fix — `source_ref`'s redefinition — does not hold up under the scrutiny this round was specifically commissioned to apply, and the round regresses on all three CRITICAL dimensions relative to round 3 (Correctness 68→60, Red-team 72→58, Safety 74→62) as a direct result. The score drops below round 3's 68 rather than continuing to climb toward 80, because this round's central fix introduces defects at least as serious as the ones it closed:

1. **Reconcile `source_ref`'s admission mechanism with `CAPTURE`'s own operator bullet.** Lines 489–492 (lineage lookup) and line 507 (TruthStore eval rows) describe the same check two different, contradictory ways in the same section. Pick one mechanism, name the actual connecting field if both stores are involved (e.g., `lineage.eval_run_id → evals` row), and update whichever bullet is now stale. (Correctness C-1, Consistency Cs-1, Implementability I-2/I-3, Completeness Co-2, Safety S-3)
2. **Address the temporal gap in "checkpoint EXISTS in lineage ⇔ §8 gate passed."** Either (a) show that the memory-axis rollback mechanism described in §3/§8 (fast-decay `drift`, "rollback fires only on a fresh, adequately-powered re-eval") never actually reverses an *already-committed* checkpoint (only rejects not-yet-committed candidates) — in which case state that explicitly, since the current text does not — or (b) if it can reverse a committed checkpoint, add a way for the admission check to detect that a referenced checkpoint has since been invalidated (a status field on `lineage`, or a documented join against a rollback event type), so `CAPTURE`'s "no capturing lucky runs" guarantee actually holds over time, not just at the instant of commit. (Correctness C-2, Red-team RT-2, Safety S-3, Completeness Co-3)
3. **Fix the `snapshot`/`snapshot_ref` field-name (and apparent content-vs-reference semantics) mismatch** between §17.6's schema block (`:493`) and the DATA-LAYER §5 delta (`DATA-LAYER.md:137`) it claims to have shipped consistently with. (Consistency Cs-2, Completeness Co-4 caveat)
4. **Close or explicitly defer round-3's item 5** (name the §6-orchestrator plug-point for per-component invocation logging that `w_prune`'s prune criterion depends on) — carried forward silently for a second round with no acknowledgment. (Implementability I-4, Completeness Co-5)

If a round 5 is commissioned, the authors' own stated verification method ("grep-verified... before submission") should be extended per the adversarial pass: a presence check is necessary but not sufficient — add a pass that diffs every claim about a shared mechanism against every *other* place in the same section (and its registered cross-file delta) that describes that mechanism, and stress-tests any "X exists ⇔ Y held" claim against the document's own mechanisms that could make X and Y diverge over time.
