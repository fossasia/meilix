#!/bin/bash
# Installing chromium 32 bit or 64 bit browser 
if [ "$arch" == "i386" ];
then 
sudo apt-get -qq -y install chromium-browser:i386
else 
sudo apt-get -qq -y install chromium-browser
fi