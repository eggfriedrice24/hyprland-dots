# Main
alias installed="grep -i installed /var/log/pacman.log"
alias ls="exa --color=auto --icons"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"
alias cat="bat --color always --plain"
alias grep='grep --color=auto'
alias mv='mv -v'
alias cp='cp -vr'
alias rm='rm -vr'

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
