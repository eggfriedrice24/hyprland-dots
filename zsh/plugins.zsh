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

# The completion dump lives in the cache, not in ZDOTDIR (that is this repo)
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${_zcompdump:h} ]] || mkdir -p "${_zcompdump:h}"
autoload -Uz compinit

# Without zinit (offline first start, failed clone) keep a working shell: completion
# only, no plugins. The next shell retries the clone.
if [[ ! -r ${ZINIT_HOME}/zinit.git/zinit.zsh ]]; then
  compinit -d "$_zcompdump"
  unset _zcompdump
  return 0
fi

# zinit's own compinit calls (creinstall on plugin updates) use the same dump
typeset -gA ZINIT
ZINIT[ZCOMPDUMP_PATH]=$_zcompdump
source "${ZINIT_HOME}/zinit.git/zinit.zsh"

# Completions
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

compinit -d "$_zcompdump"
unset _zcompdump

# Plugins (fzf-tab first: it must load after compinit but before the plugins
# that wrap widgets, fast-syntax-highlighting and zsh-autosuggestions)
zinit light-mode for \
  Aloxaf/fzf-tab \
  hlissner/zsh-autopair \
  zdharma-continuum/fast-syntax-highlighting \
  MichaelAquilina/zsh-you-should-use \
  zsh-users/zsh-autosuggestions

zinit ice wait'3' lucid atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down'
zinit light zsh-users/zsh-history-substring-search

zinit ice wait'2' lucid
zinit light zdharma-continuum/history-search-multi-word
