# Decision: APPROVED — B2-prereq-gap

**Date:** 2026-06-26
**Approver:** change-approver
**Review source:** docs/research/reviews/B2-prereq-gap-review-2026-06-26.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 83 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 90 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 83 | >= 70 | PASS |
| G2: Safety floor | Safety score | 88 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**
All three gates pass. The round-3 review reached overall confidence 83 (G1 threshold > 80), with all three critical-dimension floors well above the 70 floor: Correctness 90, Red-team resistance 83, Safety 88 (G2). The two round-2 hard blockers (missing parameter defaults and unquantified trigger condition) and the round-2 adversarial objection (premature `g.decay_edges()` firing before transfer can manifest) are all resolved via the `d_max=4`, `n_trigger=3`, `n_post=5` additions and the post-mastery temporal guard (G3: zero unresolved blockers). The check-on-the-checker scan found three moderate residuals (Finding 3-C: edge-confidence traversal filter absent; Finding 4-D: `redirect_log` state record unspecified; Finding 5-C: decay rate uncharacterized) and one adversarial known limitation (single-session clustering of `n_post` observations for human learners) — all four are explicitly labelled non-blocking in the review body and verdict, consistent with the headline score of 83. No contradiction was found between the findings and the headline score.

The following advisory (non-blocking) items should be addressed in the implementation phase or a future spec revision:

1. **Finding 3-C — RC-4 edge-confidence traversal filter:** Add a traversal guard `edge.confidence >= tau_traverse` to the BFS walk to avoid diagnosing prereq paths the graph has already learned are unreliable.
2. **Finding 4-D — Post-redirect state record:** Define a `redirect_log` entry (e.g., `{skill_S, prereq_P, mastery_confirmed_at, n_post_observations}` in `TruthStore` or a `Diagnose`-owned `StateStore` record) so the `n_post` window is tracked consistently across sessions and implementors.
3. **Finding 5-C — Decay rate:** Characterize or inherit from §5.1 an explicit default decay rate per negative post-redirect outcome, so the safety recovery window is quantified.
4. **Adversarial objection — Session-boundary guard for human learning:** Consider requiring a minimum session boundary (or elapsed time) between P-mastery and the S-lift check, in addition to `n_post>=5`, to allow sleep-consolidation effects to manifest. Flag as a B4-adjacent concern; can be a known limitation in this spec.

## Next step

**Authorized for commit.** This decision record authorizes the change described in `B2-prereq-gap-review-2026-06-26.md` (revised build-spec B2 in `docs/research/BUILD-SPECS.md`) to be committed. The change-approver does not apply the edit; the committing agent or user must reference this record when creating the commit.
