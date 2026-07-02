# Project profile

_Last profiled: 2026-07-02 by scout (deep pass; supersedes the 2026-06-22 in-session seed). Living document — refine inline as understanding improves._

## What this project is
- **MDLP (Multi-Dimensional Learning Pathway)** — a research project producing a probabilistic, multi-dimensional learning-pathway **algorithm** (competence inference + curriculum decision + gated self-improvement), generalized from human students to **self-learning agents**, plus a planned **`mdlp` Python library** that implements it. [verified]
- The repo today is **documentation-substance**: the algorithm spec, gate-approved build specs, paper draft, data-layer design, release plan, and review audit trail live under `docs/research/` and `docs/`. **No Python code exists in this repo yet** (`find . -name '*.py'` = 0 per RELEASE-PLAN §2). [verified]
- The repo also carries the **Turing Agents v0.2.0** self-evolving scaffold (Markdown + Bash) that the research runs on. Framing as of 2026-07-01: the framework is "generalized from Turing's own proven in-production setup" — **TAP LMS lineage references removed** (working-tree edits to CLAUDE.md/README/RELEASE-PLAN). [verified]
- **Scope rule (hard):** this session/repo manages ONLY MDLP. The `turing-agents` repo (which holds the v1 reference build of the machinery) is **never touched from here** — reference only. [verified — user memory + HANDOVER-v2 scope rule]

## Core intellectual state (as of 2026-07-02)
- **Spec of record:** `docs/research/ALGORITHM-v0.2-pathway-learner.md`, §1–§19, all additions additive. §13 Tutor, §14 calibration, §15 re-visiting (2026-06-26); §16 unified retrieval, §17 self-modification (SOLVE/JUDGE), §18 multi-agent, §19 self-calibrating gate (2026-06-27). All gate-approved. [verified]
- **§19 is gate-approved but UNCOMMITTED** — approved 85/100 by change-approver on 2026-06-29 after 3 review rounds (`reviews/S19-*`); the spec edit sits in the working tree awaiting the authorized commit. [verified]
- **Build specs:** `BUILD-SPECS.md` — **A1, A5, B1, B2, B3, B4 all ▣ APPROVED** (review-360 scores 82–85, change-approver APPROVED each). E (store-native levers) covered; G frontier items designed as §17/§18 (M3). [verified]
- **The honest fact that frames v2 (HANDOVER-v2 §1): M0 is NOT actually passed.** The turing-agents v1 "held-out +0.487, B7 GO" result was a constant **baked into a synthetic domain**; the live runner was never wired, and the DecisionEngine wasn't in the end-to-end loop. **v2 starts at Phase A: make M0 real.** Never cite the v1 result as evidence of learning. [verified]
- Corrected objective (unchanged since 2026-06-22): `A* = argmax E[Δ competence | S, A]` (learning progress), not the paper's degenerate `argmax P(success)`; `P(success)` stays as measurement primitive only. [verified]
- Two load-bearing principles: **P1** measurement independent of optimization (reward only on held-out; held-out never enters context); **P2** every `add` has an inverse. Gates are statistical (`significant()` vs SE), never scalar. [verified]

## Governance / process conventions
- **Every spec change flows the two-stage gate: `review-360` (0–100, critical-floor aggregation) → `change-approver` (three-gate policy: overall >80; correctness/red-team/safety floors ≥70; zero blockers; check-on-the-checker).** Both are evolved agents created 2026-06-26 (`.claude/agents/review-360.md`, `change-approver.md`). Decision records in `docs/research/reviews/`; the approver authorizes but does not apply the commit. [verified]
- Milestones are hard-gated, never parallelized past a gate: **M0** (real learning on held-out) → **M1** (open schema + capability suite, after C0 re-red-team) → **M2** (weight axis, GPU) → **M3** (§17/§18/§19 frontier). [verified]
- Commit style: `docs(research): …`, `docs(site): …`, `evolve: <what> — <why>`, one logical change per commit. [verified — git log]
- Framework memory: lessons L-001…L-009 active (append-and-supersede); red-team root causes RC-1…RC-8 must each keep a guarding regression test. [verified]

## v2 release plan (`docs/RELEASE-PLAN-v2.md`)
- **v2 = the algorithm as an installable `mdlp` Python library authored in THIS repo** (v1 was scaffold only). Three maturity tiers: **① Working/validated core** (state dual-Beta + `significant()`, eval gates, Tutor+A1, §14 calibration, embedded 5-store, M0 verifier loop) · **② Experimental** (A5, B1, B2, B4, B3 — unit-tested to approved specs, unvalidated end-to-end) · **③ Tag/design-only** (**C1 human verifier = tag-only; Frappe/ERPNext deferred**; M2 = docs). [verified]
- **The one hard gate: M0 acceptance** — held-out pass-rate beats a frozen no-learning baseline beyond `z·SE` on a REAL corpus, memorization/hard-code probes fail as designed. A NO-GO is a valid, publishable release outcome. [verified]
- Versioning: tag `v2.0.0`; package `2.0.0`; CHANGELOG split (MDLP line vs Turing Agents 0.x line); **GitHub-only first, PyPI deferred to v2.1**. [verified]

## Tech stack
- Now: Markdown + Bash (framework scripts under `scripts/`); GitHub Pages site (`docs/index.html`). [verified]
- Planned (v2): Python `mdlp` package — pure-stdlib-friendly core, heavy deps as optional extras; embedded default tier = SQLite + networkx + local vector index, zero external infra; full 5-store data layer (SQL / document / vector / graph / cache) per `DATA-LAYER.md`. [verified — design docs; no code yet]
- Build/test/run: none yet in this repo. v2 defines them (`pip install`, `mdlp --version`, pytest + red-team regression suite in CI). [verified]

## Layout
- `docs/research/` — the substance: `ALGORITHM-v0.2-pathway-learner.md` (spec of record) · `BUILD-SPECS.md` (approved capability specs) · `IMPLEMENTATION-v2.md` (full build doc, untracked) · `HANDOVER-v2.md` (honest status + phased plan) · `PAPER.md`/`PAPER-method-section.md` · `DATA-LAYER.md` · `ALGORITHM-INTEGRATIONS.md` (A–G register) · landscape/report/red-team docs · `reviews/` (gate audit trail).
- `docs/RELEASE-PLAN-v2.md` — release scope, tiers, decisions [D-1..D-3].
- `docs/evolution/` — framework backlog + studies; `docs/index.html` — Pages site.
- Root: `CLAUDE.md`, `WORKFLOW.md`, `README.md`, `RESEARCH-HANDOVER.md` (original brief), `EVOLUTION-LOG.md`, `VERSION` (0.2.0 = framework, collides with algorithm versioning — [D-1]).
- `.claude/agents/` — 8 framework agents + 2 evolved governance agents (`review-360`, `change-approver`). `skills/` — still empty (README only). `tasks/BOARD.md` — kanban.

## Goals / what success looks like
- Ship **v2.0.0**: installable `mdlp` (embedded default, no infra), Tier ① validated by a **real** M0 result (GO or honest NO-GO), Tier ② present-but-experimental, Tier ③ documented, README/site rewritten, CHANGELOG split, red-team regression suite green. [verified — RELEASE-PLAN §8]
- Longer arc: M1 capability suite → M2 weight axis → M3 self-modification/fleet; paper with pre-registered evaluation protocol. [verified]

## Open questions for the user
- **Library housing contradiction:** RELEASE-PLAN §3 [D-2] says author `mdlp/` **in this repo**; HANDOVER-v2 §3 (committed 2026-06-26) locks housing as "stays in `turing-agents/mdlp`". The 2026-07-01 direction favors this-repo, and the scope rule forbids touching turing-agents from here — but HANDOVER-v2 §3/§9/§10 still point builders at turing-agents. Needs one authoritative answer + a HANDOVER-v2 amendment.
- [D-1] confirmation: CHANGELOG split + VERSION handling when Python lands here.
- §19 spec edit is approved-but-uncommitted alongside unrelated working-tree changes — when/how does the authorized commit land?
- Who implements Phase A here? No Python specialists (`pathway-builder`, `eval-harness-builder`) exist in this repo's agent roster — HANDOVER-v2 §9 assumed turing-agents ones.
