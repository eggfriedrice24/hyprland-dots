#!/usr/bin/env bash
# Stage 3: Set zsh as default shell and configure ZDOTDIR

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

success "=== Stage 3: Complete ==="
