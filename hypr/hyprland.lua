-- Hyprland config - Lua entry point

require("startup")
require("env")
require("windowrule")
require("keybinds")
-- palette module, symlinked from the theme repo's extras/lua. Fall back to the same literal
-- colours so the rest of this config still applies when the repo is not cloned yet.
local ok, efr = pcall(require, "eggfriedrice")
if not ok then
	efr = { border = "rgb(c9a747)", fg_gutter_ui = "rgb(586480)" }
end

-- Monitors, devices and other per-machine values: machines/<profile>/hypr.lua, picked by machine.lua
-- (the same resolution as install/machine.sh). A broken profile leaves no monitor rules, not a dead session.
local machine_ok, machine = pcall(require, "machine")
if not machine_ok or type(machine) ~= "table" then
	print("machine.lua did not load: " .. tostring(machine))
	machine = { name = "generic", monitors = {} }
end
hl.env("DOTFILES_PROFILE", machine.name)
for _, monitor in ipairs(machine.monitors or {}) do
	hl.monitor(monitor)
end

-- Input
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

-- General
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 0,
		border_size = 0,
		col = {
			active_border = efr.border, -- gold accent border
			inactive_border = efr.fg_gutter_ui, -- readable gray, inactive borders
		},
		layout = "dwindle",
		-- no_focus_fallback = false
		-- resize_on_border = false
	},
})

-- Misc
hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		vrr = 0, -- keep 0: this panel is OLED, and VRR makes its luminance track the varying refresh
		-- interval, which shows up as brightness flicker in dark scenes. Tried vrr=2 (fullscreen only)
		-- on 2026-09-20 and the flicker appeared in-game immediately. Related: hypr flicker history.
		animate_manual_resizes = true,
		mouse_move_focuses_monitor = true,
		enable_swallow = true,
		swallow_regex = "^(com\\.mitchellh\\.ghostty)$",
		-- lets a fresh hyprlock take over the lock after the old one crashed. Did not help on its own
		-- in the Sep 26 2026 incident: the cure there was `pkill hyprlock` plus
		-- `hyprctl eval 'hl.clear_crashed_lockscreen()'` from a TTY (recipe in the README)
		allow_session_lock_restore = true,
	},
})

-- Render
hl.config({
	render = {
		direct_scanout = 0, -- MUST stay 0: scanout hands the game its 8bpc buffer, forcing DP-1 off its 10bpc format.
		-- That format change triggers a runtime modeset (brief black screen), which is exactly what
		-- the bitdepth=10 setting and the GRUB video= param exist to keep confined to boot.
	},
})

-- raise windows when they gain focus, so overlapping ones don't stay buried.
-- dispatch executes asynchronously, so don't hold the event's window object
-- (it can expire before execution) - with no window given, the dispatcher
-- resolves the active window itself when it runs
hl.on("window.active", function(w)
	if w == nil then
		return
	end
	hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Decoration
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

-- Animations
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
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })

-- Layouts
hl.config({
	dwindle = {
		preserve_split = true, -- you probably want this
	},
})

-- master: defaults, see https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

-- Per-machine config, binds and devices go last so they win over the shared values above
if machine.apply then
	machine.apply()
end
