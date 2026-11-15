#!/usr/bin/env bash
# Derived theme artifacts: what the theme repo's extras turn into once a tool has compiled or copied
# them, which no symlink can carry. Each part rebuilds only when its input is newer than its output.
#   bat       bat's theme cache, from bat/themes/*.tmTheme (links into extras/bat)
#   fsh       fast-syntax-highlighting's generated theme, from extras/fsh/eggfriedrice.ini
#   papirus   the Papirus-Dark-eggfriedrice icon theme, from extras/papirus (install/papirus-folders.sh)
#   starship  check only: the [palettes.eggfriedrice] block pasted into starship/starship.toml
#             against extras/starship (the installer never rewrites the tracked file)
#
# Sourced by install stages 4 and 6, which call the parts they own (needs install/utils.sh).
# Run directly it applies every part, for example after `make extras` in the theme repo:
#   install/theme-apply.sh [--force]      DRY_RUN=1 prints what it would do

THEME_APPLY_FORCE="${THEME_APPLY_FORCE:-0}"

# bat: `bat cache --build` compiles every theme in its config dir into themes.bin. Stale when the
# cache is missing, lacks eggfriedrice, is older than a theme file, or was written by another bat.
theme_apply_bat() {
    local themes="${DOTFILES_DIR}/bat/themes" theme cache_dir reason="" file built current
    theme="$themes/eggfriedrice.tmTheme"
    if ! has_cmd bat; then
        warn "bat not found, skipping theme cache build"
        return 0
    fi
    if [[ ! -e "$theme" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            # fresh dry run: the link resolves once stage 2 has cloned the theme repo
            dry "bat cache --build"
            return 0
        fi
        error "bat theme missing or dangling: $theme"
        return 1
    fi
    if ! command -v bat &>/dev/null; then
        # dry run on a machine where stage 1 would install bat
        dry "bat cache --build"
        return 0
    fi

    cache_dir="$(bat --cache-dir 2>/dev/null || echo "${XDG_CACHE_HOME:-$HOME/.cache}/bat")"
    if [[ "$THEME_APPLY_FORCE" == "1" ]]; then
        reason="forced"
    elif [[ ! -f "$cache_dir/themes.bin" ]]; then
        reason="no theme cache yet"
    elif ! bat --list-themes 2>/dev/null | grep -x 'eggfriedrice' >/dev/null; then
        reason="the cache has no eggfriedrice theme"
    else
        for file in "$themes"/*; do
            if [[ "$file" -nt "$cache_dir/themes.bin" ]]; then
                reason="$(basename "$file") is newer than the cache"
                break
            fi
        done
    fi
    if [[ -z "$reason" && -f "$cache_dir/metadata.yaml" ]]; then
        built="$(sed -n 's/^bat_version: *//p' "$cache_dir/metadata.yaml")"
        current="$(bat --version 2>/dev/null | awk '{ print $2 }')"
        if [[ -n "$built" && -n "$current" && "$built" != "$current" ]]; then
            reason="the cache was built by bat $built, this is $current"
        fi
    fi
    if [[ -z "$reason" ]]; then
        success "bat theme cache is current"
        return 0
    fi

    info "Rebuilding the bat theme cache ($reason)..."
    run bat cache --build
    if [[ "${DRY_RUN:-0}" != "1" ]] && ! bat --list-themes 2>/dev/null | grep -x 'eggfriedrice' >/dev/null; then
        error "bat theme eggfriedrice still missing after the cache build"
        return 1
    fi
}

# fsh: fast-theme turns the .ini into current_theme.zsh in the plugin's work dir. Stale when another
# theme is active or the .ini is newer than that file. Cosmetic, so a failure only warns.
theme_apply_fsh() {
    local ini="$THEME_DIR/extras/fsh/eggfriedrice.ini" plugin state name work reason=""
    plugin="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins/zdharma-continuum---fast-syntax-highlighting"
    if [[ ! -f "$ini" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            dry "zsh -ic \"fast-theme '$ini'\" (once the theme repo is cloned)"
            return 0
        fi
        warn "fsh theme not found, skipping: $ini"
        return 0
    fi
    if [[ ! -d "$plugin" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            dry "zsh -ic \"fast-theme '$ini'\" (once zinit has installed the plugin)"
        else
            warn "fast-syntax-highlighting not installed, skipping its theme; rerun the installer once zinit has its plugins"
        fi
        return 0
    fi

    # the plugin decides its work dir at load time (falls back to ~/.cache/fsh), so ask a shell
    state="$(zsh -ic 'print -r -- "FSH|${FAST_THEME_NAME:-}|${FAST_WORK_DIR:-}"' 2>/dev/null | grep '^FSH|' | tail -n 1)" || true
    name="${state#FSH|}"
    name="${name%%|*}"
    work="${state##*|}"
    if [[ "$THEME_APPLY_FORCE" == "1" ]]; then
        reason="forced"
    elif [[ "$name" != "eggfriedrice" ]]; then
        reason="active theme is ${name:-unknown}"
    elif [[ -z "$work" || ! -f "$work/current_theme.zsh" ]]; then
        reason="no generated theme found"
    elif [[ "$ini" -nt "$work/current_theme.zsh" ]]; then
        reason="the theme is newer than fast-theme's copy"
    fi
    if [[ -z "$reason" ]]; then
        success "fast-syntax-highlighting theme is current"
        return 0
    fi
    info "Applying fast-syntax-highlighting theme ($reason)..."
    try "fast-theme $ini" zsh -ic "fast-theme '$ini'"
}

# papirus: Papirus-Dark-eggfriedrice, built by install/papirus-folders.sh, which stamps its inputs
# (folder colours, the script, the installed Papirus) and answers --check from that stamp
theme_apply_papirus() {
    local script="${DOTFILES_DIR}/install/papirus-folders.sh" out status=0
    if [[ ! -f /usr/share/icons/Papirus/index.theme ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]] && has_pkg papirus-icon-theme; then
            dry "$script"
            return 0
        fi
        warn "Papirus is not installed, folder icons not recoloured"
        return 1
    fi
    if [[ "$THEME_APPLY_FORCE" == "1" ]]; then
        info "Rebuilding Papirus folder icons (forced)..."
        run "$script" --force
        return
    fi
    out="$("$script" --check 2>&1)" || status=$?
    case "$status" in
        0) success "Papirus folder icons are current" ;;
        1)
            info "Rebuilding Papirus folder icons (${out#papirus-folders: })..."
            run "$script"
            ;;
        *)
            warn "${out:-papirus-folders.sh --check failed}"
            return 1
            ;;
    esac
}

# the palette's "name = value" lines, whitespace removed, from a [palettes.eggfriedrice] table
_starship_palette() {
    awk '/^\[palettes\.eggfriedrice\]/ { on = 1; next } /^\[/ { on = 0 }
        on && /^[A-Za-z0-9_]+[[:space:]]*=/ { gsub(/[[:space:]]/, ""); print }' "$1"
}

# starship has no include, so its palette is a pasted copy; report drift, never rewrite the file
theme_check_starship() {
    local extra="$THEME_DIR/extras/starship/eggfriedrice.toml" config="${DOTFILES_DIR}/starship/starship.toml"
    if [[ ! -f "$extra" || ! -f "$config" ]]; then
        return 0
    fi
    if [[ "$(_starship_palette "$extra")" == "$(_starship_palette "$config")" ]]; then
        success "starship palette matches extras/starship"
    else
        warn "starship/starship.toml's [palettes.eggfriedrice] differs from ${extra/#$HOME/\~}; paste that block over it and commit"
    fi
}

# every part; returns non-zero when one failed
theme_apply_all() {
    local status=0
    theme_apply_bat || status=1
    theme_apply_fsh || status=1
    theme_apply_papirus || status=1
    theme_check_starship || status=1
    return "$status"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -Eeuo pipefail
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export DOTFILES_DIR
    # shellcheck source=install/utils.sh
    source "${DOTFILES_DIR}/install/utils.sh"
    case "${1:-}" in
        "") ;;
        --force) THEME_APPLY_FORCE=1 ;;
        -h | --help)
            echo "Usage: $0 [--force]   rebuild derived theme artifacts that are older than the theme (DRY_RUN=1: print only)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    theme_apply_all
    if (( ${#FAILED[@]} )); then
        warn "Failed: ${FAILED[*]}"
        exit 1
    fi
fi
