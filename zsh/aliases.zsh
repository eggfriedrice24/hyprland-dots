# Main
# -a: a pacman.log that lived through a power cut holds a NUL byte, and grep would only say
# "binary file matches"
alias installed="grep -ai installed /var/log/pacman.log"
# up: dots-update (bin/, linked into ~/.local/bin by install stage 3); until that link exists,
# the copy in the checkout this zsh config lives in
if (( $+commands[dots-update] )); then
  alias up='dots-update'
elif [[ -x ${ZDOTDIR:A:h}/bin/dots-update ]]; then
  alias up="${ZDOTDIR:A:h}/bin/dots-update"
else
  alias up="sudo pacman -Syu && yay -Sua"
fi
alias ls="eza --color=auto --icons=auto"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"
alias cat="bat --plain --paging=never"
alias grep='grep --color=auto'
alias mv='mv -v'
# verbose; rm asks once before removing more than three files or recursing, and
# directories need an explicit -r for both
alias cp='cp -v'
alias rm='rm -vI'

alias c="clear"
alias q="exit"

# Git aliases
alias g='git'
alias gcl='git clone'
alias gp='git push'
alias gcm='git commit -m'

# Editor
alias v='nvim'

# Claude Code account switching
# claude / claudep -> personal account (~/.claude, current login)
# claudew          -> work account (~/.claude-work, separate login)
claudep() { CLAUDE_CONFIG_DIR="$HOME/.claude" command claude "$@" }
claudew() { CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@" }

# Socket Firewall (work projects) - w-suffixed so personal installs stay untouched
if command -v sfw >/dev/null 2>&1; then
  alias npmw="sfw npm"
  alias npxw="sfw npx"
  alias yarnw="sfw yarn"
  alias pnpmw="sfw pnpm"
  alias bunw="sfw bun"
  alias gow="sfw go"
  alias cargow="sfw cargo"
fi
