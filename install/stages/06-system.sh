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
grub_file=/etc/default/grub
grub_changed=0

# grub_add_param VAR PARAM [KEY]: make PARAM one of the words of VAR. Words matching KEY, an ERE
# for the parameter's name (default: PARAM up to its "="), are replaced instead of a second value
# being appended, so a moved connector (video=DP-3 -> DP-1) leaves nothing behind. Only a single,
# plain double-quoted assignment is edited; anything else gets a warning and is left alone.
grub_add_param() {
    local var="$1" param="$2" key="${3:-}"
    if [[ -z "$key" ]]; then
        key="${param%%=*}="
        key="${key//./\\.}"
    fi
    local line
    line="$(grep -E "^${var}=" "$grub_file" || true)"
    if [[ -z "$line" ]]; then
        warn "$var not found in $grub_file; add $param to the kernel command line by hand"
        return 0
    fi
    local plain_re='^'"$var"'="([^"$`\\]*)"[[:space:]]*$'
    if [[ "$line" == *$'\n'* || ! "$line" =~ $plain_re ]]; then
        warn "$var in $grub_file is not a single plain double-quoted value; add $param by hand"
        return 0
    fi

    local -a words kept=() replaced=()
    local word has=0
    read -ra words <<<"${BASH_REMATCH[1]}"
    for word in "${words[@]}"; do
        if [[ "$word" == "$param" && $has -eq 0 ]]; then
            kept+=("$word")
            has=1
        elif [[ "$word" == "$param" || "$word" =~ ^${key} ]]; then
            # the first old value is replaced in place, later ones are dropped
            replaced+=("$word")
            if [[ $has -eq 0 ]]; then
                kept+=("$param")
                has=1
            fi
        else
            kept+=("$word")
        fi
    done
    if [[ $has -eq 1 && ${#replaced[@]} -eq 0 ]]; then
        success "GRUB $var already has $param"
        return 0
    fi
    if [[ $has -eq 0 ]]; then
        kept+=("$param")
    fi

    local new="${kept[*]}" escaped
    if (( ${#replaced[@]} )); then
        info "Replacing ${replaced[*]} with $param in GRUB $var"
    else
        info "Adding $param to GRUB $var"
    fi
    escaped="$(printf '%s' "$new" | sed 's/[\\|&]/\\&/g')"
    run sudo sed -i -E "s|^${var}=.*|${var}=\"${escaped}\"|" "$grub_file"

    # only a verified edit triggers grub-mkconfig
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
        local after
        after="$(grep -E "^${var}=" "$grub_file" || true)"
        if [[ "$after" != "${var}=\"${new}\"" ]]; then
            warn "GRUB $var did not take $param (now: ${after:-missing}); add it by hand"
            return 0
        fi
    fi
    grub_changed=1
}

if [[ -f "$grub_file" ]]; then
    grub_add_param GRUB_CMDLINE_LINUX "zswap.enabled=0" # zram replaces zswap
    if [[ "$MACHINE" == "desktop" ]]; then
        # ASUS OLED on DP-1: fix the link at boot so login does not retrain it (see hypr/hyprland.lua).
        # The key also matches an older video=DP-N: entry (the monitor was on DP-3 until Sep 10).
        grub_add_param GRUB_CMDLINE_LINUX_DEFAULT "video=DP-1:2560x1440@240" 'video=DP-[0-9]+:'
    fi
    if grep -q '^GRUB_TIMEOUT=2$' "$grub_file"; then
        success "GRUB timeout already 2s"
    else
        info "Setting GRUB timeout to 2s"
        run sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$grub_file"
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
            try "gsettings $key $value" gsettings set org.gnome.desktop.interface "$key" "$value"
        else
            # no session bus on a TTY install: give dconf a private one
            try "gsettings $key $value" dbus-run-session -- gsettings set org.gnome.desktop.interface "$key" "$value"
        fi
    }
    # adw-gtk3 draws everything from named colors, which gtk-3.0/gtk.css redefines from the palette
    gset gtk-theme "'adw-gtk3-dark'"
    # Papirus-Dark with the palette's folders, built into ~/.local/share/icons by papirus-folders.sh
    if run "$DOTFILES_DIR/install/papirus-folders.sh"; then
        gset icon-theme "'Papirus-Dark-eggfriedrice'"
    else
        warn "Papirus folder recolor failed, icon theme left as is"
    fi
    gset color-scheme "'prefer-dark'"
    gset cursor-size "24"
else
    warn "gsettings not found, GTK theme not applied"
fi

success "=== Stage 6: Complete ==="
