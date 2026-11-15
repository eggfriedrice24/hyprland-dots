#!/usr/bin/env bash
# Replace the AUR fnm-bin and pnpm-bin with the fnm and pnpm repository packages
#
# Both -bin packages were in the first package lists on 2026-03-19 (98e6033) and were replaced
# by the repository packages the same day (bd90ca5). They provide fnm and pnpm, so the installer
# counts them as present and never installs the repository builds. Node versions (~/.local/share/fnm)
# and pnpm's global store are not touched.

swap_package fnm-bin fnm
swap_package pnpm-bin pnpm
