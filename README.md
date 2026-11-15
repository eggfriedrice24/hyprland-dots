# dotfiles

Personal dotfiles for Arch Linux with Hyprland, shared by three machines (see [Machines](#machines)).

**Author:** eggfriedrice

## What's Included

- **[Hyprland](https://hypr.land/)** - Wayland compositor (Lua config), hyprlock, hypridle
- **[Waybar](https://github.com/Alexays/Waybar)** - status bar
- **[Ghostty](https://ghostty.org/)** - terminal
- **[Neovim](https://neovim.io/)** - editor with LSP, formatting and linting via Mason
- **[Zsh](https://www.zsh.org/)** - shell with the Zinit plugin manager and a [Starship](https://starship.rs/) prompt
- **[OpenCode](https://opencode.ai/)** - AI coding assistant configuration
- **[rofi](https://github.com/davatorium/rofi)** - launcher, emoji picker, calculator and clipboard history
- **GTK** - adw-gtk3-dark and libadwaita recolored from the palette, Thunar styling, Papirus folders in the palette
- **GRUB** - a boot menu theme with the eggfriedrice.code logo, built from the palette
- dunst, bat, btop, eza, frameit, pipewire and wireplumber drop-ins
- `dots-update`, `dots-snapshot`, `dots-prune` and the installer described below

## Theme

All configurations share the eggfriedrice design system from `~/p/eggfriedrice.nvim`: colours and typography (Nunito
Medium for every UI surface, Cartograph CF only for terminal text, a small size scale). Every config that carries
either points at a generated file under its `extras/`: ghostty, waybar, rofi, dunst, hyprland, hyprlock, GTK 3 and 4,
Thunar, zsh, fzf, fast-syntax-highlighting, bat, eza, btop, opencode and frameit, with the Papirus folders, the
Starship palette and the GRUB theme derived from it. The palette lives in one place: `make extras` in that repo, then
`install/theme-apply.sh` here for the derived caches (the GRUB theme, which needs root, on the next `up`). The links are relative (`../../p/eggfriedrice.nvim/...`), so
the dotfiles and the theme repo have to be siblings under `$HOME`. The installer clones the theme repo before it links
anything, and `install/lint-colors.sh` reports colour literals that bypass the palette.

## Machines

| Machine | Hostname | Profile | Recognised by |
| --- | --- | --- | --- |
| Desktop: Gigabyte B650 AORUS ELITE AX V2, RX 7900 XTX, ASUS OLED on DP-1, HP in portrait on HDMI-A-1 | `t` | `desktop` | DMI vendor and product name |
| ThinkPad, the existing laptop | `tt` | `thinkpad` | vendor `LENOVO` with a ThinkPad product version or family |
| Framework Laptop 13 Pro (Intel Core Ultra X7 358H), arriving December 2026 | `tf` | `framework` | vendor `Framework`, product name `Laptop*` (a guess until it is here) |
| any other laptop | | `laptop` | a `BAT*` battery |
| anything else (a VM, a borrowed machine) | | `generic` | nothing matched |

`thinkpad` and `framework` extend the shared `laptop` layer, so the ThinkPad behaves the same while its DMI strings are
not in `machines/index` yet. How profiles work: [Machine profiles](#machine-profiles).

## Fresh install from the Arch ISO

`bootstrap.sh` replaces archinstall: boot the ISO in UEFI mode with Secure Boot off (GRUB is unsigned), connect
(`iwctl` for WiFi), then

```bash
curl -fsSL https://raw.githubusercontent.com/eggfriedrice24/hyprland-dots/master/bootstrap.sh -o bootstrap.sh
bash bootstrap.sh
```

It asks for the disks, the hostname (`t`, `tt` or `tf`; there is no default), user and locale, shows a summary, and
wipes nothing until you type `ERASE`. It builds a 2 GiB ESP at `/boot` (room for the `.old` kernels), an optional swap
partition (none by default; zram comes from the dotfiles), and a btrfs root with zstd compression and the subvolumes
`@`, `@snapshots`, `@log`, `@pkg`, `@docker` and `@flatpak`, with snapper, snap-pac and grub-btrfs, so every pacman
transaction is a snapshot you can boot from GRUB (see [Snapshots and recovery](#snapshots-and-recovery)). `/home` is an
existing ext4 partition kept as is, a whole second disk formatted as ext4, or a `@home` subvolume. Optional LUKS2 (the
default on a laptop): one passphrase at boot opens root; a new `/home` disk opens with a key file stored on root, a swap
partition gets a random key every boot (so no hibernation), and the emergency shell works although root has no
password. A kept `/home` stays unencrypted. It then clones this repo over https and runs `install.sh --yes` inside the
new system; if that fails, rerun `./install.sh` after the first boot.

To test unpushed commits in a VM, `DOTFILES_REPO=http://10.0.2.2:8000/.git` points the clone at a local server, and
`INSTALL_ARGS="--profile framework"` picks a profile (a VM matches no DMI line, so it would otherwise be `generic`).

## Installation

Prerequisites on a fresh Arch install: a user in the `wheel` group with `sudo`, `git`, and network access. Everything
else, including the AUR helper (yay) and the theme repo, is installed by the script.

```bash
git clone https://github.com/eggfriedrice24/hyprland-dots.git ~/dotfiles
git -C ~/dotfiles remote set-url --push origin git@github.com:eggfriedrice24/hyprland-dots.git
cd ~/dotfiles
./install.sh --print-profile   # the machine profile and how it was found
./install.sh --dry-run         # prints every action without executing
./install.sh
```

| Option | Effect |
| --- | --- |
| `--dry-run` | print every action, change nothing |
| `--yes` | no confirmation prompt (bootstrap.sh uses it) |
| `--profile NAME` | use `machines/NAME` and pin it in `~/.config/dotfiles/profile`, which Hyprland reads too; `--laptop` and `--desktop` are short for it |
| `--profile auto` | remove the pin and detect the machine again |
| `--print-profile` | print the profile and its source (`flag`, `pinned`, `dmi`, `battery` or `fallback`), then exit |
| `--no-upgrade` | no keyring refresh and full upgrade in stage 1 (dots-update has just done both) |
| `--skip=a,b` | skip stages by name: `packages`, `theme`, `symlinks`, `shell`, `services`, `system`, `snapshots`, `migrations`, `finalize` |
| `--quiet` | only print what changes |

Exit status: 0 done, 1 a stage failed (the message names the file, line and command), 3 every stage ran but a migration
is still pending. A real run is logged to `~/.local/state/dotfiles/install/<time>.log`. `THEME_REPO` overrides the theme
repo's clone URL (a local mirror for VM tests).

The stages in `install/stages/` run in order:

1. **packages** - enables `[multilib]`; stops with the exact command when `rust`, `jack2` or `pulseaudio` would have to
   be removed; refreshes `archlinux-keyring`, then a full upgrade; microcode and Vulkan driver by detected vendor; the
   lists in `install/packages/` (base, system, audio, hyprland, fonts, apps, dev), then the profile's `packages.txt`;
   AUR via yay (`aur.txt`, then the profile's `aur.txt`), bootstrapping yay-bin when no helper is present
2. **theme** - clones or fast-forwards `~/p/eggfriedrice.nvim`, checks every extra the configs reference and that every
   tracked symlink resolves
3. **symlinks** - links each config directory into `~/.config`, plus `~/.zshenv`, `~/.wallpapers`, the Cartograph
   and Nunito fonts and every command in `bin/` into `~/.local/bin`; existing real files are backed up as
   `*.bak.<timestamp>`, and links into the repo whose target is gone are removed
4. **shell** - `chsh` to zsh, first zinit run, then the fast-syntax-highlighting theme and the bat cache, each rebuilt
   only when the theme is newer; a warning when the Starship palette drifted from the theme
5. **services** - NetworkManager, sshd, timesyncd, fstrim, bluetooth, tailscaled, cronie, docker group, the profile's
   `services`, pipewire user sockets. postgresql (cluster initialised) and valkey are installed but not started at
   boot: `dbup` / `dbdown` start and stop both
6. **system** - the profile's `/etc` files (`machines/<profile>/etc/`), zram, wireless regdom FR, GRUB command line
   (`zswap.enabled=0` plus the profile's `grub` file), GTK theme (adw-gtk3-dark, recolored from the palette by
   `gtk-3.0/` and `gtk-4.0/`), Papirus-Dark with the palette's folders (`install/papirus-folders.sh`, rebuilt only when
   something changed), dark mode and the UI font via gsettings, the GRUB theme (`install/grub-theme.sh`, rebuilt only
   when the palette, the fonts or the panel changed), then the profile's `system.sh` hook
7. **snapshots** - on the btrfs layout bootstrap.sh builds only: snapper retention, the pacman hook that keeps the
   outgoing kernel, vfat in the initramfs; one line and no change anywhere else
8. **migrations** - the one-off changes in `install/migrations/` this machine has not run yet (see [Migrations](#migrations))
9. **finalize** - the font picker's UI fonts from Google Fonts (`font-picker --fetch`, optional, needs the network),
   font cache, XDG user dirs, state dirs, Rust nightly, Node 22 via fnm, Neovim plugins and Mason tools (headless, on a
   machine that has none yet), Claude Code, seeds `opencode/google-workspace.env` from its example, Stremio flatpak,
   then a summary: failed optional steps, what needs a restart, relogin or reboot, the manual steps and the profile's
   `notes`

Optional steps (AUR builds, the font fetch, rustup, fnm, Neovim, Claude Code, flatpak, gsettings) do not stop the run;
they are listed at the end. The script is idempotent: rerun it after pulling to converge a machine, or let `dots-update`
do both.

## Machine profiles

Everything that belongs to one machine lives in `machines/<profile>/`; the rest of the repo is shared.

| File | Read by | Holds |
| --- | --- | --- |
| `hypr.lua` (required) | Hyprland | a table with `monitors` (`hl.monitor` specs), `config` (applied after the shared `hl.config` values), `setup` (a function for binds, devices and event handlers) and `hypridle` (an idle config in that directory) |
| `extends` | both | the profile this one builds on, applied first (`thinkpad` and `framework` extend `laptop`) |
| `packages.txt`, `aur.txt` | stage 1 | extra packages |
| `services` | stage 5 | system units to enable, one per line |
| `etc/` | stage 6 | files laid out like `/etc` |
| `grub` | stage 6 | kernel parameters, `VARIABLE PARAMETER [KEY]` per line |
| `system.sh` | stage 6 | a hook for edits that are not whole files |
| `notes` | stage 9 | lines that are not comments are printed as manual steps |
| `keep.txt` (optional) | dots-prune | packages this machine keeps on purpose, one per line; dots-prune also writes it |
| `hypridle.conf` | Hyprland | the laptop layer's idle config |

The installer (`install/machine.sh`) and Hyprland (`hypr/machine.lua`) pick the profile the same way: `--profile`
(installer only; it also writes the pin), the pin in `~/.config/dotfiles/profile`, the DMI strings against
`machines/index` (`profile|sys_vendor|product_name|product_version|product_family`, a trailing `*` is a prefix match,
first match wins), a `BAT*` battery means `laptop`, anything else is `generic`. Hyprland resolves on every config load
and exports `DOTFILES_PROFILE`, so the session side needs nothing but a pull; a profile that fails to load leaves
Hyprland without monitor rules, not without a session. `DMI_DIR` and `PS_DIR` point both resolvers at a fake tree for
tests.

What each profile carries today:

- **desktop** - DP-1 at 2560x1440@240 and 10 bpc, the HP in portrait (SUPER+O flips it), Razer mouse sensitivity,
  `it87-dkms-git`, rtw89 and btusb module options, `video=DP-1:2560x1440@240` on the kernel command line (keep it in sync
  with the DP-1 rule), Bluetooth FastConnectable, the WiFi BSSID note
- **laptop** - eDP-1 at scale 1 plus a rule for anything plugged in, `sof-firmware`, a key-only sshd drop-in, the idle
  config in `machines/laptop/hypridle.conf` (dim at 2.5 min, lock at 5, display off at 5.5, suspend at 15 on battery
  only), a key press wakes the display
- **thinkpad** - the laptop layer as it is
- **framework** - eDP-1 at scale 1.6, XWayland zero scaling, tap to click, three-finger workspace swipe, touch mapped
  to the panel, the lid turns the panel off on a dock, `intel-media-driver`, `libva-utils`, `fwupd`, `powertop`,
  `framework-system`, `power-profiles-daemon`; every value marked VERIFY is settled on the machine with
  `machines/framework/ARRIVAL.md`
- **generic** - every output at its preferred mode

A new machine needs a directory with at least `hypr.lua` (and an `extends` file for a laptop), a line in
`machines/index` from `cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}`, and
`./install.sh --print-profile` to confirm. Switching a machine to another profile never undoes the old one's packages or
files; that is a migration.

## Keeping a machine in sync

`dots-update` (alias `up`; stage 3 links it into `~/.local/bin`) brings a machine up to date in one run:

1. fetch and fast-forward `~/dotfiles` and `~/p/eggfriedrice.nvim`, never stash, rebase or merge (a repo that cannot be
   fast-forwarded is left as it is and reported), and start over when the pull changed `dots-update` itself
2. check the theme extras and every tracked link
3. a pre-update snapshot, on machines that have snapshots
4. Arch news, `archlinux-keyring`, `pacman -Su`, AUR (`yay` or `paru`), `flatpak update`
5. `install.sh --no-upgrade`: new packages, links, services, `/etc` files, theme caches, and the migrations
6. the matching post snapshot, or the pre one discarded when nothing changed
7. a report: commits pulled, packages changed, `.pacnew` files, and what needs a restart, a relogin or a reboot

```bash
up --dry-run    # show the plan; fetches the remotes, changes nothing else
up              # pacman and the AUR helper ask as usual; --yes answers for them
up --check      # refresh the status file without sudo: pending packages, commits behind, reboot or relogin needed
up -- --profile framework   # anything after -- goes to install.sh
up --prune      # afterwards, pick packages the dotfiles do not list and remove them (see Pruning)
```

`--no-pull`, `--no-packages`, `--no-converge` and `--no-snapshot` leave a phase out. Exit status: 0 done, 1 stopped, 2
done with warnings, 130 interrupted. Logs are in `~/.local/state/dotfiles/update/log/` (the newest linked as
`last.log`), the status file is `~/.local/state/dotfiles/update/status`. On battery below 30 percent it asks first.
Without a terminal, `hypr/scripts/systemupdate.sh up` opens it in a Ghostty window that stays open.

## Pruning

`dots-prune` (or `up --prune` after an update) lists the explicitly installed packages that the dotfiles do not
account for: not in `install/packages/*.txt`, not in the profile layers' `packages.txt`, `aur.txt` or `keep.txt`, not
part of what `bootstrap.sh` installs (read from its `pacstrap` line), and not providing a listed name. Each comes with
its size and how many dependencies would go with it; you mark the ones to remove in fzf and confirm once. The ones you
keep can be added to `machines/<profile>/keep.txt` (tracked: commit it) so the next run does not ask about them again.
Orphans, dependencies nothing needs any more, are offered last. `dots-prune --dry-run` only lists.

Two things keep a machine from collecting such packages in the first place: `/etc/makepkg.conf.d/no-debug.conf`
(stage 1) stops AUR builds from installing `<pkg>-debug` packages, and the AUR helper runs with `--removemake`, so
build-only dependencies do not stay behind.

## Migrations

The stages only add and converge. Removing or replacing what an older version of the dotfiles left on a machine is
the job of a migration: `install/migrations/<YYYYMMDD-HHMM>-<slug>.sh`, line 2 a one-line description. Each runs once
per machine, oldest first, as stage 8 (after the stages have put the new state in place), in its own
`set -Eeuo pipefail` shell with the installer's helpers (`remove_packages`, `swap_package`, `remove_path`,
`remove_etc_file`, `as_root`) and `DOTFILES_DIR`, `PROFILE` and `DRY_RUN`.

State is `~/.local/state/dotfiles/migrations`, one `<id> <applied|baseline|skipped> <time>` line per event; the last
line for an id wins, an id without one is pending. A machine whose `~/.config` does not link into the dotfiles yet (a
new install) records every existing migration as `baseline` without running it. A failed migration stays pending,
stops the ones after it and makes install.sh exit 3; the stages are not affected.

```bash
install/migrate.sh              # run the pending ones
install/migrate.sh --status     # every migration and its state; no root, writes nothing
install/migrate.sh --dry-run    # what they would do
install/migrate.sh --skip ID    # record one that cannot work on this machine as skipped
install/migrate.sh --rearm ID   # forget ID's state so it runs again (after a rollback)
install/migrate.sh --baseline   # record every pending one as baseline without running it
install/migrate.sh --new SLUG   # an empty migration named for the current time
```

Never edit a migration that has been pushed, another machine may have run it already: write a new one. When something
a migration removes is added back, delete that migration. A machine whose configs were copied instead of linked looks
new and gets everything as baseline; delete the state file after its first run so the next one runs them.

## Snapshots and recovery

Only machines installed with bootstrap.sh have snapshots (root on the btrfs subvolume `@`, `/.snapshots` on
`@snapshots`, snapper). The desktop is ext4 and has none: there every command below says so and changes nothing.

- snap-pac takes a pre and post snapshot around every pacman transaction; `dots-update` takes one important pair
  around the whole update, labelled `dots=pre-update` with the dotfiles commit. snapper keeps 10 numbered and 5
  important snapshots, no timeline.
- grub-btrfs lists them in GRUB's snapshots submenu, and grub-btrfs-overlayfs boots the read-only ones with a writable
  overlay.
- A pacman hook keeps the outgoing kernel and initramfs on the ESP as `vmlinuz-<pkgbase>.old` and
  `initramfs-<pkgbase>.old.img`, so a snapshot from before a kernel upgrade still boots a kernel it has the modules for:
  each snapshot in GRUB's snapshot menu has a second entry, `vmlinuz-linux.old & initramfs-linux.old.img`, and that is
  the one to pick for a snapshot older than the last kernel upgrade. vfat in the initramfs keeps `/boot` mountable if
  one boots with a mismatched kernel anyway. The `.old` entry in GRUB's advanced menu is today's root with the old
  kernel, not a way back.
- `/home` is never snapshotted or rolled back, and neither is `~/dotfiles` in it.

```bash
dots-snapshot status       # 0 available, 1 not available (says why), 2 booted into a snapshot
dots-snapshot list
dots-snapshot create "before trying X"
dots-snapshot rollback N   # -n shows every step first
dots-snapshot undo         # put back the root and kernel the last rollback replaced
dots-snapshot cleanup      # delete the old roots and kernel backups rollbacks left
```

Three ways back, mildest first:

1. **It boots, an update broke something**: `dots-snapshot list`, then `dots-snapshot rollback N` (without N: the
   newest pre-update snapshot) and reboot.
2. **It does not boot**: pick the pre-update snapshot in GRUB's snapshots submenu; once it is up,
   `dots-snapshot rollback` makes the booted snapshot the system again, with its own kernel; reboot.
3. **Nothing boots**: from the Arch ISO, open LUKS if used (`cryptsetup open /dev/<root partition> cryptroot`), mount
   the partition that holds the dotfiles (or clone them), then
   `bash <dotfiles>/bin/dots-snapshot rollback N --device /dev/mapper/cryptroot --esp /dev/<esp partition>`.

A rollback prepares everything before it touches anything (a writable copy of the snapshot, the NetworkManager
connections, Bluetooth pairings and Tailscale state carried over, the snapshot's own kernel and initramfs), then swaps
the roots and the kernel files; the restored system runs from the next boot. The replaced root stays as
`@broken-<time>` (what `dots-snapshot undo` puts back) until `dots-snapshot cleanup`. It prints the
migrations applied after the snapshot (their work is undone in the system but still recorded as applied) with the
`install/migrate.sh --rearm <id>` command for each, and the dotfiles commit the snapshot was taken at; nothing is
checked out for you.

## Syncing an existing machine

For a machine that has not been updated in a while (the ThinkPad). Do it in one sitting, from a TTY, not from inside
Hyprland: the pull replaces the config the running session reads, and a Hyprland older than 0.55 cannot read the Lua
config at all.

1. Log out of Hyprland and log in on TTY2 (Ctrl+Alt+F2; TTY1 starts Hyprland by itself).
2. Note what the machine is, for its line in `machines/index`:

   ```bash
   cat /sys/class/dmi/id/{sys_vendor,product_name,product_version,product_family}; ls /sys/class/power_supply
   ```

3. Back up the OpenCode database. The tracked config is OpenCode 2; pacman upgrades a 1.x install and the database is
   migrated in place on the first start. A 1.x `opencode` that is not `/usr/bin/opencode` (a Vite+ global) has to go
   first: `vp remove -g opencode-ai`.

   ```bash
   cp ~/.local/share/opencode/opencode.db ~/.local/share/opencode/opencode.db.v1-backup
   ```

4. Check for packages the installer stops on: `pacman -Q rust jack2 pulseaudio`. For each one that is installed,
   `sudo pacman -S rustup pipewire-jack pipewire-pulse` (the matching replacement) and answer y to the removal.
5. Pull the dotfiles, which brings `dots-update` along (commit or stash local changes first if the pull refuses):

   ```bash
   git -C ~/dotfiles pull --ff-only
   ```

6. Dry run, then the real run. It pulls the theme repo too (or clones `~/p/eggfriedrice.nvim` when it is missing),
   upgrades every package, Hyprland included, converges the machine and runs the migrations:

   ```bash
   ~/dotfiles/bin/dots-update --dry-run
   ~/dotfiles/bin/dots-update
   ```

7. Check the result: `~/dotfiles/install.sh --print-profile` says `thinkpad dmi` (or `laptop battery` until the index
   has its strings) and `~/dotfiles/install/migrate.sh --status` shows nothing `pending`.
8. Reboot when the report asks for it (a kernel upgrade always does), otherwise log out; then log in on TTY1.
9. In Neovim: `:Lazy restore` (plugins at the tracked `lazy-lock.json`), `:MasonUninstall rustfmt` if Mason still has
   it (rustup provides it), `:Lazy clean`.

The migrations an old machine picks up remove catppuccin-gtk-theme-mocha, kitty and its config, and qt5ct, and swap
swww for awww, rofi-wayland for rofi, t3code-bin for t3code-nightly-bin, and the AUR fnm-bin and pnpm-bin for the
repository packages, and stop postgresql and valkey from starting at boot (`dbup` / `dbdown` start and stop them; a
server already running keeps running until `dbdown` or a reboot); `install/migrate.sh --status` lists them. Without
`dots-update` (to see each step on its own): `git -C ~/p/eggfriedrice.nvim pull --ff-only`, then
`./install.sh --dry-run` and `./install.sh` in `~/dotfiles`.

## After install

Things that hold secrets or hardware state and are set up by hand:

- **WiFi**: the ISO's connection is not carried over; `nmcli device wifi connect <ssid> --ask`
- **SSH and git**: restore `~/.ssh` (keys and `config`; keychain in `zsh/env.zsh` starts one agent shared by all
  terminals) and `~/.gitconfig`, then `gh auth login`
- **Tailscale**: `sudo tailscale up`
- **Bluetooth**: pair and trust devices with `bluetoothctl`
- **WiFi on the desktop**: pin the connection to the AP's BSSID and the 5 GHz band to avoid rtw89 stalls:
  `nmcli con modify "<name>" 802-11-wireless.bssid <AP MAC> 802-11-wireless.band a 802-11-wireless.powersave 2`
- **Default apps**: `xdg-mime default zen.desktop x-scheme-handler/http x-scheme-handler/https text/html application/pdf`
  and `xdg-mime default imv.desktop image/png image/jpeg image/webp image/gif`
- **OpenCode**: fill in `opencode/google-workspace.env` (seeded from the example)
- **Slack**: paste the theme from `~/p/eggfriedrice.nvim/extras/slack/eggfriedrice.txt`
- **Zen**: link `~/p/eggfriedrice.nvim/extras/zen/userChrome.css` to `<profile>/chrome/userChrome.css` (about:profiles
  shows the profile folder), set `toolkit.legacyUserProfileCustomizations.stylesheets` to true in about:config, restart
- **Helium**: `chrome://extensions`, Developer mode, Load unpacked, pick `~/p/eggfriedrice.nvim/extras/chromium`
- **efr**: clone `git@github.com:eggfriedrice24/eggfriedrice.code.git` to `~/p/eggfriedrice.code` (the path
  `zsh/efr.zsh` sources its zsh plugin from), then `just install` there (needs `just`, rustup and Zig 0.17.0),
  `systemctl --user enable --now efrd` and `efr login openai`. Its config `~/.config/efr/config.toml` is not tracked;
  `palette` under `[render]`, set to the absolute path of `~/p/eggfriedrice.nvim/extras/efr/eggfriedrice.toml`,
  themes it
- **Neovim**: stage 9 installs the plugins and Mason tools headless on a new machine; if it reported a failure, start
  `nvim` and run `:Lazy restore`, then `:MasonToolsInstallSync`
- **Ghostty per machine**: optional untracked `ghostty/local` (for example a laptop font size)
- **Machine-only shell paths**: optional untracked `zsh/local.zsh`, sourced by `zsh/session.zsh`

## A crashed lock screen

When hyprlock dies, Hyprland paints a red "lockscreen crashed" screen. The `hyprctl keyword` command it suggests does
not work with the Lua config, and starting hyprlock again did not repaint in the one recorded case. What unlocked with
the session intact (it unlocks without a password): switch to a TTY (Ctrl+Alt+F2), log in, then

```bash
export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/$UID/hypr | head -1)
pkill hyprlock
hyprctl eval 'hl.clear_crashed_lockscreen()'
```

and go back with Ctrl+Alt+F1. `misc.allow_session_lock_restore` is set in `hypr/hyprland.lua`, so
`hyprctl eval "hl.exec_cmd('hyprlock')"` may let a new hyprlock take over, but the recipe above is the reliable way out.

## Keybinds

Defined in `hypr/keybinds.lua`, plus the profile binds at the end. Caps Lock switches between the US and Georgian
layouts.

| Keys | Action |
| --- | --- |
| **Apps** | |
| SUPER+Return | Ghostty |
| SUPER+T / SUPER+B | Zen / Helium |
| SUPER+E | Thunar |
| SUPER+D | launcher (rofi) |
| SUPER+period | emoji picker, Enter copies |
| SUPER+equal | calculator, Enter copies the result |
| SUPER+SHIFT+F | UI font picker: each font drawn in itself; choosing one sets the theme's `font.ui` and applies it live (commit `typography.lua` in eggfriedrice.nvim to keep it) |
| SUPER+V | clipboard history: Enter copies, Shift+Delete removes, Ctrl+Shift+Delete wipes |
| **Capture** | |
| Print | screenshot of the focused monitor, saved to `~/Pictures/Screenshots` and copied |
| SUPER+SHIFT+S | screenshot of an area, saved and copied |
| SUPER+SHIFT+R / SUPER+SHIFT+V | start / stop recording the focused monitor (to `~/Videos/Recordings`, no audio) |
| SUPER+SHIFT+Z | frameit: highlight a region while screen sharing |
| SUPER+SHIFT+X | colour picker, copies the hex |
| **Session** | |
| CTRL+ALT+L | lock |
| CTRL+ALT+S | suspend |
| SUPER+SHIFT+Escape | exit Hyprland |
| **Windows** | |
| SUPER+Q | close |
| SUPER+SHIFT+Q | force-kill (the Steam client gets a clean `steam -shutdown` instead) |
| SUPER+F | fullscreen |
| SUPER+Space / SUPER+SHIFT+Space | float the window / every window on the workspace |
| SUPER+P / SUPER+SHIFT+P | pseudotile the window / every window on the workspace |
| SUPER+S | toggle the split direction |
| SUPER+arrows | preselect where the next window opens |
| SUPER+C | center a floating window |
| SUPER+G | toggle a tabbed group |
| SUPER+Tab | next window (and next tab of a group) |
| ALT+arrows | move focus |
| ALT+SHIFT+arrows | move the window |
| SUPER+CTRL+arrows | resize |
| SUPER+left drag / SUPER+right drag | move / resize with the mouse |
| **Workspaces and monitors** | |
| SUPER+1..0 | go to workspace 1 to 10, pulled onto the focused monitor |
| SUPER+SHIFT+1..0 | send the window to workspace 1 to 10 |
| SUPER+ALT+up/down, SUPER+scroll | next / previous workspace |
| SUPER+A / SUPER+SHIFT+A | show the special workspace / send the window there |
| ALT+Tab | focus the next monitor |
| SUPER+SHIFT+comma / period | move the workspace to the left / right monitor |
| **Hardware keys** (also on the lock screen) | |
| volume up, down, mute | volume, capped at 100 percent, repeats while held |
| brightness up, down | panel backlight, or DDC/CI on an external monitor |
| play/pause, next, previous | the active player (playerctl) |
| mic mute | toggle the microphone, with a notification |
| **Profiles** | |
| SUPER+O (desktop) | turn the HP between portrait and landscape |
| three-finger swipe (framework) | switch workspace |
| lid closed on a dock (framework) | the internal panel turns off, back on when opened |

## Structure

```
dotfiles/
├── install.sh           # installer entry point
├── bootstrap.sh         # fresh install from the Arch ISO
├── bin/                 # dots-update, dots-snapshot, dots-prune (linked into ~/.local/bin)
├── install/
│   ├── stages/          # 01-packages ... 09-finalize
│   ├── packages/        # package lists for every machine
│   ├── migrations/      # one-off changes, run once per machine as stage 8
│   ├── etc/             # /etc files every machine gets (zram, keep-old-kernel hook, mkinitcpio, makepkg, grub.d)
│   ├── hooks/           # keep-old-kernel, run by that pacman hook
│   ├── utils.sh         # helpers for the stages, migrations and commands
│   ├── machine.sh       # machine profile resolver
│   ├── migrate.sh       # migration runner and CLI
│   ├── theme-apply.sh   # bat cache, fast-syntax-highlighting theme, Papirus folders, Starship check
│   ├── papirus-folders.sh
│   ├── grub-theme.sh    # the GRUB theme from grub/, into /boot/grub/themes
│   └── lint-colors.sh   # colour literals outside the palette
├── machines/            # index (DMI -> profile) and one directory per profile
├── grub/                # GRUB theme templates: theme.txt and the eggfriedrice.code logo
├── hypr/                # Hyprland (Lua), machine.lua, hyprlock, hypridle, scripts/
├── waybar/              # status bar
├── ghostty/             # terminal
├── nvim/                # Neovim
├── zsh/                 # shell modules, .zshenv sets ZDOTDIR, .zprofile starts Hyprland on TTY1
├── starship/            # prompt
├── gtk-3.0/ gtk-4.0/    # GTK colours and Thunar
├── rofi/ dunst/ bat/ btop/ eza/ frameit/ opencode/ pipewire/ wireplumber/
├── .wallpapers/         # linked to ~/.wallpapers
└── fonts/               # Cartograph CF and Nunito, linked into ~/.local/share/fonts
```

## License

Free to use and modify.
