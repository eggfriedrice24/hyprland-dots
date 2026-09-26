#!/usr/bin/env sh
# Toggle game mode: animations, blur, gaps and rounding off; run again to restore.
# The Lua config manager rejects `hyprctl keyword`, so values go through `hyprctl eval`.
# Restored values mirror hyprland.lua.

enabled=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')

if [ "$enabled" = "true" ]; then
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { rounding = 0, blur = { enabled = false } },
        general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })' >/dev/null
    notify-send -a "Game mode" -u low "Game mode on"
else
    hyprctl eval 'hl.config({
        animations = { enabled = true },
        decoration = { rounding = 3, blur = { enabled = true } },
        general = { gaps_in = 5, gaps_out = 0, border_size = 0 },
    })' >/dev/null
    notify-send -a "Game mode" -u low "Game mode off"
fi
