#!/usr/bin/env bash
# Stage 4: Default shell, zinit bootstrap and the generated shell themes

info "=== Stage 4: Shell ==="

# Login shell (a dry run on a fresh machine has not installed zsh yet; stage 1 puts it in /usr/bin)
zsh_path="$(command -v zsh || echo /usr/bin/zsh)"
current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [[ -n "$current_shell" && "$(readlink -f "$current_shell")" == "$(readlink -f "$zsh_path")" ]]; then
    success "Default shell is already zsh"
else
    info "Changing default shell to zsh (asks for your password)..."
    run chsh -s "$zsh_path"
    note relogin "the login shell is now zsh"
fi

# ~/.zshenv is linked to zsh/.zshenv in stage 3 and sets ZDOTDIR
if [[ -L "$HOME/.zshenv" && "$(readlink -f "$HOME/.zshenv")" == "$(readlink -f "${DOTFILES_DIR}/zsh/.zshenv")" ]]; then
    success "~/.zshenv points at the dotfiles"
else
    warn "~/.zshenv is not the dotfiles link, zsh will not find ZDOTDIR"
fi

zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
fsh_plugin="$zinit_home/plugins/zdharma-continuum---fast-syntax-highlighting"

# zinit clones its plugins on the first interactive shell; do it here, visibly, so fast-theme can run.
# A failed bootstrap (offline, GitHub down) only costs the plugins until the next shell, so it warns
# instead of aborting; `exit 0` keeps the rc's last status out of it.
if [[ -d "$fsh_plugin" ]]; then
    success "zinit plugins already installed"
elif [[ "${DRY_RUN:-0}" == "1" ]]; then
    dry "zsh -ic 'exit 0' (bootstrap zinit and its plugins)"
else
    info "Installing zinit and its plugins (first interactive shell)..."
    if ! zsh -ic 'exit 0'; then
        warn "zsh exited with an error while bootstrapping zinit; the next shell retries"
    fi
fi

# Shell-side theme artifacts, each rebuilt only when the theme is newer (install/theme-apply.sh):
# fast-syntax-highlighting's generated theme, bat's theme cache (the theme name in bat/config
# resolves only after a cache build; a dangling theme link stops the install), starship's palette copy
# shellcheck source=install/theme-apply.sh
source "${DOTFILES_DIR}/install/theme-apply.sh"
theme_apply_fsh
theme_apply_bat || return 1
theme_check_starship

success "=== Stage 4: Complete ==="
