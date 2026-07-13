# 360 Review: B2-amendA-typed-edges (round 8) — 2026-07-13

| Field | Value |
|---|---|
| Artifact | `docs/research/BUILD-SPECS.md:213-262` (Amendment A to the approved B2, round 8 — "typed hierarchy edges + derived traversal order") |
| Proposed change | Round-8 revision: fixes round 7's sole blocking item by relabeling the worked capacity example (`:234`) as **"illustrative, not load-bearing"**; the `arrival ≤ 3/trigger` figure is now explicitly a **stipulated illustration input**, no longer attributed to `n_trigger`; the text now states plainly that a branchy walk can legitimately yield several candidate roots per trigger ("no small constant is guaranteed"); and the actual, arrival-independent guarantee (`Q_max` + `queue_rank` eviction + capped aging bound the backlog and degrade to triage order under any arrival composition, never silent drops) is restated as the load-bearing claim, separate from the illustration |
| Reviewer | review-360 |
| Date | 2026-07-13 |

## Circuit-breaker check

`.claude/memory/circuit-breaker.json`: `agents.status = "open"`. Filing as a full review report (not a proposal).

Scope note: fresh re-review of Amendment A (`BUILD-SPECS.md:213-262`) against round 7 (`docs/research/reviews/B2-amendA-typed-edges-review-r7.md`, overall 79 — one point short of gate, needs-revision, exactly one blocking item), with an explicit audit of every numbered item accumulated across rounds 1–7. The approved B2 base (`BUILD-SPECS.md:182-211`) and `B2-prereq-gap-decision.md` are fixed context.

## Full cross-round item audit

### Rounds 1–6's 34 items (25 from rounds 1–4 + 5 from round 5 + 4 from round 6, all previously verified closed and unaffected through round 7) — spot-checked against the round-8 text

Round 8's only edit is confined to the worked-capacity-example clause inside `:234` (the amendment is byte-identical elsewhere; line range `213-262` is unchanged from round 7). None of the round 1–6 mechanisms — the `Edge` schema (`:219`), the `weight` reservation (`:221`), the no-type-short-circuit collection rule (`:222`), the `q_edge` soft-floor re-admission channel (`:222`), the `priority(e→P)` formula and degenerate-frontier fallback (`:223-227`), the `queue_rank`/`gap_z`/`age`/`A_cap` formulas (`:229-233`), the union acyclicity mechanism (`:235`), the `hard`-tie-break (`:236`), or the Plug-point (`:237`) — are touched. Spot-checked at their cited lines: all remain closed, no regression. **34/34 remain closed.**

### Round 7's 1 blocking item + 1 adversarial finding — checked against the round-8 text

| # | Round-7 required change | Status in r8 |
|---|---|---|
| 1 | Fix or retract the worked capacity example's arrival-rate justification (`:234`): either derive `≤3/trigger` from an actual structural bound, or explicitly relabel it as a stipulated, not derived, illustrative scenario | **Closed, cleanly, taking exactly the option round 7 offered and the amendment had not yet taken.** `:234` now reads: *"Worked capacity example (r8) — illustrative, not load-bearing: defaults confirm `⌊b_conf/n_conf⌋ = 3` candidates per trigger. **Take arrival ≤ 3 new candidates per trigger as a stipulated illustration input, not a derived bound** — a single skill's branchy walk can legitimately yield several candidate roots in one trigger (that is the no-short-circuit design working as intended), so no small constant is guaranteed."* This directly retracts the round-7 `n_trigger`-based derivation (no longer present anywhere in the text) and replaces it with the honest label round 7 requested. Verified: `⌊b_conf/n_conf⌋ = ⌊15/5⌋ = 3` is itself a *correctly derived* quantity — it is **confirmation capacity per trigger** (a fact about `b_conf`/`n_conf`, both stated parameters, `:238`), a categorically different thing from **arrival rate** (a fact about the graph and learner behavior, which nothing in the amendment bounds) — the text now keeps these two quantities cleanly separated, which is exactly what rounds 5–7 conflated or mis-derived. |
| 2 | Resolve the direct contradiction between the "one per distinct failing skill" framing and `:222`'s "no type short-circuit... edge type never drops a candidate" design principle / `test_both_types_reach_candidacy` | **Closed.** The new text explicitly concedes the point rather than continuing to assert against it: "a single skill's branchy walk can legitimately yield several candidate roots in one trigger (**that is the no-short-circuit design working as intended**)." This is now a *statement in agreement with* `:222` and `test_both_types_reach_candidacy` (`:244`), not in tension with them. Verified no remaining occurrence of a "bounded per-skill candidate count" claim anywhere in the amendment. |
| 3 | If retracted/relabeled, confirm the downstream numeric claims ("drains at steady state," "waits ≈2 triggers") are illustrative only, and that the load-bearing guarantee doesn't require them | **Closed.** The illustrative clause is explicitly scoped ("under the stipulated rate the queue drains at steady state, a median-`queue_rank` arrival waits ≈2 triggers, and the worst case is `A_cap`-bounded"), and the paragraph closes with a separately-labeled, unconditional claim: **"The actual guarantee is arrival-independent: `Q_max` + `queue_rank` eviction + capped aging bound the backlog and degrade to the stated triage order under any arrival composition — never to silent drops."** This is exactly the arrival-independent guarantee round 7 itself verified as sound and structurally distinct from the flawed assumption (r7 Correctness: "the actual safety-relevant guarantee... holds independently of whether the ≤3/trigger premise holds"). |
| Adv. | Round 7's adversarial finding (process-level): five consecutive rounds (2, 3, 4, 5/6, 7) showed the same species of error — fixing one round's overclaim in a passage introduces a fresh, differently-shaped overclaim in the same passage. Concrete ask: derive the bound structurally, or explicitly acknowledge it as unbounded/stipulated | **Substantially closed for the specific overclaim the finding named; one narrower, non-load-bearing residual surfaces in its place — see Correctness and the round-8 adversarial pass below.** Round 8 takes exactly option (b) the round-7 objection proposed ("explicitly acknowledged as unbounded, with the worked example relabeled as depending on a stipulated, not derived, arrival rate") rather than inventing a new structural derivation — so the specific five-instance pattern (crediting a named mechanism, e.g. `n_trigger`, with a guarantee it structurally cannot provide) does not recur in this round's edit. A distinct, much narrower imprecision is introduced in the same clause ("the worst case is `A_cap`-bounded" sits in tension with the same paragraph's own "stays evicted only *while* strictly more-severe candidates keep arriving" — see Correctness) — this is not the same failure mode (it is a units/scope looseness inside an explicitly-illustrative aside, not a false attribution of a load-bearing guarantee to a named mechanism), so the chain is treated as broken for the specific finding, with the residual flagged fresh below rather than counted as a sixth instance of the identical pattern. |

**Net for round 8: the single blocking item carried since round 6 is closed, cleanly, on the terms round 7 itself specified as acceptable. The round-7 adversarial finding's specific ask is honored; a narrower, non-blocking looseness is introduced in the same illustrative aside (see below) — smaller in kind and consequence than the pattern it replaces, but worth naming so the amendment's editing history doesn't quietly repeat the shape of the problem at a smaller scale.**

## Dimension scores

| # | Dimension | Score | Status |
|---|---|---|---|
| 1 | Correctness (CRITICAL) | 88 | pass |
| 2 | Design faithfulness | 80 | pass |
| 3 | Red-team resistance (CRITICAL) | 88 | pass |
| 4 | Implementability | 84 | pass |
| 5 | Safety / integrity (CRITICAL) | 85 | pass |
| 6 | Efficiency / cost | 81 | pass |
| 7 | Completeness | 76 | weak |
| 8 | Consistency | 86 | pass |
| 9 | Calibration / honesty | 84 | pass |

## Findings by dimension

### 1. Correctness

- **The round-7 blocking misattribution is fully retracted, and the replacement text is internally sound.** `:234` no longer claims `arrival ≤ 3/trigger` follows from `n_trigger ≥ 3` (`BUILD-SPECS.md:187`); it is now labeled "a stipulated illustration input, not a derived bound." Verified: `n_trigger` still appears nowhere in the arrival-rate sentence, closing the exact defect r7 identified.
- **`⌊b_conf/n_conf⌋ = 3` is a genuinely, correctly derived quantity** — `b_conf = 15` (`:238`), `n_conf ≥ 5` (`:238`, "the existing base parameter"), `⌊15/5⌋ = 3`. This is **confirmation-capacity per trigger** (how many candidates the budget can floor-confirm in one trigger), a different quantity from arrival rate (how many new candidates the walk produces), and the text now keeps the two cleanly separated — this distinction is exactly what would resolve the ambiguity a careless reading of rounds 5–7 risked.
- **New, narrow, non-load-bearing imprecision: "the worst case is `A_cap`-bounded" is in tension with the paragraph's own stated triage tradeoff two sentences earlier.** `:234` states, unchanged since round 6/7: "a capped candidate stays evicted only *while* strictly more-severe candidates keep arriving — triage, not starvation" — i.e., wait time has **no absolute bound**; it is conditional on arrival relenting. `test_eviction_cannot_starve_forever`'s own description (`:249`) matches this: "while strictly-more-severe candidates keep arriving it may stay evicted... but never loses candidacy" — again, no bound on *how long*, only a guarantee it isn't forever conditional on arrival eventually relenting. The illustrative clause's "the worst case is `A_cap`-bounded" reads as an absolute wait-time bound, but `A_cap` (3 z-units, `:238`) bounds **priority-inversion magnitude** (how many z-units of fresher severity an aged candidate can be outranked by), not **wait time in triggers** — these are different units, and the paragraph's own honest-tradeoff sentence contradicts an absolute-bound reading. This is a real, checkable imprecision, but its blast radius is small: it sits entirely inside the paragraph's own "illustrative, not load-bearing" clause (which the amendment now explicitly disclaims as non-guaranteed), and the separately-stated load-bearing guarantee at the end of the same sentence ("`Q_max` + `queue_rank` eviction + capped aging bound the backlog... under any arrival composition — never to silent drops") does not depend on it and is correct as stated (verified algebraically in round 7, unchanged since). Scored as a minor Correctness deduction, not blocking.
- All previously-verified formulas (`priority(e→P)`, `gap_z`, `queue_rank`, the `q_edge` Bernoulli re-admission latency `~1/q_edge`) remain unchanged and correct, unaffected by this round's single edit.

### 2. Design faithfulness

- Unaffected by this round's edit. Carried, non-blocking (unchanged since round 5): the `§19.1` `q_explore` citation at `:222` remains an imprecise analogy — `q_explore` is an isolated, non-decision-affecting shadow mechanism (`ALGORITHM-v0.2-pathway-learner.md:562`, "outcomes are recorded only"), while `q_edge` is a live, decision-affecting quota; `§5.3`'s `reachability_exploration`/R1's `ε_ret`, cited in the same sentence, are the accurate analogs.
- Carried, non-blocking (unchanged since round 2): `priority(e→P)`'s unweighted 1:1 additive combination has no `λ` analog of `§5.3`'s explicit, registered weight (`ALGORITHM-v0.2-pathway-learner.md:165`).
- Carried, non-blocking (unchanged since round 3): no explicit authoring-API sentence for Teacher-created `part_of`/`hard` edges; the Plug-point (`:237`) still only strongly implies the write path via `GraphStore.merge()`.
- Carried, non-blocking, out of scope for this amendment (from the base B2 decision record, `B2-prereq-gap-decision.md`, advisories 2–3): the `redirect_log` state record and the decay-rate characterization are still unspecified; this amendment does not touch them and was never asked to.

### 3. Red-team resistance

- **RC-4's closed-loop reopening remains genuinely closed** (soft floor + `q_edge`, unaffected by this round).
- **RC-1 (masking at candidacy/confirmation) remains closed** — no type short-circuit + `n_conf` floor + evidence-only expiry, unaffected, and the round-8 edit now makes the amendment's own "no small constant is guaranteed" framing an explicit statement of the same RC-1 discipline (a bounded arrival assumption cannot be assumed to hold merely because it would be convenient — the honest fallback, arrival-independent guarantee, is what actually governs).
- **The round-5/6 adversarial finding (unbounded aging → unbounded priority inversion) remains fully closed**, unaffected by this round (the `queue_rank` formula that closed it is untouched).
- **A residual, narrower observation relevant to red-team framing:** had the previous rounds' false `n_trigger`-derived bound survived into an implementation, an implementer sizing `Q_max`/`b_conf` off a falsely-derived "≤3/trigger" ceiling could under-provision capacity, and a learner (or an adversarial curriculum author) producing a genuinely branchy composite failure could exceed that assumed ceiling — a availability/DoS-adjacent risk on the confirmation queue. This round's explicit "no small constant is guaranteed" + the restated arrival-independent guarantee closes that risk cleanly; scoring this dimension slightly above round 7 to reflect that closure.
- RC-4 (mixed-type cycles, authored edges), RC-4 inverse (hard-edge density) — remain closed, unaffected.

### 4. Implementability

- **Genuine improvement over round 7:** a developer reading `:234` now has an unambiguous instruction — the numeric example is a worked illustration to sanity-check the mechanism, not a specification to build a capacity ceiling against; the load-bearing guarantee (arrival-independent backlog bound) is separately and plainly stated as what to actually implement and test against. This closes round 7's implementability wrinkle ("a developer sizing test fixtures... off the flawed assumption").
- **Minor residual:** the "worst case is `A_cap`-bounded" imprecision (Correctness, above) could still mislead an implementer into writing a test asserting an absolute wait-time bound in triggers, which the amendment's own honest-tradeoff sentence ("while more-severe candidates keep arriving") does not actually support. None of the amendment's own tests (`test_aging_cap_bounds_inversion`, `test_eviction_cannot_starve_forever`, `:250-251`) assert such a bound, so this is a documentation-only risk, not a test-level one.
- Carried, non-blocking (unchanged since round 3): no explicit authoring-API sentence for Teacher-created edges.

### 5. Safety / integrity

- The §8 commit gate, §14 calibration layer, and the verifier (`HUMAN-LEARNING-VERIFIER.md`) remain untouched.
- Base B2's integrity hinge ("confirm before redirect + verify the redirect helped," `BUILD-SPECS.md:211`) is unaffected — confirmation still gates every redirect regardless of arrival composition or the worked example's framing.
- No new gate weakening introduced. If anything, retracting the false arrival-rate derivation and stating the guarantee's arrival-independence explicitly is a small positive for integrity: it removes a document-level claim that, if trusted uncritically by a future implementer or reviewer, could have led to an under-provisioned confirmation queue being mistaken for a safe design.

### 6. Efficiency / cost

- No new LLM calls. The edit is a documentation-only change to one worked example's framing; no new asymptotic cost, unchanged from round 7's assessment.

### 7. Completeness

- **The completeness gap round 7 flagged ("a wrong justification is now presented as settled") is substantially eased** — the justification is no longer wrong, and it is now explicitly labeled non-load-bearing, so the prior absence of a test backing its specific numeric claims ("drains at steady state," "waits ≈2 triggers") is now honestly scoped as expected (an illustration, not a spec) rather than an unflagged gap.
- **Still no test exercises a high-fan-out scenario** — i.e., a single trigger yielding more than 3 candidates (the composite-with-multiple-weak-constituents case the amendment's own text now explicitly concedes is normal, not pathological, for the no-type-short-circuit design). `test_both_types_reach_candidacy` (`:244`) demonstrates ≥2 candidates from one trigger but not a stress case near or beyond `Q_max`/`b_conf` capacity from one skill's walk alone. Given the amendment now explicitly disclaims a bound on this ("no small constant is guaranteed"), a regression test exercising the arrival-independent guarantee (`Q_max` + `queue_rank` + aging) under a *concretely high* single-trigger fan-out (e.g., 6+ candidates from one composite skill's constituents) would directly validate the claim that actually matters, rather than leaving it to `test_queue_bounded_under_sustained_arrival` (`:248`), which is phrased around *sustained* multi-trigger arrival rather than *single-trigger* fan-out.
- Carried, non-blocking (from the base B2 decision record): `redirect_log` and decay-rate characterization remain unspecified; out of this amendment's scope.

### 8. Consistency

- **The round-7 internal contradiction (arrival ≤3/trigger vs. no-type-short-circuit + `test_both_types_reach_candidacy`) is fully resolved** — the new text explicitly concedes the design principle rather than contradicting it, verified by direct textual comparison of `:222`, `:234`, and `:244`.
- **A minor, narrower internal tension is introduced in the same clause** (Correctness, above): "the worst case is `A_cap`-bounded" vs. the same paragraph's "stays evicted only *while* strictly more-severe candidates keep arriving." Both describe wait-time behavior for an aged candidate, and a careful reading finds them in tension (one implies an absolute cap, the other implies no absolute cap given sustained severe arrival). Confined to the illustrative aside; does not propagate to the load-bearing guarantee sentence that follows it, which is internally consistent with the rest of the amendment.
- `DATA-LAYER.md:76,141,213` citations remain accurate; the `q_explore`-analogy imprecision (Design faithfulness, above) recurs here as a minor, unchanged citation-accuracy issue.

### 9. Calibration / honesty

- **Genuine, substantial improvement on the specific meta-pattern this review has tracked since round 2.** Rounds 2 (`weight`/`reach_weight` conflation), 3 ("starvation-proof" framing), 4 (`τ_traverse` "not a structural override"), 5/6 (arrival-damping misattribution), and 7 (`n_trigger`-derived arrival bound) each showed "a cited mechanism credited with a guarantee it does not actually provide." Round 8 breaks the pattern for this specific clause by taking the honest route explicitly offered by round 7's own adversarial objection: label the number as stipulated, concede the design implication squarely ("no small constant is guaranteed"), and separate the illustration from the actual (arrival-independent) guarantee. This is the first round in this amendment's eight-round history where a flagged overclaim is closed by **retraction and explicit non-guarantee**, rather than by asserting a different, equally-confident-sounding derivation.
- **A smaller, narrower version of the same underlying habit (overstating what a named mechanism bounds) surfaces once more, at reduced scale, inside the same now-honest clause** — "the worst case is `A_cap`-bounded" (Correctness/Consistency, above) states a bound in the wrong units/scope relative to the paragraph's own adjacent honest caveat. This is meaningfully smaller than the five prior instances: it is confined to a clause the text itself has just labeled "illustrative, not load-bearing," it does not misattribute the guarantee to an unrelated mechanism (unlike rounds 5–7), and no test encodes it. It is flagged here, and in the adversarial pass below, precisely because the review has tracked this species of claim across seven prior rounds and a genuinely rigorous pass should not wave it through merely because the containing clause is now labeled non-binding — "illustrative" should still mean "correct within its own stated scope."

## Strongest adversarial objection

The round-7 blocking item is closed, and closed honestly — but look again at the exact clause that closed it, `:234`'s worked-example paragraph, one more time before accepting it at face value. Two adjacent claims inside the same "illustrative, not load-bearing" aside are not the same claim: "under the stipulated rate the queue drains at steady state, a median-`queue_rank` arrival waits ≈2 triggers, **and the worst case is `A_cap`-bounded**" is immediately preceded, in the same paragraph, by an unrelated but directly-conflicting honest admission: "a capped candidate stays evicted only *while* strictly more-severe candidates keep arriving — triage, not starvation." If wait time were truly `A_cap`-bounded (a fixed, finite ceiling on delay), the "while... keep arriving" qualifier would be vacuous — you would never need to invoke sustained future arrival to explain why a candidate is still waiting, because the bound alone would guarantee it clears by some fixed trigger count regardless of what arrives next. The two statements can only both be true if "the worst case is `A_cap`-bounded" is read very narrowly — as a bound on priority-inversion magnitude (z-units of severity an aged candidate can be outranked by), not a bound on wait time (number of triggers) — but the sentence's own phrasing ("the worst case is...") reads naturally as a wait-time claim, sitting in a sentence about triggers-to-drain and triggers-to-wait. This is the same underlying editorial habit the last five rounds have shown — a mechanism (`A_cap`) is invoked with more confidence about what it bounds than it actually delivers — recurring in miniature, in the very clause written to retract the fifth full-scale instance of exactly that habit. The concrete, checkable ask: either drop "the worst case is `A_cap`-bounded" from the illustrative aside (the paragraph's honest triage-not-starvation admission already says everything true that can be said about worst-case wait), or state explicitly which quantity `A_cap` bounds there (priority-inversion magnitude in z-units, not trigger-count). This is not raised in full in any of the nine dimensions above in isolation — Correctness and Consistency each flag the textual tension; this is the compound observation that the very act of closing a five-round-old overclaiming pattern has, in the same edit, produced a smaller specimen of the identical species, which is the pattern this amendment's own history says to watch for most closely at exactly this moment.

Given the confined, non-load-bearing scope of this residual (it lives entirely inside a clause the amendment itself now labels "illustrative, not load-bearing," it is not encoded in any test, and the actual safety-relevant guarantee stated in the same sentence is unaffected and correct), it is treated as a non-blocking finding for this round rather than a fresh blocking item — but it is the one loose thread a hostile reviewer should point at before signing off.

## Aggregate confidence

```
critical_floor  = min(Correctness=88, RedTeam=88, Safety=85) = 85
weighted_mean   = (88*2 + 80 + 88*2 + 84 + 85*2 + 81 + 76 + 86 + 84) / 11
                = (176 + 80 + 176 + 84 + 170 + 81 + 76 + 86 + 84) / 11
                = 1013 / 11
                = 92.09 → 92
overall         = min(85, 92) = 85
```

**Overall confidence: 85 / 100**

## Verdict

**ready-for-approval**

All three CRITICAL dimensions clear 70 with margin (Correctness 88, Red-team resistance 88, Safety 85), and the overall score of 85 clears the 80 gate. The single blocking item carried from round 6 through round 7 — the worked capacity example's arrival-rate assumption — is now closed on the honest terms round 7 itself specified as sufficient: the number is explicitly labeled a stipulated illustration input rather than a derived bound, the amendment concedes outright that its own no-type-short-circuit design can legitimately produce more than the illustrated arrival rate, and the actual, load-bearing guarantee (`Q_max` + `queue_rank` eviction + capped aging bound the backlog and degrade to triage order under any arrival composition, never silent drops) is stated separately and correctly, unaffected by whether the illustration's premise holds. This closes the specific five-round overclaiming pattern (rounds 2, 3, 4, 5/6, 7) this review has tracked, for this clause.

One non-blocking residual, surfaced in this round's adversarial pass, should be picked up in implementation or the next spec touch of this passage (not required to clear the gate, since it is confined to an explicitly-illustrative, non-tested aside and does not affect the load-bearing guarantee):

1. In `:234`'s worked-example clause, "the worst case is `A_cap`-bounded" is in tension with the same paragraph's "stays evicted only *while* strictly more-severe candidates keep arriving" — either drop the "`A_cap`-bounded" wait-time claim from the illustration, or restate it precisely as a bound on priority-inversion magnitude (z-units), not wait time (triggers).
2. No test currently exercises a single-trigger, high-fan-out scenario (several candidates from one composite skill's own walk) against `Q_max`/`b_conf` capacity — worth adding alongside the existing `test_both_types_reach_candidacy`/`test_queue_bounded_under_sustained_arrival` pair to directly validate the "no small constant is guaranteed" claim the amendment now makes explicitly.
3. Carried from the base B2 decision record (non-blocking, out of this amendment's scope): the `redirect_log` state record and an explicit decay-rate characterization remain unspecified.
