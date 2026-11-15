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

# Full upgrade first: installing on top of a stale database is a partial upgrade.
# The keyring goes first so packages signed by newly added packager keys verify.
info "Refreshing package database and archlinux-keyring..."
run sudo pacman -Sy --needed --noconfirm archlinux-keyring
info "Upgrading the system..."
run sudo pacman -Su --noconfirm

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

# Clone and build yay-bin; returns non-zero instead of aborting (AUR down, makepkg failure)
bootstrap_yay() {
    local tmpdir status=0
    tmpdir="$(mktemp -d)" || return 1
    if ! git clone --quiet https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin" ||
        ! (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm); then
        status=1
    fi
    rm -rf "$tmpdir"
    return "$status"
}

aur_lists=(aur)
if [[ "$MACHINE" == "desktop" ]]; then
    aur_lists+=(aur-desktop)
fi

# AUR helper: yay is what the existing machines use; bootstrap yay-bin when nothing is present
AUR_HELPER=""
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
        AUR_HELPER="yay"
    elif bootstrap_yay; then
        success "yay installed"
        AUR_HELPER="yay"
    else
        # the official packages are in; everything after this stage still works without the AUR ones
        warn "Could not build yay-bin, skipping the AUR lists: ${aur_lists[*]}"
        FAILED+=("yay-bin bootstrap; AUR lists not installed: ${aur_lists[*]}")
    fi
fi
export AUR_HELPER

if [[ -n "$AUR_HELPER" ]]; then
    for list in "${aur_lists[@]}"; do
        install_aur_packages "${DOTFILES_DIR}/install/packages/${list}.txt"
    done
fi

success "=== Stage 1: Complete ==="
