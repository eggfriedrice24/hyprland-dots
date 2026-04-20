#!/bin/bash
awww img `find $wallpaper_path -type f | shuf -n 1` --transition-type any --transition-fps 60
