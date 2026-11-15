#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
ASSUME_YES=0
PROFILE_FLAG=""
PRINT_PROFILE=0
CURRENT_STAGE="preflight"
INSTALL_ARGS="$*" # for the log header; the parser below consumes the arguments

usage() {
    echo "Usage: $0 [--dry-run] [--yes] [--profile NAME|auto] [--print-profile] [--help]"
    echo "  --dry-run         Print actions without executing"
    echo "  --yes             Do not ask for confirmation (used by bootstrap.sh)"
    echo "  --profile NAME    Use machines/NAME and pin it in ~/.config/dotfiles/profile (Hyprland reads it too)"
    echo "  --profile auto    Remove the pin and detect the machine again"
    echo "  --laptop          Same as --profile laptop"
    echo "  --desktop         Same as --profile desktop"
    echo "  --print-profile   Print the resolved profile and how it was found, then exit"
    exit "${1:-0}"
}

while (( $# )); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --profile)
            [[ -n "${2:-}" ]] || { echo "--profile needs a name" >&2; usage 1; }
            PROFILE_FLAG="$2"
            shift
            ;;
        --profile=*) PROFILE_FLAG="${1#--profile=}" ;;
        --laptop)  PROFILE_FLAG="laptop" ;;
        --desktop) PROFILE_FLAG="desktop" ;;
        --print-profile) PRINT_PROFILE=1 ;;
        --help|-h) usage 0 ;;
        *) echo "Unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

# Machine profile (machines/<name>): flag, pin, DMI match, then battery -> laptop, else generic.
# hypr/machine.lua resolves the same way, so Hyprland and the installer agree.
source "${DOTFILES_DIR}/install/machine.sh"
read -r PROFILE PROFILE_SOURCE < <(detect_profile "$PROFILE_FLAG")
if [[ "$PRINT_PROFILE" -eq 1 ]]; then
    echo "$PROFILE $PROFILE_SOURCE"
    exit 0
fi
PROFILE_DIR="${MACHINES_DIR}/${PROFILE}"
mapfile -t PROFILE_LAYERS < <(profile_layers "$PROFILE")

# tools installed by the stages themselves (claude, uv tools) land here
export PATH="$HOME/.local/bin:$PATH"
export DOTFILES_DIR DRY_RUN PROFILE PROFILE_SOURCE PROFILE_DIR

source "${DOTFILES_DIR}/install/utils.sh"

if ! profile_exists "$PROFILE"; then
    error "Unknown machine profile '$PROFILE' (${PROFILE_SOURCE}). Known: $(list_profiles | paste -sd' ')"
    if [[ "$PROFILE_SOURCE" == "pinned" ]]; then
        error "Fix or remove the pin in $PROFILE_PIN, or rerun with --profile auto"
    fi
    exit 1
fi

# Name the file, line and command that failed. A command that failed inside `run` is reported
# at the line that called run, with its arguments (BASH_COMMAND would only say "$@").
# Subshells stay quiet: a failure that matters fails the parent command too and is reported there,
# while one inside a process substitution (`< <(find ...)`) never stops the install.
on_error() {
    if (( BASH_SUBSHELL > 0 )); then
        return 0
    fi
    local status="$1" line="$2" cmd="$3"
    shift 3
    local file="${BASH_SOURCE[1]:-$0}"
    if [[ "${FUNCNAME[1]:-}" == "run" ]]; then
        file="${BASH_SOURCE[2]:-$file}"
        line="${BASH_LINENO[1]:-$line}"
        cmd="$*"
    fi
    error "Installation failed in ${CURRENT_STAGE} (exit ${status}) at ${file#"$DOTFILES_DIR"/}:${line}: ${cmd}"
}
trap 'on_error "$?" "$LINENO" "$BASH_COMMAND" "$@"' ERR

# Prerequisites the script cannot install for itself
if [[ $EUID -eq 0 ]]; then
    error "Run as your normal user, not root; sudo is used where needed."
    exit 1
fi
for tool in sudo git; do
    if ! command -v "$tool" &>/dev/null; then
        error "$tool is required. As root: pacman -S $tool (and add your user to the wheel group for sudo)."
        exit 1
    fi
done

# bootstrap.sh grants passwordless sudo for its chroot run and deletes the file afterwards; a run that
# was killed leaves it behind. /etc/sudoers.d is root-only, and `sudo -n` succeeds only without a
# prompt (a cached ticket, or that very NOPASSWD rule), so this never asks for a password.
# Skipped inside the chroot, where the file is expected, and in a dry run.
bootstrap_sudoers=/etc/sudoers.d/99-bootstrap
if [[ "$DRY_RUN" -eq 0 ]] && ! systemd-detect-virt --chroot &>/dev/null &&
    sudo -n test -e "$bootstrap_sudoers" 2>/dev/null; then
    warn "$bootstrap_sudoers is left over from an interrupted bootstrap.sh and gives $USER passwordless root."
    warn "Remove it: sudo rm $bootstrap_sudoers"
fi

DISPLAY_DIR="${DOTFILES_DIR/#$HOME/\~}"

echo
echo "  ┌─────────────────────────────┐"
echo "  │     dotfiles installer      │"
echo "  ├─────────────────────────────┤"
printf "  │  Profile:  %-16s │\n" "$PROFILE"
printf "  │  Found by: %-16s │\n" "$PROFILE_SOURCE"
printf "  │  Path:     %-16s │\n" "$DISPLAY_DIR"
printf "  │  Dry run:  %-16s │\n" "$( [[ $DRY_RUN -eq 1 ]] && echo 'yes' || echo 'no' )"
echo "  └─────────────────────────────┘"
echo

if [[ "$DRY_RUN" -eq 0 && "$ASSUME_YES" -eq 0 ]]; then
    read -rp "Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
fi

# A real run keeps its own log unless a caller (dots-update) passed one in; a dry run writes nothing
if [[ -z "${LOG_FILE:-}" && "$DRY_RUN" -eq 0 ]]; then
    log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/install"
    if mkdir -p "$log_dir" 2>/dev/null; then
        LOG_FILE="$log_dir/$(date +%Y-%m-%dT%H-%M-%S).log"
    else
        warn "Cannot create $log_dir, this run is not logged"
    fi
fi
if [[ -n "${LOG_FILE:-}" ]]; then
    export LOG_FILE
    _log START "install.sh ${INSTALL_ARGS} | profile ${PROFILE} (${PROFILE_SOURCE}) | dotfiles $(git -C "$DOTFILES_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    [[ "$DRY_RUN" -eq 1 ]] || info "Logging to ${LOG_FILE/#$HOME/\~}"
fi

# A profile given by flag or pin can differ from what the hardware says; show both
if [[ "$PROFILE_SOURCE" == "flag" || "$PROFILE_SOURCE" == "pinned" ]]; then
    read -r detected_profile _ < <(detect_profile auto)
    if [[ "$detected_profile" != "$PROFILE" ]]; then
        info "Using profile ${PROFILE} (${PROFILE_SOURCE}). Detection says ${detected_profile}."
    fi
fi
if (( ${#PROFILE_LAYERS[@]} > 1 )); then
    info "Profile layers, base first: ${PROFILE_LAYERS[*]}"
fi

# --profile NAME pins NAME, so Hyprland (hypr/machine.lua) and later runs use it too; auto unpins
current_pin=""
if [[ -s "$PROFILE_PIN" ]]; then
    IFS= read -r current_pin < "$PROFILE_PIN" || true
    current_pin="${current_pin//[[:space:]]/}"
fi
if [[ "$PROFILE_FLAG" == "auto" ]]; then
    if [[ -e "$PROFILE_PIN" ]]; then
        info "Removing the profile pin ${PROFILE_PIN} (was: ${current_pin:-empty})"
        run rm -f "$PROFILE_PIN"
    fi
elif [[ -n "$PROFILE_FLAG" && "$current_pin" != "$PROFILE" ]]; then
    info "Pinning profile ${PROFILE} in ${PROFILE_PIN}"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        dry "write '${PROFILE}' to ${PROFILE_PIN}"
    else
        mkdir -p "$(dirname "$PROFILE_PIN")"
        printf '%s\n' "$PROFILE" > "$PROFILE_PIN"
    fi
fi

for stage in "${DOTFILES_DIR}"/install/stages/[0-9]*.sh; do
    CURRENT_STAGE="$(basename "$stage" .sh)"
    source "$stage"
done
CURRENT_STAGE="done"
_log END "install.sh finished"
