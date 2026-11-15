#!/usr/bin/env bash
# Stage 2: eggfriedrice design system
# Every colour-bearing config links into this repo's extras/, so it has to exist before the symlinks.
# THEME_DIR, theme_ensure and verify_theme live in install/utils.sh (dots-update uses them too).

info "=== Stage 2: Theme repository ==="

theme_ensure
verify_theme

success "=== Stage 2: Complete ==="
