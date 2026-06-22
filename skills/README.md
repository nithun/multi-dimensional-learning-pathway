# skills/

Reusable playbooks for recurring technical concerns. **Empty on purpose** — skills are created on demand, not up front (the framework expands on evidence, not speculation).

## How skills appear here

When a technical concern recurs (≥3 times, or once with high consequence) and reduces to a concrete procedure, the `skill-smith` agent writes `skills/<topic>/SKILL.md`. From then on, the read-first protocol (see `CLAUDE.md`) loads the matching skill before any task on that topic.

## Anatomy

```
skills/<topic>/SKILL.md
```

Each `SKILL.md` follows the **portable SKILL.md standard** (agentskills.io / Anthropic skills): frontmatter (`name`, `description` written for retrieval) and a body — when to use which approach, a mechanical procedure, non-negotiable rules (each citing its source), anti-patterns, and real examples from this project. Sticking to the standard keeps skills portable and lets them **compound** across the project over time (adopted from Multica's skill-reuse model).

## Creating one

Don't hand-write these unless you're prototyping. Instead:

- Tell the user / main Claude: "we keep needing X — write a skill for it", which spawns `skill-smith`, or
- Let `retrospective` detect the recurrence and spawn `skill-smith` itself.

This keeps every skill grounded in real, repeated need and logged in `evolution-log.jsonl`.
