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
    ["gtk-3.0"]="$HOME/.config/gtk-3.0"
    ["gtk-4.0"]="$HOME/.config/gtk-4.0"
    ["bat"]="$HOME/.config/bat"
    ["eza"]="$HOME/.config/eza"
    ["btop"]="$HOME/.config/btop"
    ["frameit"]="$HOME/.config/frameit"
    ["pipewire"]="$HOME/.config/pipewire"
    ["wireplumber"]="$HOME/.config/wireplumber"
    [".wallpapers"]="$HOME/.wallpapers"
    ["fonts/Cartograph"]="$HOME/.local/share/fonts/Cartograph"
    ["fonts/Nunito"]="$HOME/.local/share/fonts/Nunito"
    ["fonts/AtkinsonHyperlegibleNext"]="$HOME/.local/share/fonts/AtkinsonHyperlegibleNext"
)

run mkdir -p "$HOME/.config"

# sorted for stable output between runs
mapfile -t link_names < <(printf '%s\n' "${!symlinks[@]}" | sort)
for src_name in "${link_names[@]}"; do
    link_path "${DOTFILES_DIR}/${src_name}" "${symlinks[$src_name]}"
done

# Commands in bin/ (dots-update, dots-snapshot, dots-prune): every executable in bin/ goes on PATH through ~/.local/bin,
# a real directory other tools install into too, so the files are linked one by one
for cmd in "${DOTFILES_DIR}"/bin/*; do
    [[ -f "$cmd" && -x "$cmd" ]] || continue
    link_path "$cmd" "$HOME/.local/bin/$(basename "$cmd")"
done

# Links into this repo whose target no longer exists (a config dir or command removed from the repo)
while IFS= read -r -d '' link; do
    target="$(readlink "$link")"
    if [[ "$target" == "$DOTFILES_DIR"/* && ! -e "$link" ]]; then
        info "Removing dangling link: $link -> $target"
        run rm "$link"
    fi
done < <(find "$HOME" "$HOME/.config" "$HOME/.local/bin" -mindepth 1 -maxdepth 1 -type l -print0 2>/dev/null)

success "=== Stage 3: Complete ==="
