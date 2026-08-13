# IMPL-PROTOCOL — pre-registered independent-reimplementation study (spec-as-corpus)

**Status:** protocol (pre-registration draft, 2026-08-13). Sibling of `M1-EVAL-PROTOCOL.md`; same discipline — everything in §1–§4 is frozen before any implementer runs, so the outcome is decided by criteria fixed here, not post-hoc judgment. This is WP-C of `PLAN-harvest-2026-08.md`: one run, three outputs — (1) a **bridge** corpus with real verifiers for G4, (2) the implementability study (RAF-4, `STUDY-ontologies-and-raft.md` §7), (3) the empirical decomposition audit (RAF-8's data).

**Precedent.** Howard et al., *Raft Refloated* (SIGOPS OSR 2015; F4 in `STUDY-ontologies-and-raft.md` §5): a clean-slate reimplementation found what thirty review rounds had not — under-specified client handling and a livelock whose fix was absent from the original spec. The methodology has a known yield, and MDLP already ran it once by accident: IX-040 (the 2026-07-28 audit of TA) was an unplanned single-implementer instance. This protocol turns that incident into a repeatable, pre-registered measurement with fresh implementers.

**Terms used.** *The spec* = `ALGORITHM-v0.2-pathway-learner.md` §1–§21 plus `DATA-LAYER.md` (the spec of record). *Stubs* = the named per-section test lists ("Checks (build-spec stubs)", convention §17.5 onward; ~120 named tests). *TA* = turing-agents, the reference implementation (not a subject here — its read was IX-040). *Conformant / live-path-reachable* are used exactly as ALGORITHM §21.2 defines them. Execution crosses to any implementation substrate only via the owner (L-012).

## 1. Competency questions — frozen first (ONT-4's device, scoped to this domain)

Per `STUDY-ontologies-for-mdlp.md` §5: a corpus is representative iff the skill graph induced from it answers its CQs. These six are the checkable definition of "representative enough to be a bridge," written before any run and amendable only by superseding this document:

- **CQ-1 (coverage).** For every spec-of-record section carrying a stub list, does the corpus contain at least one task whose held-out verifier scores competence on that section's mechanism?
- **CQ-2 (prerequisite routing).** Where section *s* cites section *t*'s mechanism, can the induced graph route a learner through *t* before *s* — does the recovered prerequisite order agree with the citation partial order (checked against RAF-8's reference-density map)?
- **CQ-3 (discrimination).** Do held-out outcomes vary across sections and across implementers — does the suite separate strong from weak implementations rather than saturating all-pass or all-fail?
- **CQ-4 (mechanical verifiability).** Is every task scored by pytest execution alone — same process, same rules, every time — with no LLM judge anywhere in the scoring path?
- **CQ-5 (defect-class realism).** Can the corpus distinguish *conforming* from *unwired* (§21.2's built-but-not-on-the-live-path class — the IX-040 defect class), not merely pass from fail?
- **CQ-6 (granularity).** Is each task section-sized — attemptable by one implementer in one bounded episode, so per-section attribution is meaningful?

## 2. Design — N independent implementers × spec section × held-out stubs

- **Subjects.** **N = 5** independent implementer agents (see §7 for why 5), one pinned backbone model version for all of them (the M1-EVAL fixed-backbone control). *Independent* means: fresh context per implementer, no shared artifacts, no cross-implementer visibility, no access to TA's codebase or to IX-040's findings.
- **Curriculum (what an implementer sees).** The full spec of record — the whole of ALGORITHM §1–§21 and DATA-LAYER, as Raft implementers got the whole paper. Per-section attribution comes from stub ownership (§3), not from context truncation; sections cite 6–9 other sections (S3), so a per-section context diet would manufacture failures the spec did not cause.
- **Held-out suite (what an implementer never sees) — the P1 mechanics, precisely.** The stub **names and one-line intents are public**: they appear in the spec text itself and function as Raft's named properties did — the implementer knows *what* will be checked. The stub **bodies** — the executable pytest code, its fixtures, operands, and assertions — are held out: they never enter any implementer's context, in any form, at any point. Enforcement is mechanical, as in the C0-hardened M0 run: context assembly excludes all test paths; every implementer transcript is audited post-hoc for stub-body strings; a hit voids that implementer's affected cells (see C-3).
- **Harness.** A fixed driver, written and frozen before any implementer starts, executes each implementation through the same scripted **canonical run** (default configuration, truth records collected) and then runs the held-out stub bodies against it. The canonical run is this protocol's instantiation of §21.2's "canonical protocol run": live-path reachability is read from the run's recorded truth trace (`component_invoked` / gate-decision rows, DL §5), exactly per §21.2's operational definition — a property of a recorded run, not of a call graph.
- **Frozen in the run artifact before implementer 1 starts:** spec commit hash, stub-suite commit hash, harness commit hash, N, backbone version, this document's criteria.

## 3. Metrics — frozen

Unit of classification: (implementer, section, stub). Classes, per §21.2, applied in this order (first match wins, so the three are exhaustive and exclusive):

1. **Divergent** — the stub body fails (including mechanism absent): §21.2 clause (a) fails.
2. **Unwired** — the stub's mechanism is present and passes when directly invoked, but leaves no trace in the canonical run: clause (b) fails. Built-but-unwired, as a measured quantity instead of an audit finding.
3. **Conforming** — stub passes **and** the mechanism is live-path-reachable in the canonical run: (a) ∧ (b).

Reported, per section, aggregated over N: **conforming fraction, unwired fraction, divergent fraction**, plus inter-implementer agreement per stub. The **per-section implementability map** — these fractions joined with each section's cross-reference density — is the decomposition-audit output (RAF-8): where divergence concentrates and whether it tracks citation load is the empirical answer to whether additive equalled decomposed. Token cost per implementer is reported, not gated.

## 4. Decision criteria — frozen, and what they mean for G4

Three corpus gates. Note what is deliberately **not** a gate: the conforming fraction. A low fraction is the study's yield (Howard et al.'s was exactly that), never a failed run — gating on it would punish the protocol for finding what it exists to find.

- **C-1 (representativeness):** CQ-1…CQ-6 answered affirmatively.
- **C-2 (discrimination, CQ-3 made numeric):** pooled conforming fraction strictly inside (0.05, 0.95), and at least two sections' conforming fractions differ by ≥ 0.20.
- **C-3 (P1 integrity):** zero unremediated stub-body leaks; voided cells ≤ 10% of all cells.

**GO** — all three hold over the full section set: the corpus is admitted as the **G4 bridge corpus** — real code, real pytest verifiers, usable in the `M1-EVAL-PROTOCOL.md` corpus slot now. Stated plainly, as the ungated-harvest note (§2) requires: this is **not** the full G4 corpus and does not close G4. It is one narrow domain — one spec, one authorial style, ~120 stubs — strictly better than toy ciphers, available today. The full representative corpus remains owed under HANDOVER-v3.
**PARTIAL** — C-1/C-2 hold only on a proper subset of sections: the bridge is admitted restricted to that enumerated subset; excluded sections are named with the failing CQ.
**NO-GO** — C-2 or C-3 fails globally, or the CQs are unanswerable: the corpus is not admitted for G4 in any role. A NO-GO says the *corpus device* failed — it says nothing about MDLP's algorithm, and the implementability map is still delivered in full.

## 5. Reported regardless of outcome

M-R discipline (HANDOVER-v3 §3): the milestone is the *run*, not the sign of the result — a NO-GO is a valid, publishable outcome. Every run of this protocol reports: the CQ answers with evidence; all three fractions per section and pooled; the implementability map with RAF-8 join; a divergence catalog in which each divergent stub is adjudicated as *spec under-specification* / *spec defect* / *implementer error*, with written rationale (unanimous failure across independent implementers is presumptive spec signal, the Raft Refloated pattern; split failure is presumptive implementer noise); the P1 audit result including voided cells; token cost; and every deviation from this document, dated.

## 6. Threats to validity — named, with mitigations

- **Corpus-author circularity (the honest one, carried from `NOTE-ungated-harvest.md` §2).** The spec's author is the stub author and the harness author: the same mind wrote the curriculum, the exam, and the grader. **P1 holds mechanically** — held-out bodies never enter implementer context — but no mechanical boundary removes the conceptual circularity, and this protocol does not claim it does. Mitigations: stub bodies and adjudication rules frozen at pre-registration hashes before any run; every adjudication in §5's catalog is logged with rationale and is itself reportable; a stub found to contradict the spec text is recorded as a **corpus defect**, never silently repaired mid-run.
- **Narrow domain.** One spec, one style. No claim beyond bridge status is made or implied (§4). Portability of the *method* — not the result — is the only generalization asserted.
- **Implementer monoculture.** N agents on one backbone fail in correlated ways; unanimous divergence may be model idiom, not spec defect. Mitigations: agreement reported per stub (§3); the §5 adjudication rule treats unanimity as *presumptive*, not conclusive, spec signal; backbone version pinned and reported so a second run on a different backbone is comparable.
- **Public stub names.** Implementers can aim at named checks (as Raft implementers aimed at named properties). Accepted as design, not leakage: the names are the spec's own conformance vocabulary (§21.2). The held-out boundary is the body, and C-3 polices it.
- **Harness bias.** The canonical run script decides live-path reachability. Mitigation: the script is frozen pre-run, is identical across all N, and its truth trace is part of the deliverable — reachability claims are re-derivable from the recorded run per §21.2.
- **Small N.** N = 5 bounds the resolution of agreement statistics; fractions carry no significance claims (this protocol has no `z·SE` gate to misuse them in). Anything needing statistical weight goes through `M1-EVAL-PROTOCOL.md` on the admitted corpus.

## 7. What this is not — and pre-registered choices the sources left open

Not a spec change, not a gate-mechanism change, not a replacement for `M1-EVAL-PROTOCOL.md` (it *feeds* that protocol's corpus slot on GO), and not the G4 closure. Execution happens outside this repo and crosses only via the owner (L-012).

Choices this document fixes that no source document determined, recorded so review can attack them: **N = 5** (smallest N where a 4–1 split is distinguishable from unanimity; no source names a number); **whole-spec context** rather than per-section diets (§2's rationale); **stub names public / bodies held out** as the P1 line (the spec text itself publishes the names); the **C-2 constants** (0.05/0.95 band, 0.20 separation, 10% void ceiling — order-of-magnitude choices, frozen so they cannot drift post-hoc); and the **divergent-before-unwired classification order** (§3 — a stub that both fails and is unwired counts divergent). Changing any of these after a run has started requires superseding this document through the L-010 gate.
