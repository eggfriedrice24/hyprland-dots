#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=0
MACHINE=""

usage() {
    echo "Usage: $0 [--dry-run] [--laptop|--desktop] [--help]"
    echo "  --dry-run   Print actions without executing"
    echo "  --laptop    Force laptop mode"
    echo "  --desktop   Force desktop mode"
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --laptop)  MACHINE="laptop" ;;
        --desktop) MACHINE="desktop" ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $arg"; usage ;;
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

export DOTFILES_DIR DRY_RUN MACHINE

source "${DOTFILES_DIR}/install/utils.sh"

trap 'error "Installation failed at stage — check output above"' ERR

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
    source "$stage"
done
