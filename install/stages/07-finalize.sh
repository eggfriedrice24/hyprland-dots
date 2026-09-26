#!/usr/bin/env bash
# Stage 7: Fonts, directories, toolchains, external installers, final notes

info "=== Stage 7: Finalize ==="

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
if command -v rustup &>/dev/null; then
    if rustup show active-toolchain &>/dev/null; then
        success "Rust toolchain: $(rustup show active-toolchain 2>/dev/null | cut -d' ' -f1)"
    else
        info "Installing the nightly Rust toolchain..."
        run rustup default nightly
    fi
fi

# Node via fnm (versions live in ~/.local/share/fnm)
if command -v fnm &>/dev/null; then
    if fnm list 2>/dev/null | grep 'default' >/dev/null; then
        success "fnm default Node: $(fnm list 2>/dev/null | grep 'default' | awk '{print $2}')"
    else
        info "Installing Node 22 via fnm..."
        run fnm install 22
        run fnm default 22
    fi
else
    warn "fnm not found, no Node version installed"
fi

# Claude Code (installs into ~/.local/bin)
if command -v claude &>/dev/null; then
    success "Claude Code already installed: $(claude --version 2>/dev/null)"
else
    info "Installing Claude Code..."
    run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
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
if command -v flatpak &>/dev/null; then
    if ! flatpak remotes --columns=name 2>/dev/null | grep -x 'flathub' >/dev/null; then
        info "Adding the flathub remote..."
        run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
    if flatpak info com.stremio.Stremio &>/dev/null; then
        success "Stremio flatpak installed"
    else
        info "Installing Stremio (flatpak)..."
        run sudo flatpak install -y --noninteractive flathub com.stremio.Stremio
    fi
fi

success "=== Stage 7: Complete ==="
echo
info "Installation complete. Reboot and log in on TTY1 to start Hyprland."
echo
info "Manual steps the installer does not cover (details in README.md):"
echo "  - restore ~/.ssh (keys and config) and ~/.gitconfig, then: gh auth login"
echo "  - tailscale up"
echo "  - pair Bluetooth devices with bluetoothctl"
echo "  - desktop WiFi: pin the connection to the AP's BSSID and 5 GHz band"
echo "  - default apps: xdg-mime default zen.desktop x-scheme-handler/http (full list in README.md)"
echo "  - fill in opencode/google-workspace.env; paste the Slack theme from ~/p/eggfriedrice.nvim/extras/slack"
echo "  - Neovim: start nvim once, then :Lazy restore to pin plugins to lazy-lock.json"
