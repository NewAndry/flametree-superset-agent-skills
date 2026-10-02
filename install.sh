#!/usr/bin/env bash
# Flametree Analytics MCP plugin installer for Claude Code (macOS, Linux).
#
#   curl -fsSL https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.sh | bash
#
# Stand: dev by default; pick another (prod, demo, test, dev):
#   curl -fsSL https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.sh | bash -s test
#
# 1. registers the marketplace and installs the stand's plugin (MCP server + skills);
# 2. opens a terminal window that runs `claude mcp login …` — the browser shows the
#    Flametree portal sign-in; with an active portal session it completes without clicks;
# 3. waits until the server reports Connected.
# Safe to re-run. Needs the `claude` CLI on PATH.
set -euo pipefail

REPO="https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills.git"
MARKETPLACE="flametree"
STAND="$(printf '%s' "${1:-${FLAMETREE_STAND:-dev}}" | tr '[:upper:]' '[:lower:]')"

case "$STAND" in
  prod) PLUGIN_NAME="flametree-analytics";      SERVER_NAME="flametree" ;;
  demo) PLUGIN_NAME="flametree-analytics-demo"; SERVER_NAME="flametree-demo" ;;
  test) PLUGIN_NAME="flametree-analytics-test"; SERVER_NAME="flametree-test" ;;
  dev)  PLUGIN_NAME="flametree-analytics-dev";  SERVER_NAME="flametree-dev" ;;
  *) echo "Unknown stand '$STAND'. Use one of: prod, demo, test, dev." >&2; exit 1 ;;
esac
PLUGIN="$PLUGIN_NAME@$MARKETPLACE"
SERVER="plugin:$PLUGIN_NAME:$SERVER_NAME"

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }

command -v claude >/dev/null 2>&1 || { echo "The 'claude' CLI is not on PATH. Install Claude Code first: https://code.claude.com/docs/en/desktop" >&2; exit 1; }

step "Stand: $STAND"
step "Marketplace '$MARKETPLACE'"
if claude plugin marketplace list 2>&1 | grep -q "$MARKETPLACE"; then
  claude plugin marketplace update "$MARKETPLACE" >/dev/null
else
  claude plugin marketplace add "$REPO" >/dev/null
fi

step "Plugin $PLUGIN"
claude plugin install "$PLUGIN" >/dev/null

if claude mcp list 2>&1 | grep -F "$SERVER" | grep -q Connected; then
  step "Already signed in"
else
  step "Sign-in: a terminal window and a browser tab with the Flametree portal login open now"
  login="claude mcp login $SERVER"
  if [ "$(uname)" = "Darwin" ]; then
    osascript -e "tell application \"Terminal\" to do script \"$login\"" >/dev/null
  elif command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator -e $login &
  elif command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- $login &
  elif [ -t 0 ]; then
    $login
  else
    echo "No terminal emulator found. Run in a terminal: $login" >&2
  fi
  connected=0
  for _ in $(seq 1 36); do
    sleep 5
    if claude mcp list 2>&1 | grep -F "$SERVER" | grep -q Connected; then connected=1; break; fi
  done
  if [ "$connected" = 1 ]; then step "Signed in"; else echo "WARNING: sign-in not completed within 3 minutes. Finish it in the opened window, or run: $login" >&2; fi
fi

echo
printf '\033[32mDone. Start a new Claude Code session (or run /reload-plugins) and ask Claude to list your Flametree tenants.\033[0m\n'
