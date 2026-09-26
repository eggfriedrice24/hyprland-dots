#!/usr/bin/env bash
# Stage 3: Symlink config directories and files into place

info "=== Stage 3: Symlinks ==="

declare -A symlinks=(
    ["hypr"]="$HOME/.config/hypr"
    ["nvim"]="$HOME/.config/nvim"
    ["opencode"]="$HOME/.config/opencode"
    ["ghostty"]="$HOME/.config/ghostty"
    ["zsh"]="$HOME/.config/zsh"
    ["zsh/.zshenv"]="$HOME/.zshenv"
    ["starship"]="$HOME/.config/starship"
    ["waybar"]="$HOME/.config/waybar"
    ["dunst"]="$HOME/.config/dunst"
    ["rofi"]="$HOME/.config/rofi"
    ["tmux"]="$HOME/.config/tmux"
    ["lazygit"]="$HOME/.config/lazygit"
    ["bat"]="$HOME/.config/bat"
    ["eza"]="$HOME/.config/eza"
    ["btop"]="$HOME/.config/btop"
    ["pipewire"]="$HOME/.config/pipewire"
    ["wireplumber"]="$HOME/.config/wireplumber"
    [".wallpapers"]="$HOME/.wallpapers"
    ["fonts/Cartograph"]="$HOME/.local/share/fonts/Cartograph"
)

run mkdir -p "$HOME/.config"

# sorted for stable output between runs
mapfile -t link_names < <(printf '%s\n' "${!symlinks[@]}" | sort)
for src_name in "${link_names[@]}"; do
    link_path "${DOTFILES_DIR}/${src_name}" "${symlinks[$src_name]}"
done

# Links into this repo whose target no longer exists (a config dir removed from the repo)
while IFS= read -r -d '' link; do
    target="$(readlink "$link")"
    if [[ "$target" == "$DOTFILES_DIR"/* && ! -e "$link" ]]; then
        info "Removing dangling link: $link -> $target"
        run rm "$link"
    fi
done < <(find "$HOME" "$HOME/.config" -mindepth 1 -maxdepth 1 -type l -print0 2>/dev/null)

success "=== Stage 3: Complete ==="
