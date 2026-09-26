#!/usr/bin/env bash
# Stage 6: System configuration outside $HOME: kernel module options, zram, bluetooth,
# wireless regulatory domain, GRUB command line, GTK settings

info "=== Stage 6: System configuration ==="

etc_src="${DOTFILES_DIR}/install/etc"

# Kernel module options
install_etc_file "$etc_src/modprobe.d/btusb-no-autosuspend.conf" /etc/modprobe.d/btusb-no-autosuspend.conf
if [[ "$MACHINE" == "desktop" ]]; then
    # rtw89 WiFi card: ASPM and power save off, cures the periodic stalls (costs power, so desktop only)
    install_etc_file "$etc_src/modprobe.d/rtw89.conf" /etc/modprobe.d/rtw89.conf
fi

# zram swap
if has_pkg zram-generator; then
    install_etc_file "$etc_src/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
fi

# Bluetooth: advertise as fast-connectable (quicker headphone and keyboard reconnects)
if [[ -f /etc/bluetooth/main.conf ]]; then
    if grep -q '^FastConnectable = true' /etc/bluetooth/main.conf; then
        success "bluetooth FastConnectable already on"
    else
        info "Enabling bluetooth FastConnectable..."
        run sudo sed -i 's/^#\?FastConnectable = .*/FastConnectable = true/' /etc/bluetooth/main.conf
    fi
fi

# Wireless regulatory domain
if [[ -f /etc/conf.d/wireless-regdom ]]; then
    if grep -q '^WIRELESS_REGDOM="FR"' /etc/conf.d/wireless-regdom; then
        success "wireless regdom already FR"
    else
        info "Setting wireless regdom to FR..."
        run sudo sed -i 's/^#WIRELESS_REGDOM="FR"$/WIRELESS_REGDOM="FR"/' /etc/conf.d/wireless-regdom
    fi
fi

# GRUB kernel command line
grub_changed=0
grub_add_param() {
    local var="$1" param="$2"
    local line
    line="$(grep -E "^${var}=" /etc/default/grub || true)"
    if [[ -z "$line" ]]; then
        warn "$var not found in /etc/default/grub, skipping $param"
        return 0
    fi
    if [[ "$line" == *"$param"* ]]; then
        success "GRUB $var already has $param"
        return 0
    fi
    info "Adding $param to GRUB $var"
    run sudo sed -i -E "s|^(${var}=\")(.*)\"[[:space:]]*$|\1\2 ${param}\"|; s|^(${var}=\") |\1|" /etc/default/grub
    grub_changed=1
}

if [[ -f /etc/default/grub ]]; then
    grub_add_param GRUB_CMDLINE_LINUX "zswap.enabled=0" # zram replaces zswap
    if [[ "$MACHINE" == "desktop" ]]; then
        # ASUS OLED on DP-1: fix the link at boot so login does not retrain it (see hypr/hyprland.lua)
        grub_add_param GRUB_CMDLINE_LINUX_DEFAULT "video=DP-1:2560x1440@240"
    fi
    if grep -q '^GRUB_TIMEOUT=2$' /etc/default/grub; then
        success "GRUB timeout already 2s"
    else
        info "Setting GRUB timeout to 2s"
        run sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
        grub_changed=1
    fi
    if [[ $grub_changed -eq 1 ]]; then
        if command -v grub-mkconfig &>/dev/null; then
            info "Regenerating grub.cfg..."
            run sudo grub-mkconfig -o /boot/grub/grub.cfg
        else
            warn "grub-mkconfig not found, regenerate the bootloader config by hand"
        fi
    fi
else
    info "No /etc/default/grub, skipping kernel command line"
fi

# GTK theme and dark mode live in dconf; nothing in the dotfiles carries them otherwise
if command -v gsettings &>/dev/null; then
    gset() {
        local key="$1" value="$2"
        if [[ "$(gsettings get org.gnome.desktop.interface "$key" 2>/dev/null)" == "$value" ]]; then
            success "gsettings $key already $value"
            return 0
        fi
        info "gsettings $key = $value"
        if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
            run gsettings set org.gnome.desktop.interface "$key" "$value"
        else
            # no session bus on a TTY install: give dconf a private one
            run dbus-run-session -- gsettings set org.gnome.desktop.interface "$key" "$value"
        fi
    }
    gset gtk-theme "'catppuccin-mocha-yellow-standard+default'"
    gset color-scheme "'prefer-dark'"
    gset cursor-size "24"
else
    warn "gsettings not found, GTK theme not applied"
fi

success "=== Stage 6: Complete ==="
