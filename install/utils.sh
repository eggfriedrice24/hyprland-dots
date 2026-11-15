#!/usr/bin/env bash
# Shared helpers for install stages

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Every helper line is also appended, uncoloured, to $LOG_FILE when it is set (install.sh sets
# its own for a real run, dots-update passes one in). Command output is not captured, so pacman,
# sudo and makepkg keep the terminal.
_log() {
    [[ -n "${LOG_FILE:-}" ]] && printf '%s %-5s %s\n' "$(date +%H:%M:%S)" "$1" "$2" >>"$LOG_FILE"
    return 0
}
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; _log INFO "$*"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; _log WARN "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; _log ERROR "$*"; }
# QUIET=1 keeps the "already done" lines out of the terminal; they still reach the log
success() {
    [[ "${QUIET:-0}" == "1" ]] || printf "${GREEN}[OK]${NC} %s\n" "$*"
    _log OK "$*"
}
dry() { printf "${YELLOW}[DRY-RUN]${NC} %s\n" "$*"; _log DRY "$*"; }

# Dry-run wrapper: prints the command if DRY_RUN=1, otherwise executes it.
# Pipelines cannot be passed directly; wrap them as: run bash -c '... | ...'
run() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "$*"
    else
        _log RUN "$*"
        "$@"
    fi
}

# note reboot|relogin|restart|todo "reason": something the user has to do once this run is over.
# The final stage lists them; dots-update reads them from $DOTS_NOTES_FILE for its own summary.
NOTES=()
note() {
    local kind="$1"
    shift
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "would need $kind: $*"
        return 0
    fi
    warn "$kind needed: $*"
    NOTES+=("$kind: $*")
    if [[ -n "${DOTS_NOTES_FILE:-}" ]]; then
        printf '%s\t%s\n' "$kind" "$*" >>"$DOTS_NOTES_FILE"
    fi
    return 0
}

# Optional steps that failed; stage 7 lists them at the end instead of the install stopping
FAILED=()

# try LABEL CMD...: run an optional step through run; a failure is reported and collected, never fatal
try() {
    local label="$1"
    shift
    if run "$@"; then
        return 0
    else
        local status=$?
        warn "Optional step failed (exit ${status}): ${label}"
        FAILED+=("$label")
    fi
}

# Packages a dry run of stage 1 would install. A dry run counts them (and their commands) as present,
# so the later stages print what they would do with them instead of skipping them as missing.
declare -A PLANNED_PKGS=()
plan_packages() {
    [[ "${DRY_RUN:-0}" == "1" ]] || return 0
    local pkg
    for pkg in "$@"; do
        PLANNED_PKGS["$pkg"]=1
    done
}

has_pkg() {
    pacman -Qq "$1" &>/dev/null && return 0
    [[ "${DRY_RUN:-0}" == "1" && -n "${PLANNED_PKGS[$1]:-}" ]]
}

# has_cmd CMD [PKG]: CMD is on PATH, or a dry run plans PKG (default: CMD), which provides it
has_cmd() {
    command -v "$1" &>/dev/null && return 0
    [[ "${DRY_RUN:-0}" == "1" && -n "${PLANNED_PKGS[${2:-$1}]:-}" ]]
}

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
    plan_packages "${to_install[@]}"
}

# install_packages FILE [LABEL]: install a .txt list via pacman; LABEL names it in the output
# (default: the file name without .txt)
install_packages() {
    local file="$1"
    local name="${2:-$(basename "$file" .txt)}"
    if [[ ! -f "$file" ]]; then
        error "Package list not found: $file"
        return 1
    fi
    local -a pkgs
    mapfile -t pkgs < <(parse_package_list "$file")
    info "Installing ${name} packages..."
    install_package_names "$name" "${pkgs[@]}"
}

# install_aur_packages FILE [LABEL]: install a .txt list via $AUR_HELPER
install_aur_packages() {
    local file="$1"
    local name="${2:-$(basename "$file" .txt)}"
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
    plan_packages "${to_install[@]}"
    # AUR builds break for reasons outside this repo (upstream PKGBUILD, PGP keys); one failure
    # must not stop the configs from being linked, so retry one by one and report at the end
    if ! run "$AUR_HELPER" -S --needed --noconfirm "${to_install[@]}"; then
        warn "Batch AUR install failed, retrying one package at a time"
        for pkg in "${to_install[@]}"; do
            has_pkg "$pkg" && continue
            if ! run "$AUR_HELPER" -S --needed --noconfirm "$pkg"; then
                warn "AUR package failed: $pkg"
                AUR_FAILED+=("$pkg")
            fi
        done
    fi
}
AUR_FAILED=()

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

# Copy a tracked file into /etc (root, 0644) when it differs from what is there.
# ETC_FILE_CHANGED is 1 afterwards when the file was (or in a dry run would be) replaced, so the
# caller can add the note the change needs.
ETC_FILE_CHANGED=0
install_etc_file() {
    local src="$1" dest="$2"
    ETC_FILE_CHANGED=0
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        success "Already in place: $dest"
        return 0
    fi
    info "Installing: $dest"
    run sudo install -Dm644 "$src" "$dest"
    ETC_FILE_CHANGED=1
}

# install_etc_tree DIR: every file under DIR (a tree laid out like /etc) to the same path under /etc.
# ETC_TREE_CHANGED lists the destinations that changed.
ETC_TREE_CHANGED=()
install_etc_tree() {
    local src="${1%/}" file dest
    ETC_TREE_CHANGED=()
    [[ -d "$src" ]] || return 0
    while IFS= read -r -d '' file; do
        dest="/etc/${file#"$src"/}"
        install_etc_file "$file" "$dest"
        if (( ETC_FILE_CHANGED )); then
            ETC_TREE_CHANGED+=("$dest")
        fi
    done < <(find "$src" -type f -print0 | sort -z)
}

# profile_files NAME: machines/<layer>/NAME for each layer of the active profile that has one,
# base layer first (PROFILE_LAYERS is set by install.sh)
profile_files() {
    local layer
    for layer in ${PROFILE_LAYERS[@]+"${PROFILE_LAYERS[@]}"}; do
        if [[ -e "${DOTFILES_DIR}/machines/${layer}/$1" ]]; then
            printf '%s\n' "${DOTFILES_DIR}/machines/${layer}/$1"
        fi
    done
}

# layer_of PATH: the profile layer a machines/<layer>/... path belongs to
layer_of() {
    local rel="${1#"${DOTFILES_DIR}/machines/"}"
    printf '%s' "${rel%%/*}"
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
