#!/usr/bin/env sh

tagBri="notifybri"
step=5

notify_bri() {
    percent=$1
    [ -z "$percent" ] && return

    angle="$(( ((percent + 5) / 10) * 10 ))"
    ico="$HOME/.config/dunst/iconbri/bri-${angle}.svg"

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
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null
}

ddc_bus_for_monitor() {
    monitor=$1

    ddcutil detect --brief 2>/dev/null | awk -v monitor="$monitor" '
        $1 == "I2C" && $2 == "bus:" { bus = $3 }
        $1 == "DRM" && $2 == "connector:" && $3 ~ ("-" monitor "$") {
            sub(".*/i2c-", "", bus)
            print bus
            exit
        }
    '
}

set_backlight() {
    case $1 in
        i) brightnessctl -q s +${step}% ;;
        d) brightnessctl -q s ${step}%- ;;
    esac

    bri=$(brightnessctl g)
    max=$(brightnessctl m)
    percent=$(( 100 * bri / max ))
    notify_bri "$percent"
}

set_ddc_brightness() {
    monitor=$1
    bus=$(ddc_bus_for_monitor "$monitor")

    if [ -z "$bus" ]; then
        notify_error "Brightness: no DDC bus for ${monitor}"
        return 1
    fi

    case $2 in
        i) ddcutil -b "$bus" --noverify setvcp 10 + "$step" ;;
        d) ddcutil -b "$bus" --noverify setvcp 10 - "$step" ;;
    esac

    percent=$(ddcutil -b "$bus" --brief getvcp 10 2>/dev/null | awk '{print $4}')
    notify_bri "$percent"
}

monitor=$(focused_monitor)
backlight=$(ls /sys/class/backlight/ 2>/dev/null | head -n1)

case $monitor in
    eDP-*|LVDS-*)
        if [ -n "$backlight" ]; then
            set_backlight "$1"
            exit
        fi
        ;;
esac

if [ -n "$monitor" ]; then
    ( set_ddc_brightness "$monitor" "$1" ) &
elif [ -n "$backlight" ]; then
    set_backlight "$1"
fi
