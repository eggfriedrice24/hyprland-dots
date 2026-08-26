#!/usr/bin/env sh
# Keyboard (Keychron K4 over Bluetooth) battery watcher using sysfs + dunst
# Thresholds: low <20%, critical <10%. Only fires when discharging.
# Module hides itself when the keyboard is off / on cable (sysfs node vanishes).

NAME="Keychron K4"
BAT="/sys/class/power_supply/hid-dc:2c:26:15:d5:6a-battery-3"
LOW=${KBD_LOW:-20}
CRIT=${KBD_CRIT:-10}
TAG="notifykbd"
RID=91235
CHECK_EVERY=60
last_level=-1

notify() {
  urgency="$1"
  msg="$2"
  icon="$3"

  dunstify -a "Keyboard" -i "$icon" -u "$urgency" \
    -h string:x-dunst-stack-tag:$TAG \
    -r $RID \
    "$msg"
}

while :; do
  if [ -r "$BAT/capacity" ]; then
    cap=$(cat "$BAT/capacity" 2>/dev/null)
    status=$(cat "$BAT/status" 2>/dev/null)
    [ -z "$cap" ] && cap=100

    if [ "$status" != "Charging" ] && [ "$status" != "Full" ]; then
      if   [ "$cap" -lt "$CRIT" ] && [ "$last_level" -ne "$CRIT" ]; then
        notify critical "$NAME battery critical: ${cap}%" "battery-empty"
        last_level=$CRIT
      elif [ "$cap" -lt "$LOW" ] && [ "$last_level" -ne "$LOW" ]; then
        notify normal "$NAME battery low: ${cap}%" "battery-caution"
        last_level=$LOW
      elif [ "$cap" -gt $((LOW + 5)) ]; then
        last_level=-1
      fi
    else
      last_level=-1
    fi
  else
    # keyboard off / wired: nothing to watch, re-arm for next connect
    last_level=-1
  fi

  sleep "$CHECK_EVERY"
done
