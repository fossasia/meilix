#!/bin/bash
if echo "$GENERATOR_package_vlc" | grep -q vlc; then 
sudo apt-get install -q -y vlc; fi