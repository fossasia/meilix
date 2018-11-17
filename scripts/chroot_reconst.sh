#!/bin/bash
# Minimimal chroot file for a reconstruction of meilix
# 14 Nov 18 v.0.1 first minimal try
# 15 Nov 18 v.0.2 let's exmperiment

sudo chroot chroot <<EOF
# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
export TTY=unknown
export TERM=vt100
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

# To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Installing wget
apt-get install wget apt-transport-https

# Add key for third party repo
apt-key update 
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1EBD81D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 91E7EE5E

# Update in-chroot package database
apt-get -qq update

# Install core packages
apt-get -qq -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

# Install base packages
#apt-get -qq -y install xorg lightdm  
apt-get -qq -y install xorg xinit sddm
# Install LXQT components
apt-get -qq -y install lxqt openbox 
apt-get -f install
update-alternatives --display x-session-manager

update-alternatives --install /usr/bin/x-session-manager x-session-manager /usr/bin/startlxqt 140
#update-alternatives --set x-session-manager /usr/bin/lxqt-session
#ugly hack
sed -i 's\plasma.desktop\lxqt.desktop\g' /usr/share/initramfs-tools/scripts/casper-bottom/15autologin
update-initramfs -u

# Meilix Check Skript
chmod +x meilix_check.sh
./meilix_check.sh

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

exit
EOF
