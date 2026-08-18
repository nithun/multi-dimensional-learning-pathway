# Proposal: quantified safety-margin sensitivity in the property-impact statement

| | |
|---|---|
| Filed by | `retrospective`, 2026-08-18 |
| Status | proposal only — **not applied**, because the skills lane is `paused` (`circuit-breaker.json`, see B-006). This is a different, narrower defect class than the one that tripped the pause (L-019's asserted-not-demonstrated class); it is filed as a proposal purely as a consequence of the lane being closed to direct writes, not because this specific device is expected to fail the same way. |
| Confidence | 0.75 |
| Lesson | L-020 |
| Target (when the lane reopens) | `skills/spec-change-gate/SKILL.md` — "Pre-submission authoring checklist," step 4 (property-impact statement) |

## The gap

Checklist step 4 requires every submission to tag each safety property PR-1..PR-N as
*preserved*, *strengthened*, or *modified-with-argument*. It does not require a
**quantified** before/after comparison when the change touches a safety margin (a
threshold, a retention window, a trip/rollback condition) — only a qualitative tag.

Two 2026-08-13 wave instances show this gap has real cost:

- `κ_reval`'s retirement was tagged "preserved"/"strengthened" in the submission's own
  property-impact statement, but `review-360` quantified it as a **2× increase** in the
  evidence margin required to trip rollback-to-freeze on an unvalidated-in-generation
  fallback (`docs/research/reviews/S10-1-epoch-discipline-review.md:29`). The
  qualitative tag was wrong; only the reviewer's arithmetic caught it.
- PR-8(iii)'s heartbeat predicate would have required a schema mechanism change smuggled
  in as a checker predicate — caught and honestly downgraded instead of built
  (`docs/research/reviews/DL-conformance-checker-review.md`, round 1).

Both were caught (nothing unsafe shipped) but both cost a full review round on a defect
class step 4 was specifically designed to prevent at the qualitative level.

## Proposed device

Add to checklist step 4: **when a change touches a safety margin (any threshold,
retention window, or trip/rollback condition — not just a property preservation claim),
the property-impact statement must state the margin's value *before* the change and
*after* the change, in the same units, before submission.** A tag of "preserved" without
a stated before/after pair is treated the same as no statement (checklist fails).

## Why deferred rather than applied now

The skills lane is paused (B-006) after `EV-77` and `EV-102` — two different
authoring-checklist devices for a *different* defect class (L-019's
asserted-not-demonstrated class) both measurably failed to reduce recurrence. This
proposal targets L-020's distinct class (unquantified safety-margin claims), and there
is no evidence yet that a quantification requirement specifically would fail the same
way RAF-7 did — but per circuit-breaker protocol, *any* write to a paused lane is a
proposal, not a direct edit, regardless of the confidence or the specific mechanism.
Revisit when the user reopens the skills lane, or fold this into whatever replaces the
self-checklist approach if L-019's finding (favor mechanical/independent checking over
authoring checklists) generalizes to a redesign of the whole pre-submission section.
