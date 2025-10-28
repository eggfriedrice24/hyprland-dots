#!/usr/bin/env sh
# Battery watcher using acpi + dunst
# Thresholds: caution <35%, critical <25%. Only fires when discharging.

TAG="notifybat"
RID=91234
CHECK_EVERY=60
last_level=-1

get_percent() {
  acpi -b 2>/dev/null \
    | awk -F', ' '/Battery/ { gsub("%","",$2); print $2 }' \
    | sort -n | head -n1
}

get_status() {
  acpi -b 2>/dev/null | awk -F', ' '/Battery/ {print $1}' | awk -F': ' 'NR==1{print $2}'
}

on_ac() {
  ac=$(acpi -a 2>/dev/null | awk -F': ' 'NR==1{print $2}')
  [ "$ac" = "on-line" ]
}

notify() {
  level="$1"
  urgency="$2"
  msg="$3"
  icon="$4"

  dunstify -a "Battery" -i "$icon" -u "$urgency" \
    -h string:x-dunst-stack-tag:$TAG \
    -r $RID \
    "$msg"
}

while :; do
  cap=$(get_percent)
  [ -z "$cap" ] && cap=100

  status=$(get_status)

  if [ "$status" = "Discharging" ] && ! on_ac; then
    if   [ "$cap" -lt 25 ] && [ "$last_level" -ne 25 ]; then
      notify "$cap" critical "Battery critical: ${cap}%" "battery-empty"
      last_level=25
    elif [ "$cap" -lt 35 ] && [ "$last_level" -ne 35 ]; then
      notify "$cap" normal "Battery low: ${cap}%" "battery-caution"
      last_level=35
    elif [ "$cap" -gt 40 ]; then
      last_level=-1
    fi
  else
    last_level=-1
  fi

  sleep "$CHECK_EVERY"
done

