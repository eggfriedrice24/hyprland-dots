#!/usr/bin/env bash
# Stage 2: Symlink config directories

info "=== Stage 2: Symlinks ==="

declare -A symlinks=(
    ["hypr"]="$HOME/.config/hypr"
    ["nvim"]="$HOME/.config/nvim"
    ["opencode"]="$HOME/.config/opencode"
    ["kitty"]="$HOME/.config/kitty"
    ["ghostty"]="$HOME/.config/ghostty"
    ["zsh"]="$HOME/.config/zsh"
    ["starship"]="$HOME/.config/starship"
    ["waybar"]="$HOME/.config/waybar"
    ["rofi"]="$HOME/.config/rofi"
    ["tmux"]="$HOME/.config/tmux"
    ["lazygit"]="$HOME/.config/lazygit"
    ["pipewire"]="$HOME/.config/pipewire"
    ["wireplumber"]="$HOME/.config/wireplumber"
    [".wallpapers"]="$HOME/.wallpapers"
)

run mkdir -p "$HOME/.config"

for src_name in "${!symlinks[@]}"; do
    src="${DOTFILES_DIR}/${src_name}"
    dest="${symlinks[$src_name]}"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        warn "Source not found, skipping: $src"
        continue
    fi

    if [[ -L "$dest" ]]; then
        current_target="$(readlink "$dest")"
        if [[ "$current_target" == "$src" ]]; then
            success "Already linked: $dest"
            continue
        else
            info "Replacing stale symlink: $dest -> $current_target"
            run rm "$dest"
        fi
    elif [[ -d "$dest" ]]; then
        warn "Real directory exists, skipping: $dest"
        continue
    fi

    info "Linking: $dest -> $src"
    run ln -sf "$src" "$dest"
done

success "=== Stage 2: Complete ==="
