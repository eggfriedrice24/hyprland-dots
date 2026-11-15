-- Shared laptop layer: the thinkpad and framework profiles extend it (their extends file), and it is
-- the profile of any laptop that matches nothing in machines/index (detected by its battery).
return {
	monitors = {
		{ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 },
		-- anything plugged in: its preferred mode, placed by Hyprland
		{ output = "", mode = "preferred", position = "auto", scale = 1 },
	},

	-- dim, lock, display off, and suspend on battery (the desktop keeps the lock-only hypr/hypridle.conf)
	hypridle = "hypridle.conf",

	config = {
		-- the idle config turns the display off; a key press wakes it, not only the mouse
		misc = { key_press_enables_dpms = true },
	},

	setup = function()
		-- Lid closed with no other screen: lock and turn the display off. On external power the
		-- machine keeps running, reachable over tailscale like a small server (logind ignores the
		-- lid there: etc/systemd/logind.conf.d/10-lid.conf); on battery logind suspends it as before.
		-- With another screen connected nothing happens here: a profile's dock handling (the
		-- Framework's) turns the panel off instead and the session stays unlocked.
		-- locked: the lid still works while hyprlock is up.
		local lid = "Lid Switch" -- the switch in `hyprctl devices` (ThinkPad and Framework alike)
		hl.bind("switch:on:" .. lid, function()
			for _, m in ipairs(hl.get_monitors()) do
				if m.name ~= "eDP-1" and m.enabled ~= false then
					return
				end
			end
			hl.exec_cmd("loginctl lock-session")
			hl.dispatch(hl.dsp.dpms({ action = "off" }))
		end, { locked = true })
		hl.bind("switch:off:" .. lid, function()
			hl.dispatch(hl.dsp.dpms({ action = "on" }))
		end, { locked = true })
	end,
}
