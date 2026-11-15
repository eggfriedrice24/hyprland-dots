-- Keybinds

local scriptsDir = "$HOME/.config/hypr/scripts"
local notifycmd = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low"

local term = "ghostty"
local volume = scriptsDir .. "/volumecontrol.sh"
local screenshot = scriptsDir .. "/screensht"
local screenrecord = scriptsDir .. "/screenrecord"
local colorpicker = scriptsDir .. "/colorpicker"
local files = "thunar"
local browser = "zen-browser"
local browserP = "helium-browser"

-- Volume and brightness: locked so they also work on the lock screen. Volume steps repeat while
-- held; brightness does not yet, because held presses would race on the DDC path
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volume .. " i"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volume .. " d"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volume .. " m"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/brightnesscontrol.sh i"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/brightnesscontrol.sh d"), { locked = true })

-- Media and mic mute: playerctl drives whichever MPRIS player is active; mic mute toggles the
-- default source and says which way it went, since most keyboards have no mic LED
local micmute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then "
	.. notifycmd
	.. " -i microphone-sensitivity-muted-symbolic 'Microphone muted'; else "
	.. notifycmd
	.. " -i microphone-sensitivity-high-symbolic 'Microphone on'; fi"
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(micmute), { locked = true })

-- Screenshot and recording: R records the focused monitor to ~/Videos/Recordings, V stops it
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(screenrecord .. " screen"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd(screenrecord .. " stop"))
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " full"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot .. " area"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("frameit")) -- highlight a region while screen sharing

-- Apps and misc
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd(colorpicker))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd(term))
hl.bind("SUPER + T", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browserP))
hl.bind("SUPER + E", hl.dsp.exec_cmd(files))
hl.bind("SUPER + D", hl.dsp.exec_cmd("killall rofi || rofi -show drun -theme ~/.config/rofi/config.rasi"))
-- copy mode: the default insert mode needs wtype, which is not installed, so Enter only copies
hl.bind(
	"SUPER + period",
	hl.dsp.exec_cmd(
		[[killall rofi || rofi -show emoji -emoji-mode copy -emoji-format "{emoji}" -modi emoji -theme ~/.config/rofi/global/emoji]]
	)
)
-- rofi-calc: live qalc result under the input, Enter copies it and closes. With history on, Enter only
-- saves to history and copying needs a second Enter on the history row, so history is off. rofi-calc
-- does not guard an empty result on this path, hence the test -n (else Enter on nothing clears the clipboard);
-- not `[ ]`, rofi strips square-bracket blocks from commands as optional sections
hl.bind(
	"SUPER + equal",
	hl.dsp.exec_cmd(
		[[killall rofi || rofi -show calc -modi calc -no-show-match -no-sort -terse -no-history -no-persist-history -hint-result "= " -hint-welcome "Enter copies the result" -calc-command "test -n '{result}' && printf %s '{result}' | wl-copy" -theme ~/.config/rofi/global/calc]]
	)
)
-- UI font picker: each candidate drawn in itself; choosing one sets the theme's font.ui and applies it live
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("killall rofi || ~/.config/hypr/scripts/font-picker"))
-- clipboard history (text only): Enter copies, Shift+Delete removes an entry, Ctrl+Shift+Delete wipes it all
hl.bind("SUPER + V", hl.dsp.exec_cmd("killall rofi || " .. scriptsDir .. "/clipboard"))

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
-- force-kill the focused window. Only the Steam client itself (class exactly "steam", games are
-- steam_app_*) gets a clean `steam -shutdown`, since killing it leaves Steam half running
hl.bind("SUPER + SHIFT + Q", function()
	local w = hl.get_active_window()
	if w == nil then
		return
	end
	if w.class == "steam" then
		hl.exec_cmd("steam -shutdown")
	else
		hl.dispatch(hl.dsp.window.kill())
	end
end)
hl.bind("SUPER + SHIFT + Escape", hl.dsp.exit())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + Space", hl.dsp.window.float())
hl.bind("SUPER + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind("SUPER + S", hl.dsp.layout("togglesplit")) -- dwindle

-- Workspace modes
-- workspaceopt is gone in the Lua config manager - toggle every window on the
-- active workspace instead
hl.bind("SUPER + SHIFT + Space", function()
	local ws = hl.get_active_workspace()
	if ws == nil then
		return
	end
	for _, w in ipairs(hl.get_workspace_windows(ws)) do
		-- pcall in case a window expires mid-loop
		pcall(function()
			hl.dispatch(hl.dsp.window.float({ window = w }))
		end)
	end
	hl.exec_cmd(notifycmd .. " 'Toggled All Float Mode'")
end)
hl.bind("SUPER + SHIFT + P", function()
	local ws = hl.get_active_workspace()
	if ws == nil then
		return
	end
	for _, w in ipairs(hl.get_workspace_windows(ws)) do
		pcall(function()
			hl.dispatch(hl.dsp.window.pseudo({ window = w }))
		end)
	end
	hl.exec_cmd(notifycmd .. " 'Toggled All Pseudo Mode'")
end)

-- SUPER+Tab did three things in the old config: cycle focus, raise the window,
-- and (for grouped windows) switch the active group member
hl.bind("SUPER + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
	hl.dispatch(hl.dsp.group.next())
end)

-- Focus
hl.bind("ALT + left", hl.dsp.focus({ direction = "l" }))
hl.bind("ALT + right", hl.dsp.focus({ direction = "r" }))
hl.bind("ALT + up", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + down", hl.dsp.focus({ direction = "d" }))

-- Preselect split direction
hl.bind("SUPER + left", hl.dsp.layout("preselect l"))
hl.bind("SUPER + right", hl.dsp.layout("preselect r"))
hl.bind("SUPER + up", hl.dsp.layout("preselect u"))
hl.bind("SUPER + down", hl.dsp.layout("preselect d"))

-- Switch between monitors
hl.bind("ALT + Tab", hl.dsp.focus({ monitor = "+1" }))

-- Move workspace to monitor
hl.bind("SUPER + SHIFT + comma", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + period", hl.dsp.workspace.move({ monitor = "r" }))

-- Move windows
hl.bind("ALT + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("ALT + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("ALT + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("ALT + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Resize
hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Groups (tabbed)
-- old config bound "g" (togglegroup) and "G" (notify) separately - same key
hl.bind("SUPER + G", function()
	hl.dispatch(hl.dsp.group.toggle())
	hl.exec_cmd(notifycmd .. " 'Toggled Group Mode'")
end)

-- Special workspace
hl.bind("SUPER + A", hl.dsp.workspace.toggle_special())
hl.bind("SUPER + SHIFT + A", hl.dsp.window.move({ workspace = "special" }))
hl.bind("SUPER + C", hl.dsp.window.center())

-- Workspaces: switch with SUPER+[0-9], move window with SUPER+SHIFT+[0-9].
-- Switching always happens on the focused monitor: if the workspace lives on
-- the other monitor it is pulled over first (focusworkspaceoncurrentmonitor)
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind("SUPER + " .. key, function()
		local mon = hl.get_active_monitor()
		local ws = hl.get_workspace(i)
		if mon ~= nil and ws ~= nil and ws.monitor ~= nil and ws.monitor.name ~= mon.name then
			hl.dispatch(hl.dsp.workspace.move({ workspace = i, monitor = mon.name }))
		end
		hl.dispatch(hl.dsp.focus({ workspace = i }))
	end)
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + ALT + up", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + ALT + down", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse bindings
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
