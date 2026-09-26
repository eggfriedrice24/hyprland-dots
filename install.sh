#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
MACHINE=""
CURRENT_STAGE="preflight"

usage() {
    echo "Usage: $0 [--dry-run] [--laptop|--desktop] [--help]"
    echo "  --dry-run   Print actions without executing"
    echo "  --laptop    Force laptop mode"
    echo "  --desktop   Force desktop mode"
    exit "${1:-0}"
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --laptop)  MACHINE="laptop" ;;
        --desktop) MACHINE="desktop" ;;
        --help|-h) usage 0 ;;
        *) echo "Unknown option: $arg" >&2; usage 1 ;;
    esac
done

# Auto-detect machine type
if [[ -z "$MACHINE" ]]; then
    if ls /sys/class/power_supply/BAT* &>/dev/null; then
        MACHINE="laptop"
    else
        MACHINE="desktop"
    fi
fi

# tools installed by the stages themselves (claude, uv tools) land here
export PATH="$HOME/.local/bin:$PATH"
export DOTFILES_DIR DRY_RUN MACHINE

source "${DOTFILES_DIR}/install/utils.sh"

trap 'error "Installation failed in ${CURRENT_STAGE}. Check the output above."' ERR

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

DISPLAY_DIR="${DOTFILES_DIR/#$HOME/\~}"

echo
echo "  ┌─────────────────────────────┐"
echo "  │     dotfiles installer      │"
echo "  ├─────────────────────────────┤"
printf "  │  Machine:  %-16s │\n" "$MACHINE"
printf "  │  Path:     %-16s │\n" "$DISPLAY_DIR"
printf "  │  Dry run:  %-16s │\n" "$( [[ $DRY_RUN -eq 1 ]] && echo 'yes' || echo 'no' )"
echo "  └─────────────────────────────┘"
echo

if [[ "$DRY_RUN" -eq 0 ]]; then
    read -rp "Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
fi

for stage in "${DOTFILES_DIR}"/install/stages/[0-9]*.sh; do
    CURRENT_STAGE="$(basename "$stage" .sh)"
    source "$stage"
done
CURRENT_STAGE="done"
