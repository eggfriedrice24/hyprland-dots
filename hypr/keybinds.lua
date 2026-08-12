-- Keybinds

local scriptsDir = "$HOME/.config/hypr/scripts"
local notifycmd  = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low"

local term        = "ghostty"
local volume      = scriptsDir .. "/volumecontrol.sh"
local screenshot  = scriptsDir .. "/screensht"
local colorpicker = scriptsDir .. "/colorpicker"
local files       = "thunar"
local browser     = "zen-browser"
local browserP    = "helium-browser"

-- Volume and brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(volume .. " i"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(volume .. " d"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(volume .. " m"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(scriptsDir .. "/brightnesscontrol.sh i"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/brightnesscontrol.sh d"))

-- Screenshot and recording
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("wf-recorder -f $(xdg-user-dir VIDEOS)/$(date +'%H:%M:%S_%d-%m-%Y.mp4')"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("killall -s SIGINT wf-recorder"))
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " full"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(screenshot .. " area"))

-- Apps and misc
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd(colorpicker))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd(term))
hl.bind("SUPER + T", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browserP))
hl.bind("SUPER + E", hl.dsp.exec_cmd(files))
hl.bind("SUPER + D", hl.dsp.exec_cmd("killall rofi || rofi -show drun -theme ~/.config/rofi/config.rasi"))
hl.bind("SUPER + period", hl.dsp.exec_cmd([[killall rofi || rofi -show emoji -emoji-format "{emoji}" -modi emoji -theme ~/.config/rofi/global/emoji]]))
-- "WB" is not a valid key name, these binds never triggered in the old config either
-- hl.bind("SUPER + SHIFT + WB", hl.dsp.exec_cmd("killall -SIGUSR2 waybar")) -- Reload waybar
-- hl.bind("SUPER + WB", hl.dsp.exec_cmd("killall -SIGUSR1 waybar")) -- Hide waybar

-- Window management
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd([[sh -c 'info=$(hyprctl activewindow -j); if echo "$info" | jq -r ".class" | grep -qi steam; then steam -shutdown; else kill -9 $(echo "$info" | jq ".pid"); fi']]))
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
  if ws == nil then return end
  for _, w in ipairs(hl.get_workspace_windows(ws)) do
    -- pcall in case a window expires mid-loop
    pcall(function() hl.dispatch(hl.dsp.window.float({ window = w })) end)
  end
  hl.exec_cmd(notifycmd .. " 'Toggled All Float Mode'")
end)
hl.bind("SUPER + SHIFT + P", function()
  local ws = hl.get_active_workspace()
  if ws == nil then return end
  for _, w in ipairs(hl.get_workspace_windows(ws)) do
    pcall(function() hl.dispatch(hl.dsp.window.pseudo({ window = w })) end)
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

-- Toggle HP monitor orientation (physical pivot: landscape <-> portrait)
hl.bind("SUPER + O", function()
  local m = hl.get_monitor("HDMI-A-1")
  if m == nil then return end
  if m.transform == 0 then
    hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "-1440x-560", scale = 1, transform = 1 })
    hl.exec_cmd(notifycmd .. " 'HP: portrait'")
  else
    hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@60", position = "-2560x0", scale = 1, transform = 0 })
    hl.exec_cmd(notifycmd .. " 'HP: landscape'")
  end
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
