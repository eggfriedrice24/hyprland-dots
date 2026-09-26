#!/usr/bin/env sh
# Volume control with a dunst progress notification (icons come from the icon theme)

tagVol="notifyvol"

notify_vol() {
    vol=$(pamixer --get-volume)
    sink=$(pamixer --get-default-sink | tail -1 | rev | cut -d '"' -f -2 | rev | sed 's/"//')
    mute=$(pamixer --get-mute)

    if [ "$mute" = "true" ]; then
        ico="audio-volume-muted-symbolic"
    elif [ "$vol" -ge 66 ]; then
        ico="audio-volume-high-symbolic"
    elif [ "$vol" -ge 33 ]; then
        ico="audio-volume-medium-symbolic"
    else
        ico="audio-volume-low-symbolic"
    fi

    if [ "$mute" = "true" ]; then
        dunstify "Muted" -i "$ico" -a "$sink" -u low -r 91190 -t 800
    else
        dunstify -i "$ico" -a "$sink" -u low -h string:x-dunst-stack-tag:$tagVol \
            -h int:value:"$vol" "Volume: ${vol}%" -r 91190 -t 800
    fi
}

case $1 in
    i) pactl set-sink-volume @DEFAULT_SINK@ +5%
        notify_vol
        ;;
    d) pactl set-sink-volume @DEFAULT_SINK@ -5%
        notify_vol
        ;;
    m) pactl set-sink-mute @DEFAULT_SINK@ toggle
        notify_vol
        ;;
    *) echo "volumecontrol.sh [action]"
        echo "i -- increase volume [+5]"
        echo "d -- decrease volume [-5]"
        echo "m -- mute [x]"
        ;;
esac
