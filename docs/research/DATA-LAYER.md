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
    def append_event(self, ev: Event) -> str: ...
    def record_eval(self, r: EvalResult, lineage: Lineage) -> str: ...
    def read_events(self, **filter) -> Iterator[Event]: ...
    def lineage(self, checkpoint_id: str) -> Lineage: ...     # what data trained what

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

class CacheStore(Protocol):
    def get(self, key: str): ...
    def set(self, key: str, val, *, ttl=None) -> None: ...
    def invalidate(self, checkpoint_id: str) -> None: ...      # drop stale-on-new-checkpoint

class ArtifactStore(Protocol):                                # M2
    def put_checkpoint(self, blob) -> str: ...
    def register(self, ckpt_id: str, lineage: Lineage, metrics: dict, stage: str) -> None: ...
    def gc(self, retention) -> None: ...
```

A `Stores` bundle (a dataclass holding one instance of each port) is what the algorithm receives.

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
stores = build_stores(load_config("mdlp.toml"))   # returns the Stores bundle, fully wired
```
Default (no config) = all embedded → `pip install mdlp` and run, no infra.

---

## 5. Record schemas (what lives where)

- **Truth (SQL):** `events(id, ts, type, payload, actor)`; `evals(id, ts, skill, difficulty, split{public|held_out}, n_pass, n_total, verifier, item_ids, checkpoint_id)`; `lineage(checkpoint_id, parent, dataset_id, eval_run_id)`.
- **State (Document):** `cell{skill, difficulty, context, mastery:{α,β}, drift:{α,β}, n_eff, updated_ts, checkpoint_id}` — extra dimensions added freely (schemaless = the open competence field).
- **Vector:** `{id, embedding, kind: skill|lesson|failure, skill_ref, text, meta}`.
- **Graph:** nodes `{skill, status: live|pending_human, suite_ref}`; edges `prereq{weight, confidence}`, `transition{visits, value}`; mcts `{node, visits, value, checkpoint_gen}`.
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
def rebuild_all(truth, stores): ...      # disaster recovery / backend migration
```
This is what makes the design safe: caches can be dropped and rebuilt; you can **migrate from embedded → full tier by pointing at a new backend and replaying truth**; and the learning layer stays an optional, rebuildable add-on over the canonical file logs (L-010). On any checkpoint change, `CacheStore.invalidate()` plus a tree-stat discount keep the hot path from serving stale state.

---

## 7. Dependencies (optional extras — heavy deps never forced)

```
mdlp[stores]            # embedded tier: numpy, networkx, (faiss-cpu | sqlite-vec)   ← default
mdlp[postgres]          # psycopg
mdlp[mongo]             # pymongo
mdlp[qdrant]            # qdrant-client     (or [pgvector] / [milvus])
mdlp[neo4j]             # neo4j
mdlp[redis]             # redis
mdlp[full]              # all of the above — the complete 5-store hybrid
```
`app/` (the control plane) never imports any of this; the data layer is part of the opt-in `mdlp` package.

---

## 8. How the algorithm consumes it (dependency injection)

The algorithm modules depend only on the **ports**, never a concrete DB:
```python
class EvolutionLoop:
    def __init__(self, stores: Stores, ...):
        self.truth, self.state, self.vec, self.graph, self.cache = (
            stores.truth, stores.state, stores.vector, stores.graph, stores.cache)
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
