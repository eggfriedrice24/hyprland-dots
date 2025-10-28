##
## Plugins
##

# Zinit setup
ZINIT_HOME="${ZINIT_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/zinit}"

if [[ ! -f ${ZINIT_HOME}/zinit.git/zinit.zsh ]]; then
  print -P "%F{14}▓▒░ Installing Zinit...%f"
  command mkdir -p "${ZINIT_HOME}" && command chmod g-rwX "${ZINIT_HOME}"
  command git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}/zinit.git" && \
    print -P "%F{10}▓▒░ Zinit install successful.%f" || \
    print -P "%F{9}▓▒░ Zinit clone failed.%f"
fi

source "${ZINIT_HOME}/zinit.git/zinit.zsh"

# # Theme: Powerlevel10k
# zinit light romkatv/powerlevel10k
# [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Completions
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

autoload -Uz compinit && compinit

# Plugins
zinit light-mode for \
  hlissner/zsh-autopair \
  zdharma-continuum/fast-syntax-highlighting \
  MichaelAquilina/zsh-you-should-use \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab

zinit ice wait'3' lucid atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down'
zinit light zsh-users/zsh-history-substring-search



zinit ice wait'2' lucid
zinit light zdharma-continuum/history-search-multi-word

# FZF (binary)
zinit ice from"gh-r" as"command"
zinit light junegunn/fzf-bin

# EXA (ls replacement)
zinit ice wait lucid from"gh-r" as"program" mv"bin/exa* -> exa"
zinit light ogham/exa

# BAT (cat replacement)
zinit ice wait lucid from"gh-r" as"program" mv"*/bat -> bat" atload"export BAT_THEME='Nord'"
zinit light sharkdp/bat
