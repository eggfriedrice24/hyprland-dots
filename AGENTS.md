# AGENTS.md

## Repository Overview

This is a personal dotfiles repository for Arch Linux with Hyprland (Wayland compositor). The configuration follows a
modular architecture with a unified eggfriedrice theme generated from the eggfriedrice.nvim design system.

## Installation & Setup

**Installer:** `install.sh` runs the nine stages in `install/stages/` in order (01-packages, 02-theme, 03-symlinks,
04-shell, 05-services, 06-system, 07-snapshots, 08-migrations, 09-finalize). Package lists live in
`install/packages/*.txt`. Use `./install.sh --dry-run --yes` first; `--profile NAME|auto` picks or unpins the machine
profile, `--print-profile` shows it, `--no-upgrade`, `--skip=a,b` and `--quiet` exist for `dots-update`. Exit status 3
means a migration is still pending. Rerunning is idempotent. Helpers every stage uses (`run`, `try`, `note`,
`install_etc_file`, `profile_files`, ...) are in `install/utils.sh`.

**Machine profiles:** `machines/<profile>/` (desktop, laptop, thinkpad, framework, generic) holds everything
machine-specific: `hypr.lua` (monitors, config, setup, hypridle), `extends`, `packages.txt`, `aur.txt`, `services`,
`etc/`, `grub`, `system.sh`, `notes`. `machines/index` maps DMI strings to a profile; `install/machine.sh` and
`hypr/machine.lua` resolve it identically (flag, pin in `~/.config/dotfiles/profile`, DMI, battery -> laptop, else
generic). Hostnames are `t` (desktop), `tt` (ThinkPad), `tf` (Framework), but nothing may key on the hostname.

**Commands:** `bin/` is linked into `~/.local/bin` by stage 3. `bin/dots-update` (alias `up`) syncs both repos,
snapshots, upgrades packages and runs `install.sh --no-upgrade`. `bin/dots-snapshot` owns every snapper call (status,
pre, post, list, rollback, undo, cleanup); it is a no-op on this ext4 desktop. `install/migrate.sh` runs and lists the
one-off migrations in `install/migrations/`. README.md documents all three.

**Zsh XDG Setup:** `~/.zshenv` is a symlink to `zsh/.zshenv`, which sets `ZDOTDIR="$HOME/.config/zsh"`.

**Hyprland Auto-Start:** `zsh/.zprofile` sources `zsh/session.zsh` (PATH, XDG dirs, EDITOR, BROWSER, TERMINAL,
SSH_AUTH_SOCK), hands those names to systemd and D-Bus activation, and execs Hyprland on a TTY1 login outside any
graphical session.

**Bootstrap Process:**

- Zsh auto-installs Zinit plugin manager on first run (stage 4 runs that first shell)
- Neovim auto-installs Lazy.nvim on first run; stage 9 restores the plugins from `lazy-lock.json` and installs the Mason
  tools headless on a machine that has none
- Both use lazy-loading for optimal performance

## Key Architectural Patterns

### Modular Configuration Design

All major components use a source/import pattern to split configs into logical modules:

**Hyprland** - Lua config (0.55+ format), main config at `hypr/hyprland.lua` requires:

- `startup.lua` - Autostart (environment for the portals, polkit agent, pipewire restart, dunst, cliphist text watcher,
  awww, waybar logging to `~/.local/state/waybar.log`, the battery watchers, hypridle with the profile's config)
- `env.lua` - Environment variables
- `windowrule.lua` - Window and layer rules
- `keybinds.lua` - Keyboard shortcuts
- `eggfriedrice.lua` - symlink to the eggfriedrice.nvim Lua palette module (`extras/lua`); `require("eggfriedrice")` gives `.border`, `.alpha.<name>`, `.hex.<name>`
- `machine.lua` - resolves the machine profile and loads `machines/<profile>/hypr.lua` through the tracked
  `hypr/machines -> ../machines` link; `hyprland.lua` applies its monitors first and its config and `setup()` last

`hypr/hypridle.conf` (the desktop's lock-only idle; laptops use `machines/laptop/hypridle.conf`) and
`hypr/hyprlock.conf` belong to hypridle/hyprlock (separate tools, still hyprlang).
Lua API reference: `/usr/share/hypr/stubs/hl.meta.lua` (lua-ls picks it up via `hypr/.luarc.json`).

**Zsh** - `.zshrc` sources the modules in a plain loop, in order:

```bash
theme.zsh → env.zsh → aliases.zsh → options.zsh → efr.zsh → plugins.zsh → keybinds.zsh → prompt.zsh
```

`env.zsh` sources `session.zsh` first, the same file `.zprofile` reads before Hyprland starts; machine-only paths go in
the untracked `zsh/local.zsh`, which `session.zsh` sources. `options.zsh` selects the emacs keymap.

**Neovim** - `init.lua` imports from `lua/config/`, Lazy.nvim auto-imports from `lua/plugins/`:

- `lua/config/` - Core configuration (options, keymaps, lazy setup)
- `lua/plugins/` - Plugin specs organized by category (lsp.lua, coding.lua, editor.lua, formatting.lua, lualine.lua,
  treesitter.lua, ui.lua, colorscheme.lua)
- `after/plugin/` - `lsp.lua` (diagnostics display) and `theme-dev.lua` (`:ThemeReload` for the local theme build)

### XDG Base Directory Compliance

All configurations follow XDG specification defined in `zsh/session.zsh` (shared by shells and the graphical session):

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
- plugins pinned in `lazy-lock.json` (tracked; the installer restores it headless on a new machine, `:Lazy restore`
  by hand)

### Mason - LSP/Tools Manager

`mason-tool-installer` in `nvim/lua/plugins/lsp.lua` keeps these installed (checked at every start, and by
`MasonToolsInstallSync` headless); every name must exist in the Mason registry:

**LSPs:** lua-language-server, gopls, json-lsp, typescript-language-server, astro-language-server, css-lsp,
tailwindcss-language-server, html-lsp, yaml-language-server, jdtls, basedpyright, emmet-language-server, rust-analyzer
**Formatters:** stylua, prettier, black, isort, gofumpt, goimports, google-java-format, shfmt **Linters:** eslint-lsp,
selene, shellcheck, golangci-lint, markdownlint

Not from Mason: rustfmt comes with rustup (Mason dropped it), oxfmt and oxlint are taken from a project's
`node_modules` when present. Formatters are wired in `formatting.lua` (conform.nvim, format on save) and linters in
the same file (nvim-lint: selene, golangcilint, markdownlint, shellcheck; zsh is not shellchecked).

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
# Check a config without loading it (safe; a plain edit in ~/dotfiles reloads the live session)
Hyprland --verify-config --config <path>/hypr/hyprland.lua

# The Lua config manager rejects `hyprctl keyword`; dispatch takes hl.dsp.* Lua, eval runs Lua
hyprctl eval 'hl.config({ misc = { vrr = 0 } })'

# Utility scripts (in hypr/scripts/)
./scripts/volumecontrol.sh i|d|m      # Volume (capped at 100 percent) with an OSD
./scripts/brightnesscontrol.sh i|d    # Backlight on the panel, DDC/CI on an external monitor
./scripts/screensht full|area         # Screenshots
./scripts/screenrecord screen|area|stop|toggle
```

### Installer and theme checks

```bash
./install.sh --dry-run --yes          # every action, nothing changed
./install.sh --print-profile          # the machine profile and its source
install/migrate.sh --status           # migrations and their state
install/theme-apply.sh                # rebuild the derived theme caches after `make extras` in the theme repo
install/lint-colors.sh                # colour literals that bypass the palette
```

## Development Workflow

### Multi-Language Support

The Neovim configuration supports these languages with LSP, formatting and linting:

- **TypeScript/JavaScript** - ts_ls, eslint, prettier (oxfmt and oxlint when the project has them)
- **Astro, CSS, Tailwind, HTML, emmet** - astro (falls back to Mason's bundled TypeScript), cssls, tailwindcss, html,
  emmet_language_server, prettier
- **Lua** - lua_ls, stylua, selene
- **Python** - basedpyright, isort, black
- **Go** - gopls, goimports, gofumpt, golangci-lint
- **Rust** - rust_analyzer, rustfmt (rustup)
- **Java** - jdtls, google-java-format
- **Shell** - shfmt, shellcheck (sh and bash)
- **JSON/YAML/Markdown** - jsonls, yamlls, prettier, markdownlint

### Version Managers

**FNM (Fast Node Manager)** - the binary and the default Node are on PATH from `zsh/session.zsh`, so launchers and user
units find `node` too; `zsh/env.zsh` adds `fnm env --use-on-cd`:

- Auto-switches Node versions based on `.nvmrc` files
- Node 22 is the default the installer sets up

**PNPM** - from the repository package (pnpm 11 sets `PNPM_HOME` through `/etc/profile.d/pnpm.sh`)

**rustup** - the installer selects the nightly toolchain

## Important Configuration Details

### Monitors and other per-machine values

Configured in `machines/<profile>/hypr.lua`, never in the shared hypr files:

- Desktop: DP-1 (ASUS OLED, 2560x1440@240, bitdepth 10, coupled to `video=DP-1` in `machines/desktop/grub`) and
  HDMI-A-1 (HP, portrait, SUPER+O flips it)
- Laptop layer: eDP-1 at scale 1 plus a catch-all rule for anything plugged in
- Framework: eDP-1 at scale 1.6 (VERIFY values are settled with `machines/framework/ARRIVAL.md`), gestures, lid handling
- Waybar on all outputs

### Migrations, updates and snapshots

- A change that must remove or replace something on machines that already ran an older version (a package, a config
  dir, an `/etc` file) is a new migration: `install/migrate.sh --new <slug>`, description on line 2, helpers from
  `install/utils.sh` and `install/migrate.sh` (`remove_packages`, `swap_package`, `remove_path`, `remove_etc_file`,
  `as_root`). Never edit a migration that has been pushed; delete one when the thing it removes is added back.
- Gate behaviour on `PROFILE` or on a capability (`has_battery`, `has_snapshots`, `has_pkg`), never on the hostname.
- `dots-update` is the only caller of `dots-snapshot pre/post/discard`; snap-pac covers ad-hoc pacman runs.
- State lives in `~/.local/state/dotfiles/` (`migrations`, `update/`, `install/` logs, `last-rollback`); the profile
  pin in `~/.config/dotfiles/profile`.

### Keyboard Layouts

Configured in `hypr/hyprland.lua`:

- US + Georgian layouts
- Caps Lock toggles between layouts

### Theme Consistency

All components use unified colors and typography:

- Source of truth: `~/p/eggfriedrice.nvim/lua/eggfriedrice/colors.lua` and `typography.lua` (Nunito Medium for UI,
  Cartograph CF for terminal text only, sizes xs 9, sm 10, md 11, lg 13); generated per-app files under its `extras/`
  (regenerate with `make extras` there, then run `install/theme-apply.sh` here)
- Hyprland and hyprlock: `hypr/eggfriedrice.lua` symlink and `source =` of `extras/hyprland` (colours and `$font_ui`)
- Neovim: eggfriedrice.nvim as a local `dir =` build; lualine, incline and notify take colours from `eggfriedrice.colors`
- Starship: the `[palettes.eggfriedrice]` block in `starship/starship.toml` is copied from `extras/starship` (re-paste after `make extras`; stage 4 warns on drift)
- Shell: `zsh/theme.zsh` sources `extras/zsh`, `zsh/env.zsh` sources `extras/fzf`, fast-syntax-highlighting uses `extras/fsh` via `fast-theme`
- waybar imports `extras/gtk` (colours, `font.css`); ghostty's tab bar imports `extras/gtk` (colours, `typography.css`);
  rofi imports `extras/rofi` (colours, launcher roles, `@font-ui-sm` and friends); dunst, bat, eza, btop, opencode and
  frameit link or include their extras
- GTK apps: `gtk-3.0/` and `gtk-4.0/` import `extras/adw` (named colors that recolor adw-gtk3 and libadwaita) plus `extras/gtk`; `gtk-3.0/thunar.css` styles Thunar; the UI font is the gsettings `font-name` stage 6 sets; `install/papirus-folders.sh` builds Papirus-Dark-eggfriedrice from `extras/papirus` (`install/theme-apply.sh` reruns it when needed)
- Every extra the dotfiles reference is listed in `THEME_REQUIRED_EXTRAS` (`install/utils.sh`); stage 2 and
  `dots-update` fail when one is missing. `install/lint-colors.sh` reports hex literals outside its allowlist.

### Git Workflow

The `.gitignore` excludes:

- Runtime files: `.zcompdump`, `.zsh_history`, `nvim/.netrwhist`, `nvim/plugin/`
- Logs and swap files
- Machine-local files: `ghostty/local`, `zsh/local.zsh`, the GTK state files apps write into the linked config dirs
  (`gtk-3.0/bookmarks`, `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`), `opencode/google-workspace.env`

`AGENTS.md` is tracked, and so is `CLAUDE.md`, a one-line `@AGENTS.md` import: edit `AGENTS.md`, never copy it. Keep machine-local and runtime files out of the repo by adding them to `.gitignore`.

## System Requirements

- **OS:** Arch Linux
- **Display Server:** Wayland
- **Compositor:** Hyprland
- **Terminal:** Ghostty
- **Shell:** Zsh
- **Editor:** Neovim
- **Fonts:** Nunito (UI), Cartograph CF (terminal, tracked in `fonts/`), JetBrainsMono Nerd Font (icons), Noto Color Emoji
- **Additional tools:** waybar, dunst, rofi, awww, cliphist, hypridle, hyprlock, polkit-kde-agent, pipewire, Thunar

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
- Keybinds live in `hypr/keybinds.lua`, machine-only ones in a profile's `setup()`; README.md has the table, keep it
  in step with both

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

Hyprland utility scripts live in `hypr/scripts/`:

- `battery-watcher.sh` (laptop battery: notices at 25 and 10 percent, suspend at 5 while discharging) and
  `kbd-battery-watcher.sh` (the Keychron K4, found by model name), started by `startup.lua`
- `brightnesscontrol.sh` (backlight or DDC/CI, serialized with flock) and `volumecontrol.sh`, both with an OSD
- `idle-suspend` (suspends only on battery; called by `machines/laptop/hypridle.conf`)
- `screensht`, `screenrecord` and `colorpicker`; `clipboard` (the cliphist picker on SUPER+V)
- `gamemode.sh` (animations, blur, gaps and rounding off and back, run by hand)
- `systemupdate.sh` (waybar JSON from the dots-update status file; `up` opens dots-update in a terminal)

When creating new scripts, place them in this directory and make them executable. Commands meant for a shell go in
`bin/` instead, which stage 3 links into `~/.local/bin`.
