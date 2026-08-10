# CONTINUE HERE — session continuity brief

**Written:** 2026-07-30, at the end of a long working session, immediately before a **Claude login change**. The next session starts with **zero conversational context** — nothing from prior chats carries over. Everything needed is in this repo; this file is the entry point.

*(Switching Claude accounts? Read `HANDOVER-NEW-LOGIN.md` first — it covers what breaks and what to re-establish; then come back here.)*

**Read in this order:** this file → `.claude/memory/project-profile.md` (living state) → `.claude/memory/lessons.md` (L-001…L-014, the standing rules) → `CLAUDE.md` (framework protocol) → whatever the task touches.

---

## 1. What this project is (30 seconds)

**MDLP** = a probabilistic, multi-dimensional **learning-pathway algorithm** for self-learning agents: per-skill dual-Beta competence, curriculum by expected learning progress (`A* = argmax E[Δcompetence]`), and **statistical held-out gates** on every commit. Two load-bearing principles: **P1** measurement independent of optimization (held-out never enters context), **P2** every `add` has an inverse.

**This repo is documentation-substance** — spec of record, gate-approved build specs, data-layer design, paper draft, external-system studies, and the full review audit trail. **No Python lives here.** The implementation is the user's separate `turing-agents` (TA) repo.

**The differentiator, verified three times from source:** no shipped self-improving agent measures whether its learning worked — not HKUDS OpenSpace (point-estimate counters + hardcoded thresholds), not Conway automaton (prompt-text "constitution" enforced by nothing), not NousResearch hermes (its own curator prompt tells the model to distrust its usage counters). MDLP's statistics are the unoccupied ground.

---

## 2. Hard rules that are not obvious (violating these is expensive)

1. **`/Users/samyoga/dev/turing-agents` is READ-ONLY from here. Forever.** (L-012.) Audit it, report on it, read it freely — **never write, edit, or run git there**. It is the user's own implementation with its own framework. Anything it needs crosses **via the user, manually**; the `HANDOVER-*.md` docs are exactly that vehicle. *(This rule previously also lived in the user-level Claude memory, which does not survive the login change — it is preserved here and as L-012.)*
2. **Every change to a gated artifact runs the two-stage gate before commit** (L-010): `review-360` (scores 0–100, nine dimensions) → `change-approver` (APPROVE/REJECT). Gated artifacts = `docs/research/ALGORITHM-v0.2-pathway-learner.md`, named items in `docs/research/BUILD-SPECS.md`, and (by established practice) `docs/research/DATA-LAYER.md` sections. Playbook: `skills/spec-change-gate/SKILL.md`. **Expect 3–8 rounds.** A round-1 score of 40–60 is normal, not failure — the gate has caught real defects every single time.
3. **The approver authorizes; it never commits.** The committing agent/user applies the edit and cites the decision-record path in the commit message.
4. **Authoring discipline (L-013, learned the hard way ~6 times):** write the schema/formula **first**, then prose citing it; do an **end-to-end contradiction read** of the whole section (grep can't catch two statements that disagree); **grep-verify every cross-reference exists** before resubmitting. The gate caught this exact defect class repeatedly.
5. **Check `journal.jsonl` before re-running a failed background workflow** (L-014) — results are often already on disk even when the agent's wrap-up died.
6. **Never cite the v1 "+0.487 GO"** — it was a constant baked into a synthetic domain. The real result is the 2026-07-01 M0 GO (below).

---

## 3. Where things stand (state of play, 2026-07-30)

### Research side: specification-complete for the current horizon
Everything is gate-approved and committed on `main`:
- **Spec of record:** `ALGORITHM-v0.2-pathway-learner.md` §1–§20 (§1–§19 + §17.6 lineage schema + **§20 Continuous operation**).
- **Build specs:** A1, A5, B1–B4, B3, **R1** (§16 companion), **B2 Amendment A** — all ▣ APPROVED.
- **Data layer:** `DATA-LAYER.md` incl. **§6.1/§6.2 write discipline** and **§11 Observability & analytics**.
- **Audit trail:** every review round + decision record in `docs/research/reviews/`.

### Implementation side (TA): real, honest, narrower than the spec
From a read-only four-way audit (2026-07-28, TA HEAD `949ed74`) — **do not re-derive this, it's recorded**:
- ✅ Math core verified correct; **held-out integrity genuinely holds** (the thing most likely to be faked in this class of system); 234 tests green; 5-store layer complete on both tiers.
- ⚠️ **Built-but-unwired:** A1's `U(a)` objective, the §14 calibrator (not behind `estimate()`), drift/rollback/breaker (live loop is commit-only), the §4 shape+counterfactual verifier (live path uses bare `exact_check`), all of §16 (hermetic).
- 🐞 **Six real bugs:** A5 `agreement()` **inverts** its RC-7 anti-bubble control + anchor-set unenforced; `rebuild_all` doesn't flush Redis; truth is upsert-not-append (empty-id retries double-count); `decision.py` reachability sign inversion (`u = q·rw` misorders when `q<0`); B4 `S0` ignores mastery.
- 🚨 **The credibility ceiling:** M0 GO (held-out 0.495 vs 0.025 baseline, **margin +0.47**, artifact `b7-a33f906-n15x10-r1.json`) and *all* M1 validation are on **toy cipher skills**. The representative coding+pytest corpus that the M0 GO itself flagged as "still ahead" **has never been built**.

### Current milestone: **M-R** (`docs/research/HANDOVER-v3.md`)
> *A GO or honest NO-GO on a real coding corpus, produced by a run no human supervised.*

Three acceptance clauses: **representative** (M1-EVAL-PROTOCOL cold→warm on real pytest tasks) · **resumable** (kill -9 anywhere, restart, exact evidence counts) · **unattended** (two-level loop, budget tiers, external watchdog). **The milestone is the run, not the sign — a NO-GO is a publishable, milestone-satisfying outcome.**

---

## 4. What to do next

**The critical path is on the user's side (TA), and nothing in this repo blocks it.** HANDOVER-v3 §4 is a 4-phase build guide with per-task acceptance tests:
- **Phase 0** — fix the six audit bugs (½ day; the A5 pair is where a green test suite is currently hiding a defeated safety control). Add the hermes SQLite `_transaction()` sweep here (`with sqlite3.connect()` commits but never closes; in WAL mode each leak pins 3 fds → `Errno 24`).
- **Phase 1** — adopt the approved write discipline (DL §6.1/6.2), then B2 Amendment A and R1.
- **Phase 2** — **build the representative corpus** (the single biggest credibility item in the program).
- **Phase 3** — the autonomy loop. **Now spec-backed:** read §20 + DL §11 *alongside* HANDOVER-v3 §4, which predates their approval and still cites the study docs for those patterns.
- **Phase 4** — the M-R run itself.

**On this (research) side, the sensible next moves:**
- **AUT-3** — a small §17.5/§17.6 hardening delta (freeze-the-enforcement-manifest naming JUDGE source/gate statistics/eval harness/truth writer; modification-frequency rate limit; dry-run validator). Queued in `STUDY-automaton-autonomy.md` §6.
- **AUT-4** — a claims audit: verify every claimable state in the 5-store design carries a TTL or liveness probe (§20.6's invariant binds all future additions).
- **M2 data engine** — when its trigger fires, `STUDY-hermes-agent.md` §4 is a ready-made reference design (trajectory generation → success-flag rejection sampling → student-tokenizer-budgeted compression); MDLP's statistical gates slot in exactly where hermes has only a boolean `completed`.
- **Advisories** carried by the approved decision records (each names its own) — worth a sweep before the next spec wave.

---

## 5. Things only the user (Nithun) can do

1. **Re-save the scope rule as a user-level memory** in the new login, if that memory system is used again. Substance (also L-012): *manage only this MDLP repo; `turing-agents` is never written to from here; information crosses manually.*
2. **Carry HANDOVER-v3 + the decision records to TA** — this repo cannot.
3. **The curator daemon is dropped** (backlog B-002, closed 2026-07-30): the script runs fine, but headless `claude` fails `401 OAuth access token has been revoked`, and launchd is additionally blocked by macOS TCC on `~/Documents`. Both fixes are user-only (re-auth + Full Disk Access). **All evolution is in-session** — which is the mode every successful cycle has actually used. **This will need re-checking under the new login.**
4. **Push decisions** — `git push` is outward-facing and always the user's call.

---

## 6. Session history index (what happened, where it's recorded)

| When | What | Where |
|---|---|---|
| 2026-06/07 | Spec sprint: §13–§19, A1/A5/B1–B4 build specs, M0 GO, M1 live validation | `ALGORITHM-v0.2`, `BUILD-SPECS`, `reviews/` |
| 2026-07-13 | External-repo study (RAG-Anything, AgentScope, **OpenSpace**) → 7 proposals → 4 gate-approved spec changes (R1, §17.6, B2-AmendA, DL §6.1/6.2) over ~30 review rounds | `STUDY-raganything-agentscope-openspace.md`, `reviews/` |
| 2026-07-28 | Read-only TA audit (4 agents) · automaton autonomy study · small-models research · **HANDOVER-v3** | `STUDY-automaton-autonomy.md`, `STUDY-small-models-for-mdlp.md`, `HANDOVER-v3.md`, IX-040…043 |
| 2026-07-28 | hermes-agent deep study (2 agents) | `STUDY-hermes-agent.md`, IX-044 |
| 2026-07-30 | **AUT-1 (§20) + AUT-2 (DL §11)** drafted → 13 combined gate rounds → both APPROVED; backlog B-002/B-004 closed | `reviews/S20-*`, `reviews/DL-observability-*`, IX-045 |

Full interaction log: `.claude/memory/interactions.jsonl` (IX-001…IX-045). Framework self-edits: `.claude/memory/evolution-log.jsonl` (EV-001…EV-092). Retrospectives: `docs/evolution/RR-*.md`.

---

## 7. Open questions (live)

- **[D-1]** CHANGELOG split + `VERSION` handling when Python lands (VERSION 0.2.0 is the *framework*, colliding with algorithm versioning) — becomes real when TA cuts v2.
- **M2 compute path** (NEXT-STEPS D3): hosted fine-tune API vs rented burst GPU vs skip the weight axis. Deferred until the memory axis plateaus with a strong verifier. Claude-as-student ⇒ no general fine-tuning ⇒ open-weights student (SmolLM3/Qwen3 per the small-models study) or skip.
- Whether to gate **AUT-3/AUT-4** now or when TA reaches them.
- The merged `research/external-repo-study-2026-07-13` branch still exists and is safe to delete.

---

*If anything here conflicts with what you observe in the repo, the repo wins — and update this file plus `project-profile.md` in the same turn. Never let this document drift into fiction.*
