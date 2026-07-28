# Glossary

Project vocabulary, acronyms, codenames — each with a one-line decode. Seeded by `scout` 2026-07-02; maintained inline + by `retrospective`.

| Term | Means | Source |
|---|---|---|
| MDLP | Multi-Dimensional Learning Pathway — the algorithm/research project (and the planned `mdlp` Python package) | verified — repo name, RELEASE-PLAN-v2 |
| Turing Agents | The self-evolving Markdown+Bash agent scaffold this repo runs on (v0.2.0); separate version line from the MDLP algorithm | verified — CLAUDE.md, README |
| v0.2 spec | `ALGORITHM-v0.2-pathway-learner.md` — the spec of record, §1–§19, all additions additive | verified |
| `significant()` | The one gate primitive: every commit/rollback/promote/admit tests a delta against its own SE/CI — gates are statistical, never scalar (fixes RC-1) | verified — spec §2 |
| dual posterior | The state model keeps two Beta posteriors per skill cell: mastery (slow decay, `γ_slow`, drives promotion) and drift (fast decay, `γ_fast`, drives rollback only) (fixes RC-5) | verified — spec §3 |
| ĉ / competence point | `αm/(αm+βm)` — point estimate of competence for a skill×difficulty cell, with posterior SE | verified — spec §3 |
| held-out split / secret set | Eval items never shown to the learner; reward is computed ONLY on held-out (principle P1); the generalization gate requires `Δĉ_secret ≥ ρ_gen · Δĉ_public` | verified — spec §4 |
| P1 / P2 | The two design principles: P1 measurement independent of optimization; P2 every `add` has an inverse | verified — spec/HANDOVER |
| RC-1…RC-8 | The 8 root causes from the v0.1 red-team (`ALGORITHM-v0.1-redteam.md`); each must keep a guarding regression test | verified |
| Tutor layer | §13 — generic curriculum strategist with pluggable Teachers; picks actions by expected learning gain | verified — spec §13 |
| A1 | BUILD-SPEC: information-gain selection — Tutor objective `U(a)=(1−w)z(E[Δc])+w·z(EIG)`, closed-form Beta EIG (approved 85/100) | verified — BUILD-SPECS |
| A5 | BUILD-SPEC: warm-start priors from "learners like you" via kNN over the vector store, MMR diversity, influence decays with own evidence (approved 82) | verified — BUILD-SPECS |
| B1 | BUILD-SPEC: misconception clustering → graph-linked remediation, admitted only on significant held-out lift (approved 82) | verified — BUILD-SPECS |
| B2 | BUILD-SPEC: prerequisite-gap diagnosis via backward graph walk, confirm before redirect (approved 83) | verified — BUILD-SPECS |
| B3 | BUILD-SPEC: cross-agent fleet transfer — zero-trust, quarantined behind the §8 commit gate (approved 82) | verified — BUILD-SPECS |
| B4 | BUILD-SPEC: forgetting-aware spacing — `R(t)=exp(−t/S)`, review-budget cap (approved 82) | verified — BUILD-SPECS |
| C1 | The human verifier line (human-learning instantiation). **Tag-only in v2**; the Frappe/ERPNext instantiation is deferred; its docs stay as research reference | verified — RELEASE-PLAN §4, HANDOVER-v2 §6 |
| SOLVE/JUDGE | §17 partition: `self_modify` may edit only SOLVE (the solve-scaffold); JUDGE (verifier, held-out + generator, gates, posterior, orchestrator) has no agent write-path, ever | verified — spec §17.1 |
| §19 / self-calibrating gate | Gate thresholds tuned by measured learning, clamped so the effective gate is never looser than §8; approved 85/100 on 2026-06-29, spec edit currently uncommitted | verified — S19 decision record |
| review-360 gate | The two-stage governance flow for every spec change: `review-360` (multi-viewpoint 0–100 review, critical-floor aggregation) → `change-approver` (APPROVE/REJECT: overall >80, correctness/red-team/safety ≥70, zero blockers, check-on-the-checker) | verified — .claude/agents/, reviews/ |
| M0 / M1 / M2 / M3 | The gated milestones: M0 prove real learning on held-out · M1 open schema + capability suite (after C0 re-red-team) · M2 weight axis (GPU) · M3 self-mod + fleet (§17/§18/§19) | verified — IMPLEMENTATION-v2 §1 |
| B7 | The M0 go/no-go acceptance test id (held-out beats frozen no-learning baseline beyond `z·SE`, probes fail as designed); the v1 "B7 GO" was baked, not real | verified — HANDOVER-v2 §1 |
| Phase A / B / C | The v2 build arc: A make M0 real (the whole game) · B implement the approved capability suite after C0 · C package & release | verified — HANDOVER-v2 §5 |
| Tier ① ② ③ | v2 maturity labels: ① working/validated core · ② experimental (spec-complete, unvalidated end-to-end) · ③ tag/design-only roadmap | verified — RELEASE-PLAN §4 |
| C0 | Mandatory re-red-team of the implementation before opening growth / starting Phase B (M1 precondition) | verified — HANDOVER-v2 §5 |
| 5-store | The data layer: SQL (truth) · document (inferred state) · vector · graph · cache; v2 default is the embedded tier (SQLite + networkx + local vector, zero infra) | verified — DATA-LAYER refs |
| EIG | Expected information gain — the exploration term in A1's blended objective | verified — BUILD-SPECS A1 |
| provision_suite | The eval-item generator for newly grown skills (growth-provisioning invariant, RC-3); part of JUDGE, never agent-writable | verified — spec §5.1/§17.1 |
| PAL | Personalized adaptive learning — the human-facing product layer; explicitly NOT in v2 scope | verified — RELEASE-PLAN §1 |
| memory axis / weight axis | The two improvement axes: memory/context-level (skills, lessons — free) vs weight-level (SFT/RL fine-tuning — M2, GPU) ; §17 adds a third: the scaffold (code) axis | verified — spec §17 note |
| [D-1] [D-2] [D-3] | Open owner decisions in RELEASE-PLAN-v2: versioning split · library housing · release cut line | verified — RELEASE-PLAN |
| M-R | The current milestone (HANDOVER-v3, 2026-07-28): **representative + resumable + unattended** — a GO or honest NO-GO on a real coding corpus, from a run no human supervised; supersedes HANDOVER-v2's phase framing | verified — HANDOVER-v3 §3 |
| G1–G7 | HANDOVER-v3's gap map from current state to autonomous MDLP: audit bugs · adopt approved spec deltas · wire-or-retract unwired constructs · **representative corpus (the credibility item)** · autonomy loop · model providers · observability | verified — HANDOVER-v3 §2 |
| R1 | The §16-companion retrieval BUILD-SPEC: 5-mode retrieval dispatch + learned fusion reranker (linear over 5 features); approved 87/100, 2026-07-13 | verified — BUILD-SPECS, reviews/ |
| §17.6 / scaffold-version log | Lineage schema for scaffold self-modification: FIX/DERIVE/CAPTURE operators, ancestry-checked CAPTURE; approved 84/100; M3-horizon (schema may land, no runtime until M3) | verified — spec §17.6, reviews/ |
| B2 Amendment A | Typed `part_of` graph edges, soft `τ_traverse` floor with `q_edge` inverse, and the `queue_rank` confirmation queue for prereq-gap redirects; approved 85/100 | verified — BUILD-SPECS, reviews/ |
| work unit / `intent_key` | DATA-LAYER §6.1 write discipline: every eval run is a leased work unit minted from a dispatch row; `open_work_unit` is idempotent on a UNIQUE `intent_key` (= dispatch event id) — kill -9 resume with no double-count and no lost evidence | verified — DATA-LAYER §6.1 |
| RedactedTruthView | §6.2 P1 boundary: the SOLVE bundle wraps the truth store in a view with held-out `item_ids`/content stripped and write-methods raising — measurement stays unreachable from optimization | verified — DATA-LAYER §6.2 |
| queue_rank | B2 Amendment A's ranked confirmation queue for candidate prerequisite gaps (confirm before redirect, ordered) | verified — BUILD-SPECS B2-A |
| AUT-1..4 | Queued gated proposals from the automaton study: §20 continuous-operation spec · ObservabilityPort/AnalyticsStore data-layer delta · §17.5/§17.6 enforcement-manifest hardening · claims-TTL audit | verified — STUDY-automaton-autonomy §6 |
| two-level loop | The autonomy skeleton (automaton adopt-#1): infinite outer supervisor (every exit = timed sleep) wrapping the existing bounded n-tick learning run as the inner cycle | verified — STUDY-automaton-autonomy, HANDOVER-v3 Phase 3 |
| potion / Model2Vec | Static-embedding family (potion-base-32M, MIT, numpy-only — no torch, no inference): MDLP's zero-infra `embed-lite` pick at ~93% of MiniLM quality; default `embed` = all-MiniLM-L6-v2; upgrade = Qwen3-Embedding-0.6B | verified — STUDY-small-models §2 |
| OpenSpace | HKUDS OpenSpace — closest shipped relative (self-evolving skill layer, experience counters, LLM-gated evolution); a point-estimate, statistics-free degenerate of MDLP and the natural paper baseline | verified — STUDY-raganything-agentscope-openspace |
| ObservabilityPort / AnalyticsStore | Proposed opt-in roles for unattended runs: embedded defaults = truth events/JSONL + SQLite views (zero-infra); full tier = Langfuse (traces) + ClickHouse (rebuildable analytics projection). Never default | verified — STUDY-automaton-autonomy §5 (proposal, ungated) |
