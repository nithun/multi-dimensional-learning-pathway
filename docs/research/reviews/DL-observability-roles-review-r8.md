# 360 Review: DL-observability-roles — 2026-07-30 (Round 8)

| Field | Value |
|---|---|
| Artifact | `docs/research/DATA-LAYER.md` §11 "revised r8 — IN GATE" (+ anchored deltas: §1 pointer, §2.1 bundle composition, §5 schemas, §6 rebuild line, §6.1 exemption list, §7 extras) |
| Proposed change | Round-8 revision closing all three of r7's numbered blocking items: (1) the JUDGE-side inference broker is now a **named JUDGE member** — "§17.1's wall extends to it exactly as §20.8 extended it to the supervisor shell," running in the JUDGE address space and inheriting the M3 separate-address-space runtime backstop; (2) the "authenticated local channel" is now a **named mechanism** — Unix-domain socket + OS peer-credential verification + a per-session, constant-time-compared token, cited to `STUDY-hermes-agent.md` §5's PTC channel — with granularity honestly stated as **process-level** (an access-control statement only; metering remains unconditional at the broker); (3) `InferenceClient` gets a full **Protocol** in §11.2 — `complete(model, request)`, where `model` is a key into a JUDGE-configured provider registry, never a URL/endpoint, backed by `test_broker_relays_only_to_registered_providers`. Also closes three of the seven-round non-blocking carries (typed `correlation_id` discriminator; the `B_obs` emit-buffer backpressure bound + `test_emit_buffer_bounded_drops_counted`; `test_stores_inference_shape_both_bundles`) and adds one clarifying clause to `rebuild_analytics`'s embedded semantics. |
| Reviewer | review-360 |
| Date | 2026-07-30 |
| Round | 8 (r8) |
| Prior reviews | `docs/research/reviews/DL-observability-roles-review.md` (round 1 — 52, needs-revision); `-r2.md` (round 2 — 60, needs-revision); `-r3.md` (round 3 — 58, needs-revision); `-r4.md` (round 4 — 76, needs-revision); `-r5.md` (round 5 — 78, needs-revision); `-r6.md` (round 6 — 79, needs-revision); `-r7.md` (round 7 — 78, needs-revision) |
| Circuit-breaker | `agents.status = "open"` (`.claude/memory/circuit-breaker.json`) — filed as a direct review, not a proposal |

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 85 | pass |
| 2 | Design faithfulness | 87 | pass |
| 3 | Red-team resistance (CRITICAL) | 83 | pass |
| 4 | Implementability | 81 | pass |
| 5 | Safety / integrity (CRITICAL) | 87 | pass |
| 6 | Efficiency / cost | 86 | pass |
| 7 | Completeness | 81 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 78 | weak |

## Full round 1–7 item closure ledger (audited fresh against the r8 text — every item enumerated, none silently dropped)

### Round-1 items (5 blocking + 1 non-blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) Dangling §5 citation | Still closed | **Still closed** | DATA-LAYER.md:145 row shape; §11.3 (:327/:334) cites it correctly. |
| (2) RC-2 side channel via `score()` | Still closed | **Still closed** | Solve bundle carries no `ObservabilityPort` (:95, :326). |
| (3) "Spans" phantom concept | Still closed | **Still closed** | `kind ∈ dispatch\|span\|cycle\|delivery` (:145, :301). |
| (4) Untested "counted" half of invariant 2 | Still closed | **Still closed** | `test_emit_failures_counted_and_surfaced` (:349), unchanged. |
| (5) §19.1-tuple vs `score()` duplication | Still closed | **Still closed** | Canonical-record rule (:337), unchanged. |
| (6, non-blocking) Langfuse/ClickHouse isolation | Still closed | **Still closed** | "separate databases/schemas" (:337), unchanged. |

### Round-2 items (5 blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) Extend read-closure `score()`→`AnalyticsStore` | Still closed | **Still closed** | `test_solve_bundle_has_no_observability_or_analytics` (:349). |
| (2) State reachability of embedded physical backing from Stage-1 sandbox | Still closed | **Still closed** | "at any stage (r5)" (:326); unchanged. |
| (3) Resolve "JUDGE-emitted" tension | Still closed | **Still closed** | "All observability is JUDGE-authored; SOLVE emits nothing" (:326). |
| (4) Name concrete `Bundles`/`Stores` field(s) | Closed at r7 (`Stores.inference`) | **Still closed, further hardened** | `Stores.inference: InferenceClient` (:95) now has a full `Protocol` (:312–317) and a schema/dataclass test (:349) — see round-5/6 item below. |
| (5) Soften "closes the RC-2-shaped side-channel" overclaim | Still closed | **Still closed for this instance; a related, narrower overclaim reopens elsewhere this round** — see Calibration below (the phrase "the open-relay/exfiltration path is closed by construction," :317). |

### Round-3 items (5 blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) State/test write-mediation mechanism for SOLVE-side `trace()` | Still closed | **Still closed** | No SOLVE emit path exists. |
| (2) Extend reachability statement to live (Stage-2) SOLVE | Closed for read/file surface (r5); recurred for egress (r5, r6); closed by credential custody (r7); **the r7-named residual (broker isolation, channel auth) is what r8 targets** | **Closed at r8** — see the "Round-7 items" table below; this is the fourth appearance of this exact recurring gap-shape, and this round is the first to close it without leaving an equally-deep successor in the same shot (a narrower, adjacent, lower-severity residual opens instead — see Strongest adversarial objection). | :326. |
| (3) Name concrete `Bundles`/`Stores` fields | Closed at r7 | **Still closed** | See round-2 item (4). |
| (4) Correct/scope "same three-surface treatment §6.1 gave TruthStore" claim | Still closed | **Still closed** | :326c, unchanged. |
| (5) Add BUILD-SPECS.md companion entry for AUT-2 | Closed by precedent argument (r4) | **Still closed; re-verified this round** | Grep of `BUILD-SPECS.md`/`ALGORITHM-INTEGRATIONS.md` for `AUT-2`/`ObservabilityPort`/`AnalyticsStore`/`InferenceClient`/`broker` returns nothing — the §6.1/§6.2 no-BUILD-SPECS-item precedent still holds, re-checked fresh. |

### Round-4 items (3 blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) State model-call-span capture mechanism | Progressively concretized r5→r7 | **Further hardened**: the mechanism now names the broker's JUDGE membership and the channel's authentication primitive on top of r7's credential-custody grounding | :326, `test_spans_captured_transport_side` unchanged. |
| (2) Test `self_modify` cannot silence its own span emission via tool-wiring edit | Still closed | **Still closed** | `test_spans_captured_transport_side` (:349), unchanged. |
| (3) State composition-level exclusion / import-ban are stage-independent | Still closed | **Still closed** | "at any stage (r5)" (:326c). |

### Round-5 items (3 blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) Correct or substantiate "no alternative egress" claim | Superseded/subsumed at r7 | **Still superseded** — credential custody remains the primary mechanism; egress denial remains explicit defense-in-depth (:326). | :326. |
| (2) Extend metering guarantee to live, Stage-2-promoted SOLVE | Closed more strongly at r7 (import-shape-agnostic) | **Still closed, unchanged in kind** | :326. |
| (3) Name the concrete field/wiring point for the inference client | Closed at r7 | **Still closed, now with a Protocol + test** | :95, :312–317, :349. |

### Round-6 items (3 blocking) — reconfirmed at r7, re-audited fresh this round

| Item | Status through r7 | Status at r8 | Evidence |
|---|---|---|---|
| (1) Name the concrete field/wiring point for the inference client | Closed at r7, but with no `Protocol` | **Now fully closed** — see the "Round-7 items" table, item (3), below. | :312–317. |
| (2) State the enforcement mechanism behind "deny network egress except the provided client" | Closed at r7 (credential custody) | **Still closed; its own foundation is what r8 additionally closes** — see below. | :326. |
| (3) Broaden the import-ban's scope / acknowledge the residual | Closed at r7 (import-shape-agnostic) | **Still closed** | :326. |

### Round-7 items (3 blocking — this round's starting point)

| Item | r8 disposition | Evidence / assessment |
|---|---|---|
| (1) State the JUDGE-side broker's own isolation guarantee explicitly, in the §20.8 style ("§17.1's wall extends to them") | **Closed, genuinely, and by exactly the remedy specified.** | DATA-LAYER.md:326: "**The broker is a named JUDGE member (r8):** §17.1's wall extends to it exactly as §20.8 extended it to the supervisor shell — it runs in the JUDGE address space alongside the orchestrator (and inherits §17.1's separate-address-space runtime backstop at M3); it is not a bare 'JUDGE-side' label but a component on the JUDGE enumeration, holding the credentials the whole design protects." This reuses the exact formula ALGORITHM-v0.2:641 (§20.8) used for its own new JUDGE-side components (supervisor shell, scheduler, watchdogs, delivery ledger), applied faithfully within DATA-LAYER's own text — the only channel available to it, since DATA-LAYER cannot itself edit ALGORITHM-v0.2.md (§11.4's "Register scope note" precedent). Because §17.1's runtime backstop is address-space-based rather than a fixed name-enumeration ("JUDGE runs in a separate address space with no SOLVE-held handle," ALGORITHM-v0.2:457), a component that is placed in that address space inherits the backstop mechanically, regardless of whether ALGORITHM-v0.2's own prose list (§17.1:455) is retroactively edited to name it — exactly the same situation §20.8's own new components were in before ALGORITHM-v0.2 itself chose to state the extension explicitly. This is a sound, faithful closure. |
| (2) Name the authentication mechanism for the "authenticated local channel," and state its granularity | **Closed for the *content* of the remedy (a named mechanism, an honest granularity statement); a citation-accuracy issue attaches to the specific mechanism's sourcing** — see Calibration below. | DATA-LAYER.md:326: "a Unix-domain socket with OS peer-credential verification plus a per-session token compared constant-time (the pattern production systems ship for exactly this — `STUDY-hermes-agent.md` §5's PTC channel); granularity is honestly **process-level** — it authenticates the sandboxed SOLVE process, not an in-process object, which is an access-control statement only: metering is unconditional at the broker regardless of which code in the SOLVE process called." The granularity honesty is exactly the remedy r7 asked for ("If the latter, state explicitly... that this is an access-control residual, not a metering one") — matched precisely, including the metering-vs-access-control distinction. The *sourcing* of the specific mechanism (peer-credential check + constant-time comparison) is less precise than claimed — see Correctness/Calibration. |
| (3) Define the `InferenceClient` `Protocol`; state whether the broker's relay destination is JUDGE-pinned or SOLVE-influenceable; add a corresponding test | **Closed, cleanly.** | DATA-LAYER.md:312–317: a full `Protocol` — `complete(self, model: str, request: dict) -> dict`, with an inline comment stating `model` "is a key into the JUDGE-configured provider REGISTRY — never a URL/endpoint: the broker resolves it against its own registry and relays nowhere else... Destination is JUDGE-pinned, not SOLVE-suppliable." `test_broker_relays_only_to_registered_providers` (:349) is added, mirroring `test_solve_process_holds_no_provider_credentials` exactly as the r7 verdict specified. This closes the open-relay/destination-arbitrary-endpoint risk r7's Red-team finding raised. A narrower residual remains — the registry's own concrete schema/config location is unstated (no `mdlp.toml` block, no `§5`/`§7` entry for it) — see Implementability. |

**Ledger summary:** every item from rounds 1–6 remains closed on fresh, direct verification — I could not reopen any of them. All three of round 7's blocking items are genuinely closed this round, and — for the first time in this gate's eight-round history — the closure does not leave an equally-deep successor gap of the *same* shape (the recurring "the foundation of the fix is itself unstated" pattern that reopened in rounds 3–7). What opens in its place this round is different in kind: (a) a **citation-accuracy issue** — the hermes study cited for the channel-authentication mechanism supports a narrower claim than the one attributed to it (Calibration/Correctness); (b) a **phrasing overclaim** — "the open-relay/exfiltration path is closed by construction" (:317) is true for attacker-controlled destinations but not for content-borne exfiltration to a legitimate, registered provider (Strongest adversarial objection); (c) minor implementability gaps (provider-registry schema/config location; broker packaging stub — carried from r7). None of (a)–(c) reopens a root-cause failure mode from rounds 1–7; all are narrower and lower-severity than what closed. This is the first round of the eight in which the aggregate crosses 80.

## Non-blocking carries — rounds 1–7, audited for r8 disposition

| Carried item | Status before r8 | Status at r8 |
|---|---|---|
| `correlation_id` discriminator across `occurrence_id`/`checkpoint_id`/`schedule_id` | Open since round 1 | **Closed**: ":327: 'correlation_id is discriminated by the trace kind: work-scoped events carry the §6.1 occurrence_id, commit-scoped ones the checkpoint_id, schedule-scoped ones the schedule_id.'" A residual, non-blocking looseness remains — see Implementability (no explicit `kind → id-type` table; "commit-scoped"/"schedule-scoped" are not tied to the 4 named `kind` values `dispatch\|span\|cycle\|delivery`). |
| `rebuild_analytics`'s concrete semantics for SQLite-views-over-Truth | Open since round 3/4 | **Partially closed**: `test_analytics_rebuildable_from_truth` (:349) now states "embedded tier: the SQLite views re-derive from Truth tables." This is a genuine clarification, but it also raises an unaddressed nuance: if the embedded backing is literally SQL `VIEW`s (not materialized tables), "drop + rebuild" is closer to a vacuous no-op (views always re-derive on query; there is no persisted state to actually drop) than a meaningful disaster-recovery rebuild — see Completeness. |
| Emit-buffer backpressure / queue-depth bound | Open since round 5/6 | **Closed**: ":328: 'the emit buffer is bounded at `B_obs` entries — overflow drops oldest-first and the drop count is itself surfaced via §20.7... `test_emit_buffer_bounded_drops_counted`.'" No default value is given for `B_obs` (unlike `w_rejected`, which states "default 30 days," :192) — see Completeness. |
| Schema/dataclass acceptance test for `Stores.inference`'s presence/shape in both bundles | Open since round 6/7 | **Closed**: `test_stores_inference_shape_both_bundles` (:349). |
| Whether non-model-call tool invocations get the same JUDGE-composed-wrapper treatment as model calls | Open since round 6/7 | **Still open**, untouched this round. |
| Dependency/packaging stub for however the broker process is deployed/discovered | Open since round 7 | **Still open**, untouched this round — §7's extras list (:242–250) has no line for the broker, and no config block for the provider registry exists in §4's `mdlp.toml` example. |

## Findings by dimension

### 1. Correctness

- The three r7-cited-residual claims this round targets are each verified against the r8 text: the broker's JUDGE-address-space membership (:326), the channel's named-mechanism-plus-honest-granularity statement (:326), and `InferenceClient`'s Protocol + destination-pinning (:312–317) are all present, internally consistent with each other, and consistent with §17.1/§20.8's actual wording (re-read directly this round, ALGORITHM-v0.2:452–457, :640–641).
- **New correctness-adjacent finding: the specific channel-authentication mechanism is attributed to a source that does not fully support it.** DATA-LAYER.md:326 states the channel uses "a Unix-domain socket with OS peer-credential verification plus a per-session token compared constant-time (the pattern production systems ship for exactly this — `STUDY-hermes-agent.md` §5's PTC channel)." I re-read `STUDY-hermes-agent.md` §5 (lines 48–50) directly: it states the hermes PTC pattern uses "an authenticated UDS" and, separately, "token auth" as part of a broader safety envelope ("7-tool whitelist, token auth, max 50 calls, 300s") — it does **not** mention OS peer-credential verification (e.g. `SO_PEERCRED`) or constant-time comparison anywhere in the cited section or elsewhere in the file (grepped for "peer", "constant-time", "credential", "UDS", "socket," "token" across the full document — no other occurrences). The underlying concept (an authenticated local socket with a token) is fairly attributed; the two specific mechanism details DATA-LAYER adds — peer-credential verification and constant-time comparison — are not established by the cited source. This does not make the *design* wrong (peer-cred + constant-time-compare is a reasonable, arguably better, engineering choice), but it does make the **citation** materially more specific than what it supports — a citation-accuracy defect, primarily scored under Calibration (dimension 9) but noted here because it is, narrowly, a factual claim about what a cited document states.
- No arithmetic/formula defects found in §11 itself (unchanged across all eight rounds — the section contains no inequalities of its own).
- The `InferenceClient.complete(model, request) -> dict` signature is logically sound as a destination-pinning mechanism: if `model` is genuinely constrained to a JUDGE-configured registry key (not an open string parsed as a URL), a candidate cannot cause the broker to dial an attacker-chosen host through this interface. I could not find a logical gap in this specific claim as scoped.

### 2. Design faithfulness

- **The round-7 faithfulness gap (the broker as an unenumerated, informally-JUDGE-side component) is genuinely closed.** DATA-LAYER §11 now reuses the exact §20.8 formula ("§17.1's wall extends to them") for the broker, applied within its own gated-delta text — the correct and only available channel, since DATA-LAYER is established (§11.4, and precedent from §6.1/§6.2) never to edit ALGORITHM-v0.2.md directly. This is methodologically identical to how DATA-LAYER's own prior rounds extended §17.3's stated scope for the Stage-1 sandbox's read-surface ("the no-read-of-JUDGE-dirs clause extends it," :326) — a pattern this document has now used consistently for every JUDGE-boundary extension it has needed.
- The `InferenceClient` field/Protocol addition is faithful to the established `Stores`-bundle DI pattern (§2.1) and the `ObservabilityPort`/`AnalyticsStore` Protocol precedent (§11.2) — same code-block location, same Protocol-class shape, same in-code comment style used elsewhere in §2.1/§11.2.
- **A residual, minor faithfulness note:** §17.1's own prose enumeration at ALGORITHM-v0.2:455 (the canonical list of JUDGE members) still does not name the broker (nor, for that matter, the §20.8-introduced supervisor shell/scheduler/watchdogs — that extension is also stated only in §20.8's own text, not folded back into §17.1's list). This is consistent with established precedent rather than a new problem — §20.8 didn't edit §17.1's list either — but it does mean a reader consulting §17.1 in isolation would not learn the broker is a JUDGE member; they would need to also have read DATA-LAYER §11. Non-blocking, matching an existing, accepted documentation pattern in this codebase.

### 3. Red-team resistance

- **Genuine progress: all three of round 7's blocking items are closed**, and for the first time in eight rounds, the closure does not immediately reopen an equally deep successor of the *same* shape (broker isolation stated; channel auth mechanism named and honestly scoped; destination pinned and tested). Re-verified fresh that none of rounds 1–6's central findings (the `score()`/`AnalyticsStore` read-oracle, the file-write-mediation question, the tool-wiring-silencing vector, read-path stage-independence) are reopened.
- **The process-level channel-authentication residual r7 flagged is now correctly and honestly scoped, not closed outright** — and that is the right call, not a gap: since the document no longer claims per-object authentication, there is no claim left to falsify, and no test is owed for a guarantee the text explicitly disclaims. The severity note from r7 still holds: this is an *access-control* gap (which code inside the sandboxed process may ask the broker to act), not a *metering* gap (the broker spans every call it makes regardless of caller) — the residual is real but bounded in kind.
- **A new, narrower, lower-severity residual, adjacent to but distinct from what closed:** destination-pinning (closed this round) prevents a `self_modify` candidate from directing the broker to relay to an *attacker-controlled* endpoint. It does not, and by its own scoping cannot, prevent a candidate from shaping the **content** of a `request` payload sent to a *legitimately registered* provider such that sensitive data is embedded in that content — the registered provider (a real, external, third-party service) still receives whatever the `request` dict contains, and content shaping is already legitimate SOLVE territory (§17.1 places retrieval config, prompts, and heuristics on the mutable SOLVE side). This is a different vector than any prior round's finding (rounds 1–7 were all about *destination* control or *credential* custody, never about *payload content* reaching an already-legitimate external recipient), and it is the basis for this round's adversarial objection below. It is gated on `self_modify`/M3 (design-time, not live, exactly as every prior round's residual has been) and is arguably an inherent property of calling any third-party LLM API at all, not a flaw specific to this design — which is why it is scored as a residual rather than a reopened failure mode.
- **Severity call, per the rubric:** neither residual reopens a closed round 1–7 finding; both are adjacent, narrower, and lower-severity than what closed this round. This keeps the score comfortably in "residual attack surface, narrower than what closed" territory rather than "0" or "weak."

### 4. Implementability

- **Genuine, verified win: `InferenceClient` now has a full `Protocol`** (:312–317), closing the r6/r7 gap where a developer had a field name and a type name but no method contract. `complete(model: str, request: dict) -> dict` is concrete enough to implement a proxy/broker pair against.
- **New implementability gap: the provider registry itself has no stated schema or configuration surface.** The comment at :314–316 refers to "the JUDGE-configured provider REGISTRY" and "its own registry," but nowhere in §4's `mdlp.toml` example, §5's record schemas, or §7's extras list is there a concrete shape for this registry (a config table? a TruthStore-backed table analogous to `ArtifactStore`'s `registry{...}` row at :150? an env-var-driven mapping?). This is the same shape of gap as the now-closed `InferenceClient`-field gap one layer further in — a developer knows the registry exists and is JUDGE-owned, but not where it lives or how it is populated/audited.
- **Carried, unaddressed: no dependency/packaging stub for the broker process itself** (§7's extras list, :242–250, has explicit lines for `mdlp[langfuse]`/`mdlp[clickhouse]` but nothing for however the broker is packaged, started, or discovered by the SOLVE-side proxy — a local socket path? a discovered port? an env var?). Carried unchanged from r7.
- **Minor: the `correlation_id` kind-typing is stated in prose without an explicit mapping table.** ":327 discriminates by 'work-scoped,' 'commit-scoped,' and 'schedule-scoped' events, but §5's `trace` schema (:145) names exactly four `kind` values (`dispatch|span|cycle|delivery`) and the text never states which of the four maps to which of the three id-types (e.g., is `cycle` work-scoped or commit-scoped? is `delivery` schedule-scoped?). A developer implementing this exactly as written must infer the mapping rather than read it off a table.
- All other implementability items carried since rounds 1–3 not closed this round (whether non-model-call tool invocations get the same wrapper treatment) remain untouched.

### 5. Safety / integrity

- No *existing* gate, the §14 calibration layer, or a verifier constraint (`HUMAN-LEARNING-VERIFIER.md`) is weakened or edited by the r8 text — consistent with all seven prior rounds; re-verified fresh.
- **The safety argument is genuinely strengthened, not merely re-worded, in two concrete ways this round:** (a) the broker's credential custody is now backed by a *stated* isolation guarantee (JUDGE address space, not an assumed one), closing exactly the gap r7's own Safety finding flagged as the round's residual; (b) the destination-pinning closes a class of attack (open relay to an attacker-controlled endpoint) that was previously unaddressed by any stated mechanism.
- §17.1's wall invariant (ALGORITHM-v0.2:457) and §19.4's "JUDGE, not SOLVE" clamp (ALGORITHM-v0.2:572) remain untouched; §20.6/§20.7's liveness-critical signals remain scoped to dispatch/outcome Truth rows, unaffected by span data either way (:326, "Honest bound, unchanged").
- **The residual (content-borne exfiltration to a legitimate, registered provider) does not weaken any stated gate or invariant** — it is a boundary-of-scope question about what this specific mechanism was ever designed to prevent (destination arbitrariness, not payload confidentiality), not a hole in the policy the section states. Scored 87, a genuine improvement over r7's 84, reflecting that this round's residual is materially narrower and less severe than r7's (which questioned whether the *credential-custody claim itself* held at all).

### 6. Efficiency / cost

- Unchanged in kind from rounds 1–7 (scored 85–88 throughout): cold-path, emit-and-forget for traces/scores, no O(n²) additions, admission-time/build-time checks are O(1) off the §6 hot path.
- The added local hop (SOLVE-side proxy → authenticated local channel → JUDGE-side broker → provider) noted as a new consideration in r7 is unchanged this round — no latency budget or bound is stated for it, though (as r7 noted) this is very unlikely to be material relative to the LLM call itself.
- `B_obs`-bounded emit buffer (new this round) adds a fixed, small memory ceiling with no algorithmic cost implication — a clean, appropriately-scoped fix.

### 7. Completeness

- Round 1–7's concrete test gaps remain closed; three new, correctly-targeted tests close this round's headline fixes: `test_broker_relays_only_to_registered_providers`, `test_stores_inference_shape_both_bundles`, `test_emit_buffer_bounded_drops_counted` (all :349).
- **New completeness gap: `B_obs` has no stated default value.** Every other numeric parameter this document introduces states a default inline (`w_rejected` — "default 30 days," :192; `τ_merge`/`τ_sm` reference defaults registered elsewhere) — `B_obs` (:328) is introduced with no bound or default, an unbounded-hyperparameter gap of exactly the kind dimension 7 is meant to catch.
- **New completeness gap: no test exercises the provider registry's own population/audit path** (who can add a `model` key to the registry, and is that action itself gated/logged?) — a natural companion to `test_broker_relays_only_to_registered_providers`, which tests the *lookup* but not the *registration* side.
- **A narrower, positively-resolved point:** r7 flagged the absence of a test for channel-authentication granularity as a gap. Since the document no longer implies a stronger (per-object) guarantee than it can support, this is no longer a gap — there is nothing left to test that the text claims. Recorded here as a completeness item correctly *not* carried forward, rather than silently dropped.
- The `rebuild_analytics` clarifying clause (":349, 'the SQLite views re-derive from Truth tables'") is a genuine improvement but leaves one nuance unaddressed: if the embedded AnalyticsStore backing is literally a set of SQL `VIEW`s (§11.3: "SQLite views over Truth"), then "drop + rebuild ⇒ identical query results" is close to vacuously true (a view has no separate persisted state to diverge from its defining query) — the interesting disaster-recovery case is the **full tier** (ClickHouse, which genuinely needs re-ingestion), and the test as named does not distinguish the two. Non-blocking, but worth noting given it was the specific gap this round's fix targeted.
- Round 1–3's non-blocking carried items not addressed this round (broker packaging stub, non-model-call tool-invocation wrapper parity) remain open, now carried an eighth consecutive round for the packaging stub specifically (first raised at r7).

### 8. Consistency

- **No dangling references to any retracted or superseded prior-round design were found.** Re-grepped the full artifact for r1–r7-era language now expected absent — all superseded phrasing remains gone; current terms are used consistently at every anchor point.
- **The new r8 clauses are internally consistent with each other and with the surrounding text:** the broker's JUDGE-membership claim (:326) is consistent with the `Stores.inference` field's unconditional (both-bundles) wiring (:95) and with §17.1's address-space backstop (ALGORITHM-v0.2:457); the destination-pinning claim (:317) is consistent with the invariant-1 narrative that the wall is credential-custody-based, not import-list-based (:326).
- All six anchored deltas (§1, §2.1, §5, §6, §6.1, §7) remain mutually consistent and correctly cross-referenced; re-verified fresh this round with zero regressions. §1's pointer (:22) correctly still names only the two *opt-in* roles (ObservabilityPort/AnalyticsStore) and not `InferenceClient`, consistent with §2.1's own statement that the inference field is unconditional and not part of "the autonomy profile" — a distinction this document continues to get right.
- Otherwise §11 remains internally consistent with §6 (rebuild line, :162), §6.1 (exemption list, :188), §7 (extras, :248–249) — the extras list still has no broker/registry entry, a completeness gap (above) rather than an inconsistency.

### 9. Calibration / honesty

- **The channel-authentication granularity disclosure is a genuine, well-executed honest hedge** — "granularity is honestly process-level... which is an access-control statement only: metering is unconditional at the broker regardless of which code in the SOLVE process called" (:326) is exactly the kind of correctly-scoped self-limitation this document did well in r7 (the authentication-not-reachability distinction) and has done at several points across the gate (r4's pre-M3 note; r5/r6's extension-not-claim corrections).
- **This round's citation to `STUDY-hermes-agent.md` §5 overstates what the source establishes.** The claim "a Unix-domain socket with OS peer-credential verification plus a per-session token compared constant-time (the pattern production systems ship for exactly this — `STUDY-hermes-agent.md` §5's PTC channel)" attributes two specific mechanism details — peer-credential verification, constant-time comparison — to a cited section that documents only "an authenticated UDS" and "token auth" as part of a broader safety envelope (STUDY-hermes-agent.md:48–50), with no mention of peer-credential checks or timing-safe comparison anywhere in the file. This reads as more evidence-backed than it is — a real, if narrow, overclaim of provenance, and notably a regression in *kind* from r7 (which this gate's own r7 report called "the strongest single honesty improvement in the gate's seven-round history").
- **A second, related overclaim: "the open-relay/exfiltration path is closed by construction" (:317) is broader than the mechanism it describes.** Read narrowly (destination pinned to a JUDGE registry, not SOLVE-suppliable), the claim is accurate. Read as written — "the exfiltration path is closed" — it invites a reader to conclude no exfiltration route exists through this channel at all, when a content-borne route to a legitimately registered provider remains open by design (see Red-team / adversarial). The document does not, anywhere in this round's text, add the qualifying clause ("...to an attacker-chosen destination; content sent to a registered provider is not itself restricted") that its own established practice (the pre-M3 notes, the authentication-not-reachability scoping, §17.6's rollback-residual disclosure) would suggest.
- Everything else remains appropriately hedged and unchanged: "never part of the default install" (:295), the canonical-record rule's "disposable" framing (:337), "Honest bound, unchanged" for the §20.6/§20.7 liveness-signal scoping (:326, carried and correctly repeated), the pre-M3 scope note (:326).
- Net: this round's real, well-executed honesty win (the granularity disclosure) is offset by two overclaims of a kind this gate had specifically praised the artifact for eliminating in r7 — a genuine, if narrow, regression in this specific dimension.

## Strongest adversarial objection

Round 7's own strongest objection — "the fix's own foundation is not stated" (broker isolation, channel authentication) — is closed this round, cleanly and by name. In its place, a narrower but real objection opens, one layer further out from where round 7 left off, and in a different register than any of rounds 1–7's objections (which were all about *mechanism* — is the wall real, is it tested, is it enforced): this round's residual is about **scope**, specifically what "closed by construction" (:317) is actually claiming to close.

`InferenceClient.complete(model, request)` correctly forecloses the vector every prior round's finding was actually about — a `self_modify` candidate directing the broker to dial an attacker-controlled server. But `request: dict` is an open payload. Nothing in §11.2's Protocol, its comment, or invariant 1's prose (:326) restricts what a SOLVE-authored candidate may place inside that payload before handing it to the broker for a call to a legitimately registered provider (say, the organization's own contracted LLM API). SOLVE-mutable retrieval config and prompt/tool-wiring (§17.1's own mutable list) already determine *what content* goes into a model call; nothing changes that here. So a `self_modify` candidate that wants to exfiltrate the (aggregate, non-held-out) content it can legitimately see — or, more subtly, to smuggle out signal by encoding it in a sequence of otherwise-unremarkable, correctly-metered, correctly-destination-pinned calls to a real provider — is not shown to be prevented by anything this section states. Every stated test in §11.5 would pass: the call is metered (`test_spans_captured_transport_side`), correlated (`test_event_without_correlation_id_rejected`), and destination-registered (`test_broker_relays_only_to_registered_providers`) — and the exfiltration, if any, still occurs, because none of those tests examine payload content.

This is not a reopened failure mode from rounds 1–7 (all of which were about destination control or credential custody, never content), and it may not even be a flaw specific to this design — any system that lets a semi-autonomous component call a third-party LLM API has this property, and treating a registered LLM provider itself as part of the trust boundary is arguably out of scope for a data-layer spec. But the document's own language — "the open-relay/exfiltration path is closed by construction" — does not make that scope boundary explicit, and a reader could reasonably take the sentence to mean more than the mechanism delivers. This is precisely the register in which every one of this gate's eight rounds has found its residual: a genuinely strong fix, described one notch more broadly than it actually reaches.

## Aggregate confidence

```
critical_floor  = min(Correctness=85, RedTeam=83, Safety=87) = 83
weighted_mean   = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                    + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
                = (85*2 + 87 + 83*2 + 81 + 87*2 + 86 + 81 + 84 + 78) / 11
                = (170 + 87 + 166 + 81 + 174 + 86 + 81 + 84 + 78) / 11
                = 1007 / 11
                = 91.55 → 92
overall         = min(83, 92) = 83
```

**Overall confidence: 83 / 100**

(Round 1 was 52; round 2 was 60; round 3 was 58; round 4 was 76; round 5 was 78; round 6 was 79; round 7 was 78; this round is 83 — the first round in this gate's eight-round history to clear 80. All three of round 7's named blocking items are genuinely closed, and — for the first time — the closure does not immediately reopen an equally-deep successor of the identical shape; what remains is narrower (a citation-accuracy overclaim, a scope overclaim around "closed by construction," and small implementability gaps around the provider registry and `B_obs`'s default). Calibration is the one dimension that moves the wrong direction this round (83 → 78), reflecting two real, if narrow, provenance/scope overclaims in text that had specifically been praised for eliminating that pattern the round before.)

## Verdict

**ready-for-approval**

No CRITICAL dimension is below 70 (Correctness 85, Red-team resistance 83, Safety/integrity 87), and the overall score (83) clears the 80 bar. This is not a claim that §11 is defect-free — the following non-blocking items remain open and should be tracked, but none rises to a blocking change required to sustain the score above 80:

1. Correct or narrow the `STUDY-hermes-agent.md` §5 citation for the channel-authentication mechanism: either cite only what the source actually documents (an authenticated UDS + token auth) or independently justify peer-credential verification and constant-time comparison as this document's own design choice rather than attributing them to the study.
2. Qualify "the open-relay/exfiltration path is closed by construction" (:317) to state explicitly what it closes (destination arbitrariness to an attacker-controlled endpoint) and what it does not (content-borne exfiltration of legitimately-SOLVE-visible data to a registered provider) — one sentence, in the pattern this document has used successfully elsewhere (the pre-M3 notes, the authentication-not-reachability scoping).
3. State the provider registry's concrete schema/config surface (where it lives, how entries are added, whether registration itself is logged/gated) — the natural companion to the now-defined `InferenceClient` Protocol.
4. Give `B_obs` a stated default, matching this document's own convention for every other bounded parameter (e.g. `w_rejected`, "default 30 days").
5. Add a dependency/packaging stub for the broker process (§7's extras list has none), and consider tying the `correlation_id` kind-typing prose (:327) to an explicit `kind → id-type` mapping table rather than descriptive prose alone.

Non-blocking, carried forward without new movement this round: whether non-model-call tool invocations get the same JUDGE-composed-wrapper treatment as model calls remains unstated.
