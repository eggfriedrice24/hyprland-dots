#!/usr/bin/env bash
# Remove kitty and its leftover config directory or link: ghostty replaced it
#
# kitty left the package lists and stage 3 on 2026-08-09 (f363867). A machine set up before then
# has the package and ~/.config/kitty, a link into the dotfiles that no longer resolves; the
# desktop has an empty directory there. A directory that still holds files is left alone.

kitty_config="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"

if has_exact_pkg kitty; then
    require_package ghostty "the terminal that replaces kitty"
    remove_packages kitty
else
    success "Already absent: kitty"
fi

if [[ -L "$kitty_config" ]]; then
    remove_path "$kitty_config"
elif [[ -d "$kitty_config" ]]; then
    if [[ -z "$(ls -A "$kitty_config")" ]]; then
        remove_path "$kitty_config"
    else
        warn "Leaving ${kitty_config/#$HOME/\~} in place, it holds files of its own; delete it by hand if they are not needed"
    fi
else
    success "Already absent: $kitty_config"
fi
