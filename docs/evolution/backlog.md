# Evolution backlog

The framework's own task queue. Lifecycle: `queued → in-progress → done | dropped`. Append-and-amend; never delete a row.

| ID | Item | Type | Status | Evidence | Opened | Close condition |
|---|---|---|---|---|---|---|
| B-001 | Profile the project (run `scout`) | profile | done | project UNPROFILED | unset | project-profile.md no longer says UNPROFILED — met: deep profile landed 2026-07-02, commit 3236339 |
| B-002 | Fix the unattended curator daemon (never completed a successful run: chmod +x missing on 2026-06-22 install → `Operation not permitted`; then 401 auth failures 2026-06-25/26) | infra | queued | `.claude/daemon/launchd.err.log`, `.claude/daemon/runs/20260625-212941.log`, `.claude/daemon/runs/20260626-173811.log` | 2026-07-02 | a `.claude/daemon/runs/*.log` entry shows a completed run (no 401/permission error) after re-running `scripts/install.sh --daemon`, or the user explicitly drops unattended mode in favor of in-session-only evolution |
| B-003 | Build `skills/spec-change-gate/` (review-360 → change-approver playbook: round-numbering convention, decision-record format, "approver authorizes, never commits") | skill | queued | scout-proposals-2026-07-02.md; flow ran 9+ times (A1, A5, B1–B4, §16, §17/§18, §19); full brief at docs/evolution/proposal-2026-07-02-spec-change-gate-skill.md | 2026-07-02 | `skills/spec-change-gate/SKILL.md` exists and is referenced the next time a spec change (S20+) runs the gate |
