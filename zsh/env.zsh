##
## PATH & ENV Var
##

# PATH, XDG dirs and default apps are shared with the graphical session
source "$ZDOTDIR/session.zsh"

export GPG_TTY="${TTY:-$(tty)}"

# SSH Agent (keychain reuses existing agent across terminals; the key is restored by hand, see README).
# keychain is a Python script (~60 ms a shell): source the agent file it wrote and only run it when
# that agent is gone. The glob avoids naming the host; ~/.keychain is never synced between machines.
if command -v keychain >/dev/null; then
  _kc=(~/.keychain/*-sh(N[1]))
  [[ -n $_kc ]] && source $_kc >/dev/null
  if [[ ! -S $SSH_AUTH_SOCK ]] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    eval "$(keychain --eval --quiet --noask efr)"
  fi
  unset _kc
fi

# FNM (Fast Node Manager) - auto-switch Node versions from .nvmrc. Versions live in
# ~/.local/share/fnm; session.zsh puts the binary and the default Node on PATH.
if command -v fnm >/dev/null; then
  # a nested shell inherits its parent's per-shell dir; drop it so only this shell's is on PATH
  path=(${path:#*/fnm_multishells/*})
  eval "$(fnm env --use-on-cd --shell zsh)" # --shell: no ps scan to guess it (~25 ms a shell)
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
