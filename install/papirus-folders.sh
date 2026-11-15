#!/usr/bin/env bash
# Build Papirus-Dark-eggfriedrice: Papirus-Dark with its folders in the palette's yellow.
#
# papirus-folders only switches between Papirus's preset colors, by relinking files under
# /usr/share. This copies the folder-yellow and user-yellow icons instead, swaps Papirus's
# three yellow hexes for the palette's (extras/papirus in the theme repo), and drops the
# color from the names, so folder-yellow-documents.svg becomes folder-documents.svg. The
# user theme holds only those and inherits everything else from Papirus-Dark, so no root
# and nothing that a Papirus update can overwrite.
#
# A stamp in the built theme records its inputs (the palette's folder colours, this script,
# the installed Papirus), so a run only rebuilds when one of them changed:
#   papirus-folders.sh           build when the stamp is missing or stale
#   papirus-folders.sh --force   build regardless
#   papirus-folders.sh --check   change nothing; exit 0 current, 1 stale, 2 cannot build
set -euo pipefail

THEME_DIR="${THEME_DIR:-$HOME/p/eggfriedrice.nvim}"
colors="$THEME_DIR/extras/papirus/eggfriedrice.sh"
src=/usr/share/icons/Papirus
dest="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Papirus-Dark-eggfriedrice"
stamp="$dest/.eggfriedrice-stamp"

mode=build
case "${1:-}" in
    "") ;;
    --check) mode=check ;;
    --force) mode=force ;;
    -h | --help)
        echo "Usage: $0 [--check|--force]   build Papirus-Dark-eggfriedrice when its inputs changed"
        exit 0
        ;;
    *)
        echo "papirus-folders: unknown option: $1" >&2
        exit 2
        ;;
esac

[[ -f "$colors" ]] || { echo "papirus-folders: missing $colors" >&2; exit 2; }
[[ -f "$src/index.theme" ]] || { echo "papirus-folders: Papirus is not installed" >&2; exit 2; }

# what the build depends on; Papirus is identified by its index.theme (replaced by every update)
want="colors $(sha256sum <"$colors" | cut -d' ' -f1)
script $(sha256sum <"${BASH_SOURCE[0]}" | cut -d' ' -f1)
papirus $(stat -c '%s %Y' "$src/index.theme")"

if [[ "$mode" != force ]]; then
    have=""
    [[ -f "$stamp" ]] && have="$(<"$stamp")"
    if [[ -n "$have" && "$have" == "$want" && -f "$dest/index.theme" ]]; then
        [[ "$mode" == check ]] || echo "papirus-folders: $dest is current"
        exit 0
    fi
    if [[ "$mode" == check ]]; then
        if [[ -z "$have" ]]; then
            echo "papirus-folders: no build stamp yet"
        else
            echo "papirus-folders: the palette, this script or Papirus changed since the last build"
        fi
        exit 1
    fi
fi

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
    # Papirus also has colorless aliases of colorless names, and not only folder-* and user-*
    # ones (folder-publicshare.svg -> folder-image-people.svg, inode-directory.svg -> folder.svg,
    # network.svg -> folder-network.svg). Without them here the lookup falls through to stock
    # Papirus and the folder comes out blue, so link every alias whose target we built, pass
    # after pass until every chain is resolved.
    aliases=()
    for link in "$places"/*.svg; do
        [[ -L "$link" ]] || continue
        target="$(readlink "$link")"
        [[ "$target" == */* ]] && continue
        aliases+=("$(basename "$link")" "$target")
    done
    added=1
    while ((added)); do
        added=0
        for ((i = 0; i < ${#aliases[@]}; i += 2)); do
            name="${aliases[i]}"
            target="${aliases[i + 1]}"
            if [[ ! -e "$dest/$dir/$name" && -e "$dest/$dir/$target" ]]; then
                ln -s "$target" "$dest/$dir/$name"
                added=1
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

# written last, so an interrupted build counts as stale and is redone
printf '%s\n' "$want" >"$stamp"

echo "papirus-folders: built $dest (${#dirs[@]} directories)"
