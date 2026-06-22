# autopilots/ — recurring routines

Named, recurring units of work the team runs on a cadence — the framework's version of Multica's **autopilots**. The built-in "evolve" autopilot is the curator daemon itself (`scripts/evolve.sh`); the files here define *additional* routines (a weekly deep retrospective, a daily standup from the board, a monthly plugin-research sweep, …).

## Defining an autopilot

One file per autopilot, `autopilots/<name>.md`, with a small header then the prompt the routine runs:

```
# Autopilot: <name>
enabled: true            # false = defined but won't fire
cadence: 7d              # 30m | 12h | 7d — minimum gap between runs
agent: <agent-name>      # which teammate it drives (informational)
---
<the instruction the headless run executes — e.g. "Run the retrospective agent
for a full weekly sweep: audit the last 7 days of interactions, ...">
```

## Running them

- `scripts/autopilot.sh --list` — show all autopilots and whether each is due.
- `scripts/autopilot.sh <name>` — run one now.
- `scripts/autopilot.sh --due` — run every enabled autopilot whose cadence has elapsed.

`--due` is what the curator daemon (or launchd) calls each tick, so enabled autopilots fire on their own. Like the curator, autopilot runs honor the kill-switch (`.claude/daemon/DISABLED`) and are **opt-in** — they run Claude headless, so they only fire once you've enabled the background daemon (see `ACTIVATING-THE-DAEMON.md`) or invoke them by hand.

Per-autopilot last-run stamps live in `.claude/daemon/autopilots/` (git-ignored).
