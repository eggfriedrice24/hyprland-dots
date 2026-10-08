##
## efr: the agent harness from ~/p/eggfriedrice.code
##

# `, <prompt>` sends one line to the efr daemon; a lone `,` or Ctrl+Space toggles
# sticky agent mode. Sourced before plugins.zsh, so fast-syntax-highlighting and
# zsh-autosuggestions wrap the efr widgets as well. Skipped until `just install` puts
# efr on PATH, so a fresh machine prints nothing. The daemon's hidden shells read this
# file too; the plugin returns early there on its own.
_efr_plugin="$HOME/p/eggfriedrice.code/shell/zsh/efr.plugin.zsh"
if [[ -r $_efr_plugin ]] && (( $+commands[efr] )); then
  source "$_efr_plugin"
fi
unset _efr_plugin

# vim:ft=zsh
