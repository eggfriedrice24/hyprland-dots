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

# Optional steps that failed; stage 9 (finalize) lists them at the end instead of the install stopping
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

# install_etc_file SRC DEST [MODE]: copy a tracked file to DEST (owned by root, MODE default 644,
# 755 for a hook script) when its content or mode differs from what is there.
# ETC_FILE_CHANGED is 1 afterwards when the file was (or in a dry run would be) replaced, so the
# caller can add the note the change needs.
ETC_FILE_CHANGED=0
install_etc_file() {
    local src="$1" dest="$2" mode="${3:-644}"
    ETC_FILE_CHANGED=0
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest" && [[ "$(stat -c %a "$dest")" == "$mode" ]]; then
        success "Already in place: $dest"
        return 0
    fi
    info "Installing: $dest"
    run sudo install -Dm"$mode" "$src" "$dest"
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

# ---------------------------------------------------------------- root, removal, snapshots

# as_root CMD...: run a command as root. sudo when it does not have to ask (cached credentials, or
# NOPASSWD as in the bootstrap chroot) or has a terminal to ask on; pkexec and the polkit agent's
# dialog when started without a terminal (a keybind, a launcher) inside the graphical session.
# Stages keep `run sudo`; migrations use this.
as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif sudo -n true 2>/dev/null || [[ -t 0 || -t 2 ]]; then
        sudo "$@"
    elif command -v pkexec &>/dev/null && [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        pkexec "$@"
    else
        error "Cannot become root (no terminal for sudo, no graphical session for pkexec): $*"
        return 1
    fi
}

# remove_packages PKG...: remove the installed ones, with the dependencies nothing else needs.
# Without -c: a package something else still depends on makes pacman, and so the caller, fail.
remove_packages() {
    local -a installed=()
    local pkg
    for pkg in "$@"; do
        # exact name only: pacman -Q also answers for a provider (frameit -> frameit-bin), which must stay
        if [[ "$(pacman -Qq "$pkg" 2>/dev/null)" == "$pkg" ]]; then
            installed+=("$pkg")
        fi
    done
    if (( ${#installed[@]} == 0 )); then
        success "Already absent: $*"
        return 0
    fi
    info "Removing packages: ${installed[*]}"
    run as_root pacman -Rns --noconfirm "${installed[@]}"
}

# remove_path PATH...: delete files or directories inside $HOME that an older version left behind
remove_path() {
    local path
    for path in "$@"; do
        if [[ "$path" != "$HOME"/?* || "$path" == *..* ]]; then
            error "remove_path only deletes inside \$HOME: $path"
            return 1
        fi
        if [[ -e "$path" || -L "$path" ]]; then
            info "Removing: $path"
            run rm -rf -- "$path"
        else
            success "Already absent: $path"
        fi
    done
}

# remove_etc_file PATH: delete a file under /etc that an older version installed (the counterpart
# of install_etc_file). Sets ETC_FILE_CHANGED like install_etc_file.
remove_etc_file() {
    local path="$1"
    ETC_FILE_CHANGED=0
    if [[ "$path" != /etc/?* || "$path" == *..* ]]; then
        error "remove_etc_file only deletes inside /etc: $path"
        return 1
    fi
    if [[ -e "$path" || -L "$path" ]]; then
        info "Removing: $path"
        run as_root rm -f -- "$path"
        ETC_FILE_CHANGED=1
    else
        success "Already absent: $path"
    fi
}

# has_snapshots: the btrfs layout bootstrap.sh builds (/ on btrfs, /.snapshots its own @snapshots
# subvolume) with snapper installed. ext4 machines, this desktop among them, and btrfs layouts made
# by hand answer no, so nothing creates snapper configs there.
has_snapshots() {
    local fstype opts
    fstype="$(findmnt -no FSTYPE / 2>/dev/null)" || return 1
    [[ "$fstype" == btrfs ]] || return 1
    opts="$(findmnt -no OPTIONS /.snapshots 2>/dev/null)" || return 1
    [[ ",$opts," == *,subvol=@snapshots,* || ",$opts," == *,subvol=/@snapshots,* ]] || return 1
    command -v snapper &>/dev/null
}

# ---------------------------------------------------------------- repositories and theme

# THEME_REPO can point at a local mirror (VM tests); THEME_DIR is where every theme link expects it
THEME_REPO="${THEME_REPO:-https://github.com/eggfriedrice24/eggfriedrice.nvim}"
THEME_DIR="${THEME_DIR:-$HOME/p/eggfriedrice.nvim}"
export THEME_DIR

# repo_sync DIR NAME: fast-forward a clone to its upstream and nothing else: no stash, no rebase,
# no merge commit. A dirty tree is fine as long as the incoming commits do not touch the dirty files;
# git refuses the whole fast-forward otherwise and the checkout stays as it was.
# Result in REPO_SYNC_STATUS: updated current ahead diverged blocked busy detached no-upstream
# offline missing, plus would-update in a dry run. REPO_SYNC_OLD and REPO_SYNC_NEW hold HEAD
# before and after, REPO_SYNC_DETAIL the reason when nothing was pulled. Never fails.
# A dry run fetches only with DRY_FETCH=1 (dots-update sets it; a fetch moves origin/* and nothing else).
repo_sync() {
    local dir="$1" name="$2" gitdir counts ahead behind out
    REPO_SYNC_STATUS="" REPO_SYNC_OLD="" REPO_SYNC_NEW="" REPO_SYNC_DETAIL=""

    if ! git -C "$dir" rev-parse --git-dir &>/dev/null; then
        REPO_SYNC_STATUS=missing REPO_SYNC_DETAIL="not a git checkout: $dir"
        warn "$name: $REPO_SYNC_DETAIL"
        return 0
    fi
    REPO_SYNC_OLD="$(git -C "$dir" rev-parse HEAD)"
    REPO_SYNC_NEW="$REPO_SYNC_OLD"
    gitdir="$(git -C "$dir" rev-parse --absolute-git-dir)"

    if [[ -e "$gitdir/MERGE_HEAD" || -e "$gitdir/CHERRY_PICK_HEAD" || -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" ]]; then
        REPO_SYNC_STATUS=busy REPO_SYNC_DETAIL="a merge, rebase or cherry-pick is in progress"
    elif ! git -C "$dir" symbolic-ref -q HEAD >/dev/null; then
        REPO_SYNC_STATUS=detached REPO_SYNC_DETAIL="HEAD is detached"
    elif ! git -C "$dir" rev-parse -q --verify '@{u}' &>/dev/null; then
        REPO_SYNC_STATUS=no-upstream REPO_SYNC_DETAIL="the branch has no upstream"
    fi
    if [[ -n "$REPO_SYNC_STATUS" ]]; then
        warn "$name: not pulling, $REPO_SYNC_DETAIL"
        return 0
    fi

    if [[ "${DRY_RUN:-0}" == "1" && "${DRY_FETCH:-0}" != "1" ]]; then
        dry "git -C $dir fetch, then merge --ff-only @{u}"
        REPO_SYNC_STATUS=current
        return 0
    fi
    # without a terminal nothing may ask for a passphrase or a password
    local -a fetch=(git -C "$dir" fetch --quiet)
    if [[ ! -t 0 ]]; then
        fetch=(env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" timeout 45 "${fetch[@]}")
    fi
    if ! out="$("${fetch[@]}" 2>&1)"; then
        REPO_SYNC_STATUS=offline REPO_SYNC_DETAIL="${out%%$'\n'*}"
        warn "$name: fetch failed, keeping the local checkout (${REPO_SYNC_DETAIL:-no output})"
        return 0
    fi

    counts="$(git -C "$dir" rev-list --left-right --count 'HEAD...@{u}')"
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
    if (( behind == 0 )); then
        if (( ahead > 0 )); then
            REPO_SYNC_STATUS=ahead REPO_SYNC_DETAIL="$ahead unpushed commit(s)"
            info "$name: up to date, $REPO_SYNC_DETAIL"
        else
            REPO_SYNC_STATUS=current
            success "$name: up to date"
        fi
    elif (( ahead > 0 )); then
        REPO_SYNC_STATUS=diverged REPO_SYNC_DETAIL="$ahead local and $behind remote commit(s); rebase or merge by hand: git -C $dir pull --rebase"
        warn "$name: diverged, not pulling ($REPO_SYNC_DETAIL)"
    elif [[ "${DRY_RUN:-0}" == "1" ]]; then
        REPO_SYNC_STATUS=would-update
        REPO_SYNC_NEW="$(git -C "$dir" rev-parse '@{u}')"
        dry "$name: fast-forward $behind commit(s)"
    elif out="$(git -C "$dir" merge --ff-only --quiet '@{u}' 2>&1)"; then
        REPO_SYNC_STATUS=updated
        REPO_SYNC_NEW="$(git -C "$dir" rev-parse HEAD)"
        info "$name: fast-forwarded $behind commit(s) to ${REPO_SYNC_NEW:0:7}"
    else
        REPO_SYNC_STATUS=blocked
        REPO_SYNC_DETAIL="$(sed -n 's/^[[:space:]]\+//p' <<<"$out" | paste -sd' ')"
        warn "$name: $behind commit(s) NOT pulled, local changes are in the way: ${REPO_SYNC_DETAIL:-$out}"
    fi
    return 0
}

# Clone the theme repo when it is missing, fast-forward it otherwise
theme_ensure() {
    if [[ -d "$THEME_DIR/.git" ]]; then
        repo_sync "$THEME_DIR" theme
    else
        info "Cloning theme repo to $THEME_DIR..."
        run mkdir -p "$(dirname "$THEME_DIR")"
        run git clone --quiet "$THEME_REPO" "$THEME_DIR"
        REPO_SYNC_STATUS=updated REPO_SYNC_OLD="" REPO_SYNC_NEW="" REPO_SYNC_DETAIL="cloned"
    fi
}

# Every extra the dotfiles reference. Most consumers fall back silently when one is missing,
# so a broken theme would otherwise go unnoticed until the desktop looks wrong.
THEME_REQUIRED_EXTRAS=(
    adw/gtk-3.0.css
    adw/gtk-4.0.css
    bat/eggfriedrice.tmTheme
    btop/eggfriedrice.theme
    dunst/eggfriedrice.conf
    eza/eggfriedrice.yml
    frameit/eggfriedrice.toml
    fsh/eggfriedrice.ini
    fzf/eggfriedrice.sh
    ghostty/eggfriedrice
    gtk/eggfriedrice.css
    hyprland/eggfriedrice.conf
    lazygit/eggfriedrice.yml
    lua/eggfriedrice.lua
    opencode/eggfriedrice.json
    papirus/eggfriedrice.sh
    rofi/eggfriedrice.rasi
    tmux/eggfriedrice.tmux
    zsh/eggfriedrice.zsh
)

# The theme repo has every required extra, and every symlink tracked in the dotfiles resolves
# (most of them point into the theme repo). Skipped in a dry run that has not cloned it yet.
verify_theme() {
    local missing=0 extra entry mode path
    if [[ ! -d "$THEME_DIR/extras" ]]; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
            warn "Theme repo not cloned in dry-run, skipping the extras and link check"
            return 0
        fi
        error "Theme repo has no extras/ directory: $THEME_DIR"
        return 1
    fi
    for extra in "${THEME_REQUIRED_EXTRAS[@]}"; do
        if [[ ! -s "$THEME_DIR/extras/$extra" ]]; then
            error "Missing theme extra: $THEME_DIR/extras/$extra"
            missing=1
        fi
    done
    # ls-files -s: "<mode> <object> <stage>\t<path>"; 120000 is a symlink
    while IFS= read -r -d '' entry; do
        mode="${entry%% *}"
        path="${entry#*$'\t'}"
        if [[ "$mode" == 120000 && ! -e "$DOTFILES_DIR/$path" ]]; then
            error "Dangling link in the dotfiles: $path -> $(readlink "$DOTFILES_DIR/$path")"
            missing=1
        fi
    done < <(git -C "$DOTFILES_DIR" ls-files -s -z 2>/dev/null)
    if (( missing )); then
        error "Theme repo is incomplete or older than the dotfiles expect; update $THEME_DIR (or run 'make extras' there) and retry"
        return 1
    fi
    success "All ${#THEME_REQUIRED_EXTRAS[@]} theme extras present, every tracked link resolves"
}
