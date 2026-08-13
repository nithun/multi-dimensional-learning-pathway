# "LLMs can't jump" study — what abduction says about MDLP's growth function

**Date:** 2026-08-13 · **Subject:** Tom Zahavy (Google DeepMind), *Position: LLMs can't jump*, **ICML 2026 Position Paper Track, accepted** (OpenReview `klU4737opt`; author PDF Jan 27 2026 read in full, 9 pp; full review thread read — ratings 4/5/5 after rebuttal).
**Status:** study document — ungated. Proposals flow the L-010 gate.
**Source class, stated up front:** a **position paper**, not an empirical result. The strongest claim was contested in review — reviewer Ldv4 forced "our analysis **confirms**" down to "**suggests**," and public rebuttals exist (e.g. "Hot Take: LLM can jump"). Everything below treats the paper as an *argument with a taxonomy*, not as evidence. Its value to MDLP survives that grading, because the taxonomy alone reclassifies MDLP's mechanisms in a useful way — and one of its arguments lands a direct hit on an approved section's premise.

---

## 1. The paper in brief

**Frame.** Einstein's letter to Solovine sketches discovery as a cycle (Fig. 1 of the paper): **Sense Experience (E) → Jump (J) → Axioms (A) → deduced theorems (S, S′) → experiments → E.** The paper adopts Peirce's inference taxonomy, stated as permutations of Rule / Case / Result:

- **Deduction** (Rule + Case → Result) — analytic; the only mode that guarantees truth. *LLMs are rapidly conquering it* (AlphaProof silver, gold-level 2025 systems, Lean/mathlib).
- **Induction** (Case + Result → Rule) — statistical generalization. *Mastered* (that's what training is).
- **Abduction** (Rule + Result → Case, or a new Rule to explain a surprising Result) — inference to the best explanation. Split further, after Magnani: **selective** abduction (choose among existing candidate explanations) vs **manipulative** abduction (generate axioms *without symbolic precedent*, via embodied simulation — "thinking by doing").

**Case study.** The GR reconstruction (via Norton's phases): the 1907 "happiest thought" (a falling observer feels no field) was a **simulated sensory experience**, not a datum; Newtonian gravity had **no empirical crisis** (equivalence verified to 10⁻⁹; the one anomaly, Mercury's perihelion, was attributed to a hidden planet, *Vulcan*); therefore "creativity as compression" (Schmidhuber) fails here — **"without a significant discrepancy between prediction and observation, there is no gradient to drive the system toward a foundational restructuring."** An inductive engine "would prefer to patch Newtonian gravity with a parameter like the Vulcan hypothesis rather than expanding the hypothesis space." Deduction is real but **downstream** — "a verification step within the invention loop, not the mechanism of invention" (1913–15 was deductive grind; the axioms came from the jump). The 1913 *Entwurf* failure: "the derivation failed not because the logic was flawed, but because the axioms were incorrect."
**Proposal (their §4/§6).** Action-controllable world models (Genie-class, vs passive Veo-class prediction) as a "synthetic laboratory": **counterfactual intervention** (Pearl) — "an AI cannot merely watch a video of an elevator; it must possess the capacity … to conceptually cut the cable." "Invention as verification": conjecture in language, test against internal physical priors, **bypassing external experimental data** that may not arrive for decades. Plus a closing note the rest of the paper is often read without: **the substrate is discipline-specific** — "for physics, the substrate is the world; for mathematics, it is the abstract landscape of formal systems."

---

## 2. The Peirce mapping — MDLP's loop, reclassified

Running MDLP's §6 loop through the taxonomy is clarifying, because MDLP has all three modes and has never named them:

| Peirce mode | MDLP mechanism |
|---|---|
| **Induction** | §3 posterior updates; §14 calibration; every Beta cell — Case+Result→Rule, literally |
| **Deduction** | §8/§19 gate evaluation; §16 retrieval sharpening `Q`; §5.2 reachability products — consequences of current structure |
| **Abduction** | **`g.step` (§5.1)**: a surprising Result (failure cluster) → posit a new Rule (a skill that explains the failures). §15's "insight is a prediction error" is the abductive **trigger**, formalized |

And the EJASE cycle **is** MDLP's loop: E = episode outcomes → J = growth `g` → A = the skill graph (the learner's axiom system) → S,S′ = curriculum decisions and predictions → experiments = held-out evals → E. That makes the paper's question precise for MDLP: **what kind of abduction is `g`?**

**Answer: selective, bounded by symbolic precedent.** `g` clusters *observed* failure embeddings; a new skill is born only when `similarity(cluster, nearest_admitted) < τ_new` — i.e. the hypothesis space is spanned by what has already been experienced and embedded. **MDLP cannot posit a skill for which no failure trace exists.** That is precisely the paper's "bounded by the existing symbolic space" critique, applied not to an LLM's vocabulary but to an embedding space of traces. MDLP's growth is real abduction — but it is the *selective* kind, and the spec has never had the vocabulary to say so.

---

## 3. Three hits on MDLP, graded

### H1 — The no-error-signal argument names a third liveness state *(strong; extends NOTE-learning-liveness)*

`NOTE-learning-liveness.md` §1.4 distinguished **done** (zero LP, high competence) from **stuck** (zero LP, low competence). The paper says there is a third state, and it is the interesting one: **converged-within-paradigm** — every posterior at ceiling, no failures, hence no clusters, hence no growth, *while the schema itself is wrong or incomplete*. Newton-in-1900 is the picture: 10⁻⁹ precision, one tiny anomaly, absorbed by a hypothesized hidden planet.

And MDLP has a specific mechanism that enacts the Vulcan move: **`coherent_with` absorption** (§5.1) attributes a failure to an existing skill cell when it is coherent with that cell's success items. RC-4 named wrong-cell absorption as a defect and bounded it — but the bound is similarity-based, so a *systematically anomalous* trace that is nonetheless coherent with an existing cell keeps being absorbed, exactly as perihelion data kept being "explained" by Vulcan. The residue MDLP would never see: **a cell whose failures are individually absorbable but collectively patterned.** Nothing watches for that pattern; the anomaly never reaches `F`, so growth never sees it.

*What this yields:* LIV-1's distinguisher should be **three-state** (stalled / converged / **converged-with-absorbed-anomaly-pattern**), and the third needs its own cheap signal — e.g. per-cell absorbed-failure rate and its trend, which TruthStore already records enough to compute. Not a breaker; a surfacing.

### H2 — A direct challenge to §15's premise *(the sharpest single hit; honest limitation, not a defect)*

§15's core: *"an insight is a prediction error … it decays to zero as you assimilate."* §13.1's diagnose mode: `A* = argmax E[ΔH]`. Both are **computed under the current model**. The paper's Einstein case is a counterexample class: the restructuring with the highest eventual value carried **near-zero expected surprise under the reigning model** — Newtonian mechanics predicted almost everything, so any surprise-gated revisit policy would have deprioritized exactly the data that mattered.

Stated precisely: **`E[ΔH | D, state]` values information within the current hypothesis space; a restructuring changes the space, and its value is undefined under the measure the Tutor maximizes.** Growth `g` partially escapes (it extends the space) — but only when driven by failures, which is H1's limit again.

This does **not** break §15 — for within-schema learning the surprise gate is right, and MDLP's domain (agent skills, not physics paradigms) may rarely need more. But it is a real, citable boundary of the objective, and `PAPER.md` should state it *as scope* rather than have a reviewer state it as a gap: **MDLP optimizes within-schema learning and evidence-driven schema extension; evidence-free restructuring is out of scope, and Zahavy 2026 is the argument for why that is a distinct, unsolved capability.** Position-paper support is exactly the right strength for a scope claim.

### H3 — Manipulative abduction has an MDLP analog, and MDLP's domain makes it cheaper than the paper thinks *(the constructive one)*

The paper's cure — an action-controllable world model as a synthetic laboratory for counterfactual intervention — sounds like heavy infrastructure. Two observations shrink it for MDLP:

1. **In MDLP's domain the world model is exact and already present.** The paper's closing paragraph concedes the substrate is discipline-specific: for physics it's the world; for mathematics, formal systems. For **coding agents, the runtime and test harness are a perfectly consistent, fully action-controllable simulator** — the thing the paper says is the hard missing piece is, in MDLP's domain, `pytest`. §15.4 already names replayable episodes and within-episode search (two-level MCTS) for exactly this class of domain. The "synthetic laboratory" is not future work here; it is the eval harness read through a different lens.

2. **The counterfactual machinery already exists — on the wrong side of the wall for this purpose.** §4.2's verifier injects *fresh counterfactual variants* to defeat hard-coded answers; §8's deployment loop samples variations into the held-out suite. That is counterfactual **verification** (JUDGE-side, anti-gaming). The paper's "simulation as physical variation" — citing test-time RL, AlphaProof's problem-variation, and (notably) Zahavy's own creative-chess work — is the same operation used for **invention**: generate task variants the learner has never failed at, *run* them, and let the outcomes seed `F` with failures that organic experience would not have produced. That is a growth mechanism for skills **without prior failure traces** — manipulative abduction's MDLP-sized analog: not "axioms from sensation," but **evidence manufactured by intervention rather than waited for.**

The safety shape is already known: the variant generator on the SOLVE-visible side must be distinct from the held-out generator (P1 — the JUDGE's item synthesis stays sealed), outcomes flow through the ordinary §8 gate, and the budget competes in §5.3 like any action. Degeneracy: generator off ⇒ exactly current §5.1.

---

## 4. Where MDLP is *stronger* than the paper's subjects — worth claiming

- **MDLP's symbols are grounded in execution.** The paper's "Chinese room" critique — symbols with no access to referents — does not apply to a skill whose *extension is an executable suite*: a skill's meaning in MDLP is checkable against the runtime, which is the domain's world. The symbol-grounding problem (Harnad) is solved in MDLP's domain by construction, for the same reason verification is cheap in it.
- **"Invention as verification" is MDLP's architecture already.** Conjecture (growth posits a skill) → immediate internal test (provision a suite, run it) → gate. The paper proposes as a future capability the shape MDLP has as its core loop; the difference is only *where hypotheses come from* (H3).
- **The paper's subjects don't measure; MDLP does.** AI Scientist and AlphaEvolve are critiqued for optimizing within fixed frameworks on existing gradients. MDLP's distinctive contribution — statistical gates on held-out competence — is orthogonal to the abduction gap and unaddressed by every system the paper surveys. The fourth confirmation of the landscape claim, from a source arguing a different point.

---

## 5. What not to take

- **World-model infrastructure** (Genie-class latent physics manifolds). Wrong domain; MDLP's simulator is the runtime (H3.1).
- **The strong ontological claim** ("structurally incapable"). Contested in review, softened by the authors themselves, publicly rebutted. MDLP should cite the taxonomy and the no-error-signal argument, never the impossibility claim.
- **Embodiment as a requirement.** The paper's own final paragraph undercuts it for non-physical domains; MDLP's domain is non-physical.
- **A new "abduction axis."** MDLP does not need a fourth learning axis; it needs (a) the third liveness state named (H1), (b) the scope boundary stated (H2), and (c) one exploration mechanism (H3). L-003 discipline: no momentum-building.

---

## 6. Proposals — each gated before touching a gated artifact

- **JMP-1 — three-state liveness distinguisher (extends LIV-1, NOTE-learning-liveness):** stalled / converged / converged-with-absorbed-anomaly-pattern; the third watched via per-cell absorbed-failure rate + trend over the coverage-floor set. Surfacing, not a breaker.
- **JMP-2 — counterfactual variation as a growth mechanism (§5.1/§5.3 delta, research-grade):** a SOLVE-visible variant generator, distinct from JUDGE's item synthesis (P1), whose run outcomes seed `F`; budgeted as an ordinary action; generator-off degeneracy to current §5.1. This is the paper's "simulation as physical variation" landed on MDLP's exact substrate.
- **JMP-3 — scope statement for `PAPER.md`:** MDLP optimizes within-schema learning + evidence-driven schema extension; evidence-free restructuring (manipulative abduction) is explicitly out of scope, with Zahavy 2026 as the boundary argument and H3.1 (exact world models in code domains) as the reason the boundary is softer for MDLP's domain than for physics. Also add the Peirce naming to the loop description — induction/deduction/abduction locate `g` precisely and cost one paragraph.

---

*Provenance: author-hosted PDF read in full (9 pp, Jan 27 2026 version — the ICML camera-ready adds an Archimedes example, a softened conclusion, and an expanded alternative-views section, all known from the review thread); OpenReview forum read in full (decision + 3 reviews + all rebuttals; final ratings 4/5/5); the concurrent neuro-symbolic abduction system the authors cite in rebuttal (arXiv 2509.23004) noted but not read. The Peirce/EJASE mapping onto §6, the Vulcan ≙ `coherent_with`-absorption identification, the §15 boundary argument, and all three proposals are ours. Fetch path for the record: OpenReview PDF is Cloudflare-challenged for tools; the browser pane passed verification and the forum page supplied the review thread; the paper body came from the author's site. Nothing gated touched; L-012 unchanged.*
