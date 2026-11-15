#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
ASSUME_YES=0
PROFILE_FLAG=""
PRINT_PROFILE=0
NO_UPGRADE=0
QUIET=0
SKIP_STAGES=""
CURRENT_STAGE="preflight"
INSTALL_CMDLINE="$*" # for the log header; the parser below consumes the arguments

# stage names for --skip: the file names without their number (01-packages.sh -> packages)
stage_names() {
    local stage name
    for stage in "${DOTFILES_DIR}"/install/stages/[0-9]*.sh; do
        name="$(basename "$stage" .sh)"
        printf '%s\n' "${name#*-}"
    done
}

usage() {
    echo "Usage: $0 [--dry-run] [--yes] [--profile NAME|auto] [--print-profile] [--no-upgrade] [--skip=STAGES] [--quiet] [--help]"
    echo "  --dry-run         Print actions without executing"
    echo "  --yes             Do not ask for confirmation (used by bootstrap.sh)"
    echo "  --profile NAME    Use machines/NAME and pin it in ~/.config/dotfiles/profile (Hyprland reads it too)"
    echo "  --profile auto    Remove the pin and detect the machine again"
    echo "  --laptop          Same as --profile laptop"
    echo "  --desktop         Same as --profile desktop"
    echo "  --print-profile   Print the resolved profile and how it was found, then exit"
    echo "  --no-upgrade      No keyring refresh and full upgrade in stage 1 (dots-update has just done both)"
    echo "  --skip=a,b        Skip these stages: $(stage_names | paste -sd' ')"
    echo "  --quiet           Only print what changes: no banner, no [OK] lines, no closing notes"
    echo "Exit status: 0 done, 1 a stage failed, 3 every stage ran but a migration is still pending"
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
        --no-upgrade) NO_UPGRADE=1 ;;
        --skip=*) SKIP_STAGES="${SKIP_STAGES:+$SKIP_STAGES,}${1#--skip=}" ;;
        --quiet|-q) QUIET=1 ;;
        --help|-h) usage 0 ;;
        *) echo "Unknown option: $1" >&2; usage 1 ;;
    esac
    shift
done

# a misspelt stage name would otherwise run the stage it was meant to skip
if [[ -n "$SKIP_STAGES" ]]; then
    mapfile -t known_stages < <(stage_names)
    IFS=, read -ra skip_list <<<"$SKIP_STAGES"
    for name in "${skip_list[@]}"; do
        if [[ -n "$name" && " ${known_stages[*]} " != *" $name "* ]]; then
            echo "Unknown stage for --skip: $name (stages: ${known_stages[*]})" >&2
            exit 1
        fi
    done
fi

# Machine profile (machines/<name>): flag, pin, DMI match, then battery -> laptop, else generic.
# hypr/machine.lua resolves the same way, so Hyprland and the installer agree.
source "${DOTFILES_DIR}/install/machine.sh"
read -r PROFILE PROFILE_SOURCE < <(detect_profile "$PROFILE_FLAG")
if [[ "$PRINT_PROFILE" -eq 1 ]]; then
    echo "$PROFILE $PROFILE_SOURCE"
    exit 0
fi
mapfile -t PROFILE_LAYERS < <(profile_layers "$PROFILE")

# tools installed by the stages themselves (claude) and the bin/ commands land here
export PATH="$HOME/.local/bin:$PATH"
export DOTFILES_DIR DRY_RUN PROFILE PROFILE_SOURCE NO_UPGRADE QUIET

source "${DOTFILES_DIR}/install/utils.sh"
# shellcheck source=install/migrate.sh
source "${DOTFILES_DIR}/install/migrate.sh"

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
# Skipped inside the chroot, where the file is expected, and in a dry run. bootstrap.sh says so with
# DOTFILES_BOOTSTRAP=1: systemd-detect-virt --chroot needs /proc/1/root, which the user it runs the
# installer as cannot read, so it misses arch-chroot.
bootstrap_sudoers=/etc/sudoers.d/99-bootstrap
if [[ "$DRY_RUN" -eq 0 && "${DOTFILES_BOOTSTRAP:-0}" != 1 ]] && ! systemd-detect-virt --chroot &>/dev/null &&
    sudo -n test -e "$bootstrap_sudoers" 2>/dev/null; then
    warn "$bootstrap_sudoers is left over from an interrupted bootstrap.sh and gives $USER passwordless root."
    warn "Remove it: sudo rm $bootstrap_sudoers"
fi

DISPLAY_DIR="${DOTFILES_DIR/#$HOME/\~}"

if [[ "$QUIET" -eq 0 ]]; then
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
fi

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
    _log START "install.sh ${INSTALL_CMDLINE} | profile ${PROFILE} (${PROFILE_SOURCE}) | dotfiles $(git -C "$DOTFILES_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    [[ "$DRY_RUN" -eq 1 ]] || info "Logging to ${LOG_FILE/#$HOME/\~}"
fi

# A profile given by flag or pin can differ from what the hardware says; show both
if [[ "$PROFILE_SOURCE" == "flag" || "$PROFILE_SOURCE" == "pinned" ]]; then
    read -r detected_profile _ < <(detect_profile auto)
    if [[ "$detected_profile" != "$PROFILE" ]]; then
        info "Using profile ${PROFILE} (${PROFILE_SOURCE}). Detection says ${detected_profile}."
    fi
fi
if (( ${#PROFILE_LAYERS[@]} > 1 && ! QUIET )); then
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

# Before stage 3 links anything: a machine whose ~/.config already links into the dotfiles has
# every migration pending, a new one records them all as baseline (install/migrate.sh)
migrations_init

for stage in "${DOTFILES_DIR}"/install/stages/[0-9]*.sh; do
    CURRENT_STAGE="$(basename "$stage" .sh)"
    if [[ ",$SKIP_STAGES," == *",${CURRENT_STAGE#*-},"* ]]; then
        info "=== Skipping stage ${CURRENT_STAGE#*-} ==="
        continue
    fi
    source "$stage"
done
CURRENT_STAGE="done"
# 3: every stage ran, but a migration failed (or another run held the lock) and is still pending
if [[ -n "$MIGRATION_FAILED" ]]; then
    _log END "install.sh finished, migration ${MIGRATION_FAILED} still pending"
    exit 3
fi
_log END "install.sh finished"
