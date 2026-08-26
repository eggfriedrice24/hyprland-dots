-- Autostart

-- hl.exec_cmd spawns async processes, no need for "& disown"
hl.on("hyprland.start", function()
  hl.exec_cmd("~/.config/hypr/scripts/resetxdgportal.sh") -- reset XDPH for screenshare
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- for XDPH
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- for XDPH
  hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1") -- authentication dialogue for GUI apps
  hl.exec_cmd("systemctl --user restart pipewire") -- Restart pipewire to avoid bugs
  hl.exec_cmd("dunst") -- start notification demon
  hl.exec_cmd("wl-paste --type text --watch cliphist store") -- clipboard store text data
  hl.exec_cmd("wl-paste --type image --watch cliphist store") -- clipboard store image data
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("sleep 1 && awww img ~/.wallpapers/wp.jpg --transition-type none")
  hl.exec_cmd("sleep 2 && waybar >> ~/.local/state/waybar.log 2>&1")
  hl.exec_cmd("~/.config/hypr/scripts/battery-watcher.sh") -- laptop battery low notifications (acpi)
  hl.exec_cmd("hypridle")
end)
