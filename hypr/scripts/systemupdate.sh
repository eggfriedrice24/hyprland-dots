#!/usr/bin/env bash
# The launcher for an interactive update without a terminal: dots-update in a Ghostty window that
# stays open after it ends. dots-update names it when it is started where it cannot ask questions.
#
#   systemupdate.sh up

[[ -f /etc/arch-release ]] || exit 0

script="$(readlink -f "${BASH_SOURCE[0]}")"
dotfiles="$(dirname "$(dirname "$(dirname "$script")")")"

if [[ "${1:-}" == up ]]; then
    exec ghostty --title=dots-update --wait-after-command=true -e "$dotfiles/bin/dots-update"
fi
echo "Usage: $0 up   run dots-update in a Ghostty window" >&2
exit 1
