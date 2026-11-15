-- Framework Laptop 13 Pro (hostname tf, Intel Core Ultra X7 358H, 2880x1920 panel). Extends the
-- laptop layer. SKELETON: every value marked VERIFY is confirmed on the machine (hyprctl monitors,
-- hyprctl devices), see machines/framework/ARRIVAL.md.

-- VERIFY: the scale that reads well (1.5, 1.6 and 2 divide 2880x1920 evenly); 1.6 is 1800x1200 logical
local panel = { output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.6 }

-- VERIFY: the switch device name in `hyprctl devices` (ARRIVAL.md, section 7)
local lid_switch = "Lid Switch"

-- VERIFY: the ACPI lid node; the first one that exists is read
local lid_state_files = {
	"/proc/acpi/button/lid/LID0/state",
	"/proc/acpi/button/lid/LID/state",
	"/proc/acpi/button/lid/LID1/state",
}

local function lid_closed()
	for _, path in ipairs(lid_state_files) do
		local f = io.open(path, "r")
		if f then
			local state = f:read("a") or ""
			f:close()
			return state:find("closed") ~= nil
		end
	end
	return false
end

-- an enabled output other than the panel (a dock or a cable)
local function external_present()
	for _, m in ipairs(hl.get_monitors()) do
		if m.name ~= panel.output and m.enabled ~= false then
			return true
		end
	end
	return false
end

local function panel_off()
	hl.monitor({ output = panel.output, disabled = true })
end

local function panel_on()
	local m = hl.get_monitor(panel.output)
	if m == nil or m.enabled == false then
		hl.monitor(panel)
	end
end

return {
	monitors = {
		panel,
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

		-- Lid on a dock: closing it turns the panel off so the session moves to the external
		-- outputs; opening it brings the panel back. Without an external output nothing happens
		-- here and logind suspends as usual (HandleLidSwitchDocked keeps a docked laptop awake).
		-- locked: the lid still works while hyprlock is up.
		hl.bind("switch:on:" .. lid_switch, function()
			if external_present() then
				panel_off()
			end
		end, { locked = true })
		hl.bind("switch:off:" .. lid_switch, panel_on, { locked = true })

		-- the last external output went away while the panel was off: bring it back, never headless
		hl.on("monitor.removed", function()
			if not external_present() then
				panel_on()
			end
		end)
		-- docked with the lid already closed
		hl.on("monitor.added", function()
			if lid_closed() and external_present() then
				panel_off()
			end
		end)

		-- config load or reload with the lid closed on a dock
		if lid_closed() and external_present() then
			panel_off()
		end
	end,
}
