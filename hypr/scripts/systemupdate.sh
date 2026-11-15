#!/usr/bin/env bash
# Update status for a bar or menu, and the one launcher for an interactive update.
#
#   systemupdate.sh          one waybar JSON line (return-type json) from dots-update's status file
#   systemupdate.sh check    refresh the status first (dots-update --check: no sudo, fetches), then print it
#   systemupdate.sh up       dots-update in a ghostty window that stays open after it ends
#
# The JSON text is the number of pending packages ("!" for only a reboot or relogin, "*" for only
# commits or migrations), empty when there is nothing to do, so a module hides itself; class is one
# of uptodate, pending, relogin, reboot or unknown, plus failed when the last run did not end cleanly. A reboot or relogin flag counts only in the boot or Hyprland
# session it was raised in, so a stale flag disappears without rerunning anything.

[[ -f /etc/arch-release ]] || exit 0

script="$(readlink -f "${BASH_SOURCE[0]}")"
dotfiles="$(dirname "$(dirname "$(dirname "$script")")")"
updater="$dotfiles/bin/dots-update"
status_file="${DOTS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}/update/status"

if [[ "${1:-}" == up ]]; then
    if [[ -x "$updater" ]]; then
        exec ghostty --title=dots-update --wait-after-command=true -e "$updater"
    fi
    # a checkout from before dots-update existed
    helper="$(command -v yay || command -v paru)" || helper="sudo pacman"
    exec ghostty --title=dots-update --wait-after-command=true -e sh -c "$helper -Syu"
fi
if [[ "${1:-}" == check && -x "$updater" ]]; then
    "$updater" --check >/dev/null 2>&1 || true
fi

# JSON string: backslash, quote, newline and tab escaped; other control characters dropped
json_str() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//[$'\001'-$'\037']/}"
    printf '"%s"' "$s"
}
num() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then printf '%s' "$1"; else printf 0; fi
}

declare -A st=()
if [[ -r "$status_file" ]]; then
    while IFS='=' read -r key value; do
        if [[ "$key" =~ ^[a-z_]+$ ]]; then st["$key"]="$value"; fi
    done <"$status_file"
fi

if [[ -z "${st[checked]:-}${st[last_run]:-}" ]]; then
    printf '{"text":"","alt":"unknown","class":["unknown"],"tooltip":%s}\n' \
        "$(json_str "No update check yet: $updater --check")"
    exit 0
fi

official="$(num "${st[official]:-0}")"
aur="$(num "${st[aur]:-0}")"
migrations="$(num "${st[migrations]:-0}")"
total=$((official + aur))
boot_id="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null)"

reboot=0 relogin=0
if [[ ! -d "/usr/lib/modules/$(uname -r)" ]] ||
    [[ "${st[reboot]:-0}" == 1 && "${st[reboot_boot_id]:-}" == "$boot_id" ]]; then
    reboot=1
fi
if [[ "${st[relogin]:-0}" == 1 && -n "${st[relogin_session]:-}" &&
    "${st[relogin_session]}" == "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    relogin=1
fi

tooltip="Packages: $official official, $aur AUR"
other=0 # commits to pull or migrations to run, with no package pending
for repo in dotfiles theme; do
    behind="${st[${repo}_behind]:-}"
    case "$behind" in
        "" | 0) ;;
        "?") tooltip+=$'\n'"${repo^}: upstream not reachable" ;;
        *)
            tooltip+=$'\n'"${repo^}: $behind commit(s) behind"
            other=1
            ;;
    esac
done
if ((migrations)); then other=1; fi
if ((migrations)); then tooltip+=$'\n'"Migrations: $migrations pending"; fi
if ((reboot)); then tooltip+=$'\n'"Reboot needed"; fi
if ((relogin)); then tooltip+=$'\n'"Relogin needed"; fi
if [[ -n "${st[checked]:-}" ]]; then
    tooltip+=$'\n'"Checked $(date -d "@${st[checked]}" '+%Y-%m-%d %H:%M' 2>/dev/null)"
fi
if [[ -n "${st[last_run]:-}" ]]; then
    tooltip+=$'\n'"Last update $(date -d "@${st[last_run]}" '+%Y-%m-%d %H:%M' 2>/dev/null) (${st[last_result]:-unknown})"
fi

if ((reboot)); then
    class=reboot
elif ((relogin)); then
    class=relogin
elif ((total > 0 || other)); then
    class=pending
else
    class=uptodate
fi
classes="$(json_str "$class")"
if [[ -n "${st[last_result]:-}" && "${st[last_result]}" != ok ]]; then classes+=",$(json_str failed)"; fi

text=""
if ((total > 0)); then
    text="$total"
elif ((reboot || relogin)); then
    text="!"
elif ((other)); then
    text="*"
fi
printf '{"text":%s,"alt":%s,"class":[%s],"tooltip":%s}\n' \
    "$(json_str "$text")" "$(json_str "$class")" "$classes" "$(json_str "$tooltip")"
