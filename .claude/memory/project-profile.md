# Project profile

_Last profiled: 2026-07-02 by scout (deep pass; supersedes the 2026-06-22 in-session seed). Living document — refine inline as understanding improves._

## What this project is
- **MDLP (Multi-Dimensional Learning Pathway)** — a research project producing a probabilistic, multi-dimensional learning-pathway **algorithm** (competence inference + curriculum decision + gated self-improvement), generalized from human students to **self-learning agents**, plus a planned **`mdlp` Python library** that implements it. [verified]
- The repo today is **documentation-substance**: the algorithm spec, gate-approved build specs, paper draft, data-layer design, release plan, and review audit trail live under `docs/research/` and `docs/`. **No Python code exists in this repo yet** (`find . -name '*.py'` = 0 per RELEASE-PLAN §2). [verified]
- The repo also carries the **Turing Agents v0.2.0** self-evolving scaffold (Markdown + Bash) that the research runs on. Framing as of 2026-07-01: the framework is "generalized from Turing's own proven in-production setup" — **TAP LMS lineage references removed** (working-tree edits to CLAUDE.md/README/RELEASE-PLAN). [verified]
- **Scope rule (hard):** this session/repo manages ONLY MDLP. The `turing-agents` repo (which holds the v1 reference build of the machinery) is **never touched from here** — reference only. [verified — user memory + HANDOVER-v2 scope rule]

## Core intellectual state (as of 2026-07-02)
- **Spec of record:** `docs/research/ALGORITHM-v0.2-pathway-learner.md`, §1–§19, all additions additive. §13 Tutor, §14 calibration, §15 re-visiting (2026-06-26); §16 unified retrieval, §17 self-modification (SOLVE/JUDGE), §18 multi-agent, §19 self-calibrating gate (2026-06-27). All gate-approved. [verified]
- §19 committed 2026-07-02 (`6ccc1a9`, with all four S19 review records) after user authorized the commit. [verified]
- **Build specs:** `BUILD-SPECS.md` — **A1, A5, B1, B2, B3, B4 all ▣ APPROVED** (review-360 scores 82–85, change-approver APPROVED each). E (store-native levers) covered; G frontier items designed as §17/§18 (M3). [verified]
- **M0 status — REAL PASS as of 2026-07-01 (supersedes the 2026-06-26 "not passed" fact).** History matters: the v1 "+0.487 B7 GO" was a constant baked into a synthetic domain — never cite THAT as learning evidence. But TA then cleared Phase A for real: **C0-hardened live B7 GO on real Claude** (920 calls, 0 errors, n_held=15 × 10 ticks): held-out 0.495 vs no-learning baseline 0.025, **margin +0.47**, powered/paired-gated, artifact `b7-a33f906-n15x10-r1.json`, TA SHA a33f906. DecisionEngine (Thompson-sampled LP + coverage floor) wired in the live loop — round-robin removed. Scope caveats: single skill (made-up cipher, knowledge-bottleneck not execution-heavy), single run; representative coding+pytest corpus still ahead. [verified 2026-07-02 read-only audit]
- **M1 live validation COMPLETE as of 2026-07-02** (TA commit c210565): growth/provision_suite ✓, B4 spacing (SRS curve, 9–11 live fires after T-053 fix) ✓, A5 warm-start (formulas exact, head-start confirmed) ✓, §15 spacing-due + downstream-failure ✓, B2 prereq-gap fired live (nova-chain → weak root nova-cipher, tick 4) ✓. Pre-live C0-M1 adversarial review caught 2 DOA blockers, fixed first (T-052 §16 EIG-unit gate, T-053 §15 same-tick elapsed=0; also T-054 B2 depth cap). **Still hermetic-only / not live:** §16 retrieval (no multi-store corpus yet), B1 wiring into live loop, merge/prune live, A5 `div` scaling, B4 self-check as decision-maker. Small n on M1 runs (n_held=5/skill — wiring confirmation, not powered margins). [verified 2026-07-02 read-only audit]
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
- ~~Library housing contradiction~~ **RESOLVED by the user (2026-07-02):** `/Users/samyoga/dev/turing-agents` is the user's **own research implementation** — they build there themselves; nothing in that repo is ever modified from here. HANDOVER-v2 §3's resolution of [D-2] toward turing-agents stands (the v2 artifact is cut there, by the user). This repo's job is the research/specs; any information the implementation needs is **passed manually by the user** — never written across by an agent.
- [D-1] confirmation: CHANGELOG split + VERSION handling when Python lands here.
- **M2 compute path (NEXT-STEPS D3, recorded 2026-07-02):** hosted fine-tune API vs rented burst GPU vs skip weight axis. Deferred until trigger: memory-axis held-out gains plateau while verifier is strong. No GPU needed through v2 (M0/M1 = API calls only); no path requires a full-time GPU. Claude-as-student ⇒ no general fine-tuning ⇒ open-weights student or skip. *TA-side corroboration (read-only audit 2026-07-03): the reference build dropped M2 per its own B-040 frontier decision — consistent with defer/skip.*
- **Reference-build state (read-only audit 2026-07-03):** turing-agents v1 program COMPLETE (all 4 gates GO, 2026-07-03; 19 features, 551 root tests green); MDLP M1 live-validation fully closed there (B2 prereq diagnosis + downstream-failure trigger confirmed on real `claude`, artifact `m1-live-d8126f0-n12-prereq.json`); §16 retrieval remains hermetic-only by design. [verified — audit report; this repo observes only, never writes there]
- §19 spec edit is approved-but-uncommitted alongside unrelated working-tree changes — when/how does the authorized commit land?
- ~~Who implements Phase A here?~~ **RESOLVED (2026-07-02):** the user implements Phase A themselves in turing-agents; this repo needs no Python build specialists for it.
