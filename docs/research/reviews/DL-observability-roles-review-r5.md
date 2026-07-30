# 360 Review: DL-observability-roles — 2026-07-30 (Round 5)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §11 "revised r5 — IN GATE" (+ anchored deltas: §1 pointer, §2.1 bundle composition, §5 schemas, §6 rebuild line, §6.1 exemption list, §7 extras) |
| Proposed change | Round-5 revision closing r4's two remaining narrow gaps: (1) names the model-call-span mechanism — SOLVE makes model calls only through a JUDGE-composed, SOLVE-unswappable inference client the orchestrator hands it (mirroring the `Stores`-bundle DI pattern), with `kind=span` rows emitted transport-side and a new regression test; (2) states and tests that the composition-level exclusion and the admission-time import-ban covering the observability/analytics backing are stage-independent (Stage-1 sandbox and live Stage-2-promoted SOLVE alike) |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Round | 5 (r5) |
| Prior reviews | `docs/research/reviews/DL-observability-roles-review.md` (round 1 — 52, needs-revision); `docs/research/reviews/DL-observability-roles-review-r2.md` (round 2 — 60, needs-revision); `docs/research/reviews/DL-observability-roles-review-r3.md` (round 3 — 58, needs-revision); `docs/research/reviews/DL-observability-roles-review-r4.md` (round 4 — 76, needs-revision) |
| Circuit-breaker | `agents.status = "open"` (`.claude/memory/circuit-breaker.json`) — filed as a direct review, not a proposal |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 79 | weak |
| 2 | Design faithfulness | 83 | pass |
| 3 | Red-team resistance (CRITICAL) | 78 | weak |
| 4 | Implementability | 74 | weak |
| 5 | Safety / integrity (CRITICAL) | 84 | pass |
| 6 | Efficiency / cost | 88 | pass |
| 7 | Completeness | 74 | weak |
| 8 | Consistency | 79 | weak |
| 9 | Calibration / honesty | 76 | weak |

## Round 1–4 item closure ledger (audited fresh against the r5 text)

### Round-1 items (5 blocking + 1 non-blocking)

| Item | Status through r4 | Status at r5 | Evidence |
|---|---|---|---|
| (1) Dangling §5 citation | Closed | **Still closed** | DATA-LAYER.md:145 carries the row shape; §11.3 (DATA-LAYER.md:327) cites it correctly. |
| (2) RC-2 side channel via `score()` | Closed (by retraction, r4) | **Still closed** | Solve bundle carries no `ObservabilityPort` at all (DATA-LAYER.md:95, :319) — no emit surface exists to reach. |
| (3) "Spans" phantom concept | Closed | **Still closed** | `kind ∈ dispatch\|span\|cycle\|delivery` (DATA-LAYER.md:145, :301). |
| (4) Untested "counted" half of invariant 2 | Closed | **Still closed** | `test_emit_failures_counted_and_surfaced` (DATA-LAYER.md:342), unchanged. |
| (5) §19.1-tuple vs `score()` duplication | Closed | **Still closed** | Canonical-record rule (DATA-LAYER.md:330), unchanged. |
| (6, non-blocking) Langfuse/ClickHouse isolation | Closed | **Still closed** | "separate databases/schemas" (DATA-LAYER.md:330), unchanged. |

### Round-2 items (5 blocking)

| Item | Status through r4 | Status at r5 | Evidence |
|---|---|---|---|
| (1) Extend read-closure `score()`→`AnalyticsStore` | Closed by retraction (r4) | **Still closed** | `test_solve_bundle_has_no_observability_or_analytics` (DATA-LAYER.md:342). |
| (2) State reachability of embedded physical backing from the Stage-1 sandbox | Closed for Stage-1 only (r3/r4) | **Now closed for all stages, explicitly** | "SOLVE code has no read path... **at any stage (r5)**" (DATA-LAYER.md:319); `test_solve_cannot_read_observability_backing_any_stage` (DATA-LAYER.md:342). |
| (3) Resolve "JUDGE-emitted" tension | Moot, closed by retraction (r4) | **Still closed** | "All observability is JUDGE-authored; SOLVE emits nothing" (DATA-LAYER.md:319). |
| (4) Name concrete `Bundles`/`Stores` field(s) | Closed for `ObservabilityPort`/`AnalyticsStore` (r4) | **Closed for those two fields; a structurally identical gap reopens for the new `r5` object** | DATA-LAYER.md:95 still names `observability`/`analytics` fields. But the r5-introduced "JUDGE-composed inference client" (DATA-LAYER.md:319) has **no field name anywhere** — not on `Stores` (DATA-LAYER.md:53-93, unchanged), not on `Bundles`, not as a separate construct. See Implementability/Correctness findings below — this is the same category of gap round 2/3 raised and round 4 fixed for a different pair of objects, now recurring for a third. |
| (5) Soften "closes the RC-2-shaped side-channel" overclaim | Closed (r4) | **Still closed** | Honest-scope note (DATA-LAYER.md:319, "stronger than §6.1's TruthStore treatment... not merely parallel"). |

### Round-3 items (5 blocking)

| Item | Status through r4 | Status at r5 | Evidence |
|---|---|---|---|
| (1) State/test write-mediation mechanism for SOLVE-side `trace()` | Closed by retraction (r4) | **Still closed** | No SOLVE emit path exists (DATA-LAYER.md:319a). |
| (2) Extend reachability statement to live (Stage-2) SOLVE code | Closed in substance, not stated explicitly (r4) | **Now closed explicitly** | Same evidence as round-2 item (2) above — this was r4's own item 3 (below), and it is now done. |
| (3) Name concrete `Bundles`/`Stores` fields | Closed (r4) | **Closed for the original two fields; reopens for the new inference-client object** (see round-2 item 4). |
| (4) Correct/scope "same three-surface treatment §6.1 gave TruthStore" claim | Closed (r4) | **Still closed** | DATA-LAYER.md:319c, unchanged. |
| (5) Add BUILD-SPECS.md companion entry for AUT-2 | Closed by explicit, verified precedent argument (r4) | **Still closed** | DATA-LAYER.md:338; re-verified by direct grep of BUILD-SPECS.md for `AUT-2`/`ObservabilityPort`/`AnalyticsStore`/`6.1`/`6.2` — the precedent (§6.1/§6.2 carry no BUILD-SPECS item either) still holds. |

### Round-4 items (3 blocking — this round's starting point)

| Item | r5 disposition | Evidence / assessment |
|---|---|---|
| (1) State the model-call-span capture mechanism explicitly, same rigor as `Stores` | **Closed for the mechanism; a new, narrower implementability/correctness gap opens on the *plug-point* and the *stage scope* of its supporting claim** | DATA-LAYER.md:319: "SOLVE makes model calls only through the **JUDGE-composed inference client** the orchestrator hands it — the same pattern as the `Stores` bundle... a SOLVE-unswappable object, wired outside every SOLVE-editable surface," plus `test_spans_captured_transport_side` (DATA-LAYER.md:342). This is real, substantive progress — round 4's central "no mechanism at all" gap is gone. But: (a) no field/attribute name is given for this object anywhere (§2.1's code block, DATA-LAYER.md:53-93, is unchanged — no `inference_client`/`ModelClient` port appears), so "the same rigor §2.1 gives the `Stores` bundle" is *claimed* but not *delivered* — a developer still has nothing concrete to add to a dataclass; (b) the supporting clause "the §17.3 sandbox permits no alternative egress" is not established by the section it cites — see Correctness below. |
| (2) Add a test/statement that `self_modify` cannot silence its own span emission via tool-wiring edit | **Closed** | `test_spans_captured_transport_side` (DATA-LAYER.md:342): "a SOLVE component cannot issue a model call that produces no span — metering is in the JUDGE-composed client, not in SOLVE." Directly on-point, correctly targeted at this exact item. |
| (3) State explicitly that the composition-level exclusion and the admission-time import-ban are stage-independent | **Closed** | "at any stage (r5)" (DATA-LAYER.md:319c) + `test_solve_cannot_read_observability_backing_any_stage` (DATA-LAYER.md:342) — a direct, well-targeted closure, matching exactly what round 4 asked for. |

**Non-blocking, carried forward since round 1 (still open at r5, now a fifth consecutive round):** the `correlation_id` discriminator across `occurrence_id`/`checkpoint_id`/`schedule_id` remains unspecified; `rebuild_analytics`'s concrete semantics for SQLite-views-over-Truth remain unaddressed (DATA-LAYER.md:328, unchanged); no backpressure/queue-depth bound is stated for the emit-and-forget buffer.

**Ledger summary:** every one of rounds 1–3's blocking items remains closed (nothing regressed), and two of round 4's three items are cleanly and concretely closed. The third (the model-call-span mechanism) is genuinely closed *as a mechanism* — this is real, substantive progress on the item that has been open since round 1 in one form or another — but the closure text introduces a new, narrower instance of the exact compounding pattern every round of this gate has produced: a claim stated more broadly than what its cited support actually establishes. See Correctness/Red-team below.

## Findings by dimension

### 1. Correctness

- The round-4 defect (no stated mechanism for how `kind=span` model-call data gets captured "from the outside") is resolved with a real, coherent design move: SOLVE's mutable tool-wiring decides *which* calls to make, but the object that actually executes a model call is a JUDGE-composed, SOLVE-unswappable client (DATA-LAYER.md:319) — the identical DI idiom §2.1 already uses for `Stores` (SOLVE picks *what* to ask; it never controls *who answers*). This is a genuine, checkable correctness improvement over r4, where the claim "observes... tool call... from the outside" had no supporting mechanism at all.
- **A new, narrower correctness gap: the clause supporting this closure over-cites its authority.** DATA-LAYER.md:319 states: "the inference *transport* is harness, and the §17.3 sandbox permits no alternative egress." Checked against the cited source — ALGORITHM-v0.2:464 (§17.3 Stage 1): "The candidate SOLVE runs in a **sandbox** (isolated subprocess, **no write access outside SOLVE**)..." — §17.3 states a **filesystem-write** restriction. It says nothing about network egress, and "isolated subprocess" alone does not entail a network-egress restriction (an isolated *process* and a network-*isolated* process are different properties; the text conflates them here). This is not a hypothetical nitpick: the very same paragraph, one clause earlier, shows the authors know the difference and flag it explicitly when they extend §17.3's stated scope — "(c) backing files — ... §17.3's 'no write access outside SOLVE' **extended explicitly**: no read access to JUDGE data dirs" (DATA-LAYER.md:319c). That extension is flagged as an extension. The egress claim is not; it is asserted as though already established by §17.3, when it is not stated there at all. Verified against the full §17.3 text (ALGORITHM-v0.2:462-465) and against `ALGORITHM-INTEGRATIONS.md`/`BUILD-SPECS.md` (grepped for `egress`/`network`/`sandbox` — no hit anywhere in the corpus establishing a network-isolation property for the Stage-1 sandbox).
- **A second, related gap: even taken at face value, the "no alternative egress" claim is scoped only to "the §17.3 sandbox" — i.e., the Stage-1 shadow-trial population — and says nothing about live, Stage-2-promoted SOLVE**, which is the population that actually issues the model calls `kind=span` is meant to observe in ordinary operation (per §11.1's own consumer framing, DATA-LAYER.md:301). This is the mirror image of the gap round 4's item (3) closed for the *file-read* path (which r5 correctly generalized to "any stage") — but for the *model-call-egress* path, no equivalent stage-generalization is stated or tested. A `self_modify` candidate that has already cleared Stage-1 and gone live (§17.3 Stage 2, ALGORITHM-v0.2:465, "the candidate replaces the running SOLVE") is not analyzed here at all for whether it retains, or could newly acquire via a `FIX`/`DERIVE` edit (§17.6), an ordinary static `import` of a raw external model-provider SDK that bypasses the JUDGE-composed client entirely. Such an import is neither reflection, `eval`, nor dynamic import, so it does not trip §17.1's decidable-ban clause (ALGORITHM-v0.2:457) — the same category of hole rounds 2/3 found for the `TruthStore`/`AnalyticsStore` adapters, for which this document *did* eventually add a named, explicit import-ban (DATA-LAYER.md:319b: "the M3 admission import-check... bans the analytics and observability adapters identically"). No analogous import-ban is stated for a raw inference-SDK import.
- No arithmetic/formula defects found in §11 itself (unchanged across all five rounds — the section contains no inequalities of its own).

### 2. Design faithfulness

- The JUDGE-composed inference-client design is the *right* kind of fix: it reuses, rather than invents, the established ports-and-adapters idiom the document already applies to `Stores` (§2.1) — SOLVE's mutable surface picks parameters, a JUDGE-wired object executes. This is a faithful extension of an existing, proven pattern, not a new primitive.
- **The one faithfulness gap**: the pattern is described in prose but never actually instantiated in the artifact's own code the way `Stores`/`Bundles` is (DATA-LAYER.md:53-93, unchanged). A developer reading §2.1 literally has six ports plus the two r4-added optional fields (`observability`, `analytics`) to build against — and nothing for the object §11.2 now calls "the JUDGE-composed inference client." The document has the right idiom and simply doesn't extend it, in code, to this third object — the same shape of gap r4 itself flagged for the *concept* of a model-call mechanism, now recurring one layer down for its *wiring*.
- BUILD-SPECS.md scope note (DATA-LAYER.md:338) remains faithful to the verified §6.1/§6.2 precedent — unchanged from r4, still accurate.

### 3. Red-team resistance

- **Genuine, verified progress: the A2-shaped gap r4 found (a `self_modify` candidate silencing its own span emission via an ordinary tool-wiring edit) is closed, concretely.** `test_spans_captured_transport_side` (DATA-LAYER.md:342) directly targets this: metering lives in the transport, not in SOLVE's own code, so editing tool-wiring changes *which* calls are made but not *whether* they are metered. This is the correct fix, and it closes exactly the residual r4's adversarial pass identified.
- **A new, narrower instance of the same root-cause family (RC-2 / A2: an unmetered, unobserved execution surface) opens on an adjacent path the fix does not cover: a direct import of an external model-provider SDK, bypassing the JUDGE-composed client entirely.** As detailed under Correctness: (a) the claim that the Stage-1 sandbox blocks "alternative egress" is not supported by §17.3's actual text (a filesystem-write restriction, not a network restriction); (b) even if it were, the claim is scoped to Stage-1 only, and live/Stage-2-promoted SOLVE — which is the population that actually makes the model calls this section exists to observe — has no stated or tested restriction against importing a raw inference client directly. A `self_modify` `FIX`/`DERIVE` candidate that does this would make model calls that produce **no span at all**, not a silenced one — the identical failure mode (`STUDY-automaton-autonomy.md` A2: "a stuck agent that looks alive," or here, an agent whose spend/behavior is invisible to the audit trail) this section's own header cites as its reason for existing, reached by a different, unaddressed door.
- **Severity call, per the agent's own rubric** ("score 0 if it reopens a known failure mode; score based on residual attack surface otherwise"): this does **not** reopen any of rounds 1–4's closed findings (the `score()`/`AnalyticsStore` read-oracle, the file-write-mediation question, and the tool-wiring-silencing vector are all genuinely, verifiably closed). It is a fresh, narrower, adjacent instance of the same root cause, gated — like rounds 2/3's analogous findings — on `self_modify`/M3 not yet being built (a design-time gap, not a live exploit today), and on an as-yet-unbuilt raw-SDK import actually being reachable in the eventual implementation. That keeps it out of the 0 band and in the "residual attack surface, weak-but-fixable" band — materially narrower in scope than any of rounds 1–3's central findings (it is one un-generalized clause about one execution surface, not a whole read/write/query mechanism), but real and concrete.

### 4. Implementability

- The two genuine implementability gaps r4 flagged are both closed: `test_spans_captured_transport_side` gives a developer a concrete, testable acceptance criterion for the metering guarantee, and the stage-independence statement (r5) removes the ambiguity about whether Stage-2-promoted code is covered for the *read*-path guarantees.
- **New implementability gap, in the same category as round 2/3's `Bundles`/`Stores`-field gap (closed there, reopened here for a new object): no field, attribute, or wiring point is named for "the JUDGE-composed inference client."** Is it a new field on `Stores`? A parameter passed to `EvolutionLoop`/`Retriever` alongside `bundles` (§8, DATA-LAYER.md:260-268)? A wrapper the orchestrator injects into SOLVE's tool-wiring config at dispatch time? The document gives a developer the *policy* ("SOLVE-unswappable, wired outside every SOLVE-editable surface") without the *mechanism name* the way it does for `observability`/`analytics` (DATA-LAYER.md:95: "`Stores` gains two optional fields..."). A literal implementation of §11 as written has no concrete place to hang this object.
- **A second new implementability gap: no specification of what happens to non-model-call tool invocations** (e.g., a store `retrieve()` call, or a future tool SOLVE's tool-wiring might invoke) with respect to the "transport-side" metering guarantee — the fix is scoped explicitly to "model calls"; whether other externally-observable SOLVE actions get the same JUDGE-composed-wrapper treatment, or remain unmetered by design, is not stated. (Narrower and non-blocking relative to the model-call gap above, but worth flagging since §11.1's own table lists "traces — one per §6.1 `dispatch`" as a *separate*, already-covered content type — so this is specifically about any *other* tool call a future `self_modify` candidate's tool-wiring might add.)
- All other implementability items from rounds 1–3 (the `correlation_id` discriminator; `rebuild_analytics`'s concrete SQLite-view-rebuild semantics; a backpressure/queue-depth bound) remain untouched in r5 — expected, since none were on any round's blocking list, but now carried for a fifth consecutive round without comment.

### 5. Safety / integrity

- No *existing* gate, the §14 calibration layer, or a verifier constraint (`HUMAN-LEARNING-VERIFIER.md`) is weakened or edited by §11 as revised — consistent with all four prior rounds.
- **The round-4 safety-relevant question (does the observability substrate's own design create a new hazard, or does it merely fail to close one?) is answered the same way as before: this round's residual gap does not loosen any *stated* invariant's math.** §17.1's wall invariant (ALGORITHM-v0.2:457) and §19.4's "JUDGE, not SOLVE" clamp (ALGORITHM-v0.2:572) are both untouched by the residual raw-SDK-import gap identified above — a bypass of *metering* is not a bypass of the *gate*; the §8/§19 statistical clauses that actually decide whether a change is admitted never depend on span data. This is why the finding is scored in Red-team/Completeness/Calibration territory more than Safety, matching the pattern the last two rounds established for structurally analogous residuals.
- **This round's residual is, if anything, less safety-relevant than r3's (the file-write-mediation question, since resolved) or r4's (the wholly-unspecified tool-call mechanism, since resolved), because — per the artifact's own §20.6/§20.7 text, restated again in this round's fix (DATA-LAYER.md:319) — none of the hard liveness/failure-delivery guarantees depend on span-level data**; they depend on work-unit/dispatch-level Truth rows, which remain fully JUDGE-observed and are not implicated by anything found this round. The consequence of the residual gap, if it were ever exploited, is a **degraded audit trail** (an unmetered execution surface), not a corrupted gate decision or a defeated safety floor.
- Scored 84: a modest, genuine improvement over r4's 82, reflecting that the section's core safety claim — "gate-posture content and now model-call metering are JUDGE-only, on every surface that matters to §20's actual liveness/safety detectors" — is more completely and more concretely true this round than last, even though one narrower audit-fidelity question remains open.

### 6. Efficiency / cost

- Unchanged in kind from rounds 1–4 (all scored 85–88): cold-path, emit-and-forget, no new synchronous LLM calls, no O(n²) additions. The r5 addition (a JUDGE-composed inference-client wrapper around model calls) is, at most, O(1) per call — a thin instrumentation wrapper, not an algorithmic change.
- No new cost concern introduced by the stage-independence generalization (a statement/test change, not a runtime cost change).

### 7. Completeness

- Round 1–4's concrete test gaps are now all closed: `test_solve_bundle_has_no_observability_or_analytics`, `test_all_observability_rows_judge_authored`, `test_solve_cannot_read_observability_backing_any_stage`, `test_spans_captured_transport_side`, `test_digest_redacts_held_out` (DATA-LAYER.md:342) directly regress every closed item in the ledger above.
- **New completeness gap, mirroring Correctness/Red-team above: no test exercises the raw-SDK-import bypass on live/Stage-2-promoted SOLVE.** Nothing in §11.5 resembles `test_solve_candidate_cannot_import_raw_inference_client` or `test_promoted_solve_cannot_bypass_metered_transport` — the existing test (`test_spans_captured_transport_side`) checks that a call made *through the harness* is metered; it does not check that a call made *around* the harness is impossible or is itself caught at admission.
- **A second, narrower completeness gap**: no test or design stub addresses the field/wiring name for the JUDGE-composed inference client (Implementability, above) — there is nothing analogous to a schema/dataclass acceptance test the way `test_solve_bundle_has_no_observability_or_analytics` exists for the `observability`/`analytics` fields.
- Round 1–4's non-blocking carried items (the `correlation_id` discriminator; `rebuild_analytics`'s SQLite-view semantics; the emit-and-forget backpressure bound) remain open, now for a fifth round.

### 8. Consistency

- **No dangling references to any retracted or superseded prior-round design were found.** Grepped the full artifact for r2/r3-era language (`trace-only`, `score_raises`, `has_no_analytics`, "either side") — all absent; current terms (`test_solve_bundle_has_no_observability_or_analytics`, "all rows JUDGE-emitted," "at any stage (r5)") are used consistently at every anchor point.
- **New inconsistency: the "no alternative egress" clause (DATA-LAYER.md:319) is inconsistent with what §17.3 actually says (ALGORITHM-v0.2:462-465), and inconsistent in *treatment* with the adjacent clause in the same sentence, which correctly flags itself as an extension of §17.3's stated scope.** This is a textual tension between DATA-LAYER §11 and the ALGORITHM section it cites as authority, of the same *kind* as round 1's dangling §5 citation (a citation asked to support more than it contains) though far narrower in blast radius (one clause, not a missing schema).
- Otherwise §11 remains internally consistent with §6 (rebuild line, DATA-LAYER.md:162), §6.1 (exemption list, DATA-LAYER.md:188), §7 (extras, DATA-LAYER.md:248-249), §1 (pointer, DATA-LAYER.md:22), and the §2.1 bundle-composition delta — all six anchored deltas are present, mutually consistent, and correctly cross-referenced.

### 9. Calibration / honesty

- Genuine honesty improvements are carried and reconfirmed from r4: the "stronger than §6.1... not merely parallel" scoping and the register-scope precedent argument both remain scoped claims that hold up to direct checking (re-verified this round).
- **A smaller instance of the identical overclaim pattern every round of this gate has produced recurs once more, at a narrower scope than r4's.** The clause "the §17.3 sandbox permits no alternative egress" states, as settled fact, a property §17.3 does not establish (Correctness, above) — and does so without the hedging discipline the very same paragraph demonstrates one clause earlier ("extended explicitly," DATA-LAYER.md:319c) when it knowingly stretches §17.3's stated scope. The gap here is that the same care was not applied to the egress claim: it is presented as already-true rather than as an explicit, flagged extension (or, if genuinely uncertain, an open design question). This is materially smaller than rounds 1–3's overclaims (one clause, one sentence, not a whole surface's closure) and smaller even than r4's (which was about an entire missing mechanism) — but it is the same category of gap, appearing for a fifth consecutive round in a progressively narrower place, which is itself worth naming as a pattern: this document's authoring voice reliably closes the *loudest* open question each round while introducing one quieter one nearby.
- Everything else is appropriately hedged: "never part of the default install" (DATA-LAYER.md:295, unchanged), the canonical-record rule's "disposable" framing (DATA-LAYER.md:330, unchanged), "Honest bound, unchanged" for the §20.6/§20.7 liveness-signal scoping (DATA-LAYER.md:319, carried and correctly repeated this round).

## Strongest adversarial objection

Every one of rounds 1–4's central findings is, on fresh and direct inspection, genuinely closed — I could not reopen any of them. The retraction (r4) and its stage-generalization (r5) are structurally sound, and the model-call-span mechanism r4 asked for is, for the first time across five rounds, actually named. The strongest remaining objection is the one this round's own fix quietly invites: **the fix names a mechanism (a JUDGE-composed, SOLVE-unswappable inference client) and then defends its completeness with a clause that oversells its own cited authority and under-scopes its own claim.** Concretely: §11.2 (DATA-LAYER.md:319) supports "no alternative egress" by pointing at "the §17.3 sandbox" — but §17.3 (ALGORITHM-v0.2:462-465) says nothing about network egress, only about filesystem write access, and the claim is in any case scoped to the Stage-1 shadow-trial population, never to the live, Stage-2-promoted SOLVE code that actually does the ordinary, continuous work `kind=span` exists to observe. **A developer implementing §11 exactly as written, and passing every listed §11.5 test — including the new `test_spans_captured_transport_side` — could still ship a live, promoted `self_modify` candidate that imports a raw external model-provider SDK directly, bypasses the JUDGE-composed client entirely, and makes model calls that produce no span at all** — not a silenced signal, an absent one, through a door (an ordinary static import, per §17.1's decidable-ban scope) this design has already, elsewhere, had to close explicitly for two other adapter classes (`TruthStore`, `AnalyticsStore`) and has not closed here. This is precisely the A2 failure mode (`STUDY-automaton-autonomy.md`: "shipped autonomy without working observability, so a stuck agent looks alive") this section's header cites as its reason for existing — reached, this time, through the one execution surface the fix's own supporting clause claims to have covered but does not. As with every prior round's residual, this does not touch any §20 liveness-critical detector (those remain dispatch/outcome-level and fully JUDGE-observed) — it is an audit-fidelity gap, not a safety-floor break — but it is real, on-topic, and, notably, the fifth consecutive round in which this exact review has found a version of the same underlying pattern: the loudest open question closes; a quieter one, one layer further out, opens in its place.

## Aggregate confidence

```
critical_floor  = min(Correctness=79, RedTeam=78, Safety=84) = 78
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                    + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (79*2 + 83 + 78*2 + 74 + 84*2 + 88 + 74 + 79 + 76) / 11
                = (158 + 83 + 156 + 74 + 168 + 88 + 74 + 79 + 76) / 11
                = 956 / 11
                = 86.9 → 87
overall         = min(78, 87) = 78
```

**Overall confidence: 78 / 100**

(Round 1 was 52; round 2 was 60; round 3 was 58; round 4 was 76; this round is 78 — a further, genuine improvement, reflecting verified closure of all three of round 4's blocking items, two of them cleanly. The score stays below 80 because the round's own central fix — naming the model-call-span mechanism — introduces one narrower, previously-unexamined gap of the same shape rounds 1–4 each found in turn: a supporting clause ("no alternative egress") that overclaims relative to what its cited source (§17.3) actually establishes, and under-scopes relative to the population (live, Stage-2-promoted SOLVE) that actually needs the guarantee.)

## Verdict

**needs-revision**

Specific blocking changes required to clear 80:

1. **Correct or substantiate the "no alternative egress" claim.** Either (a) cite an actual network-isolation property of the Stage-1 sandbox if one is intended (and, per this document's own established discipline elsewhere in the same paragraph, flag it explicitly as an extension of §17.3's stated scope — "no write access outside SOLVE" is a filesystem property; a network-egress restriction is a distinct property that ALGORITHM-v0.2:462-465 does not state), or (b) drop the claim and instead specify a **static import-level ban on raw model-provider SDK imports** for any `self_modify` candidate — mirroring the existing, named bans for the unredacted `TruthStore` and `AnalyticsStore` adapters (DATA-LAYER.md:319b) — with a corresponding test (e.g. `test_solve_candidate_cannot_import_raw_inference_client`).
2. **Extend the metering guarantee explicitly to live, Stage-2-promoted SOLVE, not only the Stage-1 sandbox population.** State plainly whether a promoted `self_modify` candidate's tool-wiring can, by any code path, reach an inference call that bypasses the JUDGE-composed client, and add a test that exercises the *promoted* population specifically (the existing `test_spans_captured_transport_side` does not state which population it covers).
3. **Name the concrete field/wiring point for the JUDGE-composed inference client**, with the same rigor §2.1 gives the `observability`/`analytics` fields (DATA-LAYER.md:95) — a developer needs an attribute name or an explicit construction-time wiring statement, not only the policy prose currently given.

Non-blocking, carried forward from rounds 1–4 (not required to clear 80, but now open for a fifth consecutive round): the `correlation_id` discriminator across `occurrence_id`/`checkpoint_id`/`schedule_id` remains unspecified; `rebuild_analytics`'s concrete semantics for SQLite-views-over-Truth remain unaddressed; no backpressure/queue-depth bound is stated for the emit-and-forget buffer; whether non-model-call tool invocations get the same JUDGE-composed-wrapper treatment as model calls is unstated (narrower, non-blocking relative to item 1/2 above).
