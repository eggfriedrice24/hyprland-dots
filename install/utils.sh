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
dry() { printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"; }

# Dry-run wrapper: prints the command if DRY_RUN=1, otherwise executes it.
# Pipelines cannot be passed directly; wrap them as: run bash -c '... | ...'
run() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "$*"
    else
        "$@"
    fi
}

has_pkg() { pacman -Qq "$1" &>/dev/null; }

# Strip comments, blank lines and surrounding whitespace from a package list file
parse_package_list() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        error "Package list not found: $file"
        return 1
    fi
    sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$file"
}

# Install the given official-repo packages that are not installed yet
install_package_names() {
    local name="$1"
    shift
    local -a to_install=()
    local pkg
    for pkg in "$@"; do
        has_pkg "$pkg" || to_install+=("$pkg")
    done

    if (( ${#to_install[@]} == 0 )); then
        success "All ${name} packages already installed"
        return 0
    fi

    info "Installing ${#to_install[@]} ${name} packages: ${to_install[*]}"
    run sudo pacman -S --needed --noconfirm "${to_install[@]}"
}

# Install packages from a .txt list via pacman
install_packages() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        error "Package list not found: $file"
        return 1
    fi
    local -a pkgs
    mapfile -t pkgs < <(parse_package_list "$file")
    info "Installing $(basename "$file" .txt) packages..."
    install_package_names "$(basename "$file" .txt)" "${pkgs[@]}"
}

# Install AUR packages from a .txt list via $AUR_HELPER
install_aur_packages() {
    local file="$1"
    local name
    name="$(basename "$file" .txt)"
    if [[ ! -f "$file" ]]; then
        error "Package list not found: $file"
        return 1
    fi

    if [[ -z "${AUR_HELPER:-}" ]]; then
        error "No AUR helper available"
        return 1
    fi

    local -a pkgs to_install=()
    mapfile -t pkgs < <(parse_package_list "$file")
    info "Installing ${name} (AUR) packages..."
    local pkg
    for pkg in "${pkgs[@]}"; do
        has_pkg "$pkg" || to_install+=("$pkg")
    done

    if (( ${#to_install[@]} == 0 )); then
        success "All ${name} AUR packages already installed"
        return 0
    fi

    info "Installing ${#to_install[@]} AUR packages: ${to_install[*]}"
    run "$AUR_HELPER" -S --needed --noconfirm "${to_install[@]}"
}

# Symlink dest -> src. Replaces stale links, backs up real files or directories in the way.
link_path() {
    local src="$1" dest="$2"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        warn "Source not found, skipping: $src"
        return 0
    fi

    if [[ -L "$dest" ]]; then
        local current
        current="$(readlink "$dest")"
        if [[ "${current%/}" == "${src%/}" ]]; then
            success "Already linked: $dest"
            return 0
        fi
        info "Replacing stale symlink: $dest -> $current"
        run rm "$dest"
    elif [[ -e "$dest" ]]; then
        local backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
        warn "Backing up existing $dest to $backup"
        run mv "$dest" "$backup"
    fi

    run mkdir -p "$(dirname "$dest")"
    info "Linking: $dest -> $src"
    run ln -sfn "$src" "$dest"
}

# Copy a tracked file into /etc (root, 0644) when it differs from what is there
install_etc_file() {
    local src="$1" dest="$2"
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        success "Already in place: $dest"
        return 0
    fi
    info "Installing: $dest"
    run sudo install -Dm644 "$src" "$dest"
}

enable_system_service() {
    local service="$1"
    if systemctl is-enabled "$service" &>/dev/null; then
        success "Already enabled: $service"
    else
        info "Enabling: $service"
        run sudo systemctl enable "$service"
    fi
}

enable_user_service() {
    local service="$1"
    if systemctl --user is-enabled "$service" &>/dev/null; then
        success "Already enabled (user): $service"
    else
        info "Enabling user service: $service"
        if ! run systemctl --user enable "$service"; then
            warn "Could not enable $service, it may need an active user session"
        fi
    fi
}
