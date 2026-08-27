#!/usr/bin/env sh
# Keyboard (Keychron K4 over Bluetooth) battery watcher using sysfs + dunst
# Thresholds: low <20%, critical <10%. One notification per level.
#
# - right after every (re)connect the kernel node exists but reads 0% (or
#   status Unknown) until the keyboard sends its first battery report; those
#   reads are placeholders and are skipped
# - over Bluetooth the K4 never reports "Charging", the percentage just climbs
#   while the cable is in, so recovery is detected by the level rising again
# - when the level recovers the notification is closed automatically
# - when the keyboard is off / on cable the sysfs node vanishes and the loop idles

NAME="Keychron K4"
BAT=${KBD_BAT:-/sys/class/power_supply/hid-dc:2c:26:15:d5:6a-battery-3}
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

# forget the last alert; close it on screen if one is showing
rearm() {
  [ "$last_level" -ne -1 ] && dunstify -C $RID 2>/dev/null
  last_level=-1
}

while :; do
  cap=$(cat "$BAT/capacity" 2>/dev/null)
  status=$(cat "$BAT/status" 2>/dev/null)

  if [ -z "$cap" ]; then
    # keyboard off / wired: nothing to watch, re-arm for next connect
    last_level=-1
  elif [ "$cap" -eq 0 ] || [ "$status" = "Unknown" ]; then
    : # placeholder before the first battery report, not a real reading
  elif [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
    rearm
  elif [ "$cap" -lt "$CRIT" ]; then
    if [ "$last_level" -ne "$CRIT" ]; then
      notify critical "$NAME battery critical: ${cap}%" "battery-empty"
      last_level=$CRIT
    fi
  elif [ "$cap" -lt "$LOW" ]; then
    if [ "$last_level" -ne "$LOW" ]; then
      notify normal "$NAME battery low: ${cap}%" "battery-caution"
      last_level=$LOW
    fi
  elif [ "$cap" -gt $((LOW + 5)) ]; then
    rearm
  fi

  sleep "$CHECK_EVERY"
done
