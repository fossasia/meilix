#!/usr/bin/env bash
#wallpaper downloading
set -e
#fix this with help of base64 after testing
url_wallpaper="https://meilix-generator.herokuapp.com/uploads/wallpaper" # url heroku wallpaper 
wget -N --quiet $url_wallpaper
#converting wallpaper according to theme
convert wallpaper wallpaper.jpg
#changing theme wallpaper
mv /usr/share/lxqt/themes/meilix/wallpaper.jpg
