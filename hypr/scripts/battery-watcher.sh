#!/usr/bin/env sh
# Laptop battery watcher using sysfs + dunst
# While discharging on battery: low notice at 25%, critical notice at 10%, and at 5% a last
# warning followed by a suspend one check later if still discharging (no hibernate: swap is zram
# only). Each level fires once; plugging in or climbing above 30% re-arms them.
# Only real batteries (BAT*) are considered, so peripherals that also show up
# under /sys/class/power_supply (e.g. a Bluetooth keyboard) are ignored.
# Exits immediately on machines without a battery (desktop).
#
# Test overrides: PS_DIR (power_supply tree), BATTERY_CHECK_EVERY (seconds),
# BATTERY_WATCHER_DRY=1 prints the notices and the suspend instead of acting.

PS=${PS_DIR:-/sys/class/power_supply}
TAG="notifybat"
RID=91234
CHECK_EVERY=${BATTERY_CHECK_EVERY:-60}
DRY=${BATTERY_WATCHER_DRY:-0}
LOW=25
CRIT=10
SUSPEND_AT=5
REARM_ABOVE=30
last_level=-1

ls -d "$PS"/BAT* >/dev/null 2>&1 || exit 0

get_percent() {
  cat "$PS"/BAT*/capacity 2>/dev/null | sort -n | head -n1
}

get_status() {
  cat "$PS"/BAT*/status 2>/dev/null | head -n1
}

on_ac() {
  for d in "$PS"/*; do
    [ "$(cat "$d/type" 2>/dev/null)" = "Mains" ] && [ "$(cat "$d/online" 2>/dev/null)" = "1" ] && return 0
  done
  return 1
}

notify() {
  urgency="$1"
  msg="$2"
  icon="$3"

  if [ "$DRY" = "1" ]; then
    echo "dry: notify $urgency: $msg"
    return
  fi
  dunstify -a "Battery" -i "$icon" -u "$urgency" \
    -h string:x-dunst-stack-tag:$TAG \
    -r $RID \
    "$msg"
}

suspend_now() {
  if [ "$DRY" = "1" ]; then
    echo "dry: systemctl suspend"
    return
  fi
  systemctl suspend
}

# forget the last alert; close it on screen if one is showing
rearm() {
  if [ "$last_level" -ne -1 ] && [ "$DRY" != "1" ]; then
    dunstify -C $RID 2>/dev/null
  fi
  last_level=-1
}

while :; do
  cap=$(get_percent)
  status=$(get_status)

  if [ -z "$cap" ] || on_ac || [ "$status" != "Discharging" ]; then
    rearm
  elif [ "$cap" -le "$SUSPEND_AT" ]; then
    if [ "$last_level" -eq "$SUSPEND_AT" ]; then
      # warned one check ago and still discharging
      suspend_now
      # after resume, warn again before the next suspend
      last_level=-1
    else
      notify critical "Battery at ${cap}%: suspending in a minute, plug in now" "battery-empty"
      last_level=$SUSPEND_AT
    fi
  elif [ "$cap" -le "$CRIT" ]; then
    if [ "$last_level" -ne "$CRIT" ]; then
      notify critical "Battery critical: ${cap}%" "battery-empty"
      last_level=$CRIT
    fi
  elif [ "$cap" -le "$LOW" ]; then
    if [ "$last_level" -ne "$LOW" ]; then
      notify normal "Battery low: ${cap}%" "battery-caution"
      last_level=$LOW
    fi
  elif [ "$cap" -gt "$REARM_ABOVE" ]; then
    rearm
  fi

  sleep "$CHECK_EVERY"
done
