# Decision: APPROVED — B2-amendA-typed-edges

**Date:** 2026-07-13
**Approver:** change-approver
**Review source:** docs/research/reviews/B2-amendA-typed-edges-review-r8.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 85 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 88 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 88 | >= 70 | PASS |
| G2: Safety floor | Safety score | 85 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. G1: round-8's overall confidence is 85, clearing the >80 bar (critical_floor = min(88, 88, 85) = 85; weighted_mean = 92; overall = min(85, 92) = 85). G2: all three CRITICAL-dimension floors clear 70 with margin — Correctness 88, Red-team resistance 88, Safety 85 — none close to the 70 floor. G3: round 7's sole carried blocking item (the worked capacity example's arrival-rate justification falsely attributed to `n_trigger`) is verified closed in round 8 on the honest terms round 7 itself specified as sufficient: the `≤3/trigger` figure is now explicitly labeled a stipulated illustration input, not a derived bound, and the amendment concedes its own no-type-short-circuit design can legitimately yield more candidates per trigger than the illustration assumes — closing the five-round (rounds 2, 3, 4, 5/6, 7) cited-mechanism-overclaim pattern this review has tracked since round 2. The full cross-round audit in the r8 report verifies all 34 items accumulated across rounds 1–6, round 7's blocking item, and round 7's adversarial finding as closed against the current text (`BUILD-SPECS.md:213-262`), with zero blocking items remaining. Check-on-the-checker: the r8 report itself explicitly frames all three residual findings (the `A_cap`-bounded wait-time looseness, the missing high-fan-out test, and the two base-B2 advisories) as non-blocking, confined to an explicitly-labeled illustrative aside that does not affect the load-bearing guarantee — no item in the findings body is tagged critical/blocking/must-fix or severity >= HIGH while the headline score stands at 85, so no override is triggered; the review is not miscalibrated.

**Advisories carried forward (non-blocking, per the S16/R1 precedent — the implementer should be aware of these but they do not gate this approval):**
1. In `BUILD-SPECS.md:234`'s worked-example clause, "the worst case is `A_cap`-bounded" is in tension with the same paragraph's own "stays evicted only *while* strictly more-severe candidates keep arriving." Either drop the `A_cap`-bounded wait-time claim from the illustration, or restate it precisely as a bound on priority-inversion magnitude (z-units), not wait time (triggers).
2. No test currently exercises a single-trigger, high-fan-out scenario (several candidates from one composite skill's own walk) against `Q_max`/`b_conf` capacity — worth adding alongside `test_both_types_reach_candidacy`/`test_queue_bounded_under_sustained_arrival` to directly validate the amendment's own "no small constant is guaranteed" claim.
3. Carried from the base B2 decision record (`B2-prereq-gap-decision.md`, advisories 2–3), out of this amendment's scope: the `redirect_log` state record and an explicit decay-rate characterization remain unspecified.

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`B2-amendA-typed-edges-review-r8.md` to be committed. The change-approver does not apply the
edit; the committing agent or user must reference this record when creating the commit.
