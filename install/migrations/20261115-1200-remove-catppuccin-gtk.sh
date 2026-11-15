#!/usr/bin/env bash
# Remove catppuccin-gtk-theme-mocha and its yay build directory: adw-gtk3-dark replaced it
#
# The package left install/packages/aur.txt on 2026-11-14 (d8eee6b). A machine installed before
# that still carries it; the desktop removed it by hand, so there only the build cache goes.

# never pull the theme out from under GTK: stage 6 has to have switched to adw-gtk3-dark first
current_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
if [[ "${current_theme,,}" == *catppuccin* ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        warn "GTK still uses ${current_theme}; a real run switches it to adw-gtk3-dark in stage 6 first"
    else
        error "GTK still uses ${current_theme}; run ./install.sh so stage 6 applies adw-gtk3-dark, then retry"
        exit 1
    fi
fi

remove_packages catppuccin-gtk-theme-mocha
remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/yay/catppuccin-gtk-theme-mocha"
