##
## PATH & ENV Var
##

# PATH, XDG dirs and default apps are shared with the graphical session
source "$ZDOTDIR/session.zsh"

export GPG_TTY="${TTY:-$(tty)}"

# SSH Agent (keychain reuses existing agent across terminals; the key is restored by hand, see README)
if command -v keychain >/dev/null; then
  eval "$(keychain --eval --quiet --noask efr)"
fi

# FNM (Fast Node Manager) - auto-switch Node versions from .nvmrc. Versions live in
# ~/.local/share/fnm; session.zsh puts the binary and the default Node on PATH.
if command -v fnm >/dev/null; then
  # a nested shell inherits its parent's per-shell dir; drop it so only this shell's is on PATH
  path=(${path:#*/fnm_multishells/*})
  eval "$(fnm env --use-on-cd)"
fi

export SUDO_PROMPT="passwd: "

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

# vim:ft=zsh:nowrap
