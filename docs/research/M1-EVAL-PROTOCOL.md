# M1 evaluation protocol — cold→warm two-phase on a representative corpus

**Status:** protocol (pre-registration draft, 2026-07-13). Not an algorithm change — this instruments the existing M0/M1 gates (§2, §4, §8) on the representative corpus that the M0 GO explicitly left ahead. Design adapted from the strongest external precedent found in the 2026-07-13 study (OpenSpace's GDPVal two-phase cold→warm benchmark — `STUDY-raganything-agentscope-openspace.md` §3, P4), with MDLP's statistical gates replacing its LLM-judge scoring.

**Why this exists.** The M0 GO (2026-07-01, `b7-a33f906-n15x10-r1.json`) was a single made-up knowledge-bottleneck skill. Its scope caveats name the next evidence step: a representative coding+pytest corpus. This protocol pre-registers that run so the result — GO or NO-GO — is decided by frozen criteria, not post-hoc judgment.

## 1. Design (two phases, three arms)

- **Corpus.** A representative coding task set with programmatic verifiers (pytest suites per task), split per §4: public (learnable-from) vs held-out (never in context — P1). Held-out items get isomorphic variants (B3-style: same structure, fresh operands/identifiers) to defeat memorization.
- **Phase 1 — COLD.** The learner runs the full §6 loop from an empty skill library over the public split. Skills accumulate under the normal §8 gates. Held-out evaluated per tick (the standard cadence).
- **Phase 2 — WARM.** The **same held-out tasks** (isomorphic-variant instances), rerun with the Phase-1 accumulated library, learning **frozen** (no new commits) — measures what the accumulated memory axis is worth on its own.
- **Baseline arm.** The frozen no-learning agent (same backbone, no library, no learning loop) on the same held-out instances — the §2 comparison arm, as in M0.
- **Fixed backbone.** One model version pinned for all arms and both phases, so any delta isolates *learning*, not model capability (the external precedent's key control).

## 2. Gates (frozen before the run)

- **Primary (the M0-style gate, unchanged):** held-out pass-rate (Phase 1 end) beats the frozen baseline beyond `z·SE`, paired and powered (pre-register `n_held`, ticks, and z at M0 values unless a power analysis says otherwise).
- **Warm-transfer gate (new, secondary):** Phase-2 pass-rate beats baseline beyond `z·SE` — the accumulated library alone, without further learning, transfers to fresh isomorphic instances.
- **Cost metric (reported, not gated):** Phase-2 tokens / Phase-1 tokens per solved task. The external precedent reports ~46% — cost reduction is a headline reviewers respond to; we report it honestly without gating on it.
- **Stratified reporting:** pass-rate deltas per `skill × difficulty` cell (MDLP already has the cells — §3), so the result shows *where* gains concentrate, not one averaged number.

## 3. Controls (carried from M0, plus corpus-specific)

- Memorization/hard-code probes must fail as designed (M0 acceptance, unchanged).
- Held-out never enters context (P1); enforcement as in the C0-hardened M0 run.
- Isomorphic variants on every held-out instance (no answer-specific leakage across phases).
- Pre-registered: corpus hash, splits, `n_held`, ticks, z, backbone version — all frozen in the run artifact before tick 1. A NO-GO is a valid, publishable outcome (RELEASE-PLAN §M0 discipline, extended to M1).

## 4. What this is not

Not a new gate mechanism (uses §2/§8 as-is), not a spec change, not a leaderboard exercise. It is the pre-registration that makes the representative-corpus claim auditable. Execution happens in the reference implementation (turing-agents) by the user; this document crosses only via the user (L-012).
