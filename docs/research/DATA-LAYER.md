# MDLP Data Layer — the 5-store hybrid as a pluggable Python library

**Goal:** realize the concept paper's hybrid 5-store data architecture (SQL · MongoDB · Vector · Graph · Redis) as a reusable Python library that backs the pathway-learner algorithm — **with a pluggable backend** so the same code runs on a zero-infra embedded tier *or* the full five databases.

**The reconciliation.** Earlier analysis (REPORT §7.4, L-010) warned against *standing up* five databases on day one. This library resolves that: the five stores are **ports (interfaces)**; you wire either the **embedded tier** (SQLite + networkx + a local vector lib + in-proc cache — default, zero install) or the **full 5-store tier** (Postgres + MongoDB + a vector DB + Neo4j + Redis). The full architecture is *designed and available*; it is not *forced*. Switch backends by config, not code — and only when real transition data justifies the heavier tier (the L-010 evidence gate).

> One-line identity: **the SQL truth store is canonical; every other store is a rebuildable projection.** That single rule (P1 from the algorithm) is what makes the hybrid safe, swappable, and cache-aggressive.

---

## 1. The store roles (the paper's 5 + 1)

| Role | Paper store | Holds | Path | Loop step (algorithm) |
|---|---|---|---|---|
| **TruthStore** | SQL | canonical event log, eval results, **data/checkpoint lineage** | 🧊 cold | BACKUP / COMMIT — the source of truth |
| **StateStore** | MongoDB | the **growing** competence field (dual Beta posteriors per `skill×difficulty×context`) — *schemaless because the schema grows* | 🌗 warm | BACKUP (write) / SELECT (read) |
| **VectorStore** | Vector DB | embeddings of skills/lessons/failures; ANN recall; failure clustering | 🔥 hot | SELECT (retrieval) / GROW (clustering) |
| **GraphStore** | GraphDB | the skill graph (prereqs, transitions), the MCTS tree | 🔥 hot | SELECT (soft reachability) / BACKUP (tree) |
| **CacheStore** | Redis | materialized frontier, hot state vector, hot competence — the "act fast" layer | 🔥 hot | SELECT (sub-ms reads) |
| **ArtifactStore** | *(added)* | model checkpoints + datasets + a model registry (M2) | 🧊 cold | EXPAND(weight) / COMMIT |

*(The autonomy deployment profile adds two opt-in roles — ObservabilityPort and AnalyticsStore, §11. They are never part of the default install.)*

The hot stores form the **act path** (millisecond reads at decision time); the cold stores form the **learn path** (async writes during evolution). `StateStore`'s schemaless nature is not incidental — it is *required* by the open schema: a growing, ragged competence field can't live in a rigid SQL table.

---

## 2. Library shape (ports & adapters)

```
mdlp/stores/                       # (extractable later as a standalone lib `pathway-stores`)
  __init__.py                      # factory: build_stores(config) -> Stores
  ports.py                         # the 6 abstract interfaces (stdlib only, zero deps)
  schemas.py                       # dataclasses for the records each store holds
  embedded/                        # TIER 1 — zero-infra (default)
    truth_sqlite.py
    state_sqlite.py                # competence cells in a JSON column (schemaless-enough)
    vector_local.py                # faiss-cpu / sqlite-vec / numpy brute force
    graph_networkx.py
    cache_inproc.py                # dict + TTL (or diskcache)
    artifact_fs.py                 # local filesystem + a JSON registry
  full/                            # TIER 2 — the 5-store hybrid (optional extras)
    truth_postgres.py
    state_mongo.py
    vector_qdrant.py               # or pgvector / milvus
    graph_neo4j.py
    cache_redis.py
    artifact_s3.py                 # S3/MinIO + registry table
  rebuild.py                       # rebuild any projection store from TruthStore
```

### 2.1 The ports (abstract interfaces)
```python
class TruthStore(Protocol):
    def open_work_unit(self, agent_id, episode_id, suite_id, intent_key) -> WorkUnit: ...  # idempotent mint; raises UnknownIntentKey — §6.1
    def append_event(self, ev: Event) -> AppendResult: ...    # {id, deduped, rejected_reason} — §6.1
    def record_eval(self, r: EvalResult, lineage: Lineage) -> AppendResult: ...  # same contract (§6.1)
    def read_events(self, **filter) -> Iterator[Event]: ...
    def lineage(self, checkpoint_id: str) -> Lineage: ...     # what data trained what

class RedactedTruthView(TruthStore):                          # SOLVE-side truth handle — §6.1 P1 boundary
    """Same Protocol; results with split=held_out have item_ids/content stripped (aggregates pass)."""

class StateStore(Protocol):                                   # the growing competence field
    def get(self, skill, difficulty, context=None) -> Cell | None: ...
    def put(self, cell: Cell) -> None: ...
    def cells(self, **filter) -> Iterator[Cell]: ...          # ragged, schemaless
    def snapshot(self, checkpoint_id: str) -> None: ...

class VectorStore(Protocol):
    def upsert(self, id: str, vec: list[float], meta: dict) -> None: ...
    def query(self, vec: list[float], k: int, **filter) -> list[Hit]: ...   # ANN recall
    def cluster(self, ids: list[str]) -> list[Cluster]: ...                  # failure clustering

class GraphStore(Protocol):
    def add_skill(self, s: str, prereqs: list[Edge], *, status="live") -> None: ...
    def reach_weight(self, s: str, state) -> float: ...        # ∏ P(prereq mastered) — soft
    def update_transition(self, a, b, r) -> None: ...
    def tree_backup(self, node: str, r: float) -> None: ...    # discounted MCTS value
    def prereqs(self, s) -> list[Edge]: ...
    def in_edges(self, s, types=None) -> list[Edge]: ...       # typed walk (prereq/part_of) — B2 Amendment A
    def merge(self, delta: GraphDelta) -> MergeReport: ...     # the only projection write path — §6.2

class CacheStore(Protocol):
    def get(self, key: str): ...
    def set(self, key: str, val, *, ttl=None) -> None: ...
    def invalidate(self, checkpoint_id: str) -> None: ...      # drop stale-on-new-checkpoint

class ArtifactStore(Protocol):                                # M2
    def put_checkpoint(self, blob) -> str: ...
    def register(self, ckpt_id: str, lineage: Lineage, metrics: dict, stage: str) -> None: ...
    def gc(self, retention) -> None: ...
```

A `Stores` bundle (a dataclass holding one instance of each port) is what the algorithm receives. **Two bundles exist** (§6.1 P1 boundary), and their composition is enumerated, not implied: the **JUDGE bundle** holds the unredacted `TruthStore` — and, when the autonomy profile is on, the full `ObservabilityPort` and the `AnalyticsStore` (§11); the **SOLVE bundle** holds a `RedactedTruthView` (same interface; held-out `item_ids`/content stripped) and **neither observability nor analytics** — no `ObservabilityPort` of any kind, no `AnalyticsStore` (§11 delta: all observability is JUDGE-authored; SOLVE emits nothing). Concretely, `Stores` gains two optional fields — `observability: ObservabilityPort | None` and `analytics: AnalyticsStore | None` — populated **only** in the JUDGE bundle, and only when the autonomy profile is on; and one field present in **both** bundles — `inference: InferenceClient`, the JUDGE-composed metering client (§11 invariant 1) — the solve bundle's copy being the forwarding proxy described there. Wired at `build_stores()` time, outside every SOLVE-editable surface.

---

## 3. The two tiers (concrete backends)

| Role | Embedded tier (default) | Full 5-store tier |
|---|---|---|
| TruthStore | **SQLite** (stdlib) | **PostgreSQL** |
| StateStore | SQLite + JSON column | **MongoDB** |
| VectorStore | `faiss-cpu` / `sqlite-vec` / numpy | **Qdrant** / **Milvus** / **pgvector** |
| GraphStore | **networkx** (in-proc) | **Neo4j** |
| CacheStore | in-proc dict + TTL | **Redis** |
| ArtifactStore | local filesystem + JSON registry | **S3/MinIO** + registry table |

**The lean middle option** (REPORT's recommendation): one **Postgres + pgvector** instance covers TruthStore *and* VectorStore, `networkx` covers GraphStore, Redis optional — three processes covering five roles. The config below lets you mix backends per role, so you adopt heavy stores one at a time as load demands.

---

## 4. Configuration (select backend per role)

```toml
# mdlp.toml
[stores]
truth    = "embedded"            # sqlite://./mdlp.db
state    = "embedded"
vector   = "embedded"
graph    = "embedded"
cache    = "embedded"
artifact = "embedded"

# ...flip to the full tier per role as you scale, e.g.:
# truth  = "postgres://user@host/mdlp"
# state  = "mongodb://host/mdlp"
# vector = "qdrant://host:6333"
# graph  = "neo4j://host:7687"
# cache  = "redis://host:6379"
```
```python
from mdlp.stores import build_stores
bundles = build_stores(load_config("mdlp.toml"))   # -> Bundles{judge: Stores, solve: Stores}
# bundles.judge.truth is the unredacted TruthStore (orchestrator/eval harness only);
# bundles.solve.truth is the RedactedTruthView (§6.1 P1 boundary) — same Protocol, held-out items stripped
```
Default (no config) = all embedded → `pip install mdlp` and run, no infra.

---

## 5. Record schemas (what lives where)

- **Truth (SQL):** `events(id = identity_hash, ts, type, payload, actor, agent_id, episode_id, checkpoint_id, attempt_idx)`; `evals(id = identity_hash, ts, skill, difficulty, split{public|held_out}, n_pass, n_total, verifier, item_ids, checkpoint_id, agent_id, episode_id, attempt_idx)` — the `identity_hash` id, occurrence-provenance, and `agent_id` fleet-key columns realize §6.1 (`agent_id` mirrors `lineage`/StateStore keying; single-agent default is a constant — no reliance on `episode_id` being fleet-globally-unique) (delta gated with §6.1); `lineage(checkpoint_id, parent, dataset_id, eval_run_id, agent_id)` *(`agent_id` = the fleet key, mirroring §18.1's per-agent StateStore keying; single-agent default is a constant — delta gated under ALGORITHM §17.6)*; `work_unit_opened(occurrence_id, agent_id, episode_id, suite_id, attempt_idx, intent_key UNIQUE, item_ids, owner{pid, started_at}, lease_expires_at, ts)` *(the identity-root row; `intent_key` = the dispatch event's id; `attempt_idx` = the dispatch's `seq` — one counter, not two; `item_ids` pins the drawn sample at open — §6.1 delta; `owner` + heartbeat-refreshed `lease_expires_at` make ALGORITHM §20.2's "owner proved dead" a checkable predicate — §20 delta)*; `dispatch{agent_id, episode_id, suite_id, action_fingerprint, seq, schedule_id?, ts}` *(administrative event appended before work begins; `seq` = the persisted count of prior dispatches for that `(agent, episode, suite)`, assigned atomically inside the append transaction — the discriminator that keeps two genuinely distinct same-action dispatches from colliding; `action_fingerprint` = hash of the selected action's parameters (skill, difficulty, teacher, context refs) — a content descriptor, deliberately NOT the discriminator; the event's id is the `intent_key` — §6.1 delta)*; `scaffold_versions(version_id, component_id, parents, operator, source_ref, snapshot_ref, diff, gate_ref, status, revalidation, created_ts)` + event kinds `selfmod_rejected{reason, proposal_hash, ts}`, `component_invoked{component_id, episode_id, ts}` *(delta gated under ALGORITHM §17.6)*; `rejected_ingest{reason, payload, ts}` *(system actor, full payload retained — §6.1 delta)*; `schedule(schedule_id, agent_id, kind ∈ cron|interval|once, expr, next_run_at, tier_minimum, enabled, state ∈ ok|error)` + `supervisor_lease(agent_id, holder{pid, started_at}, lease_expires_at)` *(the §20.2 singleton — heartbeat-refreshed at `h_lease`, expired past `g_lease`)* + `wake_events(id, agent_id, payload, ts, consumed_ts)` *(atomic consume via `UPDATE … RETURNING`)* + event kind `work_unit_closed{occurrence_id, outcome ∈ completed|failed|unknown, ts}` *(terminal, immutable; `unknown` written only by the recovery scan after the owner is proved dead, and never auto-retried — delta gated under ALGORITHM §20)*; event kinds `trace{correlation_id, kind ∈ dispatch|span|cycle|delivery, payload, ts}` + `score{correlation_id, name, value, ts}` *(the embedded ObservabilityPort backing — administrative class, **all rows JUDGE-emitted** (the orchestrator observing SOLVE; SOLVE emits nothing); stored under the JUDGE data directory — delta gated under §11)*.
- **State (Document):** `cell{skill, difficulty, context, mastery:{α,β}, drift:{α,β}, n_eff, updated_ts, checkpoint_id}` — extra dimensions added freely (schemaless = the open competence field).
- **Vector:** `{id, embedding, kind: skill|lesson|failure, skill_ref, text, meta}`.
- **Graph:** nodes `{skill, status: live|pending_human|retired, suite_ref}` *(`retired` realizes `g.prune_orphans`'s inverse at the store — delta gated with §6.2)*; edges `prereq{weight, confidence, hard}`, `part_of{weight, confidence, hard}` *(typed hierarchy edges + `hard` flag — schema delta gated under B2 Amendment A, BUILD-SPECS)*, `transition{visits, value}`; mcts `{node, visits, value, checkpoint_gen}`.
- **Cache (Redis):** `frontier:{state_hash} → [actions]`; `statevec:{node} → vector`; `cĥot:{skill,diff} → ĉ` — all **version-stamped by `checkpoint_id`** and invalidated on a new checkpoint.
- **Artifact:** checkpoint blobs; `registry{ckpt_id, base, adapter, dataset_id, metrics, parent, stage: probation|merged, created_ts}`.

---

## 6. Source-of-truth & rebuild discipline

`TruthStore` is canonical and append-only. `StateStore`, `VectorStore`, `GraphStore`, `CacheStore` are **derived projections**:
```python
# rebuild.py
def rebuild_state(truth, state): ...     # replay evals → recompute Beta posteriors
def rebuild_vectors(truth, vector): ...  # re-embed skills/lessons/failures
def rebuild_graph(truth, graph): ...     # replay growth/transition events
def rebuild_analytics(truth, analytics): ...  # re-derive the columnar projection — §11 delta
def rebuild_all(truth, stores): ...      # disaster recovery / backend migration
```
This is what makes the design safe: caches can be dropped and rebuilt; you can **migrate from embedded → full tier by pointing at a new backend and replaying truth**; and the learning layer stays an optional, rebuildable add-on over the canonical file logs (L-010). On any checkpoint change, `CacheStore.invalidate()` plus a tree-stat discount keep the hot path from serving stale state.

### 6.1 Idempotent evidence — occurrence-identity hashing (a §3 correctness requirement) *(added 2026-07-13 — ▣ APPROVED: review-360 83/100 over 12 rounds → change-approver, `reviews/DL-write-discipline-decision.md`)*

Every record that can move a posterior — eval results, failure traces, lessons, skill artifacts — carries an **identity hash** whose inputs are, per record type:

```
id = hash( record_type ‖ semantic_payload ‖ occurrence_provenance )
     semantic_payload      = the content (items, outcome, skill, artifact bytes …)
     occurrence_provenance = episode/trace id + checkpoint_id + attempt index
                             (NEVER wall-clock ts, NEVER filename)
```

The occurrence component is the load-bearing half: **re-ingesting the *same* occurrence** (pipeline retry, replayed transcript, curator re-digestion — same episode, same checkpoint, same attempt) produces the same id and dedupes; **a genuine repeat measurement** (same skill/items/outcome observed again in a *new* episode/attempt — the *modal* case for a stable candidate under `sustained_heldout` §9, Stage-1 shadow monitoring §17.3, and the §19.1 `w_obs` machinery) produces a **new id and a new event**. Round 1 of this gate hashed the semantic payload alone, which would have silently *under*-counted exactly those repeat observations — the inverse bias of the duplication it set out to fix.

**Who mints occurrence ids, and why retries reuse them (the durability contract — full lifecycle, r6).** Occurrence provenance is **minted once, durably, at work-unit creation — never generated at ingestion time**. The **work unit is the eval run** (matching the batched `evals` row over `item_ids` — §5; not per-item, so the granularities agree). The lifecycle, with its port:

1. **Declare intent, durably and distinctly** — before any work, the §6 orchestrator appends a **`dispatch` event** (administrative — it appears in the record-class exemption list below) capturing `(agent_id, episode_id, suite_id, action_fingerprint, seq)`. **`seq` is the discriminator:** the persisted count of prior dispatches for that `(agent, episode, suite)`, assigned atomically inside the append's own transaction — so two *genuinely distinct* dispatch decisions, even selecting the *identical action* in the same episode (routine repeated practice), always carry different `seq` and therefore different ids (`test_distinct_dispatches_distinct_keys`). `action_fingerprint` (hash of the selected action's parameters) is a content descriptor only, never the discriminator. **The dispatch event's id is the `intent_key`, with its hash inputs stated exactly** (not "the general rule" by reference — its occurrence discriminator is `seq`, not the eval-record provenance triple): `id = hash( "dispatch" ‖ agent_id ‖ episode_id ‖ suite_id ‖ action_fingerprint ‖ seq )`, **`ts` and `checkpoint_id` excluded** — `seq` alone separates occurrences, and it cannot repeat (unique per `(agent, episode, suite)` by the atomic counter). So a *transport-level retry of the same append* dedupes, while a new decision (new `seq`) never can. **The `seq` counter, concretely:** embedded tier — the count-and-insert is one SQLite statement in one transaction (`INSERT … SELECT COUNT(*) …`); full tier — a per-`(agent, episode, suite)` counter row bumped atomically in the same DB transaction as the append — including the first dispatch, via atomic upsert (`INSERT … ON CONFLICT DO UPDATE SET n = dispatch_seq.n + 1 RETURNING n`), so concurrent FIRST dispatches for a brand-new key cannot race either. No new primitive is invented: appending decisions to the canonical event log is what TruthStore is for (§10).
2. **Mint, idempotently** — `TruthStore.open_work_unit(agent_id, episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}`. **Open validates its reference first, with a named rejection contract:** an `intent_key` that resolves to no `dispatch` row **raises `UnknownIntentKey`** (the same reference-validity principle as step 5 — identity is only ever *copied from* the dispatch record, never invented at open; the exception, not a null return, because a failed open must never be mistakable for a work unit). `attempt_idx := dispatch.seq` is a **copy** of the value step 1 already assigned atomically — one counter, not two; open performs no counting of its own. The `work_unit_opened` row carries `intent_key` with a **UNIQUE constraint** (§5) — the constraint IS the idempotency mechanism: open-with-existing-key returns the existing row; open-with-new-key inserts. The check-and-insert executes in **one transaction of the truth backend** (SQLite is natively transactional on the embedded tier; Postgres on the full tier — TruthStore never borrows §6.2's *graph* writer lock, which is `networkx`'s mechanism, not SQL's), so concurrent opens with the SAME `intent_key` serialize to one insert + one return-existing (`test_same_intent_concurrent_open`). The row **pins `item_ids` at open**, so a resumed work unit re-evaluates the *same* items: the §4.1 rotating sample cannot produce a different `semantic_payload` under the same occurrence (a different sample is a new dispatch ⇒ new `seq` ⇒ new work unit).
3. **Recover by reading truth, never by re-deriving** — on restart, the orchestrator scans truth for **both** kinds of orphan: work units with no terminal eval record (**resume**: same `occurrence_id`, same pinned items) and `dispatch` rows with no `work_unit_opened` row yet (**complete the mint**: call `open_work_unit` with the dispatch's `intent_key` — idempotent, so a lost open-ack is also safe). The write-then-ack-loss race resolves itself at every stage: if the crashed attempt's `record_eval` DID land, the scan shows the work unit closed — nothing to resubmit (a forced resubmission dedupes by identity); if it didn't land, the resumed run's records are first-time appends. No path mints a second occurrence for one real attempt, and no path merges two real attempts into one occurrence (distinct `seq`).
4. **Record** — the run's posterior-moving records (evals, outcome events) carry the minted `occurrence_id`; a literal retry re-executes an existing work unit and reads its id from the durable row.
5. **Enforce** — `append_event`/`record_eval` return `AppendResult{id, deduped: bool, rejected_reason: str|None}` (one three-field contract, everywhere) and set `rejected_reason` for a **posterior-moving** record whose occurrence references no `work_unit_opened` row — a harness minting fresh trace ids per call has no matching row and is refused by the store, not by test discipline. **On mint rate, stated plainly: the store imposes no rate limit on `open_work_unit`.** The practical bound is that each work unit requires a dispatch decision from the §6 loop (one per selected action), which is a caller-side, JUDGE-side property — not a store guarantee; a compromised orchestrator could mint freely, and the defense there is that minting alone moves no posterior (only gated eval outcomes do).

**No circularity, no unenforced hole — the exemption is by record class, and the class is checkable:** occurrence validation applies exactly to records that can move a posterior (§6.1's opening scope). *Identity-root* records (`work_unit_opened`) and administrative events (**`dispatch`**, `selfmod_rejected`, `component_invoked`, `rejected_ingest`, `work_unit_closed` *(§20 delta)*, `trace`/`score` *(§11 delta)*) move no posterior — StateStore Beta updates key only off eval/outcome records, so this boundary is a property of the update path, not a policy promise. `open_work_unit` is therefore the one legitimate entry point that creates identity rather than referencing it — and it creates identity idempotently (step 2), so re-invocation cannot manufacture duplicate occurrences.

**Held-out `item_ids` are pinned but reach SOLVE only redacted (P1 across the store boundary):** pinning the drawn sample in `work_unit_opened`/`evals` rows makes held-out item identifiers durable truth data — and truth is **legitimately SOLVE-reachable**: §16.4 names the truth store as one of `retrieve()`'s modalities (eval history → grounding/citations), and §17.1 places *retrieval config* on the mutable SOLVE side. So the enforcement point cannot be "SOLVE never reads truth"; it is a **view boundary in the ports-and-adapters layer**: the `Stores` bundle handed to SOLVE-side components (the §5.2/§16 retrieve path, and any future `self_modify`-editable code) wraps TruthStore in a **`RedactedTruthView`** — identical interface, but rows with `split = held_out` have `item_ids` and item-content references **stripped before any result leaves the adapter** (aggregates like `n_pass/n_total` pass through: outcomes are not secrets, the items are). The **unredacted** TruthStore handle exists only on the JUDGE side (the eval harness and the §6 orchestrator — the components §17.1 already makes immutable and, at M3, address-space-isolated). SOLVE's mutable retrieval config chooses *which queries to issue*; it cannot choose *which view answers them* — the view is wired at `build_stores()` time, outside every SOLVE-editable surface. This is consistent with §17.1 rather than contradicted by it: the held-out set and its generator are JUDGE members, and the redacted view is simply their guard at the library boundary (`test_held_out_item_ids_not_solve_readable` asserts against the view: a truth-mode retrieve over eval history returns aggregates, never held-out `item_ids`). **Durability against `self_modify` (M3), stated as its own check — not inferred from the wall invariant:** §17.1's static check catches SOLVE→JUDGE *write*-paths; acquiring an unredacted *read* reference is a different hazard, so the admission analysis additionally verifies that **no SOLVE candidate imports or constructs the unredacted `TruthStore` adapter** (a type/import-level check, decidable because §17.1 already bans reflection/`eval`/dynamic import in SOLVE), with the §17.3 Stage-1 sandbox as the runtime backstop (candidates run holding only the solve bundle). Pre-M3 there is no `self_modify`, and the wiring at `build_stores()` is the whole story (`test_solve_candidate_cannot_import_unredacted_truth`).

**A rejection is handled, never a silent discard of real work — and bounded:** the store logs a `rejected_ingest{reason, payload}` event (system actor, **full payload retained** so re-association is always possible — a hash alone would strand the evidence), the caller receives `rejected_reason` and must either re-associate the records with its open work unit and re-append, or escalate to the breaker. **Growth bound:** an unre-associated payload is pruned to its hash after the retention window `w_rejected` (default 30 days); the row itself is permanent (audit preserved, storage bounded — the same blobs-prunable/rows-permanent discipline as §10/§17.6).

Tests for §6.1 are consolidated with §6.2's into the single **write-discipline test set** at the end of §6.2 (one list, one place — rounds 3–7 flagged the split).

`TruthStore.append_event` / `record_eval` stay **true appends**: an append whose identity already exists writes nothing and returns `AppendResult{id, deduped: true, rejected_reason: None}` — nothing is ever modified (append-only preserved; identical-identity re-appends are no-ops, which is idempotence, not upsert), and the caller can observe that a dedup occurred (the §6.2 `MergeReport` standard, applied here). The same three-field `AppendResult` covers all outcomes: fresh append, dedup, or rejection (see the lifecycle above). Defense in depth: `StateStore` Beta updates are ALSO keyed by the evidence id they consumed, so even a duplicate that slipped past ingestion cannot double-update a posterior.

Rationale — inference correctness, not storage hygiene: duplicated evidence double-counts into `(α,β)`; deduplicated *distinct* evidence starves the repeat-observation statistics — both silently bias downstream decisions. Occurrence-identity hashing removes exactly the true duplicates and nothing else, and makes `rebuild.py` idempotent **over whatever the log contains** (replaying truth N times yields identical posteriors; the guarantee is determinism given the log — ingestion correctness above is what makes the log itself right). *(Pattern provenance: content-hash ids are how RAG-Anything/LightRAG achieve idempotent re-ingestion — `STUDY-raganything-agentscope-openspace.md` P2; the occurrence-provenance requirement and the Beta-bias argument are ours.)*

Port delta: `schemas.py` records gain `identity_hash` (+ its provenance fields) and the exception `UnknownIntentKey`; `ports.py` gains `RedactedTruthView` (the SOLVE-side truth handle) and `build_stores` returns the two-bundle `Bundles{judge, solve}`; `TruthStore.open_work_unit(agent_id, episode_id, suite_id, intent_key) -> WorkUnit{occurrence_id, attempt_idx}` (idempotent on `intent_key`; **raises `UnknownIntentKey`** when the key resolves to no `dispatch` row — the rejection contract, since `WorkUnit` carries no error channel); `append_event`/`record_eval` return `AppendResult{id, deduped: bool, rejected_reason: str|None}`.

### 6.2 Two-phase projection writes — extract, then transactional merge *(added 2026-07-13 — ▣ APPROVED: review-360 83/100 over 12 rounds → change-approver, `reviews/DL-write-discipline-decision.md`)*

Writes into the projection stores (Graph/Vector) from growth (§5.1 of the algorithm) and indexing paths are **two-phase**:

1. **EXTRACT** — parallel, cheap candidate generation (new skills / edges / embeddings), producing a `GraphDelta`; extractors hold no write locks. **Liveness is decided before the delta exists:** growth candidates enter the `GraphDelta` already carrying the `live` / `pending_human` status that `provision_suite` (§5.1, RC-3) assigned — **MERGE never assigns or upgrades liveness** (it is a projection writer, not a gate).
2. **MERGE** — one transactional `GraphStore.merge(delta) -> MergeReport` applying **set-merge semantics** (`V∪V'`, `E∪E'`) with dedup **by identity only** (§6.1 identity-hash equality). **Semantic merging is not this layer's job:** `τ_merge`-based similar-skill unification remains exclusively `g.maybe_merge()`'s (§5.1, algorithm layer) — when it fires, it emits **one growth event in truth** with a concrete schema, from which BOTH projections replay:
   ```
   skill_merge{ survivor_id, absorbed_id,
                evidence_union: [cell_ids moved into survivor],   # replayed by rebuild_state
                graph_ops:      GraphDelta.merges entry,          # replayed by rebuild_graph
                provenance:     truth_event_id, checkpoint_id }
   ```
   so graph and posterior projections can never diverge on what was merged (a merged graph node with an un-merged posterior cell is unrepresentable — both derive from the same row). Two mechanisms, two jobs, one symbol no longer shared.

Schemas — the delta carries growth's **inverses** too, since `merge()` is the only projection write path (a write path that could express `add` but not `retire`/`decay` would force §5.1's inverse operations to bypass the atomic-swap guarantee):
```
GraphDelta { adds:         [Node],                        # status pre-decided (see EXTRACT)
             edges:        [Edge],
             merges:       [(survivor_id, absorbed_id)],  # emitted only by g.maybe_merge()
             retires:      [node_id],                     # g.prune_orphans → status=retired
             edge_updates: [(edge_id, confidence)],       # g.decay_edges / renewal
             provenance:   [truth_event_ids] }            # list — one delta per tick coalesces many events
MergeReport{ added: [id], deduped: [id], merged: [(id,id)], retired: [id], updated: [id], rejected: [(id, reason)] }
```

**"Transactional," per tier — and the failure contract.** Full tier: the backend's native transaction (Neo4j/Postgres). Embedded tier (`networkx`, in-proc): apply the delta to a **shadow copy, then atomically swap the graph reference under a single writer lock** — the embedded tier is single-process by definition (§3), and concurrent §18 fleet agents in one process serialize on that lock; a **multi-process fleet requires the full tier** (stated as a hard constraint, not an aspiration). **Cost, stated and bounded:** the shadow copy is O(|V|+|E|) time and transient 2× memory *per merge call*, so merges are **coalesced — one `merge()` per §6 loop tick** (all of that tick's growth/index deltas in one call), never one per candidate; this is cold/learn-path work (§1), and "graph copy time exceeding the tick's merge budget" is hereby an explicit, measurable **additional trigger for the §9 M1 flip `graph → neo4j`** (whose native transactions remove the copy entirely). Failure contract, both tiers: `merge()` is all-or-nothing — on failure no partial application, the delta is retained for retry, and the failure is a truth event.

Continual operation **never full-re-indexes** a projection; `rebuild.py` remains the only full-rebuild path (disaster recovery / backend migration, per §6) — and `rebuild_graph` **replays through the same `merge()` path** as continual operation, so a rebuild reproduces byte-for-byte what incremental merging produced.

Port delta: `GraphStore.merge(delta: GraphDelta) -> MergeReport`; `VectorStore.upsert` ids must be identity-hashes (already idempotent by id).

**Write-discipline test set (one consolidated list for §6.1 + §6.2):**
*Identity & minting (§6.1):* `test_occurrence_id_stable_across_restart` (restart ⇒ no false dedup, no false new-count) · `test_retry_reuses_occurrence_id` (a literal retry ⇒ `deduped=True`, one Beta update) · `test_reopen_same_intent_idempotent` (same `intent_key` twice ⇒ same `WorkUnit`, one row — the UNIQUE constraint, not prose) · `test_same_intent_concurrent_open` (concurrent opens, SAME key ⇒ one insert, one return-existing) · `test_distinct_dispatches_distinct_keys` (two independent dispatches selecting the IDENTICAL action in one `(episode, suite)` ⇒ distinct `seq` ⇒ distinct `intent_key`s, two work units — the round-7 silent-merge regression) · `test_ack_loss_recovery_no_double_count` (crash after successful `record_eval`, before ack ⇒ recovery scan finds the work unit closed; a forced resubmission dedupes) · `test_seq_atomic_under_concurrency` (concurrent `dispatch` appends ⇒ distinct gapless `seq` — the counter is assigned at dispatch, opens only copy it; no lost update on either tier) · `test_open_requires_dispatch_row` (an `intent_key` resolving to no `dispatch` row is rejected at open) · `test_recovery_completes_lost_mint` (a `dispatch` row with no `work_unit_opened` row is completed by the recovery scan via idempotent open) · `test_resumed_work_unit_reuses_pinned_items` (recovery re-evaluates the `item_ids` pinned at open) · `test_same_occurrence_deduped` (retry/replay of one occurrence ⇒ one event, one Beta update, `deduped=True`) · `test_repeat_measurement_not_deduped` (same skill/items/outcome in a new dispatch ⇒ two events, two Beta updates — the round-1 regression) · `test_unregistered_occurrence_rejected` (invented provenance ⇒ `rejected_reason` set, `rejected_ingest` logged with full payload, re-association succeeds) · `test_rejected_payload_pruned_after_window` (an unre-associated payload prunes to hash after `w_rejected`; the row persists) · `test_admin_events_exempt_but_powerless` (exempt record classes — incl. `dispatch` — cannot move any posterior) · `test_held_out_item_ids_not_solve_readable` (no SOLVE-side read path surfaces held-out `item_ids` from `work_unit_opened`/`evals` rows — P1 at the store boundary) · `test_open_rejection_contract` (a bad `intent_key` raises `UnknownIntentKey`, never returns a `WorkUnit`) · `test_solve_candidate_cannot_import_unredacted_truth` (M3: the admission import-check rejects a SOLVE candidate referencing the unredacted adapter) · `test_first_dispatch_upsert_race` (concurrent first dispatches for a new `(agent,episode,suite)` key yield gapless distinct `seq`).
*Projection writes (§6.2):* `test_rebuild_idempotent` (replaying truth twice ⇒ identical posteriors and projections) · `test_rebuild_routes_through_merge` (rebuild == incremental result) · `test_concurrent_extract_single_merge` (overlapping extract batches merge without duplicates) · `test_merge_never_assigns_liveness` (a delta node without `provision_suite` status is rejected) · `test_semantic_merge_single_event` (a `g.maybe_merge()` firing yields one truth event whose replay updates both projections) · `test_merge_report_shows_inverses` (dedup/merge/retire/update visible, not silent) · `test_embedded_merge_atomic_swap` (reader never observes a half-applied delta).

---

## 7. Dependencies (optional extras — heavy deps never forced)

```
mdlp[stores]            # embedded tier: numpy, networkx, (faiss-cpu | sqlite-vec)   ← default
mdlp[postgres]          # psycopg
mdlp[mongo]             # pymongo
mdlp[qdrant]            # qdrant-client     (or [pgvector] / [milvus])
mdlp[neo4j]             # neo4j
mdlp[redis]             # redis
mdlp[langfuse]          # ObservabilityPort full tier — §11 (autonomy profile)
mdlp[clickhouse]        # AnalyticsStore full tier — §11 (autonomy profile)
mdlp[full]              # all of the above — the complete 5-store hybrid
```
`app/` (the control plane) never imports any of this; the data layer is part of the opt-in `mdlp` package.

---

## 8. How the algorithm consumes it (dependency injection)

The algorithm modules depend only on the **ports**, never a concrete DB:
```python
class EvolutionLoop:                                  # the §6 orchestrator — a JUDGE member (§17.1)
    def __init__(self, bundles: Bundles, ...):
        j = bundles.judge                              # unredacted: BACKUP/COMMIT/eval writes
        self.truth, self.state, self.graph, self.cache = j.truth, j.state, j.graph, j.cache
        self.retriever = Retriever(bundles.solve)      # everything SOLVE-visible (§5.2/§16 retrieve,
                                                       # incl. R1 modes) sees only the RedactedTruthView
    # SELECT reads cache/graph/vector (hot); BACKUP writes truth/state/graph (cold);
    # GROW clusters via vector + adds to graph; COMMIT appends to truth + invalidates cache.
```
Swap the whole storage substrate by passing a different `Stores` bundle — the loop is unchanged. (This is also what makes the stores independently testable: the M0 tests run against the embedded tier; a nightly job can run the same suite against the full tier.)

---

## 9. Staging (so the 5-store stays evidence-gated)

- **M0:** embedded tier only. Prove the loop measures truth (held-out competence) with SQLite + networkx + a local vector index. No external DB.
- **M1:** if/when the skill graph and embedding corpus outgrow in-proc — flip `graph → neo4j` and/or `vector → qdrant`, leaving the rest embedded. The competence field's growth is the trigger to flip `state → mongo`.
- **Scale/prod:** the full tier via `mdlp[full]`, wired by config; `rebuild_all` migrates existing truth into it.

**Honest tradeoff:** the full five-store hybrid is real operational weight (five services to run, monitor, back up). The library makes that weight *opt-in and per-role*, so you pay it exactly when data justifies it — which is the only way the original paper's architecture is defensible in practice.

---

## 10. Standalone-library option

`mdlp/stores/` is written to depend on nothing else in `mdlp` (only `ports.py` + `schemas.py`), so it can be **extracted as a standalone package** `pathway-stores` — a reusable "pluggable hybrid datastore for probabilistic-pathway / learner-state systems" usable beyond this project. If you want the 5-store model as a *general* library (not tied to the agent algorithm), build it under `mdlp/stores/` first, then lift it out once its interface stabilizes.

---

*Companion: `IMPLEMENTATION.md` (§1 layout, §8 data binding) — this doc expands `stores/` into the full hybrid. Build order: embedded tier during M0 (it's required), full-tier adapters added per-role under the M1/scale evidence gate.*

---

## 11. Observability & analytics roles — the autonomy profile *(added 2026-07-30, revised r8 — IN GATE)*

*Two opt-in roles for unattended operation (ALGORITHM §20 / milestone M-R). **Never part of the default install** — `pip install mdlp` stays zero-infra (L-010); the autonomy deployment profile flips both on by config, exactly like the full-tier stores. Provenance: the studied autonomy failure mode this closes is shipped-but-inert observability (`STUDY-automaton-autonomy.md` avoid-list A2 — a stuck agent that looks alive); the delivery/`[SILENT]` patterns are hermes-verified (`STUDY-hermes-agent.md` §3.5).*

### 11.1 The two roles

| Role | Holds | Path | Consumers |
|---|---|---|---|
| **ObservabilityPort** | traces — one per §6.1 `dispatch`, with model-call cost/latency as `kind=span` entries — and scores (gate decisions, calibration tuples) | 🧊 cold — emit-and-forget | §20.7 passive-informing digests; humans auditing an unattended run after the fact |
| **AnalyticsStore** | a **columnar, rebuildable projection** of TruthStore | 🧊 cold | §19 calibration-tuple queries; difficulty-stratified reporting (M1-EVAL-PROTOCOL); fleet dashboards (§18) |

### 11.2 Ports

```python
class ObservabilityPort(Protocol):
    def trace(self, correlation_id: str, kind: str, payload: dict) -> None: ...   # correlation_id REQUIRED
    def score(self, correlation_id: str, name: str, value: float) -> None: ...
    def flush(self) -> None: ...

class InferenceClient(Protocol):                              # Stores.inference — both bundles (§2.1)
    def complete(self, model: str, request: dict) -> dict: ...
    # `model` is a key into the JUDGE-configured provider REGISTRY — never a URL/endpoint:
    # the broker resolves it against its own registry and relays nowhere else
    # (test_broker_relays_only_to_registered_providers). Destination is JUDGE-pinned,
    # not SOLVE-suppliable — the open-relay/exfiltration path is closed by construction.

class AnalyticsStore(Protocol):
    def ingest(self, rows: list[dict]) -> None: ...
    def query(self, q: str, params: dict | None = None) -> list[dict]: ...
    def rebuild(self, truth: TruthStore) -> None: ...          # = rebuild_analytics (§6)
```

**Three invariants, all load-bearing:**
1. **All observability is JUDGE-authored; SOLVE emits nothing (r4).** Every `trace` and `score` row is written by a JUDGE component — the §6 orchestrator, which *runs* SOLVE and therefore observes every dispatch, tool call, and outcome from the outside (the §17.6 `component_invoked` pattern, generalized: JUDGE observing SOLVE, never SOLVE reporting on itself). **Model-call spans included (r5):** SOLVE makes model calls only through the **JUDGE-composed inference client** the orchestrator hands it — the same pattern as the `Stores` bundle (§2.1): a SOLVE-unswappable object, wired outside every SOLVE-editable surface (§17.1's mutable SOLVE list is prompts/tool-wiring/heuristics/retrieval-config; the inference *transport* is harness). **The enforcement is credential custody, stated buildably (r7):** the SOLVE-side `InferenceClient` (the `Stores.inference` field, §2.1; Protocol in §11.2) is a **forwarding proxy** — it relays requests over an authenticated local channel to a **JUDGE-side broker** that alone holds the provider credentials and makes the actual network call, emitting the span as it does. **The broker is a named JUDGE member (r8):** §17.1's wall extends to it exactly as §20.8 extended it to the supervisor shell — it runs in the JUDGE address space alongside the orchestrator (and inherits §17.1's separate-address-space runtime backstop at M3); it is not a bare "JUDGE-side" label but a component on the JUDGE enumeration, holding the credentials the whole design protects. **The channel's authentication is named (r8):** a Unix-domain socket with OS peer-credential verification plus a per-session token compared constant-time (the pattern production systems ship for exactly this — `STUDY-hermes-agent.md` §5's PTC channel); granularity is honestly **process-level** — it authenticates the sandboxed SOLVE process, not an in-process object, which is an access-control statement only: metering is unconditional at the broker regardless of which code in the SOLVE process called. So the wall is not an import list: **provider keys never exist in the SOLVE process**, and a generic networking import that dials a model endpoint directly simply cannot authenticate (`test_solve_process_holds_no_provider_credentials`). Two supplementary guards, each honestly scoped: **Stage 1** — the §17.3 sandbox is extended here to deny network egress at the process level, which network controls *can* enforce (an *extension* of §17.3's stated scope, exactly as the no-read-of-JUDGE-dirs clause extends it); **Stage 2 / live SOLVE** — the M3 admission import-check additionally bans raw model-provider SDK/transport imports as defense-in-depth (`test_solve_cannot_import_raw_provider_sdk`) — depth behind the credential wall, not the wall itself. Pre-M3 there is no `self_modify` and SOLVE code is harness-authored — the concern this closes is M3-scoped. `kind=span` cost/latency rows are emitted **transport-side** — a `self_modify` candidate can change *which* calls it makes, never *whether they are metered* (`test_spans_captured_transport_side`). Honest bound, unchanged: §20.6/§20.7's liveness-critical signals depend only on dispatch/outcome Truth rows, never on span data. The **solve bundle carries no ObservabilityPort at all** — which closes the three surfaces by construction rather than by mediation: (a) **emit** — there is no SOLVE emit path to mediate (r3's "SOLVE-side traces" are retracted; that design would have been the artifact's only SOLVE-authored write into JUDGE territory, a wall §17.1 has no mechanism to police for plain method calls on the single-process embedded tier); (b) **query** — `AnalyticsStore` is absent from the solve bundle by composition (§2.1), and the M3 admission import-check that bans the unredacted `TruthStore` adapter (§6.1) bans the analytics and observability adapters identically; (c) **backing files** — the JSONL trace file and admin-event rows live in the JUDGE data directory, to which SOLVE code has no read path **at any stage (r5)**: the Stage-1 sandbox has no read mount (§17.3's "no write access outside SOLVE" extended explicitly: no *read* access to JUDGE data dirs), and live Stage-2-promoted SOLVE holds the same solve bundle and passed the same admission import-ban — the composition-level exclusion is stage-independent because both the bundle wiring and the admission check precede every stage. **Honest scope:** the file surface holds because SOLVE never writes observability data — this is *stronger* than §6.1's TruthStore treatment (which must mediate legitimate SOLVE reads), not merely parallel to it.
2. **No correlation id, no event — and the id is typed (r8):** `correlation_id` is discriminated by the trace `kind`: work-scoped events carry the §6.1 `occurrence_id`, commit-scoped ones the `checkpoint_id`, schedule-scoped ones the `schedule_id` — one field, kind-determined referent, so joins are unambiguous. Every `trace`/`score` call names the §6.1 `occurrence_id` (or `checkpoint_id`/`schedule_id`) it belongs to — an event that cannot be joined to the work that caused it is noise, not observability (the studied system's audit log dropped its join key at the sole call site and became un-joinable forever).
3. **Observability can never take the system down.** Emit failures are swallowed and *counted* (a failure counter is itself surfaced via §20.7); no emit sits on the §6 hot path; `flush()` is called at cycle boundaries only; the emit buffer is **bounded** at `B_obs` entries — overflow drops oldest-first and the drop count is itself surfaced via §20.7 (bounded loss, never unbounded memory; `test_emit_buffer_bounded_drops_counted`).

### 11.3 Tiers

| Role | Embedded (default when the profile is on) | Full tier |
|---|---|---|
| ObservabilityPort | Truth administrative events (`trace`/`score` kinds, §5) + a JSONL trace file | **Langfuse** (self-hosted, Apache-2.0) |
| AnalyticsStore | SQLite views over Truth | **ClickHouse** (Apache-2.0) |

Config per role, as §4; extras `mdlp[langfuse]` / `mdlp[clickhouse]` (§7). Note: self-hosted Langfuse v3 ships ClickHouse in its own stack — one deployment can back both roles, in **separate databases/schemas** (the AnalyticsStore projection never writes into Langfuse's tables or vice versa). **Canonical-record rule:** where a Truth record already exists (e.g. the §19.1 calibration tuple), `score()` mirrors it for legibility — Truth remains the canonical copy and the only one anything statistical reads; the observability copy is disposable.

### 11.4 Discipline

- **AnalyticsStore is a projection.** The §6 identity extends unchanged: truth canonical, analytics rebuildable (`rebuild_analytics(truth)`, listed in §6's rebuild block). Dropping and rebuilding it is always safe; it is never a write-path for anything.
- **`trace`/`score` are administrative record classes** (§6.1 exemption list — they move no posterior, checkable by the same update-path property).
- **P1 across exports (r4):** traces are JUDGE data and SOLVE cannot read them (invariant 1) — the residual P1 surface is **human-facing exports**: §20.7 digests and any full-tier export (Langfuse) pass held-out redaction (aggregates and outcomes, never held-out `item_ids`/content), so an unattended run's reports cannot become a leak channel for the very items the run is measuring.

**Register scope note:** like §6.1/§6.2 (this document's other gated deltas), §11 is data-layer design, not an ALGORITHM-INTEGRATIONS capability — by that precedent it carries no BUILD-SPECS item; its build stubs live below.

### 11.5 Tests (build stubs)

`test_default_config_needs_no_observability_deps` (profile off ⇒ importing `mdlp.stores` pulls neither langfuse nor clickhouse) · `test_analytics_rebuildable_from_truth` (drop + `rebuild_analytics` ⇒ identical query results; embedded tier: the SQLite views re-derive from Truth tables) · `test_stores_inference_shape_both_bundles` (`Stores.inference` present and `InferenceClient`-typed in both bundles) · `test_broker_relays_only_to_registered_providers` (a `model` key outside the JUDGE registry is refused; no URL/endpoint parameter exists) · `test_emit_buffer_bounded_drops_counted` · `test_emit_failure_never_blocks` (a raising backend ⇒ work completes) · `test_emit_failures_counted_and_surfaced` (the failure counter increments and reaches the §20.7 digest even when the backend keeps raising — counting must not depend on the failing emitter) · `test_event_without_correlation_id_rejected` · `test_solve_bundle_has_no_observability_or_analytics` (the solve `Stores` composition carries neither field; the M3 admission import-check rejects a SOLVE candidate importing the observability or analytics adapters — mirroring `test_solve_candidate_cannot_import_unredacted_truth`) · `test_all_observability_rows_judge_authored` (every `trace`/`score` row's emitter is the orchestrator/eval-harness call path; no SOLVE call site exists — the r4 no-SOLVE-emission regression) · `test_solve_cannot_read_observability_backing_any_stage` (neither a §17.3 Stage-1 sandboxed candidate nor live Stage-2-promoted SOLVE can open the JSONL trace file or the admin-event rows) · `test_spans_captured_transport_side` (a SOLVE component cannot issue a model call that produces no span — metering is in the JUDGE-composed client, not in SOLVE) · `test_solve_cannot_import_raw_provider_sdk` (the M3 admission check rejects a SOLVE candidate statically importing a model-provider SDK/transport — defense-in-depth behind the credential wall) · `test_solve_process_holds_no_provider_credentials` (no provider key material is readable from the SOLVE process/sandbox environment; a direct endpoint call cannot authenticate — the r7 load-bearing egress regression) · `test_digest_redacts_held_out` (a §20.7 digest / full-tier export of an eval run carries aggregates, never held-out `item_ids`) · `test_analytics_never_a_write_path` (no store mutation reachable through AnalyticsStore).
