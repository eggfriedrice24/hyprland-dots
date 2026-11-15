-- Desktop (hostname t): Gigabyte B650 AORUS ELITE AX V2, RX 7900 XTX
-- ASUS XG27AQDMGR (OLED, 1440p240) on DP-1, HP P27q G4 on HDMI-A-1 in portrait.
-- DP-1 is also named by the kernel command line in machines/desktop/grub: keep the two in sync.

local notifycmd = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low"

-- right of main, in portrait (pivot). transform 1 = 90 deg clockwise, 3 = counter-clockwise;
-- position centers the 2560-tall portrait against the 1440-tall main (y from -560 to 2000)
local hp_portrait = { output = "HDMI-A-1", mode = "2560x1440@60", position = "2560x-560", scale = 1, transform = 1 }
local hp_landscape = { output = "HDMI-A-1", mode = "2560x1440@60", position = "2560x0", scale = 1, transform = 0 }

return {
	monitors = {
		-- 10bpc matches the boot console's link config, avoids a second DP retrain at login
		{ output = "DP-1", mode = "2560x1440@240", position = "0x0", scale = 1, bitdepth = 10 },
		hp_portrait,
	},

	setup = function()
		hl.device({ name = "razer-razer-deathadder-essential", sensitivity = -0.85 })
		hl.device({ name = "razer-razer-deathadder-essential-1", sensitivity = -0.85 })

		-- Toggle HP monitor orientation (physical pivot: landscape <-> portrait)
		hl.bind("SUPER + O", function()
			local m = hl.get_monitor("HDMI-A-1")
			if m == nil then
				return
			end
			if m.transform == 0 then
				hl.monitor(hp_portrait)
				hl.exec_cmd(notifycmd .. " 'HP: portrait'")
			else
				hl.monitor(hp_landscape)
				hl.exec_cmd(notifycmd .. " 'HP: landscape'")
			end
		end)
	end,
}
