##
## Session environment
##
# Sourced by .zprofile before Hyprland is exec'd, so the compositor, rofi, waybar,
# exec_once commands and, through the import in .zprofile, systemd user units see the
# same PATH, XDG dirs and default apps as a terminal. env.zsh sources it again in every
# interactive shell.

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_DATA_DIRS="/usr/local/share:/usr/share:/var/lib/flatpak/exports/share:$XDG_DATA_HOME/flatpak/exports/share"
# pam_systemd sets this at login; the fallback covers shells started some other way
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
export XDG_DESKTOP_DIR="$HOME/Desktop"
export XDG_DOWNLOAD_DIR="$HOME/Downloads"
export XDG_TEMPLATES_DIR="$HOME/Templates"
export XDG_PUBLICSHARE_DIR="$HOME/Public"
export XDG_DOCUMENTS_DIR="$HOME/Documents"
export XDG_MUSIC_DIR="$HOME/Music"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_VIDEOS_DIR="$HOME/Videos"

# Each dir once, however often this runs: nested shells source it again and the first
# (newest) entry wins
typeset -U path PATH
# No pnpm lines: /etc/profile.d/pnpm.sh (pnpm 11 and later) sets PNPM_HOME and appends
# $PNPM_HOME/bin, where global commands live now
path=(~/.local/bin $path)
# toolchain bins that only exist once the tool has been used
path=(~/go/bin(N/) ~/.cargo/bin(N/) $path)

# fnm: the binary when it came from its curl installer (pacman's lives in /usr/bin), then
# the default Node, so anything started outside a shell (launchers, user units) finds node
# and npm. Interactive shells put fnm's per-shell dir in front of this in env.zsh.
[[ -x $XDG_DATA_HOME/fnm/fnm ]] && path=($XDG_DATA_HOME/fnm $path)
path=($XDG_DATA_HOME/fnm/aliases/default/bin(N/) $path)

export TERMINAL="ghostty"
export BROWSER="zen-browser"
export VISUAL="nvim"
export EDITOR="nvim"

# Names .zprofile hands to systemd and D-Bus activation before it starts Hyprland
session_env=(
  PATH
  XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CONFIG_DIRS XDG_DATA_DIRS
  EDITOR VISUAL TERMINAL BROWSER
)

# Machine-only additions (project bin dirs and the like) go in zsh/local.zsh, which git
# ignores. It is sourced here, so the graphical session gets them too; keep it safe to
# run twice, for example `path=(~/uni/t-mesh/bin(N/) $path)`.
if [[ -r ${ZDOTDIR:-$HOME/.config/zsh}/local.zsh ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/local.zsh"
fi

# vim:ft=zsh:nowrap
