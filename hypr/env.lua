-- Default env vars.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- wayland first, X11 (XWayland) as the fallback for toolkits that cannot do wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Qt dialogs (polkit, qBittorrent, OBS) follow the GTK theme and fonts through the gtk3 platform
-- theme plugin that qt5-base and qt6-base ship, no extra package or per-app config
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
