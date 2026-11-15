## Modular Zsh config: one module per concern, sourced in this order

for file in theme env aliases options efr plugins keybinds prompt; do
  source "$ZDOTDIR/$file.zsh"
done
unset file
