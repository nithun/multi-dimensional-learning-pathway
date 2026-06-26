# C1 (Frappe / ERPNext) — Milestone-0 domain instantiation

The concrete domain for the C1 go/no-go. Takes the generic protocol ([`HUMAN-LEARNING-M0-PROTOCOL.md`](HUMAN-LEARNING-M0-PROTOCOL.md), the "how") and the verifier design ([`HUMAN-LEARNING-VERIFIER.md`](HUMAN-LEARNING-VERIFIER.md), the "what") and binds them to **Frappe custom app development + ERPNext implementation** — a learner cohort of onboarding developers / implementation consultants. Design only; the cohort + item bank are the owner-supplied real-world gates (§9).

> **Why this domain de-risks C1:** the work product is *code and configuration you can run*. The single hardest problem in the human verifier (`VERIFIER.md` §4 — "human competence is latent, there is no deterministic oracle") is **largely lifted here**: a learner's DocType, server script, or ERPNext config can be installed on a fresh site and asserted against, exactly like an agent eval. Frappe/ERPNext sits at the **GO end** of the C1 tractability spectrum — the verifiable-domain ideal — *except* for one consulting layer we deliberately defer (§2).

---

## 1. The verifiability win — this domain has a near-agent-grade oracle

`VERIFIER.md` §4 lists five things that make human learning harder than agent learning. Three of them shrink dramatically here:

| §4 "harder than agents" challenge | Status in Frappe/ERPNext |
|---|---|
| **No deterministic oracle** — "you cannot run the human and check the answer" | **Largely lifted.** You can run their *artifact*: install the app, introspect the DocType schema, post the document, assert the side effects. The oracle is `frappe.get_doc` / the GL Entry / the Stock Ledger — the same execution/schema/task-success verifier MDLP uses for agents. |
| **Guessing inflates competence** (the IRT `c_i` problem) | **Near-zero `c_i`.** You cannot accidentally build a correct DocType with a child table, a naming series, and a working `validate` hook. Build tasks have `c_i ≈ 0`, so IRT-3PL collapses toward 2PL and the per-item signal is cleaner than any MCQ domain. |
| **Latent, only inferred** | **Partly lifted.** Competence (will they build the *next* one right?) is still latent — but each item's outcome is a strong, sub-component-checkable observation, not a noisy single bit. |
| Data sparse & expensive | **Unchanged** — still minutes per item; per-learner posterior stays wide → §13.1 info-gain selection still essential. |
| Confounds (motivation/fatigue) | **Unchanged** — model/control as in the generic protocol §8. |

**Implication:** for this domain the verifier does *not* lean on the weak predictive-validity-only admission (`VERIFIER.md` §2.3). It uses a real execution oracle at the item level and accumulates held-out outcomes into the dual posterior — the strongest version of C1, and the one most likely to return **GO**.

---

## 2. Scope — two tracks, one triage

The user named two things; they are different skills with different cohorts, so we triage them by verifiability and target the verifiable core in M0.

**Track A — Frappe custom app development** (a developer cohort). Almost entirely code → strong oracle.
**Track B — ERPNext implementation** (a consultant cohort). Mixed: configuration with checkable outcomes *plus* an open-ended consulting layer.

| Sub-skill | Oracle | C1 disposition |
|---|---|---|
| **A. DocType modeling** (fields, types, child tables, links, naming) | schema introspection | **GO — M0 MVP** |
| **A. Server controller logic** (`validate`/lifecycle hooks, `frappe.db`) | run lifecycle, assert side effects | GO |
| **A. Client form scripting** (`frappe.ui.form.on`, `frm` API) | headless form events / DOM assert | GO |
| **A. Whitelisted API** (`@frappe.whitelist`, `frappe.call`) | call endpoint, assert response | GO |
| **A. Permissions** (role perms, permission queries) | assert role can/can't access | GO |
| **A. `hooks.py`** (doc_events, scheduler, overrides) | trigger event, assert effect | GO |
| **B. Transactional config** (post Sales Invoice → correct GL + stock) | assert GL Entry / Stock Ledger Entry | GO |
| **B. Workflow setup** (states/transitions/roles) | drive transitions, assert state | GO (mechanics) |
| **B. Report Builder / dashboards** | assert query output | partial (output checkable, design judged) |
| **B. Requirements gathering / process mapping** ("is this the *right* model for the client?") | — subjective — | **DEFER (NO-GO surface)** |
| **B. Solution architecture trade-offs** (custom app vs config) | — judgment — | **DEFER** |
| **B. Client communication / training delivery** | — soft skill — | **DEFER** |

This is the C1 GO-condition made concrete (`VERIFIER.md` §5): **verifiable sub-skills first, defer the open-ended.** The deferred row is not a failure — it is the same soft-judge trap as agent open-ended tasks, and bounding where MDLP applies *is* the milestone's job.

---

## 3. The sub-skill prerequisite graph (Track A — the M0 spine)

Eight nodes, a real DAG (the protocol asks for ~5–8 sub-skills with genuine prerequisites):

```
(1) bench / app scaffolding        bench new-app, app structure, install, migrate
        │
        ▼
(2) DocType modeling  ◀────────────  ← M0 MVP single sub-skill
        │   fields, field types, child tables, Link, naming series, reqd/unique
        ├──────────────┬───────────────┬───────────────┐
        ▼              ▼               ▼               ▼
(3) Links &      (4) Server      (5) Client       (7) Permissions
   relationships     controller       form script      role perms,
   Link/Dynamic      validate/         form.on,         perm query
   Link, fetch       on_submit,        frm API
        │            frappe.db             │
        └──────┬───────┴──────────────────┘
               ▼
        (6) Whitelisted API  @frappe.whitelist + frappe.call wiring
               │
               ▼
        (8) hooks.py  doc_events, scheduler_events, overrides
```

This graph is exactly what **B2 (prereq-gap diagnosis)** walks backward over, and the failure clusters at each node are what **B1 (misconception clustering)** names — so a successful C1 here directly unblocks the highest-differentiation human-ed apps on a domain we control.

---

## 4. The instrument

- **MVP sub-skill: DocType modeling** (node 2) — foundational, the cleanest schema oracle, the richest isomorphic-variant space.
- **Item = a build spec.** e.g. *"Create a DocType `Asset Maintenance Log`: a Date `maintenance_date` (reqd), a Link `asset` → Asset, a child table `parts_replaced` → `Maintenance Part Item`, a Select `status` with options Draft/Done/Cancelled, naming series `AML-.YYYY.-`."* The learner builds it; the verifier asserts the resulting schema.
- **Public vs held-out split.** Public specs may be used in instruction/practice; **held-out specs** (fresh entities, never taught on) drive the competence posterior. The generalization gate (§8 of v0.2) compares them — drilling the public specs must not move held-out.
- **Isomorphic variants** (the counterfactual probe). Same competence — *fields, types, child table, Link, naming, Select* — different surface: `Library Loan` ↔ `Equipment Checkout` ↔ `Lab Sample Log`. Memorizing one spec does not transfer; the underlying skill does. Defeats the real Goodhart here: **copy-paste from a past project / the docs**.

---

## 5. The verifier — execution-based assessment (`verify(skill)`)

The headline mechanism, and why this domain is special. `HumanLearnerAdapter.verify(skill)` for Track A is an **automated harness**, not a human grader:

1. Spin up / reset a scratch Frappe site (or introspect in a sandboxed bench).
2. Install the learner's app / import the built DocType.
3. Run an **assertion suite** per held-out item:
   - **schema assertions** — field exists, correct `fieldtype`, `reqd`/`unique` flags, child-table `options` points to the right doctype, `autoname` matches the series;
   - **behavioral assertions** — `frappe.new_doc(...)` with a violating value is rejected by `validate`; a valid doc submits; `on_submit` produces the expected linked records.
4. Each assertion is a sub-component outcome → a **partial-credit vector**, not one bit. This is what makes the per-item signal far richer than answer-checking.

Because the oracle is real, the dual posterior is fed clean, guessing-resistant evidence; `significant()`, the held-out/generalization/cumulative gates, info-gain selection, and §14 calibration are all **inherited unchanged** (`VERIFIER.md` §6). The only domain code is the assertion suites.

**Track B transactional analog:** *"Configure ERPNext so posting a Sales Invoice for Item X to Customer Y (tax template T, warehouse W) yields GL entries A/B/C and decrements Bin(W,X)."* Verifier asserts the GL Entry + Stock Ledger Entry rows. Isomorphic variants vary item/customer/tax/warehouse. Same oracle-grade check.

---

## 6. Behavioural signals — the human edge, instantiated

Each attempt emits a process trace (`PROTOCOL.md` §2.2); folded in as an evidence weight `w(x) ∈ (0,1]`, calibrated, not assumed:

| Signal (Frappe/ERPNext) | Reading |
|---|---|
| time-to-working-build | fast+correct → `w≈1` strong mastery; slow+correct → effortful, lower-confidence |
| docs / forum lookups, AI-assistant calls | the hint analog — heavy lookup + correct → the docs did the work, `w` small |
| `bench migrate` / install failures before success | attempts → effortful path |
| UI form-builder vs hand-written JSON / fixtures | process evidence (not better/worse, but diagnostic of understanding) |

**Characteristic error types → misconceptions (feeds B1):** `Data` field where a `Link` is needed · child table whose `options` points at the parent not the row doctype · missing `reqd` on a business-critical field · `naming_rule` unset / wrong series format · `on_submit` logic placed in `validate` (fires too early) · permission given to the wrong role level. Each recurring error trace is a candidate named misconception — the B1 pipeline on a domain with a clean oracle to confirm the lift.

---

## 7. The MVP — smallest viable go/no-go

Per `PROTOCOL.md` §9, even smaller than the full protocol:

- **One sub-skill:** DocType modeling.
- **Cohort:** ~30 onboarding developers (a realistic services-team intake).
- **Design:** pre-test (held-out specs) → instruction → post-test (fresh held-out + isomorphic variants) → delayed post-test (1–2 wks).
- **Conditions:** adaptive loop ON vs fixed-sequence control; plus a **teaching-to-the-test probe** (drill the exact public specs).
- **Check H1 + H2 only:** does held-out build-competence rise post-instruction beyond `z·SE` (signal exists), and does the generalization gate flag the teaching-to-the-test arm (public↑ / held-out flat)?
- **Outcome:** held-out moves + the gate flags drilling → **expand** to the full 8-node protocol and Track B. Held-out flat → **stop**; the cheap NO-GO (and on a domain this verifiable, a NO-GO would itself be a strong negative result).

---

## 8. Pre-registered hypotheses (inherited, instantiated)

- **H1 (signal):** held-out DocType-build competence rises post-instruction beyond `z·SE`, more under the adaptive loop than the fixed control.
- **H2 (gameable-resistant):** the generalization gate flags the drill-the-public-specs arm (public↑, held-out flat). The domain-specific gaming vector — copy-paste from a past app — is defeated by held-out fresh entities + isomorphic variants.
- **H3 (behaviour adds):** lookup-/time-weighted posteriors predict held-out + delayed transfer better (lower Brier/ECE) than outcome-only.
- **H4 (durable):** gains survive the delayed post-test; the drift posterior + decay catch a "crammed the night before" learner.
- **H5 (validity):** the assessment estimate predicts transfer (isomorphic specs) and retention (delayed) above threshold.
- **Decision rule (unchanged):** **GO** iff H1 ∧ H2 ∧ H5; **NO-GO** if H1 fails; **PARTIAL** if H1 ∧ H2 but H5 weak.

---

## 9. What's specified vs. owner-supplied

- **Fully specified now (algorithmic + domain design):** the sub-skill graph, the verifiability triage, the item form, the public/held-out split, the isomorphic-variant scheme, the **execution-based verifier harness design**, the behavioural weights, the misconception error taxonomy, the protocol, hypotheses, and decision rule — all reusing v0.2 §§2–15 unchanged.
- **Owner must supply (real-world gates):**
  1. a **cohort** (~30 onboarding devs for the MVP);
  2. the **item bank** — authored build specs per sub-skill × difficulty, IRT-calibrated on a pilot;
  3. the **assertion suites** — the per-item schema/behavioral checks the verifier runs (one-time engineering, reusable, and the highest-leverage build because it *is* the oracle).

Item 3 is the domain-specific engineering investment — but it is ordinary Frappe test code (`frappe.tests` / `bench run-tests` style assertions), well within the cohort's own skill set, and it converts the otherwise-hardest part of human assessment into an automated agent-grade oracle.

---

## 10. Cross-refs

Generic protocol — [`HUMAN-LEARNING-M0-PROTOCOL.md`](HUMAN-LEARNING-M0-PROTOCOL.md) · verifier design — [`HUMAN-LEARNING-VERIFIER.md`](HUMAN-LEARNING-VERIFIER.md) · adapter — [`ALGORITHM-v0.2-pathway-learner.md`](ALGORITHM-v0.2-pathway-learner.md) §13 (`HumanLearnerAdapter`) · downstream apps unblocked by a GO — [`BUILD-SPECS.md`](BUILD-SPECS.md) B1 (misconception clustering), B2 (prereq-gap), and warm-start A5 · register — [`ALGORITHM-INTEGRATIONS.md`](ALGORITHM-INTEGRATIONS.md) (C1).
