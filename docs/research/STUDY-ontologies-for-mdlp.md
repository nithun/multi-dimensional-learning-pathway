# Ontologies for MDLP — growth is ontology learning, and the field has twenty years of results on it

**Date:** 2026-08-12 · **Status:** study document — **ungated**. Proposals at the end flow the L-010 gate.
**Why separate:** `STUDY-ontologies-and-raft.md` treated ontologies through one essay plus the SHACL spec, blended with Raft material. This is the field on its own terms.
**New ground, checked:** knowledge tracing, BKT and IRT are already covered (`PAPER.md`, `REPORT-self-learning-agents.md`, `ALGORITHM` §3) and are **not** re-derived here. **Ontology learning, OntoClean, ontology evaluation, competency questions, SKOS/persistent identifiers, and the skills-standard ecosystem (ESCO / O\*NET / CTDL) appear nowhere in the corpus.** That is the gap this fills.

---

## 1. The central claim

> **MDLP's growth function `g` (§5.1) is an ontology-learning system. The field has a name for every stage of it, twenty years of results, a standard evaluation methodology, and a known list of failure modes — none of which MDLP currently references.**

Buitelaar/Cimiano's **ontology learning layer cake** (2005) orders the subtasks so each is input to the next: **terms → synonyms → concepts → taxonomic relations → non-taxonomic relations → axioms.** Mapping §5.1 onto it:

| Layer cake | MDLP §5.1 | State |
|---|---|---|
| **terms** | failure traces embedded — `F.add(embed(traj))` | ✔ |
| **synonyms** | `g.maybe_merge()` under `τ_merge` hysteresis | ✔ |
| **concepts** | `cluster(F)` → `new_skill(prior=Beta(α0,β0))` | ✔ **intension** (cluster) + **extension** (suite items), **no lexicon** — see §7 |
| **taxonomic relations** | `add_soft_prereq_edges` by co-mastery; `part_of` (B2 Amendment A) | ✔ |
| **non-taxonomic relations** | `transition{visits,value}`; §15.6 derivation edges | ✔ |
| **axioms** | — | **✘ absent** |

Two observations follow, and the second is the more interesting.

**(a) MDLP stops exactly one layer short, and that layer is ONT-1.** The missing axiom layer *is* the structural-constraint set proposed in the prior study. This reframes the proposal: not "bolt on a validation gate," but **complete the layer cake.**

**(b) The field stops there too.** Buitelaar et al.'s own three closing observations were: *more research is needed in the axiom-extraction subtask*; *a common evaluation platform is needed*; and *the move from static corpora to web-scale resources*. Twenty years on, axiom extraction remains the frontier — recent work is still benchmarking LLMs on axiom identification. **So MDLP's gap is the field's gap, which makes it a contribution position rather than a hygiene item** — and MDLP has something the ontology-learning field has never had for this: **a held-out competence signal to score a learned axiom against.**

---

## 2. Correction to the prior study — the enforcement point already exists

The earlier study said MDLP has no structural gate and that `merge()` would be a clean place to insert one. **That understated what is already built.** B2 Amendment A (approved) specifies:

> *"Acyclicity is enforced over `prereq` ∪ `part_of` … Every edge insertion — grown (§5.1) **or authored** — passes the same acyclicity check before entering the live graph … enforced at the graph **write path**: `GraphStore.merge()` validation, reporting violations via `MergeReport.rejected`."*

That is precisely ONT-1's mechanism — a structural constraint, checked deterministically, on the only write path, reporting into a validation report — **already approved and already covering both grown and authored edges.**

So the finding sharpens rather than dissolves:

- **The enforcement point is solved. The constraint *inventory* is not.** Exactly one structural constraint is enforced (union acyclicity). Dozens of invariants of the same kind — `pending_human` exclusion, suite-and-verifier presence on `live` nodes, `parents[]` cardinality by scaffold operator, status-machine totality, the reserved `maintenance` namespace, the claims-TTL rule — live in prose and in tests.
- **Worse, the one constraint that exists arrived reactively.** Amendment A's own text shows acyclicity being added as a *caught gap* ("closes the author-time RC-4 gap: §5.1's invariant covers only growth-inserted edges"), in a late review round. **Constraints are currently discovered one at a time by review rounds** — which is the L-013 / C2 pattern again, now visible in a third place. §3 is about deriving them instead.

---

## 3. OntoClean — deriving constraints instead of discovering them

Guarino & Welty's **OntoClean** tags every class with four meta-properties and then checks the hierarchy against constraints those tags imply:

- **Rigidity (R)** — is membership necessary for the instance's whole existence? (*+R* rigid / *−R* anti-rigid)
- **Identity (I)** — is there a criterion determining when two instances are the same?
- **Unity (U)** — are the object's parts and boundaries determinable?
- **Dependence (D)** — does an instance existentially require an instance of another class?

The constraints that catch real errors:

1. **An anti-rigid class cannot subsume a rigid one.** (`Student` cannot subsume `Person` — studenthood changes, personhood doesn't.)
2. **A class carrying an identity criterion cannot be subsumed by one that lacks it.**
3. **A dependent class cannot subsume an independent one.**

### Applied to MDLP, where it bites

MDLP has **two typed relations sharing one schema and one rule set**: `prereq{weight, confidence, hard}` and `part_of{weight, confidence, hard}`, same decay of `confidence`, same `τ_traverse` floor, same `q_edge` quota, same union-scoped acyclicity.

**They are not the same kind of relation, and OntoClean is precisely the discipline that says so:**

- **`part_of` is mereological and rigid.** Whether skill *B* is a constituent of composite skill *A* is a fact about the skills, **true regardless of who is learning**.
- **`prereq` is a dependency relation and learner-relative — anti-rigid by construction.** §5.2 makes reachability a *function of the learner's posterior*: `reach_weight(s,n) = ∏ P(mastery[p] ≥ θ)`. The same edge is effectively live for one learner and dormant for another.

*To be fair to the current design, one worry does not survive contact with the text:* B2 Amendment A carefully disambiguates `confidence` as **edge-existence belief** (with `weight` explicitly RESERVED and consumed by nothing, under the no-static-bias rule). Decaying a *belief that a part_of relation exists* is entirely coherent — the relation's truth isn't decaying, the evidence for it is. That is right.

**What does survive:** union-scoped acyclicity is the *only* well-formedness condition either relation gets, and a mereological hierarchy and a dependency ordering have **different** well-formedness conditions. A part-of hierarchy has unity and parthood constraints that a dependency DAG does not (can a skill be `part_of` two unrelated composites? can a composite be `part_of` its own constituent's sibling? is `part_of` transitive here, and if so is the transitive closure acyclic *and* consistent with `prereq`?). None of these are asked today, and each is the kind of question that will otherwise arrive as a caught gap in review round five.

**The proposal is therefore not "add constraints" but "derive them":** tag `prereq`, `part_of`, and the node classes (`live` / `pending_human` / `retired`, composite vs atomic skill, misconception) with meta-properties **once**, and read the constraint set off the tags. That turns constraint discovery from reactive to systematic — and there is recent work using LLMs for OntoClean-based refinement, so the tagging itself is tractable.

---

## 4. The granularity problem MDLP cannot currently see

`τ_new(region)` is described as "adaptive, region-local" — a **granularity dial with no principle behind it**. `τ_merge > τ_new` gives hysteresis, which prevents oscillation but says nothing about whether the resulting skills are the *right size*.

This is a named, hard, unsolved problem. The **granularity gap** literature comparing LLM skill decomposition against expert ontologies (ESCO / O\*NET) reports **inconsistent granularity as the primary failure mode** of automated decomposition — evaluated by alignment analysis, embedding-based semantic matching, Hungarian-algorithm optimal matching to expert categories, and precision/recall against gold-standard taxonomies. The conclusion is that automated decomposition **complements rather than replaces** expert ontologies, and needs human validation for granularity in particular.

**Why this matters for MDLP specifically:** the `provision_suite` invariant guarantees every live skill is *scorable*. It says nothing about whether it is *well-sized*. A skill split too finely fragments evidence across cells and starves every posterior (`n_min` inflates `n_eff`, masking the fragmentation); a skill fused too coarsely hides a real competence gap inside an average. **Both failures are invisible to a gate that only asks whether held-out competence moved** — the resulting number is well-measured and about the wrong object. This is OntoClean's **Unity** meta-property with a budget attached, and it is a genuine blind spot.

---

## 5. Ontology evaluation is the answer to G4

The literature classifies ontology evaluation into five families: **gold-standard**, **corpus/data-driven**, **task-based**, **criteria-based**, and **human**. MDLP currently does **exactly one**:

| Family | MDLP |
|---|---|
| **Task-based** — does the ontology support the task, regardless of structure? | ✔ **this is the held-out competence gate.** MDLP already does task-based ontology evaluation and has never called it that |
| **Gold-standard** — coverage/accuracy against a reference | ✘ — and references exist (§6) |
| **Corpus/data-driven** — fit to the source corpus | ✘ |
| **Criteria-based** — structural quality metrics (OntoClean, OQuaRE) | ✘ — §3 |
| **Human** — expert review | partial: `pending_human` queue |

### Competency questions make "representative" specifiable

**Competency questions** (CQs) are the standard validation device: *what queries must this ontology be able to answer?* An ontology is adequate iff it answers its CQs.

**Translate to G4 — the credibility item.** "Representative corpus" is currently prose, which is why it cannot be checked and why HANDOVER-v3 can only assert it. The CQ form makes it a checklist: **what tasks must this skill graph be able to route a learner through?** Write the questions first, then a corpus is representative iff the graph induced from it answers them. That is testable, pre-registerable in the same style as `M1-EVAL-PROTOCOL.md`, and it converts G4 from a judgement call into an instrument.

It also composes with the earlier spec-as-corpus idea: the CQs for a spec-implementation corpus are enumerable directly from the spec's own section structure.

---

## 6. Portability — skills as identifiers that mean something outside one MDLP instance

An established ecosystem exists: **ESCO** (EU), **O\*NET** (US), **CTDL / CTDL-ASN** with **Rich Skill Descriptors** and a Credential Registry carrying **51,000+ open skills**, plus the WEF Global Skills Taxonomy. They share three properties MDLP lacks: **publicly documented definitions, persistent identifiers, and cross-mapping support**, represented in **RDF/SKOS** with provenance.

One detail deserves flagging on its own: cross-framework links in that ecosystem are deliberately kept as **mappings rather than hard merges, "to ensure reversibility and auditability."** That is **P2 — every add has an inverse — arrived at independently by a completely different field**, for exactly the reasons the red-team gave. Genuine external validation of MDLP's instinct, and worth citing in the paper.

**What MDLP is missing.** A skill is an internal cluster id. It has an intension and an extension but **no lexicon** (§1) and no stable public identifier. Consequences, all currently paid:

- **B3 transfer must be zero-trust and re-validated** partly because there is *no shared vocabulary* in which sender and receiver could agree on what a skill is. That re-validation is correct and should stay — but a shared identifier would let it start from "the same skill" rather than "an isomorphic variant that might be the same skill."
- **Human↔agent comparison is impossible**, which undercuts the framing that the Tutor is identical across learners (§13).
- **Any external competence claim is uninterpretable.** "This agent has 0.8 on skill 4417" means nothing off-instance.

**The cheap version:** give each skill a stable identifier plus an *optional, non-authoritative* mapping to an external framework, recorded as a mapping (not a merge, not a rename). Costs nothing statistically, touches no posterior, and makes competence claims portable. **The expensive version — seeding the graph from ESCO/O\*NET — should be resisted**, because MDLP's thesis is that skills are discovered from failures rather than authored; an external taxonomy is at most a warm-start prior in the A5 sense, and it should carry the same bounded, decaying influence and the same requirement that gated competence come only from the learner's own held-out evidence.

---

## 7. Prerequisite-relation learning is its own field — and MDLP is ahead in one specific way

Educational-KG work on prerequisite inference (ProPRL's concept–resource hypergraph plus a directed learning-behaviour graph; Structure-based Knowledge Tracing propagating over prerequisite *and* similarity relations; unsupervised inference from document, Wikipedia-hyperlink, graph and text features) evaluates by **alignment against ground-truth graphs** and by **correlating inferred prerequisite probability with causal support from behavioural data.**

MDLP infers prereqs from `top_k_by_confidence(co_mastery)` — **correlational**, and co-occurrence is not prerequisite. That is the field's central known pitfall.

**But MDLP already has the cure and has not named it:** `g.decay_edges()` decays edge confidence *"unless **intervention** evidence renews it."* **Intervention evidence is causal support.** MDLP's edges are maintained by a mechanism the field treats as the gold-standard validation signal, and B2 Amendment A's `q_edge` exploration quota — which guarantees below-floor edges are still occasionally traversed so evidence can flow again — is, structurally, **a randomized-intervention policy over the edge set.** That is a stronger causal story than co-occurrence-based baselines, and it is currently buried in a decay rule and an anti-starvation quota.

Two things follow: **name it** (an edge's confidence is an interventionally-maintained causal belief, not a co-occurrence statistic), and **evaluate against the field's baselines** — a learned MDLP prereq graph versus unsupervised prerequisite-inference baselines on a shared corpus is a direct, publishable comparison MDLP can currently make no claim about.

---

## 8. Practical — MDLP's graph is a property graph, not RDF

`GraphStore` is **networkx** (embedded) / **Neo4j** (full) — a labelled property graph. SHACL is an RDF technology and does not apply natively. The options and the honest verdict:

- **neosemantics (n10s)** validates Neo4j against SHACL — a Neo4j plugin, full-tier only. **Breaks zero-infra; rejected.**
- **Neo4j GRAPH TYPE** — an engine-native typed schema defining what the database may contain **on every write**, versus SHACL which validates **when invoked**. That distinction is exactly MDLP's design question, and the answer is clear: **validate-on-write is the correct model**, because it is the only one that cannot be skipped, and it matches §6.2's all-or-nothing transactional merge contract.
- **What MDLP should actually do: take the semantics, not the stack.** A declarative constraint table over `GraphDelta`, evaluated inside `merge()`, reporting into `MergeReport.rejected` — which is **already how union acyclicity works** (§2). It is stdlib-only, tier-independent (identical behaviour on networkx and Neo4j because it sits above both), and needs no RDF anywhere.

The relevant borrowings from SHACL are therefore conceptual and small: **node shapes vs property shapes** (constrain the node, or constrain values reachable by a path), the **closed-shape** idea (`sh:closed` — no properties beyond those declared, which is how you catch a delta carrying a field nobody declared), **severities** (Violation / Warning / Info, mapping onto reject / `pending_human`+`queue_rank` / record-only), and the **validation-report-not-exception** return shape, which `MergeReport` already is.

---

## 9. What not to take

- **An RDF/OWL/triplestore tier.** Zero-infra is load-bearing; the property graph is the right substrate; nothing here needs triples.
- **OWL reasoning.** Open-world plus no-unique-name means violations surface as silent inferences rather than errors — the failure the source essay documents. MDLP's write path must reject and report, never infer.
- **Seeding the skill graph from an expert taxonomy.** Contradicts the discovered-not-authored thesis. Mapping yes; seeding no (§6).
- **A heavyweight ontology methodology** (METHONTOLOGY / NeOn full process). The harvest is four devices — layer-cake vocabulary, OntoClean meta-properties, competency questions, evaluation families — not a process framework.
- **Replacing the statistical gate with symbolic checks.** The two are complements; this was the prior study's thesis and it holds.

---

## 10. Proposals — each gated before touching a gated artifact

- **ONT-1′ (revises ONT-1) — generalize the constraint mechanism that already exists.** B2 Amendment A already validates union acyclicity inside `merge()` and reports via `MergeReport.rejected`. Generalize it from one hard-coded check to a **declared constraint table**, add SHACL's three severities, and require one violating-input test per constraint (the §20.6 alarm-fire-test discipline, new surface). **Cheaper and better-founded than ONT-1 as originally written** — the precedent is approved and in the write path.
- **ONT-3 — OntoClean meta-property tagging for the graph vocabulary.** Tag `prereq`, `part_of`, and the node classes once; read the constraint set off the tags rather than discovering constraints one review round at a time. Directly targets the third observed instance of the reactive-constraint pattern.
- **ONT-4 — competency questions for G4.** Write the CQs that a representative corpus must let the graph answer, pre-registered in the style of `M1-EVAL-PROTOCOL.md`. **Converts the credibility item from a judgement call into an instrument**, and composes with the spec-as-corpus idea.
- **ONT-5 — skill identity and optional external mapping.** Stable identifier per skill plus non-authoritative mappings to ESCO/CTDL, recorded as mappings, never merges. Statistically inert; makes competence claims portable and gives B3 a shared vocabulary to start from.
- **ONT-6 — name the causal story and benchmark it.** State that edge confidence is an interventionally-maintained causal belief (`decay_edges` renewal + `q_edge` quota = a randomized-intervention policy), and evaluate the learned prereq graph against unsupervised prerequisite-inference baselines.
- **ONT-7 — granularity as a first-class concern.** `τ_new` currently has hysteresis but no principle; over- and under-splitting are both invisible to a held-out competence gate. At minimum, instrument it (cluster-size distribution, per-skill `n_eff` starvation, merge/split churn) so the blind spot is observable before it is fixed.

**Positioning note for `PAPER.md`:** §1(b) is a genuine research position — the ontology-learning field's twenty-year-old open problem is the **axiom layer**, and MDLP is the first system in a position to attack it with a **held-out competence signal** as the scoring function for a candidate axiom. Worth stating explicitly rather than leaving implicit in a proposal.

---

*Provenance: Buitelaar/Cimiano ontology-learning layer cake and its closing observations; OntoClean (Guarino & Welty) meta-properties and subsumption constraints, plus recent LLM-assisted OntoClean refinement work; the ontology-evaluation survey literature (five families) and competency-question practice; the LLM-skill-decomposition vs expert-ontology granularity-gap work; ESCO / O\*NET / CTDL-ASN / Rich Skill Descriptors and the Credential Registry; educational-KG prerequisite-relation learning (ProPRL, Structure-based Knowledge Tracing, unsupervised inference); Neo4j neosemantics and GRAPH TYPE versus SHACL. MDLP-side claims were checked against the artifacts rather than recalled — §2's correction came from reading B2 Amendment A directly, and it revises a claim made in `STUDY-ontologies-and-raft.md`. Knowledge tracing / BKT / IRT deliberately not re-derived; already in `PAPER.md` and `REPORT-self-learning-agents.md`. L-012 unchanged.*
