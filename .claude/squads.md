# Squads — who does what

The squad registry the `dispatcher` (squad leader) routes by. A squad is a group of teammates (agents) led by a leader that delegates. Keep routing to the **narrowest fitting specialist**; if none fits, the dispatcher assigns `@you` or asks `agent-smith` to build the missing teammate.

## Framework squad (the meta-team — present from day one)

Leader: `curator` · Members:

| Task type | Teammate |
|---|---|
| Profile / understand the project | `scout` |
| Write a reusable playbook | `skill-smith` |
| Build a new specialist agent | `agent-smith` |
| Find external tools / connectors | `plugin-researcher` |
| Extract lessons / self-improve | `retrospective` |
| Diagnose drift / re-steer | `course-corrector` |

## Project squad (grows as the project does)

Leader: `dispatcher` · Members: _none yet — `agent-smith` adds specialists here as recurring project task-types appear._

| Task type | Teammate |
|---|---|
| _e.g. "build a feature"_ | _(none yet — assign @you or have agent-smith build `feature-builder`)_ |
| _e.g. "review a change"_ | _(none yet)_ |
| _e.g. "run / fix tests"_ | _(none yet)_ |

---

_How the project squad grows: when the same kind of task recurs (≥3×), `retrospective`/`curator` has `agent-smith` build a specialist for it, and adds the row here. Until then the dispatcher routes that task type to `@you`. This is evidence-gated team growth — no specialist exists until real work needs it._
