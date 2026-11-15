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

# Packages the lists replace through a conflict. `pacman -S --noconfirm` answers No to "Remove rust?",
# so the install would fail halfway; stop before anything changes and print the command to run.
# Exact names only: `pacman -Qq rust` also answers for rustup, which provides rust.
installed_exact() {
    local names
    names="$(pacman -Qq "$1" 2>/dev/null)" || return 1
    [[ $'\n'"$names"$'\n' == *$'\n'"$1"$'\n'* ]]
}
conflicting=()
replacements=()
for pair in rust:rustup jack2:pipewire-jack pulseaudio:pipewire-pulse; do
    if installed_exact "${pair%%:*}"; then
        conflicting+=("${pair%%:*}")
        replacements+=("${pair##*:}")
    fi
done
if (( ${#conflicting[@]} )); then
    conflict_cmd="sudo pacman -S ${replacements[*]}"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        warn "${conflicting[*]} conflict with ${replacements[*]}; a real run stops here until you run: $conflict_cmd"
    else
        error "${conflicting[*]} conflict with ${replacements[*]} and --noconfirm will not remove them."
        error "Run this, answer y to each removal, then rerun the installer: $conflict_cmd"
        return 1
    fi
fi

# Full upgrade first: installing on top of a stale database is a partial upgrade.
# The keyring goes first so packages signed by newly added packager keys verify.
# --no-upgrade: the caller (dots-update) has just synced the databases and upgraded.
if [[ "${NO_UPGRADE:-0}" == "1" ]]; then
    success "Keyring refresh and full upgrade already done by the caller"
else
    info "Refreshing package database and archlinux-keyring..."
    run sudo pacman -Sy --needed --noconfirm archlinux-keyring
    info "Upgrading the system..."
    run sudo pacman -Su --noconfirm
fi

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

# Official repo packages. Audio before hyprland so waybar picks pipewire-jack as its JACK provider;
# fonts before apps so steam's ttf-font dependency is already met by noto-fonts (not gnu-free-fonts)
for list in base system audio hyprland fonts apps dev; do
    install_packages "${DOTFILES_DIR}/install/packages/${list}.txt"
done

# Machine profile packages (machines/<layer>/packages.txt), base layer first
mapfile -t profile_lists < <(profile_files packages.txt)
for list in "${profile_lists[@]}"; do
    install_packages "$list" "$(layer_of "$list") profile"
done

# Clone and build yay-bin; returns non-zero instead of aborting (AUR down, makepkg failure)
bootstrap_yay() {
    local tmpdir status=0
    tmpdir="$(mktemp -d)" || return 1
    if ! git clone --quiet https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin" ||
        ! (cd "$tmpdir/yay-bin" && makepkg -sir --noconfirm); then # -r: drop the build-only deps again
        status=1
    fi
    rm -rf "$tmpdir"
    return "$status"
}

# AUR lists: the shared one, then the profile layers' aur.txt
aur_lists=("${DOTFILES_DIR}/install/packages/aur.txt")
aur_labels=(aur)
mapfile -t profile_aur_lists < <(profile_files aur.txt)
for list in "${profile_aur_lists[@]}"; do
    aur_lists+=("$list")
    aur_labels+=("$(layer_of "$list") profile")
done

# No <pkg>-debug packages from AUR builds (yay-bin's own included), before anything is built
install_etc_file "${DOTFILES_DIR}/install/etc/makepkg.conf.d/no-debug.conf" /etc/makepkg.conf.d/no-debug.conf

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
        warn "Could not build yay-bin, skipping the AUR lists: ${aur_labels[*]}"
        FAILED+=("yay-bin bootstrap; AUR lists not installed: ${aur_labels[*]}")
    fi
fi
export AUR_HELPER

if [[ -n "$AUR_HELPER" ]]; then
    for i in "${!aur_lists[@]}"; do
        install_aur_packages "${aur_lists[$i]}" "${aur_labels[$i]}"
    done
fi

success "=== Stage 1: Complete ==="
