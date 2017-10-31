#!/bin/bash
sudo chroot chroot <<EOF
# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
export TTY=unknown
export TERM=vt100
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

apt-get purge lxqt-powermanagement
# To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Add key for third party repo
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1EBD81D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 91E7EE5E

# Update in-chroot package database
apt-get -qq update

# Install core packages
apt-get -qq -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

# Install meilix metapackage
dpkg -i meilix-metapackage*.deb
apt-get install -f

# Install base packages
apt-get -qq -y install xorg sddm lxqt

# Plymouth theme 
apt-get -qq -y install plymouth-label #dependency of our theme
dpkg -i plymouth-meilix-logo_1.0-1_all.deb plymouth-meilix-text_1.0-1_all.deb
apt-get install -f

ls /usr/share/plymouth/themes # show us which themes we have
# show us the plymouth meilix-logo folder
ls /usr/share/plymouth/themes/meilix-logo/
update-alternatives --verbose --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/meilix-logo/meilix-logo.plymouth 100
update-alternatives --verbose --install /usr/share/plymouth/themes/text.plymouth text.plymouth /usr/share/plymouth/themes/meilix-text/meilix-text.plymouth 99
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/meilix-logo/meilix-logo.plymouth 100
update-alternatives --verbose --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/meilix-logo/meilix-plymouth-theme.plymouth 100

update-alternatives --list text.plymouth
update-alternatives --list default.plymouth

update-alternatives --auto text.plymouth
update-alternatives --auto default.plymouth

#update-alternatives --skip-auto --config default.plymouth
update-initramfs -u # update initram
#update-initramfs -u -b /image/casper # update initram
update-initramfs -c -k all
#update-initramfs -c -k all -b /image/casper
ls /


# Fix chromium install problem
 mv /etc/chromium-browser/ /etc/chromium-browser_

# Archive Manager
apt-get -qq -y --purge install file-roller unrar

# lubuntu-restricted-extras
apt-get -qq -y --purge install lubuntu-restricted-extras

# Install specific packages
apt-get -qq -y -o Dpkg::Options::="--force-overwrite" --purge install chromium-browser

#rm -rf /etc/chromium-browser
mv /etc/chromium-browser_ /etc/chromium-browser

# Install lxrandr to change monitor settings
apt-get -qq -y --purge install lxrandr

# Install Internet packages
apt-get -qq -y --purge install flashplugin-installer google-talkplugin pidgin qpdfview libqtwebkit4

# Install local Skype 32Bit package
dpkg -i skype-ubuntu_4.1.0.20-1_i386.deb

# Install graphic
apt-get -qq -y --purge install gimp inkscape
apt-get -qq -y --purge remove imagemagick

# Install Libreoffice
apt-get -qq -y --purge install --no-install-recommends libreoffice-gtk libreoffice-gtk libreoffice-writer libreoffice-calc libreoffice-impress

# Install Instand Messanger
dpkg -i meilix-imclient_*_all.deb
apt-get install -f

#screen-dimming turns off always
echo -ne "\033[9;0]" >> /etc/issue
setterm -blank 0 >> /etc/issue

#Install vlc
apt-get -qq -y install vlc

#Instal dropbox
apt-get -qq -y install nautilus-dropbox
nautilus --quit

# Oxygen to be used as a fallback icon theme
apt-get -qq -y install oxygen-icon-theme

# Install text editor
apt-get -qq -y install kate

# Remove lxqt-powermanagement
apt-get -qq -y purge lxqt-powermanagement
apt-get -qq -y purge lxqt-powermanagement-l10n

#Google custom ad
apt-get -qq -y --purge install mygoad
#Install East Asia font
apt-get -qq -y --purge install ttf-arphic-uming ttf-wqy-zenhei ttf-sazanami-mincho ttf-sazanami-gothic ttf-unfonts-core
# Install languages packs
apt-get -qq -y --purge install language-pack-zh-hans language-pack-ja
apt-get -qq -y --purge install language-pack-gnome-en
# Install ibus
apt-get -qq -y --purge install ibus ibus-clutter ibus-gtk ibus-gtk3 ibus-qt4
apt-get -qq -y --purge install ibus-unikey ibus-anthy ibus-pinyin ibus-m17n
apt-get -qq -y --purge install im-switch

# Meilix default settings
dpkg -i --force-overwrite meilix-default-settings_1.0_all.deb
update-initramfs -u
dpkg -i --force-overwrite systemlock_0.1-1_all.deb
apt-get install -f
apt-get -qq -y remove dconf-tools

# Clean up the chroot before
perl -i -nle 'print unless /^Package: language-(pack|support)/ .. /^$/;' /var/lib/apt/extended_states
apt-get -qq clean
rm -rf /tmp/*
#rm /etc/resolv.conf
rm meilix-default-settings_1.0_all.deb
rm meilix-metapackage_1.0-1_all.deb
rm systemlock_0.1-1_all.deb plymouth-meilix-logo_1.0-1_all.deb plymouth-meilix-text_1.0-1_all.deb skype-ubuntu_4.1.0.20-1_i386.deb
rm meilix-imclient_*_all.deb

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

exit
EOF
