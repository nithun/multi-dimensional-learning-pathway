# Project profile

_Last profiled: 2026-07-28 by scout (deep pass; supersedes the 2026-07-02 deep pass + all inline deltas since). Living document — refine inline as understanding improves._

## What this project is
- **MDLP (Multi-Dimensional Learning Pathway)** — a research project producing a probabilistic, multi-dimensional learning-pathway **algorithm** (competence inference + curriculum decision + gated self-improvement), generalized from human students to **self-learning agents**. [verified]
- The repo is **documentation-substance**: spec of record, gate-approved build specs, data-layer design, paper draft, eval protocols, external-system studies, and the full review audit trail under `docs/research/`. **No Python code lives here.** The implementation lives in the user's separate `turing-agents` (TA) repo. [verified]
- **Scope rule (hard, L-012):** this repo manages ONLY MDLP research/specs. `/Users/samyoga/dev/turing-agents` is the user's own implementation — read-only from here, forever; anything it needs crosses **via the user, manually** (the HANDOVER docs are exactly that vehicle). [verified — L-012, user memory]
- The repo also carries the **Turing Agents v0.2.0** self-evolving scaffold (Markdown + Bash) the research runs on. [verified]

## Branch / working-tree situation (2026-07-28)
- HEAD = `research/external-repo-study-2026-07-13`, **13 commits ahead of local `main`, not merged**; local `main` is itself 7 commits ahead of `origin/main`. Nothing since 2026-07-02 is pushed. [verified — git]
- Committed on the branch: the 4 gate-approved 2026-07-13 spec changes (`ce53ccc`…`adfba2f`), ungated study deliverables (`bb70…/8c6cc56`), and the 2026-07-13 + 2026-07-28 evolve commits (L-013/L-014, spec-change-gate skill update, RR-2026-07-28). [verified]
- **Still uncommitted (untracked):** `docs/research/HANDOVER-v3.md`, `STUDY-automaton-autonomy.md`, `STUDY-small-models-for-mdlp.md`; modified `interactions.jsonl`. Commits await user authorization. [verified — git status]

## Core intellectual state (as of 2026-07-28)
- **Spec of record:** `ALGORITHM-v0.2-pathway-learner.md` §1–§19 **plus §17.6** (scaffold-version log, FIX/DERIVE/CAPTURE, approved 84/100). All additions additive; all gate-approved. [verified]
- **Build specs all ▣ APPROVED:** A1, A5, B1–B4 (2026-06 sprint, 82–85) **plus the 2026-07-13 external-study wave**: **R1** §16-companion retrieval build-spec (5-mode dispatch + fusion reranker, 87/100), **B2 Amendment A** (typed `part_of` edges, `τ_traverse`/`q_edge`, `queue_rank` confirmation queue, 85/100), **DATA-LAYER §6.1/§6.2 write discipline** (work-unit lifecycle with `intent_key` idempotency, occurrence-identity hashing, two-phase extract→merge projection writes, `RedactedTruthView` P1 boundary, 83/100 over 12 rounds). Decision records in `docs/research/reviews/`. [verified]
- Corrected objective (stable since 2026-06-22): `A* = argmax E[Δ competence | S, A]`; `P(success)` is measurement primitive only. Principles **P1** (measurement independent of optimization; held-out never in context) and **P2** (every `add` has an inverse). Gates statistical (`significant()`), never scalar. [verified]
- **M0 REAL PASS (2026-07-01)** — C0-hardened live B7 GO on real Claude: held-out 0.495 vs baseline 0.025, margin +0.47, powered/paired, artifact `b7-a33f906-n15x10-r1.json`. **M1 live validation complete (2026-07-02, TA c210565)**. History caveat: the earlier v1 "+0.487 GO" was baked — never cite it. [verified]
- **BUT — 2026-07-28 read-only TA audit (IX-040, TA HEAD `949ed74`) tempers the evidence base.** Four-way audit: math core correct, held-out integrity genuinely holds, 234 tests green. Three structural caveats: (1) **built-but-unwired** constructs (A1 `U(a)`, §14 calibrator not behind `estimate()`, drift/rollback/breaker not in the live loop, §4 shape+counterfactual verifier off the live path, all of §16 hermetic); (2) **6 genuine bugs** (A5 `agreement()` inverts RC-7 anti-bubble + anchor-set unenforced, `rebuild_all` no Redis flush, truth upsert-not-append double-counts, `decision.py` reachability sign inversion, B4 `S0` ignores mastery); (3) **all live evidence is on toy cipher skills — the representative coding corpus has never been built.** That's the credibility ceiling. [verified — IX-040, HANDOVER-v3 §1]

## Current milestone: M-R (HANDOVER-v3, supersedes HANDOVER-v2)
- `docs/research/HANDOVER-v3.md` (2026-07-28, uncommitted) is the current handover to TA: third-person status review, **gap map G1–G7** (G1 audit bugs · G2 adopt approved spec deltas, §6.1/6.2 load-bearing · G3 wire-or-retract · G4 **representative corpus — THE credibility item** · G5 autonomy loop · G6 embedding/model providers · G7 observability), and milestone **M-R = representative + resumable + unattended**: *a GO or honest NO-GO on a real coding corpus, produced by a run no human supervised*. Three acceptance clauses (M1-EVAL-PROTOCOL run on real pytest tasks; kill -9 resumability on the §6.1 work-unit layer; two-level loop + budget tiers + external watchdog). 4-phase autonomous build guide with per-task acceptance criteria. **The milestone is the run, not the sign — NO-GO is publishable.** [verified]
- Explicitly NOT in M-R: M2 weight axis (deferred per NEXT-STEPS D3), M3 runtime, C1 human verifier, PyPI. [verified]

## Research corpus (2026-07 studies, all ungated study docs)
- `STUDY-raganything-agentscope-openspace.md` (2026-07-13): **OpenSpace = closest living relative + natural paper baseline** (statistics-free degenerate of MDLP); RAG-Anything/LightRAG → §16/R1 patterns; AgentScope → library engineering. All 7 proposals executed through the gate 2026-07-13. [verified]
- `STUDY-automaton-autonomy.md` (2026-07-28): Conway automaton deep read — 10 adopt patterns (two-level loop, leased schedule table, wake queue, pure tier function, debounced terminal states, frozen enforcement manifest, claim TTLs, layered brakes) + 8 avoid patterns (prompt-as-enforcement, inert alarms, no-revert self-mod, silent budget spin). Recommends **ObservabilityPort (Langfuse) + AnalyticsStore (ClickHouse) as opt-in full-tier roles, never defaults** (zero-infra identity preserved). Queues **AUT-1..4** as future gated proposals. Independently vindicates MDLP's statistical-gate/JUDGE stance. [verified]
- `STUDY-small-models-for-mdlp.md` (2026-07-28, reconstructed from journal after synthesis misfire — L-014): placement map (6 dark embedding consumers behind one unprovided interface; reranker optional; student/teacher/judge roles). Picks: **all-MiniLM-L6-v2** default, **potion-base-32M** (Model2Vec, numpy-only) zero-infra tier, **Qwen3-Embedding-0.6B** upgrade; ms-marco-MiniLM/Ettin rerank; Phi-4-mini (MIT) judge; SmolLM3/Qwen3 as M2 open-weights student. M0/M1 student stays Claude. Extras only — nothing model-based in the stdlib core. [verified]
- `M1-EVAL-PROTOCOL.md` (2026-07-13): pre-registered cold→warm two-phase protocol, three arms, frozen criteria — exists but **has nothing to run on** until the corpus is built (G4). [verified]

## Governance / process conventions
- **Every gated spec change flows `review-360` → `change-approver`** (L-010; playbook in `skills/spec-change-gate/SKILL.md`, incl. the L-013 pre-submission authoring checklist: schema-first edits, end-to-end contradiction read, grep-verify every cross-reference). The gate demonstrably works — ~30 rounds across the 4 external-study changes, 5+ catches of the same authoring-defect class. The approver authorizes; the user lands commits. [verified]
- Milestones hard-gated, never parallelized past a gate: M0 ✓ → M1 (live-validated) → **M-R (current)** → M2 (deferred) → M3. [verified]
- Commit style: `docs(research): …`, `docs(site): …`, `evolve: <what> — <why>`; one logical change per commit. [verified — git log]
- Framework memory: lessons L-001…L-014 active; RC-1…RC-8 each keep a guarding regression test; large research runs: check the journal before re-running (L-014). [verified]

## Tech stack
- Here: Markdown + Bash (`scripts/`), GitHub Pages site (`docs/index.html`). [verified]
- Implementation (in TA, by the user): Python `mdlp` package, ports-and-adapters 5-store layer (embedded tier = SQLite + networkx + local vector, zero infra; full tier adds Postgres/Redis/Neo4j, and — proposed, opt-in — Langfuse/ClickHouse). [verified — audit; design docs]
- Build/test/run: none in this repo; TA runs pytest (234 green at audit). [verified]

## Layout
- `docs/research/` — the substance: `ALGORITHM-v0.2-pathway-learner.md` (spec of record) · `BUILD-SPECS.md` · `DATA-LAYER.md` · `HANDOVER-v3.md` (current; v2/v1 historical) · `M1-EVAL-PROTOCOL.md` · `STUDY-*.md` ×3 · `PAPER.md`/`PAPER-method-section.md` · `LANDSCAPE-…` · `IMPLEMENTATION-v2.md` · `reviews/` (gate audit trail).
- `docs/RELEASE-PLAN-v2.md` — release tiers + open decisions [D-1..D-3]; `docs/evolution/` — framework backlog, run reports, proposals.
- `.claude/agents/` — 8 framework agents + `review-360` + `change-approver`. `skills/spec-change-gate/` — the one skill. `tasks/BOARD.md` — kanban.

## Goals / what success looks like
- Near: **M-R** executed in TA (by the user / TA's own loop, guided by HANDOVER-v3) — representative corpus GO-or-honest-NO-GO, resumable, unattended. [verified — HANDOVER-v3 §3]
- This repo's job meanwhile: keep specs/gate/protocol ahead of the build, run the AUT-1..4 proposals through the gate when due, maintain the paper positioning (OpenSpace baseline). [inferred — from the standing division of labor]
- Longer arc: v2.0.0 `mdlp` release (GitHub-only first), paper with pre-registered eval; M2 weight axis only if the memory axis plateaus. [verified]

## Open questions for the user
- **When do the branch commits land?** `research/external-repo-study-2026-07-13` (13 commits) is unmerged to `main`; `main` is unpushed (7 commits ahead of origin). And HANDOVER-v3 + the 2 new studies are still uncommitted — awaiting authorization. [verified — git]
- **Has HANDOVER-v3 crossed to TA yet?** It supersedes v2 and defines M-R; the crossing is manual (L-012). Unknown from this repo.
- **AUT-1..4** (continuous-operation spec §20, ObservabilityPort/AnalyticsStore data-layer delta, §17.5/§17.6 hardening, claims-TTL audit) are queued ungated proposals — run them through the L-010 gate now, or wait for TA's Phase-3 pull?
- [D-1] versioning/CHANGELOG split — still open, only bites when Python lands somewhere versioned.
- **Daemon (B-002) genuinely stale:** zero successful unattended runs ever (chmod bug, then 401s); no retry since 2026-06-26 across 3 audits. Needs a real retry or an explicit decision to drop unattended mode.
- ~~§19 uncommitted~~ resolved — committed `6ccc1a9` 2026-07-02. ~~Library housing / who implements~~ resolved 2026-07-02 — the user, in TA, manually.
