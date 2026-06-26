# C1 — The human-learning verifier

**The human-side Milestone-0.** MDLP is verifier-grounded: for agents the verifier is execution / schema / task-success (cheap, reliable). For a *human* learner, what plays that role — and is it reliable enough to learn on? This gates every human-ed scenario (misconception clustering, prerequisite-gap diagnosis, "learners like you"). Design only.

Companion: `ALGORITHM-v0.2-pathway-learner.md` §13 (`HumanLearnerAdapter`); the **go/no-go experiment**: [`HUMAN-LEARNING-M0-PROTOCOL.md`](HUMAN-LEARNING-M0-PROTOCOL.md); `NEXT-STEPS.md` (C1).

---

## 1. The core insight — the agent machinery transfers almost verbatim

The human verifier is **held-out assessment**, and MDLP's existing discipline maps over with almost no change:

| Agent mechanism (v0.2) | Human-learning analog |
|---|---|
| public vs **held-out** item split (§4) | practice/instruction items vs **held-out assessment** items the learner never saw during teaching |
| **generalization gate** `Δheld-out ≥ ρ·Δpublic` (§8) | rejects **teaching-to-the-test** — public scores rise, held-out doesn't |
| **counterfactual variant** probe (§4) | an **isomorphic item** (same concept, different surface/numbers) — defeats memorizing the specific problem |
| dual Beta posterior + `n_min` floor + `significant()` (§3) | a single assessment item is a noisy Bernoulli; you accumulate evidence with uncertainty, never trust one item |
| **decay `γ`** + drift posterior (§3, §7) | catches **cramming** — a transient gain that doesn't stick shows as drift down; durable learning survives the decay |
| verifier **admission** by predictive reliability (§4) | admit an assessment instrument only if it **predicts held-out transfer** above a bar (below) |

So the held-out split, the posterior, and the gates are **not agent-specific** — they are exactly the tools you need for noisy human assessment. That's the keystone: the human verifier is the same verifier, fed by assessment instead of execution.

---

## 2. What the human verifier *is* — three layers

### 2.1 Held-out assessment (the outcome signal)
A versioned item bank per skill, split into a **public** set (may appear during instruction) and a **held-out** set (drives the competence posterior, never shown while teaching). Items are **IRT-calibrated**: model `P(correct | ability θ, item)` with difficulty/discrimination and — critically — a **guessing** parameter (3-PL), so "right by luck" doesn't inflate competence. This is the human analog of the trajectory-shape/counterfactual checks: the guessing parameter and the isomorphic-variant probe together do what "derived-from-query + counterfactual" do for agents.

### 2.2 Behavioural-signal likelihood (the human *advantage*)
Agents have a clean outcome oracle but no rich process trace. Humans are the opposite — assessment is noisy, but every attempt emits **process signals**: response time, hesitation, hints used, number of attempts, partial/scratch work, self-explanation, error *type*. Fold these into the likelihood, not just correct/incorrect:

```
P( correct, response_time, hints_used, attempts | competence, item )
```

- fast + correct → strong mastery evidence; slow + correct → effortful, lower-confidence mastery;
- correct only after 3 hints → not yet mastered (the hints did the work);
- a *characteristic* error type → evidence for a specific misconception (feeds B1).

These tighten or widen the **same posterior** — they don't replace the outcome, they refine it. This is the human side's genuine edge over the agent side.

> Caveat: behavioural signals are confounded (slow = careful *or* distracted; fast = fluent *or* guessing). Weight them as **soft evidence with their own reliability**, never as ground truth — exactly how MDLP treats a soft verifier.

### 2.3 Reliability / admission — predictive validity (no execution oracle)
For agents, a verifier is admitted if its precision lower-CI ≥ ρ_min against a human audit set. Humans have **no execution oracle and no ground-truth "true competence"** to check against — this is the genuinely harder part. Replace the audit set with **predictive validity**: an assessment instrument is *admitted* for a skill band only if its held-out estimate **predicts future held-out / transfer performance** above a threshold (calibrated against a cohort, with a confidence interval). Reliability of a human verifier = how well it forecasts the next held-out outcome, not how well it matches an oracle that doesn't exist.

---

## 3. The gaming analogs — and why existing machinery catches them

| Human Goodhart | Defence (already in v0.2) |
|---|---|
| **Teaching-to-the-test** (public ↑, understanding flat) | generalization gate (§8) — reward only the held-out delta |
| **Memorizing the specific problem** | isomorphic-variant probe (§2.1) — same concept, new surface |
| **Guessing / luck** | IRT guessing parameter + accumulate-with-uncertainty (never trust one item) |
| **Cramming** (transient spike) | decay `γ` + drift posterior — gains that don't survive spaced re-assessment age out |
| **Gaming the hint system** | behavioural likelihood (§2.2) — hint-heavy "correct" counts as weak evidence |

The mapping is striking: the same hardening that defeats the agent pilot-killers defeats the human ones.

---

## 4. What is genuinely *harder* than agents (be honest)

1. **Latent, not observable.** Agent competence is observed (run the eval); human competence is *latent* and only inferred — so the inference model (IRT/BKT) does real, load-bearing work, and is itself a source of error.
2. **No deterministic oracle.** You cannot "run the human and check the answer." Assessment is the only window and it's indirect.
3. **Data is sparse and expensive.** A human spends minutes per item; an agent runs thousands of evals. The per-learner posterior stays **wide** → which makes the **§13.1 information-gain selection essential**: with little data, the Tutor must pick the *most diagnostic* item, not the most "advancing" one. The bias-free principle isn't optional here; it's forced by data scarcity.
4. **Confounds.** Motivation, fatigue, anxiety move performance independently of competence — nuisance variables to model or control for, absent in the agent case.
5. **Stakes & ethics.** A wrong competence estimate has real human cost (frustration, misplacement). Reversibility and calibration matter differently than for an agent checkpoint.

---

## 5. The go / no-go (mirrors the agent side)

**Human learning is tractable for MDLP exactly where a reliable held-out assessment + isomorphic variants can be built** — checkable-answer domains: math, programming, languages, factual recall, structured STEM problem-solving. **It is NOT tractable where competence is subjective/open-ended** — essay quality, creativity, soft skills — the same soft-judge trap as agents (an LLM/human grader is a gameable, low-reliability verifier there).

So the human-side GO-condition is the agent-side one, restated: **verifiable domains first; defer the open-ended.** And the first build should be the human analog of agent Milestone-0 — a fixed skill, an IRT-calibrated held-out bank with isomorphic variants, and a check that **held-out competence moves with instruction while the generalization gate rejects teaching-to-the-test** — *before* any of the scenario apps (B1/B2/B4).

---

## 6. Integration with v0.2 / §13

`HumanLearnerAdapter` exposes:
- `posterior(skill)` — the §3.2 dual Beta, updated by the **behavioural-signal likelihood** (§2.2), not a bare pass/fail;
- `verify(skill) → held-out outcome` — IRT-scored held-out items + isomorphic variants (§2.1), admitted by predictive validity (§2.3);
- everything else (held-out split, generalization/cumulative gates, decay, the Tutor's info-gain selection) is inherited from §1–§13 **unchanged**.

The only new machinery is the **IRT/behavioural likelihood** and the **predictive-validity admission** — both swap in behind the existing `ProbabilisticState` / `EvalHarness` ports.

---

## 7. Open questions & the smallest experiment

- **The audit problem:** without an oracle, how well does predictive validity (§2.3) actually gate bad assessments? Needs a cohort study (does the held-out estimate forecast transfer?).
- **How much do behavioural signals really add** over outcome-only, per domain? (Likely large for procedural skills, small for recall.)
- **Smallest experiment (human Milestone-0):** one well-structured skill (e.g. a unit of algebra), a public/held-out item bank with isomorphic variants, a small cohort; show held-out competence rises with instruction, the generalization gate flags a teaching-to-the-test condition, and behavioural-signal-augmented posteriors predict transfer better than outcome-only. If held-out doesn't move — stop and fix the assessment, exactly as on the agent side.
