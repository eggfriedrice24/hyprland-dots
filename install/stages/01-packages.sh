#!/usr/bin/env bash
# Stage 1: Enable multilib, sync the system, install pacman and AUR packages

info "=== Stage 1: Packages ==="

# [multilib] is needed for steam and every lib32-* package; a stock pacman.conf ships it commented out
if grep -q '^\[multilib\]' /etc/pacman.conf; then
    success "multilib repository already enabled"
else
    info "Enabling multilib repository..."
    run sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi

# Full upgrade first: installing on top of a stale database is a partial upgrade
info "Refreshing package database and upgrading the system..."
run sudo pacman -Syu --noconfirm

# Hardware-specific packages: CPU microcode and Vulkan driver by detected vendor.
# Installed before apps so steam's vulkan-driver dependency resolves to the right provider.
detect_hardware_packages() {
    local -a pkgs=()
    if grep -q 'AuthenticAMD' /proc/cpuinfo; then
        pkgs+=(amd-ucode)
    elif grep -q 'GenuineIntel' /proc/cpuinfo; then
        pkgs+=(intel-ucode)
    fi

    local dev class vendor
    for dev in /sys/bus/pci/devices/*; do
        class="$(<"$dev/class")"
        [[ "$class" == 0x03* ]] || continue # display controllers only
        vendor="$(<"$dev/vendor")"
        case "$vendor" in
            0x1002) pkgs+=(vulkan-radeon lib32-vulkan-radeon) ;;
            0x8086) pkgs+=(vulkan-intel lib32-vulkan-intel) ;;
            0x10de) pkgs+=(nvidia-utils lib32-nvidia-utils) ;;
        esac
    done

    if (( ${#pkgs[@]} )); then
        printf '%s\n' "${pkgs[@]}" | sort -u
    fi
}

mapfile -t hardware_pkgs < <(detect_hardware_packages)
if (( ${#hardware_pkgs[@]} )); then
    info "Detected hardware packages: ${hardware_pkgs[*]}"
    install_package_names hardware "${hardware_pkgs[@]}"
else
    warn "Could not detect CPU or GPU vendor, no microcode or Vulkan driver selected"
fi

# Official repo packages (audio before hyprland so waybar picks pipewire-jack as its JACK provider)
for list in base system audio hyprland apps dev fonts; do
    install_packages "${DOTFILES_DIR}/install/packages/${list}.txt"
done

# AUR helper: yay is what the existing machines use; bootstrap yay-bin when nothing is present
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    success "AUR helper found: yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    success "AUR helper found: paru"
else
    info "No AUR helper found, bootstrapping yay-bin..."
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "clone and install yay-bin from AUR"
    else
        tmpdir="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
        (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        success "yay installed"
    fi
    AUR_HELPER="yay"
fi
export AUR_HELPER

install_aur_packages "${DOTFILES_DIR}/install/packages/aur.txt"
if [[ "$MACHINE" == "desktop" ]]; then
    install_aur_packages "${DOTFILES_DIR}/install/packages/aur-desktop.txt"
fi

success "=== Stage 1: Complete ==="
