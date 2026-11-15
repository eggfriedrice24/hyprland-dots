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
elif [[ "${DRY_RUN:-0}" == "1" ]]; then
    # a dry run reads the real home: stage 3 only planned the link (and the backup of a file in its way)
    dry "stage 3 links $HOME/.zshenv to ${DOTFILES_DIR}/zsh/.zshenv"
else
    warn "~/.zshenv is not the dotfiles link, zsh will not find ZDOTDIR"
fi

zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
fsh_plugin="$zinit_home/plugins/zdharma-continuum---fast-syntax-highlighting"

# zinit clones its plugins on the first interactive shell; do it here, visibly, so fast-theme can run.
# A failed bootstrap (offline, GitHub down) only costs the plugins until the next shell, so it warns
# instead of aborting; `exit 0` keeps the rc's last status out of it. The plugins load in turbo mode
# (wait ice), so a shell that exits at once would clone none of them: `@zinit-scheduler burst` runs
# every queued load before exiting. It gets a usable TERM when the environment lacks one (the
# bootstrap chroot). Inside bootstrap's chroot run a shell that installs zinit itself has been seen to
# stop after the first plugins (VM QA, 2026-11-15; the same command run on its own installs them all),
# so it runs again, at most three times, until the last plugin to need its theme is there.
case "${TERM:-}" in
    "" | dumb | unknown) zinit_term=xterm-256color ;;
    *) zinit_term="$TERM" ;;
esac
if [[ -d "$fsh_plugin" ]]; then
    success "zinit plugins already installed"
elif [[ "${DRY_RUN:-0}" == "1" ]]; then
    dry "TERM=$zinit_term zsh -ic '@zinit-scheduler burst; exit 0' (bootstrap zinit and its plugins)"
else
    info "Installing zinit and its plugins (first interactive shell)..."
    for zinit_pass in 1 2 3; do
        if ! TERM="$zinit_term" zsh -ic '@zinit-scheduler burst; exit 0'; then
            warn "zsh exited with an error while bootstrapping zinit (pass $zinit_pass)"
        fi
        [[ -d "$fsh_plugin" ]] && break
        if (( zinit_pass < 3 )); then
            info "Not every zinit plugin is installed yet, running the shell again..."
        fi
    done
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
