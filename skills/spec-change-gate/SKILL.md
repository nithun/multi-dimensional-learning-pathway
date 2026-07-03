---
name: spec-change-gate
description: Use when proposing, revising, or about to commit any change to docs/research/ALGORITHM-v0.2-pathway-learner.md or a named item in docs/research/BUILD-SPECS.md. Covers the review-360 -> change-approver two-stage gate — round-numbering, file-naming, the decision-record format, and the separation of duties between reviewer and approver. Triggers: "spec change", "algorithm change", "build-spec item", "gate this change", "review this section", "get this approved", "before I commit this edit to the spec".
---

# Spec-change-gate skill

Any addition or change to `docs/research/ALGORITHM-v0.2-pathway-learner.md` or a named
item in `docs/research/BUILD-SPECS.md` is a research-integrity risk, not a normal edit —
a wrong formula, a reopened red-team failure mode, or a silently-weakened gate compounds
into every downstream section. This project runs such changes through a two-stage gate,
`review-360` (scores it) then `change-approver` (decides), before the change is ever
committed. Done naively — skipping the gate, or letting one agent both review and approve
— the two catches this flow has already made (a data-poisoning hole and a wrong-clause
gate architecture, both at round 1) would have shipped straight into the spec.

This is a process playbook. It does not restate the two agents' full mechanics — read
`.claude/agents/review-360.md` and `.claude/agents/change-approver.md` for those.

## When to use which approach

- **Any change to `ALGORITHM-v0.2-pathway-learner.md` (new section, revised section,
  parameter change) or a named `BUILD-SPECS.md` item** → always runs the gate. There is
  no "small enough to skip" exception in the record to date.
- **A change already REJECTED once** → re-submit to `review-360` again (new round, not
  a patched version of the old review), then re-spawn `change-approver` on the new report.
- **A change you believe is obviously correct** → still gate it. The two real
  high-consequence catches (below) were both changes their authors likely believed were
  sound; round-1 scores of 45 and 68 said otherwise.

## The procedure

1. **Spawn `review-360`** on the artifact (build-spec item, or a described/diffed change
   to the algorithm doc). It reads the artifact plus supporting docs, scores nine
   dimensions 0-100, runs one adversarial pass, and computes:
   ```
   critical_floor = min(Correctness, Red-team resistance, Safety)
   weighted_mean  = (Correctness*2 + DesignFaithfulness + RedTeam*2 + Implementability
                      + Safety*2 + Efficiency + Completeness + Consistency + Calibration) / 11
   overall        = min(critical_floor, weighted_mean)
   ```
   It writes `docs/research/reviews/<slug>-review.md` and never approves and never edits
   the artifact.

2. **Spawn `change-approver`** on that review report. It applies three gates, not a
   re-review:
   - G1: overall confidence **> 80**
   - G2: Correctness, Red-team resistance, Safety each **>= 70**
   - G3: **zero** unresolved blocking items
   - plus **check-on-the-checker**: if a critical/blocking finding is buried in the body
     while the headline score is still > 80, override to REJECT as "review miscalibrated."

   It writes `docs/research/reviews/<slug>-decision.md` with verdict APPROVED or
   REJECTED, and never re-reads the artifact under review.

3. **If REJECTED**, fix the artifact per the decision record's numbered required changes,
   then repeat from step 1 as the next round (see naming below). Expect roughly 3 rounds
   to reach approval on a substantive change — a first-round score in the 45-78 range is
   normal, not a sign the process is broken (average across 9 runs: ~3 rounds, ~82 final).

4. **If APPROVED**, the decision record authorizes the commit — it does not perform it.
   The committing agent/user applies the change and cites the decision record's path in
   the commit message.

## Round-numbering / file-naming convention

Observed directly in `docs/research/reviews/`:

- **Round 1**: unsuffixed — `<slug>-review.md`, `<slug>-decision.md`.
- **Round 2+**: append `-rN` to both — `<slug>-review-r2.md`, `<slug>-decision-r2.md`,
  `<slug>-review-r3.md`, etc. A new REJECT/APPROVE cycle always gets a new pair of files;
  `change-approver` never edits an existing decision record in place.
- **Prefer slug + `-rN`, not a date suffix.** One record deviates from this:
  `B2-prereq-gap-review-2026-06-26.md` used a date suffix for round 1 and then reused
  that same filename across rounds via in-place edits instead of `-r2`/`-r3`. That is the
  pattern to avoid going forward — it collapses the round history into one file and loses
  the audit trail the `-rN` convention preserves.

## Rules (non-negotiable)

- **The gate runs before every commit to a gated artifact, no exceptions.** — the flow
  ran 9+ times with no skipped instance (A1, A5, B1-B4, S16, S17/S18, S19); *source: L-010*.
- **`review-360` never approves; `change-approver` never re-reviews the artifact** —
  separation of duties is the point: neither agent can unilaterally push a bad change
  through. *Source: `.claude/agents/review-360.md` INVARIANTS, `.claude/agents/change-approver.md` "You are a separation-of-duties gate".*
- **The approver authorizes, never commits.** Every APPROVED decision record ends with
  "Authorized for commit... The change-approver does not apply the edit; the committing
  agent or user must reference this record when creating the commit." *Source:
  `docs/research/reviews/S17-S18-selfmod-fleet-decision.md:28`, L-010.*
- **Check-on-the-checker overrides a flattering headline score.** A buried
  critical/blocking finding forces REJECT even if the overall number clears 80. *Source:
  `.claude/agents/change-approver.md` "Check-on-the-checker rule".*
- **A round-1 score in the 45-78 range is expected, not a process failure.** Two of the
  nine gate runs caught real, high-consequence defects at exactly that stage: S17/S18
  (round 1 = 45/100, 8 blockers — an item-generation immutability hole that would have
  allowed data poisoning) and S19 (round 1 = 68/100 — the gate as spec'd controlled only
  the statistical clause, not the generalization/cumulative clauses). Both reached
  approval by round 3 (82 and 85 respectively) after real revision, not score inflation.
  *Source: `docs/research/reviews/S17-S18-selfmod-fleet-decision.md`,
  `docs/research/reviews/S19-self-calibrating-gate-review.md`, L-010.*

## Anti-patterns

- **Patching an existing review/decision file in place across rounds** (the B2 date-suffix
  case) → use `-r2`, `-r3`... on fresh filenames instead; it is what makes "9+ runs,
  ~3 rounds average" auditable after the fact.
- **Treating `change-approver`'s job as re-reviewing the artifact** → it consumes
  `review-360`'s report only; if you find yourself re-reading the algorithm doc inside
  `change-approver`, that work belongs in a new `review-360` round instead.
- **Committing on an APPROVED decision record without citing it** → the commit message
  or PR description should reference `docs/research/reviews/<slug>-decision.md` so the
  authorization is traceable.
- **Treating a low round-1 score as a signal to abandon or water down the change** →
  the two highest-value catches in this project's history happened exactly there; revise
  and re-submit instead.

## Examples

Two real gate runs, both catching a high-consequence issue at round 1:

```
docs/research/reviews/S17-S18-selfmod-fleet-review.md       (round 1: 45/100, 8 blockers)
docs/research/reviews/S17-S18-selfmod-fleet-review-r2.md     (round 2: 80/100, 3 notes)
docs/research/reviews/S17-S18-selfmod-fleet-review-r3.md     (round 3: 82/100, 0 blockers)
docs/research/reviews/S17-S18-selfmod-fleet-decision.md      (APPROVED, cites review-r3)

docs/research/reviews/S19-self-calibrating-gate-review.md    (round 1: 68/100, wrong-clause architecture)
docs/research/reviews/S19-self-calibrating-gate-review-r2.md
docs/research/reviews/S19-self-calibrating-gate-review-r3.md (round 3: 85/100)
docs/research/reviews/S19-self-calibrating-gate-decision.md  (APPROVED, cites review-r3)
```

The anti-pattern to avoid:

```
docs/research/reviews/B2-prereq-gap-review-2026-06-26.md   (date suffix, edited in place
                                                              across rounds instead of -r2/-r3)
```
