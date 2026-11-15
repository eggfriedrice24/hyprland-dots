##
## Keybindings
##

# Function to prepend sudo to current command
_sudo_command_line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N _sudo_command_line

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey -s '^K' 'ls^M'

# Ctrl+B prepends sudo to the current command (or the previous one on an empty line)
bindkey -M emacs '^B' _sudo_command_line

# plain backspace (zsh-autopair rebinds it to also delete the closing pair) and
# Ctrl+U kills to the start of the line instead of the whole line
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^U" backward-kill-line

# vim:ft=zsh:nowrap
