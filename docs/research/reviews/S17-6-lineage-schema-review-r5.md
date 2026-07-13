# 360 Review: S17-6-lineage-schema — 2026-07-13 (Round 5)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` §17.6, "The scaffold-version log — concrete schema & mutation operators" (lines 479–511), marked "added 2026-07-13, revised r5" |
| Proposed change | Round-5 rewrite unifying `source_ref`'s admission mechanism into one predicate stated identically in the schema field and the `CAPTURE` bullet ("every referenced `checkpoint_id` is an **ancestor** of the current live checkpoint," a §10 lineage `parent`-chain walk); renames `snapshot` → `snapshot_ref` to match the DATA-LAYER delta; names the §6-orchestrator `component_invoked` event as the invocation-logging plug-point `w_prune` depends on; ships all three (`scaffold_versions`, `selfmod_rejected`, `component_invoked`) in one DATA-LAYER §5 delta line |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json` → `agents.status = "open"` (last updated 2026-07-03). Filing directly to `docs/research/reviews/` (not `-proposal.md`).

## Round 1–4 item resolution scorecard (every numbered item, closed or explicitly deferred)

| # | Item (originating round) | Claimed status this round | Verified status | Evidence |
|---|---|---|---|---|
| 1 | `revalidation` in the formal schema block (R3) | — (already closed R3/R4) | **Still closed, unchanged** | `ALGORITHM-v0.2-pathway-learner.md:498` — `revalidation ∈ {n/a, pending, passed, failed}` is in the code block. No regression. |
| 2 | Quantify + register `κ_reval` (R3) | — (already closed R4) | **Still closed, unchanged** | `:509` κ_reval named, defaulted (0.5), registered; `:286` §12 lists it. Text is verbatim-identical to R4 on this point; arithmetic re-verified below (Correctness C-4). |
| 3 | `source_ref` self-contradiction: schema field vs. `CAPTURE` bullet (R4's C-1/Cs-1) | Addressed | **Genuinely resolved** | `:489–491` (schema field) now reads "admission-checked against the §10 lineage table, **see the CAPTURE bullet for the exact predicate**" — it explicitly defers to, rather than duplicates or contradicts, `:507`. `:507` states the one predicate once: "the orchestrator verifies at admission — **one predicate, one check target** — that every referenced `checkpoint_id` is an ancestor of the current live checkpoint." A grep for `eval rows`, `TruthStore eval`, `episode's outcome`, `gated episode` across the whole file returns **zero hits** — the R4-flagged contradictory language ("the TruthStore eval rows are the check target") has been removed outright, not merely reworded alongside the surviving claim. This is a real fix, not a relabeling: there is now exactly one described mechanism, stated once, referenced once. |
| 4 | Temporal soundness: "EXISTS in lineage ⇔ gate passed" only true at commit instant (R4's C-2) | Addressed | **Genuinely resolved for the case the section specifies (single execution head); see Correctness C-1/C-2 and the adversarial pass for the case it does not specify** | The check moved from **existence** to **ancestry** (`:507`). Traced against §3/§8's rollback mechanism (rollback = reactivate the immediate parent, retire the regressing candidate — §17.3's Stage-2 model, generalized): a rolled-back checkpoint becomes a sibling/descendant of the reactivated parent, never an ancestor of whatever the chain grows into next, so "ancestor" correctly and permanently excludes it where "existence" did not. This is a real, verified soundness improvement for a single running agent's own checkpoint chain. |
| 5 | `snapshot` / `snapshot_ref` field-name and content-vs-reference mismatch with DATA-LAYER (R4's Cs-2) | Addressed | **Genuinely resolved** | `:492–493` now reads `snapshot_ref (ArtifactStore blob id — the full component content, immutable; the truth row holds the reference, the blob holds the bytes)` — name and semantics (reference, not inline content) now match `DATA-LAYER.md:138`'s `snapshot_ref` field exactly. |
| 6 | Register `scaffold_versions` + `selfmod_rejected` (+ now `component_invoked`) as one DATA-LAYER §5 delta (R3/R4) | Addressed | **Genuinely resolved, all three present** | `DATA-LAYER.md:138` — `scaffold_versions(version_id, component_id, parents, operator, source_ref, snapshot_ref, diff, gate_ref, status, revalidation, created_ts)` + event kinds `selfmod_rejected{...}`, `component_invoked{...}` *(delta gated under ALGORITHM §17.6)* — field list matches the §17.6 schema block field-for-field. |
| 7 | Name the §6-orchestrator plug-point for per-component invocation logging (R3's item 5, silently carried through R4) | Addressed | **Genuinely resolved** | `:506` — "every invocation is **logged to truth by the §6 orchestrator** as a `component_invoked{component_id, episode_id, ts}` event (JUDGE-side observation of SOLVE execution — the orchestrator runs SOLVE, so it sees every dispatch...)." This is a concrete locus, not an assertion of existence — the orchestrator is the one component both SOLVE and JUDGE code paths pass through by construction (§17.1), so "it sees every dispatch" is architecturally plausible, not hand-waved. |
| 8 | (R2/R3 legacy) `τ_sm`/`w_prune` §12 registration, invocation-based prune well-definedness, `selfmod_rejected` flood bound | — (closed since R3) | **Still closed, unchanged** | `:286`, `:503`, `:506` unchanged from R3/R4 — no regression found. |
| 9 | (R2 legacy, DF-4) reactivation mechanism never cross-referenced to §7's RC-6 fix (discounted UCT + tree invalidation) as the code-axis analog | Not claimed addressed | **Still open, unchanged across 4 consecutive rounds** | No new text links `:508`'s reactivation mechanism to §7. Minor, non-blocking, but now a 4-round-old unaddressed nit — see Design faithfulness DF-1. |
| 10 | **NEW this round** (not previously numbered, but the specific object of this round's audit instruction): is "ancestor of the current live checkpoint" well-defined under §18's multi-agent, per-agent-competence architecture (multiple simultaneously-"live" checkpoints, one per fleet agent), and does DATA-LAYER's `lineage` table support disambiguating whose chain to walk? | Not addressed (not claimed, not raised by the round's own cover note) | **Open — genuine, uncaught gap; see Correctness C-1 and the adversarial pass** | `DATA-LAYER.md:138`'s `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` carries no `agent_id` column, unlike `StateStore`'s explicit `agent_id` key (`:521`, "the schema delta"). §18.5 ("why N agents don't compound the risk, §17×§18") addresses only the JUDGE-write-path collective-capture risk (RC-2) — it does not address whether "the current live checkpoint" is agent-scoped, and §17.6 never cites §18 at all. |

All items the caller claimed addressed (3–7) verify as genuinely, concretely resolved on direct inspection — the strongest round-over-round showing across all five rounds. Item 10, surfaced by this round's own audit instruction rather than by the author's cover note, is real and unaddressed.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 84 | pass |
| 2 | Design faithfulness | 78 | pass |
| 3 | Red-team resistance (CRITICAL) | 78 | pass |
| 4 | Implementability | 76 | weak |
| 5 | Safety / integrity (CRITICAL) | 80 | pass |
| 6 | Efficiency / cost | 80 | pass |
| 7 | Completeness | 66 | weak |
| 8 | Consistency | 70 | weak |
| 9 | Calibration / honesty | 76 | pass |

## Findings by dimension

### 1. Correctness

**Score: 84 — pass**

**C-1. The ancestry predicate is sound and well-defined for the case the section actually specifies — a single running agent's own checkpoint chain — verified by direct construction, not narrative trust.** `ALGORITHM-v0.2-pathway-learner.md:30` defines the agent-state node `n = (c, K, L, Θ, z)`; a single running agent instance has exactly one live `c` at any instant. `DATA-LAYER.md:138`'s `lineage(checkpoint_id, parent, dataset_id, eval_run_id)` gives each checkpoint exactly one `parent` (singular, not `parents[]`), so the ancestor relation for checkpoints is a tree, and "walk from the current node via `parent`" (`:507`) is a well-formed, terminating operation. Tracing the rollback mechanism through §3 (`:57-58`, dual mastery/drift posteriors, drift "drives rollback only") and §8 (`:229`, "rollback fires only on a FRESH, adequately-powered re-eval") against §17.3's own Stage-2 model (reactivate the immediate parent, retire the regressing candidate) confirms: a rolled-back checkpoint is structurally a sibling-or-descendant of whatever the chain regrows into, **never** an ancestor of a later "current live checkpoint" — so "is an ancestor" correctly and *permanently* excludes it, unlike round 4's "exists" test. This closes round 4's C-2 for the documented case.

**C-2. Residual, but correctly and honestly scoped: the "ancestry stays sound over time" argument is not shown to hold once §18's multi-agent architecture is in play.** §18.1 (`:521`) gives each agent its own competence posterior "keyed by `agent_id` (the schema delta)" but the shared `lineage` table has no analogous `agent_id` column (`DATA-LAYER.md:138`) — so at fleet scale there can be multiple simultaneously-"live" checkpoints (one per running agent), and neither §17.6 nor §18 states whether "the current live checkpoint" in the `CAPTURE` predicate means "the checkpoint of the agent performing this `self_modify` episode" (the only reading that makes the mechanism well-defined) or is otherwise disambiguated by the schema. §18.5 (`:543`, "why N agents don't compound the risk, §17×§18") is the section that would be the natural place to reconcile this — it exists, and does address a different self_modify×fleet risk (collective JUDGE-write capture, RC-2) — but it does not address checkpoint/lineage scoping, and §17.6 never cites §18 at all. This is a genuine, citable gap in the "stays sound over time" claim (`:507`), narrower than round 4's (it does not affect the single-agent case, which is the case most of the document's worked examples assume), but it is exactly the gap this round's own audit instruction asked to be checked for, and the round's cover note ("a full end-to-end contradiction read... this round") does not mention it. See the adversarial pass.

**C-3. Minor, newly surfaced: the ancestor-walk's dependence on `lineage` rows never being deleted is never stated, only inferable.** §10 (`:266`) states "Checkpoints and the tree get retention/GC policies (bounded rewind horizon + tagged milestones)" — read alone, this could mean checkpoint *entities* (including their `lineage` rows) are pruned after a retention window, which would break an ancestor walk reaching back further than the horizon. §17.6 draws the ArtifactStore-blob-vs-truth-row distinction explicitly for its *own* new table ("`scaffold_retention` (§17.5) bounds pruning of *blobs* only; lineage rows are permanent," `:508`) but never makes the parallel statement for the pre-existing §10 checkpoint `lineage` table the ancestry walk itself now newly depends on. The likely-intended reading (SQL truth is canonical/append-only per `DATA-LAYER.md:149`, so §10's GC is ArtifactStore-blob-only, mirroring §17.6's own pattern) is plausible but is asserted nowhere for the table this round's fix actually walks.

**C-4. `κ_reval`'s arithmetic re-verified, unchanged from round 4, still correct.** `significant(Δ,SE)` trips at `Δ ≥ z·SE` (§2, `:43`); halving to `κ_reval·z = 0.5z` (`:509`) lowers the trip bar, correctly tightening (not loosening) the post-rollback monitor. Verified by direct substitution:
```
python3 -c "z=2.0; se=1.0; print('normal trip Δ>=', z*se, ' tightened trip Δ>=', 0.5*z*se)"
→ normal trip Δ>= 2.0  tightened trip Δ>= 1.0
```
A smaller `Δ` now clears the tightened bar — matches "stricter scrutiny" as claimed.

**Summary:** the round's headline fix (C-1) is a genuine, verified correctness improvement for the case in scope, and the identical-predicate self-contradiction from round 4 is fully closed. The residual (C-2/C-3) is real but narrower and differently-shaped than any prior round's correctness defect — it is a scope gap (the mechanism is not shown wrong, only shown not to cover a case the document's own architecture makes possible), which is why this dimension clears 70 for the first time across all five rounds, unlike a self-contradiction or an unsound equivalence.

---

### 2. Design faithfulness

**Score: 78 — pass**

**DF-1. Unresolved across four consecutive rounds (R2 DF-4, R3 DF-4, R4 DF-4): the reactivation mechanism (`:508`) is still never explicitly connected to §7's RC-6 fix (discounted UCT + tree-value invalidation on checkpoint change) as the deliberate code-axis analog of the same design pattern.** Purely a missed cross-reference, not a defect in the mechanism itself — but four rounds without a one-line fix is itself worth noting as a pattern of the revision process not picking up genuinely minor, previously-identified items even while doing a "full end-to-end read."

**DF-2. NEW, related to Correctness C-2: §17 and §18 are both explicitly M3-gated, cross-referencing additions (`:516`, "**M3**, with §17") with a dedicated section (§18.5) reconciling one specific self_modify×fleet risk — but §17.6 (added and revised five times *after* §18 already existed in the document) never once cites §18, despite §17.6 being the section that gives "checkpoint" and "lineage" their first concrete, walkable schema.** This is a faithfulness gap in the sense that §18.5 sets a precedent (explicitly reconciling a cross-axis interaction, "N × 0") that §17.6 does not follow for the interaction its own new ancestry mechanism most plausibly touches.

**DF-3. The `source_ref` fix's design intent (reuse `:10`'s lineage schema via ancestry rather than invent a new eval-row join, and state the predicate once) is faithful to the document's MVP/parsimony discipline and, this round, is also faithfully and consistently *executed* — an improvement over round 4, where the intent was right but the execution (Correctness C-1/C-2 in that round) was not.**

**DF-4. Attribution to OpenSpace (line 481) is unchanged and remains accurate.** No overclaim of novelty for the schema shape.

---

### 3. Red-team resistance

**Score: 78 — pass**

Evidence from `ALGORITHM-v0.1-redteam.md` RC-1–RC-8.

**RT-1. Round 4's RT-2 (the narrow RC-2-adjacent gap — `CAPTURE`'s admission check unable to detect post-commit invalidation) is genuinely closed for the single-agent case.** The ancestry predicate (Correctness C-1) does now detect and exclude a rolled-back source checkpoint, closing the specific "capturing a pattern from a checkpoint that was lucky, not just the episode" gap round 4 identified — a real, verified fix to a CRITICAL-dimension finding, not a narrative reframing.

**RT-2. NEW, narrower RC-6-adjacent residual: at fleet scale, if "current live checkpoint" resolves ambiguously or inconsistently across concurrently-running agents (Correctness C-2), the ancestry check's guarantee ("stays sound over time") is unverified for that configuration.** This is not a reopening of RC-6 in the form the redteam doc describes it (stale MCTS tree values after a weight move) — it is a structurally adjacent failure shape (a check whose soundness argument implicitly assumes a single execution head, applied without qualification to an architecture the same document elsewhere makes explicitly multi-headed). Scored as a residual, not a reopening, per the dimension's own scoring instruction, because: (a) the single-agent case — the only case the section's own text and worked examples ever discuss — is genuinely sound; (b) §18.5 already establishes that the *JUDGE-capture* variant of this risk is bounded ("N × 0"); what's unaddressed is a narrower, non-adversarial specification gap (which chain to walk), not a demonstrated exploit path.

**RT-3. Round 3's honestly-scoped RC-6 residual (RT-3 in that report — reactivation narrows but does not close the stale-fallback window) remains open in the same, unchanged, honestly-labeled form.** No regression.

**RT-4. No previously-closed red-team item (RT-1/RT-4/RT-5 from earlier rounds, or round 4's RT-1) is reopened.** The wall invariant, capability isolation, dedup-in-JUDGE-admission-path, and `selfmod_rejected` flood bound are all unchanged and re-verified present.

**Summary:** the round's flagship fix closes a genuine CRITICAL-dimension red-team gap (RT-1) for the documented case, without reopening anything previously closed. The new residual (RT-2) is real but narrower in shape and consequence than round 4's, keeping this dimension in the "pass" band for the first time in the section's five-round history.

---

### 4. Implementability

**Score: 76 — weak**

**I-1. `test_capture_requires_gated_success` (`:510`) is now implementable as a single, well-defined test — a genuine fix to round 4's I-3.** It asserts one predicate (ancestry via `lineage.parent`-chain walk), matching the one mechanism now described once in the section.

**I-2. NEW: a developer building this for a fleet deployment (§18, also M3) has no stated answer for what checkpoint value to pass as "the current live checkpoint" when multiple agents run concurrently over the shared `lineage` table.** The natural implementation (scope the ancestry walk to the calling agent's own chain) is almost certainly what's intended, but it requires the implementer to invent the scoping rule themselves — precisely the class of gap this section's "concrete schema" title exists to eliminate, and precisely the class of gap flagged repeatedly in rounds 1–4 for other fields (`source_ref`, `revalidation`, `κ_reval`) before each was fixed by naming the missing piece explicitly.

**I-3. `component_invoked`'s plug-point (`:506`) is concretely locatable and implementable** — closes round 4's I-4 cleanly.

**I-4. Minor: the retention/GC interaction (Correctness C-3) leaves an implementer unsure whether the ancestor walk must handle a "referenced checkpoint no longer in `lineage`" case** (would that be treated as "not an ancestor" ⇒ correctly refused, or as an error?) — not specified either way.

**Summary:** two of round 4's implementability gaps are cleanly closed (I-1, I-3), but a new implementation-blocking ambiguity (I-2) appears for exactly the deployment configuration (fleet, M3) the document's own milestone structure says this section must eventually support, plus one smaller unspecified edge case (I-4).

---

### 5. Safety / integrity

**Score: 80 — pass**

**S-1. No named gate, budget enforcer, or partition is weakened.** §17.1/§17.3/§17.5 text is unchanged (confirmed by direct read); the `self_modify` budget enforcer remains JUDGE-owned (`:455`).

**S-2. `CAPTURE`'s "no capturing lucky runs" safety property is now a genuinely checked, auditable, single-mechanism control for the single-agent case — a real safety improvement over all four prior rounds.** The ancestry predicate detects and excludes the specific failure round 4 identified (a source checkpoint later invalidated by RC-5 rollback), closing round 4's S-3 for that case.

**S-3. The fleet-scoping gap (Correctness C-2) is a completeness/specification gap, not a demonstrated weakening of any existing gate or control.** No mechanism is shown to admit something it shouldn't; rather, the mechanism's scope of applicability is under-specified for a configuration (multi-agent) the document elsewhere treats as real and M3-gated alongside §17 itself (`:516`, "M3, with §17"). This keeps the dimension out of "blocking" territory but is worth resolving before an M3 fleet deployment actually exercises `self_modify`+`CAPTURE` per-agent.

**S-4. The residual honesty language (`:507`, "two-fold... (a) a source checkpoint can still be rolled back after a CAPTURE is admitted... (b) ancestry verifies the episodes were gated, not that the distilled pattern caused their success") is accurate and appropriately hedged** — consistent with the document's best practice elsewhere (§17.3's "narrows... does not close").

**Summary:** no gate is weakened, and the round's central fix (ancestry-based admission) is a genuine, verified safety improvement for the documented case — enough to clear 70 for the first time in five rounds. It does not score higher because the fleet-scale applicability of that same guarantee is untested and unstated.

---

### 6. Efficiency / cost

**Score: 80 — pass**

**E-1. The ancestor-chain walk is a bounded, cold-path operation** (single-parent tree, walked once per `CAPTURE` admission, not a hot-path or per-episode cost) — no complexity regression.

**E-2. Unaddressed but plausible: if `lineage` rows are in fact permanent (Correctness C-3), chain depth grows unboundedly over a long-running agent's lifetime, making the walk's cost grow with system age.** Not stated as bounded or amortized (e.g., via periodic "tagged milestone" shortcuts, which §10 mentions for the *rewind horizon* but not explicitly for the ancestry-walk's own performance). A minor, unaddressed cost note, not a hot-path or asymptotic-class problem.

**E-3. `w_prune`'s soft eviction bound (unchanged from round 3/4) remains open** — no cap on live-component count, unchanged, neither new nor worsened.

---

### 7. Completeness

**Score: 66 — weak**

**Co-1. Resolved: round 4's Co-2/Co-3 (`source_ref` mechanism under/over-specified; `snapshot`/`snapshot_ref` mismatch)** — both now cleanly present and reconciled (scorecard items 3, 5).

**Co-2. Resolved: round 4's Co-5 (invocation-logging plug-point never named)** — now present (scorecard item 7).

**Co-3. NEW, the dimension's central gap: no statement anywhere addresses what "the current live checkpoint" means, or how the ancestry walk is scoped, under §18's multi-agent architecture** (Correctness C-2, Implementability I-2) — despite §18 being real, existing, cross-referencing supporting content in the same document (§18.5 exists and reconciles a *different* self_modify×fleet risk), this specific interaction is not addressed, deferred, or flagged as future work anywhere in §17.6 or §18.

**Co-4. NEW: no statement reconciles §17.6's ancestry-walk dependency on permanent `lineage` rows with §10's own, pre-existing "checkpoints... get retention/GC policies" clause** (Correctness C-3) — the parallel statement §17.6 makes for its *own* new table ("lineage rows are permanent," `:508`) is not extended to the pre-existing table this round's fix now newly depends on for correctness.

**Co-5. Unresolved, unchanged across four rounds: no explicit cross-reference from the reactivation mechanism to §7's RC-6 discounted-UCT/tree-invalidation pattern** (Design faithfulness DF-1) — minor, non-blocking, but genuinely still open.

**Co-6. Positive:** the test-stub list (`:510`) is now internally coherent — `test_capture_requires_gated_success` has exactly one predicate to assert against (Implementability I-1) — a genuine hygiene improvement over round 4.

**Summary:** the round closes every completeness gap it was explicitly asked to close (Co-1, Co-2), but the two gaps this round's own audit instruction specifically asked to be checked for (fleet-scoping, retention interaction) are real and open (Co-3, Co-4), alongside one long-standing minor item (Co-5) — enough to keep this dimension below 70.

---

### 8. Consistency

**Score: 70 — weak**

**Cs-1. Resolved: round 4's Cs-1 (intra-section self-contradiction between the `source_ref` schema field and the `CAPTURE` bullet)** — now one predicate, stated once, cross-referenced correctly (scorecard item 3). This is the cleanest, most concrete fix of the round.

**Cs-2. Resolved: round 4's Cs-2 (`snapshot`/`snapshot_ref` field-name and semantics mismatch with the DATA-LAYER delta)** — now matched exactly (scorecard item 5).

**Cs-3. NEW, borderline: §17.6's own architecture claim ("the check stays sound *over time*, not just at the commit instant," `:507`) is not qualified against §18's per-agent-checkpoint architecture, even though §18 is presented as a *sibling*, cross-referencing, same-milestone addition (`:516`) rather than an unrelated or hypothetical future concern.** A reader comparing §17.6's "stays sound over time" claim against §18.1's "each agent keeps its own... checkpoint" would reasonably ask which chain the claim is about; neither section answers this for the other. This is narrower than round 4's Cs-1 (it is a cross-section scope gap, not an intra-section direct contradiction) but is a real, citable inconsistency in what "the current live checkpoint" is implicitly assumed to mean across two sections that are supposed to compose.

**Cs-4. `revalidation`/`κ_reval`'s presence remains fully consistent across the schema block, prose, §12, and DATA-LAYER** — unchanged, still solid.

**Summary:** the round closes both concrete, grep-verifiable inconsistencies round 4 found (Cs-1, Cs-2) — a genuine, clean improvement. The new item (Cs-3) is real but is a cross-section scope gap rather than a direct textual contradiction, which is why this dimension clears the "weak" floor's low end (70) rather than remaining in round 4's territory, but does not reach "pass" outright given the gap is exactly on the section's own central, newly-added soundness claim.

---

### 9. Calibration / honesty

**Score: 76 — pass**

**Ca-1. Genuine, accurate, and well-hedged: the "residual honesty, two-fold" language (`:507`) accurately scopes what the ancestry check does and does not guarantee** — (a) post-admission rollback of the source is not caught by admission-time ancestry, addressed instead by §17.3's own gate on the captured component; (b) ancestry proves gating, not causation. Both are true, precisely stated, and not overclaimed.

**Ca-2. Mild overclaim: "the check stays sound *over time*, not just at the commit instant" (`:507`) is stated without qualification, when the argument supporting it (traced in Correctness C-1) only holds for a single execution head — the claim is true for the case actually demonstrated but is phrased as a general property of the mechanism.** This is a narrower, softer version of round 4's Ca-2 pattern (a confident closing claim not fully qualified against the document's own other mechanisms) — here the "other mechanism" is §18's fleet architecture rather than §3/§8's rollback machinery, and the round-4-style overclaim risk (confident tone outrunning verified scope) recurs, just at smaller scale and severity.

**Ca-3. The round's cover claim ("the author additionally did a full end-to-end contradiction read of the section this round... grep-verification is blind to present-but-contradicting artifacts") correctly upgrades the round-4-identified verification methodology gap, and it does catch and fix the intra-section contradiction (Cs-1) it was aimed at.** It does not, however, extend to cross-*section* claims (§17.6 vs. §18) — the same blind spot round 4's adversarial pass warned about ("diff every claim... against every other place... that describes the same mechanism") is only partially closed: the round closed it for other bullets *within* §17.6, but not for the one cross-file/cross-section claim this round's own predicate introduces.

**Ca-4. Accurate, unchanged: "No change to the partition (§17.1), the gate (§17.3), the budgets (§17.5), or any §1–§16 mechanism" (line 481)** — verified true.

**Summary:** this round's calibration is markedly more disciplined than rounds 2–4 (no false "registered in §12"-style claims, no flatly false cross-references), and the section's own hedging language is honest where it applies. The residual gap is narrower and more specific than any prior round's: a true-for-the-demonstrated-case claim phrased without the scope qualifier that the document's own §18 architecture would require.

---

## Strongest adversarial objection

**The round's own methodology upgrade — "a full end-to-end contradiction read of the section this round" — was, by its own framing, a direct response to round 4's adversarial pass ("grep-verification is blind to present-but-contradicting artifacts... the closing pass needs to diff every claim about a shared mechanism against every other place in the section... and stress-test any 'X ⇔ Y' claim against the document's own mechanisms that could make X and Y diverge"). It correctly executed that instruction — but scoped it to the section's own four walls, and the instruction never said to stop there.**

Round 4's adversarial pass named two remedies: (a) diff every claim about a shared mechanism against every *other place* that describes it, and (b) stress-test any "X exists ⇔ Y held" claim against the document's own *other mechanisms* that could make X and Y diverge over time. This round visibly did (a) within §17.6 — the `source_ref` schema field now explicitly defers to the `CAPTURE` bullet instead of restating a second, incompatible version, and it visibly did (b) for the one divergence-mechanism round 4 named explicitly (§3/§8's RC-5 rollback) — tracing through exactly how ancestry, not existence, survives that specific mechanism. Both are real, verified, well-reasoned fixes.

But §17.6's new claim — "the check stays sound over time" — is an "X ⇔ Y held over time" claim of exactly the shape round 4 asked to be stress-tested against *every* mechanism that could make it diverge, not just the one round 4 happened to name. §18 is such a mechanism: it is not a hypothetical future extension the author could be forgiven for not anticipating — it is a fully-written, cross-referencing, same-milestone (M3) sibling section that already has its own subsection (§18.5) explicitly reconciling a different self_modify×fleet interaction, and it explicitly gives `StateStore` (a structurally similar per-agent-state table) an `agent_id` key specifically because "each agent keeps its own" state. A closing pass thorough enough to satisfy round 4's own adversarial pass in letter would have run the same "which other mechanism could make this diverge" question against §18 the same way it was run against §3/§8/RC-5 — the two checks are the same shape, and §18 was one search away (a grep for `self_modify` outside §17, or for `agent_id`, immediately surfaces both `:521`'s per-agent `StateStore` key and `:543`'s explicit "§17×§18" reconciliation section). The round's own claimed methodology, applied to its own claimed scope of diligence, should have found this; it found the intra-section case and stopped at the section boundary. This is not evidence the fix is wrong — the single-agent case is genuinely, verifiably sound — but it is evidence that "sound over time" was asserted at a scope (any deployment) broader than what was actually checked (a single execution head), which is precisely the pattern round 4 was written to close, recurring here in a narrower, cross-section form rather than the intra-section form round 4 caught and this round fixed.

## Aggregate confidence

```
critical_floor  = min(Correctness=84, RedTeam=78, Safety=80) = 78
weighted_mean   = (84*2 + 78 + 78*2 + 76 + 80*2 + 80 + 66 + 70 + 76) / 11
                = (168 + 78 + 156 + 76 + 160 + 80 + 66 + 70 + 76) / 11
                = 930 / 11 = 84.5 → 85
overall         = min(78, 85) = 78
```

**Overall confidence: 78 / 100**

## Verdict

**needs-revision**

This is the strongest round in the section's five-round history by a wide margin (58 → 64 → 68 → 58 → **78**), and it is the first round in which all three CRITICAL dimensions (Correctness 84, Red-team 78, Safety 80) individually clear 70. Every item this round's cover note claimed as addressed verifies as genuinely, concretely resolved on direct inspection: the intra-section `source_ref` self-contradiction is fully closed (one predicate, stated once, cross-referenced correctly), the ancestry-based admission check is a real and verified soundness improvement over the "existence" test for the case the document actually specifies (a single agent's own checkpoint chain), the `snapshot_ref` naming mismatch is fixed, and the invocation-logging plug-point is named concretely. The round's own claimed verification upgrade (a full contradiction read, not just grep-for-presence) is real and did close what it was aimed at.

The score does not clear 80 because this round's own audit instruction asked for exactly the check that would have found the residual gap: whether the ancestry predicate is well-defined under the document's own multi-agent (§18) architecture, where checkpoints are not obviously single-headed. They are not:

1. **State whether the `CAPTURE` ancestry predicate's "current live checkpoint" is scoped per-agent, and if so, add the scoping mechanism to the schema** (an `agent_id` column on `lineage`, analogous to `StateStore`'s, or an explicit statement that the walk is always parameterized by the calling agent's own checkpoint and never needs disambiguation from a shared table) — cite and reconcile against §18.1's per-agent `StateStore` key and §18.5's existing self_modify×fleet reconciliation section, rather than leaving §17.6 silent on §18 entirely. (Correctness C-2, Red-team RT-2, Implementability I-2, Completeness Co-3, Consistency Cs-3, Calibration Ca-2)
2. **State explicitly whether `lineage` rows (the pre-existing §10 table the ancestry walk now depends on for correctness) are permanent, or subject to §10's stated checkpoint retention/GC policy** — mirroring the parallel statement §17.6 already makes for its own new table ("lineage rows are permanent," distinct from blob GC). If checkpoint entities can be GC'd within the stated "bounded rewind horizon," the ancestor walk needs a stated behavior for a referenced checkpoint that has aged out. (Correctness C-3, Implementability I-4, Completeness Co-4, Efficiency E-2)
3. **(Minor, carried across four rounds, easy to close) Add the one-line cross-reference from the reactivation mechanism (`:508`) to §7's RC-6 fix**, naming it explicitly as the code-axis analog of discounted-UCT/tree-invalidation. (Design faithfulness DF-1, Completeness Co-5)

If a round 6 is commissioned, the closing-pass discipline that correctly caught this round's intra-section contradiction should be explicitly extended one level further: for any claim of the form "this stays sound over time" or "the check is well-defined," grep the *whole document* (not just the section under revision) for the other sections that describe the same conceptual entity (here: `checkpoint`, `lineage`, `agent_id`) before asserting the claim holds unconditionally.
