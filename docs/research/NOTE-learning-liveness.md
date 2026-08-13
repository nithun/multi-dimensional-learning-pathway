# Learning liveness — the heartbeat MDLP doesn't have, and validation that is terminal instead of inductive

**Date:** 2026-08-12 · **Status:** note, ungated. Two related gaps found by asking what §20's heartbeat machinery actually measures.
**Companion to:** `STUDY-ontologies-for-mdlp.md` (the layer cake is the staged pipeline this note says goes unvalidated) and `STUDY-ontologies-and-raft.md` §4 (Raft's inductive-invariant discipline is the model for the fix).

---

## 1. The alarm inventory, read end to end

Every halt/alert condition MDLP has:

| Trigger | Source | Detects |
|---|---|---|
| K consecutive rollbacks | §8 | harm |
| eval-variance spike | §8 | harm |
| production-outcome degradation | §8 | harm |
| near-safety-boundary probing | §8 | harm |
| `ECE_band > τ_cal` miscalibration | §14.3 | harm |
| gate saturation / unattainable target | §19.6 | harm |
| sustained budget-tier deferral | §20.4 | **absence — one cause only** |

Plus §20.6's three liveness signals (process heartbeat, loop-progress heartbeat, last-success stamp), leases, the external freshness watchdog, and the claims rule.

> **Every MDLP alarm detects harm. Exactly one detects absence, and only for a single cause.**

A learner whose process is up, whose loop is advancing, whose work units are completing, and which is **learning nothing** trips none of them.

### 1.1 And no-progress is answered by sleeping, not by alarming

§20.5.3: *"No-progress cycles (no gated commit **and** no new evidence recorded) ⇒ exponential backoff `s_idle·2^k`, capped at `s_idle_max`."*

So a permanently stalled learner backs off to the maximum interval and stays there — all three liveness signals green, the freshness watchdog satisfied (work units *are* completing), the breaker untripped. Worse, §20.7's delivery contract makes this the **quietest** possible state: failures are always delivered and **only success may be suppressed**, and an idle no-progress cycle is not a failure. **The cycles of a stalled learner are precisely the ones eligible for silencing.**

§20.4 shows MDLP already saw this failure — the sustained-deferral alert exists to close *"the 'looks alive, stopped learning' failure where every liveness signal stays green."* It closes it for one cause (a mid-tier budget suppressing growth). **The general case is open**, and the specific case is evidence that it matters.

### 1.2 The progress definition is weaker than it reads

*"No new evidence recorded"* counts **records landing**, not the posterior moving. Evidence can land and teach nothing — items already mastered, failures attributed to existing cells with no significant Δ. A learner can record evidence every cycle forever and never move.

### 1.3 A fix with a side effect: `n_min` masks evidence starvation

§3's `clamp_decay` enforces `n_eff ≥ n_min` so a single eval can never swing `ĉ` by more than `ε` — the correct RC-5 fix. **Side effect:** a cell whose real evidence has dried up is floored at `n_min`, so `ĉ` stays plausible and its SE stays bounded. **A starved cell and a thinly-evidenced cell are indistinguishable downstream**, and nothing watches the floor. Not an argument against the clamp — an argument that the clamp needs an observer.

### 1.4 The sharpest version: MDLP cannot tell "done" from "stuck"

A learner that has mastered everything and a learner that can learn nothing produce **identical** no-progress cycles. MDLP's response to both is to sleep longer.

The distinguisher is cheap and already computable: **zero LP with high competence across the coverage-floor set = converged; zero LP with low competence = stalled.** One is the successful terminal state of a learning system and deserves a report; the other is a failure and deserves an alarm. They currently share a code path.

---

## 2. The proposal — a learning heartbeat, built to §20.6's own discipline

§20.6 requires *"three separate signals, separately written… they fail independently and mean different things,"* and *"every alarm has a test that fires it on synthetic input; a metric read by an alarm but never written anywhere is a build failure."* Apply that same discipline to learning rather than liveness:

| Signal | Measures | Fails when |
|---|---|---|
| **evidence heartbeat** | fresh `n_eff` accrual per cycle; **fraction of live cells sitting at the `n_min` floor** | evidence starves (§1.3) |
| **progress heartbeat** | count of cells with a `significant()` positive LP slope over window `k` | the learner plateaus |
| **structure heartbeat** | skills added / merged / pruned; edges renewed by **intervention** evidence | growth stalls or the graph freezes |

Three signals, separately written, failing independently, each with a fire-test. Then the §1.4 distinguisher on top: **zero progress + high coverage-floor competence ⇒ converged (report); zero progress + low ⇒ stalled (alert, always delivered).**

Deliberately *not* proposed: a new breaker. Stalling is not harm, and halting a stalled learner accomplishes nothing. The right response is **surfacing**, via §20.7's always-delivered class alongside `unknown` attempts and sustained-deferral alerts.

---

## 3. Stage validation — MDLP validates terminally, Raft validates inductively

The §6 loop is `SELECT → EXPAND → EVALUATE → GROW → BACKUP → COMMIT`, and **only COMMIT has a gate.**

The ontology study showed why that is structurally risky: the layer cake is **ordered**, each layer's output feeding the next, so a malformed concept yields a malformed taxonomy yields a malformed axiom. Concretely — if GROW emits a badly-granular skill (the granularity blind spot), nothing checks it at GROW. The error enters the posteriors at BACKUP and surfaces at COMMIT, if at all, as a competence number that is **well-measured and about the wrong object.** By then attribution is gone.

**Raft's model is the opposite and it is the one to copy.** `AppendEntries` carries `(prevLogIndex, prevLogTerm)`; the follower **rejects on mismatch**. Log Matching is not checked at the end — it is *maintained*, at every append. In Ousterhout's words it is *"basically an induction step… once the logs get in sync, this rule guarantees you can't add on to the log without maintaining that synchronization."*

**MDLP already has exactly one instance of this and should generalize it:** B2 Amendment A's union-scoped acyclicity check, enforced at insertion on the `merge()` write path for grown *and* authored edges. That is an inductive invariant. It is the pattern; there is one of it.

Candidate per-stage invariants, each cheap and deterministic:

- **GROW** — every emitted node carries a `provision_suite`-assigned status (already asserted by `test_merge_never_assigns_liveness`); cluster size within the granularity envelope; no edge violating the type's meta-property constraints (ONT-3).
- **BACKUP** — every posterior update references a `work_unit_opened` row (already enforced by §6.1's `rejected_reason` path) and its evidence id is unconsumed.
- **EVALUATE** — the bound verifier is the strictest applicable one (§4.3 states it; is it checked?).
- **SELECT** — the chosen action's cell is soft-reachable and inside the coverage-floor allocation.

The claim is not that each of these is missing — several are enforced. **The claim is that there is no stated discipline that every stage's output is validated before the next stage consumes it**, so which ones exist is a matter of which review round happened to catch them. That is the same reactive-constraint pattern the ontology study found in the graph vocabulary, now visible in the loop itself.

---

## 4. Two open questions

- **Is learner band progression gated?** §4.3 re-checks *verifier* admission as the agent enters a new difficulty band ("admission is continuous, not one-shot") — the verifier side is covered. Whether the *learner's* readiness to be selected into a harder band is itself validated, or simply emerges from §5.3's selection over `(s,d)` cells, is not stated either way. Worth resolving rather than assuming.
- **Do the participant-level heartbeats feed peer eligibility?** In `NOTE-peer-learning-roles.md`, a stalled participant is still eligible to teach on its stale posterior. A per-participant progress heartbeat is the natural input to eligibility, and T5's epoch stamping is the other half.

---

## 5. Proposals

- **LIV-1 — learning heartbeat (§20.6 delta):** three signals, separately written, each with a fire-test, plus the converged-vs-stalled distinguisher routed to §20.7's always-delivered class. Directly generalizes §20.4's sustained-deferral alert from one cause to the general case.
- **LIV-2 — `n_eff`-floor observability (§3/§20 delta):** report the fraction of live cells pinned at `n_min`. Cheap; closes the §1.3 mask.
- **LIV-3 — state the staged-validation discipline (§6 delta):** every loop stage validates its output before the next consumes it, in the manner of B2 Amendment A's insertion-time acyclicity check. Then audit which stages currently do.

---

*Ungated. Nothing here is a spec delta; if pursued it flows the L-010 gate. The alarm inventory in §1 was read from ALGORITHM §8/§14.3/§19.6/§20 directly, not recalled.*
