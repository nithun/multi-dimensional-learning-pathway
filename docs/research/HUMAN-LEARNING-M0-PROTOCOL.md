# C1 — Human-learning Milestone-0 protocol (the go/no-go experiment)

The operational counterpart to [`HUMAN-LEARNING-VERIFIER.md`](HUMAN-LEARNING-VERIFIER.md) (the "what"). This is the "how to test it": a **pre-registered** experiment that answers the human-side go/no-go — *does a reliable, gameable-resistant learning signal exist?* — the same discipline as the agent-side B7. Design only; success criteria fixed before any run.

---

## 1. Purpose

Before building any human-ed app (misconception clustering, prereq-gap, "learners like you"), establish that the **held-out assessment + behavioural-signal verifier** measures *true* learning, rejects teaching-to-the-test, and predicts transfer. If it doesn't, the whole human direction is NO-GO — stop or change domain. (A NO-GO is a publishable result that bounds where the approach applies.)

---

## 2. The measurement model (what feeds the posterior)

### 2.1 Outcome likelihood — IRT-3PL (with a guessing floor)
For learner ability `θ_s` on skill `s` and item `i`:

```
P(correct_i | θ_s) = c_i + (1 − c_i)·σ( a_i (θ_s − b_i) )
```

- `b_i` difficulty · `a_i` discrimination · **`c_i` guessing** (lower asymptote) — `c_i` is what stops a lucky guess from inflating competence (a correct on a high-`c` item is weak evidence).
- Items are **calibrated** (`a,b,c`) on a held-out cohort the learner never trains on.

### 2.2 Behavioural augmentation — the human edge
Each attempt emits a process trace `x = (response_time, hints_used, attempts, error_type)`. Fold it in as an **evidence weight** `w(x) ∈ (0,1]` on the item's contribution to the dual Beta (§3 of v0.2):

```
clean (fast, no hints)        → w ≈ 1     strong mastery evidence
slow / hint-heavy correct     → w small   the hints/time did the work, not mastery
incorrect                     → negative evidence; error_type → misconception (feeds B1)
```

So the Beta update uses **guessing-corrected, behaviourally-weighted pseudo-counts**, not raw pass/fail. The weights `w(·)` are themselves **calibrated** (§14): does "fast+correct" actually predict held-out mastery? — validated empirically, not assumed.

### 2.3 Plug-in (no v0.2 rebuild)
This is the `HumanLearnerAdapter`: IRT + `w(x)` shape the *likelihood* behind the existing `ProbabilisticState`/`EvalHarness` ports. The dual posterior, `significant()`, the gates, info-gain selection, and calibration are inherited unchanged.

---

## 3. The instrument

- **Domain (worked example, swappable):** one well-structured skill cluster — e.g. *solving linear equations* — with ~5–8 sub-skills and a real prerequisite graph.
- **Item bank** per sub-skill × difficulty (~20–30 items), IRT-calibrated on a pilot cohort.
- **Splits:** `public` (may appear in instruction/practice) vs **`held_out`** (assessment only, never shown while teaching) — the generalization gate compares them.
- **Isomorphic variants:** same concept, different surface/numbers — the human analog of the agent counterfactual probe (defeats memorizing the *specific* problem; measures transfer).

---

## 4. Protocol

**Design:** pre-test (held-out) → instruction → post-test (fresh held-out + isomorphic variants) → **delayed** post-test (1–2 weeks; the retention/cramming check). Between-subjects conditions + within-subject competence tracking.

**Conditions / ablations:**
| Condition | Tests |
|---|---|
| **Adaptive loop ON** (Tutor selects items/Teacher by gain) | does held-out competence move *more* than a fixed sequence (H1) |
| **Fixed-sequence control** | the baseline — competence change without adaptation |
| **Teaching-to-the-test probe** (drill the *public* items) | the generalization gate must flag public↑ / held-out-flat (H2) |
| **Outcome-only vs behaviour-augmented posterior** | does `w(x)` predict transfer/retention better (H3) |

**Logged:** every (item, outcome, response_time, hints, attempts, error_type), the predicted `p̂` at decision time (for calibration §14), condition, and timestamps.

---

## 5. Pre-registered hypotheses

- **H1 (signal exists):** held-out competence rises post-instruction beyond `z·SE` — and more under the adaptive loop than the fixed control.
- **H2 (gameable-resistant):** the generalization gate flags the teaching-to-the-test condition (public ↑, held-out flat).
- **H3 (behaviour adds):** behaviour-augmented posteriors predict the held-out + delayed post-test better than outcome-only (lower Brier/ECE).
- **H4 (durable):** gains survive the delayed post-test; the drift posterior + decay catch the crammed condition.
- **H5 (verifier validity):** the assessment estimate predicts **transfer** (isomorphic) and **retention** (delayed) above a threshold — the predictive-validity admission, replacing the (nonexistent) execution oracle.

---

## 6. Metrics

Held-out competence trajectory (primary, on held-out only) · generalization gap (public − held-out) · Brier/ECE of the posterior vs realized · transfer accuracy (isomorphic) · retention (delayed) · predictive validity (estimate→future-held-out correlation) · per-condition effect sizes with CIs over the cohort.

---

## 7. Decision rule (the go/no-go)

- **GO** if **H1 ∧ H2 ∧ H5** hold — the signal exists, resists gaming, and is predictively valid. (H3/H4 strengthen the case but H1/H2/H5 are the gate.)
- **NO-GO** if **H1 fails** (held-out doesn't move) — the signal is too weak; stop the human direction or change domain. *Exactly the agent-side rule: if held-out doesn't move, fix the verifier before building anything.*
- **PARTIAL** (H1 ∧ H2, H5 weak) — the signal exists but reliability is borderline → tighten the instrument (more isomorphic variants, better calibration) before apps.

---

## 8. Confounds & controls

Motivation/fatigue (counterbalance order, attention checks) · practice effects (always-fresh held-out items) · regression to the mean (the fixed-sequence control) · guessing (IRT `c_i`) · calibration leakage (IRT calibrated on a *separate* cohort) · demand effects (blind the condition where possible).

---

## 9. MVP — the smallest viable version

Even smaller than §4: **one sub-skill, ~30 learners**, pre/post held-out + isomorphic variants, full behavioural logging; check **H1 + H2** only. If held-out moves and the gate flags teaching-to-the-test, expand to the full protocol. If not — stop here; that's the cheap NO-GO.

---

## 10. Real-world gates (what this design can't supply)

This is the protocol; running it needs two things only the owner can provide: **(a) a learner cohort** (even ~30 for the MVP) and **(b) the item bank + calibration** for the chosen domain. Everything algorithmic — the measurement model, the gates, the analysis — is specified here and reuses v0.2 §§2–15 unchanged. Pick the domain and the cohort access, and this is runnable.
