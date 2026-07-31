-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

-- Layer Effects
hl.layer_rule({ match = { namespace = "^(rofi)$" }, blur = true, ignore_alpha = 0.20 })

-- Opacity
hl.window_rule({ match = { class = "^(Brave-browser)$" }, opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(steam)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(Spotify)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(Code)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(thunar)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(file-roller)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(nwg-look)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt5ct)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(discord)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(WebCord)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, opacity = "0.80 0.80" })

-- Position
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { title = "^(Media viewer)$" }, float = true })
hl.window_rule({ match = { title = "^(Volume Control)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(Viewnior)$" }, float = true })
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

hl.window_rule({ match = { title = "^(Volume Control)$" }, move = { 75, "monitor_h*0.44" } }) -- was: move 75 44%

hl.window_rule({ match = { class = "^(steam)$" }, center = true })
hl.window_rule({ match = { class = "^(discord)$" }, center = true })

-- Workspace
hl.window_rule({ match = { class = "^(zen)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(Brave-browser)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(slack)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(discord)$" }, workspace = "6" })
hl.window_rule({ match = { class = "^(signal)$" }, workspace = "7" })
hl.window_rule({ match = { class = "^(tally-desktop)$" }, workspace = "8" })
hl.window_rule({ match = { class = "^(com.stremio.stremio)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "10" })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, workspace = "8" })
hl.window_rule({ match = { class = "^(steam_app_.*)$" }, fullscreen = true })

-- Size
hl.window_rule({ match = { class = "^(download)$" }, size = { 800, 600 } })
hl.window_rule({ match = { title = "^(Open File)$" }, size = { 800, 600 } })
hl.window_rule({ match = { title = "^(Save File)$" }, size = { 800, 600 } })
hl.window_rule({ match = { title = "^(Volume Control)$" }, size = { 800, 600 } })

-- idleinhibit handled by hypridle (the Lua API has an idle_inhibit effect again if ever needed)
-- hl.window_rule({ match = { class = "^(mpv)$" }, idle_inhibit = "focus" })
-- hl.window_rule({ match = { class = "^(Brave-browser)$" }, idle_inhibit = "fullscreen" })

-- xwaylandvideobridge
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, opacity = "0.0 override 0.0 override" })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_anim = true })
-- no_focus / no_initial_focus exist in the Lua API (they were disabled in the old
-- config while the 0.53 syntax was unclear) - uncomment to enable
-- hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_focus = true })
-- hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_initial_focus = true })
