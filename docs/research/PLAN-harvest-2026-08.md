# Harvest plan — mapping the 2026-08 research arc onto MDLP's gaps

**Date:** 2026-08-13 · **Status:** planning document, ungated. Inverts the session's five studies/notes: organized by **MDLP's gaps**, not by source. Collapses the **24 queued proposals** (RAF-1..10 · ONT-1′,3..7 · LIV-1..3 · JMP-1..3 · VIS-1..4 · P-001) into **six work packages**, sequenced.
**Boundary (L-012):** gaps G1–G7 live in HANDOVER-v3 and are TA's to execute, crossed via the owner. This repo's leverage on them is **spec-side**: make the specs that prevent, detect, or define them. That's what this plan schedules.

---

## 1. The gap inventory — standing + discovered

**Standing (HANDOVER-v3, TA-side execution):**
G1 six audit bugs · G2 adopt approved deltas (§6.1/6.2 load-bearing) · G3 built-but-unwired (wire-or-retract) · **G4 representative corpus — THE credibility item** · G5 autonomy loop · G6 model providers · G7 observability.

**Discovered this arc (spec-side, this repo's to fix):**

| id | Gap | Found by |
|---|---|---|
| **S1** | No named safety-property set — TA modifies the algorithm with no list of what modifications must preserve; built-but-unwired (G3) is *undetectable by construction*, only discoverable by deep-read | Raft study F-B/F-C; every production Raft deviation was arguable-safe **only because properties were named** |
| **S2** | Structural constraints are reactive and incomplete — one enforced (acyclicity), arrived as a late-round caught gap; dozens live in prose/tests; no derivation discipline | Ontology study §2–§3; third sighting of the L-013 pattern |
| **S3** | The spec ratchets — `review-360` has no compression term, additive-only by convention, additive ≠ decomposed (layers cite 6–9 sections); the comprehension load is the plausible root cause of the audit's defect pattern | Method check C1–C4, F-F/F-G/F-H |
| **S4** | No learning liveness — every alarm detects harm, essentially none detect absence; done vs stuck vs converged-with-absorbed-anomalies share one code path; `n_min` masks starvation | Liveness note; JMP-1 (the Vulcan move) |
| **S5** | Granularity is unprincipled and unobserved — `τ_new` has hysteresis, not a principle; both failure directions invisible to the competence gate | Ontology study §4 |
| **S6** | Growth is bounded by the learner's own history — failure-driven only; no manufactured evidence, no top-down/backward design, no hypothetical states | Zahavy study H3; prospection note |
| **S7** | Stale-evidence handling is five mechanisms with five vocabularies; §17.6's fallback residual admitted open | RAF-3; KIP-101 receipt |
| **S8** | Skills are unportable (no stable identity, no external mapping); the prereq graph's causal story is unnamed and unbenchmarked | ONT-5/ONT-6 |
| **S9** | Paper positioning gaps — no scope statement on abduction, no Peirce naming, the axiom-layer contribution unstated, IX-040 unused as the hook | JMP-3; layer cake §1(b); ungated note §6 |

**The meta-observation that makes this plan coherent:** S1+S2+S7 are one problem (no invariant layer), S3 is its cause continuing to operate, S5+S6 are one problem (growth quality), and G4+S9 share one experiment. Hence six packages, not 24 items.

---

## 2. The work packages

### WP-A — Author better *(fixes S3 · cheapest · FIRST — changes everything downstream)*
**Composes:** RAF-7 (explain-it-back · cut step · weak-spot→rule) + RAF-2 (four duplications: promotion ×2, termination ×2, calibration ×2, decay ×4) + the compression middle path (spec-of-record ~12 sections, current text becomes appendix-of-record — nothing deleted, the *reading path* compressed).
**Why first:** every later package produces spec text; this package determines its quality. RAF-7 is a **framework-side** change (`skills/spec-change-gate/SKILL.md` + the review agents), so it lands as `evolve:` commits under the open agents/skills lanes — *except* anything inside an INVARIANTS fence, which becomes a task for the owner (L-005). RAF-2 and the compression path are gated spec work and carry the owner's decision points 1–2 from the synthesis.
**Done when:** the gate runs all three devices on its next real submission; the four duplications are consolidated or explicitly kept with reasons.

### WP-B — The invariant layer *(fixes S1+S2+S7 · prevents G1/G3-class · the structural centerpiece)*
**Composes:** RAF-1a (the ~8-property figure: property × mechanism × guard × section) + RAF-1b (**a checker that replays TruthStore** and reports violations — truth is already a complete canonical trace, so this is near-free) + ONT-1′ (generalize the approved acyclicity check into a declared constraint table at `merge()`, three severities, fire-test per shape) + ONT-3 (OntoClean meta-property tagging → constraints *derived*, not discovered) + LIV-3 (per-stage validation discipline, B2's insertion-time check as the pattern) + RAF-3 (epoch stamps; cross-generation reads revalidate or reject; retires `κ_reval`; the synthetic in-generation eval from KIP-595).
**One architecture, five layers:** declare invariants (RAF-1a) → derive them systematically (ONT-3) → enforce deterministically at write time (ONT-1′) → maintain inductively per stage (LIV-3) → check the rest by trace replay (RAF-1b), with epochs (RAF-3) as one of the properties.
**Payoff on standing gaps:** *the audit's defect class becomes detectable at runtime* — a property whose mechanism is not on the live path is an unproved property, and the checker says so. G1's six bugs are TA's to fix, but four of six would have been checker-visible. Ships to TA as a HANDOVER addendum when gated (via the owner).
**Done when:** the property figure is a gated ALGORITHM §21; the checker spec is in DATA-LAYER; the constraint table replaces the single hard-coded check.

### WP-C — The corpus experiment *(fixes G4 — the credibility item · plus S9's best evidence · one experiment, three outputs)*
**Composes:** ONT-4 (competency questions **first** — the checkable definition of "representative") + spec-as-corpus (spec sections + the ~120 stubs as real code+pytest tasks, available today) + RAF-4 (the pre-registered independent-reimplementation protocol, Howard-et-al. methodology).
**The design:** write CQs → pre-register (sibling of `M1-EVAL-PROTOCOL.md`) → N independent agent implementers × section × stubs, held-out stubs never in context → measure conforming / unwired / divergent per section.
**Three outputs from one run:** (1) a bridge corpus with real verifiers that upgrades the toy-cipher evidence base *now* (explicitly *not* a substitute for the full G4 corpus — a bridge); (2) the implementability study — Ousterhout's user study run at agent scale, a paper contribution; (3) the empirical decomposition audit (RAF-8's data falls out as the per-section difficulty map).
**Honest limits carried from the ungated note:** one narrow domain; corpus-author ground truth (P1 holds mechanically; the circularity is named in the protocol).

### WP-D — Learning liveness *(fixes S4 · small · anytime)*
**Composes:** LIV-1 (three signals — evidence/progress/structure — separately written, fire-tests, built to §20.6's own discipline) + LIV-2 (fraction of cells pinned at `n_min`) + JMP-1 (**three-state** distinguisher: stalled / converged / converged-with-absorbed-anomaly-pattern, the third watched via per-cell absorbed-failure rate).
**One §20.6/§20.7 delta.** Surfacing, never a breaker — stalling is absence, not harm. Generalizes §20.4's sustained-deferral alert from one cause to the class.

### WP-E — Growth beyond its own history *(fixes S5+S6 · research-grade · after A+B)*
**Composes:** ONT-7 first (granularity instrumentation — observe before acting: cluster-size distribution, per-skill starvation, merge/split churn) + JMP-2 (counterfactual variation as growth: SOLVE-side variant generator, P1-separated from JUDGE's item synthesis, outcomes seed `F` through the ordinary gate) + VIS-1 (`previsit` as §15's forward twin) + VIS-2 (vision nodes + backward design via the existing backward walk).
**The composed picture:** growth becomes three-sourced — bottom-up (failures, today), intervention (manufactured evidence, JMP-2), top-down (vision-directed, VIS-2) — with granularity finally observable. This is the package that answers Zahavy on MDLP's substrate; the safety lines are already written (projection proposes, reality disposes; generator-off degeneracy).
**Ordering inside:** ONT-7 → JMP-2 → VIS-1/2. Each gated separately; each degenerates to current spec when off.

### WP-F — Positioning & portability *(fixes S8+S9 · continuous, paper-cadence)*
**Composes:** JMP-3 (scope statement: within-schema learning + evidence-driven extension; evidence-free restructuring out of scope, Zahavy as the boundary argument; Peirce naming for the loop) + ONT-5 (stable skill ids + non-authoritative ESCO/CTDL mappings — mappings, never merges) + ONT-6 (name the causal prereq story — `decay_edges` intervention-renewal + `q_edge` = a randomized-intervention policy — and benchmark against co-occurrence baselines) + P-001 (propose→validate→apply into `patterns.md` — framework-side, no gate) + the paper hooks (IX-040 as the credibility hook; the axiom-layer position: MDLP attacks ontology learning's 20-year open layer with a held-out signal; the ESCO mappings-not-merges convergence with P2).

---

## 3. Sequencing

```
WP-A (author better)          ── first; framework-side parts immediate, gated parts next
   └─► WP-B (invariant layer) ── the structural centerpiece; RAF-1a is the first gate submission
          ├─► WP-C (corpus)   ── CQs can be drafted in parallel; pre-register after B's figure exists
          └─► WP-E (growth)   ── ONT-7 early (instrumentation is cheap); JMP-2/VIS after B
WP-D (liveness)               ── small, independent; slot anywhere
WP-F (positioning)            ── continuous; P-001 immediately (no gate), rest at paper cadence
```

**First three gate submissions, in order: RAF-1a → ONT-1′ → LIV-1(+JMP-1).** Rationale: RAF-1a is the highest-leverage single artifact (makes G3-class detectable, anchors WP-B, first thing a paper reviewer looks for); ONT-1′ is the cheapest because its mechanism is already approved; the liveness delta is small and self-contained. RAF-7's framework-side parts don't queue behind the gate at all — they can land as `evolve:` commits now, which is why WP-A is "first" without blocking anything.

**Deferred, explicitly (L-003 — queued is not endorsed):** peer learning (largest new direction; revisit at M-R when the fleet is real — but carry Q5: it may not be M3-gated); VIS-3/4 (after VIS-1/2 prove); RAF-5 (fleet membership — M3 horizon); RAF-9/RAF-10 (real but not load-bearing now); ONT-2 (folded into ONT-4 — the CQ form is the cheap version of the same idea).

---

## 4. The framework's own harvest (the other half of "evolve")

The retrospective is **due** (triage flag) and this arc minted its substrate — IX-048…IX-056 plus lesson candidates that now have the evidence bar:

- **Source-class grading** — *three instances this arc*: primary transcript ≫ walkthrough (the method M1–M10 were only in the transcript); position paper supports scope claims, never mechanism claims (Zahavy, review-softened); non-research sources can donate devices but not studies (the two-page guide → RAF-7b/c). Reduces to a mechanical rule; ripe for L-015.
- **ML-1** — a mechanism-level mapping is not a problem-level identity (the isomorphism error, owner-caught).
- **ML-3** — points of misfit are more generative than points of fit (argmax→ZPD band; Vulcan→absorption).
- **The reactive-constraint pattern** — third sighting (L-013 class, acyclicity's arrival, the constraint inventory); WP-B is the fix, but the *authoring* lesson stands on its own.
- **The OpenReview fetch chain** — WebFetch and API Cloudflare-blocked; browser pane passes; forum HTML carries the review thread; author sites carry PDFs. Candidate for a small skill if it recurs (first instance — log, don't build; L-003).

These are `retrospective`'s to write, not this plan's — listed so the due run has its inputs named.

---

## 5. What this plan does *not* do

- **Fix G1/G2/G5/G6/G7.** TA-side, HANDOVER-governed, owner-crossed (L-012). This plan's contribution to them is WP-B (prevention/detection) and nothing else.
- **Commit to the spec compression.** WP-A carries the owner's decision points 1–2 (compress? add a compression dimension to the gate?) — decisions, not defaults.
- **Start peer learning or prospection's later stages.** Directions, parked with explicit revisit triggers.
- **Add anything new.** Every item above exists in a committed study/note; this document only maps, composes, and sequences.

---

*Companion reading order: `SYNTHESIS-raft-ontologies-peer-learning.md` (findings, graded) → this plan (gaps → packages) → the individual studies for detail. Everything gated flows `review-360` → `change-approver` (L-010); framework-side items are `evolve:` commits under the open lanes; INVARIANTS-fenced edits become owner tasks (L-005).*
