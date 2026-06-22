# Activating the autonomous curator daemon

The framework already learns and evolves **inside your sessions** with zero effort from you. This document is only about the extra step that lets it also evolve **while you're away** — a true background process that runs even when no Claude session is open.

## Why this needs your explicit go-ahead

The background daemon runs Claude **headless and non-interactively**. With no human present to approve each step, it runs with relaxed permissions (`--dangerously-skip-permissions` inside `scripts/evolve.sh`). That is a real tradeoff, so it is **off by default** and Claude will not enable it for you automatically — Claude Code's safety system blocks an assistant from wiring an always-on, self-approving agent loop on its own. You enable it deliberately, here.

**What contains the risk:**
- The curator's INVARIANTS forbid it from touching your **source code** — only `.claude/`, `skills/`, `docs/`, memory, and the framework's own docs.
- It stages commits **by explicit path** (never `git add -A`), so your uncommitted work is never swept in.
- Every change is an atomic `evolve:` git commit — **revert anything** with `git revert`.
- Instant pause: `touch .claude/daemon/DISABLED` (the daemon exits immediately on its next tick).
- It runs on the cheaper `sonnet` model and **no-ops when there's no new session activity**, so an idle machine costs nothing.

**Residual risk to accept:** a headless agent with shell access, ingesting session text, is a prompt-injection surface. Keep it scoped to this project; the kill-switch and git history are your safety net.

## Option A — the always-on daemon (launchd, runs even when away)

One command — it generates a correctly-pathed launchd job for this machine and loads it:

```bash
scripts/install.sh --daemon
```

Verify / disable later:
```bash
launchctl list | grep turing-agents
launchctl unload ~/Library/LaunchAgents/com.turing-agents.curator.*.plist
rm ~/Library/LaunchAgents/com.turing-agents.curator.*.plist
```

## Option B — evolve at session end only (lighter, no always-on process)

Add this `SessionEnd` hook to `.claude/settings.json` under `"hooks"` so the curator flushes each session when it ends (you'll be asked to approve the Bash permission once):

```json
"SessionEnd": [
  { "hooks": [ { "type": "command",
      "command": "nohup bash \"$CLAUDE_PROJECT_DIR/scripts/evolve.sh\" >/dev/null 2>&1 &" } ] }
]
```

## Option C — run it yourself, when you want

```bash
scripts/evolve.sh        # digest new sessions + evolve, right now
```

## Either way, nothing changes about your workflow

You keep building. The curator's digests land in `EVOLUTION-LOG.md` and the SessionStart banner. If it ever drifts, say *"we're going in the wrong direction"* and the course-corrector will diagnose and fix it.
