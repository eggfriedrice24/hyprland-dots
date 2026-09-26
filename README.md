# dotfiles

Personal dotfiles for Arch Linux with Hyprland compositor.

**Author:** eggfriedrice

## What's Included

- **[Hyprland](https://hypr.land/)** - Wayland compositor configuration
- **[Waybar](https://github.com/Alexays/Waybar)** - Wayland bar
- **[Neovim](https://neovim.io/)** - Modern text editor with LSP support
- **[Ghostty](https://ghostty.org/)** - GPU-accelerated terminal emulator
- **[OpenCode](https://opencode.ai/)** - AI coding assistant configuration
- **[Zsh](https://www.zsh.org/)** - Shell configuration with Zinit plugin manager
- **[Starship](https://starship.rs/)** - Cross-shell prompt

## Theme

All configurations share the eggfriedrice palette. Every color-bearing config points at a generated file under `~/p/eggfriedrice.nvim/extras` (ghostty, waybar, rofi, dunst, hyprland, hyprlock, zsh, fzf, starship, bat, eza, btop, opencode, tmux, lazygit), so the palette lives in one place and `make extras` in that repo updates everything.

## Installation

Clone the repository and symlink the configuration files to their appropriate locations:

```bash
git clone https://github.com/eggfriedrice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Example symlinking
ln -sf ~/.dotfiles/hypr ~/.config/hypr
ln -sf ~/.dotfiles/nvim ~/.config/nvim
ln -sf ~/.dotfiles/opencode ~/.config/opencode
ln -sf ~/.dotfiles/ghostty ~/.config/ghostty
ln -sf ~/.dotfiles/starship ~/.config/starship
ln -sf ~/.dotfiles/waybar ~/.config/waybar
ln -sf ~/.dotfiles/zsh ~/.config/zsh
```

## System Requirements

- **OS:** Arch Linux
- **Display Server:** Wayland
- **Window Manager:** Hyprland
- **Font:** Cartograph CF (with icon support)

## Structure

```
dotfiles/
├── hypr/          # Hyprland window manager
├── waybar/        # Wayland bar
├── opencode/      # OpenCode configuration
├── ghostty/       # Terminal emulator
├── nvim/          # Neovim editor
├── starship/      # Shell prompt
└── zsh/           # Shell configuration
```

## License

Free to use and modify.
