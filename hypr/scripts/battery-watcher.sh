#!/usr/bin/env sh
# Laptop battery watcher using sysfs + dunst
# Thresholds: caution <35%, critical <25%. Only fires when discharging on battery.
# Only real batteries (BAT*) are considered, so peripherals that also show up
# under /sys/class/power_supply (e.g. a Bluetooth keyboard) are ignored.
# Exits immediately on machines without a battery (desktop).

PS=${PS_DIR:-/sys/class/power_supply}
TAG="notifybat"
RID=91234
CHECK_EVERY=60
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

  dunstify -a "Battery" -i "$icon" -u "$urgency" \
    -h string:x-dunst-stack-tag:$TAG \
    -r $RID \
    "$msg"
}

# forget the last alert; close it on screen if one is showing
rearm() {
  [ "$last_level" -ne -1 ] && dunstify -C $RID 2>/dev/null
  last_level=-1
}

while :; do
  cap=$(get_percent)
  status=$(get_status)

  if [ -z "$cap" ] || on_ac || [ "$status" != "Discharging" ]; then
    rearm
  elif [ "$cap" -lt 25 ]; then
    if [ "$last_level" -ne 25 ]; then
      notify critical "Battery critical: ${cap}%" "battery-empty"
      last_level=25
    fi
  elif [ "$cap" -lt 35 ]; then
    if [ "$last_level" -ne 35 ]; then
      notify normal "Battery low: ${cap}%" "battery-caution"
      last_level=35
    fi
  elif [ "$cap" -gt 40 ]; then
    rearm
  fi

  sleep "$CHECK_EVERY"
done
