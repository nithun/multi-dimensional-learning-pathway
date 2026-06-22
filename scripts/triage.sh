#!/usr/bin/env bash
# triage.sh — the deterministic "need analyzer": decides when a re-profile (scout) or a
# retrospective is DUE, from the accumulating interaction substrate. A cheap heuristic
# run every interaction (via the Stop hook) — NOT an agent. It only FLAGS; the curator
# (or you) runs the actual deep work. Writes .claude/memory/triage.json + prints a line.
#
#   triage.sh                 recompute + print the due flags
#   triage.sh --mark-retro    reset the retrospective baseline (call after a retro runs)
#   triage.sh --mark-profile  reset the deep-profile baseline (call after scout runs)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 - "$ROOT" "${1:-}" <<'PY'
import json, os, sys
root, mode = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
mem = os.path.join(root, ".claude", "memory")
ixf = os.path.join(mem, "interactions.jsonl")
evf = os.path.join(mem, "evolution-log.jsonl")
tj  = os.path.join(mem, "triage.json")
RETRO_N, PROFILE_N = 5, 8   # interactions since last, before "due"

def count(path, needle=None):
    if not os.path.exists(path):
        return 0
    n = 0
    for line in open(path, encoding="utf-8", errors="replace"):
        if line.strip() and (needle is None or needle in line):
            n += 1
    return n

state = {}
if os.path.exists(tj):
    try:
        state = json.load(open(tj))
    except Exception:
        state = {}

ix_count = count(ixf)
pending = count(evf, '"outcome":"pending"')

if mode == "--mark-retro":
    state["retro_baseline"] = ix_count
elif mode == "--mark-profile":
    state["profile_baseline"] = ix_count

since_retro = ix_count - state.get("retro_baseline", 0)
since_profile = ix_count - state.get("profile_baseline", 0)
# Due on accumulated NEW work since the last run only. (pending is informational —
# a fresh retrospective always leaves its own edits pending, so it must NOT trigger
# "due", or the loop never rests. Bug found by running the loop, 2026-06-22.)
retrospective_due = since_retro >= RETRO_N
reprofile_due = since_profile >= PROFILE_N

state.update({
    "ix_count": ix_count, "pending": pending,
    "since_retro": since_retro, "since_profile": since_profile,
    "retrospective_due": retrospective_due, "reprofile_due": reprofile_due,
})
json.dump(state, open(tj, "w"), indent=2)

flags = []
if retrospective_due:
    flags.append(f"retrospective DUE (since_retro={since_retro}, pending={pending})")
if reprofile_due:
    flags.append(f"re-profile DUE (since_profile={since_profile})")
print("triage: " + ("; ".join(flags) if flags else f"nothing due (ix={ix_count}, pending={pending})"))
PY
