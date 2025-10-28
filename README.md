# dotfiles

Personal dotfiles for Arch Linux with Hyprland compositor.

**Author:** eggfriedrice

## What's Included

- **[Hyprland](https://hypr.land/)** - Wayland compositor configuration
- **[Neovim](https://neovim.io/)** - Modern text editor with LSP support
- **[Kitty](https://sw.kovidgoyal.net/kitty/)** - GPU-accelerated terminal emulator
- **[Zsh](https://www.zsh.org/)** - Shell configuration with Zinit plugin manager
- **[Starship](https://starship.rs/)** - Cross-shell prompt

## Theme

All configurations use a consistent color scheme inspired by Catppuccin Mocha and Halcyon themes.

## Installation

Clone the repository and symlink the configuration files to their appropriate locations:

```bash
git clone https://github.com/eggfriedrice/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Example symlinking
ln -sf ~/.dotfiles/hypr ~/.config/hypr
ln -sf ~/.dotfiles/nvim ~/.config/nvim
ln -sf ~/.dotfiles/kitty ~/.config/kitty
ln -sf ~/.dotfiles/starship ~/.config/starship
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
├── kitty/         # Terminal emulator
├── nvim/          # Neovim editor
├── starship/      # Shell prompt
└── zsh/           # Shell configuration
```

## License

Free to use and modify.
