# Ungated harvest — what these sources make possible if nothing is off-limits

**Date:** 2026-08-12 · **Status:** **speculative note. Not a study, not a proposal set, not evidence-graded.** Written on an explicit request to think without gate discipline, MVP discipline, or additive-only discipline. Several items below **contradict standing project rules** (L-010's gate flow, P2's append-and-supersede, the "additive only" convention). Those collisions are named where they occur rather than smoothed over.
**Companion to:** `STUDY-ontologies-and-raft.md` (the graded version).

---

## 1. ~~MDLP is a consensus algorithm with a statistical quorum~~ — **WITHDRAWN 2026-08-12**

> **This section's central claim is retracted.** Raft and MDLP serve different purposes: Raft agrees on *facts* among identical replicas; MDLP infers *competence* among deliberately differing learners. A 1:1 structural comparison is not available, and the section below reasons from "the mechanisms map" to "the problems are the same," which does not follow. The correspondence table remains readable as a *loose* aid, not as a derivation — in particular **the property list is NOT derivable from Raft's** as claimed.
>
> **What survives, and it is the more useful claim:** Raft is a worked study in **assigning roles to a population under uncertainty**. That transfers, and it transfers to peer learning rather than to consensus. See **`NOTE-peer-learning-roles.md`**, which supersedes this section.
>
> **Two items below survive the retraction on their own merits**, because neither depends on the isomorphism: the **decay/replay-determinism question** (does any decay key off wall-clock? `test_rebuild_idempotent` asserts determinism, not determinism-relative-to-a-decay-schedule), and the observation that **RAF-1's property slate was hand-assembled** and should be attacked rather than trusted.

### (retained for the record — read as retracted)

MDLP is a consensus algorithm with a statistical quorum, and has never said so

Look at what MDLP's core loop actually does: **multiple unreliable witnesses must agree on a value, and the agreed value then determines shared state.** Witnesses are held-out items and verifiers; the value is competence; the shared state is the checkpoint and the skill graph. That is the consensus problem.

The correspondence is not loose:

| Raft | MDLP |
|---|---|
| term | `checkpoint_id` / generation |
| leader, whose log is authoritative | JUDGE + TruthStore ("truth canonical, projections rebuildable") |
| log entry | evidence record with occurrence identity |
| **committed** = stored on a **majority of servers** | **committed** = `Δ > margin + z·SE` on **held-out items** |
| followers converge to leader's log | projections rebuild from truth |
| membership change | §18 fleet roster + the rotating held-out sample |
| State Machine Safety | `test_rebuild_idempotent` |

**The single substantive difference is the quorum rule** — Raft counts servers, MDLP runs a hypothesis test over items. Raft's quorum is exact because commands are deterministic; MDLP's is statistical because evidence is noisy. *Everything else transfers.*

Two consequences, and both are large:

**(a) The property list is derivable, not inventable.** RAF-1's slate was assembled by hand from approved text. Under this framing it can be *translated* — each Raft property has an MDLP image, and where the image is missing that is a finding rather than an oversight. Example: **Leader Completeness** translates to

> **Competence Completeness** — *if a competence claim was committed at generation g, every later generation's estimate incorporates the evidence that produced it.*

MDLP **deliberately violates this**, because decay (`γ_slow`, `γ_fast`, `g.decay_edges`, discounted UCT) exists precisely to forget. That is a legitimate design choice — but it means rebuild determinism holds *only relative to a fixed decay schedule and replay order*, and `test_rebuild_idempotent` as written asserts determinism, not that condition. **Concrete thing to check: does any decay anywhere key off wall-clock rather than event count?** §3's update is per-update (fine) and §17.6's `w_prune` counts evaluation windows (fine); §5.1's `g.decay_edges` "unless intervention evidence renews it" does not state its window. If any of them is time-based, replay is not deterministic and a whole test's guarantee is weaker than it reads. This is exactly the class of question a property checker settles and a deep-read does not.

**(b) It is the paper's frame.** "Learning as a replicated state machine; competence as a committed log entry; the commit rule as a statistical quorum" is a positioning MDLP does not currently have, and it borrows 30 years of accumulated intuition for free. It also converts the current claim — *nobody measures learning outcomes*, a negative, three-times-confirmed but negative — into a positive one.

*Honest caveat:* the isomorphism should be attacked before it is leaned on. The place it is most likely to break is membership: Raft's quorum set is known and fixed between configuration changes, while MDLP's is a **rotating sample**, so "majority of a known set" and "enough draws from a distribution" may not be the same kind of object. If it breaks there, the fix is probably that MDLP's quorum is over *the item population*, with the drawn sample as an estimator of it — which is a fine translation, but it needs to be made rather than assumed.

---

## 2. Point MDLP at its own specification

MDLP decides what to learn next from measured competence. Ousterhout's question was how to know whether an algorithm is understandable, and his answer was to measure whether people can implement it. **These are the same problem**, and the mapping is exact:

- the **spec** is the curriculum
- an **implementer** (agent or human) is the learner
- the **~120 named test stubs** are the held-out suite
- **competence** = fraction of a section's stubs passing on an implementation that never saw them

Run that and five things fall out of one experiment:

1. **A competence posterior over spec sections** — which sections are actually hard to implement, measured rather than asserted. This is C4's decomposition audit with data instead of reference-counting.
2. **`significant()` applied to spec edits** — did this revision *significantly* improve implementability, or is the improvement noise? The explain-it-back idea (RAF-7) becomes quantitative.
3. **An empirical prereq graph over sections** — which sections must be understood before which, discovered rather than declared. MDLP's own §5.2 machinery, applied to its own text.
4. **The learning-progress signal identifies where to spend authoring effort** — exactly what the algorithm is for.
5. **An implementability number for the paper**, which is Raft's most-cited experimental contribution, run at a cost humans could not match.

**Why this is bigger than an experiment: it is a candidate bridge corpus for G4.** The audit's ceiling is that *all live evidence is on toy cipher skills*. Implementing a spec section against a pytest suite is **real coding work with real verifiers**, it is precisely the domain MDLP claims (agents learning software tasks), and **it exists today** — no corpus construction required.

*Honest limits, stated plainly:* it is **not** a substitute for G4. It is one domain, narrow in style, ~120 stubs — small. And there is a conceptual circularity worth naming even though the P1 boundary holds mechanically (held-out stubs never enter the implementer's context): the corpus author has ground truth about the corpus. What it *is*: strictly better than toy ciphers, available immediately, and the only corpus where running the experiment doubles as a paper contribution.

---

## 3. The structural gate is a verifier-*external* channel — an instrument, not just a guard

`STUDY` framed ONT-1 as a missing gate. That undersells it. Consider the two-axis space:

|  | structurally legal | structurally illegal |
|---|---|---|
| **statistically warranted** | commit | ← **this cell is the interesting one** |
| **unwarranted** | reject (cheap) | reject (twice) |

**A change that raises held-out competence while violating a structural invariant is diagnostic.** It means the verifier is rewarding something the domain model says cannot happen — which is a **verifier-defect detector that does not depend on the verifier.**

Every instrument MDLP currently aims at RC-2 is verifier-internal: held-out splits, counterfactual variants, trajectory-shape checks, audit-anchored reliability, generalization ratios. All of them ask the verifier apparatus about itself. A structural gate would be **the first channel that is independent of it** — and two independent channels that can *disagree* is worth far more than either alone. The disagreement rate is itself a metric: rising structural-violation-among-accepted-changes is an early warning that the verifier is drifting, available before any competence signal degrades.

Concretely: log every `(structurally illegal, competence-improving)` event as its own record class, and treat a rise in its rate as a §14-style breaker trigger.

---

## 4. Delete sections — and the reason MDLP cannot currently do that is structural

The additive-only convention (C1) plus append-and-supersede plus a gate that has no compression term means **the spec can only grow**. Note what the gate actually scores: correctness, completeness, risk, contradiction. **Nothing in `review-360` asks whether the artifact as a whole got easier or harder to hold.** So every approved change ratchets, by construction, and 30 rounds of high-quality review cannot catch it — the gate is not blind to the problem, it is not *looking* at it.

If nothing is off-limits, the honest reading of M2 is that MDLP should **remove**, not consolidate:

- **§13 (Tutor layer)** — explicitly "names what the decision core already is." A renaming with zero mechanism. Genuinely valuable for the human-learning framing — so move it to `PAPER.md`, where framing belongs, and out of the spec of record.
- **§15 (re-visiting / surprise)** — §15.3's termination rule duplicates §16.6, §15.4 is deterministic-domains-only, §15.6's storage story is §10. What remains that is not elsewhere is `revisit` as an action type, which is a paragraph in §5.3.
- **§14 + §19** — one calibration section, two instantiations.
- **§9 + §17.3** — one two-stage promotion primitive, parameterized by artifact kind.
- **§18** — deferred to M3 yet already forcing `agent_id` keying into approved schemas across §17.6, §6.1, DATA-LAYER §5. It is paying complexity rent two gates early.

Rough shape: **20 sections → ~12, with no capability removed.** Whether that trade is right is the owner's call; that it has never been *offered* is the finding.

**Collision, named:** this contradicts P2's append-and-supersede discipline and the additive convention directly. The counter-argument is real — those rules exist so history is never lost and so no approved mechanism silently changes. A middle path that keeps both: **the spec of record becomes the compressed 12-section artifact, and the current 20 sections become an appendix of record.** Nothing is deleted; the *reading path* is compressed. That is compression without loss, and it is probably the version worth actually proposing.

---

## 5. One control plane, one lifecycle

F6 said MDLP has three control planes — JUDGE (gates), the §20 supervisor (liveness), the §18 fleet (coverage) — with three vocabularies. Redpanda's argument applies: one mechanism everywhere beats two systems that must reason about each other.

MDLP is already ~70% of the way there and has not named it. §6.1's work unit — `(agent_id, episode_id, suite_id, intent_key, item_ids, owner, lease)` — is general. §20.2 already routes schedules through it and says so explicitly: *"no second lease system."* §17.6's scaffold-version lifecycle (`candidate→shadow→live|retired`) is a *different* state machine that is plausibly work-unit-shaped.

**The unification: everything in MDLP is a proposal with an epoch, a lease, and a gate.** Gate decisions, scheduled jobs, scaffold versions, fleet membership changes, calibration updates — one row shape, one lifecycle, one recovery predicate, one claims rule. That is P-001 promoted from "a pattern we noticed" to **the architecture**, and it is state-space minimization applied at the level Ousterhout applied it (he did not merge two functions; he made `AppendEntries` be both replication and heartbeat).

---

## 6. Paper reframe

**"In Search of an Understandable Learning Algorithm."** The echo is deliberate and the audience is right: implementers of agent-learning systems, currently served by nothing legible.

The hook is the part that feels like a liability. **MDLP already ran the negative experiment.** IX-040 is a documented case of *we specified an algorithm, implemented it ourselves, and got it wrong in six places with several constructs never wired at all.* Published alongside the property table that would have caught it, that is far more credible than a clean success story — and it is exactly Ousterhout's thesis with fresh evidence, in a domain where the implementer can be an LLM (which Antithesis explicitly flags as the emerging case).

Structure: the algorithm · the property list · what happened when it was implemented · the implementability study (§2 above) · the corpus result, GO or honest NO-GO.

---

## 7. What is *not* worth taking, so the list stays honest

- **Consensus itself.** MDLP has no need of leader election or quorum replication. The isomorphism in §1 is a *frame and a property generator*, not an instruction to implement Raft.
- **TLA+.** The trace-validation *shape* transfers and is cheap; the formalism does not — TLA+ handles probability badly and MDLP's properties are statistical.
- **RDF/OWL/triplestores.** Zero-infra is load-bearing.
- **Raft's performance engineering** (batching, pipelining, multi-raft). MDLP is not throughput-bound.
- **A human user study.** Slow, expensive, and strictly worse than the agent version, which is cheaper, repeatable, and larger-N.

---

*Nothing here is gate-approved, evidence-graded, or ready to act on. §1's isomorphism should be attacked at the membership/rotating-sample seam before it is used. §2 is the item most likely to repay work immediately. §4 contradicts standing discipline and is recorded with that collision explicit, plus a middle path that keeps both. L-012 unchanged: anything crossing to turing-agents crosses via the user.*
