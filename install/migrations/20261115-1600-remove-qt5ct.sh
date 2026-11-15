#!/usr/bin/env bash
# Remove qt5ct and its config: Qt apps follow the GTK theme through QT_QPA_PLATFORMTHEME=gtk3
#
# qt5ct left install/packages/hyprland.txt when hypr/env.lua switched the platform theme to gtk3.
# A machine installed before that still carries it. Without -c, pacman keeps qt5-base and qt5-svg
# when something else still needs them.

remove_packages qt5ct
remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct"
