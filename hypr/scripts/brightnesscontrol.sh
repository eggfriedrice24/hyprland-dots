#!/usr/bin/env sh

tagBri="notifybri"
step=5

backlight=$(ls /sys/class/backlight/ 2>/dev/null | head -n1)

function notify_bri {
    local percent=$1
    [ -z "$percent" ] && return

    angle="$(( ((percent+5)/10) * 10 ))"
    ico="$HOME/.config/dunst/iconbri/bri-${angle}.svg"

    dunstify -i "$ico" -a "Brightness" -u low \
      -h string:x-dunst-stack-tag:$tagBri \
      -h int:value:"$percent" "Brightness: ${percent}%" -r 91191 -t 800
}

if [ -n "$backlight" ]; then
    case $1 in
        i) brightnessctl -q s +${step}% ;;
        d) brightnessctl -q s ${step}%- ;;
    esac
    bri=$(brightnessctl g)
    max=$(brightnessctl m)
    percent=$(( 100 * bri / max ))
    notify_bri "$percent"
else
    (
        case $1 in
            i) ddcutil -b 7 --noverify setvcp 10 + $step ;;
            d) ddcutil -b 7 --noverify setvcp 10 - $step ;;
        esac
        percent=$(ddcutil -b 7 --brief getvcp 10 2>/dev/null | awk '{print $4}')
        notify_bri "$percent"
    ) &
fi
