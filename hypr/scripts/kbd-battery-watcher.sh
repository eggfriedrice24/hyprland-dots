#!/usr/bin/env sh
# Keyboard (Keychron K4 over Bluetooth) battery watcher using sysfs + dunst
# Thresholds: low <20%, critical <10%. One notification per level.
#
# - the battery node is found by its model_name on every check, not by a fixed
#   address, so any K4 (or a re-paired one) is picked up; with none present the loop idles
# - right after every (re)connect the kernel node exists but reads 0% (or
#   status Unknown) until the keyboard sends its first battery report; those
#   reads are placeholders and are skipped
# - a node that keeps reading 0% for ZERO_NOTICE minutes gets one low-urgency notice per
#   connection: either the battery really is flat or the keyboard sends no reports
# - over Bluetooth the K4 never reports "Charging", the percentage just climbs
#   while the cable is in, so recovery is detected by the level rising again
# - when the level recovers the notification is closed automatically
# - when the keyboard is off / on cable the sysfs node vanishes and the loop idles
#
# Overrides: KBD_MODEL (model_name to match), KBD_BAT (a fixed node, skips the lookup),
# KBD_LOW, KBD_CRIT, KBD_ZERO_NOTICE (minutes, 0 disables), PS_DIR (power_supply tree),
# KBD_CHECK_EVERY (seconds).

NAME=${KBD_MODEL:-Keychron K4}
PS=${PS_DIR:-/sys/class/power_supply}
LOW=${KBD_LOW:-20}
CRIT=${KBD_CRIT:-10}
ZERO_NOTICE=${KBD_ZERO_NOTICE:-10}
TAG="notifykbd"
RID=91235
CHECK_EVERY=${KBD_CHECK_EVERY:-60}
last_level=-1
zero_since=0
zero_noticed=0

# the battery node whose model_name is $NAME, empty when the keyboard is not connected
find_node() {
  if [ -n "$KBD_BAT" ]; then
    [ -e "$KBD_BAT/capacity" ] && echo "$KBD_BAT"
    return
  fi
  for d in "$PS"/*; do
    [ "$(cat "$d/type" 2>/dev/null)" = "Battery" ] || continue
    if [ "$(cat "$d/model_name" 2>/dev/null)" = "$NAME" ]; then
      echo "$d"
      return
    fi
  done
}

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
  bat=$(find_node)
  cap=
  status=
  if [ -n "$bat" ]; then
    cap=$(cat "$bat/capacity" 2>/dev/null)
    status=$(cat "$bat/status" 2>/dev/null)
  fi

  if [ "$cap" != "0" ]; then
    zero_since=0
  fi

  if [ -z "$cap" ]; then
    # keyboard off / wired: nothing to watch, re-arm for next connect
    last_level=-1
    zero_noticed=0
  elif [ "$cap" -eq 0 ] || [ "$status" = "Unknown" ]; then
    # placeholder before the first battery report, not a real reading, unless it never changes
    if [ "$cap" -eq 0 ] && [ "$ZERO_NOTICE" -gt 0 ] && [ "$zero_noticed" -eq 0 ]; then
      now=$(date +%s)
      [ "$zero_since" -eq 0 ] && zero_since=$now
      if [ $((now - zero_since)) -ge $((ZERO_NOTICE * 60)) ]; then
        notify low "$NAME has read 0% for ${ZERO_NOTICE} minutes: charge it, or it is not reporting its battery" "battery-missing"
        zero_noticed=1
      fi
    fi
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
