#!/usr/bin/env bash
# One-off migrations: what the idempotent stages cannot express, such as removing a package or a
# file an older version of these dotfiles installed. Each install/migrations/<YYYYMMDD-HHMM>-<slug>.sh
# runs once per machine, oldest first, after the stages have converged it.
#
#   install/migrate.sh                 run the pending migrations
#   install/migrate.sh --dry-run       print what they would do, record nothing
#   install/migrate.sh --status        list every migration and its state (no root, writes nothing)
#   install/migrate.sh --baseline      record every pending migration as baseline without running it
#   install/migrate.sh --skip ID       record one migration as skipped (one that cannot work here)
#   install/migrate.sh --rearm ID      forget the state of ID so it runs again (after a rollback)
#   install/migrate.sh --new SLUG      create an empty migration named for the current time
#   install/migrate.sh --profile NAME  use machine profile NAME instead of the detected one
#
# State: one line per event in $XDG_STATE_HOME/dotfiles/migrations, "<id> <state> <time>", where
# state is applied, baseline or skipped; the last line for an id wins and an id without one is pending.
# Sourced by install.sh: migrations_init before the stages, migrations_run as stage 8.

MIGRATIONS_DIR="${DOTFILES_DIR:-}/install/migrations"
MIGRATIONS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
MIGRATIONS_STATE="${MIGRATIONS_STATE_DIR}/migrations"
MIGRATIONS_LOCK="${MIGRATIONS_STATE_DIR}/migrations.lock"
# set by migrations_run: the id that failed, or "locked" when another run held the lock.
# install.sh exits 3 and stage 9 warns while it is set.
MIGRATION_FAILED=""
MIGRATIONS_NEW_MACHINE=0

# ids (file names without .sh) in run order; the fixed-width timestamp makes byte order chronological
migration_ids() {
    local file
    for file in "$MIGRATIONS_DIR"/[0-9]*.sh; do
        [[ -f "$file" ]] || continue
        file="${file##*/}"
        if [[ "$file" =~ ^[0-9]{8}-[0-9]{4}-[a-z0-9-]+\.sh$ ]]; then
            echo "${file%.sh}"
        else
            warn "Ignoring migration with a malformed name: $file" >&2
        fi
    done | LC_ALL=C sort
}

# second line of the file: "# what it does"
migration_description() { sed -n '2s/^#[[:space:]]*//p' "$MIGRATIONS_DIR/$1.sh"; }

# prints applied, baseline or skipped; fails when the migration is pending
migration_state() {
    [[ -f "$MIGRATIONS_STATE" ]] || return 1
    awk -v id="$1" '$1 == id { state = $2 } END { if (state == "") exit 1; print state }' "$MIGRATIONS_STATE"
}

# migration_record ID applied|baseline|skipped
migration_record() {
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "record migration $1 as $2"
        return 0
    fi
    mkdir -p "$MIGRATIONS_STATE_DIR"
    printf '%s %s %s\n' "$1" "$2" "$(date -Iseconds)" >>"$MIGRATIONS_STATE"
}

migrations_pending() {
    local id
    while IFS= read -r id; do
        migration_state "$id" >/dev/null || echo "$id"
    done < <(migration_ids)
}

migrations_baseline() {
    local id
    while IFS= read -r id; do
        migration_record "$id" baseline
    done < <(migrations_pending)
}

# One run at a time changes the state file. A dry run changes nothing and takes no lock.
migrations_lock() {
    [[ "${DRY_RUN:-0}" == "1" ]] && return 0
    mkdir -p "$MIGRATIONS_STATE_DIR" || return 1
    exec {MIGRATIONS_LOCK_FD}>"$MIGRATIONS_LOCK"
    if ! flock -n "$MIGRATIONS_LOCK_FD"; then
        exec {MIGRATIONS_LOCK_FD}>&-
        unset MIGRATIONS_LOCK_FD
        return 1
    fi
}
migrations_unlock() {
    if [[ -n "${MIGRATIONS_LOCK_FD:-}" ]]; then
        exec {MIGRATIONS_LOCK_FD}>&-
        unset MIGRATIONS_LOCK_FD
    fi
    return 0
}

# true when a ~/.config entry (or ~/.zshenv) links into this repository: into this checkout, or
# into another worktree of the same repository. Any link form counts: absolute, relative, trailing
# slash, even a link whose target an older version had and this one deleted.
dotfiles_in_use() {
    local repo common link target dir
    repo="$(readlink -f "$DOTFILES_DIR")"
    common="$(git -C "$DOTFILES_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || common=""
    for link in "${XDG_CONFIG_HOME:-$HOME/.config}"/* "$HOME/.zshenv"; do
        [[ -L "$link" ]] || continue
        target="$(readlink -f "$link")" || continue
        [[ "$target" == "$repo"/* ]] && return 0
        if [[ -n "$common" && -e "$target" ]]; then
            dir="$target"
            [[ -d "$dir" ]] || dir="$(dirname "$dir")"
            if [[ "$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" == "$common" ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# First contact with a machine, before the stages run (stage 3 creates the links that tell a machine
# already running these dotfiles from a new one):
#   new machine      -> nothing older to migrate from: record every migration as baseline
#   existing machine -> start with an empty state, so every migration is pending
# Once the state file exists this does nothing; delete the file to have the machine judged again.
migrations_init() {
    [[ -f "$MIGRATIONS_STATE" ]] && return 0
    local count
    count="$(migration_ids | wc -l)"
    if dotfiles_in_use; then
        info "Migrations: first run on a machine that already uses these dotfiles, all $count are pending"
    else
        info "Migrations: new machine, recording all $count as baseline without running them"
        MIGRATIONS_NEW_MACHINE=1
    fi
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
        mkdir -p "$MIGRATIONS_STATE_DIR"
        : >>"$MIGRATIONS_STATE"
    fi
    if (( MIGRATIONS_NEW_MACHINE )); then
        migrations_baseline
    fi
}

# Body of the process a migration runs in: utils.sh and this file are loaded, errexit is on
# whatever the caller does, and a failing command names its line in the migration.
migration_main() {
    MIGRATION_FILE="$1"
    trap migration_stopped ERR
    # shellcheck source=/dev/null
    source "$1"
}

# ERR trap: the failure may be deep inside a helper; report the migration line that called it
migration_stopped() {
    local i line=""
    for (( i = 1; i < ${#BASH_SOURCE[@]}; i++ )); do
        if [[ "${BASH_SOURCE[i]}" == "$MIGRATION_FILE" ]]; then
            line="${BASH_LINENO[i - 1]}"
            break
        fi
    done
    if [[ -n "$line" ]]; then
        error "Migration stopped at line ${line}: $(sed -n "${line}s/^[[:space:]]*//p" "$MIGRATION_FILE")"
    fi
}

# migration_exec ID: run one migration in its own bash process. Notes it adds (note relogin ...)
# reach the caller: dots-update's notes file when one is set, else this run's NOTES for stage 9.
migration_exec() {
    local id="$1" notes_file="" status=0 kind reason
    if [[ -z "${DOTS_NOTES_FILE:-}" && "${DRY_RUN:-0}" != "1" ]]; then
        notes_file="$(mktemp)"
    fi
    DOTS_NOTES_FILE="${DOTS_NOTES_FILE:-$notes_file}" \
        bash -c 'set -Eeuo pipefail; source "$1"; source "$2"; migration_main "$3"' "migration $id" \
        "$DOTFILES_DIR/install/utils.sh" "$DOTFILES_DIR/install/migrate.sh" "$MIGRATIONS_DIR/$id.sh" ||
        status=$?
    if [[ -n "$notes_file" ]]; then
        while IFS=$'\t' read -r kind reason; do
            NOTES+=("$kind: $reason")
        done <"$notes_file"
        rm -f "$notes_file"
    fi
    return "$status"
}

# Run the pending migrations in order; each is recorded only when it exits 0. The first failure
# stops the run, since later migrations may build on it; the next run retries it.
migrations_run() {
    MIGRATION_FAILED=""
    # a dry run on a new machine records no baseline, so it has to be remembered here
    if (( MIGRATIONS_NEW_MACHINE )); then
        success "New machine, nothing to migrate"
        return 0
    fi
    local -a pending
    mapfile -t pending < <(migrations_pending)
    if (( ${#pending[@]} == 0 )); then
        success "No pending migrations"
        return 0
    fi
    if ! migrations_lock; then
        MIGRATION_FAILED="locked"
        warn "Another migration run holds ${MIGRATIONS_LOCK/#$HOME/\~}, leaving ${#pending[@]} pending"
        return 1
    fi
    # the run that held the lock may have applied some of them
    mapfile -t pending < <(migrations_pending)

    local id
    for id in "${pending[@]}"; do
        info "Migration ${id}: $(migration_description "$id")"
        if migration_exec "$id"; then
            migration_record "$id" applied
            [[ "${DRY_RUN:-0}" == "1" ]] || success "Migration done: $id"
        else
            # shellcheck disable=SC2034 # read by install.sh and stage 9
            MIGRATION_FAILED="$id"
            error "Migration failed: $id (not recorded, later migrations not attempted)"
            warn "Fix the cause and rerun: ${DOTFILES_DIR/#$HOME/\~}/install/migrate.sh"
            warn "Or give up on it here:   ${DOTFILES_DIR/#$HOME/\~}/install/migrate.sh --skip $id"
            migrations_unlock
            return 1
        fi
    done
    migrations_unlock
}

migrations_status() {
    local id state
    while IFS= read -r id; do
        state="$(migration_state "$id")" || state="pending"
        printf '%-9s %s  %s\n' "$state" "$id" "$(migration_description "$id")"
    done < <(migration_ids)
}

# migrations_rearm ID: delete every state line of ID, so the next run treats it as pending
migrations_rearm() {
    local id="$1" tmp
    if [[ ! -f "$MIGRATIONS_STATE" ]] || ! awk -v id="$id" '$1 == id { found = 1 } END { exit !found }' "$MIGRATIONS_STATE"; then
        success "Nothing recorded for $id, it is already pending"
        return 0
    fi
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "forget the recorded state of $id"
        return 0
    fi
    tmp="$(mktemp "${MIGRATIONS_STATE}.XXXXXX")"
    awk -v id="$id" '$1 != id' "$MIGRATIONS_STATE" >"$tmp"
    mv -f "$tmp" "$MIGRATIONS_STATE"
    success "Rearmed $id, the next run applies it again"
}

migration_new() {
    local slug="$1" file
    if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        error "Slug must be lowercase letters and digits joined by single hyphens: ${slug:-<empty>}"
        return 1
    fi
    file="$MIGRATIONS_DIR/$(date +%Y%m%d-%H%M)-$slug.sh"
    if [[ -e "$file" ]]; then
        error "Already exists: ${file/#$HOME/\~}"
        return 1
    fi
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        dry "create ${file/#$HOME/\~}"
        return 0
    fi
    mkdir -p "$MIGRATIONS_DIR"
    cat >"$file" <<'TEMPLATE'
#!/usr/bin/env bash
# TODO one line: what this removes or moves, and why
#
# Runs once on each machine that already used these dotfiles, after the stages have converged it;
# new machines record it as baseline without running it. Check before acting, so it is a no-op
# where there is nothing to do, and make every change through run or a helper (remove_packages,
# remove_path, remove_etc_file, swap_package, as_root) so --dry-run only prints. DOTFILES_DIR,
# PROFILE and DRY_RUN are set. Any failing command leaves it pending for the next run; `return 0`
# ends it early as done. Never edit it once pushed: add a new migration instead.

TEMPLATE
    success "Created ${file/#$HOME/\~}"
}

# ---------------------------------------------------------------- helpers for migrations

# has_exact_pkg PKG: PKG itself is installed. `pacman -Qq swww` also answers for awww, which
# provides swww; a provider must not count as the package a migration removes.
has_exact_pkg() { [[ "$(pacman -Qq "$1" 2>/dev/null)" == "$1" ]]; }

# require_package PKG WHY: stop the migration, leaving it pending, until PKG is installed (stage 1
# installs every listed package before the migrations run). A dry run only warns, because the
# stage 1 of a real run would have installed it by then.
require_package() {
    local pkg="$1" why="$2"
    has_exact_pkg "$pkg" && return 0
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        warn "$pkg is not installed yet ($why); a real run installs it in stage 1 first"
        return 0
    fi
    error "$pkg is not installed ($why); run ./install.sh so stage 1 installs it, then this migration runs again"
    return 1
}

# swap_package OLD NEW [aur]: replace OLD with NEW, which takes over its commands.
# When NEW is already installed next to OLD, OLD is removed normally. Otherwise the two conflict:
# pacman -S --noconfirm answers No to "Remove OLD?", so OLD goes first without a dependency check
# (-Rdd; whatever depends on it is satisfied again by NEW a moment later) and NEW is installed,
# from the AUR with "aur". If that install fails the migration fails, and the next installer run
# installs NEW in stage 1 because nothing provides it any more.
swap_package() {
    local old="$1" new="$2" from="${3:-repo}" helper=""
    if ! has_exact_pkg "$old"; then
        success "Already absent: $old"
        return 0
    fi
    if has_exact_pkg "$new"; then
        remove_packages "$old"
        return 0
    fi
    if [[ "$from" == aur ]]; then
        helper="$(command -v yay || command -v paru || true)"
        if [[ -z "$helper" && "${DRY_RUN:-0}" == "1" ]]; then
            warn "No AUR helper yet; stage 1 of a real run builds yay before this migration"
            helper=yay
        elif [[ -z "$helper" ]]; then
            error "No AUR helper (yay or paru) to install $new with; run ./install.sh so stage 1 builds yay"
            return 1
        fi
    fi
    info "Replacing $old with $new"
    run as_root pacman -Rdd --noconfirm "$old"
    if [[ -n "$helper" ]]; then
        if ! run "${helper##*/}" -S --needed --noconfirm "$new"; then
            error "$old is removed but $new did not install; install it by hand: ${helper##*/} -S $new"
            return 1
        fi
    elif ! run as_root pacman -S --needed --noconfirm "$new"; then
        error "$old is removed but $new did not install; install it by hand: sudo pacman -S $new"
        return 1
    fi
}

# ---------------------------------------------------------------- command line

migrate_usage() {
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

migrate_main() {
    set -Eeuo pipefail
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    MIGRATIONS_DIR="${DOTFILES_DIR}/install/migrations"
    DRY_RUN="${DRY_RUN:-0}"
    # shellcheck source=install/utils.sh
    source "${DOTFILES_DIR}/install/utils.sh"

    local action="run" arg="" profile_flag=""
    while (( $# )); do
        case "$1" in
            --dry-run|-n) DRY_RUN=1 ;;
            --status) action="status" ;;
            --baseline) action="baseline" ;;
            --skip|--rearm|--new)
                action="${1#--}"
                [[ -n "${2:-}" ]] || { error "$1 needs an argument"; migrate_usage 1; }
                arg="$2"
                shift
                ;;
            --profile)
                [[ -n "${2:-}" ]] || { error "--profile needs a name"; migrate_usage 1; }
                profile_flag="$2"
                shift
                ;;
            --profile=*) profile_flag="${1#--profile=}" ;;
            --help|-h) migrate_usage 0 ;;
            *) error "Unknown option: $1"; migrate_usage 1 ;;
        esac
        shift
    done

    if [[ $EUID -eq 0 ]]; then
        error "Run as your normal user, not root; migrations ask for root where they need it."
        exit 1
    fi

    # shellcheck source=install/machine.sh
    source "${DOTFILES_DIR}/install/machine.sh"
    read -r PROFILE PROFILE_SOURCE < <(detect_profile "$profile_flag")
    if ! profile_exists "$PROFILE"; then
        error "Unknown machine profile '$PROFILE' (${PROFILE_SOURCE}). Known: $(list_profiles | paste -sd' ')"
        exit 1
    fi
    PROFILE_DIR="${MACHINES_DIR}/${PROFILE}"
    export DOTFILES_DIR DRY_RUN PROFILE PROFILE_SOURCE PROFILE_DIR
    export PATH="$HOME/.local/bin:$PATH"

    case "$action" in
        status)
            migrations_status
            ;;
        new)
            migration_new "$arg"
            ;;
        skip|rearm|baseline)
            if [[ "$action" != baseline && ! "$arg" =~ ^[0-9]{8}-[0-9]{4}-[a-z0-9-]+$ ]]; then
                error "Not a migration id: $arg (see --status)"
                exit 1
            fi
            if [[ "$action" == skip && ! -f "$MIGRATIONS_DIR/$arg.sh" ]]; then
                error "No such migration: $arg"
                exit 1
            fi
            if ! migrations_lock; then
                error "Another migration run holds ${MIGRATIONS_LOCK/#$HOME/\~}"
                exit 1
            fi
            case "$action" in
                skip)
                    # judge the machine first: a new one baselines the others
                    migrations_init
                    migration_record "$arg" skipped
                    [[ "$DRY_RUN" == "1" ]] || success "Recorded as skipped: $arg"
                    ;;
                rearm)
                    migrations_rearm "$arg"
                    ;;
                baseline)
                    migrations_init
                    migrations_baseline
                    [[ "$DRY_RUN" == "1" ]] || success "Every migration is recorded"
                    ;;
            esac
            migrations_unlock
            ;;
        run)
            migrations_init
            local status=0
            migrations_run || status=1
            if (( ${#NOTES[@]} )) && [[ -z "${DOTS_NOTES_FILE:-}" ]]; then
                warn "Before these changes are all in effect:"
                printf '  - %s\n' "${NOTES[@]}"
            fi
            exit "$status"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    migrate_main "$@"
fi
