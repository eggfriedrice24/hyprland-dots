# Session environment first: Hyprland inherits it from this shell (see session.zsh)
source "${ZDOTDIR:-$HOME/.config/zsh}/session.zsh"

# Auto-start Hyprland on TTY1 login, only from a bare TTY. Never inside efr's hidden
# agent shells (they are login shells too, and EFR_HIDDEN_SHELL marks them) and never
# from a login shell started inside a running X11 or Wayland session.
if [[ -z $EFR_HIDDEN_SHELL && -z $DISPLAY && -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 ]]; then
  # user units (portals, polkit agent, services) and D-Bus activated apps get the same
  # PATH, XDG dirs and default apps as the compositor
  systemctl --user import-environment "${session_env[@]}"
  dbus-update-activation-environment --systemd "${session_env[@]}"
  exec start-hyprland
fi
