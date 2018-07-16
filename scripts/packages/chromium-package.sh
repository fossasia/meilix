#!/bin/bash
if echo "$GENERATOR_package_chromium" | grep -q chromium; then 
sudo apt-get install -q -y chromium; fi
