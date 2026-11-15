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
}
