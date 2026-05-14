# AGENTS.md

## Repository Overview

This is a personal dotfiles repository for Arch Linux with Hyprland (Wayland compositor). The configuration follows a
modular architecture with a unified Catppuccin Mocha + Halcyon theme across all components.

## Installation & Setup

**Manual Installation:** This repository uses manual symlinking (no automated installer):

```bash
ln -sf ~/.dotfiles/hypr ~/.config/hypr
ln -sf ~/.dotfiles/nvim ~/.config/nvim
ln -sf ~/.dotfiles/kitty ~/.config/kitty
ln -sf ~/.dotfiles/starship ~/.config/starship
ln -sf ~/.dotfiles/zsh ~/.config/zsh
```

**Zsh XDG Setup:** For XDG compliance, create `~/.zshenv` in your home directory:

```bash
echo 'export ZDOTDIR="$HOME/.config/zsh"' > ~/.zshenv
```

**Hyprland Auto-Start:** Configured in `zsh/.zprofile` to start Hyprland automatically on TTY1 login.

**Bootstrap Process:**

- Zsh auto-installs Zinit plugin manager on first run
- Neovim auto-installs Lazy.nvim plugin manager on first run
- Both use lazy-loading for optimal performance

## Key Architectural Patterns

### Modular Configuration Design

All major components use a source/import pattern to split configs into logical modules:

**Hyprland** - Main config at `hypr/hyprland.conf` sources:

- `startup.conf` - Autostart applications (XDG portal, polkit, pipewire, dunst, cliphist, swww, waybar)
- `env.conf` - Environment variables
- `windowrule.conf` - Window management rules
- `keybinds.conf` - Keyboard shortcuts
- `mocha.conf` - Catppuccin Mocha color scheme

**Zsh** - `.zshrc` dynamically sources modules in order:

```bash
theme.zsh → env.zsh → aliases.zsh → options.zsh → plugins.zsh → keybinds.zsh → prompt.zsh
```

**Neovim** - `init.lua` imports from `lua/config/`, Lazy.nvim auto-imports from `lua/plugins/`:

- `lua/config/` - Core configuration (options, keymaps, lazy setup)
- `lua/plugins/` - Plugin specs organized by category (lsp.lua, coding.lua, editor.lua, formatting.lua, treesitter.lua,
  ui.lua, colorscheme.lua)
- `after/plugin/` - Plugin-specific configurations

### XDG Base Directory Compliance

All configurations follow XDG specification defined in `zsh/env.zsh`:

- XDG_CONFIG_HOME: `~/.config`
- XDG_CACHE_HOME: `~/.cache`
- XDG_DATA_HOME: `~/.local/share`
- XDG_STATE_HOME: `~/.local/state`

## Package Managers & Dependencies

### Zsh - Zinit Plugin Manager

- Location: `~/.local/share/zinit/`
- Configuration: `zsh/plugins.zsh`
- Plugins use `zinit ice wait lucid` for delayed loading

Key plugins:

- Completions: zsh-completions
- Syntax: fast-syntax-highlighting
- Suggestions: zsh-autosuggestions
- Navigation: fzf-tab
- History: history-substring-search, history-search-multi-word
- Quality of Life: zsh-autopair, zsh-you-should-use
- CLI Tools: fzf-bin, exa, bat (installed as binaries)

### Neovim - Lazy.nvim Plugin Manager

- Location: `~/.local/share/nvim/lazy/`
- Configuration: `nvim/lua/config/lazy.lua`
- 32 plugins tracked in `lazy-lock.json`

### Mason - LSP/Tools Manager

Configured in `nvim/lua/plugins/lsp.lua`:

**LSPs:** lua_ls, ts_ls, cssls, tailwindcss, html, yamlls **Formatters:** stylua, prettier, black, isort, gofumpt,
goimports, rustfmt **Linters:** luacheck, selene, eslint_d, shellcheck, flake8, golangci-lint, markdownlint

## Common Commands

### Neovim Plugin Management

```bash
# Open Neovim and run:
:Lazy                # Open Lazy.nvim UI
:Lazy sync           # Update/install plugins
:Mason               # Open Mason UI for LSP/tools
:MasonUpdate         # Update Mason packages
```

### Zsh Plugin Management

```bash
# Zinit auto-installs on first run, update with:
zinit self-update    # Update Zinit itself
zinit update --all   # Update all plugins
```

### Hyprland

```bash
# Reload configuration
hyprctl reload

# Run utility scripts (in hypr/scripts/)
./scripts/volumecontrol.sh    # Volume control
./scripts/brightness.sh       # Brightness control
./scripts/screenshot.sh       # Screenshots
./scripts/randwall.sh         # Random wallpaper
./scripts/batterynotify.sh    # Battery monitoring
```

## Development Workflow

### Multi-Language Support

The Neovim configuration supports these languages with full LSP/formatting/linting:

- **TypeScript/JavaScript** - ts_ls, prettier, eslint_d
- **Lua** - lua_ls, stylua, luacheck/selene
- **Python** - black, isort, flake8
- **Go** - gofumpt, goimports, golangci-lint
- **Rust** - rustfmt
- **CSS/HTML/YAML** - Full LSP support

### Version Managers

**FNM (Fast Node Manager)** - Configured in `zsh/env.zsh`:

- Auto-switches Node versions based on `.nvmrc` files
- Integrated with shell initialization

**PNPM** - Package manager for Node.js projects

## Important Configuration Details

### Hyprland Multi-Monitor Setup

Configured in `hypr/hyprland.conf`:

- Primary: eDP-1 (1920x1080@60Hz)
- Secondary: HDMI-A-1 (2560x1440@60Hz)
- Waybar on all outputs

### Keyboard Layouts

Configured in `hypr/hyprland.conf`:

- US + Georgian layouts
- Caps Lock toggles between layouts

### Theme Consistency

All components use unified colors:

- Hyprland: Catppuccin Mocha colors in `hypr/mocha.conf`
- Neovim: Halcyon colorscheme
- Starship: Custom colors matching theme palette
- FZF: Catppuccin Mocha colors in `zsh/env.zsh`

### Git Workflow

The `.gitignore` excludes:

- Runtime files: `.zcompdump`, `.zsh_history`, `lazy-lock.json`
- Logs and swap files
- `AGENTS.md` itself

When making changes, preserve this exclusion pattern.

## System Requirements

- **OS:** Arch Linux
- **Display Server:** Wayland
- **Compositor:** Hyprland
- **Terminal:** Kitty (primary), Ghostty (config available)
- **Shell:** Zsh
- **Editor:** Neovim
- **Font:** Cartograph CF with icon support
- **Additional tools:** waybar, dunst, swww, cliphist, polkit-kde-agent, pipewire

## Code Modification Guidelines

### When Editing Configurations

1. **Preserve modular structure** - Don't consolidate split configs back into monolithic files
2. **Maintain theme consistency** - New colors should match Catppuccin Mocha palette
3. **Follow XDG standards** - All new paths should use XDG environment variables
4. **Use lazy-loading** - New plugins should specify lazy-load conditions
5. **Update documentation** - If adding significant features, update README.md

### File Reference Patterns

- Hyprland configs reference each other with: `source = ~/.config/hypr/filename.conf`
- Zsh modules are sourced dynamically via the loop in `.zshrc`
- Neovim plugins are auto-discovered in `lua/plugins/` directory
- Hyprland scripts are centralized in `hypr/scripts/` directory

### Plugin Management

**Adding new Neovim plugins:**

1. Create or update files in `nvim/lua/plugins/`
2. Follow existing categorization (lsp, coding, editor, ui, etc.)
3. Specify lazy-load conditions (events, commands, keys)
4. Run `:Lazy sync` to install

**Adding new Zsh plugins:**

1. Add to `zsh/plugins.zsh` using Zinit syntax
2. Use `wait lucid` for non-essential plugins
3. Run `zinit update --all` to install

### Utility Scripts

All Hyprland utility scripts (15 total) are in `hypr/scripts/`:

- Battery management, brightness/volume control
- Clipboard management (cliphist)
- Screenshot utility, theme switching, color picker
- Game mode, system updates, portal resets

When creating new scripts, place them in this directory and make them executable.
