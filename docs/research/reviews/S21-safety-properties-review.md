# 360 Review: S21-safety-properties — 2026-08-13

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §21 "Safety properties — what is always true" (lines 649–684, uncommitted working-tree addition) |
| Proposed change | Add an additive naming layer — nine always-true properties (PR-1..PR-9) with maintaining mechanisms and guard tests, a conformance definition, a self-declared event-indexed-decay conformance clarification (the one non-"preserved" property-impact exception), a change-discipline subsection making property-impact statements mandatory via the existing L-010 flow, and an RC→PR map — at the end of §1–§20, with no other mechanism changes. |
| Reviewer | review-360 |
| Date | 2026-08-13 |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 35 | blocking |
| 2 | Design faithfulness | 65 | weak |
| 3 | Red-team resistance (CRITICAL) | 65 | weak |
| 4 | Implementability | 70 | weak |
| 5 | Safety / integrity (CRITICAL) | 60 | weak |
| 6 | Efficiency / cost | 95 | pass |
| 7 | Completeness | 65 | weak |
| 8 | Consistency | 40 | blocking |
| 9 | Calibration / honesty | 55 | weak |

## Findings by dimension

### 1. Correctness

**Blocking finding — PR-5 ("Reversibility") is false as stated against the approved text of §9.**

- §21.1, PR-5 (`ALGORITHM-v0.2-pathway-learner.md:663`) states: *"Every growth or promotion operation has an inverse reachable without data loss,"* maintained by *"§5.1 merge/prune/edge-decay · §9/§17.3 staged promotion with retained fallback · §17.6 reactivation-not-deletion, rows permanent."*
- §9's own code block explicitly contradicts this for the weight axis: `merge_to_base(adapter)  # STAGE 2: irreversible, fully gated` (`ALGORITHM-v0.2-pathway-learner.md:254`), and the prose immediately below it: *"a reversible adapter earns its way to an **irreversible base merge** — converts v0.1's one-way ratchet into a gated, **mostly-reversible** path"* (`ALGORITHM-v0.2-pathway-learner.md:256`, emphasis added). "Mostly-reversible" is §9's own admission that the path is *not* fully reversible — the opposite of PR-5's blanket "every… operation has an inverse … without data loss."
- The "Maintained by" column further conflates two different mechanisms: only §17.3 (code axis) actually retains a fallback — *"the frozen last-good SOLVE is retained"* (`ALGORITHM-v0.2-pathway-learner.md:465`), and that same line says explicitly *"the reversibility §9 gets from a detachable adapter, provided here by the retained fallback"* — i.e. §9's reversibility exists only during **Stage 1** (the detachable LoRA adapter), not after Stage 2's base merge. §21.1 cites "§9/§17.3 … with retained fallback" as if both stages of both axes have a retained fallback; they do not.
- Checkpoint-level rewind (§10) can revert *all* state to before the merge, but that discards every commit made after the merge too — which is precisely "data loss" under PR-5's own qualifier ("without data loss"), not an inverse of *that specific operation*.
- None of PR-5's three guard tests (`test_reactivate_restores_bytes`, `test_merge_report_shows_inverses`, `test_derive_orphan_pruned` — all §17.6/§5.1/graph-layer tests) actually exercises §9's weight-axis Stage-2 merge. The property is stated as universal, cites §9 as a maintaining mechanism, but has zero guard coverage of the one place where the approved text itself names an exception. This is exactly the "guard-vs-universal gap" the reviewing brief asked to be probed for (adversarial angle #2), and it co-occurs with a literal false-as-stated violation (adversarial angle #1).
- Downstream, §21.4's RC map (`ALGORITHM-v0.2-pathway-learner.md:683`) repeats the same error: `RC-8 → PR-5`. RC-8's own v0.2 patch (§0's table, `ALGORITHM-v0.2-pathway-learner.md:24`) is described as "two-stage **reversible** promotion" but §9 itself only claims Stage 1 is reversible — so the RC-8→PR-5 map entry inherits and compounds the same overclaim rather than correcting it.

This is a single, precisely-locatable, blocking-caliber defect per the rubric's own standard ("A single sign error or wrong bound is a blocking flaw"): a document whose sole purpose is to state what is *always* true asserts a universal claim that the spec's own approved text (§9) explicitly negates for one of the two cases the claim is supposed to cover (weight-axis promotion).

Secondary, non-blocking correctness note: two entries in the §21.4 RC map are weak fits under scrutiny — `RC-1 → … PR-4` and `RC-5 → PR-4` (`ALGORITHM-v0.2-pathway-learner.md:683`). PR-4 ("Evidence Identity") is about occurrence-hashing/dedup (§20.2, DATA-LAYER §6.1); RC-1's fix is statistical-significance testing (§2) and RC-5's fix is decoupled dual-posterior decay with an `n_min` floor (§3) — neither is primarily about occurrence identity. These aren't false, but they read as map entries constructed to satisfy "no silent gaps" (§21.4's closing claim) rather than as the tightest available fit — worth tightening in revision, not blocking on their own.

### 2. Design faithfulness

The section's macro-structure is faithful to the established additive pattern (§13–§20): "no §1–N mechanism changes," a single declared exception with its own property-impact statement, new-parameter/new-check bookkeeping extending §12, and citation discipline back to P1/P2. The conformance definition (§21.2) and the honestly-declared non-property (epoch coherence, §21.3) both mirror the spec's existing self-critical style (e.g. §17.6's "residual honesty, two-fold" at line 507-508). However, PR-5's misdescription of §9 (see §1 above) is itself a faithfulness defect — the safety-properties layer is supposed to *restate* what §1–§20 already establish, and on this one property it restates something §9 does not actually establish. Score reflects a structurally sound pattern let down by inaccurate restatement of the very artifact it claims to summarize.

### 3. Red-team resistance

No root cause is reintroduced at the mechanism level — §21 changes no code path, and the one declared exception (event-indexed decay, §21.2) *strengthens* PR-7 rather than weakening anything. §0's meta-principle (`ALGORITHM-v0.1-redteam.md:25`, "the system optimizes its own scoreboard… make the measurement independent of the optimization") is not violated by §21's mechanics.

But the PR-5 defect (§1 above) is a red-team-relevant regression at the *documentation* level specifically against **RC-8** (`ALGORITHM-v0.1-redteam.md:67-69`, "promotion mis-fire… bakes the most-frequently-used skill irreversibly into weights"). RC-8's whole lesson was that irreversibility of promotion is the danger; §9 already only *partially* closes it (Stage 1 reversible, Stage 2 not). A safety-properties document that certifies "every promotion has an inverse… without data loss" is precisely the kind of false assurance that could cause a future implementer or automated agent to build tooling (e.g. an "auto-revert any bad promotion" feature) on an incorrect premise — reopening RC-8's actual risk (irreversible weight contamination) while believing it is covered. This does not reach "reopens a known failure mode" at the mechanism level (score 0 per the rubric), because no gate or code path changed; it does represent meaningful residual attack surface at the epistemic/documentation layer, which is what this section exists to close.

### 4. Implementability

The conformance procedure (§21.2 — live-path-reachability evidenced by truth records of the canonical protocol run) is concrete and mechanically checkable, and the guard-test figure is largely accurate (all cited test names were confirmed present in their owning artifacts — see verification below). Two implementability gaps:

- **No guard exists for the specific case where PR-5 is questionable** (§9 Stage-2, see §1) — a developer trying to "implement conformance to PR-5" has nothing to run against the one place the property actually needs scrutiny.
- **§21.3's enforcement claim is not concretely wired.** *"Enforcement lives in the existing L-010 gate: `review-360` treats a missing statement as a blocking finding"* (`ALGORITHM-v0.2-pathway-learner.md:677`) describes a behavior that exists nowhere else in the repo yet: `review-360`'s own agent definition (`.claude/agents/review-360.md`) has no property-impact-statement check in its nine fixed dimensions, and `skills/spec-change-gate/SKILL.md` — the operational playbook that concretizes L-010, including its "pre-submission authoring checklist" (lines 65-99) — does not mention property-impact statements at all. The claim happens to be *self-fulfilling in this very review*, because review-360's own protocol reads the full algorithm doc (including §21) as a supporting document before reviewing any future gated change — but that is an emergent side-effect of an existing read-first step, not a wired enforcement mechanism, and nothing requires a future reviewer to notice or apply it. A concrete fix (adding the check to `skills/spec-change-gate/SKILL.md`'s pre-submission checklist, or filing a task to update `review-360.md` via `agent-smith`) would close this; as written the "enforcement" is aspirational text asserting a fact about another agent's behavior that the artifact does not itself have write-access to establish.

### 5. Safety / integrity

§21 does not weaken §8's commit gate, §14's calibration layer, §19's self-calibrating gate, or the verifier — every cited mechanism is quoted, not altered, and the one normative addition (event-indexed decay, §21.2) tightens the replay-determinism guarantee (PR-7) rather than loosening anything. On that narrow test ("does the change weaken any gate/calibration/verifier/integrity constraint") the section passes.

The score is pulled down by the same PR-5 issue treated as a *safety-integrity* concern rather than a pure math error: this section is explicitly positioned (preamble, `ALGORITHM-v0.2-pathway-learner.md:651`) as the artifact that lets future modifications and reviews reason about safety *by name*, the way KIP-595/CockroachDB defend deviations against Raft's named properties. A false "always true" claim inside exactly that artifact is a first-order integrity defect for its stated purpose — the harm model is not "a gate got weaker today" but "a future gated change cites PR-5 as license to treat a weight-axis promotion as freely revertible." Below the CRITICAL pass bar (70) on that basis.

### 6. Efficiency / cost

Purely additive documentation/naming layer — no new runtime mechanism, no new LLM call, no algorithmic complexity change. `§12`'s "no new parameters (no §12 delta)" claim (line 651) is verified true by inspection: nothing in §21 introduces a tunable that would need registration. No concerns.

### 7. Completeness

The figure covers all nine PR-numbers with mechanism + guard columns, and §21.3's edge cases (the ~10-property cap with a consolidation rule, the change-discipline supersession rule, the epoch-coherence non-property) are handled. Gaps:

- No guard test targets §9 Stage-2 specifically for PR-5 (see §1/§4).
- The RC→PR map's "no silent gaps" claim (line 683) is technically true (every RC has *an* entry) but two entries (`RC-1`, `RC-5` → `PR-4`) are weak fits and one (`RC-8` → `PR-5`) is actively wrong given §1's finding — completeness of *coverage* is fine, completeness of *correct* coverage is not.
- No test strategy is proposed for validating the conformance procedure itself (e.g., a check that the "live-path-reachability" inspection was actually run against `M1-EVAL-PROTOCOL.md`'s current version, versus a stale one) — minor, since RAF-1b is explicitly deferred.

### 8. Consistency

The central issue: **PR-5 (§21.1, line 663) is directly inconsistent with §9's own text (lines 254, 256)** — a contradiction between a newly-added section and previously-approved, unmodified content in the same file. This is the most serious kind of consistency failure a review of an *additive* change can find, because §21's entire premise (preamble, line 651) is "no mechanism changes; it names what §1–§20 already maintain" — and on PR-5 it names something §1–§20 do not maintain. Everything else checked (DATA-LAYER §5/§6.1/§6.2 citations for PR-1, PR-4, PR-6, PR-7, PR-8; §5.1/§5.3/§18.2/§20.4/§16.7 citations for PR-9; §17.1/§18.5/§20.8 for PR-2) matches the cited source text closely and accurately.

### 9. Calibration / honesty

Genuine strengths: §21.2 deliberately uses "conformant," not "proved," and states why ("passing every guard cannot prove a universally-quantified statement"); §21.3 names an honest non-property (epoch coherence) rather than inflating the list to claim it; the preamble's property-impact statement for §21's own decay-clause exception (PR-7 strengthened, others "preserved (untouched)") follows the very discipline §21.3 asks of future changes. This is real epistemic care and should be credited.

It is undercut by the PR-5 overclaim (§1): the submission context states *"every guard test name cited in the figure was grep-verified present in its owning artifact before submission."* That verification method — confirming a test *name* exists somewhere — is necessary but not sufficient to substantiate a universally-quantified safety claim, and this review demonstrates the gap concretely: all cited guard names for PR-5 do exist, yet none of them establishes the property, and the property is false as stated. A calibration-conscious submission should distinguish "guard name exists" from "guard name actually falsifies this property," and on PR-5 it did not. The self-referential §21.3 enforcement claim (§4/§5 above) is a second, milder honesty gap — stating as established fact a review behavior that is not yet wired anywhere.

## Strongest adversarial objection

**PR-5 is not merely underspecified — it is affirmatively contradicted by the section of the spec it claims to summarize, and the contradiction sits exactly on RC-8, the root cause the property is supposed to have closed.** §9's own inline comment calls Stage 2 "irreversible" and its own prose calls the result "mostly-reversible," yet PR-5 asserts, in a document titled "what is always true," that *every* promotion has an inverse *without data loss*. A hostile reader does not need to construct an edge case or a novel attack surface to break this claim — they only need to read the section two clicks upstream in the same file. That the pre-submission process (grep-verification of guard-test *names*, a cold-read explain-it-back that produced ten *ambiguity* findings) did not catch a flat *contradiction* is itself informative: the process checked legibility and cross-reference presence, but not truth-value against the cited source. This is the one objection not already surfaced as a "finding" above in the sense of being new — it is, however, the same underlying fact restated as the adversarial framing the brief asked for: is any property FALSE as stated against §1–§20? Yes, and it is the property (Reversibility) most load-bearing for exactly the failure mode (irreversible promotion) this whole section exists to keep in view.

## Aggregate confidence

```
critical_floor  = min(Correctness, RedTeam, Safety) = min(35, 65, 60) = 35
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                   + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (35*2 + 65 + 65*2 + 70 + 60*2 + 95 + 65 + 40 + 55) / 11
                = (70 + 65 + 130 + 70 + 120 + 95 + 65 + 40 + 55) / 11
                = 710 / 11
                = 64.5 → 65
overall         = min(35, 65) = 35
```

**Overall confidence: 35 / 100**

## Verdict

**needs-revision**

Blocking changes required to clear 80 (and to clear the CRITICAL floor of 70 on Correctness, Red-team resistance, and Safety):

1. **Fix PR-5's statement to match §9.** Either (a) narrow PR-5 to what is actually always true — e.g. "Every growth operation (§5.1) and every code-axis promotion (§17.3) has an inverse reachable without data loss; weight-axis Stage-2 base merges (§9) are the one exception, reversible only via full checkpoint rewind (which discards subsequent progress) — Stage 1's LoRA-adapter probation is the reversible half of that axis" — and add this as a second named exception in §21.3 alongside epoch coherence, with its own property-impact statement; or (b) if the intent is that this gap should be closed, that is a mechanism change out of scope for an additive section and must be filed as a separate proposal against §9, not asserted as already-true in §21.
2. **Correct the "Maintained by" column for PR-5** so it does not attribute "retained fallback" to §9 (only §17.3 has one); and correct the `RC-8 → PR-5` map entry in §21.4 to reflect the same narrowed claim.
3. **Add a guard test that actually exercises the §9 Stage-2 case** for whatever the corrected PR-5 claims (e.g. `test_stage2_merge_documented_as_irreversible` / `test_stage1_only_reversible_scope`), so the guard-vs-universal gap identified in this review does not recur silently.
4. **Make the §21.3 enforcement claim concrete**, not aspirational: add the property-impact-statement requirement to `skills/spec-change-gate/SKILL.md`'s pre-submission checklist (or file a task for `agent-smith` to extend `review-360.md`'s dimension rubric), rather than asserting the behavior is already enforced by a document neither of those artifacts currently reflects.
5. **Re-examine the `RC-1 → PR-4` and `RC-5 → PR-4` map entries** in §21.4 for tighter fit, or add one sentence justifying the indirect connection (e.g. via the `significant()` primitive / fresh-evidence requirement) so the map reads as reasoned rather than coverage-complete-by-construction.

None of these require touching §1–§20's mechanisms; all are corrections/additions within §21 itself, consistent with the section's own additive scope.
