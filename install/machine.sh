#!/usr/bin/env bash
# Machine identity -> profile name. Sourced by install.sh (needs DOTFILES_DIR); hypr/machine.lua
# resolves the same way from the same machines/index, so the installer and Hyprland agree.
#   1. --profile NAME (install.sh), which also writes the pin
#   2. pin: ~/.config/dotfiles/profile
#   3. DMI strings against machines/index
#   4. a BAT* battery means "laptop", anything else is "generic"
# A profile may extend another one (machines/<name>/extends names it): thinkpad and framework build
# on the shared laptop layer, whose packages, /etc files and Hyprland values apply first.

MACHINES_DIR="${DOTFILES_DIR}/machines"
PROFILE_PIN="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile"
# overridable so a fake tree can stand in for another machine in tests
DMI_DIR="${DMI_DIR:-/sys/class/dmi/id}"
PS_DIR="${PS_DIR:-/sys/class/power_supply}"

# first line of a DMI field, surrounding whitespace removed (some vendors pad the strings)
dmi_field() {
    local value=""
    if [[ -r "$DMI_DIR/$1" ]]; then
        IFS= read -r value < "$DMI_DIR/$1" || true
    fi
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

# literal compare; a trailing * turns the pattern into a prefix match, an empty pattern matches anything
field_matches() {
    local value="$1" pattern="$2"
    if [[ -z "$pattern" ]]; then
        return 0
    elif [[ "$pattern" == *'*' ]]; then
        [[ "$value" == "${pattern%\*}"* ]]
    else
        [[ "$value" == "$pattern" ]]
    fi
}

has_battery() { compgen -G "$PS_DIR/BAT*" >/dev/null; }
profile_exists() { [[ -n "$1" && "$1" != */* && -f "$MACHINES_DIR/$1/hypr.lua" ]]; }
list_profiles() {
    local f
    for f in "$MACHINES_DIR"/*/hypr.lua; do
        [[ -f "$f" ]] && basename "$(dirname "$f")"
    done
}

# profile_layers NAME: the profile and the ones it extends, one per line, base first
profile_layers() {
    local name="$1" base depth=0
    local -a layers=()
    while [[ -n "$name" ]] && (( depth < 4 )); do
        layers=("$name" "${layers[@]}")
        base=""
        if [[ -r "$MACHINES_DIR/$name/extends" ]]; then
            IFS= read -r base < "$MACHINES_DIR/$name/extends" || true
            base="${base//[[:space:]]/}"
        fi
        name="$base"
        depth=$((depth + 1))
    done
    printf '%s\n' "${layers[@]}"
}

# Prints "<profile> <source>". source: flag, pinned, dmi, battery, fallback.
# $1 is the --profile value: empty, a profile name, or "auto" (ignore the pin).
detect_profile() {
    local forced="${1:-}" name v p ver fam
    if [[ -n "$forced" && "$forced" != auto ]]; then
        echo "$forced flag"
        return 0
    fi
    if [[ "$forced" != auto && -s "$PROFILE_PIN" ]]; then
        IFS= read -r name < "$PROFILE_PIN" || true
        name="${name//[[:space:]]/}"
        if [[ -n "$name" ]]; then
            echo "$name pinned"
            return 0
        fi
    fi
    local vendor product version family
    vendor="$(dmi_field sys_vendor)"
    product="$(dmi_field product_name)"
    version="$(dmi_field product_version)"
    family="$(dmi_field product_family)"
    if [[ -r "$MACHINES_DIR/index" ]]; then
        while IFS='|' read -r name v p ver fam; do
            [[ -z "$name" || "$name" == \#* ]] && continue
            if field_matches "$vendor" "$v" && field_matches "$product" "$p" &&
                field_matches "$version" "$ver" && field_matches "$family" "$fam"; then
                echo "$name dmi"
                return 0
            fi
        done < "$MACHINES_DIR/index"
    fi
    if has_battery; then
        echo "laptop battery"
    else
        echo "generic fallback"
    fi
}
