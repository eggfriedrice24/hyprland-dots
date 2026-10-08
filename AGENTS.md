# AGENTS.md

## Repository Overview

This is a personal dotfiles repository for Arch Linux with Hyprland (Wayland compositor). The configuration follows a
modular architecture with a unified eggfriedrice theme generated from the eggfriedrice.nvim design system.

## Installation & Setup

**Installer:** `install.sh` runs the stages in `install/stages/` in order (packages, theme repo clone, symlinks, shell,
services, system drop-ins from `install/etc/`, finalize). Package lists live in `install/packages/*.txt`. Use
`./install.sh --dry-run` first; `--laptop` / `--desktop` override the battery-based machine detection, and `MACHINE` gates
the desktop-only bits (rtw89 modprobe options, GRUB `video=` line, `aur-desktop.txt`). Rerunning is idempotent.

**Zsh XDG Setup:** `~/.zshenv` is a symlink to `zsh/.zshenv`, which sets `ZDOTDIR="$HOME/.config/zsh"`.

**Hyprland Auto-Start:** Configured in `zsh/.zprofile` to start Hyprland automatically on TTY1 login.

**Bootstrap Process:**

- Zsh auto-installs Zinit plugin manager on first run
- Neovim auto-installs Lazy.nvim plugin manager on first run
- Both use lazy-loading for optimal performance

## Key Architectural Patterns

### Modular Configuration Design

All major components use a source/import pattern to split configs into logical modules:

**Hyprland** - Lua config (0.55+ format), main config at `hypr/hyprland.lua` requires:

- `startup.lua` - Autostart applications (XDG portal, polkit, pipewire, dunst, cliphist, waybar)
- `env.lua` - Environment variables
- `windowrule.lua` - Window and layer rules
- `keybinds.lua` - Keyboard shortcuts
- `eggfriedrice.lua` - symlink to the eggfriedrice.nvim Lua palette module (`extras/lua`); `require("eggfriedrice")` gives `.border`, `.alpha.<name>`, `.hex.<name>`

`hypr/hypridle.conf` and
`hypr/hyprlock.conf` belong to hypridle/hyprlock (separate tools, still hyprlang).
Lua API reference: `/usr/share/hypr/stubs/hl.meta.lua` (lua-ls picks it up via `hypr/.luarc.json`).

**Zsh** - `.zshrc` dynamically sources modules in order:

```bash
theme.zsh → env.zsh → aliases.zsh → options.zsh → efr.zsh → plugins.zsh → keybinds.zsh → prompt.zsh
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
- CLI tools (fzf, eza, bat, starship) come from `install/packages`, not zinit

### Neovim - Lazy.nvim Plugin Manager

- Location: `~/.local/share/nvim/lazy/`
- Configuration: `nvim/lua/config/lazy.lua`
- plugins pinned in `lazy-lock.json` (tracked; `:Lazy restore` on a fresh machine)

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
./scripts/brightnesscontrol.sh  # Brightness control (backlight or DDC)
./scripts/screensht full|area  # Screenshots
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

Configured in `hypr/hyprland.lua`:

- Desktop: DP-1 (2560x1440@240Hz)
- Laptop: eDP-1 (preferred mode)
- Waybar on all outputs

### Keyboard Layouts

Configured in `hypr/hyprland.lua`:

- US + Georgian layouts
- Caps Lock toggles between layouts

### Theme Consistency

All components use unified colors:

- Source of truth: `~/p/eggfriedrice.nvim/lua/eggfriedrice/colors.lua`; generated per-app files under its `extras/` (regenerate with `make extras` there)
- Hyprland and hyprlock: `hypr/eggfriedrice.lua` symlink and `source =` of `extras/hyprland`
- Neovim: eggfriedrice.nvim as a local `dir =` build
- Starship: the `[palettes.eggfriedrice]` block in `starship/starship.toml` is copied from `extras/starship` (re-paste after `make extras`)
- Shell: `zsh/theme.zsh` sources `extras/zsh`, `zsh/env.zsh` sources `extras/fzf`, fast-syntax-highlighting uses `extras/fsh` via `fast-theme`
- waybar and ghostty tabs import `extras/gtk`; rofi imports `extras/rofi`; dunst, bat, eza, btop, opencode, lazygit and tmux link or source their extras

### Git Workflow

The `.gitignore` excludes:

- Runtime files: `.zcompdump`, `.zsh_history`
- Logs and swap files
- `AGENTS.md` itself

When making changes, preserve this exclusion pattern.

## System Requirements

- **OS:** Arch Linux
- **Display Server:** Wayland
- **Compositor:** Hyprland
- **Terminal:** Ghostty
- **Shell:** Zsh
- **Editor:** Neovim
- **Font:** Cartograph CF with icon support
- **Additional tools:** waybar, dunst, awww, cliphist, polkit-kde-agent, pipewire

## Code Modification Guidelines

### When Editing Configurations

1. **Preserve modular structure** - Don't consolidate split configs back into monolithic files
2. **Maintain theme consistency** - New colours come from the eggfriedrice palette: add the role in the design system and regenerate the extras
3. **Follow XDG standards** - All new paths should use XDG environment variables
4. **Use lazy-loading** - New plugins should specify lazy-load conditions
5. **Update documentation** - If adding significant features, update README.md

### File Reference Patterns

- Hyprland config modules are pulled in with Lua `require("filename")` from `hyprland.lua`
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

Hyprland utility scripts live in `hypr/scripts/` (battery and Keychron battery watchers, brightness and volume OSD, DDC brightness, screenshot, colour picker, game mode, system update count, portal reset, kill active tree):

- Battery management, brightness/volume control
- Screenshot utility and colour picker
- Game mode, system updates, portal resets

When creating new scripts, place them in this directory and make them executable.
