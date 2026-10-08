# Auto-start Hyprland on TTY1 login
# Never inside efr's hidden agent shells: they are login shells too, and EFR_HIDDEN_SHELL
# marks them.
if [ -z "$EFR_HIDDEN_SHELL" ] && [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec start-hyprland
fi
