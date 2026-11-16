-- Autostart

-- start a watcher script from hypr/scripts unless one already runs (a restarted session would
-- otherwise stack a second copy). The pattern is anchored on the interpreter ("sh /path/x.sh")
-- so the sh -c wrapper of this very command, which also contains the path, never matches it
local function start_watcher(script)
	local pattern = "^(/usr)?(/bin/)?(ba)?sh [^ ]*/hypr/scripts/" .. (script:gsub("%.", "[.]")) .. "( |$)"
	hl.exec_cmd("pgrep -f '" .. pattern .. "' >/dev/null || exec ~/.config/hypr/scripts/" .. script)
end

-- hl.exec_cmd spawns async processes, no need for "& disown"
hl.on("hyprland.start", function()
	-- Hyprland 0.57 hands WAYLAND_DISPLAY, XDG_CURRENT_DESKTOP and HYPRLAND_INSTANCE_SIGNATURE to
	-- systemd and D-Bus itself before hyprland-session.target, so the portals need no import here.
	-- pipewire is socket-activated (pipewire.socket); a restart here was its first start at login
	-- and dropped every audio stream on a relogin.
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1") -- authentication dialogue for GUI apps
	hl.exec_cmd("dunst") -- start notification demon
	-- clipboard history for the SUPER+V picker; text only, stored images grew the db past 100 MB
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("awww-daemon")
	-- the wallpaper as soon as the daemon answers (at most 5 s), not after a fixed second
	hl.exec_cmd(
		"timeout 5 sh -c 'until awww query >/dev/null 2>&1; do sleep 0.05; done';"
			.. " awww img ~/.wallpapers/wp.jpg --transition-type none"
	)
	-- one session per log: the previous session's log moves to waybar.log.1 (kept, not truncated,
	-- so a crash from the last session can still be read after a relogin). No delay: the portal
	-- reset that once needed waybar to wait 2 s is gone, and waybar is configured in about 0.1 s
	hl.exec_cmd(
		"mkdir -p ~/.local/state; mv -f ~/.local/state/waybar.log ~/.local/state/waybar.log.1 2>/dev/null;"
			.. " exec waybar >> ~/.local/state/waybar.log 2>&1"
	)
	start_watcher("battery-watcher.sh") -- laptop battery low notifications (sysfs); exits on machines without one
	-- a machine profile can bring its own idle config (machines/<profile>/hypr.lua, field hypridle)
	local ok, machine = pcall(require, "machine")
	local idle_conf = ok and type(machine) == "table" and machine.hypridle
	local idle_file = idle_conf and io.open(idle_conf, "r")
	if idle_file then
		idle_file:close()
		hl.exec_cmd("hypridle -c '" .. idle_conf .. "'")
	else
		hl.exec_cmd("hypridle")
	end
end)
