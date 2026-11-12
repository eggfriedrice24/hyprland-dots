##
## Prompt
##

# starship comes from pacman (install/packages/dev.txt); the config lives in this repo
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# efr's corner at the right edge of the prompt: the scope and the permission mode, such
# as `app · auto`. It must run after the prompt theme. The guard keeps a shell quiet
# when the plugin is older or not loaded.
(( $+functions[efr_corner] )) && efr_corner

# vim:ft=zsh
