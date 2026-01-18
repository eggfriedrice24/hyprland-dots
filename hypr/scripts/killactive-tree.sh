#!/usr/bin/env bash

# Kill the entire process group for the currently active window.
info=$(hyprctl activewindow -j 2>/dev/null) || exit 0
pid=$(printf '%s' "$info" | jq -r '.pid // -1')

# Nothing to kill.
if [ "$pid" -lt 1 ]; then
  exit 0
fi

pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')

# Kill the process group if we have it, otherwise just the single PID.
if [ -n "$pgid" ]; then
  kill -KILL "-$pgid"
else
  kill -KILL "$pid"
fi
