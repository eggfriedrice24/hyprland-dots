-- Hyprland config - Lua entry point

require("startup")
require("env")
require("windowrule")
require("keybinds")
-- palette module, symlinked from the theme repo's extras/lua. Fall back to the same literal
-- colours so the rest of this config still applies when the repo is not cloned yet.
local ok, efr = pcall(require, "eggfriedrice")
if not ok then
	efr = { alpha = { comment = "8695b7", fg_gutter = "46516c" } }
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
		-- from the "Hairline" design (Claude Design), tightened: a 6 px seam between windows, 6 px to the
		-- screen edges, and a 1 px border. Focus is a quiet slate line (comment at 30%), the same
		-- family as the glass edge of rofi and the bar, so the yolk stays for the accents;
		-- unfocused windows keep a fainter fg_gutter hairline (20%) so shared tiling edges never merge
		gaps_in = 3,
		gaps_out = 6,
		border_size = 1,
		col = {
			active_border = "rgba(" .. efr.alpha.comment .. "4d)",
			inactive_border = "rgba(" .. efr.alpha.fg_gutter .. "33)",
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
		animate_manual_resizes = false, -- a resize follows the pointer instead of trailing it on a spring
		mouse_move_focuses_monitor = true,
		enable_swallow = true,
		swallow_regex = "^(com\\.mitchellh\\.ghostty)$",
		-- lets a fresh hyprlock take over the lock after the old one crashed. Did not help on its own
		-- in the Sep 26 2026 incident: the cure there was `pkill hyprlock` plus
		-- `hyprctl eval 'hl.clear_crashed_lockscreen()'` from a TTY (recipe in the README)
		allow_session_lock_restore = true,
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
		rounding = 6,
		rounding_power = 2,
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

-- Animations: "fluid" - smooth glides with zero overshoot; a touch slower and with longer travel
-- than crisp, but every motion is 90% done within about 190 ms, so nothing drags
-- speed is in units of 100 ms of bezier time; springs ignore speed (their timing is pure physics),
-- the parser still wants one, so springs carry speed = 1
hl.config({ animations = { enabled = true } })

-- curves
-- quart: ease-out quart, softer start than quint (24% in the first 60 Hz frame at 250 ms)
hl.curve("quart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
-- smooth: ease-in-out sine, for fades that should melt rather than drop
hl.curve("smooth", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })
-- accel: ease-in for exits
hl.curve("accel", { type = "bezier", points = { { 0.3, 0 }, { 1, 1 } } })
-- glide: critically damped (zeta 1.0), 90% at 186 ms, no overshoot; long, soft landing
hl.curve("glide", { type = "spring", mass = 1, stiffness = 440, damping = 42 })
-- settle: zeta 0.95, 90% at 163 ms, no visible overshoot; tiling reflow, drags and resizes
hl.curve("settle", { type = "spring", mass = 1, stiffness = 500, damping = 42.5 })

-- everything not set below (zoomFactor, any future leaf) gets 300 ms quart instead of 800 ms
hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "quart" })

-- windows: open grows from 88% while fading in, close eases down to 94% in 180 ms
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "glide", style = "popin 88%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "glide", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.8, bezier = "accel", style = "popin 94%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "settle" })

-- layers fade only (the wallpaper layer at startup); dunst gets its slide from a layer rule in
-- windowrule.lua; rofi and waybar keep no_anim there
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "quart", style = "fade" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "quart", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "accel", style = "fade" })

-- fades: 250 ms quart parent; focus-driven fades share it
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "quart" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.2, bezier = "quart" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.6, bezier = "smooth" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "quart" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2.5, bezier = "quart" })
hl.animation({ leaf = "fadeGlow", enabled = true, speed = 2.5, bezier = "quart" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "quart" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.2, bezier = "quart" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.6, bezier = "smooth" })
-- menus, dropdowns and tooltips (Zen, GTK): soft but still near-instant
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 1.2, bezier = "quart" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 0.9, bezier = "smooth" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 4, bezier = "smooth" })

-- border colour on focus change; borderangle stays off (disabled by default, no looping gradient)
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "quart" })

-- workspaces use a bezier, not a spring: every switch warps both workspaces before it starts
-- (WorkspaceAnimationController), so a spring always starts from rest - slower off the mark,
-- a long sub-pixel tail with both workspaces drawn, and a stall after a touchpad swipe
-- a 20% slide under a crossfade; 350 ms quart, 90% at about 155 ms
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "quart", style = "slidefade 20%" })
-- the scratchpad (SUPER+A) rises from below and sinks back
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "quart", style = "slidefadevert 20%" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3.5, bezier = "quart", style = "slidefadevert 20%" })
hl.animation({
	leaf = "specialWorkspaceOut",
	enabled = true,
	speed = 1.8,
	bezier = "accel",
	style = "slidefadevert 20%",
})

hl.animation({ leaf = "monitorAdded", enabled = true, speed = 4, bezier = "quart" })

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
