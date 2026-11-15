#!/usr/bin/env bash
# Stage 7: Snapshots, on the btrfs layout bootstrap.sh builds only (/ on @, /.snapshots on
# @snapshots, snapper): snapper's retention and the pacman hook that keeps the outgoing kernel on
# the ESP, so a pre-update snapshot stays bootable. bin/dots-snapshot relies on both.
# Anywhere else (this ext4 desktop, a btrfs root made by hand) the stage is one line and changes
# nothing: it never creates a snapper config on a layout bootstrap.sh did not build.

snap_rc=0
snap_reason="$("${DOTFILES_DIR}/bin/dots-snapshot" status 2>/dev/null)" || snap_rc=$?
if ! has_snapshots || (( snap_rc == 2 )); then
    info "=== Stage 7: Snapshots: skipped, ${snap_reason:-no snapshot layout here} ==="
    return 0
fi

info "=== Stage 7: Snapshots ==="

# snapper config "root" on the existing @snapshots subvolume. bootstrap.sh writes it; this puts it
# back when it is missing (`snapper create-config` refuses, /.snapshots already exists)
snapper_conf=/etc/snapper/configs/root
if [[ -e "$snapper_conf" ]]; then
    success "snapper config root exists"
else
    info "Creating the snapper config root for the @snapshots subvolume"
    run sudo install -Dm640 /usr/share/snapper/config-templates/default "$snapper_conf"
    snapper_configs="$(sed -n 's/^SNAPPER_CONFIGS="\(.*\)"$/\1/p' /etc/conf.d/snapper 2>/dev/null || true)"
    if [[ -z "$snapper_configs" ]]; then
        run sudo install -Dm644 /dev/stdin /etc/conf.d/snapper <<<'SNAPPER_CONFIGS="root"'
    elif [[ " $snapper_configs " != *" root "* ]]; then
        warn "/etc/conf.d/snapper lists other configs ($snapper_configs); add root to SNAPPER_CONFIGS by hand"
    fi
fi

# Retention as bootstrap.sh sets it: 10 numbered snapshots plus 5 important ones (dots-update's
# pre and post pairs), no timeline, and wheel may use snapper without sudo (dots-snapshot pre/post)
snapper_text=""
if [[ -r "$snapper_conf" ]]; then
    snapper_text="$(<"$snapper_conf")"
elif [[ -e "$snapper_conf" ]] && { [[ "${DRY_RUN:-0}" != "1" ]] || sudo -n true 2>/dev/null; }; then
    snapper_text="$(sudo cat "$snapper_conf")"
fi
if [[ -z "$snapper_text" && -e "$snapper_conf" ]]; then
    warn "Cannot read $snapper_conf without sudo in a dry run; its retention is not checked"
else
    snapper_set=()
    for snapper_pair in ALLOW_GROUPS=wheel TIMELINE_CREATE=no NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5; do
        snapper_key="${snapper_pair%%=*}"
        snapper_now="$(sed -n "s/^${snapper_key}=\"\(.*\)\"\$/\1/p" <<<"$snapper_text" | tail -n1)"
        if [[ "$snapper_now" != "${snapper_pair#*=}" ]]; then
            snapper_set+=("$snapper_pair")
        fi
    done
    if (( ${#snapper_set[@]} )); then
        info "Setting in snapper config root: ${snapper_set[*]}"
        # --no-dbus: works inside the bootstrap chroot as well, where snapperd cannot run
        run sudo snapper --no-dbus -c root set-config "${snapper_set[@]}"
    else
        success "snapper keeps 10 snapshots plus 5 important ones, no timeline, wheel allowed"
    fi
fi

# /.snapshots readable by wheel, so dots-snapshot list works without sudo
if [[ "$(stat -c '%a %G' /.snapshots 2>/dev/null)" == "750 wheel" ]]; then
    success "/.snapshots is root:wheel 750"
else
    info "Making /.snapshots root:wheel 750"
    run sudo chown root:wheel /.snapshots
    run sudo chmod 750 /.snapshots
fi

# The outgoing kernel and initramfs stay on the ESP as .old (the hook runs before
# 60-mkinitcpio-remove deletes them); the script first, so the hook never points at nothing
install_etc_file "${DOTFILES_DIR}/install/hooks/keep-old-kernel" /usr/local/share/libalpm/scripts/keep-old-kernel 755
install_etc_file "${DOTFILES_DIR}/install/etc/pacman.d/hooks/10-keep-old-kernel.hook" /etc/pacman.d/hooks/10-keep-old-kernel.hook

# snapper-cleanup applies the limits above; grub-btrfsd adds new snapshots to the GRUB menu
enable_system_service snapper-cleanup.timer
if has_pkg grub-btrfs; then
    enable_system_service grub-btrfsd
fi
# bootstrap.sh installs snap-pac last, after this stage; elsewhere its absence is worth a word
if ! has_pkg snap-pac && ! systemd-detect-virt --chroot &>/dev/null; then
    warn "snap-pac is not installed, so pacman runs outside dots-update get no snapshots: sudo pacman -S snap-pac"
fi

success "=== Stage 7: Complete ==="
