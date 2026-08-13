# Scout proposals — 2026-08-13

Deep re-profile after the 2026-08-12/13 research arc (15 interactions since the 2026-07-28 pass). The inline-maintained profile was verified accurate against the repo — no claim in it needed retraction; this pass consolidated, refreshed git state, and rotated the open-questions list. The framework's tooling needs were largely just serviced by the 2026-08-13 retrospective (L-015..L-018, RAF-7 devices, P-001, B-005), so this pass proposes almost nothing new.

## Skills worth creating (when the matching work first appears)

- None now. The one existing skill (`spec-change-gate`) covers the dominant recurring work type (gated spec changes), and its effectiveness is already under a named watch (B-005) — adding tooling before that watch resolves would be building on top of an unproven layer.

## Agents worth creating (when the matching task type recurs)

- None now. `review-360` + `change-approver` cover the gate; the upcoming work (RAF-1a → ONT-1′ → LIV-1 submissions) is exactly the task type they already handle.

## Nothing-yet items

- **Scholarly-fetch-chain skill** (OpenReview/publisher PDFs behind Cloudflare: WebFetch and API blocked → browser pane → forum HTML for reviews → author sites for PDFs). One instance (IX-055). Trigger to build: a second Cloudflare-blocked scholarly fetch. Until then it lives in PLAN-harvest §4 and the IX line. (L-003: first instance — log, don't build.)
- **Study-authoring skill** (fold L-015 source-class grading + L-017 misfit analysis + the graded-confidence format of the SYNTHESIS doc into a playbook). The lessons are fresh (landed 2026-08-13) and may be sufficient on their own. Trigger to build: a future study skips grading or misfit analysis despite the lessons being in the L-001 read path.
- **Gate-submission tracker** (the first three submissions RAF-1a → ONT-1′ → LIV-1 have a declared order and [D-4] dependency). `tasks/BOARD.md` already exists for exactly this; use it before inventing anything.

## Watch items carried forward (not proposals)

- **B-005** (backlog): do RAF-7's legibility devices actually stop the schema-claimed-not-written defect class? Resolves on the next 2 gated multi-round artifacts; a 3rd recurrence trips the skills-lane circuit breaker.
- **Push state:** `main` sits 16 commits ahead of `origin/main` — the entire 2026-08 arc is local-only. Surfaced in the profile's open questions; the user owns the push.
