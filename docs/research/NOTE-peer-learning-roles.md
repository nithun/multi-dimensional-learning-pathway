# Peer learning — teacher and student as *roles*, not types

**Date:** 2026-08-12 · **Status:** design sketch, ungated. Not a spec delta. A direction for the algorithm, prompted by the owner's reading of Raft: *"who is teacher who is student, this can be changed."*
**Correction it rests on:** an earlier note (`NOTE-ungated-harvest.md` §1) claimed MDLP and Raft are structurally isomorphic. **That claim is withdrawn** — Raft agrees on *facts* among identical replicas; MDLP infers *competence* among deliberately differing learners. Different problems. What genuinely transfers is narrower and more useful: **Raft is a worked study in assigning roles to a homogeneous population under uncertainty**, and role assignment is exactly what a peer-learning design needs.

---

## 1. What MDLP currently assumes, and why it's an assumption

§13 defines three roles as **types**:
- `Tutor` — the strategist, generic, embedded
- `LearnerAdapter` — *who* is taught
- `TeacherAdapter` — *how* a concept is taught (pluggable pedagogy, explicitly not in the core)

A `TeacherAdapter` is a **pedagogy module**, not a learner. Nothing in MDLP lets a learner teach. §18's fleet shares a substrate, and §18.3's "emergent curriculum" is the closest thing — but it is *passive*: A's validated mastery becomes a prereq scaffold and a bounded warm-start prior for B, through the graph. **No agent ever performs a teaching act for another.** Capability moves only as artifact transfer (B3, zero-trust, re-validated).

That is a design choice, never argued for. Once roles are assignments rather than types, there is one entity — a **participant**, anything carrying a competence posterior — and the system assigns `student` and `teacher` per cell, per episode, from the same pool.

---

## 2. The role machinery Raft actually contributes

Taking the mechanisms one at a time, and being explicit about which ones **do not** transfer:

**T1 — Roles are epoch-scoped, and expire.** Raft: leader *for term T*; every term begins with an election. → **teacher-of-record for (skill s, band d, epoch e)**. The role does not persist. This is what stops a once-expert peer from teaching forever after their competence has decayed or the domain has moved — the exact failure MDLP's `γ` decay exists to model but currently has no role-level consequence.

**T2 — Qualification is checked by others, never self-asserted.** Raft: a candidate advertises `(lastLogTerm, lastLogIndex)`; **voters refuse** if their own log is more complete. → **a peer may teach cell (s,d) only if the comparison passes on the student's / JUDGE's side.** Self-nomination is insufficient. `significant()` is already the right comparator. This is the anti-overconfidence mechanism, and MDLP gets it almost free.

**T3 — Randomization breaks symmetry, and here it does triple duty.** Raft's dead end was *ranking* servers ("we kept adding special case after special case"); randomized timeouts fixed it, and the same mechanism handled both initial election and split-vote retry. → When several peers qualify, **do not rank — randomize** (Thompson over the teacher-effect posterior). That gives, from one mechanism: **(a)** symmetry-breaking, **(b)** exploration over teachers, which §13's "Tutor selects among Teachers by held-out gain" requires and currently has no source of, and **(c)** *identification* — randomized assignment is what makes the teacher effect estimable at all rather than confounded with who-gets-picked. Three problems, one mechanism: past Ousterhout's bar, and it turns the fleet into a continuously-running randomized trial.

**T4 — Step-down on seeing better evidence.** Raft: a leader seeing a higher term immediately becomes a follower. → Role reversal when posteriors cross. **MDLP gets this for free by not having persistent role state**: eligibility is recomputed per episode, so no explicit step-down rule is needed. Simpler than Raft, for once.

**T5 — Epoch-stamped acts.** Every Raft RPC carries its term; stale ones are rejected. → A teaching act records `(teacher's checkpoint generation, teacher's posterior at time of teaching)`. A lesson delivered under a since-invalidated competence estimate is **identifiable and discountable later** — which is where the epoch discipline (RAF-3) finally earns its keep on something other than fallback revalidation.

**T6 — One mechanism, two purposes.** `AppendEntries` is replication *and* heartbeat. → **A teaching act is instruction *and* measurement**: attempting to articulate a skill is itself evidence about the teacher's grasp of it. Developed in §4 below.

**T7 — Observers (from KRaft, not Raft proper).** Replicas that fetch and replicate but cannot vote or lead. → **A newcomer participates and receives teaching but may not teach** until its `n_eff` clears a floor. Clean cold-start handling that keeps unqualified peers out of the teaching pool without special-casing them out of the population.

**T8 — Pull, not push — and this is a real design decision, not a detail.** Kafka (KIP-595) and MongoDB *independently* flipped Raft to pull-based, both because the surrounding system was already pull-shaped. **MDLP's substrate is learner-driven** — the entire §5.3 policy is the learner selecting its own next action from its own uncertainty. So **peer learning here should be pull-based: the student requests help for the cell it is uncertain about, and the pool answers with a qualified peer.** Note this is the *opposite* of how most multi-agent "teacher agent" architectures work, which are push-based (a designated teacher decides what to deliver). The substrate argument says push would be fighting the algorithm.

### What does NOT transfer

**The leader's log is always right.** Raft's single strongest simplification — declare an authority, and reconciliation collapses to one-way copy. **MDLP must refuse it.** A teacher is *not* authoritative; a student copying a teacher's belief wholesale is precisely the transfer-poisoning failure §18.6 names. B3's zero-trust re-validation on the receiver's own held-out is the correct alternative and it is already specified. Worth stating explicitly so the design isn't read as cargo-culting: **the one place Raft is most elegant is the one place this design deliberately diverges.**

**Passive followers.** Raft followers *"do nothing. They take no actions on their own."* A student must not be passive — the learner's own posterior driving selection is the core of MDLP. The analogy correctly stops here.

---

## 3. The sharpest divergence: qualification is a *band*, not an argmax

Raft's voting rule picks the **most complete** log — monotone, `argmax`. Applying that naively gives "the most expert peer teaches," which is **wrong**, and known to be wrong in the human literature (expert blind spot; near-peer tutoring frequently outperforming expert tutoring for novices).

The right shape is **unimodal in the competence gap**, not monotone:

```
eligible(j → i, s, d) =
      significant( ĉ_j[s,d] − ĉ_i[s,d], SE_pair, margin = δ_min )   # meaningfully ahead (T2)
    ∧ ĉ_j[s,d] − ĉ_i[s,d] ≤ δ_max                                    # ...but the gap is crossable
    ∧ j ≠ i                                                          # no self-teaching
    ∧ n_eff_j[s,d] ≥ n_observer                                      # not an observer (T7)
```

`[δ_min, δ_max]` is a computable statement of the **zone of proximal development** — a concept MDLP's human-learning framing has always invoked and never operationalized. And MDLP is unusually well-placed here: **the band should not be a guessed constant. It is learnable per skill from held-out outcomes**, by the same machinery §19 uses to learn gate thresholds. That is a genuine research result if it holds — *the optimal teaching gap, measured*.

Selection among the eligible set is then Thompson over the teacher-effect posterior (T3), not argmax over competence.

---

## 4. Teaching pays the teacher — as a measured question, not an assumption

A teaching episode produces **two** held-out measurements:

- **student:** `Δĉ_i[s,d]` on *i*'s held-out → commits through §8 unchanged, P1 intact
- **teacher:** `Δĉ_j[s,d]` on *j*'s own held-out → does articulating the skill consolidate it?

The human literature (self-explanation effect, learning-by-teaching) says yes. **MDLP should measure it rather than assume it**, and it is one of the few places MDLP can settle a real pedagogical question with its own instrument.

The stakes are structural, not academic. **If teaching pays the teacher, peer learning is self-incentivising** — the teacher's existing §13.1 objective selects `teach` on its own merits, and no fleet-altruism term is needed anywhere. **If it doesn't, the fleet needs an explicit coordination term** and peer learning becomes a cost to be justified. That is a fork in the design, and one experiment resolves it.

---

## 5. The safety boundary that makes this safe

**The Tutor does not rotate.** Teacher and student are assignments over the participant pool; the Tutor is JUDGE-side, generic, and fixed — it assigns roles, measures outcomes, and owns the gate. **Election rules are not themselves up for election.** This is not a new invariant; it is §17.1's SOLVE/JUDGE wall applied to roles, and it is what keeps P1 intact while everything else rotates freely.

Corollary worth stating: role assignment is a JUDGE act. A participant cannot assign itself a teaching role, cannot teach itself, and cannot select its own student — the same reasoning that makes §17.6 forbid cross-agent CAPTURE.

---

## 6. Failure modes and their guards

| Failure | Guard |
|---|---|
| **Blind leading the blind** — two weak peers reinforce an error | `significant()`-gated qualification (T2) + the student commits only on **its own** held-out. A bad teaching act simply fails §8. MDLP is *stronger* than human peer learning here: the outcome is measured, not assumed. |
| **Error propagation / monoculture** | Teaching acts carry provenance; §15.6's graph derivation edge makes every student a later-invalidated belief reached **traceable**. §18.6's MMR diversity already applies. |
| **Teacher exploitation** (strong agents spend everything teaching) | Budget is already a hard constraint (§5.3); `teach` competes in the same objective. Resolved cleanly if §4's answer is "teaching pays." |
| **Confounded credit** — did the student improve *because of* the teaching? | §5.2's counterfactual leave-one-out credit + T3's randomized assignment, which is what makes the effect identifiable rather than merely correlated. |
| **Collusion / self-dealing** | JUDGE assigns roles (§5); `agent_id` scoping already exists. |
| **Stale teaching** | T5's epoch stamp. |
| **Coverage erosion** — peers teach only popular cells | §5.3's `f_min` coverage floor dominates, exactly as it dominates the §18.2 fleet discount. |

---

## 7. What this unlocks

- **The curriculum becomes co-constructed rather than authored.** §18.3 gestures at "a curriculum no one authored" but delivers it passively through the graph. With role rotation the curriculum *is* the matching — who teaches whom, what, when — and the matching is learnable by the value-of-information objective MDLP already has.
- **The action space grows without new machinery.** Selection moves from (learner, skill) to (student, teacher, skill, band). §5.3 and §16 already do z-scored VOI over a typed action space; only the action *type* is new.
- **Teacher effectiveness becomes a measured matrix** `E[Δĉ_i | teacher j, s, d]` — some peers are good at some bands. Learnable under existing counterfactual credit.
- **The fleet gets a reason to exist beyond parallelism.** §18's current justification is division of labour plus transfer. Peer teaching makes the population **superadditive** — a measurable claim, with `test_fleet_of_one_equals_single_agent` already establishing the baseline to beat.
- **Human↔agent peer teaching falls out with no new mechanism.** §13's `LearnerAdapter` already gives humans and agents one shape. If roles are assignments rather than types, a human teaching an agent — or the reverse — is just another assignment.
- **It makes MDLP *more* faithful to its human origin, not less.** Peer instruction and reciprocal teaching are among the most robust findings in education research. A learning-pathway algorithm with no peer mechanism is missing the thing that works best on humans.

---

## 8. Degeneracy, and the shape of the checks

**Pool of one ⇒ no eligible peer ⇒ `teach` never fires ⇒ exactly §13 as it stands today.** Proven, not asserted — the same discipline §18.2 applies with `test_fleet_of_one_equals_single_agent`.

Sketch of the check set: `test_pool_of_one_equals_current` · `test_no_self_teaching` · `test_teacher_must_significantly_exceed_student` (T2) · `test_gap_beyond_delta_max_refused` (the ZPD band — the anti-argmax regression) · `test_student_commits_on_own_heldout_only` (P1) · `test_teacher_gain_measured_not_assumed` (§4) · `test_tutor_role_never_assigned_to_participant` (§5) · `test_observer_cannot_teach` (T7) · `test_stale_teaching_identifiable_by_epoch` (T5) · `test_randomized_assignment_identifies_teacher_effect` (T3) · `test_invalidated_belief_traceable_to_students` (§6) · `test_coverage_floor_dominates_peer_selection`.

**New parameters:** `δ_min`, `δ_max` (or the learned band) · teacher-effect prior · `n_observer` floor · teach-action budget share.

---

## 9. The open questions, ranked

1. **Does teaching pay the teacher?** (§4) — a fork in the design; one experiment settles it, and MDLP can run it.
2. **Is the optimal gap really a band, and can it be learned per skill?** (§3) — the research contribution if it holds.
3. **Pull or push?** (T8) — the substrate argues pull; worth testing rather than assuming, since it contradicts most multi-agent teacher designs.
4. **Does the population beat N independent learners on the same budget?** — the claim that justifies the fleet.
5. **Where does this sit relative to M2/M3?** Peer learning needs no weight axis and no self-modification, so it is *not* obviously gated behind them. It may be closer to M-R than §18 currently implies — worth checking, because if so, the fleet's first real payoff arrives a milestone earlier than planned.
6. **What is a role, mechanically?** Input from the Rox study (2026-08-19, `STUDY-rox-agent-swarm.md` §5.4): Rox's governance makes agents **first-class security entities** in the same permission primitive as humans (the "Pod"), so *what an agent may do* is a revocable, provenance-traced **grant**, resolved by the same formula for every actor. Rotating teacher/student roles wants exactly this shape: "teacher for skill s" as a grant conferred by the competence-gap evidence (§3's band), revoked when the gap closes — not a hardcoded topology. Production precedent that identity-uniform grants scale; the open design question is what evidence confers the grant, which is this note's §3.

---

*Ungated design sketch. Nothing here is a spec delta; if pursued, it flows the L-010 gate like anything else. `NOTE-ungated-harvest.md` §1's isomorphism claim is withdrawn and superseded by §2 of this note.*
