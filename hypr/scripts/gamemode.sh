#!/usr/bin/env sh
# Toggle game mode: animations, blur, gaps and rounding off; run again to restore.
# The Lua config manager rejects `hyprctl keyword`, so values go through `hyprctl eval`.
# Off again reloads the config, so the restored look is always exactly what hyprland.lua says.

enabled=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')

if [ "$enabled" = "true" ]; then
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { rounding = 0, blur = { enabled = false } },
        general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })' >/dev/null
    notify-send -a "Game mode" -u low "Game mode on"
else
    hyprctl reload >/dev/null
    notify-send -a "Game mode" -u low "Game mode off"
fi
