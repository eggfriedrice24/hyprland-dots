##
## Prompt
##

# starship comes from pacman (install/packages/dev.txt); the config lives in this repo
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# vim:ft=zsh
