#!/usr/bin/env bash
# Replace rofi-wayland with rofi, which absorbed its wayland support
#
# The lists moved to rofi on 2026-09-26 (9681baa). rofi replaces and provides rofi-wayland, so the
# installer sees rofi as present while rofi-wayland is still the package installed; a full upgrade
# usually swaps them, this covers a declined or skipped swap.

swap_package rofi-wayland rofi
