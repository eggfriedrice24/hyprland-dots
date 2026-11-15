-- Framework Laptop 13 Pro (hostname tf, Intel Core Ultra X7 358H, 2880x1920 panel). Extends the
-- laptop layer. SKELETON: every value marked VERIFY is confirmed on the machine (hyprctl monitors,
-- hyprctl devices), see machines/framework/ARRIVAL.md.
return {
	monitors = {
		-- VERIFY: the scale that reads well (1.5, 1.6 and 2 divide 2880x1920 evenly); 1.6 is 1800x1200 logical
		{ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.6 },
	},

	config = {
		-- VERIFY: fractional scale blurs XWayland apps unless they render at native size
		xwayland = { force_zero_scaling = true },
		input = {
			-- natural_scroll comes from the shared input block
			touchpad = { tap_to_click = true, disable_while_typing = true },
			-- a touchscreen maps to the internal panel, not to whichever output is focused
			touchdevice = { output = "eDP-1" },
		},
	},

	setup = function()
		-- VERIFY: three-finger swipe between workspaces
		hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
	end,
}
