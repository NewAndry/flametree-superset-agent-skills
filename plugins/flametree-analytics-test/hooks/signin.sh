#!/usr/bin/env bash
# Claude Code hook (SessionStart, UserPromptSubmit) shipped in every stand plugin.
# When the plugin's MCP server is not signed in yet, it opens `claude mcp login` in a separate
# terminal window, which opens the Flametree portal sign-in in the browser, and tells Claude so.
# A running session does not reconnect a server that needed sign-in at its start (neither
# /reload-plugins nor re-enabling the plugin helps), so after the sign-in a new session is needed.
# Cheap when signed in: the status is cached for 12 hours, a sign-in window opens at most every
# 5 minutes. build_plugins.py replaces plugin:flametree-analytics-test:flametree-test with the stand's server id.
SERVER="plugin:flametree-analytics-test:flametree-test"

STATE="${TMPDIR:-${TEMP:-/tmp}}/flametree-signin-$(printf '%s' "$SERVER" | tr ':/' '__')"
now=$(date +%s)
age() { [ -f "$1" ] && echo $((now - $(cat "$1" 2>/dev/null || echo 0))) || echo 999999; }

[ "$(age "$STATE.ok")" -lt 43200 ] && exit 0
[ "$(age "$STATE.opened")" -lt 300 ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0
# SessionStart and the first prompt can fire together; only one of them may open a window.
mkdir "$STATE.lock" 2>/dev/null || exit 0
trap 'rmdir "$STATE.lock" 2>/dev/null' EXIT

case "$(claude mcp get "$SERVER" 2>&1)" in
  *Connected*) echo "$now" > "$STATE.ok"; exit 0 ;;
  *"Needs authentication"*) ;;
  *) exit 0 ;;
esac

echo "$now" > "$STATE.opened"
login="claude mcp login $SERVER"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # A .cmd file avoids Git Bash re-quoting arguments on their way to cmd.exe.
    bat="$STATE.cmd"
    # `start` keeps a batch window open (cmd /k), so the file ends with `exit`.
    printf '@echo off\r\ntitle Flametree sign-in\r\n%s\r\nif errorlevel 1 pause\r\nexit\r\n' "$login" > "$bat"
    cmd.exe //c start "" "$(cygpath -w "$bat")" >/dev/null 2>&1 ;;
  Darwin) osascript -e "tell application \"Terminal\" to do script \"$login\"" >/dev/null 2>&1 ;;
  *)
    if command -v x-terminal-emulator >/dev/null 2>&1; then (x-terminal-emulator -e $login >/dev/null 2>&1 &)
    elif command -v gnome-terminal >/dev/null 2>&1; then (gnome-terminal -- $login >/dev/null 2>&1 &)
    else
      echo "Flametree: $SERVER is not signed in. Ask the user to run /mcp, pick $SERVER and choose Authenticate."
      exit 0
    fi ;;
esac
echo "Flametree: $SERVER was not signed in, so a terminal window with the Flametree portal sign-in"      "has just been opened for the user. Tell the user to finish the sign-in in the browser"      "(with an active portal session it completes by itself) and then to open a new Claude Code"      "session: a running session does not pick up the sign-in. Do not send them to /mcp."
