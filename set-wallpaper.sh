#!/usr/bin/env bash
#wallpaper downloading
set -e
url_wallpaper="https://meilix-generator.herokuapp.com/uploads/wallpaper" # url heroku wallpaper 
wget -N --quiet $url_wallpaper

#renaming wallpaper according to extension png or jpg 
for f in wallpaper; do 
    type=$( file "$f" | grep -oP '\w+(?= image data)' )
    case $type in  
        PNG)  newext=png ;; 
        JPEG) newext=jpg ;; 
        *)    echo "??? what is this: $f"; continue ;; 
    esac
    mv "$f" "${f%.*}.$newext"
done

#setting wallpaper
wall=$(ls wallpaper.*)
pcmanfm-qt --set-wallpaper ${wall} --wallpaper-mode=scaled

