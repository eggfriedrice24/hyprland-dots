##
## PATH & ENV Var
##

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.spicetify:$PATH"
export PATH="$PNPM_HOME:$PATH"
export PATH="$HOME/.scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export GPG_TTY="${TTY:-$(tty)}"

# SSH Agent (keychain reuses existing agent across terminals)
eval "$(keychain --eval --quiet --noask efr)"

# FNM (Fast Node Manager) - Auto-switch Node versions based on .nvmrc
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

export SUDO_PROMPT="passwd: "
export TERMINAL="ghostty"
export BROWSER="firefox"
export VISUAL="nvim"
export EDITOR="nvim"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_DIRS="/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$XDG_DATA_HOME/flatpak/exports/share"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_DESKTOP_DIR="$HOME/Desktop"
export XDG_DOWNLOAD_DIR="$HOME/Downloads"
export XDG_TEMPLATES_DIR="$HOME/Templates"
export XDG_PUBLICSHARE_DIR="$HOME/Public"
export XDG_DOCUMENTS_DIR="$HOME/Documents"
export XDG_MUSIC_DIR="$HOME/Music"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_VIDEOS_DIR="$HOME/Videos"

## Comment this to use normal manpager
export MANPAGER='nvim +Man! +"set nocul" +"set noshowcmd" +"set noruler" +"set noshowmode" +"set laststatus=0" +"set showtabline=0" +"set nonumber"'

if [ $(echo $MANPAGER | awk '{print $1}') = nvim ]; then
  export LESS="--RAW-CONTROL-CHARS"
  export MANPAGER="less -s -M +Gg"

  export LESS_TERMCAP_mb=$'\e[1;32m'
  export LESS_TERMCAP_md=$'\e[1;32m'
  export LESS_TERMCAP_me=$'\e[0m'
  export LESS_TERMCAP_se=$'\e[0m'
  export LESS_TERMCAP_so=$'\e[01;33m'
  export LESS_TERMCAP_ue=$'\e[0m'
  export LESS_TERMCAP_us=$'\e[1;4;31m'
fi

# FZF bases
export FZF_DEFAULT_OPTS="
  --prompt ' '
  --pointer ' λ'
  --layout=reverse
  --border horizontal
  --height 40"
# colors are appended by the generated theme (needs fzf >= 0.36)
source /home/eggfriedrice/p/eggfriedrice.nvim/extras/fzf/eggfriedrice.sh

# eza: picks up ~/.config/eza/theme.yml only while LS_COLORS and EZA_COLORS stay unset

# lazygit: user config first, generated theme layered on top
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,/home/eggfriedrice/p/eggfriedrice.nvim/extras/lazygit/eggfriedrice.yml"

# vim:ft=zsh:nowrap

# T-Mesh CLI
export PATH="$HOME/uni/t-mesh/bin:$PATH"
