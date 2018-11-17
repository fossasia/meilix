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

cat /usr/share/applications/defaults.list | grep video

# use xdg-mime to set default mimetype(s)

# ---- no debs in home or root ----
# Check for leftovers from the install

[ -f ~/*.deb ] && echo "deb package should not be in home folder" || echo "ok."
[ -f /*.deb ] && echo "deb package should not be in root" || echo "ok."


## Other

xdg-settings --list

update-alternatives --display x-session-manager
update-alternatives --get-selections 

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

# What files are installed by LXQT?
apt-get install apt-file
apt-file update
apt-file list lxqt

# Just for Test purposes

#cat conf/arch.conf
#cat conf/uuid.conf
#cat conf/initramfs.conf
#cat conf/conf.d
#cat conf/modules

ls /usr/share/xsessions/ 
echo passphrase section
ls /usr/share/initramfs-tools/scripts/casper
ls /usr/share/initramfs-tools/scripts/casper-bottom/
echo Skript 25
less /usr/share/initramfs-tools/scripts/casper-bottom/25adduser
echo Skript 15
cat /usr/share/initramfs-tools/scripts/casper-bottom/15autologin
echo end passphrase section

# passwords of user accounts 
passwd --all -S
cat /etc/passwd
id -u


echo end Meilix_check script
