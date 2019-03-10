#!/bin/bash
# Minimimal chroot file for a reconstruction of meilix
# 14 Nov 18 v.0.1 first minimal try
# 15 Nov 18 v.0.2 let's exmperiment
# 17 Nov 18 v.0.3 We have a desktop
# 18 Nov 18 v.0.4 Let's try to change the default user
# 19 Nov 18 v.0.5 Fix Plymouth installation

sudo chroot chroot <<EOF
# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
#export USERNAME=meilix
export TTY=unknown
export TERM=vt100
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

# This solves the setting up of locale problem for chroot
sudo locale-gen en_US.UTF-8

# To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Installing wget
apt-get -qq install wget apt-transport-https

# Add key for third party repo
apt-key update
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1EBD81D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 91E7EE5E

# Update in-chroot package database
apt-get -qq update
apt-get -qq -y upgrade

# Install core packages
apt-get -qq -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

# Install base packages
#apt-get -qq -y install xorg lightdm
apt-get -qq -y install xorg xinit sddm
# Install LXQT components
apt-get -qq -y install lxqt openbox
apt-get -f -qq install
update-alternatives --install /usr/bin/x-session-manager x-session-manager /usr/bin/startlxqt 140
# ugly hack
sed -i 's\plasma.desktop\lxqt.desktop\g' /usr/share/initramfs-tools/scripts/casper-bottom/15autologin
#While this is necessary for the changes to take effect we don't have to do that here.
update-initramfs -c -k -v all

# cat /usr/share/xsessions/plasma.desktop
rm  /usr/share/xsessions/plasma.desktop
# ugliest hack ever
cp  /usr/share/xsessions/lxqt.desktop /usr/share/xsessions/plasma.desktop

# Remove screensaver
apt-get -qq -y remove xscreensaver

# plymouth boot splash

# Installing 
apt-get -qq -y install git


# Installing sublime text editor
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
apt-get -qq update
apt-get -qq -y install sublime-text

# Installing related softwares
chmod +x ./*.sh
./*.sh

# Installing Firefox
apt-get -qq -y install firefox

# Installing VLC media player
apt-get -qq -y install vlc
rm /usr/share/applications/mpv.desktop
rm /usr/share/applications/smplayer.desktop
rm /usr/share/applications/smtube.desktop
rm /usr/share/applications/audacious.desktop

# after Xenial one could also use apt install ./package
dpkg -i plymouth-theme-meilix-text_1.0-2_all.deb; apt-get -qq -y -f install; dpkg -i plymouth-theme-meilix-text_1.0-2_all.deb
dpkg -i plymouth-theme-meilix-logo_1.0-2_all.deb
dpkg -i meilix-default-theme_1.0-2_all.deb
dpkg -i systemlock_0.1-1_all.deb

# Remove the "LXQT about" entry from the menu
# /usr/share/applications/lxqt-about.desktop
# or ~/.local/usr/share override (in skel!)
# set the option NoDisplay=true
cat /usr/share/applications/lxqt-about.desktop
sed -i '$ a NoDisplay=true' /usr/share/applications/lxqt-about.desktop
cat /usr/share/applications/lxqt-about.desktop

# Switching off screen dimming
echo -ne "\033[9;0]" >> /etc/issue
setterm -blank 0 >> /etc/issue
# Meilix default settings
dpkg -i --force-overwrite meilix-default-settings_1.0_all.deb

# Clean up the chroot before
perl -i -nle 'print unless /^Package: language-(pack|support)/ .. /^$/;' /var/lib/apt/extended_states
apt-get -qq clean
rm -rf /tmp/*
#rm /etc/resolv.conf

# Clean up local packages that are not needed anymore
rm -f meilix-default-settings_1.0_all.deb
rm -f meilix-metapackage_1.0-1_all.deb
rm -f systemlock_0.1-1_all.deb
rm -f plymouth-theme-meilix-logo_1.0-2_all.deb
rm -f plymouth-theme-meilix-text_1.0-2_all.deb
rm -f meilix-default-theme_1.0-2_all.deb
rm -f systemlock_0.1-1_all.deb

# Meilix Check Skript
chmod +x meilix_check.sh
./meilix_check.sh

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

exit
EOF
