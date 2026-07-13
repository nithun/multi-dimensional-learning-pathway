# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 7)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–511), marked "added 2026-07-13, revised r7" |
| Proposed change | Round-7 rewrite closing round 6's three open items: (1) `agent_id` is now a real column on `lineage` in `DATA-LAYER.md` §5 (not merely asserted), §17.6's own delta note (`:501`) lists it as the fourth shipped artifact alongside `scaffold_versions`/`selfmod_rejected`/`component_invoked`, and the `CAPTURE` bullet (`:507`) attributes the delta to *this* section rather than misattributing it to §18.1; (2) `test_capture_cross_agent_prohibited` is added to the Checks list (`:510`); (3) the reactivation mechanism (`:508`) is now explicitly cross-referenced to §7's RC-6 fix (discounted tree + invalidate-on-checkpoint-change) as its code-axis analog |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Rounds 1–6 item resolution audit (every numbered item, closed or explicitly deferred)

| # | Item (originating round) | Status this round | Evidence |
|---|---|---|---|
| 1 | `revalidation` in the formal schema block (R3) | **Still closed, unchanged** | `:498` — `revalidation ∈ {n/a, pending, passed, failed}` remains in the code block. |
| 2 | Quantify + register `κ_reval` (R3) | **Still closed, unchanged** | `:508` (`κ_reval = 0.5`); `:509` (registered, "extends §17.5"); `:286` (§12 list). Text unchanged from r4–r6. |
| 3 | `source_ref` self-contradiction: schema field vs. `CAPTURE` bullet (R4/R5) | **Still closed, unchanged** | `:489–491` defers to the `CAPTURE` bullet; `:507` states the ancestry predicate once. |
| 4 | Temporal soundness — ancestry vs. bare existence, single-agent case (R4→R5) | **Still closed, unchanged** | `:507` unedited on this clause; re-verified sound against §3/§8's RC-5 rollback mechanism. |
| 5 | `snapshot`/`snapshot_ref` naming/content-vs-reference mismatch with DATA-LAYER (R4) | **Still closed, unchanged** | `:492–493` matches `DATA-LAYER.md:138`'s `snapshot_ref` field exactly. |
| 6 | Register `scaffold_versions` + `selfmod_rejected` (+ `component_invoked`) as one DATA-LAYER §5 delta (R3/R4) | **Still closed, unchanged** | `DATA-LAYER.md:138` — all three, field-for-field matching `:485–499`. |
| 7 | Name the §6-orchestrator plug-point for per-component invocation logging (R3, closed R5) | **Still closed, unchanged** | `:506` — `component_invoked{component_id, episode_id, ts}`, unchanged. |
| 8 | (R2/R3 legacy) `τ_sm`/`w_prune` §12 registration, invocation-based prune well-definedness, `selfmod_rejected` flood bound | **Still closed, unchanged** | `:286`, `:503`, `:506` unedited, no regression. |
| 9 | Reactivation mechanism never cross-referenced to §7's RC-6 fix (R2 DF-4 → R3 → R4 → R5 → R6, unaddressed 4 rounds) | **Now closed** | `:508` — "(This is the code-axis analog of §7's RC-6 fix — discounted tree stats + invalidate-on-checkpoint-change: a restored artifact is never trusted against a moved world without fresh evidence.)" Verified against `ALGORITHM-v0.2-pathway-learner.md:213–214` (§7's actual discounted-UCT + `invalidate(node)` text) — the analogy is accurate, not decorative: both mechanisms refuse to trust a stale artifact (tree value / reactivated fallback) against a world that has moved, without first collecting fresh evidence. |
| 10 | Fleet-scoping enforcement-mechanism claim — round 6's central defect: `:507` asserted `lineage` "carries the `agent_id` key exactly as `StateStore` does," false against `DATA-LAYER.md:138`/`:139` as they stood in round 6, and self-contradicted by round 6's own `:501` delta note | **Now closed — the claim is made true, not merely restated more carefully** | `DATA-LAYER.md:138` — `lineage(checkpoint_id, parent, dataset_id, eval_run_id, agent_id)` now genuinely has the column, annotated `(agent_id = the fleet key, mirroring §18.1's per-agent StateStore keying; single-agent default is a constant — delta gated under ALGORITHM §17.6)`. `:501` now reads "four artifacts... the `scaffold_versions` table, the `selfmod_rejected` + `component_invoked` event kinds, and an `agent_id` column on `lineage`" — matching `:507`'s claim exactly, closing round 6's Cs-1/Cs-2 intra-section and cross-file contradictions. `:507` itself no longer says "exactly as `StateStore` does" (round 6's false comparator, since `StateStore`'s own `cell{...}` schema at `DATA-LAYER.md:139` still lacks `agent_id` — see Correctness C-2) — it now reads "part of THIS section's DATA-LAYER delta, above; the same per-agent keying pattern §18.1 gives `StateStore`," correctly attributing the shipped delta to §17.6 itself and treating the §18.1 comparison as a design-pattern analogy, not a claim that `StateStore`'s field already exists. This is the genuine, no-longer-false version of round 6's fix. |
| 11 | Auditability half of RT-2/Co-2 (round 6): no test asserted the cross-agent `CAPTURE` prohibition | **Now closed** | `:510` — `test_capture_cross_agent_prohibited` (a `source_ref` naming another agent's checkpoint is refused at admission — the walk filters by the proposer's `agent_id`) is added to the Checks list, matching every other safety-relevant claim in this section with a named test. |
| 12 | Retention/GC interaction (round 5, closed round 6) | **Still closed, unchanged** | `:507` — "§10's checkpoint retention/GC prunes checkpoint *blobs* only — lineage *rows*... are permanent" — unchanged, still sound against `DATA-LAYER.md:87`'s `ArtifactStore.gc` / `TruthStore`'s absence of a prune method. |
| 13 | **NEW this round** — the `lineage.agent_id` column now exists and is filtered on by the `CAPTURE` walk, but no text in §17.6, §6, or §8 specifies *who writes it and when* for the ordinary (non-`CAPTURE`) commit path | **Open — see Correctness C-1, adversarial pass** | §6's main-loop pseudocode (`:200–206`) and §8's `commit_gate` (`:222–227`) are both stated to be unchanged by §17.6 (`:481`, "no change to... any §1–§16 mechanism") and neither mentions `agent_id`. The schema's *read* side (the ancestry walk filters by `agent_id`) is fully specified; the *write* side (which component populates `lineage.agent_id` on an ordinary commit, and from what source) is not. |

All three items round 6 flagged as blocking are now genuinely closed, in the harder sense the earlier reports asked for (a real edit landing in `DATA-LAYER.md` in the same round, not a narrative claim about one). No previously-closed item is reopened. One new, narrower gap (item 13) is surfaced by this round's own fresh audit rather than by the previous round's cover note.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 92 | pass |
| 3 | Red-team resistance (CRITICAL) | 84 | pass |
| 4 | Implementability | 84 | pass |
| 5 | Safety / integrity (CRITICAL) | 84 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 84 | pass |
| 8 | Consistency | 90 | pass |
| 9 | Calibration / honesty | 86 | pass |

## Findings by dimension

### 1. Correctness

**Score: 88 — pass**

**C-1. NEW, the round's one open item: `lineage.agent_id`'s write-side population is unspecified.** `DATA-LAYER.md:138` now genuinely has the column, and `:507`'s ancestry walk correctly specifies filtering *by* it — but nothing in §6's main-loop pseudocode (`ALGORITHM-v0.2-pathway-learner.md:191–206`) or §8's `commit_gate` (`:222–227`), both explicitly stated unchanged by this section (`:481`), shows where an ordinary `FIX`/`DERIVE`/`CAPTURE` commit's lineage-append call is given the committing agent's `agent_id`. This is not a logic error in what *is* specified — the ancestry walk, as described, is sound whether or not this gap is closed, because a single agent's parent-chain is self-contained by construction (§18.1's B3 zero-trust transfer re-validates and re-commits on the *receiver's* own chain, never by importing another agent's checkpoint node directly) — but it is a genuine specification gap: a developer cannot today point to the exact line of pseudocode that sets this field. Scored as a real, non-blocking correctness gap rather than a broken mechanism, since the property the column exists to enforce is very plausibly true "for free" by construction even absent an explicit population instruction.

**C-2. Verified: `:507`'s revised claim no longer over-reaches into `StateStore`'s territory.** `DATA-LAYER.md:139`'s `cell{skill, difficulty, context, mastery:{α,β}, drift:{α,β}, n_eff, updated_ts, checkpoint_id}` still has no `agent_id` field (§18.1's own `agent_id` claim, `:521`, remains unshipped there — `IMPLEMENTATION-v2.md:243` still correctly describes it in planned tense, "`Cell` **gains** an `agent_id` key"). `:507` no longer claims otherwise: it says the lineage delta "mirrors" and follows "the same per-agent keying pattern §18.1 **gives** `StateStore`" — a claim about §18.1's stated *design intent* (true — §18.1's text does describe this keying scheme) rather than about `StateStore`'s *current shipped schema* (which is still pending). This is the precise fix that closes round 6's C-2/Cs-1/Cs-2/Ca-1 without merely relocating the same defect.

**C-3. Round 5/6's ancestry-vs-existence fix (C-1 in r5/r6) remains sound and unchanged.** Re-verified against §3 (`:57–58`) and §8 (`:229`) — no regression.

**C-4. Retention/GC argument (closed r6) remains sound, unchanged.** Re-verified against `DATA-LAYER.md:87`'s `ArtifactStore.gc` and `TruthStore`'s absence of any prune method (`DATA-LAYER.md:149`).

**C-5. `κ_reval` arithmetic remains correct, unchanged from rounds 4–6.**
```
python3 -c "z=2.0; se=1.0; print('normal trip:', z*se, ' tightened trip:', 0.5*z*se)"
→ normal trip: 2.0  tightened trip: 1.0
```

**Summary:** the round's central defect (the false schema-mechanism citation) is now genuinely fixed rather than relocated — the field exists, the claim about it is now scoped correctly, and the §18.1 comparison is now an honest design-pattern analogy rather than a false present-tense equivalence. The only residual is a new, narrower, non-blocking write-path specification gap.

---

### 2. Design faithfulness

**Score: 92 — pass**

**DF-1. Closed: the §7 RC-6 cross-reference (open 4 consecutive rounds, R2→R6) is now present and accurate.** `:508`'s parenthetical, verified against `:213–214`'s actual text (discounted UCT + `invalidate(node)` on the affected subtree), correctly identifies the shared design principle: neither mechanism trusts a stale/restored artifact against a moved world without fresh evidence. This is a real fix, not a bare citation — the comparison holds up on inspection.

**DF-2. Closed: the tension flagged in round 6 (this section held to a stricter "ship the actual schema line" bar than §18.1's own narrative-only precedent) is resolved by this round actually shipping the `DATA-LAYER.md` edit.** §17.6 now meets its own established, stricter bar for a fourth artifact in a row (`scaffold_versions`, `selfmod_rejected`, `component_invoked`, now `lineage.agent_id`), rather than falling back to §18.1's looser, unshipped convention.

**DF-3. Retention argument remains a faithful, correctly-reasoned extension of §10's checkpoint/tree GC clause** — unchanged from round 6.

**DF-4. Attribution to OpenSpace (`:481`) is unchanged and remains accurate.**

---

### 3. Red-team resistance

**Score: 84 — pass**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8.

**RT-1. Round 5's RT-1 (single-agent ancestry closing the RC-2-adjacent "no capturing lucky runs" gap) remains closed, unchanged.**

**RT-2. Round 5/6's RT-2 (fleet-scale RC-6-adjacent residual — is the ancestry guarantee well-defined and auditable at fleet scale?) is now substantively closed.** Both halves round 6 left split — the *definition* (which chain to walk) and the *auditability* (a checkable enforcement artifact) — are now real: the `agent_id` column exists in the registered schema, and `test_capture_cross_agent_prohibited` (`:510`) gives the property a named, checkable test the way every other safety-relevant claim in this section already had. The residual is narrower and different in kind: the *test asserts rejection* of a cross-agent `source_ref`, but nothing tests or specifies that `lineage.agent_id` is *correctly populated* on ordinary commits in the first place (Correctness C-1) — if that population were ever wrong (e.g., left null, or copied from the wrong context), the rejection test could pass in isolation while the underlying property silently didn't hold in production. This is a real, if narrower, residual audit gap — not the same "claimed-but-absent" shape as rounds 1–6, but a new "specified-on-read, unspecified-on-write" shape.

**RT-3. Round 3's honestly-scoped RC-6 residual (reactivation narrows but does not close the stale-fallback window) remains open in the same, unchanged, honestly-labeled form.** No regression.

**RT-4. No previously-closed red-team item is reopened.** Wall invariant, capability isolation, dedup-in-JUDGE-admission-path, and `selfmod_rejected` flood bound are all unchanged and re-verified present.

**Summary:** the round closes both halves of round 6's central red-team item genuinely, but a new, narrower audit gap (write-path population of the enforcement column) keeps this CRITICAL dimension from clearing the high-80s this round's other gains would otherwise support.

---

### 4. Implementability

**Score: 84 — pass**

**I-1. Fleet-scoping is fully implementable as specified** — a developer can implement the ancestry walk today, parameterized on the proposing agent's own checkpoint and filtering `lineage` rows by `agent_id`, with a real schema column to point at (round 5/6's I-1/I-2 both close cleanly now).

**I-2. NEW, minor: the write-path gap (Correctness C-1) is a smaller, secondary implementation hazard here too** — a developer implementing the ordinary commit path (§6/§8, unchanged) has no explicit instruction for setting `lineage.agent_id`; the natural inference (the running agent instance's own identity) is very likely correct but is inference, not specification, for a field this section's own safety claim depends on.

**I-3. Retention fix remains implementable, unchanged from round 6.**

**I-4. Closed: the reactivation-mechanism / §7 cross-reference gap (DF-1) is fixed** — a developer building the rollback path can now reuse the discounted-UCT/invalidate pattern by name rather than reinventing an unnamed equivalent.

---

### 5. Safety / integrity

**Score: 84 — pass**

**S-1. No named gate, budget enforcer, or partition is weakened.** §17.1/§17.3/§17.5 text is unchanged; the `self_modify` budget enforcer remains JUDGE-owned (`:455`).

**S-2. The retention fix remains a genuine, verified safety improvement, unchanged.**

**S-3. The cross-agent `CAPTURE` prohibition is now backed by a real, checkable schema artifact and a named test, closing round 6's flagged gap (a stated safety property with no enforcement artifact behind it).** `:507`'s "prohibited outright" claim is no longer resting on an unverified citation — `lineage.agent_id` exists (`DATA-LAYER.md:138`) and `test_capture_cross_agent_prohibited` (`:510`) makes the *rejection* path checkable. The residual — the *population* path for `agent_id` at ordinary commit time is unspecified (Correctness C-1) — is a genuine, if narrower, safety-relevant gap: an unwritten or mis-written `agent_id` at commit time would silently defeat the very filter this round added to enforce the prohibition, and nothing in this section (or §6/§8, which are unchanged) currently guards against that failure mode with a test of its own.

**S-4. The single-agent `CAPTURE` safety improvement from round 5 remains fully intact, unchanged.**

---

### 6. Efficiency / cost

**Score: 78 — pass**

**E-1. The ancestor-chain walk remains a bounded, cold-path operation, unchanged.** Adding an `agent_id` filter to an already-bounded parent-chain walk is O(1) additional work per step — no complexity regression.

**E-2. Unchanged, still open: lineage rows are permanent (confirmed, round 6), so chain depth grows unboundedly over a long-running agent's lifetime** — no amortization/milestone-shortcut mechanism is offered for the walk's own performance as chains grow, beyond §10's general "tagged milestones" note for the rewind horizon. Not addressed this round, not new.

**E-3. `w_prune`'s soft eviction bound (unchanged since rounds 3–6) remains open** — no cap on live-component count.

---

### 7. Completeness

**Score: 84 — pass**

**Co-1. Resolved (carried): the retention/GC interaction with the ancestry walk.**

**Co-2. Now resolved: the fleet-scoping enforcement/audit gap.** A `test_capture_cross_agent_prohibited`-style stub (round 6's flagged absence) is now present at `:510`, matching every other safety-relevant claim in this section with a named test.

**Co-3. Resolved: the §7 RC-6 cross-reference, open 4 consecutive rounds, is now present** (`:508`).

**Co-4. Resolved: `:501`'s own delta note now lists all four artifacts, matching `:507`'s claim exactly** — no more intra-section mismatch between the section's own "what ships" note and its own body text.

**Co-5. NEW: no test asserts that `lineage.agent_id` is correctly populated on an ordinary (non-`CAPTURE`) commit** — the natural counterpart to `test_capture_cross_agent_prohibited` (which tests the *rejection* side) would be something like `test_lineage_row_tagged_with_committing_agent`, and it is absent. See Correctness C-1, Red-team RT-2.

**Co-6. NEW, minor: the "single-agent default is a constant" phrasing (`DATA-LAYER.md:138`) never states what the constant literal is** (e.g., a sentinel string, `None`, `0`) — a small, easily-closed spec gap, not blocking for a single-agent M1/M2 build but worth pinning down before §18/M3 needs a real migration path from "the constant" to genuine per-agent values.

**Co-7. Positive:** the test-stub list (`:510`) is otherwise complete and well-mapped to the section's other claims.

---

### 8. Consistency

**Score: 90 — pass**

**Cs-1. Resolved: round 6's flagship intra-section contradiction (`:501`'s delta note vs. `:507`'s claim) no longer exists.** Both now state the same four artifacts, checked by direct comparison of the two passages.

**Cs-2. Resolved: round 6's cross-file contradiction (`:507`'s claim vs. `DATA-LAYER.md`'s actual schema) no longer exists** — `DATA-LAYER.md:138` genuinely has the field now, verified by direct read of the current file, not by trusting the section's own narration.

**Cs-3. All of rounds 4–6's previously-resolved consistency fixes remain resolved, unchanged** — `source_ref`/`CAPTURE` bullet agreement, `snapshot_ref` naming, `revalidation`'s presence across the schema block/prose/§12/DATA-LAYER.

**Cs-4. Minor, pre-existing, out of §17.6's scope: §18.1's own claim (`:521`, "the schema delta") that `StateStore` gains an `agent_id` key is still not reflected in `DATA-LAYER.md:139`'s `cell{...}` schema.** This is not a regression introduced by, or a claim made by, this round's §17.6 text — `:507` no longer leans on it as if it were already true (Correctness C-2) — but it remains a genuine, adjacent inconsistency in the surrounding document that a future round of *§18.1*, not §17.6, should close. Noted for completeness, not scored against this section.

**Summary:** the round closes both of the section's own live consistency defects (intra-section and cross-file) cleanly, verified against the current text of `DATA-LAYER.md` directly rather than against the section's own narration of it — the first round in the section's seven-round history to do so without introducing a new instance of the "claimed-but-absent" pattern anywhere.

---

### 9. Calibration / honesty

**Score: 86 — pass**

**Ca-1. Resolved: round 6's overclaim ("the lineage rows carry the `agent_id` key exactly as `StateStore` does") is corrected to an honestly-scoped claim.** `:507` now says the delta "mirrors" / follows "the same per-agent keying pattern §18.1 **gives** `StateStore`" — read as a design-pattern analogy grounded in §18.1's stated intent, which is true, rather than a claim that `StateStore`'s own field currently exists, which would still be false. This is the correct fix (matching this document's own better practice elsewhere, e.g. `:508`'s "narrows... does not close").

**Ca-2. Genuine, accurate: the retention claim remains well-calibrated, unchanged from round 6.**

**Ca-3. The "Residual honesty, two-fold" language (`:507`, unchanged since round 5) remains accurate and appropriately hedged.**

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (`:481`)** — verified true, and now also true of the `commit_gate`/§6 pseudocode point (Correctness C-1): those really are unchanged, which is precisely *why* they don't yet show where `agent_id` gets populated.

**Ca-5. NEW, minor: the section does not flag its own new write-path gap (C-1/Co-5) as an open residual the way it does for the reactivation window ("narrows... does not close") or CAPTURE's two-fold honesty note.** A one-clause acknowledgment ("population of `lineage.agent_id` at ordinary commit is assumed via the running agent's own context; not itself tested here") would have matched this section's own established calibration discipline. Its absence is a missed opportunity for self-flagged honesty, not an active overclaim — scored as a small deduction, not a defect of the same class as rounds 2/4/6's flagship overclaims.

**Summary:** this is the first round in the section's history whose calibration issue is an omission (not flagging a residual gap) rather than a commission (asserting something false) — a meaningfully different, less severe failure mode than rounds 2, 4, and 6's flagship overclaims.

---

## Strongest adversarial objection

**The schema now has the enforcement column; the section still never says who writes it, and the section's own text explicitly disclaims responsibility for that exact code path.**

`:507`'s cross-agent prohibition depends entirely on `lineage.agent_id` being correctly and reliably populated with the *committing agent's own identity* at the moment any ordinary `FIX`/`DERIVE`/`CAPTURE` commit appends a lineage row. But `:481` states, in this section's own opening framing, "No change to... any §1–§16 mechanism" — and the concrete commit path that would populate this field, §6's main-loop pseudocode (`ALGORITHM-v0.2-pathway-learner.md:191–206`, specifically the `commit_gate(child, node)` call and whatever lineage-append call follows it) and §8's `commit_gate` itself (`:222–227`), are exactly the §1–§16 mechanisms this round explicitly declines to touch. So the round has, by its own admission, added a safety-relevant column to a table without touching the one code path responsible for writing to it correctly. The natural defense — "of course each agent's own running §6 loop instance tags its own `agent_id`, that's what §18's per-agent architecture means by construction" — is plausible and probably what the authors intend, but it is exactly the kind of "this works by an inference the reader has to supply, not by an instruction the document actually gives" gap that rounds 1–6 of this exact review thread have repeatedly flagged as the section's persistent failure mode, now relocated from the *existence* of a schema artifact (rounds 1–6) to the *write-path contract* for one that newly, genuinely exists (round 7). It is a smaller and more forgivable instance than any of rounds 1–6's — the property is very likely true by construction rather than false — but it is the one thing in this round's diff that would make `test_capture_cross_agent_prohibited` pass on the *rejection* case while silently not proving the *precondition* (correct population) the test's real-world meaningfulness depends on. A single added test (`test_lineage_row_tagged_with_committing_agent` or equivalent) and one sentence naming the exact commit-path line that sets the field would close this permanently; absent it, the section's seven-round pattern of "the previous round's fix reveals a defect one level further out" has, for the first time, moved from schema-existence claims to schema-population claims — a new frontier for the same underlying discipline gap, not a new category of error.

## Aggregate confidence

```
critical_floor  = min(Correctness=88, RedTeam=84, Safety=84) = 84
weighted_mean   = (88*2 + 92 + 84*2 + 84 + 84*2 + 78 + 84 + 90 + 86) / 11
                = (176 + 92 + 168 + 84 + 168 + 78 + 84 + 90 + 86) / 11
                = 1026 / 11 = 93.27 → 93
overall         = min(84, 93) = 84
```

**Overall confidence: 84 / 100**

## Verdict

**ready-for-approval**

This is the first round in the section's seven-round history to clear 80 with all three CRITICAL dimensions at 84 or above. All three of round 6's blocking items are genuinely closed — the `agent_id` schema delta is real (shipped in `DATA-LAYER.md:138` in this same round, not merely narrated), the intra-section and cross-file contradictions round 6 introduced while attempting this fix are both resolved by making the underlying claim true rather than by re-wording it, a named test (`test_capture_cross_agent_prohibited`) now backs the cross-agent prohibition, and the four-round-old missing §7 RC-6 cross-reference is added and verified accurate. The remaining gap — `lineage.agent_id`'s write-path population is unspecified for ordinary commits (Correctness C-1, Red-team RT-2, Safety S-3, Completeness Co-5, Calibration Ca-5, and the adversarial pass) — is real but narrower than any prior round's central defect: it is a missing specification for a property very plausibly true by construction, not a false claim about the current state of a file. It does not block approval at this score, but should be tracked:

1. **(Non-blocking, recommended before implementation) Name the exact commit-path line (§6 pseudocode or §8's `commit_gate`) that populates `lineage.agent_id` on an ordinary commit, and add a corresponding test** (e.g. `test_lineage_row_tagged_with_committing_agent`) so the write side of the fleet-scoping property is as checkable as the read side now is.
2. **(Cosmetic, easy) Pin down the literal value of "the constant" used for `agent_id` in a single-agent deployment** (`DATA-LAYER.md:138`), so a future migration to real per-agent values has a stated starting point.

Neither item is a CRITICAL-dimension failure or a blocking defect; both are the kind of follow-up a `change-approver` can reasonably accept as a tracked note alongside approval rather than as a condition of it.
