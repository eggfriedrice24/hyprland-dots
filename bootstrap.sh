#!/usr/bin/env bash
# Fresh Arch install from the live ISO, then the dotfiles installer, in one run.
#
#   curl -fsSL https://raw.githubusercontent.com/eggfriedrice24/hyprland-dots/master/bootstrap.sh -o bootstrap.sh
#   bash bootstrap.sh
#
# Layout it builds:
#   root disk (wiped):  2 GiB ESP at /boot (vfat, room for the .old kernels) | optional swap (default none) | btrfs root
#     btrfs subvolumes: @ /, @snapshots /.snapshots, @log /var/log, @pkg /var/cache/pacman/pkg, @docker /var/lib/docker,
#     @flatpak /var/lib/flatpak (kept out of root snapshots; postgres, valkey, bluetooth and tailscale stay in @)
#     snapper + snap-pac (snapshot per pacman transaction, keeps 10 plus 5 important) + grub-btrfs (boot
#     snapshots from the GRUB menu); vfat in the initramfs keeps /boot mountable when a snapshot boots with
#     a newer kernel; the dotfiles keep the outgoing kernel as .old on the ESP, and `dots-snapshot rollback`
#     puts a snapshot back together with its own kernel
#     monthly btrfs scrub of / (btrfs-scrub@-.timer)
#   /home: keep an existing ext4 partition untouched, format a whole second disk as ext4, or a @home subvolume
#   optional LUKS2: passphrase for root at boot, key file on root for a new /home disk, random-key swap
#   zram swap comes from the dotfiles (install/etc/systemd/zram-generator.conf)
set -Eeuo pipefail

# override to test unpushed commits, e.g. DOTFILES_REPO=http://10.0.2.2:8000/.git from a VM
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/eggfriedrice24/hyprland-dots.git}"
# extra install.sh arguments, e.g. INSTALL_ARGS="--profile framework" in a VM (DMI says generic there)
INSTALL_ARGS="${INSTALL_ARGS:-}"
# theme repo to clone in stage 2, e.g. THEME_REPO=http://10.0.2.2:8000/eggfriedrice.nvim.git from a VM
# (empty = the installer's default, GitHub)
THEME_REPO="${THEME_REPO:-}"
DOTFILES_PUSH="git@github.com:eggfriedrice24/hyprland-dots.git"
BTRFS_OPTS="noatime,compress=zstd:1"
ESP_GB=2

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' BLUE='\033[0;34m' BOLD='\033[1m' NC='\033[0m'
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
die() { error "$*"; exit 1; }
heading() { printf '%b%s%b\n' "$BOLD" "$*" "$NC"; }
trap 'error "bootstrap failed at line $LINENO: $BASH_COMMAND"' ERR
# the temporary NOPASSWD file must not outlive the run, whether it ends, dies or is interrupted.
# An EXIT trap only: bash runs it on INT and TERM too, while an INT handler would let the script go on.
SUDOERS_TMP=""
cleanup() { if [[ -n "$SUDOERS_TMP" ]]; then rm -f "$SUDOERS_TMP"; fi; }
trap cleanup EXIT

# stdin may be a pipe (curl | bash); prompts always read the terminal
ask() { # ask VAR "question" [default]
    local __var="$1" __q="$2" __def="${3:-}" __ans
    if [[ -n "$__def" ]]; then
        read -rp "$__q [$__def]: " __ans </dev/tty
        __ans="${__ans:-$__def}"
    else
        read -rp "$__q: " __ans </dev/tty
    fi
    printf -v "$__var" '%s' "$__ans"
}
ask_required() { # ask_required VAR "question" [default]: like ask, but asks again on an empty answer
    while :; do
        ask "$@"
        [[ -n "${!1}" ]] && break
        warn "An answer is required"
    done
}
ask_password() { # ask_password VAR "label"
    local __var="$1" __a __b
    while :; do
        read -rsp "$2: " __a </dev/tty; echo
        read -rsp "Repeat: " __b </dev/tty; echo
        [[ -n "$__a" && "$__a" == "$__b" ]] && break
        warn "Empty or not matching, try again"
    done
    printf -v "$__var" '%s' "$__a"
}
# /dev/nvme0n1 + 2 -> /dev/nvme0n1p2, /dev/sda + 2 -> /dev/sda2
part() { if [[ "$1" =~ [0-9]$ ]]; then echo "${1}p$2"; else echo "$1$2"; fi; }
disk_of() { echo "/dev/$(lsblk -no PKNAME "$1" | head -1)"; }
# the disk the ISO booted from, empty when it is not mounted (copytoram, CD-ROM, PXE)
iso_boot_disk() {
    local src pk
    src="$(findmnt -no SOURCE --mountpoint /run/archiso/bootmnt 2>/dev/null)" || return 0
    [[ -b "$src" ]] || return 0
    pk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"
    [[ -n "$pk" ]] && src="/dev/$pk"
    if [[ "$(lsblk -dno TYPE "$src" 2>/dev/null)" == disk ]]; then echo "$src"; fi
}

# ---------------------------------------------------------------- preflight
[[ $EUID -eq 0 ]] || die "Run as root from the Arch live ISO."
[[ -d /run/archiso ]] || die "This is not the Arch live ISO; refusing to partition a running system."
[[ -d /sys/firmware/efi ]] || die "Boot the ISO in UEFI mode."
ping -c1 -W3 archlinux.org &>/dev/null || die "No network. Use iwctl (WiFi) and retry."

timedatectl set-ntp true
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

# ---------------------------------------------------------------- questions
ISO_DISK="$(iso_boot_disk)"
echo
heading "Disks:"
# USB disks stay listed and selectable (Framework storage expansion cards are USB)
lsblk -dpno NAME,SIZE,TRAN,MODEL -e 7,11 | awk -v b="$ISO_DISK" '$1 != b && $1 !~ /zram/'
[[ -n "$ISO_DISK" ]] && echo "  ($ISO_DISK is the live ISO and not listed)"
echo
ask_required ROOT_DISK "Disk for the system (WILL BE WIPED)"
[[ -b "$ROOT_DISK" && "$(lsblk -dno TYPE "$ROOT_DISK")" == disk ]] || die "$ROOT_DISK is not a disk"
[[ "$ROOT_DISK" != "$ISO_DISK" ]] || die "$ROOT_DISK is the live ISO this runs from"
# zram only by default; hibernation can come later from a btrfs swapfile without repartitioning
ask SWAP_GB "Swap partition size in GiB (0 = none, zram is set up anyway)" 0
[[ "$SWAP_GB" =~ ^[0-9]+$ ]] || die "Not a number: $SWAP_GB"
ask ROOT_GB "Root size in GiB (empty = rest of the disk)" ""
[[ -z "$ROOT_GB" || "$ROOT_GB" =~ ^[0-9]+$ ]] || die "Not a number: $ROOT_GB"
# refuse sizes that do not fit before anything is wiped
disk_gib=$(( $(lsblk -bdno SIZE "$ROOT_DISK") / 1024**3 ))
root_min=${ROOT_GB:-20} # without a root size, leave at least 20 GiB for it
(( ESP_GB + SWAP_GB + root_min < disk_gib )) ||
    die "${ESP_GB} GiB ESP + ${SWAP_GB} GiB swap + ${root_min} GiB root does not fit on $ROOT_DISK (${disk_gib} GiB)"

echo
heading "Partitions:"
lsblk -pno NAME,SIZE,FSTYPE,LABEL -e 7,11 | grep -v zram
echo
echo "Home: [k]eep an existing ext4 partition (not formatted), [f]ormat a whole disk as ext4, [s]ubvolume on the root disk"
# a single disk (laptop) can only hold home as a subvolume. The ISO's own disk does not count; when
# it is not known, USB and removable disks are left out of this default (they can still be chosen)
other_disks="$(lsblk -dpno NAME,TYPE,RM,TRAN -e 7,11 | awk -v r="$ROOT_DISK" -v b="$ISO_DISK" '
    $2 != "disk" || $1 == r || $1 ~ /zram/ { next }
    b != "" && $1 == b { next }
    b == "" && ($3 == "1" || $4 == "usb") { next }
    { n++ } END { print n + 0 }')"
home_default=s
(( other_disks > 0 )) && home_default=k
ask_required HOME_MODE "Home" "$home_default"
HOME_DEV=""
case "$HOME_MODE" in
    k)
        ask_required HOME_DEV "Existing home partition" "$(blkid -L home 2>/dev/null || true)"
        [[ -b "$HOME_DEV" ]] || die "$HOME_DEV is not a block device"
        [[ "$(blkid -o value -s TYPE "$HOME_DEV")" == ext4 ]] || die "$HOME_DEV is not ext4"
        [[ "$(disk_of "$HOME_DEV")" != "$ROOT_DISK" ]] || die "$HOME_DEV is on the disk that gets wiped"
        ;;
    f)
        ask_required HOME_DISK "Disk for /home (WILL BE WIPED)"
        [[ -b "$HOME_DISK" && "$(lsblk -dno TYPE "$HOME_DISK")" == disk ]] || die "$HOME_DISK is not a disk"
        [[ "$HOME_DISK" != "$ROOT_DISK" ]] || die "Pick a different disk than the system disk, or use [s]"
        [[ "$HOME_DISK" != "$ISO_DISK" ]] || die "$HOME_DISK is the live ISO this runs from"
        ;;
    s) ;;
    *) die "Unknown choice: $HOME_MODE" ;;
esac

echo
# no default: every machine gets its own name (t is the desktop, tt the ThinkPad, tf the Framework)
while :; do
    ask_required HOSTNAME_ "Hostname (t desktop, tt thinkpad, tf framework)"
    [[ "$HOSTNAME_" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] && break
    warn "Use lowercase letters, digits and inner hyphens, at most 63 characters"
done
ask USERNAME "User name" eggfriedrice
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid user name: $USERNAME"
ask_password USER_PASS "Password for $USERNAME"
ask TIMEZONE "Timezone" Europe/Paris
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "Unknown timezone: $TIMEZONE"
ask LOCALE "Locale" en_US.UTF-8
ask KEYMAP "Console keymap" us
ask RUN_DOTFILES "Run the dotfiles installer inside the new system now? [y/n]" y
PULL_KEPT=n
if [[ "$HOME_MODE" == k ]]; then
    # asked now so the run needs no answer after the wipe; a kept checkout is never pulled unasked
    ask PULL_KEPT "If the kept home has ~/dotfiles, fast-forward it to origin before installing? [y/n]" n
fi

echo
enc_default=n
ls /sys/class/power_supply/BAT* &>/dev/null && enc_default=y
ask ENCRYPT "Encrypt the system with LUKS (passphrase at every boot)? [y/n]" "$enc_default"
ENCRYPT="${ENCRYPT:0:1}"; ENCRYPT="${ENCRYPT,,}"
if [[ "$ENCRYPT" == y ]]; then
    ask_password LUKS_PASS "Disk encryption passphrase"
    [[ "$HOME_MODE" == k ]] && warn "The kept home partition stays unencrypted; only new partitions are encrypted"
fi

# ---------------------------------------------------------------- confirm
echo
heading "Summary"
echo "  System disk:  $ROOT_DISK  (wiped: ${ESP_GB} GiB ESP, ${SWAP_GB} GiB swap, btrfs root ${ROOT_GB:-rest}${ROOT_GB:+ GiB})"
case "$HOME_MODE" in
    k) echo "  /home:        $HOME_DEV (kept, NOT formatted; a kept ~/dotfiles is $([[ "$PULL_KEPT" =~ ^[Yy] ]] || printf 'not ')fast-forwarded)" ;;
    f) echo "  /home:        $HOME_DISK (wiped, ext4)" ;;
    s) echo "  /home:        @home subvolume on the root disk" ;;
esac
echo "  Host/user:    $HOSTNAME_ / $USERNAME   $TIMEZONE  $LOCALE  $KEYMAP"
if [[ "$ENCRYPT" == y ]]; then
    enc_text="LUKS2 on root"
    [[ "$HOME_MODE" == f ]] && enc_text+=" and the new /home (unlocked by a key file on root)"
    (( SWAP_GB > 0 )) && enc_text+=", swap with a random key each boot"
    echo "  Encryption:   $enc_text"
else
    echo "  Encryption:   none"
fi
echo
wipe_list="$ROOT_DISK"; [[ "$HOME_MODE" == f ]] && wipe_list+=" $HOME_DISK"
ask CONFIRM "Type ERASE to wipe $wipe_list and install"
[[ "$CONFIRM" == ERASE ]] || die "Aborted, nothing was changed."

# ---------------------------------------------------------------- partition
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true
for m in cryptroot crypthome; do cryptsetup close "$m" 2>/dev/null || true; done # leftovers of an earlier run

info "Partitioning $ROOT_DISK"
wipefs -af "$ROOT_DISK"
sgdisk --zap-all "$ROOT_DISK"
# the whole table in one sgdisk call
sg_args=(-n1:0:+"${ESP_GB}"G -t1:ef00 -c1:EFI)
n=2
SWAP_PART=""
if (( SWAP_GB > 0 )); then
    sg_args+=(-n2:0:+"${SWAP_GB}"G -t2:8200 -c2:swap)
    SWAP_PART="$(part "$ROOT_DISK" 2)"
    n=3
fi
root_end=0 # 0 = up to the end of the disk
[[ -n "$ROOT_GB" ]] && root_end="+${ROOT_GB}G"
sg_args+=(-n"$n":0:"$root_end" -t"$n":8300 -c"$n":root)
if ! sgdisk "${sg_args[@]}" "$ROOT_DISK"; then
    sgdisk -p "$ROOT_DISK" || true
    die "sgdisk could not write the partition table: sgdisk ${sg_args[*]} $ROOT_DISK"
fi
partprobe "$ROOT_DISK"; udevadm settle
ESP="$(part "$ROOT_DISK" 1)"
ROOT_PART="$(part "$ROOT_DISK" "$n")"

if [[ "$HOME_MODE" == f ]]; then
    info "Partitioning $HOME_DISK"
    wipefs -af "$HOME_DISK"
    sgdisk --zap-all "$HOME_DISK"
    sgdisk -n1:0:0 -t1:8302 -c1:home "$HOME_DISK"
    partprobe "$HOME_DISK"; udevadm settle
    HOME_PART="$(part "$HOME_DISK" 1)"
    HOME_DEV="$HOME_PART"
    if [[ "$ENCRYPT" == y ]]; then
        info "Encrypting $HOME_PART"
        # random key file, stored on the encrypted root and opened from crypttab at boot
        dd if=/dev/urandom of=/tmp/crypthome.key bs=512 count=1 status=none
        chmod 400 /tmp/crypthome.key
        cryptsetup luksFormat --type luks2 --batch-mode --key-file /tmp/crypthome.key "$HOME_PART"
        cryptsetup open --key-file /tmp/crypthome.key "$HOME_PART" crypthome
        HOME_DEV=/dev/mapper/crypthome
    fi
    mkfs.ext4 -F -L home "$HOME_DEV"
fi

info "Formatting"
mkfs.fat -F32 -n EFI "$ESP"
BTRFS_DEV="$ROOT_PART"
if [[ "$ENCRYPT" == y ]]; then
    info "Encrypting $ROOT_PART"
    printf '%s' "$LUKS_PASS" | cryptsetup luksFormat --type luks2 --batch-mode --key-file - "$ROOT_PART"
    printf '%s' "$LUKS_PASS" | cryptsetup open --allow-discards --key-file - "$ROOT_PART" cryptroot
    BTRFS_DEV=/dev/mapper/cryptroot
fi
# an encrypted swap gets a fresh random key from crypttab at every boot, so it is only formatted then
if [[ -n "$SWAP_PART" && "$ENCRYPT" != y ]]; then
    mkswap -L swap "$SWAP_PART"
    swapon "$SWAP_PART"
fi
mkfs.btrfs -f -L arch "$BTRFS_DEV"

info "Creating btrfs subvolumes"
mount "$BTRFS_DEV" /mnt
subvols=(@ @snapshots @log @pkg @docker @flatpak)
[[ "$HOME_MODE" == s ]] && subvols+=(@home)
for sv in "${subvols[@]}"; do btrfs subvolume create "/mnt/$sv"; done
umount /mnt

mount -o "$BTRFS_OPTS,subvol=@" "$BTRFS_DEV" /mnt
mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache/pacman/pkg,var/lib/docker,var/lib/flatpak}
mount -o "$BTRFS_OPTS,subvol=@snapshots" "$BTRFS_DEV" /mnt/.snapshots
mount -o "$BTRFS_OPTS,subvol=@log" "$BTRFS_DEV" /mnt/var/log
mount -o "$BTRFS_OPTS,subvol=@pkg" "$BTRFS_DEV" /mnt/var/cache/pacman/pkg
mount -o "$BTRFS_OPTS,subvol=@docker" "$BTRFS_DEV" /mnt/var/lib/docker
mount -o "$BTRFS_OPTS,subvol=@flatpak" "$BTRFS_DEV" /mnt/var/lib/flatpak
mount "$ESP" /mnt/boot
if [[ "$HOME_MODE" == s ]]; then
    mount -o "$BTRFS_OPTS,subvol=@home" "$BTRFS_DEV" /mnt/home
else
    mount "$HOME_DEV" /mnt/home
fi

# ---------------------------------------------------------------- base system
ucode=()
grep -q AuthenticAMD /proc/cpuinfo && ucode=(amd-ucode)
grep -q GenuineIntel /proc/cpuinfo && ucode=(intel-ucode)

info "Installing the base system"
pacstrap -K /mnt base linux linux-firmware linux-headers "${ucode[@]}" \
    btrfs-progs dosfstools e2fsprogs cryptsetup grub efibootmgr grub-btrfs inotify-tools snapper \
    sudo git zsh networkmanager openssh neovim man-db
cp /etc/pacman.conf /mnt/etc/pacman.conf

genfstab -U /mnt >>/mnt/etc/fstab
# subvolid pins break snapper rollbacks; subvol= is enough
sed -i 's/,subvolid=[0-9]*//; s/subvolid=[0-9]*,//' /mnt/etc/fstab
# a /boot that fails to mount must not end in emergency mode (root is locked); /home stays a hard mount
sed -i -E 's|^(\S+\s+/boot\s+vfat\s+)(\S+)|\1\2,nofail|' /mnt/etc/fstab
grep -qE '^\S+\s+/boot\s+vfat\s+\S*nofail' /mnt/etc/fstab || warn "Could not mark /boot nofail in /etc/fstab"

if [[ "$ENCRYPT" == y ]]; then
    # root is opened by the initramfs (cryptdevice= on the kernel line); the rest by systemd from crypttab
    if [[ -n "$SWAP_PART" ]]; then
        # PARTUUID: the partition has no stable content to carry a UUID, it is re-encrypted every boot.
        # nofail: a boot without swap is better than emergency mode on a locked root
        swap_partuuid="$(blkid -o value -s PARTUUID "$SWAP_PART")"
        echo "cryptswap PARTUUID=$swap_partuuid /dev/urandom swap,cipher=aes-xts-plain64,size=512,discard,nofail" >>/mnt/etc/crypttab
        echo "/dev/mapper/cryptswap none swap defaults,nofail 0 0" >>/mnt/etc/fstab
    fi
    if [[ "$HOME_MODE" == f ]]; then
        install -Dm400 /tmp/crypthome.key /mnt/etc/cryptsetup-keys.d/crypthome.key
        chmod 700 /mnt/etc/cryptsetup-keys.d
        echo "crypthome UUID=$(blkid -o value -s UUID "$HOME_PART") /etc/cryptsetup-keys.d/crypthome.key discard" >>/mnt/etc/crypttab
        shred -u /tmp/crypthome.key
    fi
fi

# ---------------------------------------------------------------- configure
info "Configuring the system"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i "s/^#\(${LOCALE//./\\.} \)/\1/" /mnt/etc/locale.gen
grep -q "^${LOCALE} " /mnt/etc/locale.gen || die "Locale $LOCALE not in locale.gen"
arch-chroot /mnt locale-gen
echo "LANG=$LOCALE" >/mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" >/mnt/etc/vconsole.conf
echo "$HOSTNAME_" >/mnt/etc/hostname
cat >/mnt/etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME_.localdomain $HOSTNAME_
EOF

# busybox hooks so grub-btrfs-overlayfs can make read-only snapshots bootable
# (encrypt asks for the root passphrase; keyboard and keymap come before it so the passphrase types right.
# keyboard sits before autodetect so every keyboard driver is included, not only the ones plugged in
# during the install: an external or docked keyboard still works at the LUKS prompt)
encrypt_hook=""
[[ "$ENCRYPT" == y ]] && encrypt_hook="encrypt "
mkdir -p /mnt/etc/mkinitcpio.conf.d
# vfat is preloaded: a snapshot boots the newest kernel from the ESP with the older modules of its
# own root, which do not match it, so without vfat in the initramfs /boot cannot be mounted
cat >/mnt/etc/mkinitcpio.conf.d/bootstrap.conf <<EOF
MODULES=(vfat)
HOOKS=(base udev keyboard autodetect microcode modconf kms keymap consolefont block ${encrypt_hook}filesystems fsck grub-btrfs-overlayfs)
EOF
arch-chroot /mnt mkinitcpio -P

# User: reuse the UID that owns a kept home directory, so file ownership stays right
uid_opt=()
if [[ -d "/mnt/home/$USERNAME" ]]; then
    old_uid="$(stat -c %u "/mnt/home/$USERNAME")"
    info "Existing /home/$USERNAME (uid $old_uid) kept"
    uid_opt=(-u "$old_uid")
    arch-chroot /mnt useradd "${uid_opt[@]}" -U -G wheel -s /usr/bin/zsh "$USERNAME"
else
    arch-chroot /mnt useradd -m -U -G wheel -s /usr/bin/zsh "$USERNAME"
fi
printf '%s:%s\n' "$USERNAME" "$USER_PASS" | arch-chroot /mnt chpasswd
arch-chroot /mnt passwd -l root
echo '%wheel ALL=(ALL:ALL) ALL' >/mnt/etc/sudoers.d/10-wheel
chmod 440 /mnt/etc/sudoers.d/10-wheel
# with root locked, sulogin refuses the emergency and rescue shells and a failed boot is a dead end.
# On an encrypted install the disk passphrase already stands in front of that shell, so let it open
if [[ "$ENCRYPT" == y ]]; then
    for unit in emergency rescue; do
        install -Dm644 /dev/stdin "/mnt/etc/systemd/system/$unit.service.d/sulogin-force.conf" <<'EOF'
[Service]
Environment=SYSTEMD_SULOGIN_FORCE=1
EOF
    done
fi

# Snapper: what "snapper create-config /" does, but on the separate @snapshots subvolume
install -Dm640 /mnt/usr/share/snapper/config-templates/default /mnt/etc/snapper/configs/root
sed -i \
    -e 's/^ALLOW_GROUPS=.*/ALLOW_GROUPS="wheel"/' \
    -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="no"/' \
    -e 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' \
    -e 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' \
    /mnt/etc/snapper/configs/root
if grep -q '^SNAPPER_CONFIGS=' /mnt/etc/conf.d/snapper 2>/dev/null; then
    sed -i 's/^SNAPPER_CONFIGS=.*/SNAPPER_CONFIGS="root"/' /mnt/etc/conf.d/snapper
else
    install -Dm644 /dev/stdin /mnt/etc/conf.d/snapper <<<'SNAPPER_CONFIGS="root"'
fi
chmod 750 /mnt/.snapshots
arch-chroot /mnt chown :wheel /.snapshots

info "Installing GRUB"
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /mnt/etc/default/grub
if [[ "$ENCRYPT" == y ]]; then
    # /boot is the plain ESP, so GRUB itself needs no cryptodisk; the kernel opens root
    root_luks_uuid="$(blkid -o value -s UUID "$ROOT_PART")"
    sed -i -E "s|^(GRUB_CMDLINE_LINUX=\")|\1cryptdevice=UUID=${root_luks_uuid}:cryptroot:allow-discards |; s| \"$|\"|" /mnt/etc/default/grub
fi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# sshd here too, not only in the dotfiles: if that step fails, the machine is still reachable to fix it.
# btrfs-scrub@-.timer scrubs the root filesystem monthly (btrfs-progs ships the unit)
for svc in NetworkManager sshd fstrim.timer snapper-cleanup.timer grub-btrfsd btrfs-scrub@-.timer; do
    arch-chroot /mnt systemctl enable "$svc"
done

# ---------------------------------------------------------------- dotfiles
DOTS="/home/$USERNAME/dotfiles"
as_user() { arch-chroot /mnt sudo -u "$USERNAME" -H "$@"; }
# the disk is already wiped here: a failed clone or pull skips the installer instead of killing the run
repo_ok=0
if [[ -d "/mnt$DOTS/.git" ]]; then
    success "Dotfiles already present in the kept home: $DOTS"
    as_user git -C "$DOTS" log -1 --format='  HEAD %h %s (%cr)' || warn "Could not read HEAD of $DOTS"
    as_user git -C "$DOTS" status --short --branch || warn "Could not read the status of $DOTS"
    if [[ "$PULL_KEPT" =~ ^[Yy] ]]; then
        if as_user git -C "$DOTS" pull --ff-only; then
            success "Fast-forwarded $DOTS"
        else
            warn "Could not fast-forward $DOTS; the installer runs on the checkout as it is"
        fi
    else
        info "Not pulled; the installer runs on the checkout as it is"
    fi
    repo_ok=1
else
    info "Cloning dotfiles to $DOTS"
    if as_user git clone "$DOTFILES_REPO" "$DOTS"; then
        repo_ok=1
        as_user git -C "$DOTS" remote set-url --push origin "$DOTFILES_PUSH" ||
            warn "Could not set the push URL of $DOTS to $DOTFILES_PUSH"
    else
        warn "Could not clone $DOTFILES_REPO; the dotfiles installer is skipped"
    fi
fi

dotfiles_ok=0
if (( repo_ok )) && [[ "$RUN_DOTFILES" =~ ^[Yy] ]]; then
    info "Running the dotfiles installer in the new system"
    # temporary passwordless sudo: the installer runs unattended as the user
    SUDOERS_TMP=/mnt/etc/sudoers.d/99-bootstrap
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >"$SUDOERS_TMP"
    chmod 440 "$SUDOERS_TMP"
    if arch-chroot /mnt sudo -u "$USERNAME" -H bash -c "cd '$DOTS' && DOTFILES_BOOTSTRAP=1 THEME_REPO='$THEME_REPO' ./install.sh --yes ${INSTALL_ARGS:-}"; then
        dotfiles_ok=1
    else
        warn "The dotfiles installer failed in the chroot; rerun it after the first boot (it is idempotent)"
    fi
    rm -f "$SUDOERS_TMP"
    SUDOERS_TMP=""
    # gpg daemons that makepkg started in the chroot keep running on the ISO: stop them, or
    # their keyring lock outlives the reboot and yay cannot import PGP keys any more
    arch-chroot /mnt sudo -u "$USERNAME" -H gpgconf --kill all 2>/dev/null || true
    rm -f "/mnt/home/$USERNAME/.gnupg/public-keys.d/"{pubring.db.lock,.#lk*} "/mnt/home/$USERNAME/.gnupg/S."*
fi

# snap-pac last, so the install itself does not leave dozens of snapshots, then one baseline snapshot
arch-chroot /mnt pacman -S --needed --noconfirm snap-pac
arch-chroot /mnt snapper --no-dbus -c root create -d "fresh install"
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# ---------------------------------------------------------------- done
echo
success "Install finished."
# the ISO's iwd connection is not carried over; the new system runs NetworkManager
echo "  Wi-Fi after the first boot: nmcli device wifi connect <ssid> --ask"
if (( ! repo_ok )); then
    echo "  After the first boot: git clone $DOTFILES_REPO ~/dotfiles && cd ~/dotfiles && ./install.sh"
elif (( ! dotfiles_ok )); then
    echo "  After the first boot: cd ~/dotfiles && ./install.sh"
fi
echo "  Then the manual steps in ~/dotfiles/README.md (ssh keys, gh auth, tailscale up, bluetooth)."
echo "  Review /mnt if you want, then: umount -R /mnt && reboot"
