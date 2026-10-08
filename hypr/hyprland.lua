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

-- Monitors
hl.monitor({ output = "DP-1", mode = "2560x1440@240", position = "0x0", scale = 1, bitdepth = 10 }) -- 10bpc matches the boot console's link config, avoids a second DP retrain at login
-- HP P27q, right of main, in portrait (pivot).
-- transform 1 = 90 deg clockwise, 3 = counter-clockwise; position centers the
-- 2560-tall portrait against the 1440-tall main (y from -560 to 2000).
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "2560x-560", scale = 1, transform = 1 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

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

hl.device({ name = "razer-razer-deathadder-essential", sensitivity = -0.85 })
hl.device({ name = "razer-razer-deathadder-essential-1", sensitivity = -0.85 })

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
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })

-- Layouts
hl.config({
	dwindle = {
		preserve_split = true, -- you probably want this
	},
})

-- master: defaults, see https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
