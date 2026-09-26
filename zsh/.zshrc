## Modular Zsh config: one module per concern, sourced in this order

while read -r file
do
  source "$ZDOTDIR/$file.zsh"
done <<-EOF
theme
env
aliases
options
plugins
keybinds
prompt
