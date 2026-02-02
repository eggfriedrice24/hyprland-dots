#!/usr/bin/env sh

# Run ddcutil in background to prevent lag
# Use --noverify for speed (skip verification read)

step=5

case $1 in
    i) ddcutil --noverify setvcp 10 + $step & ;;
    d) ddcutil --noverify setvcp 10 - $step & ;;
    *) echo "ddcbrightness.sh [action]"
       echo "i -- increase brightness [+${step}%]"
       echo "d -- decrease brightness [-${step}%]"
    ;;
esac
