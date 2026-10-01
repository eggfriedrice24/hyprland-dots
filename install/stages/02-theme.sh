#!/usr/bin/env bash
# Stage 2: eggfriedrice design system
# Every colour-bearing config links into this repo's extras/, so it has to exist before the symlinks.

info "=== Stage 2: Theme repository ==="

THEME_REPO="https://github.com/eggfriedrice24/eggfriedrice.nvim"
THEME_DIR="$HOME/p/eggfriedrice.nvim"
export THEME_DIR

if [[ -d "$THEME_DIR/.git" ]]; then
    success "Theme repo present: $THEME_DIR"
    if [[ -z "$(git -C "$THEME_DIR" status --porcelain)" ]]; then
        info "Updating theme repo..."
        run git -C "$THEME_DIR" pull --ff-only --quiet || warn "Could not fast-forward the theme repo, keeping the local checkout"
    else
        warn "Theme repo has local changes, not pulling"
    fi
else
    info "Cloning theme repo to $THEME_DIR..."
    run mkdir -p "$HOME/p"
    run git clone --quiet "$THEME_REPO" "$THEME_DIR"
fi

# Every extra the dotfiles reference. Most consumers fall back silently when one is missing,
# so a broken theme would otherwise go unnoticed until the desktop looks wrong.
required_extras=(
    bat/eggfriedrice.tmTheme
    btop/eggfriedrice.theme
    dunst/eggfriedrice.conf
    eza/eggfriedrice.yml
    frameit/eggfriedrice.toml
    fsh/eggfriedrice.ini
    fzf/eggfriedrice.sh
    ghostty/eggfriedrice
    gtk/eggfriedrice.css
    hyprland/eggfriedrice.conf
    lazygit/eggfriedrice.yml
    lua/eggfriedrice.lua
    opencode/eggfriedrice.json
    rofi/eggfriedrice.rasi
    tmux/eggfriedrice.tmux
    zsh/eggfriedrice.zsh
)

if [[ ! -d "$THEME_DIR/extras" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        warn "Theme repo not cloned in dry-run, skipping the extras check"
    else
        error "Theme repo has no extras/ directory: $THEME_DIR"
        return 1
    fi
else
    missing=0
    for extra in "${required_extras[@]}"; do
        if [[ ! -s "$THEME_DIR/extras/$extra" ]]; then
            error "Missing theme extra: $THEME_DIR/extras/$extra"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        error "Theme repo is incomplete; run 'make extras' in $THEME_DIR and retry"
        return 1
    fi
    success "All ${#required_extras[@]} theme extras present"
fi

success "=== Stage 2: Complete ==="
