# Algorithm integration register

The single source of truth for what the brainstorm sessions surfaced and **where each learning lands in the algorithm.** Consolidates: the 5-store scenarios, bias-free action, the Tutor, faster learning, confidence/calibration, the re-visiting/surprise loop, and the *Source Code* mechanics. Prioritized do-next view: [`NEXT-STEPS.md`](NEXT-STEPS.md). Design: [`ALGORITHM-v0.2-pathway-learner.md`](ALGORITHM-v0.2-pathway-learner.md).

**Legend:** ✅ in v0.2 · 🆕 ready to integrate · 🔭 aspirational (scope decision).

> The whole register compresses to one sentence: **select the next action by information gain, on a calibrated belief, gated by a trustworthy verifier, re-visiting data until the surprise dies — for any learner.** Every 🆕/🔭 below sharpens one clause of that sentence.

---

## A · Selection — the Tutor (decision core)
| Learning | Status | Integration point |
|---|---|---|
| Generic Tutor + pluggable Teachers selected by held-out gain | ✅ | §13 |
| Coverage floor — weak skills never abandoned | ✅ | §3.6 / decision |
| **Info-gain selection** `argmax E[ΔH]` — *bias-free = fastest = exploration are the same action* | 🆕 | §13.1 (deepen) |
| **Warm-start the posterior from "learners like you"** — the cold-start killer (biggest single speed win) | 🆕 | new — `ProbabilisticState` init from vector-similar cohort |
| **Desirable-difficulties scheduling** — interleaving + spacing + testing-effect | 🆕 | new — Tutor scheduling policy |

## B · State / confidence
| Learning | Status | Integration point |
|---|---|---|
| Dual posterior + `n_min` floor + `significant()` | ✅ | §2, §3 |
| Calibration layer — ECE/Brier + isotonic + `n_eff` deflation; miscalibration → breaker | ✅ | §14 |
| **Behavioural-signal likelihood** (response time, hints, attempts → posterior) | 🆕 | C1 / `HumanLearnerAdapter` |
| **Forgetting-aware spacing** — review scheduled off the decay/drift posterior + Redis | 🆕 | new — §3 decay + cache |

## C · Verifier / eval
| Learning | Status | Integration point |
|---|---|---|
| Held-out split + generalization + cumulative gates | ✅ | §4, §8 |
| **Human-learning verifier** — held-out assessment + IRT/guessing + isomorphic variants + predictive-validity admission | 🆕 | `HUMAN-LEARNING-VERIFIER.md` + `HUMAN-LEARNING-M0-PROTOCOL.md` (C1: design + go/no-go protocol) |
| **Negative evidence is information** — a failed eval/loop narrows the candidate space; store the narrowing | 🆕 | §15 *(from Source Code)* |

## D · The learning loop — re-visiting data (the §15 cluster)
| Learning | Status | Integration point |
|---|---|---|
| **Re-derivation as a first-class action** — insight = prediction error (surprise) | 🆕 | §15 |
| **Trigger on expected info-gain** — model moved / new connection / downstream failure / spacing | 🆕 | §15 |
| **Stop on realized gain < threshold** + diminishing-returns floor + per-revisit budget | 🆕 | §15 |
| **Within-episode search (two-level MCTS)** — replay one fixed data point with different actions *(deterministic domains)* | 🆕 | §15 |
| **Loops shorten as you assimilate** — skip predicted parts, spend on the surprising remainder | 🆕 | §15 |
| **Generative-not-enumerative path storage** — store data + versioned state; materialize only high-surprise insights | 🆕 | §15 / stores |

## E · Stores / data architecture (the 5-store as learning levers)
| Learning | Status | Integration point |
|---|---|---|
| **Graph** — prerequisite-aware skipping / adaptive testing (~log N); backward gap diagnosis; realized-path branches | 🆕 | B2 / graph store |
| **Vector** — misconception clustering; similar-learner retrieval; failure clustering | 🆕 | B1 / vector store |
| Truth + versioned state — replayable paths, lineage, immutable-data-with-branching-futures | ✅ | §3, §10 |
| **Redis** — real-time within-session adaptation + the spacing scheduler | 🆕 | cache store |

## F · New capability apps (scenario-level — gated on the verifier)
| App | Status | Note |
|---|---|---|
| **Misconception clustering → graph-linked remediation** (B1) | 🆕 | highest differentiation |
| Prerequisite-gap diagnosis (B2) · "Learners like you" + warm-start (B4) · At-risk prediction + intervention | 🆕 | human-ed; gated on C1 |
| Cross-agent skill transfer / fleet learning (B3) · curriculum → fine-tune data engine | 🆕 | agent-side |

## G · Aspirational / frontier (decide or defer)
| Direction | Status | Note |
|---|---|---|
| Self-modification axis (DGM-style; "exceed your designed scope") | 🔭 | from landscape §7 + Source Code |
| Task/curriculum generator (Absolute-Zero / R-Zero style) | 🔭 | from landscape §7 |
| Learned (meta-RL) Tutor policy — make π itself *learned*, not hand-designed | 🔭 | the survey's named frontier |

---

## What's actually built vs. pending
- **✅ In v0.2 now:** dual-posterior state + `significant()` (§2–3), the eval/gates (§4, §8), the data layer (§10), the **Tutor layer** (§13), the **calibration layer** (§14), the **re-visiting loop** (§15).
- **▣ Gate-approved build-specs** ([`BUILD-SPECS.md`](BUILD-SPECS.md), each cleared review-360 >80 → change-approver APPROVED): info-gain selection (A1, 85), warm-start (A5, 82), forgetting-aware spacing (B4, 82), misconception clustering (B1, 82), prereq-gap diagnosis (B2, 83), fleet transfer (B3, 82). Implementable specs with tests; **not yet code**.
- **🆕 Still design-only (not spec'd):** behavioural likelihood + human verifier (C1 — design + M0 protocol done; **domain chosen: Frappe custom-app dev + ERPNext implementation**, instrument instantiated in [`HUMAN-LEARNING-M0-FRAPPE.md`](HUMAN-LEARNING-M0-FRAPPE.md); awaits a cohort + item bank + assertion suites to run).
- **🔭 Scope decisions:** self-modification, task generation, learned-π — plus **D1, the flagship** (human-ed vs agent vs unified).

## Recommended sequence (from NEXT-STEPS)
**C1** (human verifier go/no-go) → **B1** (misconception clustering, iff C1 passes) → **A1/A5** (info-gain + warm-start, the speed core) → **D1** (flagship, owner's call).
