#!/usr/bin/env bash
# Report colour literals that bypass the eggfriedrice palette. Read-only.
#
# Colours belong to the theme repo: consumers import a generated extra (extras/gtk,
# extras/rofi, the hypr lua module, ...) or name a role, so a palette change reaches them
# with `make extras`. A hex literal in this repo is either a copy that drifts or a colour
# from outside the palette. Literals are only accepted in the files on the allowlist below.
#
# usage: install/lint-colors.sh [FILE...]
#   no FILE: every tracked text file (symlinks into the theme repo are skipped)
#   FILE:    only those files; allowlist paths are matched relative to the repo
# exit: 0 clean, 1 literals found, 2 the palette could not be read
# env:  THEME_DIR (default ~/p/eggfriedrice.nvim) to read extras/palette/eggfriedrice.json
set -Euo pipefail

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
THEME_DIR=${THEME_DIR:-$HOME/p/eggfriedrice.nvim}
PALETTE_JSON="$THEME_DIR/extras/palette/eggfriedrice.json"

# "<path glob relative to the repo> <mode>"; mode palette: the value (alpha suffix ignored)
# must be a palette colour, mode any: any value is accepted
ALLOW=(
    # [palettes.eggfriedrice] block pasted from extras/starship (re-paste after make extras)
    "starship/starship.toml palette"
    # literal fallback for when the theme repo is not cloned yet
    "hypr/hyprland.lua palette"
    # example value in a comment
    "hypr/windowrule.lua palette"
    # Papirus's stock folder colours, the ones the script replaces
    "install/papirus-folders.sh any"
    # orphaned old power menu; drop this entry together with the directory
    "rofi/powermenu/* any"
)

# #rrggbb, #rrggbbaa and hyprland's rgb(rrggbb) / rgba(rrggbbaa)
COLOR_RE='#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?\b|rgba?\([0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?\)'

if [[ ! -r "$PALETTE_JSON" ]]; then
    echo "lint-colors: cannot read the palette: $PALETTE_JSON (set THEME_DIR)" >&2
    exit 2
fi
declare -A palette=()
while read -r hex; do
    palette[${hex,,}]=1
done < <(grep -oE '#[0-9A-Fa-f]{6}\b' "$PALETTE_JSON" | cut -c2-)
if (( ${#palette[@]} == 0 )); then
    echo "lint-colors: no colours found in $PALETTE_JSON" >&2
    exit 2
fi

allow_mode() {
    local rel=$1 entry glob
    for entry in "${ALLOW[@]}"; do
        glob=${entry% *}
        # shellcheck disable=SC2053 # the allowlist path is a glob
        if [[ $rel == $glob ]]; then
            echo "${entry##* }"
            return
        fi
    done
    echo none
}

files=()
if (( $# )); then
    files=("$@")
else
    while IFS= read -r -d '' f; do
        [[ -L "$DOTFILES_DIR/$f" || ! -f "$DOTFILES_DIR/$f" ]] && continue
        files+=("$DOTFILES_DIR/$f")
    done < <(git -C "$DOTFILES_DIR" ls-files -z)
    for entry in "${ALLOW[@]}"; do
        glob=${entry% *}
        matched=0
        for f in "${files[@]}"; do
            # shellcheck disable=SC2053 # the allowlist path is a glob
            [[ ${f#"$DOTFILES_DIR"/} == $glob ]] && { matched=1; break; }
        done
        (( matched )) || echo "lint-colors: note: allowlist entry '$glob' matches no tracked file, drop it" >&2
    done
fi

found=0
for f in "${files[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "lint-colors: not a file: $f" >&2
        found=1
        continue
    fi
    rel=$(realpath -s --relative-to="$DOTFILES_DIR" "$f")
    if [[ $rel == ../* ]]; then
        # outside the repo: no allowlist entry applies, report the path as given
        rel=$f
        mode=none
    else
        mode=$(allow_mode "$rel")
    fi
    [[ $mode == any ]] && continue
    while IFS=: read -r line match; do
        hex=${match#\#}
        hex=${hex#rgba(}
        hex=${hex#rgb(}
        hex=${hex:0:6}
        hex=${hex,,}
        if [[ $mode == palette ]]; then
            [[ -n "${palette[$hex]:-}" ]] && continue
            echo "$rel:$line: $match is not a palette colour (allowed here only as a palette copy)"
        elif [[ -n "${palette[$hex]:-}" ]]; then
            echo "$rel:$line: $match copies a palette colour; import the theme extra or use the role instead"
        else
            echo "$rel:$line: $match is not in the palette; add a role in the theme repo"
        fi
        found=1
    done < <(grep -IonE "$COLOR_RE" -- "$f" || true)
done

if (( found )); then
    echo "lint-colors: colour literals outside the palette found" >&2
    exit 1
fi
echo "lint-colors: ok (${#files[@]} files)"
