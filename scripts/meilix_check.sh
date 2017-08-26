#!/bin/bash
# A script to provide some raw info about a running meilix system
# please expand

# ----- Version -----
lsb_release -a

# ----- Default Browser ------
# Expected: Chromium

readlink -f /usr/bin/x-www-browser
update-alternatives --display x-www-browser 

# set it via "sudo update-alternatives --set x-www-browser" etc. 

# ----- default file associations for Video -----
# Expected VLC

cat /usr/share/applications/defaults.list | grep video

# use xdg-mime to set default mimetype(s)

# ---- no debs in home or root ----
# Check for leftovers from the install

[ -f ~/*.deb ] && echo "deb package should not be in home folder" || echo "ok."
[ -f /*.deb ] && echo "deb package should not be in root" || echo "ok."

# Plymouth themes
ls /usr/share/plymouth/themes # show us which themes we have
# show us the plymouth meilix-logo folder
ls /usr/share/plymouth/themes/meilix-logo/
ls -l |grep .plymouth
