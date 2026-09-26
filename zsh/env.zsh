##
## PATH & ENV Var
##

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
export PATH="$HOME/.local/bin:$PATH"
# toolchain bins that only exist once the tool has been used
for _dir in "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/uni/t-mesh/bin"; do
  [[ -d "$_dir" ]] && export PATH="$_dir:$PATH"
done
unset _dir
export GPG_TTY="${TTY:-$(tty)}"

# SSH Agent (keychain reuses existing agent across terminals; the key is restored by hand, see README)
if command -v keychain >/dev/null; then
  eval "$(keychain --eval --quiet --noask efr)"
fi

# FNM (Fast Node Manager) - auto-switch Node versions from .nvmrc. Versions live in
# ~/.local/share/fnm; the same dir holds the binary when fnm came from its curl installer.
[[ -d "$HOME/.local/share/fnm" ]] && export PATH="$HOME/.local/share/fnm:$PATH"
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
fi

export SUDO_PROMPT="passwd: "
export TERMINAL="ghostty"
export BROWSER="zen-browser"
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

# man pages: less with coloured bold and underline (man-db comes from install/packages/base.txt)
export MANPAGER="less -s -M +Gg"
export LESS="--RAW-CONTROL-CHARS"
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# FZF bases
export FZF_DEFAULT_OPTS="
  --prompt ' '
  --pointer ' λ'
  --layout=reverse
  --border horizontal
  --height 40"
# colors are appended by the generated theme (needs fzf >= 0.36); EGGFRIEDRICE_EXTRAS is set in theme.zsh
if [[ -r "$EGGFRIEDRICE_EXTRAS/fzf/eggfriedrice.sh" ]]; then
  source "$EGGFRIEDRICE_EXTRAS/fzf/eggfriedrice.sh"
fi

# eza: picks up ~/.config/eza/theme.yml only while LS_COLORS and EZA_COLORS stay unset

# lazygit: user config first, generated theme layered on top
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$EGGFRIEDRICE_EXTRAS/lazygit/eggfriedrice.yml"

# vim:ft=zsh:nowrap
