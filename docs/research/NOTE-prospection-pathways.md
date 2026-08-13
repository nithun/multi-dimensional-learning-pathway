# Prospection — projecting pathways into futures that don't exist yet

**Date:** 2026-08-13 · **Status:** design sketch, ungated. The owner's idea, translated into the spec's vocabulary and checked against it.
**The idea as given:** *MDLP can help an LLM do the jump by projecting multiple pathways to a future timeline and creating new learnings not present in the current timeline. Each knowledge dot at a timestamp has pathways forward and in reverse; this creates new visions and learning. Picture the world as a flat surface of knowledge in a 5th dimension.*
**Companion to:** `STUDY-llms-cant-jump.md` (the jump this answers), `NOTE-learning-liveness.md` (H1's third state is what prospection escapes), JMP-2 (the evidence-manufacturing stage this consumes).

---

## 1. The steelman — three separable mechanisms

Unpacked, the idea contains three distinct proposals:

1. **Forward projection.** From the current knowledge state, roll out *multiple hypothetical learning futures* — not just "which action next" but "what would I know at t+k along this pathway vs that one."
2. **Backward chaining from imagined states.** Posit a knowledge dot that does not exist on any current pathway — a skill no failure has ever evidenced — and walk *backward* from it to the present frontier, inducing the intermediate steps. Those intermediates are "learnings not present in the current timeline."
3. **A branch axis on the knowledge field.** The "5th dimension": the competence field indexed not only by (skill, difficulty, agent, generation) but by **which timeline** — a stack of counterfactual sheets over the same skill surface.

All three have precise homes. And the naming matters: this is **prospection** — what the cognitive-science literature calls *mental time travel* / *episodic future simulation* (Suddendorf & Corballis; Schacter). The empirical finding there is directly relevant: **remembering the past and simulating the future run on the same machinery.** MDLP already built the past-directed half — §15's `revisit(D)`. The idea on the table is its forward twin.

---

## 2. What already exists — so the delta is exact

Checked against the spec, because most of "project multiple pathways" is *already there in some form*:

| Existing mechanism | What it already does | What it does *not* do |
|---|---|---|
| **§7 MCTS value tree** | projects futures and backs up their value — literally multiple pathways | projects **scalar value only**, never the knowledge *content* of the future state |
| **§15.4 two-level search** | replays an episode under different actions in replayable domains | episode-scoped; searches within one data point, not across a curriculum |
| **§18 fleet** | N agents *are* N physically real parallel pathways over a shared substrate | all branches live in the same present; divergence in trajectory, not in projected time |
| **§10/§17.6 lineage** | checkpoint history is already a branching DAG (rollbacks create branches) | dead branches are archive, never consulted as *alternative futures* |
| **Thompson sampling (§5.3)** | every draw is a sampled possible-world of the learner | one-step; the sampled world is discarded after selection |
| **§15.6 derivation edges** | one data node carrying multiple realized paths — "each dot has pathways" | paths are *realized* only; no hypothetical path is ever represented |
| **JMP-2 invention engine** | manufactures evidence by running never-failed variants *now* | operates at the current frontier; no target beyond it |

So the field is closer to the idea than the idea's novelty suggests — **and the two genuinely missing pieces are exactly the owner's #2 and a disciplined form of #1:**

- **Nothing in MDLP represents a hypothetical future knowledge state.** Every node in every structure is evidenced or dead.
- **Nothing chains backward from a target.** All growth is forward from failures (bottom-up). There is no top-down mechanism — and the education literature says the top-down form is how humans design curricula: **backward design** (Wiggins & McTighe's *Understanding by Design* — start from the target competence, derive the prerequisite scaffold in reverse). MDLP, a curriculum algorithm drawn from human learning, has no backward-design mechanism. That is a genuine gap the idea names.

---

## 3. The formalization

### 3.1 `previsit(H)` — §15's forward twin

§15: `revisit(D)` re-processes a **stored past point** through the current model; gated by expected surprise; stops on assimilation.
Proposed: `previsit(H)` processes a **hypothetical future point** through the current model — imagine the learner that has mastery of `H`, simulate what that learner's field looks like, and extract what the simulation reveals: candidate intermediate skills, candidate edges, candidate task variants.

The symmetry is exact and the *governance transfers wholesale*: the same `E[ΔH]` selection (§13.1), the same budget/diminishing-returns/breaker stops (§15.3), the same "infinity bounded by information, not enumeration" — you *may* imagine any future endlessly, you only *will* while imagining is expected to change what you do next, and you *stop* when it doesn't. Rumination and daydreaming are the same failure with the same guard.

### 3.2 Vision nodes and backward chaining

A `previsit` that yields a stable target becomes a **vision node**: a skill posited without evidence, entered into the graph with a new status — `hypothesis` — joining `live | pending_human | retired`. Constraints, all forced by existing invariants:

- **RC-3 holds:** a `hypothesis` node has no suite and therefore is excluded from `reachable`, retrieval, clustering, coverage floors, and *every* posterior path — exactly like `pending_human`, but machine-posited and machine-retirable.
- **What it is *for*:** backward chaining. From vision node `H`, induce the candidate prereq path back to the current frontier (the reverse walk MDLP already runs for diagnosis — B2's backward walk — pointed at a hypothesis instead of a failure). The intermediate nodes are the "new learnings not present in the current timeline": each is a *proposed* skill which, when the frontier reaches it, gets provisioned by `provision_suite` like any other candidate — **at which point it either becomes real (suite + verifier ⇒ `live`) or parks (`pending_human`) or the vision retires.**
- **Vision nodes decay.** P2: a `hypothesis` that no pathway approaches within a window retires automatically. No visionary clutter accumulates; the graph cannot fill with dreams.

### 3.3 The branch axis, made honest

The "5th dimension" is a **branch index on projected fields**: `Θ[skill, difficulty | agent, generation, branch]`, where `branch=0` is reality and `branch≥1` are projection sheets. Two honest deflations:

- Branches are **cheap, disposable planning artifacts** — computed during `previsit`, compared (which projected curriculum reaches which vision nodes at what cost), harvested for candidates, then discarded. They are *not* stored parallel worlds; storage follows §15.6's rule — store the generators, materialize only what clears a gate.
- The fleet (§18) is the *physical* version of the same geometry — N real branches. Prospection is the *simulated* version. They compose: a projected pathway can be **assigned to a fleet member to walk for real** — the fleet turns imagination into experiment, which is precisely the paper's "invention as verification" running at curriculum scale.

---

## 4. The safety line — non-negotiable, and it makes the idea gate-compatible

**A projection is a hypothesis generator, never an evidence source.** A simulated outcome must never touch a real posterior — a learner updating its competence on its own imagined successes is the optimizer feeding the measurement, RC-2 in its purest form (the verifier would be trusting the optimizer's imagination). The line, stated as invariants:

1. **Simulated outcomes update no `Θ` cell, ever.** Projection sheets (`branch≥1`) live outside the truth-derived stores; only real runs, through the ordinary §6.1 work-unit lifecycle and §8 gate, write evidence.
2. **The projector is SOLVE-side context; the held-out stays sealed.** Imagining futures may use everything SOLVE may see (P1's `RedactedTruthView` boundary applies unchanged); vision-node suites, when provisioned, come from JUDGE's generator like every suite.
3. **Everything harvested from a branch re-enters through existing doors:** candidate skills through `provision_suite` (RC-3), candidate edges through the structural checks at `merge()` (acyclicity now; ONT-1′ shapes later), candidate curricula through ordinary §5.3 selection. **Projection proposes; reality disposes.** Zero new gate machinery.

Degeneracy: prospection off ⇒ no `previsit` action, no `hypothesis` nodes ⇒ exactly the current spec. Same discipline as the peer-learning note and §18.2 (`test_prospection_off_equals_current`).

---

## 5. Does this give the LLM the jump? — the honest answer

**Partially, and the honest version is stronger than the inflated one.**

What it does deliver: Zahavy's bottleneck decomposed into a **gated pipeline** — *imagination proposes* (`previsit`, LLM-generated futures), *backward design structures* (vision nodes + reverse chaining), *intervention manufactures evidence* (JMP-2 runs the variants for real), *the gate disposes* (§8, on real held-out). The jump stops being a mystical act and becomes a **process with a budget, a stop rule, and a verifier** — which is exactly the paper's own "invention as verification," implemented on MDLP's substrate. H2's blindness is also partially answered: a restructuring with near-zero surprise under the current model can still be *reached* — not by the surprise gate, but by a vision node whose projected downstream reachability justifies the pathway toward it.

What it does not deliver, said plainly: **the projector is still a generative model, so the symbolic-precedent critique recurs one level up** — an LLM imagining futures imagines them out of its training distribution. `previsit` widens the search beyond *the learner's* experience (its failures, its timeline) but not beyond *the projector's* prior. Manipulative abduction in Zahavy's full sense — axioms with no symbolic precedent anywhere — is not achieved; what is achieved is that the learner is no longer bounded by **its own** history. For a learning-pathway algorithm, that is the right claim to make, and it is defensible.

**Where it matters most: human learners.** For code agents, JMP-2's real sandbox is cheap — often you should just *run* the counterfactual rather than imagine it. A human learner cannot be rolled out in parallel, re-run, or A/B-ed against themselves; **simulation is the only counterfactual available.** Prospection is the mechanism by which the Tutor can do backward design for a human — project the student's futures, pick the pathway, walk it forward — which is what good human teachers actually do, and which nothing in §13 currently describes. The idea strengthens the human-origin story of the whole project (it is, after all, an extension of "multi-dimensional" to one more dimension — the counterfactual one).

---

## 6. Risks beyond the safety line

| Risk | Guard |
|---|---|
| **Daydream loops** (projection replacing learning) | §15.3's budget + diminishing returns govern `previsit` identically; projection competes in §5.3 as an ordinary action and never displaces the coverage floor |
| **Vision-node sprawl** | `hypothesis` decay window (P2); a cap on live vision nodes; ONT-7's granularity instrumentation applies to posited skills too |
| **Projector bias steering the curriculum** (the LLM's prior smuggled in as "vision") | visions carry provenance (`posited_by`, projector version, epoch per RAF-3); harvested candidates face the same gates as organic ones; a vision that repeatedly fails provisioning is a *measured* fact about the projector |
| **Confusing sheets with reality** | branch index is structural: `branch≥1` data cannot be written to truth-backed stores by type — not by policy |
| **Wasted spend in cheap-rollout domains** | selection between `previsit` (imagine) and JMP-2 (run it) is itself a §16-style value-of-information choice: simulate when real rollouts are expensive, run when they're cheap |

---

## 7. Proposals

- **VIS-1 — `previsit` as §15's forward twin (§15 delta):** the action type, selected by `E[ΔH]`, governed by §15.3's stops verbatim. Smallest self-contained piece.
- **VIS-2 — vision nodes + backward design (§5.1/graph-schema delta):** `hypothesis` status, reverse chaining via the existing backward walk, decay window, provisioning-on-approach. The genuinely new capability; RC-3-compatible by construction.
- **VIS-3 — branch-indexed projection sheets (design addendum, mostly definitional):** the sheet formalism of §3.3, the type-level write barrier of §6, fleet composition (a projected pathway assignable to a fleet member as a real experiment).
- **VIS-4 — Tutor backward design for human learners (§13 delta, the payoff):** the Tutor projects learner futures and plans pathways backward from target competences — prospection as the mechanism behind what §13 currently leaves implicit in "pluggable pedagogy."

Sequencing note: VIS-1/2 depend on nothing pending; JMP-2 is the natural evidence-manufacturing stage of the pipeline but each stands alone. If pursued, all flow the L-010 gate.

---

*Ungated design sketch. The owner's intuition, formalized: forward projection = `previsit` (episodic future simulation — §15's documented twin in the cognitive literature); "pathways in reverse" = backward design (Wiggins & McTighe), which MDLP lacked; the "5th dimension" = a branch index on the competence field, kept honest as disposable planning sheets behind a type-level write barrier. The safety line — projection proposes, reality disposes — is what makes the whole idea admissible under P1/RC-2/RC-3 without new gate machinery. L-012 unchanged.*
