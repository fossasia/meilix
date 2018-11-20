#!/bin/bash
set -x
# A script to provide some raw info about a running meilix system
# please expand

echo Meilix_check - raw info about your configuration

# ----- Version -----
lsb_release -a

# ----- Default Browser ------
# Expected: Chromium

readlink -f /usr/bin/x-www-browser
update-alternatives --display x-www-browser 

# set it via "sudo update-alternatives --set x-www-browser" etc. 

# ----- default file associations for Video -----
# Expected VLC

#cat /usr/share/applications/defaults.list | grep video

# use xdg-mime to set default mimetype(s)

# ---- no debs in home or root ----
# Check for leftovers from the install

[ -f ~/*.deb ] && echo "deb package should not be in home folder" || echo "ok."
[ -f /*.deb ] && echo "deb package should not be in root" || echo "ok."


## Other

xdg-settings --list

update-alternatives --display x-session-manager
update-alternatives --get-selections 

#does not exist
#cat /usr/share/lxqt/session.conf
cat /etc/xdg/lxqt/session.conf
cat /etc/xdg/lxqt/lxqt.conf
cat /etc/xdg/lxqt/windowmanagers.conf
cat /etc/xdg/pcmanfm-qt/lxqt/settings.conf
cat /usr/share/xsessions/lxqt.desktop
ls /usr/share/lxqt

# Plymouth themes
ls /usr/share/plymouth/themes # show us which themes we have
# show us the plymouth meilix-logo folder
ls /usr/share/plymouth/themes/meilix-logo/
ls -l |grep .plymouth


# startup 
ls /usr/share/xsessions/  
cat /usr/share/xsessions/lxqt.desktop
ls /usr/local/share/xsessions

# Do lxsession files exist?
ls /usr/bin/lx*

# Just for Test purposes

ls conf
#cat conf/arch.conf
#cat conf/uuid.conf
#cat conf/initramfs.conf
#cat conf/conf.d
#cat conf/modules

ls /usr/share/xsessions/ 
echo passphrase section
cat /usr/share/initramfs-tools/scripts/casper
ls /usr/share/initramfs-tools/scripts/casper-bottom/
less /etc/casper.conf

less /usr/share/initramfs-tools/scripts/casper-bottom/25adduser
less /usr/share/initramfs-tools/scripts/casper-bottom/24preseed
cat /usr/share/initramfs-tools/scripts/casper-bottom/15autologin
echo end passphrase section

# passwords of user accounts 
passwd --all -S
cat /etc/passwd
id -u


echo end Meilix_check script
