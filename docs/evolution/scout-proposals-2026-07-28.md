# Scout proposals — 2026-07-28

Re-profile pass after the external-study build cycle, the 2026-07-28 TA audit (IX-040), and HANDOVER-v3 / M-R. Deliberately minimal: the existing tooling (review-360 + change-approver gate, `skills/spec-change-gate/`, the evolution backlog) already covers the observed recurring work. Nothing new is justified by evidence today.

## Skills worth creating
- None new. The one recurring technical concern (gated spec authoring) is already captured in `skills/spec-change-gate/SKILL.md` incl. the L-013 checklist, and B-003 closed on adherence.

## Agents worth creating
- None new. Trigger to revisit: if the AUT-1..4 proposals go through the gate and a *recurring* "autonomy-spec review" viewpoint emerges that review-360's generic viewpoints keep missing, consider a viewpoint extension to review-360 (an edit, not a new agent).

## Nothing-yet items
- **Read-only TA-audit skill.** TA audits have now run 4× (IX-014/030/036/040) with a stable shape (parallel review agents vs specs, L-012 read-only, findings cross via the user). One more occurrence with the same shape would justify a `skills/ta-audit/` playbook capturing: the 4-way split (math/integrity/wiring/bugs), the "built-but-unwired" checklist, and the file:line citation discipline. Not yet — the shape only stabilized on the 4th run.
- **Corpus/eval tooling here.** M-R's representative corpus is built in TA by the user, not here (L-012). No corpus-builder capability belongs in this repo unless the user relocates that work.
- **Autonomy-loop agents/daemon work.** B-002 (this repo's own daemon) remains queued and stale — a user decision, not a build item.

## Housekeeping surfaced to the user (not proposals)
- Branch `research/external-repo-study-2026-07-13` (13 commits) unmerged; `main` unpushed (7 ahead of origin); HANDOVER-v3 + 2 study docs uncommitted — all await your authorization.
