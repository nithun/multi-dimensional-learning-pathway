# Patterns

Recurring code/process shapes worth standardizing. Each entry: a name, the canonical form, and the lessons it relates to. Maintained by `retrospective`. Stable `P-NNN` ids so other docs can link to them.

---

## P-001 — Propose → validate → apply

Used by: any write path where a bad write is expensive to undo. MDLP arrived at this independently three times — `§6.2` EXTRACT→MERGE (`GraphStore.merge()` returns a `MergeReport` before anything lands), `§17.3` shadow→hot-swap (sandbox trial before promotion, retained fallback), `§6.1` dispatch-intent-before-work (intent declared and idempotency-keyed before the work unit executes). Externally confirmed twice: the ontology essay's pure-tools requirement ("tools remain pure — computing and proposing changes without executing them until validation passes") and Raft's log discipline (entries appended and replicated but not *applied* until committed on a majority).

Related lessons: none yet — framework-side, no gate needed (`STUDY-ontologies-and-raft.md` §7).

```
propose:  declare the write as a pending/inert artifact (a report, a sandbox, a log entry) —
          it touches no live state yet
validate: run an independent check (structural admissibility, quorum/majority, held-out
          measurement) against the proposal, not against live state
apply:    commit only on pass; on fail, the proposal is discarded or retried — never
          partially applied
```

Why this and not the obvious alternative (write directly, validate after, roll back on failure): keeping the proposal inert until validation passes means a rejected write never touches live state, so no rollback logic is needed. It also gives a mechanical name to a defect class already seen in this project: the 2026-07-28 TA audit's "built-but-unwired" constructs are, in every instance, a *validate* stage that was specified and then never placed on the *apply* path — i.e. a wiring gap in this exact shape, not a design gap.

*Source: 3 independent MDLP derivations + 2 external confirmations, well past the L-003 ≥3 evidence bar; full statement at `STUDY-ontologies-and-raft.md` §6 (P-001); interactions.jsonl IX-048/049/050.*

<!-- Example of the shape a pattern takes (delete once more real patterns exist):

## P-002 — <name>

Used by: <where this shows up>.
Related lessons: L-0NN.

```<lang>
<the canonical implementation>
```

Why this and not the obvious alternative: <one line>.
-->
