#!/usr/bin/env bash
# Stage 5: Fonts, directories, script permissions, final message

info "=== Stage 5: Finalize ==="

# Install Cartograph CF fonts
font_src="${DOTFILES_DIR}/fonts/Cartograph"
font_dest="$HOME/.local/share/fonts/Cartograph"
if [[ -d "$font_src" ]]; then
    run mkdir -p "$font_dest"
    info "Copying Cartograph CF fonts..."
    run cp -u "$font_src"/*.otf "$font_dest/"
    info "Rebuilding font cache..."
    run fc-cache -fv
else
    warn "Cartograph font directory not found, skipping"
fi

# Create expected directories
for dir in "$HOME/Pictures/Screenshots" "$HOME/.local/bin"; do
    if [[ -d "$dir" ]]; then
        success "Directory exists: $dir"
    else
        info "Creating: $dir"
        run mkdir -p "$dir"
    fi
done

# Make Hyprland scripts executable
scripts_dir="${DOTFILES_DIR}/hypr/scripts"
if [[ -d "$scripts_dir" ]]; then
    info "Setting script permissions..."
    run chmod +x "$scripts_dir"/*.sh
    success "Hyprland scripts are executable"
else
    warn "hypr/scripts directory not found"
fi

# Install Claude Code
if command -v claude &>/dev/null; then
    success "Claude Code already installed: $(claude --version 2>/dev/null)"
else
    info "Installing Claude Code..."
    run curl -fsSL https://claude.ai/install.sh | bash
fi

# Install OpenCode plugin dependencies
opencode_dir="${DOTFILES_DIR}/opencode"
if [[ -f "$opencode_dir/package.json" ]]; then
    if command -v bun &>/dev/null; then
        info "Installing OpenCode plugin dependencies..."
        run bun install --cwd "$opencode_dir" --frozen-lockfile
    else
        warn "bun not found, skipping OpenCode plugin dependencies"
    fi
fi

success "=== Stage 5: Complete ==="
echo
info "Installation complete! Reboot and log in to start Hyprland."
