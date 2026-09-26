#!/usr/bin/env bash
# Stage 3: Set zsh as default shell, configure ZDOTDIR and register shell themes

info "=== Stage 3: Shell ==="

# Set zsh as default shell
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$current_shell" == "/usr/bin/zsh" ]]; then
    success "Default shell is already zsh"
else
    info "Changing default shell to zsh..."
    run chsh -s /usr/bin/zsh
fi

# Write ~/.zshenv for XDG compliance
if [[ -f "$HOME/.zshenv" ]] && grep -q 'ZDOTDIR' "$HOME/.zshenv"; then
    success "~/.zshenv already configured"
else
    info "Writing ~/.zshenv with ZDOTDIR..."
    run tee "$HOME/.zshenv" <<< 'export ZDOTDIR="$HOME/.config/zsh"'
fi

# Generated theme files (eggfriedrice.nvim extras)
theme_extras="/home/eggfriedrice/p/eggfriedrice.nvim/extras"

# Apply the fast-syntax-highlighting theme (fast-theme persists it into the plugin work dir)
fsh_theme="${theme_extras}/fsh/eggfriedrice.ini"
if [[ ! -f "$fsh_theme" ]]; then
    warn "fsh theme not found, skipping: $fsh_theme"
elif zsh -ic '[[ "$FAST_THEME_NAME" == "eggfriedrice" ]]' &>/dev/null; then
    success "fast-syntax-highlighting theme is already eggfriedrice"
elif ! zsh -ic 'command -v fast-theme' &>/dev/null; then
    warn "fast-syntax-highlighting not installed yet (zinit clones it on first shell); run: fast-theme $fsh_theme"
else
    info "Applying fast-syntax-highlighting theme..."
    run zsh -ic "fast-theme '$fsh_theme'"
fi

# Rebuild bat's theme cache so the theme named in bat/config resolves
if ! command -v bat &>/dev/null; then
    warn "bat not found, skipping theme cache build"
elif bat --list-themes 2>/dev/null | grep -qx 'eggfriedrice'; then
    success "bat theme cache already includes eggfriedrice"
else
    info "Building bat theme cache..."
    run bat cache --build
fi

success "=== Stage 3: Complete ==="
