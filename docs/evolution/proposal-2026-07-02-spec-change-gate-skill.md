# Proposal: `skills/spec-change-gate/` — the review-360 → change-approver playbook

| | |
|---|---|
| Filed by | retrospective (RR-2026-07-02) |
| Confidence | 0.9 (would apply now, but no Task/Agent spawn tool was available in this run's toolset) |
| Action needed | Spawn `skill-smith` with the brief below; do not author the skill file directly (delegate-building rule) |
| Backlog row | B-003 (`docs/evolution/backlog.md`) |

## Evidence (≥3× bar cleared, 9+ occurrences)

The two-stage gate — `review-360` (0–100, critical-floor aggregation) → `change-approver`
(APPROVE/REJECT: overall > 80, Correctness/Red-team/Safety each ≥ 70, zero unresolved
blockers, check-on-the-checker) — has run for every one of these spec/build-spec changes,
per `.claude/memory/evolution-log.jsonl` and `docs/research/reviews/`:

| Artifact | Rounds | Final score | Real defect caught? |
|---|---|---|---|
| A1 info-gain | 2 | approved (r2) | round-1 REJECTED first |
| A5 warm-start | 6 | 82 | arithmetic error (round 3), diversity-filter gaps |
| B1 misconception | 3 | 82 | RC-1 reintroduction (lift gate missing `significant()`) |
| B2 prereq-gap | 3 | 78→ approved | RC-1 reintroduction (hard threshold), BFS stopping-rule bug |
| B3 fleet-transfer | 3 | 82 | zero-trust claim unenforced, shared item bank |
| B4 spacing | 3 | 82 | raw binary S-update (RC-1 analog) |
| §16 unified retrieval | 3 | 84 | z-scoring regression, dropped determinism caveat |
| §17/§18 self-mod + fleet | 3 | 45→82 | **RC-2 immutability hole** (item-generation writable — data-poisoning path) |
| §19 self-calibrating gate | 3 | 68→85 | **wrong-clause architecture** (gate controlled only the statistical clause, not generalization/cumulative) |

Average ~3 rounds, ~82/100 final. Two of the nine catches were high-consequence
(§17's poisoning hole, §19's architectural gap) — this is not a rubber-stamp process,
it is doing real, repeated, load-bearing work, and the procedure (round-numbering,
file-naming, decision format) currently lives only inside the two agents' own files
and the accreted `reviews/` folder convention, not as a standalone playbook.

`scout` independently flagged this exact gap in `docs/evolution/scout-proposals-2026-07-02.md`.

## Brief for `skill-smith`

Create `skills/spec-change-gate/SKILL.md`. Ground every rule in the evidence table
above and in `.claude/agents/review-360.md` / `.claude/agents/change-approver.md`
(read both in full — they are the source of truth for the mechanics). Cover at minimum:

1. **When to invoke the gate** — any addition/change to `docs/research/ALGORITHM-v0.2-pathway-learner.md`
   or a named item in `docs/research/BUILD-SPECS.md`. Never commit such a change without
   an APPROVED decision record.
2. **File-naming / round-numbering convention** (observed directly in `docs/research/reviews/`):
   first round is unsuffixed (`<slug>-review.md`, `<slug>-decision.md`); round 2+ appends
   `-r2`, `-r3`, … (`<slug>-review-r2.md`, `<slug>-decision-r2.md`). Note the one
   inconsistency seen in the record (`B2-prereq-gap-review-2026-06-26.md` uses a date
   suffix instead of `-r1`/no-suffix for its first file, then reuses that same name across
   rounds via in-place `update` actions) — flag it as the naming convention to prefer
   going forward (slug + optional `-rN`, not a date suffix).
3. **Round arithmetic** — expect ~3 rounds average to reach approval; a first round in
   the 45–78 range is normal for a substantive change, not a sign of a broken process.
4. **The separation of duties** — `review-360` never approves; `change-approver` never
   re-reviews the artifact, only applies the three gates to review-360's own report
   (G1 overall > 80, G2 each CRITICAL dim ≥ 70, G3 zero blockers) plus the
   check-on-the-checker override (a buried critical/blocking finding overrides an
   inflated headline score to REJECT).
5. **The approver authorizes but never commits** — the committing agent/user applies
   the change afterward, citing the decision record.
6. **What the gate is good at catching** — cite the two real high-consequence catches
   (§17 RC-2 immutability/poisoning hole at round-1=45; §19 wrong-clause architecture
   at round-1=68) as the concrete "this is why we do this" evidence, not hypothetical.

Keep it MVP — this is a process playbook, not a re-statement of the two agent files.
Link back to `.claude/agents/review-360.md` and `.claude/agents/change-approver.md`
rather than duplicating their full content.

## Why deferred to a proposal instead of applied now

Confidence and evidence both clear the bar for immediate action (0.9). The only reason
this landed as a proposal rather than a completed skill in this run is mechanical: this
retrospective run's tool set did not include a `Task`/`Agent` spawn primitive, and the
delegate-building rule forbids `retrospective` authoring skill files directly. The next
run (or any session where `skill-smith` can be spawned) should execute this brief
as-is — no further evidence-gathering needed.
