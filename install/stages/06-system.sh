#!/usr/bin/env bash
# Stage 6: System configuration outside $HOME: the profile's /etc files, zram, wireless
# regulatory domain, GRUB command line, GTK settings, then the profile's hooks

info "=== Stage 6: System configuration ==="

etc_src="${DOTFILES_DIR}/install/etc"

# Machine profile /etc files (machines/<layer>/etc/, laid out like /etc), base layer first:
# kernel module options for the desktop's WiFi and Bluetooth, sshd hardening on laptops
mapfile -t etc_trees < <(profile_files etc)
for tree in "${etc_trees[@]}"; do
    install_etc_tree "$tree"
    for changed in ${ETC_TREE_CHANGED[@]+"${ETC_TREE_CHANGED[@]}"}; do
        case "$changed" in
            /etc/modprobe.d/*) note reboot "kernel module options changed ($changed)" ;;
            /etc/ssh/sshd_config.d/*) note restart "sshd, for $changed: sudo systemctl restart sshd" ;;
        esac
    done
done

# zram swap
if has_pkg zram-generator; then
    install_etc_file "$etc_src/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf
    if (( ETC_FILE_CHANGED )); then
        note reboot "the zram swap device is sized at boot (/etc/systemd/zram-generator.conf changed)"
    fi
fi

# Wireless regulatory domain: FR active and no other domain active (the file is sourced, so a
# second uncommented line would win or lose depending on its position)
regdom_conf=/etc/conf.d/wireless-regdom
if [[ -f "$regdom_conf" ]]; then
    other_regdoms="$(grep '^WIRELESS_REGDOM=' "$regdom_conf" | grep -v '^WIRELESS_REGDOM="FR"$' || true)"
    if [[ -z "$other_regdoms" ]] && grep -q '^WIRELESS_REGDOM="FR"$' "$regdom_conf"; then
        success "wireless regdom already FR"
    else
        info "Setting wireless regdom to FR..."
        # comment every active domain, then enable FR (appended when the stock FR line is missing)
        if grep -Eq '^#?WIRELESS_REGDOM="FR"$' "$regdom_conf"; then
            run sudo sed -i -e 's/^WIRELESS_REGDOM=/#&/' -e 's/^#WIRELESS_REGDOM="FR"$/WIRELESS_REGDOM="FR"/' "$regdom_conf"
        else
            run sudo sed -i -e 's/^WIRELESS_REGDOM=/#&/' -e '$a WIRELESS_REGDOM="FR"' "$regdom_conf"
        fi
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

# kernel_param VAR PARAM [KEY]: through grub_add_param where GRUB is the bootloader, otherwise
# collected for one warning (this stage only knows how to edit GRUB)
manual_params=()
kernel_param() {
    if [[ -f "$grub_file" ]]; then
        grub_add_param "$@"
    else
        manual_params+=("$2")
    fi
}

kernel_param GRUB_CMDLINE_LINUX "zswap.enabled=0" # zram replaces zswap

# Machine profile kernel parameters (machines/<layer>/grub: "VARIABLE PARAMETER [KEY]" per line)
mapfile -t grub_lists < <(profile_files grub)
for list in "${grub_lists[@]}"; do
    grub_layer="$(layer_of "$list")"
    while read -r grub_var grub_param grub_key || [[ -n "$grub_var" ]]; do
        [[ -z "$grub_var" || "$grub_var" == \#* ]] && continue
        if [[ -z "$grub_param" ]]; then
            warn "machines/${grub_layer}/grub: no parameter after $grub_var, line skipped"
            continue
        fi
        kernel_param "$grub_var" "$grub_param" ${grub_key:+"$grub_key"}
    done < "$list"
done

if [[ -f "$grub_file" ]]; then
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
            note reboot "the kernel command line changed"
        else
            warn "grub-mkconfig not found, regenerate the bootloader config by hand"
        fi
    fi
else
    warn "No $grub_file, so GRUB is not the bootloader here; add these kernel parameters to its boot entries by hand: ${manual_params[*]}"
fi

# GTK theme and dark mode live in dconf; nothing in the dotfiles carries them otherwise
if has_cmd gsettings gsettings-desktop-schemas; then # gsettings is glib2's, pulled in by the schemas
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
    # only when its stamp says the palette, the script or Papirus changed (install/theme-apply.sh)
    # shellcheck source=install/theme-apply.sh
    source "${DOTFILES_DIR}/install/theme-apply.sh"
    if theme_apply_papirus; then
        gset icon-theme "'Papirus-Dark-eggfriedrice'"
    else
        warn "Papirus folder recolor failed, icon theme left as is"
    fi
    gset color-scheme "'prefer-dark'"
    gset cursor-size "24"
    # the theme's ui font (font.ui at weight.ui and size.sm in typography.lua); GTK3 has no CSS
    # variables, so this setting is how GTK apps get it. monospace-font-name is left as it is
    gset font-name "'Nunito Medium 10'"
else
    warn "gsettings not found, GTK theme not applied"
fi

# Machine profile hooks (machines/<layer>/system.sh) for edits that are not whole files,
# sourced with these helpers, base layer first
mapfile -t system_hooks < <(profile_files system.sh)
for hook in "${system_hooks[@]}"; do
    info "Running the $(layer_of "$hook") profile hook"
    # shellcheck source=/dev/null
    source "$hook"
done

success "=== Stage 6: Complete ==="
