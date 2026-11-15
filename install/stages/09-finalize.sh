#!/usr/bin/env bash
# Stage 9: Fonts, directories, toolchains, external installers, final notes

info "=== Stage 9: Finalize ==="

# Cartograph CF is linked into ~/.local/share/fonts in stage 3; make fontconfig see it
if fc-match 'Cartograph CF' 2>/dev/null | grep 'Cartograph' >/dev/null; then
    success "Cartograph CF visible to fontconfig"
else
    info "Rebuilding font cache..."
    run fc-cache -f
fi

# XDG user directories (keybinds and scripts use Videos, Pictures, Downloads)
if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
    success "XDG user directories configured"
else
    info "Creating XDG user directories..."
    run xdg-user-dirs-update
fi

# Directories the configs expect to exist
for dir in "$HOME/Pictures/Screenshots" "$HOME/.local/bin" "$HOME/.local/state/zsh"; do
    if [[ -d "$dir" ]]; then
        success "Directory exists: $dir"
    else
        info "Creating: $dir"
        run mkdir -p "$dir"
    fi
done

# Hyprland scripts executable (git tracks the mode; this covers copies made without it)
scripts_dir="${DOTFILES_DIR}/hypr/scripts"
if [[ -d "$scripts_dir" ]]; then
    run chmod +x "$scripts_dir"/*
    success "Hyprland scripts are executable"
fi

# Rust: rustup ships no toolchain until one is selected
if has_cmd rustup; then
    if rustup show active-toolchain &>/dev/null; then
        success "Rust toolchain: $(rustup show active-toolchain 2>/dev/null | cut -d' ' -f1)"
    else
        info "Installing the nightly Rust toolchain..."
        try "rustup default nightly" rustup default nightly
    fi
fi

# Node via fnm (versions live in ~/.local/share/fnm)
if has_cmd fnm; then
    if fnm list 2>/dev/null | grep 'default' >/dev/null; then
        success "fnm default Node: $(fnm list 2>/dev/null | grep 'default' | awk '{print $2}')"
    else
        info "Installing Node 22 via fnm..."
        try "fnm install 22" fnm install 22
        try "fnm default 22" fnm default 22
    fi
else
    warn "fnm not found, no Node version installed"
fi

# Neovim: plugins at the commits in the tracked lazy-lock.json, then the Mason tools, both headless
# and only on a machine that has neither yet (later additions install on the next interactive start).
# Each run ends with a check that exits 1 when something is still missing, since a failed clone or
# download leaves nvim's own exit status at 0. Treesitter parsers still build on the first real start.
if has_cmd nvim neovim; then
    nvim_data="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
    nvim_new=0
    if [[ -d "$nvim_data/lazy" ]]; then
        success "Neovim plugins installed ($nvim_data/lazy)"
    else
        nvim_new=1
        info "Installing Neovim plugins from lazy-lock.json (headless)..."
        try "Neovim plugins (start nvim and run :Lazy restore)" \
            timeout 900 nvim --headless "+Lazy! restore" \
            "+lua if vim.iter(require('lazy').plugins()):any(function(p) return not p._.installed end) then vim.cmd.cquit() end" \
            +qa </dev/null
    fi
    if (( ! nvim_new )) && [[ -n "$(ls -A "$nvim_data/mason/packages" 2>/dev/null)" ]]; then
        success "Mason tools installed ($nvim_data/mason/packages)"
    else
        info "Installing Mason tools (headless)..."
        try "Mason tools (start nvim and run :MasonToolsInstallSync)" \
            timeout 1200 nvim --headless +MasonToolsInstallSync \
            "+lua local r = require('mason-registry'); local o = require('lazy.core.plugin').values(require('lazy.core.config').plugins['mason-tool-installer.nvim'], 'opts', false); if vim.iter(o.ensure_installed):any(function(n) return not r.is_installed(type(n) == 'table' and n[1] or n) end) then vim.cmd.cquit() end" \
            +qa </dev/null
    fi
fi

# Claude Code (installs into ~/.local/bin)
if command -v claude &>/dev/null; then
    success "Claude Code already installed: $(claude --version 2>/dev/null)"
else
    info "Installing Claude Code..."
    # pipefail: a failed download must fail the step, not feed bash an empty script
    try "Claude Code installer" bash -c 'set -o pipefail; curl -fsSL https://claude.ai/install.sh | bash'
fi

# OpenCode: the Google Workspace MCP credentials are gitignored, seed the file from the example
oc_env="${DOTFILES_DIR}/opencode/google-workspace.env"
if [[ -f "$oc_env" ]]; then
    success "opencode/google-workspace.env present"
elif [[ -f "$oc_env.example" ]]; then
    info "Seeding opencode/google-workspace.env from the example (fill in your credentials)"
    run cp "$oc_env.example" "$oc_env"
    run chmod 600 "$oc_env"
fi

# Flatpak apps
if has_cmd flatpak; then
    if ! flatpak remotes --columns=name 2>/dev/null | grep -x 'flathub' >/dev/null; then
        info "Adding the flathub remote..."
        try "flatpak remote-add flathub" sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
    if flatpak info com.stremio.Stremio &>/dev/null; then
        success "Stremio flatpak installed"
    else
        info "Installing Stremio (flatpak)..."
        try "flatpak install com.stremio.Stremio" sudo flatpak install -y --noninteractive flathub com.stremio.Stremio
    fi
fi

success "=== Stage 9: Complete ==="
# --quiet (dots-update): only what went wrong; the caller prints its own summary and notes
if [[ "${QUIET:-0}" != "1" ]]; then
    echo
    info "Installation complete. Reboot and log in on TTY1 to start Hyprland."
    echo
fi
if (( ${#AUR_FAILED[@]} )); then
    warn "These AUR packages failed to build; install them by hand: yay -S ${AUR_FAILED[*]}"
    echo
fi
if (( ${#FAILED[@]} )); then
    warn "These optional steps failed; rerun the installer or do them by hand:"
    printf '  - %s\n' "${FAILED[@]}"
    echo
fi
# shellcheck disable=SC2153 # NOTES is filled by note() in install/utils.sh
if (( ${#NOTES[@]} )) && [[ -z "${DOTS_NOTES_FILE:-}" ]]; then
    warn "Before this run's changes are all in effect:"
    printf '  - %s\n' "${NOTES[@]}"
    echo
fi
if [[ "${QUIET:-0}" != "1" ]]; then
    info "Manual steps the installer does not cover (details in README.md):"
    echo "  - restore ~/.ssh (keys and config) and ~/.gitconfig, then: gh auth login"
    echo "  - tailscale up"
    echo "  - pair Bluetooth devices with bluetoothctl"
    echo "  - default apps: xdg-mime default zen.desktop x-scheme-handler/http (full list in README.md)"
    echo "  - fill in opencode/google-workspace.env; paste the Slack theme from ~/p/eggfriedrice.nvim/extras/slack"

    # Machine profile notes (machines/<layer>/notes): every line that is not a comment is a manual step
    mapfile -t note_files < <(profile_files notes)
    for notes in "${note_files[@]}"; do
        mapfile -t note_lines < <(sed 's/^[[:space:]]*//; /^#/d; /^$/d' "$notes")
        if (( ${#note_lines[@]} )); then
            echo
            info "For the $(layer_of "$notes") profile:"
            printf '  - %s\n' "${note_lines[@]}"
        fi
    done
fi
