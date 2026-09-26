#!/usr/bin/env bash
# Pending update count (official + AUR) and, with "up", an interactive upgrade in ghostty

[ -f /etc/arch-release ] || exit 0

helper=$(command -v yay || command -v paru) || { echo "no AUR helper"; exit 1; }

aur=$("$helper" -Qua 2>/dev/null | wc -l)
ofc=$(pacman -Qu 2>/dev/null | wc -l)
upd=$(( ofc + aur ))
echo "$upd"

if [ "$upd" -eq 0 ]; then
    echo " Packages are up to date"
else
    echo "󱓽 Official $ofc 󱓾 AUR $aur"
fi

if [ "${1:-}" = "up" ]; then
    ghostty --title=systemupdate -e sh -c "$helper -Syu"
fi
