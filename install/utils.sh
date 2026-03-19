#!/usr/bin/env bash
# Shared helpers for install stages

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
success() { printf "${GREEN}[OK]${NC} %s\n" "$*"; }

# Dry-run wrapper: prints command if DRY_RUN=1, otherwise executes
run() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"
    else
        "$@"
    fi
}

# Strip comments and blank lines from a package list file
parse_package_list() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        error "Package list not found: $file"
        return 1
    fi
    sed 's/#.*//; /^[[:space:]]*$/d' "$file"
}

# Install packages from a .txt list via pacman
install_packages() {
    local file="$1"
    local name
    name="$(basename "$file" .txt)"
    info "Installing ${name} packages..."

    local -a to_install=()
    while IFS= read -r pkg; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done < <(parse_package_list "$file")

    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All ${name} packages already installed"
        return
    fi

    info "Installing ${#to_install[@]} packages: ${to_install[*]}"
    run sudo pacman -S --needed --noconfirm "${to_install[@]}"
}

# Install AUR packages via paru/yay
install_aur_packages() {
    local file="$1"
    local name
    name="$(basename "$file" .txt)"
    info "Installing ${name} (AUR) packages..."

    if [[ -z "${AUR_HELPER:-}" ]]; then
        error "No AUR helper available"
        return 1
    fi

    local -a to_install=()
    while IFS= read -r pkg; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done < <(parse_package_list "$file")

    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All ${name} AUR packages already installed"
        return
    fi

    info "Installing ${#to_install[@]} AUR packages: ${to_install[*]}"
    run "$AUR_HELPER" -S --needed --noconfirm "${to_install[@]}"
}
