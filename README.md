# dotfiles

Personal dotfiles for Arch Linux with Hyprland, used on a desktop and a laptop.

**Author:** eggfriedrice

## What's Included

- **[Hyprland](https://hypr.land/)** - Wayland compositor (Lua config), hyprlock, hypridle
- **[Waybar](https://github.com/Alexays/Waybar)** - status bar
- **[Ghostty](https://ghostty.org/)** - terminal
- **[Neovim](https://neovim.io/)** - editor with LSP, formatting and linting via Mason
- **[Zsh](https://www.zsh.org/)** - shell with the Zinit plugin manager and a [Starship](https://starship.rs/) prompt
- **[OpenCode](https://opencode.ai/)** - AI coding assistant configuration
- rofi, dunst, bat, btop, eza, tmux, lazygit, pipewire and wireplumber drop-ins

## Theme

All configurations share the eggfriedrice palette. Every colour-bearing config points at a generated file under
`~/p/eggfriedrice.nvim/extras` (ghostty, waybar, rofi, dunst, hyprland, hyprlock, zsh, fzf, starship, bat, eza, btop,
opencode, tmux, lazygit), so the palette lives in one place and `make extras` in that repo updates everything. The links
are relative (`../../p/eggfriedrice.nvim/...`), so the dotfiles and the theme repo have to be siblings under `$HOME`.
The installer clones the theme repo before it links anything.

## Installation

Prerequisites on a fresh Arch install: a user in the `wheel` group with `sudo`, `git`, and network access. Everything
else, including the AUR helper (yay) and the theme repo, is installed by the script.

```bash
git clone git@github.com:eggfriedrice24/hyprland-dots.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # prints every action without executing
./install.sh             # laptop or desktop is detected from the battery; force with --laptop / --desktop
```

The stages in `install/stages/` run in order:

1. **packages** - enables `[multilib]`, full system upgrade, microcode and Vulkan driver by detected vendor, then the
   lists in `install/packages/` (official repos, then AUR via yay; `aur-desktop.txt` only on the desktop)
2. **theme** - clones or updates `~/p/eggfriedrice.nvim` and checks every extra the configs reference
3. **symlinks** - links each config directory into `~/.config`, plus `~/.zshenv`, `~/.wallpapers` and the Cartograph
   fonts; existing real files are backed up as `*.bak.<timestamp>`
4. **shell** - `chsh` to zsh, first zinit run, fast-syntax-highlighting theme, bat theme cache
5. **services** - NetworkManager, sshd, bluetooth, timesyncd, fstrim, tailscaled, valkey, postgresql (with `initdb`),
   docker group, pipewire user sockets
6. **system** - the tracked `/etc` drop-ins in `install/etc/` (btusb autosuspend, rtw89 on the desktop, zram), bluetooth
   FastConnectable, wireless regdom, GRUB command line (`zswap.enabled=0`, and the ASUS `video=` fix on the desktop),
   GTK theme and dark mode via gsettings
7. **finalize** - font cache, XDG user dirs, state dirs, Rust nightly, Node 22 via fnm, Claude Code, Stremio flatpak

The script is idempotent: rerun it after pulling to converge a machine.

## After install

Things that hold secrets or hardware state and are set up by hand:

- **SSH and git**: restore `~/.ssh` (keys and `config`) and `~/.gitconfig`, then `gh auth login`
- **Tailscale**: `sudo tailscale up`
- **Bluetooth**: pair and trust devices with `bluetoothctl`
- **WiFi on the desktop**: pin the connection to the AP's BSSID and the 5 GHz band to avoid rtw89 stalls:
  `nmcli con modify "<name>" 802-11-wireless.bssid <AP MAC> 802-11-wireless.band a 802-11-wireless.powersave 2`
- **Default apps**: `xdg-mime default zen.desktop x-scheme-handler/http x-scheme-handler/https text/html application/pdf`
  and `xdg-mime default imv.desktop image/png image/jpeg image/webp image/gif`
- **OpenCode**: fill in `opencode/google-workspace.env` (seeded from the example)
- **Slack**: paste the theme from `~/p/eggfriedrice.nvim/extras/slack/eggfriedrice.txt`
- **Neovim**: start `nvim` once, then `:Lazy restore` to pin plugins to the tracked `lazy-lock.json`
- **Ghostty per machine**: optional untracked `ghostty/local` (for example a laptop font size)

## Structure

```
dotfiles/
├── install.sh     # entry point, see install/stages and install/packages
├── install/etc/   # /etc drop-ins the system stage installs
├── hypr/          # Hyprland (Lua), hyprlock, hypridle, scripts
├── waybar/        # status bar
├── ghostty/       # terminal
├── nvim/          # Neovim
├── zsh/           # shell modules, .zshenv sets ZDOTDIR
├── starship/      # prompt
├── rofi/ dunst/ bat/ btop/ eza/ tmux/ lazygit/ opencode/ pipewire/ wireplumber/
└── fonts/         # Cartograph CF, linked into ~/.local/share/fonts
```

## License

Free to use and modify.
