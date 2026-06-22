#!/usr/bin/env bash
# install.sh — set up Turing Agents for THIS project on THIS machine.
#
#   scripts/install.sh             make scripts executable, init the daemon watermark,
#                                  and print status (safe; no background process)
#   scripts/install.sh --daemon    additionally generate + load the always-on launchd
#                                  curator daemon (opt-in; runs Claude headless).
#
# Portable: derives all paths from where it lives. No hardcoded user paths.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LA_DIR="$HOME/Library/LaunchAgents"
TEMPLATE="$ROOT/scripts/launchd/curator.plist.template"

SLUG="$(basename "$ROOT" | tr ' ' '-' | tr -cd '[:alnum:]-_' | tr '[:upper:]' '[:lower:]')"
LABEL="com.turing-agents.curator.$SLUG"
PLIST="$LA_DIR/$LABEL.plist"

CLAUDE_BIN="$(command -v claude || true)"
[ -z "$CLAUDE_BIN" ] && [ -x "$HOME/.local/bin/claude" ] && CLAUDE_BIN="$HOME/.local/bin/claude"
CLAUDE_DIR="$(dirname "${CLAUDE_BIN:-$HOME/.local/bin/claude}")"

echo "Turing Agents — install"
echo "  project: $ROOT"
echo "  claude : ${CLAUDE_BIN:-NOT FOUND (headless evolution will be disabled)}"

# 1. scripts executable + daemon dirs
chmod +x "$ROOT"/scripts/*.sh 2>/dev/null || true
mkdir -p "$ROOT/.claude/daemon/runs" "$ROOT/.claude/daemon/autopilots"
[ -f "$ROOT/.claude/daemon/watermark" ] || touch "$ROOT/.claude/daemon/watermark"
echo "  ✓ scripts executable; daemon state initialized (watching from now)"

if [ "${1:-}" = "--daemon" ]; then
  [ -f "$TEMPLATE" ] || { echo "  ✗ template missing: $TEMPLATE"; exit 1; }
  [ -z "$CLAUDE_BIN" ] && { echo "  ✗ claude CLI not found — cannot run the headless daemon."; exit 1; }
  mkdir -p "$LA_DIR"
  sed -e "s#__LABEL__#$LABEL#g" \
      -e "s#__PROJECT_DIR__#$ROOT#g" \
      -e "s#__CLAUDE_DIR__#$CLAUDE_DIR#g" \
      "$TEMPLATE" > "$PLIST"
  echo "  ✓ generated $PLIST"
  echo ""
  echo "  ⚠  The daemon runs Claude headless with relaxed permissions (it only edits"
  echo "     framework files, never your source). This is the opt-in step."
  echo "     Loading now..."
  launchctl unload "$PLIST" 2>/dev/null || true
  if launchctl load "$PLIST" 2>/dev/null; then
    echo "  ✓ daemon loaded ($LABEL). It evolves the framework every ~25 min."
    echo "    pause:  touch $ROOT/.claude/daemon/DISABLED"
    echo "    remove: launchctl unload $PLIST && rm $PLIST"
  else
    echo "  ✗ launchctl load failed. Generated plist is at $PLIST — load it manually."
  fi
else
  echo ""
  echo "  Evolution runs inside your sessions by default."
  echo "  For always-on background evolution (even while away):  scripts/install.sh --daemon"
fi
