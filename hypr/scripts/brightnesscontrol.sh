#!/usr/bin/env sh
# Brightness up (i) or down (d) with a dunst progress notification.
# The internal panel's backlight when it is the focused output (or no output is known), otherwise
# DDC/CI on the focused external monitor.
# - presses are serialized with flock, so fast repeats queue instead of racing on the i2c bus
# - the DDC connector -> i2c bus map is cached in $XDG_RUNTIME_DIR and rebuilt when the set of
#   connected DRM connectors changes, when the focused output is not in it, or when a write fails
# - the backlight never goes below FLOOR percent of its maximum, so a press cannot turn it black
#
# Test overrides: BACKLIGHT_DIR, DRM_DIR, BRIGHTNESS_MONITOR (focused output), XDG_RUNTIME_DIR.

tagBri="notifybri"
step=5
FLOOR=5

usage() {
    echo "brightnesscontrol.sh [action]"
    echo "i -- increase brightness [+${step}%]"
    echo "d -- decrease brightness [-${step}%]"
}

case $1 in
    i|d) action=$1 ;;
    *) usage >&2; exit 2 ;;
esac

RUNTIME=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
CACHE=$RUNTIME/brightness-ddc.map
LOCK=$RUNTIME/brightness.lock
BL_DIR=${BACKLIGHT_DIR:-/sys/class/backlight}
DRM=${DRM_DIR:-/sys/class/drm}

notify_bri() {
    percent=$1
    [ -z "$percent" ] && return

    ico="display-brightness-symbolic"

    dunstify -i "$ico" -a "Brightness" -u low \
      -h string:x-dunst-stack-tag:$tagBri \
      -h int:value:"$percent" "Brightness: ${percent}%" -r 91191 -t 800
}

notify_error() {
    dunstify -a "Brightness" -u low \
      -h string:x-dunst-stack-tag:$tagBri \
      "$1" -r 91191 -t 1200
}

focused_monitor() {
    if [ -n "$BRIGHTNESS_MONITOR" ]; then
        echo "$BRIGHTNESS_MONITOR"
        return
    fi
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null
}

backlight_device() {
    for d in "$BL_DIR"/*; do
        if [ -r "$d/max_brightness" ]; then
            echo "${d##*/}"
            return
        fi
    done
}

set_backlight() {
    dev=$1
    cur=$(cat "$BL_DIR/$dev/brightness" 2>/dev/null)
    max=$(cat "$BL_DIR/$dev/max_brightness" 2>/dev/null)
    [ -n "$cur" ] && [ -n "$max" ] && [ "$max" -gt 0 ] || return 1

    delta=$(( max * step / 100 ))
    [ "$delta" -lt 1 ] && delta=1
    floor=$(( max * FLOOR / 100 ))
    [ "$floor" -lt 1 ] && floor=1

    case $2 in
        i)
            target=$(( cur + delta ))
            [ "$target" -gt "$max" ] && target=$max
            ;;
        d)
            target=$(( cur - delta ))
            [ "$target" -lt "$floor" ] && target=$floor
            # already below the floor (set elsewhere): never raise on a down press
            [ "$target" -gt "$cur" ] && target=$cur
            ;;
    esac

    brightnessctl -q -d "$dev" s "$target"
    notify_bri $(( 100 * target / max ))
}

# connected state of every DRM connector; a change means monitors were plugged or unplugged
drm_signature() {
    for s in "$DRM"/card*-*/status; do
        [ -r "$s" ] || continue
        c=${s%/status}
        printf '%s=%s ' "${c##*/}" "$(cat "$s" 2>/dev/null)"
    done
}

# one ddcutil detect for all monitors: "<connector> <bus>" lines under a signature header
build_map() {
    {
        printf 'sig %s\n' "$sig"
        ddcutil detect --brief 2>/dev/null | awk '
            /^[ \t]*Display [0-9]/ { valid = 1; bus = "" }
            /^[ \t]*(Invalid|Phantom) display/ { valid = 0; bus = "" }
            $1 == "I2C" && $2 == "bus:" { bus = $3; sub(".*/i2c-", "", bus) }
            $1 == "DRM" && $2 == "connector:" && valid && bus != "" {
                c = $3
                sub("^card[0-9]+-", "", c)
                print c, bus
            }
        '
    } > "$CACHE.$$" && mv -f "$CACHE.$$" "$CACHE"
}

cache_valid() {
    [ "$(head -n1 "$CACHE" 2>/dev/null)" = "sig $sig" ]
}

lookup_bus() {
    awk -v m="$1" 'NR > 1 && $1 == m { print $2; exit }' "$CACHE" 2>/dev/null
}

ddc_step() {
    case $2 in
        i) ddcutil -b "$1" --noverify setvcp 10 + "$step" ;;
        d) ddcutil -b "$1" --noverify setvcp 10 - "$step" ;;
    esac
}

set_ddc_brightness() {
    monitor=$1
    sig=$(drm_signature)
    rebuilt=0

    if ! cache_valid; then
        build_map
        rebuilt=1
    fi
    bus=$(lookup_bus "$monitor")
    if [ -z "$bus" ] && [ "$rebuilt" -eq 0 ]; then
        build_map
        rebuilt=1
        bus=$(lookup_bus "$monitor")
    fi

    if [ -z "$bus" ]; then
        notify_error "Brightness: no DDC bus for ${monitor}"
        return 1
    fi

    if ! ddc_step "$bus" "$2" >/dev/null 2>&1; then
        # the bus may have moved (driver reload, replug): detect once more and retry
        [ "$rebuilt" -eq 1 ] || build_map
        bus=$(lookup_bus "$monitor")
        if [ -z "$bus" ] || ! ddc_step "$bus" "$2" >/dev/null 2>&1; then
            rm -f "$CACHE"
            notify_error "Brightness: DDC write to ${monitor} failed"
            return 1
        fi
    fi

    percent=$(ddcutil -b "$bus" --brief getvcp 10 2>/dev/null | awk '{print $4}')
    notify_bri "$percent"
}

# one press at a time; a press that waits more than 10 s is dropped
exec 9>"$LOCK"
flock -w 10 9 || exit 1

monitor=$(focused_monitor)
backlight=$(backlight_device)

case $monitor in
    eDP-*|LVDS-*)
        if [ -n "$backlight" ]; then
            set_backlight "$backlight" "$action"
            exit
        fi
        ;;
esac

if [ -n "$monitor" ]; then
    set_ddc_brightness "$monitor" "$action"
elif [ -n "$backlight" ]; then
    set_backlight "$backlight" "$action"
fi
