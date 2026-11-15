-- Shared laptop layer: the thinkpad and framework profiles extend it (their extends file), and it is
-- the profile of any laptop that matches nothing in machines/index (detected by its battery).
return {
	monitors = {
		{ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 },
		-- anything plugged in: its preferred mode, placed by Hyprland
		{ output = "", mode = "preferred", position = "auto", scale = 1 },
	},
}
