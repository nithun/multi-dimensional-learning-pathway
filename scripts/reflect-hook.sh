#!/usr/bin/env bash
# reflect-hook.sh — Stop hook. Runs after EVERY assistant turn. Deterministic; no claude,
# no network, never blocks the session. It re-evaluates whether a re-profile (scout) or a
# retrospective is due and refreshes the triage flags — so the framework's reflective loop
# can never silently lapse again (the L-007 failure mode). The actual deep work stays with
# the curator / you; this only keeps "what's due" current, every interaction.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cat >/dev/null 2>&1 || true        # drain the hook payload on stdin
bash "$ROOT/scripts/triage.sh" >/dev/null 2>&1 || true
exit 0
