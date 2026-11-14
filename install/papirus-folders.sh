#!/usr/bin/env bash
# Build Papirus-Dark-eggfriedrice: Papirus-Dark with its folders in the palette's yellow.
#
# papirus-folders only switches between Papirus's preset colors, by relinking files under
# /usr/share. This copies the folder-yellow and user-yellow icons instead, swaps Papirus's
# three yellow hexes for the palette's (extras/papirus in the theme repo), and drops the
# color from the names, so folder-yellow-documents.svg becomes folder-documents.svg. The
# user theme holds only those and inherits everything else from Papirus-Dark, so no root
# and nothing that a Papirus update can overwrite. Rerun after `make extras` or a Papirus
# update that adds folder icons.
set -euo pipefail

THEME_DIR="${THEME_DIR:-$HOME/p/eggfriedrice.nvim}"
colors="$THEME_DIR/extras/papirus/eggfriedrice.sh"
src=/usr/share/icons/Papirus
dest="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Papirus-Dark-eggfriedrice"

[[ -f "$colors" ]] || { echo "papirus-folders: missing $colors" >&2; exit 1; }
[[ -f "$src/index.theme" ]] || { echo "papirus-folders: Papirus is not installed" >&2; exit 1; }
# shellcheck source=/dev/null
source "$colors"

# Papirus's own yellow: front face, back face, symbol on the front
papirus_front="#f9bd30"
papirus_back="#e19d00"
papirus_symbol="#594411"

rm -rf "$dest"
mkdir -p "$dest"

dirs=()
for places in "$src"/*/places; do
    dir="${places#"$src"/}"
    shopt -s nullglob
    icons=("$places"/folder-yellow*.svg "$places"/user-yellow*.svg)
    shopt -u nullglob
    ((${#icons[@]})) || continue
    mkdir -p "$dest/$dir"
    for icon in "${icons[@]}"; do
        name="$(basename "$icon")"
        sed -e "s/$papirus_front/$FOLDER_FRONT/gI" \
            -e "s/$papirus_back/$FOLDER_BACK/gI" \
            -e "s/$papirus_symbol/$FOLDER_SYMBOL/gI" \
            "$icon" >"$dest/$dir/${name/-yellow/}"
    done
    # Papirus also has colorless aliases of colorless names (folder-publicshare.svg ->
    # folder-image-people.svg). Without them here the lookup falls through to stock
    # Papirus and the folder comes out blue, so link each alias whose target we built;
    # a few passes resolve the chains (folder-public -> folder-publicshare -> ...).
    for _ in 1 2 3; do
        for link in "$places"/folder-*.svg "$places"/user-*.svg; do
            [[ -L "$link" ]] || continue
            name="$(basename "$link")"
            target="$(readlink "$link")"
            [[ "$target" == */* ]] && continue
            if [[ ! -e "$dest/$dir/$name" && -e "$dest/$dir/$target" ]]; then
                ln -s "$target" "$dest/$dir/$name"
            fi
        done
    done
    dirs+=("$dir")
done

{
    printf '[Icon Theme]\n'
    printf 'Name=Papirus-Dark-eggfriedrice\n'
    printf 'Comment=Papirus-Dark with folders in the eggfriedrice palette\n'
    printf 'Inherits=Papirus-Dark,breeze-dark,hicolor\n'
    printf 'Directories=%s\n' "$(IFS=,; echo "${dirs[*]}")"
    # each directory's Size/Scale/Context/Type block, copied from Papirus
    for dir in "${dirs[@]}"; do
        printf '\n'
        awk -v want="[$dir]" '$0 == want { on = 1 } on && /^$/ { exit } on' "$src/index.theme"
    done
} >"$dest/index.theme"

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -q -f -t "$dest"
fi

echo "papirus-folders: built $dest (${#dirs[@]} directories)"
