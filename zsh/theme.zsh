##
## Theme
##
# Shell colors come from the generated eggfriedrice theme: autosuggestion ghost
# text and zsh-syntax-highlighting styles. fast-syntax-highlighting is themed
# separately with `fast-theme` (see install/stages/04-shell.sh) and fzf, bat,
# eza and lazygit are wired in env.zsh.
# The theme repo is cloned by install/stages/02-theme.sh.
export EGGFRIEDRICE_EXTRAS="$HOME/p/eggfriedrice.nvim/extras"

if [[ -r "$EGGFRIEDRICE_EXTRAS/zsh/eggfriedrice.zsh" ]]; then
  source "$EGGFRIEDRICE_EXTRAS/zsh/eggfriedrice.zsh"
fi
