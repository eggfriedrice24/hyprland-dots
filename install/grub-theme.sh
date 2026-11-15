#!/usr/bin/env bash
# Build the eggfriedrice GRUB theme and install it in /boot/grub/themes/eggfriedrice.
#
# grub/theme.txt and grub/logo.svg are templates: their @tokens@ take the palette's colours
# (extras/palette in the theme repo) and pixel sizes scaled to the panel GRUB draws on, since
# GRUB has no notion of DPI. The menu font is the theme's font.ui at its ui weight and the
# console's font.mono, both converted to GRUB's PF2 format with grub-mkfont.
#
# A stamp in the installed theme records the inputs (palette, templates, this script, fonts,
# scale), so a run only rebuilds when one of them changed:
#   grub-theme.sh           build and install when the stamp is missing or stale (uses sudo)
#   grub-theme.sh --force   build and install regardless
#   grub-theme.sh --check   change nothing; exit 0 current, 1 stale, 2 cannot build
#   grub-theme.sh --build DIR   only build into DIR, as the user (for a preview)
# GRUB_THEME_HEIGHT=1440 overrides the panel height the sizes are scaled from (default: the
# internal panel's preferred mode, else the tallest connected output, else 1080).
# grub.cfg loads the theme's fonts by name, so a rebuild needs grub-mkconfig (stage 6 runs it).
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
THEME_DIR="${THEME_DIR:-$HOME/p/eggfriedrice.nvim}"
palette="$THEME_DIR/extras/palette/eggfriedrice.json"
src="$DOTFILES_DIR/grub"
dest=/boot/grub/themes/eggfriedrice
stamp="$dest/.eggfriedrice-stamp"

die() {
    echo "grub-theme: $*" >&2
    exit 2
}

mode=install
out=""
case "${1:-}" in
    "") ;;
    --check) mode=check ;;
    --force) mode=force ;;
    --build)
        mode=build
        out="${2:-}"
        [[ -n "$out" ]] || die "--build needs a directory"
        ;;
    -h | --help)
        echo "Usage: $0 [--check|--force|--build DIR]   build the GRUB theme when its inputs changed"
        exit 0
        ;;
    *) die "unknown option: $1" ;;
esac

for cmd in jq fc-match grub-mkfont rsvg-convert; do
    command -v "$cmd" &>/dev/null || die "$cmd not found"
done
[[ -f "$palette" ]] || die "missing $palette"
[[ -f "$src/theme.txt" && -f "$src/logo.svg" ]] || die "missing $src/theme.txt or logo.svg"

# the panel GRUB draws on: GRUB_GFXMODE=auto takes the firmware's native mode
panel_height() {
    local best=0 internal=0 conn h
    for conn in /sys/class/drm/card*-*; do
        [[ -r "$conn/status" && "$(<"$conn/status")" == connected ]] || continue
        h="$(head -n 1 "$conn/modes" 2>/dev/null)" || continue
        h="${h#*x}"
        h="${h%%[!0-9]*}"
        [[ -n "$h" ]] || continue
        [[ "$conn" == *-eDP-* ]] && internal="$h"
        ((h > best)) && best="$h"
    done
    if ((internal)); then
        echo "$internal"
    elif ((best)); then
        echo "$best"
    else
        echo 1080
    fi
}
height="${GRUB_THEME_HEIGHT:-$(panel_height)}"
[[ "$height" =~ ^[0-9]+$ ]] || die "bad panel height: $height"
# scale in quarter steps from a 1080-line panel, 1x to 2.5x
q=$(((height * 4 + 540) / 1080))
((q < 4)) && q=4
((q > 10)) && q=10
px() { echo $((($1 * q + 2) / 4)); }

col() {
    local v
    v="$(jq -r --arg k "$1" '.semantic[$k] // .primitives[$k] // empty' "$palette")"
    [[ "$v" =~ ^#[0-9a-fA-F]{6}$ ]] || die "palette has no colour $1"
    echo "$v"
}
font_ui="$(jq -r '.typography.font.ui' "$palette")"
font_mono="$(jq -r '.typography.font.mono' "$palette")"
weight_ui="$(jq -r '.typography.weight.ui' "$palette")"

# file and face index of a family at a CSS weight; the index carries the named instance of a
# variable font (Nunito's Medium is instance 4), which grub-mkfont passes on to FreeType
font_face() {
    local fam="$1" weight="$2" style found
    case "$weight" in
        100) style=thin ;; 200) style=extralight ;; 300) style=light ;; 500) style=medium ;;
        600) style=semibold ;; 700) style=bold ;; 800) style=extrabold ;; 900) style=black ;;
        *) style=regular ;;
    esac
    found="$(fc-match -f '%{family[0]}|%{file}|%{index}' "$fam:$style")"
    [[ "${found%%|*}" == "$fam" ]] || die "font $fam is not installed (fc-match gave ${found%%|*})"
    echo "${found#*|}"
}
ui_face="$(font_face "$font_ui" "$weight_ui")"
mono_face="$(font_face "$font_mono" 400)"

# sizes at 1x, scaled. The selected entry's pill is item_h plus r above and below (GRUB draws
# its box's corners outside the item), with the text pill_x in from its left edge.
item_px=$(px 17) hint_px=$(px 13) mono_px=$(px 16)
r=$(px 8)
pill_x=$(px 14)
item_h=$(px 22)
item_gap=$((2 * r + $(px 4)))
logo_w=$(px 150)
logo_h=$(((logo_w * 668 + 348) / 696))
# GRUB never draws a progress bar smaller than 200x28, so the timeout bar is a 28-line box whose
# pieces are transparent but for a line of bar_line through its middle
bar_box=28
bar_line=2
bar_pad=$(((bar_box - bar_line) / 2))
bar_w=$(px 200)

declare -A tok=(
    [bg]="$(col surface_1)" [fg]="$(col text_muted)" [fg_bright]="$(col text_bright)"
    [yolk]="$(col accent_primary)" [hint]="$(col text_line_number)"
    [white]="$(col text_bright)" [cut]="$(col surface_1)"
    [mono_px]="$mono_px" [item_px]="$item_px" [hint_px]="$hint_px"
    [logo_w]="$logo_w" [logo_h]="$logo_h" [logo_half_w]=$((logo_w / 2)) [logo_top]=$(px 200)
    [bar_w]="$bar_w" [bar_half_w]=$((bar_w / 2)) [bar_h]="$bar_box" [bar_top]=$(($(px 30) + bar_pad))
    [menu_w]=$(px 340) [menu_half_w]=$(($(px 340) / 2)) [menu_off]=$((r + $(px 2))) [menu_h]=$(px 260)
    [item_h]="$item_h" [item_gap]="$item_gap"
    [hint_bottom]=$(px 56) [hint_h]=$(px 24)
)
fill() {
    local text key
    text="$(<"$1")"
    for key in "${!tok[@]}"; do
        text="${text//@$key@/${tok[$key]}}"
    done
    [[ "$(grep -v "@name@" <<<"$text")" != *@[a-z_]*@* ]] || die "unfilled token in $1: $(grep -o '@[a-z_]*@' <<<"$text" | head -n 1)"
    printf '%s\n' "$text"
}

# what the build depends on
want="$(
    {
        jq -c '[.semantic, .typography]' "$palette"
        cat "$src/theme.txt" "$src/logo.svg" "${BASH_SOURCE[0]}"
        echo "scale $q ui $ui_face $(stat -c '%s %Y' "${ui_face%|*}") mono $mono_face $(stat -c '%s %Y' "${mono_face%|*}")"
    } | sha256sum | cut -d' ' -f1
)"

if [[ "$mode" == check || "$mode" == install ]]; then
    have=""
    [[ -r "$stamp" ]] && have="$(<"$stamp")"
    if [[ "$have" == "$want" && -f "$dest/theme.txt" ]]; then
        [[ "$mode" == check ]] || echo "grub-theme: $dest is current"
        exit 0
    fi
    if [[ "$mode" == check ]]; then
        if [[ -z "$have" ]]; then
            echo "grub-theme: not installed yet"
        else
            echo "grub-theme: the palette, the fonts, the templates or the panel scale changed"
        fi
        exit 1
    fi
fi

build="$out"
if [[ "$mode" != build ]]; then
    build="$(mktemp -d)"
    trap 'rm -rf "$build"' EXIT
fi
mkdir -p "$build"

fill "$src/theme.txt" >"$build/theme.txt"
fill "$src/logo.svg" | rsvg-convert -w "$logo_w" -h "$logo_h" -o "$build/logo.png"

# GRUB's nine-piece boxes (PREFIX_nw.png ... PREFIX_c.png), cut from one SVG shape of
# (2 * pad_x + 1) x (2 * pad_y + 1): the corners and edges keep their size, the centre row and
# column stretch. slice PREFIX PAD_X PAD_Y SHAPE
slice() {
    local prefix="$1" x="$2" y="$3" shape="$4" name w h vx vy
    for name in nw n ne w c e sw s se; do
        case "$name" in
            nw | w | sw) w="$x" vx=0 ;;
            n | c | s) w=1 vx="$x" ;;
            *) w="$x" vx=$((x + 1)) ;;
        esac
        case "$name" in
            nw | n | ne) h="$y" vy=0 ;;
            w | c | e) h=1 vy="$y" ;;
            *) h="$y" vy=$((y + 1)) ;;
        esac
        printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s %s %s %s">%s</svg>' \
            "$w" "$h" "$vx" "$vy" "$w" "$h" "$shape" | rsvg-convert -o "$build/${prefix}_$name.png"
    done
}
# selected entry: a rounded rect of radius r, the text pill_x in from its edge
slice select "$pill_x" "$r" "<rect width=\"$((2 * pill_x + 1))\" height=\"$((2 * r + 1))\" rx=\"$r\" fill=\"$(col selection_bg)\"/>"
# every other entry: an invisible box of the same size, so all rows sit at the same offset
slice item "$pill_x" "$r" ""
# the console (c) and the entry editor (e): the whole screen in the background colour
slice terminal_box 1 1 "<rect width=\"3\" height=\"3\" fill=\"$(col surface_1)\"/>"
# timeout: the track and, drawn over it, the remaining time
line() { echo "<rect y=\"$bar_pad\" width=\"3\" height=\"$bar_line\" fill=\"$1\"/>"; }
slice bar 1 "$bar_pad" "$(line "$(col surface_2)")"
slice highlight 1 "$bar_pad" "$(line "$(col accent_primary)")"

# printable ASCII and Latin-1 plus the box and arrow glyphs GRUB's console and editor use
ranges=0x20-0x7e,0xa0-0x17f,0x2190-0x21ff,0x2500-0x259f
grub-mkfont -r "$ranges" -i "${ui_face#*|}" -s "$item_px" -n eggfriedrice -o "$build/ui-$item_px.pf2" "${ui_face%|*}"
if [[ "$hint_px" != "$item_px" ]]; then
    grub-mkfont -r "$ranges" -i "${ui_face#*|}" -s "$hint_px" -n eggfriedrice -o "$build/ui-$hint_px.pf2" "${ui_face%|*}"
fi
grub-mkfont -r "$ranges" -i "${mono_face#*|}" -s "$mono_px" -n eggfriedrice-mono -o "$build/mono-$mono_px.pf2" "${mono_face%|*}"

if [[ "$mode" == build ]]; then
    echo "grub-theme: built $build (panel $height lines, scale $q/4)"
    exit 0
fi

printf '%s\n' "$want" >"$build/.eggfriedrice-stamp"
sudo rm -rf "$dest.new"
sudo mkdir -p "$dest.new"
sudo cp "$build"/* "$build/.eggfriedrice-stamp" "$dest.new/"
sudo rm -rf "$dest"
sudo mv "$dest.new" "$dest"
echo "grub-theme: installed $dest (panel $height lines, scale $q/4)"
