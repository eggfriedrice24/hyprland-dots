#!/usr/bin/env bash
# Replace swww with awww where the upgrade left it, and drop swww's wallpaper cache
#
# The wallpaper daemon switched to awww on 2026-06-04 (1177b1c). awww replaces swww, so a full
# upgrade usually swaps them; this covers a declined or skipped swap. ~/.cache/swww is swww's
# per-output cache, which awww does not read (it keeps its own in ~/.cache/awww).

swap_package swww awww
remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/swww"
