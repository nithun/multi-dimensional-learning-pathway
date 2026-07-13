# 360 Review: R1-retrieval-dispatch (round 3) — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md` R1 item (lines 286–347) |
| Proposed change | Round-3 revision of the §16 companion build-spec — sweeps the remaining `w`→`v` naming leftover, states the `ε_mode` cross-mode floor as a deterministic per-window quota (not a probabilistic mixture), gives the mode-dispatch cold-start prior explicit `(μ0, SE0)` numbers, states the B2-Amendment-A cross-gate dependency on `part_of`/`confidence` inline with graceful degradation, and replaces the false "All registered in §12" claim with an accurate statement of where R1's dials are registered |
| Reviewer | review-360 |
| Date | 2026-07-13 |
| Round | 3 (round-2 score: 76, `reviews/R1-retrieval-dispatch-review-r2.md`; round-1: 54) |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"` (`recent_outcomes` include `effective:EV-1-review-360-2026-07-02-audit`, `effective:EV-1-change-approver-2026-07-02-audit`). Filing as a full review report, not a proposal.

## Round-2 residual resolution scorecard

Round 2 (`reviews/R1-retrieval-dispatch-review-r2.md`) closed with 6 numbered blocking changes required to clear 80. Re-verified against the current text (`BUILD-SPECS.md:286–347`):

| # | Round-2 blocking change required | Resolved this round? |
|---|---|---|
| 1 | Finish the `w`→`v` sweep (Plug-point still said `w`, r2 line 310) | **Yes, verified clean.** `BUILD-SPECS.md:317` now reads "fusion weights `v` live beside §5.2's `update_w` (which keeps maintaining the per-item `w[item]` that feeds `rel`)". A full-file grep for `reranker weight`/`fusion weight`/stray `w` in the R1 section finds only the two intentional, correctly-disambiguated `w[item]` references (`BUILD-SPECS.md:303, 317`) — no leftover instance found anywhere in the document. |
| 2 | Specify the `ε_mode` floor's enforcement mechanism concretely (deterministic quota vs. probabilistic mixture) | **Yes.** `BUILD-SPECS.md:300`: "**Cross-mode floor `ε_mode`, enforced as a deterministic quota:** per window `W_m`, each mode is **force-dispatched ⌈ε_mode · dispatches⌉ times**, scheduled round-robin across the window — a hard quota, not a probabilistic mixture, so the guarantee is exact and directly testable." This directly answers r2 Findings 1.2/3.2/4.3: `test_mode_dispatch_thompson_with_floors`'s literal `≥ ε_mode` assertion (`:336`) is now satisfiable as stated. Residual: the exact interleaving algorithm for which within-window dispatches are force-assigned vs. Thompson-sampled is not spelled out procedurally (see Implementability). |
| 3 | Give the mode-dispatch cold-start prior concrete `(μ0, SE0)` numbers, and state the exact `μ_m`/`SE_m` update rule | **Partially.** `BUILD-SPECS.md:298–299` now gives numbers: "`μ0` = the pooled cross-mode mean contribution (0 before any mode has data)" and "`SE0` = 2× the pooled per-episode SD" — a legitimate, implementable empirical-Bayes cold-start construction (the A5 template, correctly cited). **Not resolved:** the steady-state `μ_m`/`SE_m` update rule is still only described in prose ("over a sliding window `W_m`", `:298`), not as a closed formula — a developer must still infer windowed-sample-mean/SD (the natural reading, and consistent with `W_m` being named a "window" rather than a decay constant) rather than an EWMA. This is a smaller, more tractable residual than round 2's (which had *no* cold-start numbers at all). |
| 4 | Correct or remove the "All registered in §12" claim | **Yes, verified against the current algorithm text.** `BUILD-SPECS.md:325` now reads: "§16's own dials (`b_ret`, `K`, `(α_Q0,β_Q0)`) are already in §12; R1's dials are registered **here, at build-spec level** — the A1–B4 precedent (`u_ref`, `n_eff_warm`, `ρ_M`… all live in their build-spec items, not §12)." Checked against `ALGORITHM-v0.2-pathway-learner.md:286` ("Added-section parameters (extend §12): … §16 `b_ret` … `K` … `(α_Q0,β_Q0)`" — nothing else for §16) and confirmed `u_ref` (A1), `n_eff_warm` (A5), `ρ_M` (B1) are indeed absent from §12's general list (`:282`) and its "Added-section parameters" list (`:286`). The claim is now accurate and the precedent it cites is real. |
| 5 | Flag the cross-gate dependency on B2's Amendment A explicitly | **Yes, and verified sound, not just stated.** `BUILD-SPECS.md:308`: "**Cross-gate dependency, stated:** the `part_of` type and the `weight`/`confidence` field split are defined by B2 Amendment A (separately in gate); if Amendment A is not approved, `struct` computes over `prereq`-edge `confidence` only — graceful degradation, no blocking dependency". This is not just an acknowledgment — it is *correct*: `prereq`-edge `confidence` already exists in the **approved, non-amendment** base spec (`ALGORITHM-v0.2-pathway-learner.md:133`, "`g.decay_edges()` # prereq-edge confidence decays…"), so the fallback path does not itself depend on the currently-unresolved Amendment A (round 3, not yet reviewed — no `B2-amendA-typed-edges-review-r3.md` exists in `reviews/`). The degradation is genuinely independent, not merely asserted. |
| 6 | Soften the header's "Adds NO new objective, gate, or belief" claim to acknowledge the new `N(μ_m,SE_m)` mode-level posterior | **No — unaddressed.** `BUILD-SPECS.md:288` is byte-for-byte unchanged from round 1/round 2: "Adds NO new objective, gate, or belief — `U_Q = z(EIG_Q) − cost` (§16.3), the counterfactual credit (§5.2/§16.5), and the §8 gating of learned weights are unchanged." The mode-dispatch posterior `N(μ_m, SE_m)` (`:298`) is, on its face, a new belief object that did not exist in the approved §16 design — round 2's Finding 9.1 named this exact claim as an overclaim and round 2's blocking list explicitly required softening it. It was not touched this round, despite every other line in its immediate vicinity (`:290–325`) being substantially rewritten. See Calibration/honesty and the adversarial pass. |

**Net: 4 of 6 cleanly closed (1, 2, 4, 5) and verified sound (not just asserted) on independent re-derivation; 1 more materially narrowed but not fully closed (3); 1 left completely untouched for a second straight round despite being an explicit, named blocking item (6).** This is genuine, substantial, mostly-verified progress (76 → below), with one conspicuous non-fix.

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 83 | pass |
| 3 | Red-team resistance (CRITICAL) | 87 | pass |
| 4 | Implementability | 83 | pass |
| 5 | Safety / integrity (CRITICAL) | 88 | pass |
| 6 | Efficiency / cost | 86 | pass |
| 7 | Completeness | 81 | pass |
| 8 | Consistency | 85 | pass |
| 9 | Calibration / honesty | 65 | weak |

## Findings by dimension

### 1. Correctness

**Finding 1.1 — the `ε_mode` deterministic-quota fix is a genuine, checkable correctness improvement, no sign/logic error found.** `BUILD-SPECS.md:300`'s force-dispatch rule (`⌈ε_mode · dispatches⌉`, round-robin) is a standard, exact, testable admission mechanism, directly analogous to `enforce_coverage_floor` (`ALGORITHM-v0.2-pathway-learner.md:161`) rather than a stochastic mixture — this is the correct class of fix for a claim that must hold with certainty in a finite window (round 2 Finding 1.2's exact objection). Re-reading the granularity carefully: "episode" (the `W_m` sample unit) and "`EXPAND`" (the mode-dispatch decision point, `:298`) are the same event in this system — §16.2 scopes belief `Q` to one goal/episode and §16.1 nests the inner retrieve loop inside one `EXPAND` — so "per window `W_m` … force-dispatched … times" and "per-episode … divided by pulls taken" are consistently the same unit of account; no granularity mismatch, contrary to an initial reading.

**Finding 1.2 — the cold-start prior numbers are dimensionally consistent and correctly justified, but the general `μ_m`/`SE_m` formula is still prose, not a closed form.** `μ0 = 0` before any mode has data and `SE0 = 2×` pooled per-episode SD (`:298–299`) is a coherent empirical-Bayes borrowing-of-strength construction (a legitimate technique, matching the stated "A5 template" analogy of a deliberately-wide, optimistic new-arm prior). No error found. But — as in round 2 — the *steady-state* statistic ("posterior `N(μ_m,SE_m)` … divided by pulls taken, over a sliding window `W_m`", `:298`) is still described rather than written as `μ_m = mean({x_e}), SE_m = sd({x_e})/√n` the way `EIG_cell`'s closed form is spelled out (`BUILD-SPECS.md:24–30`). A developer must still infer the exact estimator (windowed sample mean/SD is the natural reading, but is not stated).

**Finding 1.3 — the `w`/`v` naming collision (round-1/round-2's Finding 1.3/8.1) is now fully and correctly closed.** Re-verified by grep across the whole document (not just the R1 section): the only remaining `w[item]` references (`:303, 317`) are the intentional, explicitly-disambiguated ones ("§5.2's per-item credit `w[item]`"); no orphaned "reranker weight(s) `w`" instance survives.

**Score rationale:** Two of the round-2 correctness gaps (the `ε_mode` guarantee, the naming collision) are now cleanly and verifiably closed; one (the exact `μ_m`/`SE_m` formula) is meaningfully narrowed (concrete cold-start numbers now exist) but still not fully specified as a closed form. **88.**

### 2. Design faithfulness

**Finding 2.1 — the B2 Amendment A cross-gate dependency is not just flagged, it is verified structurally sound.** `struct`'s graceful-degradation fallback ("computes over `prereq`-edge `confidence` only" if Amendment A fails, `:308`) rests on `prereq`-edge `confidence`, which is part of the **already-approved** base spec (`ALGORITHM-v0.2-pathway-learner.md:133`), not on anything Amendment A itself introduces — so the fallback is genuinely independent of Amendment A's outcome (currently round 3, unreviewed at that round; only rounds 1–2 have review files). This resolves round-2 Finding 2.2/8.3 substantively, not just cosmetically.

**Finding 2.2 — the "not a third selection problem" argument (round-2 Finding 2.1) remains asserted, not formalized, and is unchanged.** `BUILD-SPECS.md:301` still frames mode-then-pull dispatch as "a hierarchical decomposition of the single inner `π_Q` decision" without amending §16.1's own text (contrast the B2 Amendment A track, which *is* a formal, separately-reviewed amendment to an approved section, `BUILD-SPECS.md:213`). The `mix`-collapse sub-claim is true by construction (verified: `mix`'s candidate set literally *is* the union of all stores, `:296`, so `test_mode_dispatch_collapses_under_mix` tests a definitional identity, not a live risk) — but the broader claim that a `N(μ_m,SE_m)` episode-lift bandit is "the same decision" as `π_Q`'s live `EIG_Q` posterior remains a rhetorical framing, unchanged from round 2.

**Score rationale:** The one design-faithfulness gap that was scored (2.2, the B2 dependency) is now resolved and independently verified as correct, not merely restated; the other (2.1, the unformalized "third selection problem" argument) persists unchanged. **83.**

### 3. Red-team resistance

**Finding 3.1 — RC-1/RC-7 at the mode-dispatch layer are now closed with a verifiably hard guarantee, not just a claimed one.** Round 2's residual objection (Finding 3.2) was precisely that a stochastic-mixture reading of `ε_mode` could not literally guarantee a lower bound in a finite window — a weak, residual instance of the RC-7 starvation pattern. `BUILD-SPECS.md:300`'s deterministic round-robin quota removes that ambiguity: the guarantee is now exact by construction, matching the rigor of `enforce_coverage_floor`'s deterministic admission rule cited as the target pattern in round 2. `test_mode_dispatch_thompson_with_floors` (`:336`) can now be satisfied as literally stated.

**Finding 3.2 — no other RC newly disturbed.** RC-2 (format-correlation gaming) mitigation is unchanged (`:331`); `rel`'s RC-1/RC-7 defenses (leave-one-out credit, `ε_ret`) are unchanged (`:310, 314`, tests `:342–344`).

**Score rationale:** The one residual red-team gap identified in round 2 (the floor's hardness) is now genuinely closed, verified by re-derivation rather than accepted at face value. **87.**

### 4. Implementability

**Finding 4.1 — the fusion vector, guard, `ε_ret`, and the two closed S16 advisories remain cleanly buildable** (`BUILD-SPECS.md:303–314, 320–324`), unchanged from prior rounds' assessment.

**Finding 4.2 — the `ε_mode` mechanism is now buildable, with one residual procedural gap.** A developer can implement "force-dispatch `⌈ε_mode·dispatches⌉` per window, round-robin" directly — but the spec does not state *how* the forced slots and the Thompson-sampled slots are interleaved within a window (front-loaded vs. evenly spread, e.g. a deficit-round-robin-style scheduler vs. a simple "reserve the last N `EXPAND`s of the window" scheme) — both satisfy the literal `≥ε_mode` count but produce different exploration dynamics near a window boundary. Minor relative to round 2's ambiguity (mechanism *class* was undefined then; only a scheduling *detail* is undefined now).

**Finding 4.3 — the cold-start prior is now numerically buildable; the steady-state statistic still requires one implementer decision** (Finding 1.2): windowed sample mean/SD vs. an alternative windowed estimator. Given `W_m` is explicitly named a "window" (not a decay constant), this is a low-ambiguity residual, not a genuine fork.

**Score rationale:** Both major implementability gaps from round 2 (the cold-start numbers, the `ε_mode` mechanism class) are substantially closed; two much smaller procedural details remain unstated. **83.**

### 5. Safety / integrity

**Finding 5.1 — the RC-7 starvation gap at the mode-dispatch layer, previously only partially closed (a "hard" floor that couldn't be verified as hard), is now genuinely closed.** The deterministic quota (`:300`) makes the "hard `ε_mode` floor" language in "Honest risks" (`:329`) an accurate description of the actual mechanism for the first time across all three rounds — this is a real safety-relevant tightening, not merely re-asserted language.

**Finding 5.2 — the `v`-update gate pin (generalization sub-clause only) remains exactly what the S16 decision record commissioned and previously scrutinized.** `S16-unified-retrieval-decision.md`'s advisory item 2 explicitly asked for this pin ("generalization gate sub-clause of §8, not the full four-clause commit gate"); `BUILD-SPECS.md:312, 324` implements it faithfully. No new safety defect found here this round.

**Finding 5.3 — the reference-validation guard remains a genuine safety-positive, unchanged** (`BUILD-SPECS.md:313`).

**Score rationale:** The one integrity gap carried since round 1 (an unverifiably-"hard" floor) is now closed on independent re-derivation, not just re-asserted; nothing new found that weakens a gate, §14, or the verifier. **88.**

### 6. Efficiency / cost

**Finding 6.1 — no new cost.** The deterministic round-robin scheduler and the pooled cold-start statistic add negligible bookkeeping (a handful of running sums per mode) on top of round 2's already-negligible assessment. No new O(n²) term, no new LLM/verifier call.

**Score rationale:** Consistent with round 2. **86.**

### 7. Completeness

**Finding 7.1 — the "All registered in §12" fix (round-2 Finding 7.2) is accurate and closes a real gap, verified against the current algorithm text** (`ALGORITHM-v0.2-pathway-learner.md:282, 286`).

**Finding 7.2 — no test was added for the mode-level statistic's own correctness properties, and none could be, given Finding 1.2's residual.** Round 2's Finding 7.1 (no analogue of `test_eig_falls_with_n_eff` at the mode level) is unchanged: still no test that `SE_m` shrinks as `W_m` fills, nor one exercising the cold-start prior's numeric shape (which, unlike round 2, could now plausibly be written given `(μ0,SE0)` are specified — the remaining blocker is only the missing steady-state formula, Finding 1.2).

**Finding 7.3 — the "time-to-recover" honest-risk gap (round-2 Finding 7.4, second half) is still not acknowledged.** At `ε_mode=0.05` across 5 modes, a mode relying purely on its floor share still takes on the order of `1/ε_mode ≈ 20` dispatches per floor-share cycle to accumulate meaningful evidence, and "Honest risks" (`:329`) states the floor closes starvation without noting this bounded-but-slow recovery property — unchanged from round 2.

**Score rationale:** One real, verified completeness gap closed (the §12 claim); two carried-forward gaps (mode-statistic test coverage, recovery-time honesty) remain exactly as they were. **81.**

### 8. Consistency

**Finding 8.1 — all three concrete internal inconsistencies flagged in round 2 are now closed, each independently verified, not merely asserted-fixed.** The `w`/`v` Plug-point leftover (round-2 Finding 8.1) — closed, grep-verified (Correctness 1.3). The false "All registered in §12" claim (round-2 Finding 8.2) — closed, cross-checked against `ALGORITHM-v0.2-pathway-learner.md:282,286` (Completeness 7.1). The unacknowledged B2-Amendment-A dependency (round-2 Finding 8.3) — closed and verified sound, not merely stated (Design faithfulness 2.1).

**Finding 8.2 — a residual internal tension exists between the unchanged header claim and the newly-detailed mechanism it describes.** `BUILD-SPECS.md:288`'s "Adds NO new … belief" sits two paragraphs above `:298`'s fully fleshed-out `N(μ_m, SE_m)` posterior — a new belief object by any plain reading of the word. This was flagged in round 2 as a Calibration finding (9.1); read as an internal-consistency matter (header vs. body), it is a residual defect of the same kind as the three now-closed ones, just not closed itself.

**Score rationale:** Three of four concrete internal inconsistencies identified across rounds 1–2 are now closed and independently re-verified; one (header vs. mode-posterior body) persists. **85.**

### 9. Calibration / honesty

**Finding 9.1 — the header's "Adds NO new objective, gate, or belief" claim is now a *repeat*, unaddressed overclaim, which is a worse signal than a fresh one.** This exact claim (`BUILD-SPECS.md:288`) was named in round 2's numbered blocking list (item 6) as required to soften before clearing 80. It is unchanged, verbatim, for a third consecutive round, while every other flagged issue in its immediate vicinity was substantially rewritten this round (`:290–325`). The project's own precedent (`reviews/B2-amendA-typed-edges-review-r2.md:103`: "Confidently resolving a flagged ambiguity with an incorrect grounding is worse, calibration-wise, than leaving the ambiguity open") is about a different failure mode (wrong fix vs. no fix), but the underlying principle — that calibration is judged on what actually gets corrected, not on what gets asserted — applies here: an explicitly-named, low-cost wording fix that survives two full review rounds untouched, while structurally harder problems in the same document get resolved, is a genuine, evidenced honesty concern about which findings get acted on.

**Finding 9.2 — "All registered in §12" (round-2 Finding 7.2/9.2) is now accurate**, verified independently against `ALGORITHM-v0.2-pathway-learner.md:282,286` — a real, checked calibration improvement, not just a changed claim.

**Finding 9.3 — the "Honest risks" section's `ε_mode`-floor language is now honest, where it was previously unverifiable.** `:329`'s "the hard `ε_mode` floor" is, for the first time across all three rounds, an accurate description of the actual (deterministic-quota) mechanism (round-2 Finding 9.3 flagged this as an unverified claim of hardness; it is now verifiably true).

**Score rationale:** Two of three calibration issues are genuinely, verifiably resolved; the third is not merely unresolved but is the same named item surviving untouched for a second straight round despite being explicitly required — a repeat-miss on an explicitly-flagged, low-cost fix, which keeps this in the weak band. **65.**

## Strongest adversarial objection

**The `episode-naive` ablation arm's claimed cleanliness may be silently violated by the cache.** `BUILD-SPECS.md:294` defines `episode-naive` as "vector only: raw ANN recall, no graph, no state conditioning (**the ablation baseline arm**)" — its entire scientific purpose (`:302`: "full R1 … vs `episode-naive` … as frozen arm configurations") is to be a genuinely clean, non-graph/non-state-conditioned baseline. But `BUILD-SPECS.md:296` states, as an apparently blanket rule attached to the `mix` bullet: "`mix` (default) — all stores; **cache consulted first in every mode**." Read literally, "in every mode" includes `episode-naive`. Per §16.4 (`ALGORITHM-v0.2-pathway-learner.md:423`), the cache store is "materialised frequent context" — i.e., it can hold content whose original provenance was a graph or state-store pull, cached for hot-path reuse. If `episode-naive` consults the cache first and the cache happens to contain graph/state-conditioned materialised context (put there by a `mix`- or `curriculum-global`-mode episode earlier in the same run), the "clean ablation baseline" silently receives graph/state-influenced signal through the cache, without ever making a direct call to `GraphStore`/`StateStore`. The one test meant to guard exactly this property, `test_naive_arm_is_clean_baseline` (`:339`: "`episode-naive` touches no graph/state store"), is phrased in terms of direct store calls — an implementation could pass that test to the letter (no direct `GraphStore`/`StateStore` invocation from the `episode-naive` code path) while still failing it in spirit (cache-mediated leakage of graph/state-derived content into the arm whose entire point is to exclude that signal). This would silently invalidate the measurable claim this build-spec exists to support (full R1 vs. `episode-naive` as a scientifically clean comparison) — the single most safety-adjacent empirical claim in the document — and it is not raised anywhere in the nine dimensions above (Efficiency 6 and Completeness 7 each look at cost/tests but not at this specific cross-mode cache-provenance leak). Either "cache consulted first in every mode" needs an explicit carve-out for `episode-naive` (cache reads restricted to vector-origin entries only, or the arm bypasses cache entirely), or the test needs to assert cache-content provenance, not just direct store calls.

## Aggregate confidence

```
critical_floor  = min(Correctness=88, RedTeam=87, Safety=88) = 87
weighted_mean   = (88×2 + 83 + 87×2 + 83 + 88×2 + 86 + 81 + 85 + 65) / 11
              = (176 + 83 + 174 + 83 + 176 + 86 + 81 + 85 + 65) / 11
              = 1009 / 11
              = 91.73
overall         = min(87, 91.73) = 87
```

**Overall confidence: 87 / 100**

## Verdict

**ready-for-approval**

All three CRITICAL dimensions (Correctness 88, Red-team resistance 87, Safety/integrity 88) clear the 70 floor by a wide margin, and the overall score (87) clears 80. Four of round 2's six numbered blockers are cleanly closed and were independently re-verified against the algorithm text (not merely accepted at face value): the `w`→`v` sweep, the `ε_mode` deterministic-quota mechanism, the "All registered in §12" correction, and the B2-Amendment-A cross-gate flag (which was also checked and found to rest on the already-approved base spec, not on the unresolved amendment). One (the cold-start `μ_m`/`SE_m` steady-state formula) is materially narrowed though not fully closed. This leaves two non-blocking items on the record that do not, on the stated formula, prevent approval but should be tracked:

1. **The header's "Adds NO new objective, gate, or belief" claim (`BUILD-SPECS.md:288`) remains unaddressed for a third round** despite being explicitly named in round 2's blocking list. It should be softened to acknowledge the `N(μ_m, SE_m)` mode-dispatch posterior as a genuinely new belief object, even while the Mechanism section's argument that it does not constitute a new *selection problem* stands.
2. **State the exact `μ_m`/`SE_m` steady-state update formula** (windowed sample mean/SD over `W_m`, the natural reading, vs. any alternative), and add a test analogous to `test_eig_falls_with_n_eff` at the mode level.
3. **Investigate the `episode-naive`/cache interaction** raised in the adversarial pass before relying on the `full-R1`-vs-`episode-naive` measurable claim: either scope "cache consulted first in every mode" to exclude non-vector-origin cache entries for `episode-naive`, or strengthen `test_naive_arm_is_clean_baseline` to assert cache-content provenance, not just direct store calls.

None of these three items involve a CRITICAL dimension or a proven-wrong formula, so they are recorded as required follow-ups rather than blocking conditions for this gate.
