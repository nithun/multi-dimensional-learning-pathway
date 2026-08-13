# 360 Review: DL-conformance-checker — round 3 — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §12 "Conformance checker — replaying truth against ALGORITHM §21" (uncommitted working tree), plus co-dependent deltas: §5's two new event kinds, §6.1's exemption-list entry, §2's `conformance.py` layout line, §11's bookkeeping status flip (all re-verified this round) |
| Proposed change | Round 3 of RAF-1b: fixes round 2's two blockers — the §12.3 ArtifactStore-blob self-contradiction, and the §21.2 reconciliation's overclaimed "no reinterpretation" — plus explicit disclosure of PR-5(i)'s spot-check/retention-horizon cost |
| Prior rounds | `reviews/DL-conformance-checker-review.md` — 58/100, needs-revision, six required changes. `reviews/DL-conformance-checker-review-r2.md` — 74/100, needs-revision, two required changes (one new self-contradiction, one overclaim) |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"`. Filing as a direct review report (not a proposal).

## Round-2 required-change disposition (summary before scoring)

| # | Required change | Verified this round |
|---|---|---|
| 1 | Fix the `DATA-LAYER.md:398` ArtifactStore-blob self-contradiction | **Done, verified correct.** `:398` now reads: "A manifest version is registered by the administrative `conformance_manifest` event, whose `content` field carries the manifest **inline** (§5 — a small declarative entry table; `content_hash` for integrity; **no ArtifactStore involvement**, per §12.1's Port-delta statement)…" — matching `:146` ("`content` is the manifest inline… no blob store is involved and no `ArtifactStore` method is added") and `:369` ("the manifest content travels inline… no `ArtifactStore` involvement exists at all"). Grepped the full file for `ArtifactStore blob` — **zero hits**. All three locations now agree. The round-2 headline defect is genuinely closed. |
| 2 | Soften or substantiate the §21.2 reconciliation claim | **Done, substantively, with one residual.** `:395` no longer asserts "No §21 norm is added, weakened, or reinterpreted." It now reads: "declared as the **third conformance clarification in the RAF-1 series** (after §21's own two)… This is a **declared substitution, not a claimed equivalence** — §21.2's literal text contemplates organic execution, which a healthy run cannot provide for rollback/breaker/recovery paths… ALGORITHM §21 itself is unchanged; all PR-1..PR-9 preserved; if the canonical protocol later incorporates explicit fire-test segments, the substitution becomes literal and this clause reduces to a restatement." This is honest at the sentence level and correctly stops claiming equivalence. **Residual, examined in depth below (Design faithfulness / Consistency / Calibration / adversarial pass):** the "third clarification… after §21's own two" framing invites a direct comparison to `ALGORITHM-v0.2-pathway-learner.md:651`'s own preamble, which is itself gated, approved text stating **"two declared conformance clarifications"** as a closed, per-property-attributed list (naming PR-7 and PR-5 by number). DATA-LAYER's declaration of a third is not reflected back into that text, and the blanket "all PR-1..PR-9 preserved" line does not follow §21's own preamble convention of naming *which* PR(s) the clarification touches (§21.2's audit rule is a maintaining mechanism of **PR-4** specifically, via the named "recovery predicate," `ALGORITHM-v0.2-pathway-learner.md:662`) — see below. |
| 3 (non-blocking, r2) | Non-blocking items: cursor shape for remaining 7 predicates, manifest-field redaction test coverage, PR-5(i) spot-check disclosure | **Spot-check disclosure: done.** `:385` now states plainly: "the cost is stated plainly: without that logging, a silently-skipped spot-check before the spec's one declared-irreversible operation is trace-indistinguishable from unwired logging, permanently once §10's retention horizon passes — a spot-check event kind is a candidate ALGORITHM-side delta, out of this section's scope." This directly absorbs round 2's adversarial objection into the artifact itself, following the same disclosure pattern already used for PR-8(iii) (guard territory) and PR-9 (missing window). **Cursor shape and manifest-test-coverage: unchanged, still open** (out of this round's requested scope; carried forward again). |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 76 | weak |
| 3 | Red-team resistance (CRITICAL) | 84 | pass |
| 4 | Implementability | 74 | weak |
| 5 | Safety / integrity (CRITICAL) | 86 | pass |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 76 | weak |
| 8 | Consistency | 74 | weak |
| 9 | Calibration / honesty | 78 | weak |

## Findings by dimension

### 1. Correctness

Round 2's dominant defect (the three-way ArtifactStore-blob contradiction) is genuinely fixed and re-verified against all three locations (`:146`, `:369`, `:398`) plus a fresh grep confirming no residual `ArtifactStore blob` text anywhere in the file. Round 1's predicate-table checkability claims remain correctly downgraded (re-spot-checked: `:388` PR-8(iii) still correctly routes heartbeat-gap detection to guard territory; `:389` PR-9 still correctly flags the missing §5.3 window as out-of-scope).

One new, narrower item, not risen to a blocking factual error but worth flagging precisely: `DATA-LAYER.md:356`'s headline "**Property-impact statement (§21.3): PR-1–PR-9 all preserved**" is defensible only under a specific reading — that "preserved" refers to the §21.1 property **statements** themselves being textually untouched (trivially true, since this document cannot and does not edit `ALGORITHM-v0.2-pathway-learner.md`). It is not defensible as "the standard by which conformance is judged is unchanged" — `:395`'s own words concede a "declared substitution, not a claimed equivalence" for the live-path-reachability evidentiary standard, for exactly the class of mechanism (recovery scan, among others) that `ALGORITHM-v0.2-pathway-learner.md:662` names as one of **PR-4**'s maintaining mechanisms. §21's own preamble (`:651`) does not use a blanket "preserved" for its own two clarifications — it names the specific PR each one touches ("PR-7 strengthened," "PR-5 made legible"). DATA-LAYER's Property-impact statement does not follow that same per-property precision for its own (arguably PR-4-touching) clarification. This is not a flat factual error — the trivial reading holds — but it is imprecise relative to the convention this document is explicitly invoking by calling itself "the third… in the RAF-1 series."

### 2. Design faithfulness

Placement, scheduling, and administrative-class treatment remain faithful (unchanged from prior rounds, re-verified).

The core round-1/round-2 faithfulness gap is **narrowed but not closed**: §12.3 (`:395`) now honestly names itself a "declared substitution," a real improvement over round 2's "no reinterpretation" overclaim. But the structural issue flagged in round 1 remains: `ALGORITHM-v0.2-pathway-learner.md:651` states, as part of its own **approved, gated** preamble text, "two declared conformance clarifications" — a closed, numbered, per-property-attributed list. DATA-LAYER §12.3 unilaterally extends that count to three from a sibling, still-`IN GATE` document, without any corresponding amendment (or even a flagged follow-up task) to `ALGORITHM-v0.2-pathway-learner.md`'s own text. §21.3's change-discipline (`ALGORITHM-v0.2-pathway-learner.md:678`) does explicitly authorize "adaptation[s] in a downstream implementation" to carry their own per-property impact line in their own submission — so this is not unambiguously out of process — but it does not by itself resolve the sync gap: the moment DATA-LAYER §12 clears its own gate, `ALGORITHM-v0.2-pathway-learner.md:651` becomes a stale count of its own accounting, silently, with nothing in this delta proposing or flagging the companion amendment. See the adversarial pass below for the sharpest form of this objection.

### 3. Red-team resistance

No RC-1..RC-8 mechanism is reintroduced or newly exposed by this round's changes (both fixes are prose/consistency corrections, not mechanism changes). The removal of the ArtifactStore-blob self-contradiction is a modest but real red-team improvement over round 2: a self-contradictory build instruction is exactly the kind of ambiguity an implementer under time pressure could resolve toward the cheaper, wrong path (skip the redaction-relevant manifest-storage discipline, or worse, wire an actual blob store nobody reviewed), reproducing the shipped-but-inert/half-built detector risk (`STUDY-automaton-autonomy.md` A2) this section exists to prevent. With the contradiction gone, that specific risk is closed.

### 4. Implementability

The `:398` fix removes round 2's reopened implementability blocker (two contradictory build instructions for the same mechanism) — a genuine, material improvement; an implementer reading any of `:146`, `:369`, or `:398` now gets the same answer (inline, no `ArtifactStore` method needed).

Unchanged from round 1/2, still open: `cursor: {predicate_id → opaque_state}`'s per-predicate continuation-state shape is stated for only 2 of 9 properties (`:372`: PR-4(ii) seq continuity, PR-5(iii) row monotonicity). The schema-level redaction rule (`:146`) constrains what `cursor` may *not* contain but still does not specify what it *does* contain for PR-1, PR-3, PR-6, PR-7, PR-8, or PR-9 — a developer still has to invent seven of nine incremental-state shapes from predicate prose. Also unchanged: `schemas.py`'s `Manifest`/`ManifestEntry`/`ConformanceReport` additions are still stated in prose (`:369`) rather than as a field-by-field dataclass listing, unlike §6.1's/§6.2's Port-delta convention.

### 5. Safety / integrity

No gate, calibration layer, or verifier is weakened; the checker remains report-only (§12.4, re-verified, unchanged). The cursor-redaction mechanism closed in round 2 (`:146`'s schema-level rule) is untouched and re-verified sound this round. Residual, unchanged and still low-risk-not-demonstrated: `test_report_redacted` (`:410`) is textually scoped to "report field"/"any report field," not explicitly extended to `conformance_manifest`'s fields, though the manifest's declarative shape (mechanism/§-anchor/record-kinds/class/evidences — `:398`) continues to make this a low-probability gap rather than a demonstrated one.

### 6. Efficiency / cost

Unaffected by this round's changes. PR-1(ii)'s complexity bound (`:370`) remains stated and correct; cold/maintenance scheduling remains correctly scoped; PR-7's expensive double-replay remains `full`-scope-gated (`:369,387`).

### 7. Completeness

The PR-5(i) spot-check cost disclosure (`:385`) is a genuine completeness gain — round 2's adversarial-pass-only finding (the permanently-unauditable-hole-on-the-sole-irreversible-operation risk) is now stated in the artifact itself, not merely surfaced by review, matching the document's own established pattern of naming known gaps rather than leaving them implicit (PR-8(iii), PR-9). The underlying gap is not closed — it can't be, within this delta's stated scope — but disclosure of a known, out-of-scope gap is exactly the discipline this section's own culture calls for, and it is now followed consistently across all three cases (PR-5(i), PR-8(iii), PR-9).

Unchanged residuals: the cursor-shape gap (7 of 9 predicates unspecified — see Implementability) and the manifest-field redaction test-coverage asymmetry (see Safety) remain open, carried forward again without a stated reason they're deferred.

### 8. Consistency

The round's dominant fix: the three-location ArtifactStore-blob contradiction (`:146` vs `:369` vs `:398`) — round 2's headline new defect — is fully resolved; all three locations now agree, re-verified by direct comparison and by a full-file grep.

One residual internal-consistency question, softer than round 2's flat contradiction but real: `:356`'s blanket "PR-1–PR-9 all preserved" and `:395`'s own "declared substitution, not a claimed equivalence" sit in tension within the same section (see Correctness). Both can be simultaneously true only under the narrower reading of "preserved" (the property *statements* are textually untouched), which the text does not itself draw out for the reader — unlike, e.g., §21.3's own careful PR-5 language (`ALGORITHM-v0.2-pathway-learner.md:681`, "PR-5 does **not** claim §9 Stage-2 is reversible… The property's content is narrower and true") that explicitly forecloses the broader misreading of one of its own claims. DATA-LAYER §12 does not perform the equivalent move for its own "preserved" claim.

A second, external consistency point (new to this round, prompted by the round's own framing choice): declaring itself "the third conformance clarification in the RAF-1 series (after §21's own two)" makes an explicit numeric claim about `ALGORITHM-v0.2-pathway-learner.md:651`'s own accounting that `:651`'s text — approved, gated, and untouched by this delta — does not itself reflect. This is not a contradiction *within* DATA-LAYER.md, but it is a citable inconsistency *between* two co-dependent, individually-gated artifacts the moment both are read together, which is exactly the kind of cross-document drift this project's own gate discipline (§21.3, `ALGORITHM-v0.2-pathway-learner.md:678`) exists to prevent.

### 9. Calibration / honesty

Real, demonstrated improvement on both fronts this round: the §21.2 reconciliation moved from an overclaim ("no reinterpretation") to an honest, hedged concession ("declared substitution, not a claimed equivalence," with an explicit condition for when it stops being a substitution at all — `:395`'s closing sentence). The PR-5(i) spot-check disclosure (`:385`) is calibration at its best for this document: naming a cost plainly rather than letting a reviewer find it.

The residual is the same tension noted under Correctness/Consistency: the section's headline compliance claim ("PR-1–PR-9 all preserved," `:356`) is broader than what the section's own body text (`:395`) supports without the reader supplying a distinction ("property preserved" vs. "audit-standard substituted") the text itself does not draw. For a document whose entire founding discipline is "a predicate's existence is not the property's truth" (`:377`, quoting the S21 lesson) and whose sibling section (`ALGORITHM-v0.2-pathway-learner.md:681`) models exactly the narrower, more honest phrasing this situation calls for, this is a real, fixable calibration gap — smaller than round 1's four overclaimed predicates or round 2's "no reinterpretation" line, but not yet fully closed.

## Strongest adversarial objection

**Once this delta clears its own gate, `ALGORITHM-v0.2-pathway-learner.md`'s own approved §21 preamble becomes stale, silently, with no mechanism in this delta to catch it.** `ALGORITHM-v0.2-pathway-learner.md:651` is gated, approved text (▣ 83/100) that states, as part of its own normative content: "**with two declared conformance clarifications**," naming each by number (PR-7, PR-5). DATA-LAYER §12.3 (`:395`) now declares a **third** — honestly hedged, well-argued, and explicitly aware it's extending a count that "belongs" to §21 ("after §21's own two") — but the mechanism for that declaration to become *true of §21 itself* does not exist anywhere in this delta. §21.3's own change-discipline (`ALGORITHM-v0.2-pathway-learner.md:678`) requires that changes to what §21 declares about itself go through "the same L-010 gate (review-360 → change-approver) that admitted it" for *removing or weakening a property*; it is genuinely ambiguous whether *adding a third declared clarification to a count §21 states about itself* is bound by that same rule, or is fully covered by the separate "adaptation in a downstream implementation… includes in its submission a per-property line" allowance one paragraph earlier in the same subsection. This delta does not resolve that ambiguity — it exploits the more permissive reading without acknowledging the more restrictive one exists, and ships no follow-up task, flag, or even a comment noting that `ALGORITHM-v0.2-pathway-learner.md:651` will read "two" forever unless someone remembers to change it. This is the same failure class round 2 caught and this round fixed *within* DATA-LAYER.md (three locations disagreeing about the same fact) — except this instance spans two independently-gated documents, one of which (`ALGORITHM-v0.2-pathway-learner.md`) is explicitly off-limits to review-360 and to this delta's own authors to edit, which is precisely why it is the kind of gap that survives review after review until a reader opens both files side by side, exactly as this round's task brief asked. No dimension finding above states this specific cross-document staleness-at-approval-time mechanism as sharply as this.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(85, 84, 86) = 84
weighted_mean   = (85*2 + 76 + 84*2 + 74 + 86*2 + 88 + 76 + 74 + 78) / 11
                = (170 + 76 + 168 + 74 + 172 + 88 + 76 + 74 + 78) / 11
                = 976 / 11
                = 88.73
overall         = min(84, 88.73) = 84
```

**Overall confidence: 84 / 100**

## Verdict

**ready-for-approval**

Both of round 2's blocking findings are verified genuinely fixed: the ArtifactStore-blob three-location self-contradiction (round 2's headline defect) is fully resolved, and the §21.2 reconciliation no longer overclaims non-reinterpretation. The round's own targeted addition (PR-5(i)'s cost disclosure) is a real, unprompted-by-this-review completeness/calibration gain. Score rises from 74 to 84, clearing the ≥80 bar with all three CRITICAL dimensions (Correctness 85, Red-team resistance 84, Safety 86) above the 70 floor.

This verdict carries forward a cluster of residuals that did not block this gate but are strong candidates for advisory tracking at approval, per this project's established precedent (DL-observability-roles, DL-write-discipline) of approving at ≥80 while carrying non-blocking findings forward:

1. **The cross-document accounting gap is the most consequential residual.** `ALGORITHM-v0.2-pathway-learner.md:651` states "two declared conformance clarifications"; `DATA-LAYER.md:395` declares itself a third. Recommend change-approver either (a) require a companion, separately-gated amendment to `ALGORITHM-v0.2-pathway-learner.md:651`'s count before or alongside this approval, or (b) explicitly rule, as part of the approval record, that §21.3's downstream-submission allowance covers this case and the count at `:651` is intentionally not amended — so the decision, not just the delta, carries the reasoning.
2. **Tighten `:356`'s blanket "PR-1–PR-9 all preserved"** to either name the specific PR(s) touched by the live-path-reachability substitution (mirroring `ALGORITHM-v0.2-pathway-learner.md:651`'s own per-property convention) as "modified-with-argument," or add one sentence distinguishing "property statement preserved" from "audit-standard substituted for conditional mechanisms," matching the precision `ALGORITHM-v0.2-pathway-learner.md:681` models for the analogous PR-5 case.
3. Non-blocking, carried again from rounds 1–2: specify the per-predicate `cursor.opaque_state` shape for the remaining seven predicates (only PR-4(ii)/PR-5(iii) stated); extend `test_report_redacted`'s stated scope (or add a twin test) to explicitly cover `conformance_manifest` fields; add a field-by-field `schemas.py` listing for `Manifest`/`ManifestEntry`/`ConformanceReport` matching §6.1's/§6.2's Port-delta convention.
