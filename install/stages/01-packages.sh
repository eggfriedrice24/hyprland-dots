#!/usr/bin/env bash
# Stage 1: Install packages via pacman and AUR

info "=== Stage 1: Packages ==="

# Refresh pacman database
info "Refreshing package database..."
run sudo pacman -Sy

# Install official repo packages
for list in base hyprland audio apps dev fonts; do
    install_packages "${DOTFILES_DIR}/install/packages/${list}.txt"
done

# Bootstrap AUR helper if needed
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    success "AUR helper found: paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    success "AUR helper found: yay"
else
    info "No AUR helper found, bootstrapping paru..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        printf "${YELLOW}[DRY-RUN]${NC} clone and install paru-bin from AUR\n"
        AUR_HELPER="paru"
    else
        tmpdir="$(mktemp -d)"
        git clone https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
        (cd "$tmpdir/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        AUR_HELPER="paru"
        success "paru installed"
    fi
fi

export AUR_HELPER

# Install AUR packages
install_aur_packages "${DOTFILES_DIR}/install/packages/aur.txt"

success "=== Stage 1: Complete ==="
