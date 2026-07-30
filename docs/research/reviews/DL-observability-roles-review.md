# 360 Review: DL-observability-roles — 2026-07-30

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §11 (+ anchored deltas: §1, §6 rebuild block, §6.1 exemption list, §7 extras) |
| Proposed change | Add two opt-in autonomy-profile roles — `ObservabilityPort` (traces/spans/scores, emit-and-forget) and `AnalyticsStore` (rebuildable columnar projection of Truth) — satisfying backlog item AUT-2, never part of the default install |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Round | 1 (unsuffixed) |
| Circuit-breaker | `agents.status = "open"` — filed as a direct review, not a proposal |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 65 | weak |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 52 | weak |
| 4 | Implementability | 60 | weak |
| 5 | Safety / integrity (CRITICAL) | 72 | pass |
| 6 | Efficiency / cost | 85 | pass |
| 7 | Completeness | 55 | weak |
| 8 | Consistency | 62 | weak |
| 9 | Calibration / honesty | 78 | pass |

## Findings by dimension

### 1. Correctness

- **Dangling cross-reference — the central defect.** DATA-LAYER.md:326 (§11.3) states the embedded `ObservabilityPort` is backed by "Truth administrative events (`trace`/`score` kinds, **§5**)". §5 (DATA-LAYER.md:145) is the section that would need to carry that schema, following the exact pattern already used for every other administrative event kind in this document (`dispatch{...}`, `selfmod_rejected{reason, proposal_hash, ts}`, `component_invoked{component_id, episode_id, ts}`, `rejected_ingest{reason, payload, ts}`, `schedule{...}` + `wake_events{...}`, `work_unit_closed{occurrence_id, outcome, ts}`). I grepped the full text of §5 (DATA-LAYER.md:145) and confirmed: **no `trace{...}` or `score{...}` row schema exists there.** The citation points at content that was never written. The task brief's own enumeration of this round's anchored deltas (§1 pointer, §6 `rebuild_analytics` line, §7 extras, §6.1 exemption list) confirms a §5 schema delta was never part of this submission — §11.3 asserts it anyway.
  - This is not cosmetic: it is precisely the recurring authoring defect this project's own memory already names — `.claude/memory/lessons.md` L-013 ("claiming a schema field/registration/cross-reference exists without writing it... fixing one location while a co-dependent one stays stale"), which the gate caught 5+ times in the 2026-07-13 cycle per `evolution-log.jsonl` EV-75. §11 reproduces the identical pattern: it cites §5 for a schema it does not contain.
  - Concrete consequence: a developer implementing the embedded tier has **no concrete row shape** for `trace`/`score` events (columns? is `payload` reused verbatim as in `events`? does `score`'s `name`/`value` get its own columns or ride in `payload`? is `kind` stored?). Every other admin event type in §5 has this specified; `trace`/`score` do not.
- **Unsubstantiated derivation — "the two-bundle wiring covers this" (§11.4, DATA-LAYER.md:335).** The claim that P1 holds "across traces" leans entirely on the §6.1 `RedactedTruthView` mechanism, whose actual redaction rule (DATA-LAYER.md:190) strips exactly one thing: `item_ids`/item-content on `split=held_out` rows. §11.1 (DATA-LAYER.md:301) states `ObservabilityPort.score()` carries "gate decisions, calibration tuples" — none of which are item content or item ids. The stated redaction mechanism therefore has **no rule that touches the content §11.1 itself says scores hold**. Asserting "the solve bundle's ObservabilityPort is the redacting one" does not establish *what* it redacts for a `score()` payload; the document never states a redaction rule for numeric/calibration content, so the "P1 across traces" claim is not actually derived — it's borrowed language from a mechanism built for a different content type. See §3 (Red-team resistance) below for why this matters.

### 2. Design faithfulness

- Correctly follows the established opt-in/ports-and-adapters idiom: two new Protocol classes (DATA-LAYER.md:307-316), an embedded/full tier split matching §3's table shape, config-per-role matching §4, and extras gated in §7 exactly like `mdlp[postgres]`/`mdlp[neo4j]` etc. — no divergence from the §§2-15 layering conventions.
- Correctly scopes itself against ALGORITHM §20.7 (DATA-LAYER.md:301, "Consumers: §20.7 passive-informing digests") and ALGORITHM-v0.2:632 confirms the inverse pointer ("The trace/delivery substrate is the ObservabilityPort (DATA-LAYER §11 — separately gated)") — the cross-reference is bidirectionally consistent, a genuine strength.
- Provenance citations (STUDY-automaton-autonomy.md avoid-list A2, STUDY-hermes-agent.md §3.5) are accurate: A2 ("inert observability... the audit log drops its correlation id at the sole call site") is exactly what motivates invariant 1, and this is verified against the source (STUDY-automaton-autonomy.md:27, :41).
- Minor faithfulness gap, not blocking: unlike prior DATA-LAYER deltas (§6.1/§6.2, whose headers read "▣ APPROVED: review-360 83/100 over 12 rounds → change-approver"), this section carries no BUILD-SPECS.md companion entry, and BUILD-SPECS.md (checked directly) has no AUT-2 item at all yet. This is not disqualifying — §6.1/§6.2 set the precedent of gating a DATA-LAYER-direct delta without a BUILD-SPECS item — but it should be named explicitly rather than left implicit, since AUT-1 (§20) *was* folded directly into ALGORITHM-v0.2 with its own numbered section, giving two different precedents for how these AUT-* backlog items land.

### 3. Red-team resistance

- **A genuine, unaddressed instance of RC-2's failure family: JUDGE-internal information leaking to a SOLVE-visible read channel.** §17.1 (ALGORITHM-v0.2:457, :190 in DATA-LAYER) already recognizes that *read*-access to JUDGE-side information is "a different hazard" from write-access, and it does the work of closing that hazard for `TruthStore` specifically: a `RedactedTruthView`, an import/admission check (`test_solve_candidate_cannot_import_unredacted_truth`), and a Stage-1 sandbox backstop. §11 introduces a **second JUDGE-internal information channel** — `ObservabilityPort.score(correlation_id, name, value)` carrying, by §11.1's own description, "gate decisions, calibration tuples" (the exact §19.1 `(decision, realized-outcome, attributed-clause)` tuples that ALGORITHM-v0.2 §19.4 explicitly places in JUDGE and protects from *editing* by SOLVE/`self_modify`/fleet agents) — and does **not** perform the analogous read-side analysis. §11.4's only stated safeguard (the P1 held-out redaction) does not cover this content type (§1 above).
  - Why it bites: a `self_modify` (§17.2) candidate that can observe, via a SOLVE-visible trace/score stream, *which clause* is marginal, the current `r̂`, or how close a knob sits to its clamp, gains a side-channel view into the JUDGE's current strictness posture. §19.3's hard clamp (`z ∈ [z_8, 2·z_8]`, etc.) still bounds how loose the gate itself can ever get — so this is not a structural break of the safety floor — but it *is* exactly the kind of oracle RC-2 warns about: information that lets an optimizer aimed at the verifier find scaffold edits that pass narrowly rather than generalize, without the gate's own math changing at all. This is a residual attack surface the section does not name, does not gate, and does not test for.
  - This is scored as a residual-attack-surface weakness rather than a full reopening (0) because: (a) it is additive and opt-in (profile off ⇒ no exposure at all — DATA-LAYER.md:339 `test_default_config_needs_no_observability_deps`), (b) the §19.3 clamp remains a hard, independent floor regardless of what SOLVE observes, and (c) it is fixable by porting the exact analysis §6.1 already wrote for `TruthStore` (a redaction/no-import rule for calibration-tuple content on the SOLVE-side `ObservabilityPort`) — it is a gap in this draft, not an unfixable design flaw.
- **Secondary angle, minor:** the "spans" holds-category (DATA-LAYER.md:301, "spans (model calls: cost/latency)") has no corresponding port method (§11.2 defines only `trace`/`score`/`flush`, DATA-LAYER.md:307-310). If spans are meant to be a `trace(kind="span", ...)` call, that convention is never stated — an implementer could plausibly build a phantom feature (a documented "hold" with no write path), or silently omit span capture, and no test in §11.5 would catch either outcome. Low severity on its own, but combined with the missing §5 schema (§1 above), it means the observability data model is under-specified precisely where a red-team probe (a component that decides what to log and how) would look first.

### 4. Implementability

- The missing §5 schema (finding #1) is the most concrete implementability blocker: there is no row shape to build the embedded `ObservabilityPort` against, unlike every sibling admin-event type.
- `ObservabilityPort` defines no read/query method (only `trace`/`score`/`flush`); `AnalyticsStore` has `query`. It is plausible that reading is meant to happen out-of-band (the JSONL file directly, or the Langfuse UI) rather than through the port, but this is never stated, and §11.1's "Consumers" column (§20.7 digests, human audits) implies *some* programmatic read path is needed for §20.7 to actually consume it. Left to guesswork.
- The `correlation_id` parameter is overloaded across three different identifier spaces (`occurrence_id`, `checkpoint_id`, `schedule_id` — DATA-LAYER.md:319) with no discriminator field specified for a consumer to know which kind a given row's `correlation_id` is, beyond inferring it from `kind`/`name` freeform strings.
- `rebuild_analytics`'s meaning for the embedded tier ("SQLite views over Truth", DATA-LAYER.md:327) is left implicit — a SQL view is always live over its base tables, so what concretely does "rebuild" do here (no-op? `DROP VIEW`/`CREATE VIEW` replay after a schema change?) is unaddressed, unlike the full-tier ClickHouse case where "rebuild" clearly means re-ingest.

### 5. Safety / integrity

- No existing gate (§8), the calibration layer (§14), or the verifier (`HUMAN-LEARNING-VERIFIER.md`) is weakened, edited, or bypassed by this section; it is purely additive and opt-in, matching L-010's zero-infra default (verified: DATA-LAYER.md:339 `test_default_config_needs_no_observability_deps`).
- Invariant 2 ("observability can never take the system down," DATA-LAYER.md:320) is well-specified in its "must not" half (swallow + no hot-path emit + cycle-boundary flush) and tested (`test_emit_failure_never_blocks`). The "counted" half is weaker — see Completeness/adversarial pass below — but this does not itself weaken any existing gate.
- The one real integrity concern is the read-side JUDGE-internal leak identified in §3 above: it erodes defense-in-depth around the §17.1 SOLVE/JUDGE partition (a second, unanalyzed information channel into JUDGE internals) without breaking any single hard invariant outright (§19.3's clamp is orthogonal to what SOLVE can observe). Scored 72 (acceptable but flagged) rather than lower because no *existing* gate/floor is actually loosened by this text — the exposure is new and adjacent, not a violation of a stated invariant.

### 6. Efficiency / cost

- Correctly kept off the §6 hot path: emit-and-forget, cold path, flush at cycle boundaries only (DATA-LAYER.md:301, :320) — no O(n²) additions, no synchronous LLM calls introduced (none of `trace`/`score`/`ingest`/`query` involve a model call).
- `AnalyticsStore` is explicitly rebuildable and columnar — consistent with the existing rebuild-projection cost model (§6).
- Minor, non-blocking: possible duplicate bookkeeping between ALGORITHM §19.1's own TruthStore logging of the `(decision, realized-outcome, attributed-clause)` tuple and `ObservabilityPort.score()` emitting "gate decisions, calibration tuples" as a second call site for what may be the same underlying event — not an efficiency problem in the O() sense, but an unreconciled second write of the same information (see Consistency below).

### 7. Completeness

- **Missing schema** (§5 delta for `trace`/`score`, finding #1) — the most material gap.
- **Missing test for the "counted" half of invariant 2.** `test_emit_failure_never_blocks` (DATA-LAYER.md:339) verifies work completes despite a raising backend; nothing in §11.5 verifies the failure is actually *counted*, nor addresses the adversarial angle explicitly raised for this review: what happens when the failure counter's own surfacing (via §20.7) fails? Is the counter itself an in-process primitive independent of `ObservabilityPort` (avoiding recursion), or does it round-trip through the same port? The text ("a failure counter is itself surfaced via §20.7," DATA-LAYER.md:320) does not say, and no test covers it.
- **Missing test for the score()-leak angle** identified in §3 — `test_traces_redact_held_out_on_solve_surface` (DATA-LAYER.md:339) only exercises the item-id redaction path, not the calibration-tuple content in `score()`.
- **The Langfuse-ships-ClickHouse note (DATA-LAYER.md:329)** is informational as stated, but under-specifies isolation: if one physical ClickHouse deployment is reused to "back both roles," the note does not say whether that means separate schemas/tables (preserving "AnalyticsStore is a projection... never a write path," DATA-LAYER.md:333) or a shared instance where Langfuse-native tables and Truth-rebuilt analytics tables could be conflated by an under-careful operator. Should be tightened to state the isolation explicitly (e.g., "distinct database/schema within the shared deployment") rather than left as a bare aside.
- No edge cases discussed for: `flush()` failing itself, backpressure/queue-depth bounds for the "emit-and-forget" buffer (an unbounded internal queue under sustained backend failure could itself become a resource leak — not addressed, and not the same failure mode as "blocks the hot path").

### 8. Consistency

- The §11.3 → §5 cross-reference is factually inconsistent with §5's actual content (finding #1) — this is the sharpest concrete inconsistency in the document as submitted.
- Possible unreconciled duplication between §19.1's TruthStore-logged calibration tuple and `ObservabilityPort.score()`'s "gate decisions, calibration tuples" (DATA-LAYER.md:301) — the section doesn't say whether these are the same write reused, or two independent call sites recording overlapping information, which could produce two disagreeing accounts of the same gate decision for an auditor to reconcile.
- Everywhere else, §11 is internally consistent with §6 (rebuild block), §6.1 (exemption list), §7 (extras), and §1 (pointer line) — the four deltas the task brief named are each present, correctly worded, and correctly tagged "§11 delta."

### 9. Calibration / honesty

- Generally honest in scope-limiting language: "Never part of the default install" (DATA-LAYER.md:295, :339), "separately gated" (ALGORITHM-v0.2:632), explicit provenance citations rather than vague claims of best practice.
- One overclaim: "P1 across traces... The two-bundle wiring (§2.1) covers this" (DATA-LAYER.md:335) states a guarantee that, per finding #1 in Correctness, is not actually derived for the content type (`score()` calibration tuples) the section itself says exists. Stating "covers this" as settled, when the redaction rule for that content type is unspecified, overstates what the design currently guarantees. This is the main honesty ding; everything else in the section is appropriately hedged (e.g., "informational" framing of the Langfuse/ClickHouse note, explicit "opt-in" framing throughout).

## Strongest adversarial objection

The section's single strongest vulnerability is not any of the nine dimensions taken individually but their **compound**: §11 defines an emit-and-forget channel whose own documentation (§11.1) says it carries JUDGE-internal calibration signal ("gate decisions, calibration tuples"), cites a redaction guarantee (§11.4) that was built for a structurally different content type (item identifiers, not numeric gate state) and therefore does not actually apply, and backs the embedded implementation with a schema reference (§11.3 → §5) that does not exist in the artifact. Put together: **a developer implementing this section exactly as written would ship a channel that leaks gate-strictness information to any SOLVE-visible surface, believe (on the strength of §11.4's prose) that P1 already covers it, and have no schema to consult that would have forced them to think concretely about what fields a `score` row actually contains and who can read them.** Each gap is individually fixable and none breaks an existing hard invariant outright, but the three compound into exactly the failure category (§17.1's own words) the document elsewhere takes seriously and explicitly analyzes for `TruthStore` reads — and here does not.

## Aggregate confidence

```
critical_floor  = min(Correctness=65, RedTeam=52, Safety=72) = 52
weighted_mean   = (65*2 + 80 + 52*2 + 60 + 72*2 + 85 + 55 + 62 + 78) / 11
                = (130 + 80 + 104 + 60 + 144 + 85 + 55 + 62 + 78) / 11
                = 798 / 11
                = 72.5 → 73
overall         = min(52, 73) = 52
```

**Overall confidence: 52 / 100**

## Verdict

**needs-revision**

Specific blocking changes required to clear 80 (and to clear the 70 CRITICAL floor on Red-team resistance and Correctness):

1. Add the missing §5 schema delta for `trace`/`score` event rows (concrete columns/fields, matching the pattern already used for every other admin event kind in §5), and fix or delete the dangling §11.3 citation that currently points at content §5 does not contain.
2. Specify an explicit redaction/visibility rule for `ObservabilityPort.score()` payloads that carry JUDGE-internal content (gate decisions, calibration tuples, knob state) on any SOLVE-visible surface — port the same read-side analysis §6.1 already performs for the unredacted `TruthStore` handle (a redaction rule and/or a static check that no SOLVE-visible bundle's `ObservabilityPort` surfaces `score` calls whose `name` identifies §19 gate-internal signals) — and add a test for it (the current `test_traces_redact_held_out_on_solve_surface` covers only item-id redaction, not this).
3. Either specify how the `trace`/`score` "spans" holds-category is actually captured through the two-method port (e.g., `trace(kind="span", ...)`) or add a dedicated method — the current draft names spans as held data with no corresponding write path.
4. Add a test (or an explicit statement of mechanism) for the "counted" half of invariant 2 — that emit-failure counting happens outside the port itself (avoiding the counter's-own-emit-fails recursion) and that the count is actually surfaced via §20.7, not merely asserted in prose.
5. Resolve whether `ObservabilityPort.score()`'s logging of gate/calibration tuples is the same write as §19.1's TruthStore logging or a second, independent one — state which, to close the duplicate-bookkeeping ambiguity noted under Consistency.
