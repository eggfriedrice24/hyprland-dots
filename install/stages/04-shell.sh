#!/usr/bin/env bash
# Stage 4: Default shell, zinit bootstrap and the generated shell themes

info "=== Stage 4: Shell ==="

# Login shell
zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [[ -n "$current_shell" && "$(readlink -f "$current_shell")" == "$(readlink -f "$zsh_path")" ]]; then
    success "Default shell is already zsh"
else
    info "Changing default shell to zsh (asks for your password)..."
    run chsh -s "$zsh_path"
fi

# ~/.zshenv is linked to zsh/.zshenv in stage 3 and sets ZDOTDIR
if [[ -L "$HOME/.zshenv" && "$(readlink -f "$HOME/.zshenv")" == "$(readlink -f "${DOTFILES_DIR}/zsh/.zshenv")" ]]; then
    success "~/.zshenv points at the dotfiles"
else
    warn "~/.zshenv is not the dotfiles link, zsh will not find ZDOTDIR"
fi

theme_extras="${THEME_DIR:-$HOME/p/eggfriedrice.nvim}/extras"
zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
fsh_plugin="$zinit_home/plugins/zdharma-continuum---fast-syntax-highlighting"
fsh_theme="$theme_extras/fsh/eggfriedrice.ini"

# zinit clones its plugins on the first interactive shell; do it here, visibly, so fast-theme can run
if [[ -d "$fsh_plugin" ]]; then
    success "zinit plugins already installed"
elif [[ "${DRY_RUN:-0}" == "1" ]]; then
    dry "zsh -ic exit (bootstrap zinit and its plugins)"
    dry "zsh -ic fast-theme $fsh_theme"
else
    info "Installing zinit and its plugins (first interactive shell)..."
    zsh -ic 'exit'
fi

# fast-syntax-highlighting theme (fast-theme persists it into the plugin work dir)
if [[ ! -f "$fsh_theme" ]]; then
    warn "fsh theme not found, skipping: $fsh_theme"
elif [[ ! -d "$fsh_plugin" ]]; then
    : # dry-run on a fresh machine, printed above
elif zsh -ic '[[ "$FAST_THEME_NAME" == "eggfriedrice" ]]' &>/dev/null; then
    success "fast-syntax-highlighting theme is already eggfriedrice"
else
    info "Applying fast-syntax-highlighting theme..."
    run zsh -ic "fast-theme '$fsh_theme'"
fi

# bat theme cache: the theme name in bat/config resolves only after a cache build with the tmTheme present
bat_theme="${DOTFILES_DIR}/bat/themes/eggfriedrice.tmTheme"
if ! command -v bat &>/dev/null; then
    warn "bat not found, skipping theme cache build"
elif [[ ! -e "$bat_theme" ]]; then
    error "bat theme missing or dangling: $bat_theme"
    return 1
elif bat --list-themes 2>/dev/null | grep -x 'eggfriedrice' >/dev/null; then
    success "bat theme cache already includes eggfriedrice"
else
    info "Building bat theme cache..."
    run bat cache --build
    if [[ "${DRY_RUN:-0}" == "0" ]] && ! bat --list-themes 2>/dev/null | grep -x 'eggfriedrice' >/dev/null; then
        error "bat theme eggfriedrice still missing after the cache build"
        return 1
    fi
fi

success "=== Stage 4: Complete ==="
