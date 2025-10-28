#!/usr/bin/env sh

tagBri="notifybri"

function notify_bri {
    bri=$(brightnessctl g)
    max=$(brightnessctl m)
    percent=$(( 100 * bri / max ))

    angle="$(( ((percent+5)/10) * 10 ))"
    ico="$HOME/.config/dunst/iconbri/bri-${angle}.svg"

    dunstify -i "$ico" -a "Brightness" -u low \
      -h string:x-dunst-stack-tag:$tagBri \
      -h int:value:"$percent" "Brightness: ${percent}%" -r 91191 -t 800
}

case $1 in
    i) brightnessctl s +5% && notify_bri ;;
    d) brightnessctl s 5%- && notify_bri ;;
    *) echo "brightnesscontrol.sh [action]"
       echo "i -- increase brightness [+5%]"
       echo "d -- decrease brightness [-5%]"
    ;;
esac
