##
## Options
##

# History, persisted under XDG state (the installer creates the directory, this covers manual setups)
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # timestamps and durations
setopt INC_APPEND_HISTORY     # write as commands run, not at exit
setopt SHARE_HISTORY          # visible across open shells
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# vim:ft=zsh
