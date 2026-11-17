-- Window and layer rules

-- Layer effects
-- no_anim: hyprland animates layer size changes by scaling the old buffer, which stretches rofi every time the result count changes
hl.layer_rule({ match = { namespace = "^(rofi)$" }, blur = true, ignore_alpha = 0.20, no_anim = true })
-- the bar is simply there at login, without the layer slide and fade; glass like rofi (its
-- background is @panel, the shared glass opacity, so the blur shows through)
hl.layer_rule({ match = { namespace = "^(waybar)$" }, blur = true, ignore_alpha = 0.20, no_anim = true })
-- slurp's selection overlay: no fade-out, or area screenshots and recordings catch it dimming
-- (grimblast asks for this with `hyprctl keyword`, which the Lua config manager rejects)
hl.layer_rule({ match = { namespace = "^(selection)$" }, no_anim = true })
-- notifications (dunst, the volume and brightness OSD too) slide in from the right edge, glass
-- like rofi: their background is the shared glass opacity from the theme's dunst extra
hl.layer_rule({
	match = { namespace = "^(notifications)$" },
	animation = "slide right",
	blur = true,
	ignore_alpha = 0.20,
})

-- Opacity
-- only apps from install/packages (and the tally build); rules for apps no list installs were pruned
hl.window_rule({ match = { class = "^(steam)$" }, opacity = "0.80 0.80" })
-- thunar: translucent through gtk-3.0/thunar.css instead, so text and icons stay opaque
hl.window_rule({ match = { class = "^(discord)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(slack)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, opacity = "0.80 0.70" })

-- Position
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { title = "^(DevTools)$" }, float = true })
hl.window_rule({ match = { class = "^(file_progress)$" }, float = true })
hl.window_rule({ match = { class = "^(confirm)$" }, float = true })
hl.window_rule({ match = { class = "^(dialog)$" }, float = true })
hl.window_rule({ match = { class = "^(download)$" }, float = true })
hl.window_rule({ match = { class = "^(notification)$" }, float = true })
hl.window_rule({ match = { class = "^(error)$" }, float = true })
hl.window_rule({ match = { class = "^(confirmreset)$" }, float = true })
hl.window_rule({ match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ match = { title = "^(branchdialog)$" }, float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Operation Progress)$" }, float = true })

hl.window_rule({ match = { class = "^(steam)$" }, center = true })
hl.window_rule({ match = { class = "^(discord)$" }, center = true })

-- Workspace
hl.window_rule({ match = { class = "^(zen)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(slack)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(signal)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^(tally-desktop)$" }, workspace = "8" })
-- the flatpak's app id is com.stremio.Stremio and its desktop file names the class stremio; the old
-- all-lowercase com.stremio.stremio matched neither
hl.window_rule({ match = { class = "^(com.stremio.Stremio|stremio)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "10" })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, workspace = "8" })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, fullscreen = true })

-- Size
hl.window_rule({ match = { class = "^(download)$" }, size = { 800, 600 } })
hl.window_rule({ match = { title = "^(Open File)$" }, size = { 800, 600 } })
hl.window_rule({ match = { title = "^(Save File)$" }, size = { 800, 600 } })

-- idleinhibit handled by hypridle (the Lua API has an idle_inhibit effect again if ever needed)
-- hl.window_rule({ match = { class = "^(mpv)$" }, idle_inhibit = "focus" })
