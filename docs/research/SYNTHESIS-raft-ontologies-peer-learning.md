# Synthesis — ontologies, Raft, and peer learning

**Date:** 2026-08-12 · **Status:** consolidation checkpoint, ungated. Written at the owner's request before moving forward.
**Covers:** one working session, three source-analysis artifacts, one retraction, and one new design direction.
**Purpose:** a single place to see what was studied, what was concluded, **how confident each conclusion is**, what was withdrawn, and what decisions are now open. Where this document and its sources disagree, the sources are authoritative on detail; this one is authoritative on *status*.

---

## 1. What was studied

| Source | What it is | How it was read |
|---|---|---|
| `turing.ae/blog/agentic-systems-need-ontologies/` | Turing Agents essay: deterministic symbolic guards over probabilistic agents; corrects a talk's OWL claims | Full read; **SHACL semantics independently verified against the W3C Recommendation**, not taken on the essay's word |
| `turing.ae/blog/raft-designing-for-understandability/` | Turing Agents walkthrough of Ousterhout's lecture | Full read |
| **Ousterhout lecture transcript** (~60 min, owner-supplied) | The primary source for the **design method** | Full read — materially richer than any walkthrough; §4 of the STUDY rests on it |
| `raft.github.io` + Ongaro/Ousterhout paper | Raft itself | Read; the five safety properties and membership/compaction verified against the paper |
| **Production Raft survey** | Kafka/KRaft (KIP-595, KIP-500, KIP-101/279, KAFKA-6361), CockroachDB, TiKV, etcd/raft, MongoDB, ScyllaDB, Redpanda, HashiCorp Raft | Targeted reads: KIP-595 in full; Antithesis' 2026 bug-hunt; Howard et al. *Raft Refloated* (SIGOPS OSR 2015); etcd-raft's TLA+ trace validation |

**Provenance note that matters:** both essays are published by **Turing Agents** — the same org whose self-evolving framework this repo runs on. These are the systems-design foundations that framework leans on, so a disagreement between MDLP and them is worth resolving rather than noting.

---

## 2. The arc — how the analysis actually moved

Recorded because the *shape* of the movement carries a lesson (§6).

1. **Source mapping.** Read the two essays against the spec of record. Landed one thesis: *structural legality is deterministic, competence is statistical, and MDLP has formalized only the second.* Produced the ONT/RAF adopt-avoid lists and nine proposals.
2. **The transcript changed the centre of gravity.** The owner supplied the full lecture, flagging the **method** as the interesting part. Extracting M1–M10 from the primary source, and then checking MDLP against it (C1–C4), produced findings **more valuable than any of the mechanism transfers** — and more uncomfortable, since two of them are about how MDLP is authored rather than what it says.
3. **The production survey tested Ousterhout's own premise.** *"Implementation always changes it"* is falsifiable and ~100 deployments exist. It holds: **every serious deployment modified Raft; none adopted it verbatim.** This converted the property-list proposal (RAF-1) from a theoretical argument into an empirical one.
4. **Ungated thinking over-reached.** Asked to drop all discipline, the analysis proposed that MDLP *is* a consensus algorithm with a statistical quorum. **The owner rejected it: different purposes, no 1:1 comparison.** Correct — see §5.
5. **The correction produced the best output.** Redirected to *roles are not fixed*, the Raft material yielded a peer-learning design in which teacher and student are **assignments over a participant pool**, not types. The sharpest result in that design came from a place where **Raft is wrong for MDLP** (argmax vs. band), not where it is right.

---

## 3. Consolidated comparisons

### 3.1 Three philosophies of control

| | Ontology / SHACL approach | Raft | MDLP today |
|---|---|---|---|
| **Question answered** | is this well-formed? | do we agree on this fact? | should this be believed? |
| **Nature of the verdict** | deterministic veto | deterministic agreement | **statistical** test |
| **World assumption** | **closed** (unstated ⇒ false) | closed (known membership) | **open** (evidence accrues) |
| **Cost** | free | one round trip | a held-out eval budget |
| **Output on failure** | validation report (3 severities) | rejection + step-down | rejection + rollback |
| **Failure if absent** | silent graph corruption | split brain | reward hacking |

**The synthesis:** these are not competitors. MDLP is right that competence cannot be gated symbolically; the essay is right that structure cannot be gated statistically. MDLP has built one of the two, and pays eval budget to reject candidates a free deterministic check would refuse at the door.

### 3.2 MDLP vs Raft — the *corrected* comparison

The earlier structural isomorphism is withdrawn (§5). What remains, honestly separated:

| Transfers | Does **not** transfer |
|---|---|
| **Role assignment under uncertainty** — the whole of `NOTE-peer-learning-roles.md` | **The problem.** Raft agrees on *facts* among identical replicas; MDLP infers *competence* among deliberately differing learners |
| **Epoch discipline** — stamp records with the generation they were computed under; reject or revalidate across generations | **Quorum semantics.** Counting servers ≠ a hypothesis test over items |
| **Named safety properties** as the thing that makes modification checkable | **"The leader's log is always right."** Raft's most elegant simplification is transfer-poisoning if applied to a teacher |
| **The design method** (M1–M10) — decomposition, state-space minimization, explanation-as-fitness-function | **Passive followers.** A student driving its own posterior is MDLP's core |
| **Completeness discipline** — total state machines, exhaustive predicates with normative evaluation order | **Performance engineering** — batching, pipelining, multi-raft. MDLP is not throughput-bound |

### 3.3 Raft in production — what changed on contact

Full table in `STUDY §5`. The compressed finding: **8 of 8 systems surveyed modified Raft.** Kafka flipped push→pull, dropped heartbeats, added a commitment condition, deferred snapshots and pre-vote. CockroachDB moved to joint consensus and found etcd/raft deviating from the spec — then documented extra invariants rather than force compliance. MongoDB independently went pull-based. Redpanda uses Raft for everything and no ISR; Kafka deliberately runs two protocols.

---

## 4. Findings, graded by confidence

### High — multiple independent supports

- **F-A · MDLP has no structural-admissibility gate, and the insertion point already exists.** §6.2 declares `GraphStore.merge()` the only projection write path and `MergeReport` already carries `rejected: [(id, reason)]`. *(essay + direct reading of the spec)*
- **F-B · Named safety properties are what let Raft survive modification.** Three independent instances: KIP-595 argues its extra commitment condition preserves **Leader Completeness**; CockroachDB documented the additional invariants keeping etcd/raft's deviation safe; Antithesis' checker reports violations *by property name*. **MDLP is already being modified in TA and has no property list**, which is why IX-040 had to be a four-way deep-read instead of a checklist.
- **F-C · Bugs cluster in the extensions, not the core.** Antithesis found 2 of 3 HashiCorp Raft bugs in leadership transfer and `InstallSnapshot` — outside the verified core. MDLP's shape is identical (§1–§12 core, §13–§20 extensions) and the audit found the unwired constructs in extension territory.
- **F-D · Independent reimplementation finds what review does not.** Howard et al. found under-specification and a livelock absent from the spec; IX-040 found six bugs and unwired constructs. Two instances, same yield.
- **F-E · Implementation always modifies the algorithm.** 8 of 8 production systems. Ousterhout's premise, empirically confirmed.

### Medium — single strong support, or my inference from MDLP's own text

- **F-F · MDLP's spec is additive-only by construction, which is the add-only ratchet P2 and RC-4 exist to forbid.** The section headers state the convention themselves (*"no §1–§12 mechanism changes"* etc.). The inference — *that this is the same failure P2 names, applied to the specification rather than the data structures* — is mine, and it is the single sharpest finding of the session.
- **F-G · `review-360` has no compression term.** It scores correctness, completeness, risk, contradiction — never *does the artifact as a whole get easier or harder to hold*. So approved changes ratchet **by construction**, and no amount of review quality catches it. *(inference from the gate's own criteria)*
- **F-H · Additive ≠ decomposed.** §20 cites nine other sections; §17.6 cites six. A layer that changes nothing below still costs full comprehension load. **Measurable and not yet measured.**
- **F-I · Peer teaching qualification is a band, not an argmax.** Strong support in the human literature (expert blind spot, near-peer tutoring), and it directly contradicts the naive Raft transfer. **Untested in MDLP.**
- **F-J · The structural gate would be MDLP's first verifier-*external* channel.** Every current RC-2 instrument asks the verifier apparatus about itself. *(inference, but a clean one)*

### Open — stated as questions, not findings

- **Q1 · Does any MDLP decay key off wall-clock rather than event count?** §3 is per-update and §17.6's `w_prune` counts evaluation windows; **§5.1's `g.decay_edges` does not state its window.** If any is time-based, replay is not deterministic and `test_rebuild_idempotent` guarantees less than it reads. **Concrete, checkable, unresolved.**
- **Q2 · Does teaching pay the teacher?** Forks the peer-learning design: if yes it is self-incentivising and needs no fleet-altruism term; if no, explicit coordination is required.
- **Q3 · Is the spec + its ~120 stubs a viable bridge corpus for G4?** Better than toy ciphers, available today, narrow in style, conceptually circular in a way worth naming.
- **Q4 · Does a peer-learning population beat N independent learners on the same budget?** The claim that would justify the fleet.
- **Q5 · Is peer learning actually gated behind M2/M3?** It needs neither the weight axis nor self-modification, so §18's placement may be wrong and the fleet's first payoff may be a milestone earlier than planned.

---

## 5. Withdrawn

**The MDLP↔Raft structural isomorphism** (`NOTE-ungated-harvest.md` §1) — proposed, then rejected by the owner on the correct grounds that the two serve different purposes. The section is retained in place, marked retracted, because the reasoning is worth having on record.

**Two sub-findings survive the retraction on independent merits:** Q1 (the decay/determinism question, which never depended on the isomorphism) and the observation that **RAF-1's property slate was hand-assembled and should be attacked rather than trusted** — it is *not* derivable from Raft's, as the withdrawn section claimed.

---

## 6. Meta-learnings — about the analysis, not the sources

Three, and they generalize beyond this session.

- **ML-1 · A mechanism-level mapping is not a problem-level identity.** The isomorphism error came from reasoning "the parts correspond, therefore the problems are the same." They didn't. **When a mapping feels unusually clean, check whether the *problems* match before leaning on it — not whether the *parts* do.**
- **ML-2 · Holding a *method* against MDLP beat mapping *mechanisms* into it.** The mechanism transfers (epochs, snapshots, membership) are real but incremental. C1/C4 — found by asking *would this spec pass Ousterhout's own design criteria?* — are structural and would not have surfaced from any amount of feature comparison.
- **ML-3 · The best result came from where the source was *wrong* for MDLP.** Raft's `argmax`-completeness voting rule is exactly the wrong shape for peer teaching, and noticing *why* produced the ZPD band — the most novel idea of the session. **Points of misfit are more generative than points of fit.**

*(ML-1 and ML-3 look like lesson candidates. Per house discipline, lessons are `retrospective`'s to write — recorded here as candidates, not filed.)*

---

## 7. The consolidated proposal set

Fourteen items now exist across three documents. Consolidated, with the source doc:

**Tier 1 — carry the argument**
| ID | What | Where |
|---|---|---|
| **RAF-1** | Safety-properties figure **+ a property checker replaying TruthStore** | STUDY §7 |
| **ONT-1** | Structural admissibility gate between EXTRACT and MERGE | STUDY §7 |
| **RAF-7** | *Explain-it-back* stage added to the L-010 gate | STUDY §7 |
| **RAF-4** | Independent-reimplementation protocol | STUDY §7 |

**Tier 2 — real gaps with production receipts**
`RAF-3` epoch discipline (KIP-101 receipt) · `RAF-6` snapshot boundary (KIP-630 receipt) · `RAF-2` state-space minimization on four duplications · `RAF-8` decomposition audit

**Tier 3 — queued, not endorsed**
`ONT-2` domain ontology for G4 coverage · `RAF-5` fleet membership configuration · `RAF-9` deterministic core boundary · `RAF-10` name the control-plane story · `P-001` propose→validate→apply

**Separate track — new direction, not a proposal**
Peer learning (`NOTE-peer-learning-roles.md`). Not in the tier list because it is a **design direction**, not a delta to an existing section. If pursued it flows the gate like anything else.

**Also open from the ungated note**, and not yet proposals: pointing MDLP at its own spec (§2 of that note — the item most likely to repay work immediately); the compressed-spec-of-record + appendix-of-record middle path (§4); one control plane (§5); the paper reframe with IX-040 as the hook (§6).

---

## 8. Decision points for the owner

Nothing below is actionable without a call. Roughly in order of consequence:

1. **Does the spec get compressed?** ~20 sections → ~12 with no capability lost, via the middle path (compressed spec of record, current sections become an appendix of record). This collides with append-and-supersede discipline and is the owner's call, not the analysis's.
2. **Does `review-360` gain a compression dimension?** Without it, F-G says the ratchet continues regardless of review quality.
3. **Is the spec-as-corpus experiment run?** It resolves Q3, and simultaneously yields the implementability study, the decomposition audit, and a non-toy corpus.
4. **Is peer learning pursued now or after M-R?** Q5 suggests it may not be M3-gated. It is the largest new direction on the table and the most faithful to the human-learning origin.
5. **Which of Tier 1 goes through the gate first?** RAF-7 is cheapest and changes how everything after it is authored, which argues for it going first.

---

## 9. Artifact map

| Document | Class | Contains |
|---|---|---|
| `STUDY-ontologies-and-raft.md` | **study, ungated, evidence-graded** | §1–§3 the two essays mapped to MDLP · **§4 the design method (M1–M10) + MDLP self-check (C1–C4)** · §5 production survey (F1–F8) · §6 propose→validate→apply · §7 tiered proposals |
| `NOTE-ungated-harvest.md` | **speculative note** | §1 **retracted** · §2 spec-as-corpus · §3 verifier-external channel · §4 deletion + the compression finding · §5 one control plane · §6 paper reframe · §7 what not to take |
| `NOTE-peer-learning-roles.md` | **design sketch** | T1–T8 role transfers + two explicit refusals · the ZPD band · two-sided measurement · the Tutor-does-not-rotate boundary · failure modes · check set |
| **this document** | **synthesis checkpoint** | the arc · consolidated comparisons · confidence-graded findings · withdrawals · meta-learnings · decision points |

Session interactions captured as **IX-048 … IX-051**; `project-profile.md` updated inline each turn (L-007).

---

*Nothing in this session touched a gated artifact. Everything above is proposal or sketch; anything that becomes a spec change flows `review-360` → `change-approver` (L-010). Anything crossing to turing-agents crosses via the owner, manually (L-012).*
