# Scout proposals — 2026-07-02

Deep re-profile pass. The project already evolved the governance agents it needed (`review-360`, `change-approver`, 2026-06-26), so this pass proposes very little. The framework expands on evidence; the next evidence event is Python landing in this repo.

## Skills worth creating (when the matching work first appears)

- `skills/spec-change-gate/` — the review-360 → change-approver procedure as a written playbook (how to open a review, round numbering `-r2/-r3`, decision-record format, "approver authorizes but does not apply the commit"). **Evidence:** the flow has now run 9+ times (A1, A5, B1–B4, S16, S17/S18, S19) with a stable file/naming convention that currently lives only in the agents' heads and the reviews/ folder. **Trigger to build:** the next spec change (S20 or a BUILD-SPEC amendment) — capture the convention while executing it, via `skill-smith`.

## Agents worth creating (when the matching task type recurs)

- None yet. HANDOVER-v2 §9 names `pathway-builder` and `eval-harness-builder`, but those were scoped to the turing-agents repo. **If** [D-2] is resolved as "author `mdlp/` in this repo" (the RELEASE-PLAN recommendation), the first real Phase-A/B0 build task here is the trigger for `agent-smith` to create the in-repo equivalent(s) — not before, and not two agents until the work shows two distinct task types.

## Nothing-yet items

- **Python build/test tooling skills** (pytest conventions, package layout, CI) — no `.py` file exists in this repo yet; premature until B0 scaffolding starts.
- **A release-manager agent** — v2 release is a one-time checklist (RELEASE-PLAN §8); a checklist doc suffices unless releases recur.
- **A site-updater skill** — the Pages site has been edited twice; below the 3× threshold.

## Blocking ambiguity to resolve first (user decision, not tooling)

- The **[D-2] housing contradiction** (RELEASE-PLAN §3: author here · HANDOVER-v2 §3: stays in turing-agents) decides whether ANY build tooling ever belongs in this repo. Resolve it before creating build agents or skills.
