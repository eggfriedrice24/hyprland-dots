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

# prepend sudo on the current commmand
bindkey -M emacs '' _sudo_command_line

# plain backspace (zsh-autopair rebinds it to also delete the closing pair) and
# Ctrl+U kills to the start of the line instead of the whole line
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^U" backward-kill-line

# vim:ft=zsh:nowrap
