# 360 Review: S17-S18-selfmod-fleet — 2026-06-27 (Round 3)

| Field | Value |
|---|---|
| Artifact | `docs/research/ALGORITHM-v0.2-pathway-learner.md` — §17 "The self-modification axis" + §18 "Multi-agent populations" |
| Proposed change | Verify resolution of the three pre-implementation notes from round-2 (static-analysis completeness / capability isolation; Stage-2 rollback trigger; fleet-cache staleness bound), re-score all 9 dimensions, recompute aggregate |
| Round-1 report | `docs/research/reviews/S17-S18-selfmod-fleet-review.md` (overall 45/100, 8 blockers) |
| Round-2 report | `docs/research/reviews/S17-S18-selfmod-fleet-review-r2.md` (overall 80/100, ready-for-approval, 3 pre-implementation notes) |
| Reviewer | review-360 |
| Date | 2026-06-27 |

---

## Round-2 pre-implementation note resolution audit

### Note 1 — Static-analysis completeness + capability isolation

**Round-2 note (verbatim):** "The SOLVE/JUDGE enforcement via 'import/dataflow constraint' is the load-bearing safety mechanism. The BUILD-SPECS item must specify: (a) which static analysis tool or technique performs the check; (b) what class of influence paths it covers; (c) how runtime side channels (shared mutable state, resource exhaustion) are handled."

**What the spec now says (§17.1, line 457):**
> "The check is **sound (conservative)**: a candidate it cannot *prove* free of a SOLVE→JUDGE write-path is **rejected**, and SOLVE may not use reflection / `eval` / dynamic import (kept decidable). As a runtime backstop, **JUDGE runs in a separate address space with no SOLVE-held handle** (capability isolation), so the partition holds even where static proof is unavailable."

**Assessment:** This addresses all three sub-concerns in the note.

(a) Completeness class is now stated as "sound (conservative)" — the check errs on the side of rejection, not clearance. Any candidate the static analysis cannot certify clean is rejected outright. This answers the question "what class of influence paths does it cover" directly: the conservative answer is that *uncertainty itself is rejection*, which is a stronger guarantee than naming a specific tool.

(b) Decidability is maintained by prohibiting reflection / `eval` / dynamic import in SOLVE. These are the three standard escape hatches that make static dataflow analysis undecidable. Banning them is the correct and standard engineering response; it is explicit and checkable.

(c) Runtime side channels are addressed by capability isolation: JUDGE in a separate address space with no SOLVE-held handle. This is the correct backstop for the class of attacks (shared mutable state, resource channels) that static analysis cannot see. The address-space separation means SOLVE cannot reach JUDGE's memory even if the static check missed an indirect reference path.

The combination — sound static analysis (reject-on-uncertainty) plus capability-isolation runtime backstop — is defense-in-depth. It does not leave the "implementation correctness of the static analysis" as a single point of failure, which was the core concern. **Genuinely resolved.**

**One residual — implementation specificity:** The spec correctly does not name a specific static analysis tool (that belongs in a BUILD-SPECS item). The algorithm-spec level claim ("sound/conservative check" + address-space isolation) is the right abstraction level and is architecturally complete. No finding.

---

### Note 2 — Stage-2 rollback trigger

**Round-2 note (verbatim):** "§17.3 states 'a post-promotion monitor triggers instant rollback on regression' but does not specify the regression metric, threshold, or observation window."

**What the spec now says (§17.3, line 465):**
> "a post-promotion monitor triggers **instant rollback** when held-out + monitored-subset competence **drops beyond `significant(Δ, SE)` over a window `w_promo`**"

**Assessment:** The round-2 gap is closed precisely. The trigger is now:
- **Metric:** held-out + monitored-subset competence (the same paired-item signal used everywhere else in v0.2)
- **Threshold:** `significant(Δ, SE)` — the §2 gate primitive, not an ad-hoc scalar; this inherits the §2 significance multiplier `z` and paired-SE cancellation
- **Window:** `w_promo`, registered as a new parameter in §12 (line 286: "`w_promo` (Stage-2 rollback window)")

The parameter is also in §17.5's parameter list (line 475: "`w_promo` (Stage-2 rollback-monitor window). Registered in §12."). The `w_promo` parameter is present in §12 at line 286.

The trigger is now fully consistent with §9's rollback logic (which also uses `significant(drop, SE)`) and with §2's gate primitive. The note's concern — that "instant rollback" was under-specified — is resolved by specifying the metric, threshold, and window in one line. **Genuinely resolved.**

---

### Note 3 — Fleet-cache staleness bound

**Round-2 note (verbatim):** "§18.2's O(1) cost relies on an async-updated CacheStore projection. The BUILD-SPECS item should specify the maximum allowed staleness and how stale reads interact with the §5.3 coverage floor guarantee."

**What the spec now says (§18.2, line 499):**
> "**Staleness bound:** the cached `ĉ_j(k)` has a max age `τ_cache`; a stale/missing read is treated **conservatively as no discount** (`φ = 1`), so staleness can never cause an agent to skip a cell it should still cover."

**Assessment:** The note asked for two things: (1) a staleness bound parameter, and (2) a specified interaction with the §5.3 coverage floor.

(1) `τ_cache` is named as the bound and is registered in §12 (line 286: "`τ_cache` (fleet-cache staleness bound)") and §18.7 (line 519).

(2) The interaction with the coverage floor is specified more cleanly than the note requested: instead of describing how staleness interacts with `f_min` at the floor level, the spec makes staleness conservative at the source. A stale read sets `φ = 1` (no discount), meaning the agent treats that cell as if no fleet peer has covered it, and therefore must decide on its own merits — which means the §5.3 floor applies at full strength. This is strictly safer than attempting to specify the floor interaction: the agent over-covers rather than under-covers on stale data.

**Assessment of the conservative direction:** `φ = 1` on stale/missing is the correct safe default. The alternative — using the last known `φ < 1` — would allow a stale discount to cause an agent to skip a cell that the fleet peer may have since abandoned. The conservative default prevents this at the cost of some coordination efficiency, which is the appropriate tradeoff. The spec's claim is accurate and honest. **Genuinely resolved.**

---

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 84 | pass |
| 2 | Design faithfulness | 83 | pass |
| 3 | Red-team resistance (CRITICAL) | 82 | pass |
| 4 | Implementability | 80 | pass |
| 5 | Safety / integrity (CRITICAL) | 82 | pass |
| 6 | Efficiency / cost | 78 | pass |
| 7 | Completeness | 82 | pass |
| 8 | Consistency | 84 | pass |
| 9 | Calibration / honesty | 84 | pass |

---

## Findings by dimension

### 1. Correctness

**Score: 84 — pass** (+2 from R2)

All round-1 and round-2 correctness findings remain resolved. No new correctness issues found in the three revised passages.

**C-R3-1 — Stage-2 trigger formula coherence.** `significant(Δ, SE)` in §17.3 (line 465) references the §2 gate primitive defined at line 43–50. The Δ here is a negative competence change (regression), so the test fires when `|drop| > margin + z·SE`. The paired-item SE applies: the same held-out items are scored before and after Stage-2 promotion, so shared variance cancels and SE is reduced 2–3×. This is consistent with every other usage of `significant()` in the spec. The formula is correct and internally consistent.

**C-R3-2 — Conservative φ=1 arithmetic.** When a stale/missing read sets φ=1, the formula `value'(a→k) = value(a→k) · 1 = value(a→k)` — the fleet discount is fully suppressed. This is arithmetically trivially correct and safe. No issue.

**C-R3-3 — `w_promo` in §12.** The parameter appears at line 286 and line 475. The §12 listing is in the "Added-section parameters" paragraph (line 286), which is the established pattern for §13–§18 additions. No inconsistency found.

No correctness issues remain.

---

### 2. Design faithfulness

**Score: 83 — pass** (unchanged from R2)

All round-1 and round-2 design faithfulness findings remain resolved. The three new additions (sound/conservative check language, `significant(Δ,SE)` trigger, `τ_cache` + conservative φ=1) are each additive refinements that do not alter the architectural layering or naming conventions.

**DF-R3-1 — `significant()` reuse.** Using the §2 gate primitive in §17.3 is an explicit design-faithfulness positive: it means the Stage-2 rollback uses the same statistical discipline as every other gate in the spec, rather than introducing a bespoke threshold. This is the correct design pattern.

**DF-R3-2 — Address-space isolation.** Adding a capability-isolation runtime backstop does not contradict any §§2–15 architectural commitment. The §6 orchestrator loop (in JUDGE) running in a separate address space from SOLVE is an implementation-layer constraint that strengthens, not modifies, the existing SOLVE/JUDGE partition.

No new design faithfulness concerns.

---

### 3. Red-team resistance

**Score: 82 — pass** (+2 from R2)

Evidence sourced from ALGORITHM-v0.1-redteam.md root causes RC-1 through RC-8.

All round-1 and round-2 red-team findings remain resolved.

**RT-R3-1 — Round-2 adversarial objection: SUBSTANTIALLY CLOSED.**
The round-2 strongest adversarial objection was: "a sufficiently clever SOLVE edit could influence JUDGE through a path the static analysis does not capture — e.g., through a shared module-level mutable object or a side channel that manifests only at runtime."

The capability-isolation backstop (§17.1, line 457: "JUDGE runs in a separate address space with no SOLVE-held handle") directly addresses the runtime side-channel class. A module-level mutable object in a separate address space is not reachable from SOLVE. Resource-exhaustion attacks (e.g., SOLVE consuming all memory to starve JUDGE) are a residual but are not a write-path attack and are mitigated by the OS-level process isolation implied by separate address spaces.

The residual attack surface is now: (a) an exploit that breaks OS-level address-space separation (a hypervisor-level or kernel exploit), and (b) timing/resource-contention channels that do not write to JUDGE but might influence scheduling. Both are implementation security concerns outside the scope of an algorithm spec and are not specific to this design. The spec's architecture is as sound as any process-isolated system can be at the design stage. The 2-point R2 deduction (from 85 to 80) for this residual is now partially recovered (+2); 3 points remain as a standing irreducible residual (inherent to static analysis + process isolation on shared hardware).

RC-1 through RC-8 regression analysis: unchanged from R2. No new attack surface opened by the three additions.

---

### 4. Implementability

**Score: 80 — pass** (+1 from R2)

**I-R3-1 — Stage-2 rollback trigger now implementable.** The R2 note identified the missing trigger specification as an implementability gap. §17.3 now gives the developer: metric (held-out + monitored-subset competence), test (`significant(Δ, SE)` from §2), and window parameter (`w_promo` from §12). A developer can implement this without guessing. The §2 `significant()` function signature is already defined; the implementation is: compute paired Δ over the `w_promo` window, call `significant(Δ, SE)`, rollback if true.

**I-R3-2 — Capability isolation implementable.** "Separate address space with no SOLVE-held handle" maps to a standard OS process boundary (e.g., subprocess with no shared memory handles, communicating only via serialized message passing). This is not exotic; it is standard practice for sandboxed execution. The spec correctly leaves the mechanism unspecified (OS process, container, VM) — those are BUILD-SPECS level decisions.

**I-R3-3 — `τ_cache` implementable.** Cache-entry timestamp plus eviction-on-stale is standard. The conservative φ=1 on stale/missing is a one-line check before evaluating the discount formula. Implementable without ambiguity.

**Remaining implementability gap (unchanged from R2):** no plug-point section in BUILD-SPECS.md format. This is a BUILD-SPECS item concern, not an algorithm-spec concern, and was noted as non-blocking in R2. Unchanged.

---

### 5. Safety / integrity

**Score: 82 — pass** (+2 from R2)

**S-R3-1 — Capability isolation as defense-in-depth.** The addition of address-space isolation as a runtime backstop means the SOLVE/JUDGE partition now has two independent enforcement layers:
1. Static analysis (sound/conservative — reject-on-uncertainty, no reflection/eval/dynamic import)
2. Runtime capability isolation (separate address space, no SOLVE-held handle to JUDGE)

For a write attack to succeed, BOTH layers must fail. The static layer would need to incorrectly clear a write path, AND the OS address-space separation would need to be breached. This is defense-in-depth in the standard security sense. The R2 residual safety note (implementation correctness of the static analysis as a single point of failure) is now addressed structurally: even if the static analysis has a bug, the runtime isolation catches it.

**S-R3-2 — Conservative φ=1 safety direction confirmed.** A stale cache causing φ=1 means the fleet-coverage discount is not applied — the agent treats the cell as unmastered by peers and continues to cover it. This is the safe direction: over-coverage by the agent, not under-coverage. The §5.3 floor `f_min` is applied after φ, and with φ=1 the agent's own value(a→k) is used unmodified, which means the floor is most likely to be effective. No safety weakening from the staleness handling.

**S-R3-3 — Gates integrity survey (carried forward, all confirmed):**
- §4 eval harness + verifier: in JUDGE (line 455) ✓
- §4.1 held-out set + `provision_suite`: in JUDGE (line 455) ✓
- §8 commit/rollback/safety gates: in JUDGE (line 455) ✓
- §9 / §17.3 two-stage promotion: in JUDGE (line 455) ✓
- §14 circuit breaker + calibration: in JUDGE (line 455) ✓
- `self_modify` budget enforcer: in JUDGE (line 455) ✓
- §3 competence posterior C and update path: in JUDGE (line 455) ✓
- §6 orchestrator loop: in JUDGE (line 455) ✓
- TeacherAdapter task-distribution: in JUDGE (line 455) ✓

All nine surfaces remain accounted for. The capability-isolation backstop (line 457) now wraps all nine.

No safety weakening found. The three additions each strengthen rather than weaken integrity.

---

### 6. Efficiency / cost

**Score: 78 — pass** (+2 from R2)

**E-R3-1 — Staleness bound addressed.** §18.2 line 499 now states: "the cached `ĉ_j(k)` has a max age `τ_cache`". The parameter is registered in §12. The spec does not specify the value of `τ_cache` (correctly: this is an M3 empirical dial), but the parameter existence means the implementer has a bounded handle. The R2 note asking for this parameter is resolved.

**E-R3-2 — Conservative φ=1 efficiency tradeoff acknowledged.** The conservative handling means that on a stale-cache epoch, the fleet-coverage discount is suppressed entirely, and the agent's cell-value rankings revert to §13.1 solo-agent behavior. This is a graceful degradation: no panic, no fallback branch, just φ=1. The cost of a stale-cache epoch is thus bounded: the agent wastes some coordination efficiency but does not fail. No new efficiency concern.

**E-R3-3 — Address-space isolation cost.** Running JUDGE in a separate address space implies inter-process communication overhead for every `self_modify` submission (the candidate's evaluation requires JUDGE to score it). This is per-`self_modify` action (outer §6, episodic) not per-step — so it is not on the hot path. The cost is episodic and bounded by `sandbox_cost_cap` (line 475). No hot-path efficiency regression.

---

### 7. Completeness

**Score: 82 — pass** (+4 from R2)

**Co-R3-1 — Stage-2 rollback trigger now fully specified.** The R2 completeness finding ("§17.3 states 'a post-promotion monitor triggers instant rollback on regression' but does not specify the regression metric, threshold, or observation window") is closed. §17.3 line 465 now specifies all three: metric (held-out + monitored-subset competence), test (`significant(Δ, SE)`), and window (`w_promo`). The `w_promo` parameter is registered in §12 (line 286) and §17.5 (line 475) with its semantics stated ("Stage-2 rollback-monitor window").

**Co-R3-2 — Staleness bound parameter registered.** `τ_cache` is now in §12 (line 286) and §18.7 (line 519). The spec's "Added-section parameters" convention is followed consistently.

**Co-R3-3 — Sound/conservative class stated.** The static analysis completeness class is now explicitly declared: "sound (conservative)" with the specific carve-out for decidability (no reflection/eval/dynamic import). This is a completeness positive: the spec now tells an implementer exactly what property the static check must satisfy, not just that a check exists.

**Remaining minor gap (unchanged from R2):** the `test_fleet_self_modify_cannot_collectively_capture_verifier` test stub still lacks stated preconditions and success criteria beyond the mechanism claim. Appropriate as a stub; the BUILD-SPECS item operationalizes it. Non-blocking.

---

### 8. Consistency

**Score: 84 — pass** (+1 from R2)

**Cs-R3-1 — `w_promo` and `τ_cache` in §12 consistency check.** Both parameters appear in the "Added-section parameters" paragraph at line 286, which is the established cross-reference point for §13–§18 additions. Both also appear in their respective section parameter lists (§17.5 line 475, §18.7 line 519). No double-registration inconsistency; the §12 paragraph is explicitly labeled "Added-section parameters (extend §12)" and is the intended consolidation point. Consistent.

**Cs-R3-2 — `significant()` reuse in §17.3 vs. §2 definition.** The §2 definition (lines 43–50) defines `significant(Δ, se, margin=0, z=2)`. §17.3 references `significant(Δ, SE)` (using positional args, margin=0 default). This is consistent: margin defaults to 0 and z defaults to 2, which is the standard usage throughout the spec. No inconsistency.

**Cs-R3-3 — Conservative φ=1 vs. §18.2 formula.** The §18.2 formula states `φ(k) = 1 − ρ_fleet · 1[∃ j≠self : significant(ĉ_j(k) − θ, SE_j)]`. The staleness rule (line 499) states a stale/missing read sets φ=1. This is equivalent to: when the cache is stale, the indicator `1[...]` is treated as `false` (unknown whether any j significantly masters k), so φ = 1 − ρ_fleet · 0 = 1. Consistent with the formula: the conservative treatment is a specific input assumption, not a formula override.

All R2 consistency findings remain resolved. No new inconsistencies found.

---

### 9. Calibration / honesty

**Score: 84 — pass** (+1 from R2)

**Ca-R3-1 — "Sound (conservative)" claim is accurate.** The spec claims the static check is "sound (conservative)." In static analysis terminology, a sound analysis is one that does not produce false negatives (does not miss true violations). A conservative analysis rejects on uncertainty. These terms are being used correctly: the check will never clear a candidate that actually has a write-path (soundness), and will reject candidates it cannot prove clean (conservatism). The spec's use of these terms is accurate.

**Ca-R3-2 — Conservative φ=1 claim is accurate.** The spec states "staleness can never cause an agent to skip a cell it should still cover." This is strictly correct under the φ=1 rule: with no discount applied, the agent's value ranking is at least as high as the baseline §13.1 objective, so cells the agent should cover are covered at least as much as without the fleet-coverage term. The claim is not overclaimed.

**Ca-R3-3 — No new overstatements.** The three additions do not introduce new guarantees beyond what the mechanisms can deliver. The capability isolation is described as a "runtime backstop" (accurate: it backs up the static check) not as a proof of security. The `w_promo` window is described as a parameter (accurate: its value is unspecified, to be tuned at M3). The `τ_cache` is described as a "max age" parameter (accurate: a bound, not a specific value).

The R2 note on "N × 0" framing (§18.5): the text reads "collective optimization pressure on the JUDGE surface is N × 0." This remains a slight notational imprecision (the actual claim is that each agent's write-access to JUDGE is zero, so the product is N × 0 = 0). The text is locally accurate; no change in this round. -1 point maintained from R2.

---

## Strongest adversarial objection

The round-2 adversarial objection (static analysis incompleteness as a single point of failure) is now addressed by the capability-isolation backstop. A fresh adversarial pass is required.

**The strongest remaining objection: the "sound/conservative" static check guarantee depends on the scope boundary being correctly specified, but the scope of SOLVE and JUDGE is defined in English prose, not in a machine-checkable artifact.**

The static analysis check is supposed to verify "no write-path from SOLVE to JUDGE." But the partition of what constitutes SOLVE and what constitutes JUDGE is stated in §17.1 as a natural-language list (line 455): nine named items in JUDGE, and a prose description of SOLVE. For the static analysis to be sound, it must have an authoritative, machine-readable definition of the JUDGE boundary against which to verify candidates.

If the JUDGE boundary is defined only in English prose in the spec, then the static analysis tool must translate that prose into a concrete set of modules/classes/functions that are "JUDGE." This translation is itself a human step that can be wrong — a developer who misclassifies a JUDGE component as SOLVE (or who adds a new component without explicitly classifying it) could leave a write-path unchecked.

The capability-isolation backstop (address-space separation) mitigates this: even if the static check's boundary definition is wrong, the runtime separation enforces the boundary by physical memory separation. This is why the defense-in-depth framing is correct and important.

However, the spec does not address *boundary maintenance* under evolution: as SOLVE grows with new modules (that is the purpose of `self_modify`), each new SOLVE module must be correctly classified as SOLVE (not JUDGE) and must be statically verified against the JUDGE boundary. The spec does not specify the governance process for updating the JUDGE boundary definition as the system evolves.

This is a BUILD-SPECS item concern, not a structural flaw in the algorithm design. The architecture (address-space isolation as backstop) is robust to boundary-classification errors. But the companion BUILD-SPECS item should specify: (a) the machine-readable JUDGE boundary artifact (e.g., an allowlist of JUDGE module identifiers); (b) the review process when new components are added; (c) how the static analysis is re-run after each `self_modify` promotion.

This objection does not change the verdict — the architecture is sound — but it is the sharpest remaining concern for the BUILD-SPECS item author.

---

## Aggregate confidence

```
critical_floor  = min(Correctness=84, RedTeam=82, Safety=82) = 82
weighted_mean   = (84*2 + 83 + 82*2 + 80 + 82*2 + 78 + 82 + 84 + 84) / 11
                = (168 + 83 + 164 + 80 + 164 + 78 + 82 + 84 + 84) / 11
                = 987 / 11 = 89.73 → 90
overall         = min(82, 90) = 82
```

**Overall confidence: 82 / 100**

---

## Verdict

**ready-for-approval**

All three round-2 pre-implementation notes are verified genuinely resolved:
1. Static-analysis completeness — sound/conservative class declared + capability-isolation runtime backstop (defense-in-depth). **Closed.**
2. Stage-2 rollback trigger — `significant(Δ, SE)` over `w_promo` window, both fully specified and registered. **Closed.**
3. Fleet-cache staleness — `τ_cache` parameter registered; conservative φ=1 on stale/missing is architecturally safe and accurately claimed. **Closed.**

No CRITICAL dimension falls below 70. Overall score is 82, up from 80 in R2, driven by a lifted critical floor (82 vs. 80) owing to the runtime capability-isolation backstop.

**One note for the companion BUILD-SPECS item (non-blocking, required before implementation):**

The JUDGE boundary must be represented as a machine-readable artifact (e.g., an allowlist of JUDGE module identifiers) that the static analysis tool consults, and the process for updating this artifact as SOLVE evolves under `self_modify` must be specified. The algorithm-spec architecture is robust (address-space isolation catches boundary-classification errors at runtime), but the BUILD-SPECS item must close the governance gap to keep the static check meaningful as the system grows.
