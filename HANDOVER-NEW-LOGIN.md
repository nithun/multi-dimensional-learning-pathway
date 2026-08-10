# Handover: Claude login change

**Written:** 2026-07-30, immediately before switching the Claude account used to operate this project.

**This file is operational** — what breaks when the login changes, what to re-establish, and how to verify. For *project* state (where the research stands, what to work on next), read **`CONTINUE-HERE.md`** — that's the substantive brief. Read this one first, once, then go there.

---

## 1. The three buckets

Everything in this project falls into one of three categories. Knowing which is which prevents both wasted effort and nasty surprises.

### ✅ Survives the login change — in git, nothing to do
All project substance is version-controlled and pushed (`origin/main`):
- The spec of record, all build specs, the data layer, the paper, the four external studies, `HANDOVER-v3.md`, and the complete review/decision audit trail under `docs/research/`.
- The framework itself: `.claude/agents/` (10 agents incl. `review-360`/`change-approver`), `skills/`, `scripts/`, `.claude/squads.md`, `CLAUDE.md`, `WORKFLOW.md`.
- **Framework memory:** `.claude/memory/project-profile.md`, `lessons.md` (L-001…L-014), `patterns.md`, `glossary.md`, `interactions.jsonl` (IX-001…IX-046), `evolution-log.jsonl` (EV-001…EV-092), `circuit-breaker.json`, `backlog.md`.
- **Hooks:** `.claude/settings.json` (SessionStart → `scripts/orient.sh`; Stop → `scripts/reflect-hook.sh`) is committed and will fire under any login.

### ⚠️ Does NOT survive — Claude-account-bound, must be re-established
| What | Impact | Action |
|---|---|---|
| **User-level memory store** (`~/.claude/projects/<slug>/memory/`) | Held the scope rule. New account = empty. | Rescued verbatim to `.claude/memory/user-memory-scope-mdlp-only.md` — re-save it as a user memory in the new login (§3). Substance is already enforced as **L-012**, so nothing is lost either way. |
| **Session transcripts** (`~/.claude/projects/<slug>/*.jsonl`) | The `curator` agent digests these to reconstruct interactions. A fresh account has none — **the conversational history of this project is not recoverable under the new login.** | Nothing to fix. This is *why* `interactions.jsonl` + `CONTINUE-HERE.md` exist — the durable record is in the repo. Don't ask the curator to "catch up on past sessions"; there are none to read. |
| **MCP server OAuth** (github, notion, linear, slack, atlassian, figma, datadog, …) | All show as needing auth. None were used for this project's work. | Re-authorize only if you actually need one. **Not required** for MDLP work. |
| **Headless `claude` auth** (used by the curator daemon) | Already failing `401 OAuth access token has been revoked` — plausibly *because* of this login change. | See §4 — the daemon is formally dropped; re-check only if you want to revive it. |
| **Available skills/plugins & model access** | The skill list is account/plugin-bound and shifted several times during the last session. | Nothing to do. No MDLP workflow depends on an optional skill — the gate runs on `.claude/agents/`, which is in the repo. |

### 🖥️ Machine-local (survives a login change on *this* Mac, but is **not** in git)
These are gitignored — they persist on this machine, and would be lost on a *machine* change:
- `.claude/settings.local.json` — local permission allowlist.
- `.claude/daemon/watermark`, `runs/`, `*.log`, `.lock` — curator daemon runtime state.
- `.claude/memory/triage.json` — recomputed every interaction, safe to lose.
- `.claude/memory/chats/` — a framework leftover, deliberately never committed.
- **macOS Full Disk Access** for the terminal/Claude app — per-application, not per-account.

---

## 2. First ten minutes under the new login

Run these from the project root and confirm each:

```bash
git status -sb && git rev-list --count origin/main..main   # expect: clean (bar chats/), 0 unpushed
git log --oneline -3                                       # expect: 5c94514 CONTINUE-HERE at or near HEAD
git config user.name && git config user.email              # expect: Nithun / nithunram@gmail.com (git, not Claude — unchanged)
ls .claude/agents/ && ls skills/                           # expect: 10 agents, spec-change-gate skill
wc -l .claude/memory/interactions.jsonl                    # expect: 46 lines (IX-001…IX-046)
```

The **SessionStart hook** should print the orientation banner (project line, lesson count, backlog, circuit-breaker lanes) with no `Operation not permitted` error. If the banner is missing, `scripts/orient.sh` didn't run — check the terminal has Full Disk Access to `~/Documents`.

Then read **`CONTINUE-HERE.md`** end to end. That is the real handover.

---

## 3. Re-establish the scope memory (one paste, 30 seconds)

The single most consequential thing that was in the old account's memory. Re-save it in the new login so it's enforced at the account level too:

> **Scope: MDLP only.** My management scope is only `/Users/samyoga/Documents/Claude/Projects/Multi-Dimensional Learning Pathway`. The `/Users/samyoga/dev/turing-agents` repo is **not** mine to manage — it is the user's own research implementation with its own framework. Never write to, modify, or run git in it under any circumstances — not even if a doc (e.g. a HANDOVER) points builders there; the user is the builder there. Deliverables *about* that implementation stay in this repo (`docs/research/`), and the user carries them across manually.

Full original at `.claude/memory/user-memory-scope-mdlp-only.md`. It is also **L-012** in `lessons.md`, which every agent reads first — so the rule holds even if you skip this step.

---

## 4. Known-broken, already decided — don't re-litigate

**The curator daemon is dropped** (backlog `B-002`, closed 2026-07-30 on the user's instruction after a real retry). Evidence, so the new login doesn't repeat the investigation:
- The script itself is fine — exec bit, locking, and watermarking all work; a manual run completes cleanly.
- The headless `claude` call fails: `401 OAuth access token has been revoked` (`.claude/daemon/runs/20260730-125739.log`).
- The launchd path additionally fails with `Operation not permitted` — macOS TCC blocking `~/Documents`, fixable only by granting Full Disk Access.
- Both fixes are user-only. **Decision: in-session evolution only** — which is the mode every successful evolution cycle has actually used (all retrospectives, all scout passes, all gate cycles).
- To revive it under the new login: re-auth headless `claude`, grant Full Disk Access, then `scripts/install.sh --daemon` and confirm a clean run log. Reopen B-002 only if you do this.

**Also settled, don't redo:** the 2026-07-28 TA audit findings (six bugs, built-but-unwired constructs, toy-corpus ceiling) are recorded in `CONTINUE-HERE.md` §3 and `project-profile.md` — read them rather than re-auditing. `B-004` is closed: proposals + user-mediated delegation is the permanent handoff mechanism for the retrospective agent.

---

## 5. What needs *no* action

- **Git/GitHub** — authentication is independent of the Claude login; the remote and identity are unchanged.
- **The two-stage gate** — `review-360` and `change-approver` live in `.claude/agents/`, in the repo. They work immediately.
- **Hooks** — committed in `.claude/settings.json`.
- **The framework's read-first protocol** — `CLAUDE.md` now points new sessions at `CONTINUE-HERE.md` first.
- **Pending work** — nothing is mid-flight. The last session ended with both AUT specs approved, committed, and pushed; the working tree is clean.

---

## 6. Handover checklist

- [ ] Verified git state clean and synced (§2)
- [ ] SessionStart banner appears without permission errors (§2)
- [ ] Re-saved the scope memory, or consciously relying on L-012 (§3)
- [ ] Read `CONTINUE-HERE.md` (project state, hard rules, next moves)
- [ ] Understood that prior conversational history is gone by design — the repo is the record (§1)
- [ ] Decided whether to revive the daemon (§4) — default is *no*
- [ ] Optional cleanup: `git branch -d research/external-repo-study-2026-07-13` (fully merged)

---

*Companion files: `CONTINUE-HERE.md` (project state — read this next) · `CLAUDE.md` (framework protocol) · `.claude/memory/lessons.md` (L-001…L-014, the standing rules) · `docs/research/HANDOVER-v3.md` (the handover to the turing-agents implementation — a different document for a different audience).*
