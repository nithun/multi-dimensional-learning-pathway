# MDLP v2 — release plan

**Goal:** cut the first public release that ships the *research itself* — the v0.2 algorithm spec + the gate-approved BUILD-SPECS (A1, A5, B1–B4), as an **installable `mdlp` Python library**, with the paper and site. v1 of this repo was the agent scaffold only; **v2 is the algorithm.**

**Status:** PLAN (not started). Owner decisions flagged inline as **[D-n]**. Scope rule honored: the library is authored **in this repo**; the turing-agents copy is never touched.

---

## 1. Release thesis (what v2 *is* and is not)

| | |
|---|---|
| **Is** | The MDLP algorithm, specified and **reference-implemented for the agent side (Milestone-0)**, packaged `pip install mdlp`-able, with the 5-store data layer (embedded tier), the paper, and a refreshed site. |
| **Is not** | A finished human-ed product, the TAP LMS PAL layer, the weight axis (M2, needs GPU), or a validated human verifier (C1 needs a cohort). Those ship as **design + roadmap**, clearly labelled. |

The honest one-liner: **v2 makes the approved specs real and runnable on one verifiable domain, and ships everything else as documented design.** This matches the project's own discipline (MVP, prove-on-one-real-task, evidence over momentum).

---

## 2. Current-state audit (what we're releasing from)

**Exists and release-ready (docs):**
- `ALGORITHM-v0.2-pathway-learner.md` — the spec (§1–§15, incl. Tutor §13, Calibration §14, Re-visiting §15).
- `BUILD-SPECS.md` — **A1, A5, B1, B2, B3, B4 all ▣ gate-approved** (implementable, with tests) + `reviews/` audit trail.
- `PAPER.md` (+ method section), `DATA-LAYER.md`, `IMPLEMENTATION.md`, `HANDOVER.md` — the build is fully specified (package layout, ports/adapters, M0→M2 gates, acceptance criteria).
- `HUMAN-LEARNING-VERIFIER.md` + `M0-PROTOCOL.md` + `M0-FRAPPE.md` — C1, design-complete.
- GitHub Pages site (`docs/index.html` + assets) — published.

**Gaps that block a "library" release:**
1. **No Python in this repo** (`find . -name '*.py'` = 0). The reference code was built in turing-agents (out of scope). → **v2's main build is authoring `mdlp/` here.**
2. **Versioning collision.** `VERSION`=`0.2.0` and `CHANGELOG.md` track the *Turing Agents framework*, not the MDLP algorithm. **[D-1]**
3. **Stale README** — still says "early-stage / bootstrapping … holds the agent scaffold"; never mentions the algorithm, paper, library, or site. Must be rewritten for v2.
4. **`IMPLEMENTATION.md`/`HANDOVER.md` target turing-agents/`app/`** — must be repointed to the standalone `mdlp/` package (DATA-LAYER §10 already anticipates this "standalone-library option").

---

## 3. The central decision — library housing **[D-2]**

**Recommendation: author `mdlp/` as a standalone package in *this* repo**, exactly the layout in `IMPLEMENTATION.md §1` / `DATA-LAYER.md §10`, decoupled from any host app.

- Pure-stdlib-friendly core; heavy deps (vectors, torch) are optional extras, never forced (DATA-LAYER §7).
- Default config = all-embedded (SQLite + networkx + a local vector index) → `pip install mdlp` runs with **no external infra** (DATA-LAYER §4).
- The turing-agents build is treated as a **prior art reference only** — not imported, not edited.

*Rejected alternative:* release as "spec only, code lives in turing-agents." Fails the "installable" goal and crosses the scope boundary.

---

## 4. Release scope — three maturity tiers (the cut line)

Everything ships in v2, but **labelled by maturity** so the release is honest:

| Tier | Contents | What "shipped" means |
|---|---|---|
| **① Working (the installable core)** | `state.py` (dual-Beta + `significant()`), `eval/` gates (§4/§8), `decision.py` Tutor with **A1 info-gain** (§13.1), `§14` calibration, embedded 5-store, the **M0 verifier loop** (code-task domain) | runs, tested, **validated on the M0 go/no-go** (held-out competence beats no-learning) |
| **② Experimental (spec-complete modules)** | **A5** warm-start, **B1** misconception clustering, **B2** prereq-gap, **B4** spacing, **B3** fleet transfer | code present, unit-tested against the approved specs' test lists, **marked `experimental`**; not yet validated end-to-end (needs M1 graph/vector evidence gate) |
| **③ Design-only (roadmap)** | **C1** human verifier + Frappe M0 (needs a cohort), **M2** weight axis (needs GPU) | shipped as docs + clearly-marked "not implemented; here's the protocol" |

**[D-3] MVP cut recommendation:** v2.0.0 = **Tier ① validated + Tier ② present-but-experimental + Tier ③ documented.** Do *not* block the release on Tier ② validation — that's M1, gated separately. This keeps v2 shippable on a near horizon while being truthful about maturity.

---

## 5. Versioning & naming **[D-1]**

**Recommendation:**
- Tag the release **`v2.0.0`** — the project's second era (v1 = scaffold; v2 = algorithm + library).
- Set the **`mdlp` package version = `2.0.0`** (single source of truth via `pyproject.toml`; `VERSION` mirrors it).
- **Split the CHANGELOG** into two tracked components so the collision is resolved openly: *MDLP algorithm/library* (new, starts at 2.0.0 with the full algorithm history v0.1→v0.2→specs) and *Turing Agents framework* (the vendored scaffold, continues its own 0.x line). One file, two sections.
- Decision to confirm: is the public artifact named **`mdlp`** on PyPI, or kept GitHub-only (tag + installable from source) for v2.0? *Recommend GitHub-only first; PyPI in v2.1 once the core is battle-tested.*

---

## 6. Build milestones to reach the v2 tag

Ordered; each is a normal task, **except M0 which is a hard gate** (the real go/no-go).

- **B0 — scaffold `mdlp/`.** Package, `pyproject.toml`, `requirements.txt`, `adapters/logs.py`, `mdlp` CLI stub. *Done when:* `mdlp --version` runs; a test parses `interactions.jsonl`. (HANDOVER §4.)
- **C-core — the working core (Tier ①).** `state.py`, `eval/`, `decision.py`+A1, `§14` calibration, embedded `stores/`. Unit tests per spec §3/§4/§13.1.
- **M0 — the verifier loop + the gate.** Code-task corpus (prompt + public + held-out tests); run the loop; **acceptance = held-out pass-rate rises beyond `z·SE` over a frozen no-learning baseline, and the memorization/hard-coding probes fail as designed** (HANDOVER §7, PAPER §5.7). *If M0 fails: that's a publishable NO-GO — we still release v2 as "spec + library + the negative result," we do not paper over it.*
- **Exp — Tier ② modules.** Implement A5/B1/B2/B4/B3 against their approved test lists; mark `experimental`; no end-to-end gate (that's M1).
- **Red-team regression tests.** Encode the 8 root causes (RC-1…RC-8) as regression tests (HANDOVER §6) — these are the safety net that the gate machinery actually works.
- **Docs/site refresh.** Rewrite `README.md` for v2 (algorithm + install + paper + site); add `docs/mdlp/results/M0.md` (the evidence); update the Pages site with the library + quickstart; repoint `IMPLEMENTATION.md`/`HANDOVER.md` to the standalone package.
- **Release.** CHANGELOG, tag `v2.0.0`, build artifact, (optional) PyPI.

---

## 7. The one gate that matters

```
B0 → C-core → ┌─ M0 acceptance test ─┐
              │  held-out > no-learn  │  GO  → ship Tier ① as "validated"
              │  + probes fail right  │
              └───────────────────────┘  NO-GO → ship as "library + honest negative result"
Tier ② (experimental) and Tier ③ (design) ship either way, labelled by maturity.
```

M1/M2 (validating Tier ②, building the weight axis) are **explicitly post-v2** — they have their own gates (C0 re-red-team before M1; GPU/budget for M2) and don't block this release.

## 8. Definition of done (release checklist)

- [ ] `pip install` (from source/tag) works; `mdlp --version` prints `2.0.0`; default embedded run needs no external infra.
- [ ] Core unit tests + red-team regression tests green in CI.
- [ ] `docs/mdlp/results/M0.md` records the go/no-go outcome (GO or honest NO-GO).
- [ ] Tier ② modules importable, unit-tested, marked `experimental`.
- [ ] `README.md` rewritten for v2; site updated; paper linked; `IMPLEMENTATION.md`/`HANDOVER.md` repointed to standalone.
- [ ] CHANGELOG split + `[2.0.0]` section; `VERSION`/`pyproject` = 2.0.0; tag `v2.0.0`.
- [ ] turing-agents untouched (scope check).

## 9. Risks & explicit non-goals

- **Risk: M0 doesn't pass** → mitigated by treating a NO-GO as a *valid, publishable* release outcome (it bounds where the approach applies). The release does not depend on a positive result.
- **Risk: scope creep into Tier ② validation** → mitigated by the hard cut line in §4 (experimental = shipped unvalidated, by design).
- **Risk: re-implementing turing-agents work** → the prior build is reference-only; we author fresh in-repo. Some divergence is acceptable and in-scope.
- **Non-goals for v2:** C1 live run (needs cohort), M2 weight axis (needs GPU), TAP LMS PAL integration, PyPI publish (deferred to v2.1).

## 10. Sequenced task board (proposed)

1. **[D-1/D-2/D-3]** confirm versioning, housing, cut line.
2. B0 scaffold `mdlp/`.
3. C-core (state · eval · decision+A1 · calibration · embedded stores) + tests.
4. M0 corpus + loop + **gate**.
5. Red-team regression tests.
6. Tier ② experimental modules.
7. README rewrite + site refresh + results doc + repoint impl docs.
8. CHANGELOG + VERSION + tag `v2.0.0`.

*Cross-refs:* spec `ALGORITHM-v0.2-pathway-learner.md` · approved specs `BUILD-SPECS.md` · package layout `IMPLEMENTATION.md §1` · stores `DATA-LAYER.md` · gates/acceptance `HANDOVER.md §5–§7` + `PAPER.md §5.7` · roadmap `NEXT-STEPS.md`.
