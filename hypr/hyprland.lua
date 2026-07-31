-- █▀▀ █▄░█ █░█   █░█ ▄▀█ █▀█
-- ██▄ █░▀█ ▀▄▀   ▀▄▀ █▀█ █▀▄

require("startup")
require("env")
require("windowrule")
require("keybinds")
-- Catppuccin palette lives in mocha.lua: local mocha = require("mocha")

-- █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
-- █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

hl.monitor({ output = "DP-3", mode = "2560x1440@240", position = "0x0", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })



-- █ █▄░█ █▀█ █░█ ▀█▀
-- █ █░▀█ █▀▀ █▄█ ░█░

hl.config({
  input = {
    kb_layout = "us,ge",
    kb_options = "grp:caps_toggle",
    follow_mouse = 1,
    sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
    -- force_no_accel = true
    -- kb_model = "cherryblue" -- XKB model
    -- kb_variant = "dvorak" -- XKB variant
    -- numlock_by_default = false
    -- repeat_rate = 25
    -- repeat_delay = 600
    -- accel_profile = "flat" -- flat, adaptive
    touchpad = {
      natural_scroll = true,
    },
  },
})

hl.device({ name = "razer-razer-deathadder-essential", sensitivity = -0.85 })
hl.device({ name = "razer-razer-deathadder-essential-1", sensitivity = -0.85 })



-- █▀▀ █▀▀ █▄░█ █▀▀ █▀█ ▄▀█ █░░
-- █▄█ ██▄ █░▀█ ██▄ █▀▄ █▀█ █▄▄

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 0,
    border_size = 0,
    col = {
      active_border = "rgba(3c415580)",
      inactive_border = "rgba(382d2eff)", -- was 0xff382D2E
    },
    layout = "dwindle",
    -- no_focus_fallback = false
    -- resize_on_border = false
  },
})



-- █▀▄▀█ █ █▀ █▀▀
-- █░▀░█ █ ▄█ █▄▄

hl.config({
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    mouse_move_enables_dpms = true,
    vrr = 0,
    animate_manual_resizes = true,
    mouse_move_focuses_monitor = true,
    enable_swallow = true,
    swallow_regex = "^(kitty)$",
  },
})



-- █▀▄ █▀▀ █▀▀ █▀█ █▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- █▄▀ ██▄ █▄▄ █▄█ █▀▄ █▀█ ░█░ █ █▄█ █░▀█

hl.config({
  decoration = {
    rounding = 3,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      xray = true,
      ignore_opacity = true,
    },
  },
})



-- ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█

hl.config({ animations = { enabled = true } })

-- bezier curves
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })

-- █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
-- █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█

hl.config({
  dwindle = {
    preserve_split = true, -- you probably want this
  },
})

-- master: defaults, see https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
