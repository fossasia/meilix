#!/bin/bash
# lxgames-build.sh -- creates an LXgames LiveCD ISO, based on lubuntu-build.sh
# Author: Team
# Based heavily on HOWTO information by
#   Julien Lavergne <gilir@ubuntu.com>
# Version: 20110303

set -eu				# Be strict

# Script parameters: arch mirror gnomelanguage release
# Arch to build ISO for, i386 or amd64
arch=${1:-i386}
# Ubuntu mirror to use
mirror=${2:-"http://archive.ubuntu.com/ubuntu/"}
# Set of GNOME language packs to install.
#   Use '\*' for all langs, 'en' for English.
# Install language with the most popcon
gnomelanguage=${3:-'{en}'}	#
# Release name, used by debootstrap.  Examples: lucid, maverick, natty.
release=${4:-zesty}

# Necessary data files
datafiles="image-${arch}.tar.lzma sources.list"
# Necessary development tool packages to be installed on build host
devtools="debootstrap genisoimage p7zip-full squashfs-tools ubuntu-dev-tools"

# Make sure we have the data files we need
for i in $datafiles
do
  if [ ! -f $i ]; then
    echo "$0: ERROR: data file `pwd`/$i not found"
    exit 1
  fi
done

# Make sure we have the tools we need installed
sudo apt-get -q install $devtools -y --no-install-recommends
sudo apt-get update
sudo apt-get install dpkg-dev debhelper fakeroot

#Debuilding the metapackages
chmod +x debuild.sh
sudo ./debuild.sh

# Create and populate the chroot using debootstrap
[ -d chroot ] && sudo rm -R chroot/
# Debootstrap outputs a lot of 'Information' lines, which can be ignored
sudo debootstrap --arch=${arch} ${release} chroot ${mirror} # 2>&1 |grep -v "^I: "
# Use /etc/resolv.conf from the host machine during the build
sudo cp -vr /etc/resolvconf chroot/etc/resolvconf

# Copy the source.list to enable universe / multiverse in the chroot, and eventually additional repos.
sudo cp -v sources.list chroot/etc/apt/sources.list
sudo cp -v meilix-default-settings_*_all.deb chroot
sudo cp -v systemlock_*_all.deb chroot
sudo cp -v plymouth-meilix-logo_*_all.deb chroot
sudo cp -v plymouth-meilix-text_*_all.deb chroot
sudo cp -v meilix-metapackage_*_all.deb chroot
sudo cp -v skype-ubuntu_*_i386.deb chroot
sudo cp -v meilix-imclient_*_all.deb chroot

# Mount needed pseudo-filesystems
sudo mount --rbind /sys chroot/sys
sudo mount --rbind /dev chroot/dev
sudo mount -t proc none chroot/proc

# Work *inside* the chroot
sudo chroot chroot <<EOF
# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
export TTY=unknown
export TERM=vt100
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

#  To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Add key for third party repo
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1EBD81D9
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 91E7EE5E

# Update in-chroot package database
apt-get -q update

# Install core packages
apt-get -q -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

dpkg -i meilix-metapackage*.deb
apt-get install -f

# Install base packages
apt-get install -q -y xorg sddm lxqt

# Plymouth theme
dpkg -i plymouth-meilix-logo_1.0-1_all.deb plymouth-meilix-text_1.0-1_all.deb
apt-get install -f

# Power manager for laptop
apt-get -q -y --purge install xfce4-power-manager
# Fix chromium install problem
 mv /etc/chromium-browser/ /etc/chromium-browser_

# Archive Manager
apt-get -q -y --purge install file-roller unrar

# lubuntu-restricted-extras
apt-get -q -y --purge install lubuntu-restricted-extras

# Install specific packages
apt-get -q -y -o Dpkg::Options::="--force-overwrite" --purge install chromium-browser

#rm -rf /etc/chromium-browser
mv /etc/chromium-browser_ /etc/chromium-browser

# Install lxrandr to change monitor settings
apt-get -q -y --purge install lxrandr

# Install Internet packages
apt-get -q -y --purge install flashplugin-installer google-talkplugin pidgin galculator \
  gpicview evince libqtwebkit4
dpkg -i -y --purge install skype-ubuntu_4.1.0.20-1_i386.deb

# Install graphic
apt-get -q -y --purge install gimp inkscape
apt-get -q -y --purge remove imagemagick

# Install Libreoffice
apt-get -q -y --purge install --no-install-recommends libreoffice-gtk libreoffice-gtk libreoffice-writer libreoffice-calc libreoffice-impress

# Install imclient
dpkg -i meilix-imclient_*_all.deb
apt-get install -f

#screen-dimming turns off always
echo -ne "\033[9;0]" >> /etc/issue

# Install Google-Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
apt-get update
apt-get install google-chrome-stable

#Install vlc
apt-get -q -y install vlc

#Instal dropbox
apt-get -q -y install nautilus-dropbox
nautilus --quit

#Install git
apt-get -q -y install git

#install icons for pcmanfm
apt-get -q -y install oxygen-icon-theme

#Install text editor
apt-get -q -y install gedit

#Google custom ad
apt-get -q -y --purge install mygoad
#Install East Asia font
apt-get -q -y --purge install ttf-arphic-uming ttf-wqy-zenhei ttf-sazanami-mincho ttf-sazanami-gothic ttf-unfonts-core
# Install languages packs
apt-get -q -y --purge install language-pack-zh-hans language-pack-ja
apt-get -q -y --purge install language-pack-gnome-en
# Install ibus
apt-get -q -y --purge install ibus ibus-clutter ibus-gtk ibus-gtk3 ibus-qt4
apt-get -q -y --purge install ibus-unikey ibus-anthy ibus-pinyin ibus-m17n
apt-get -q -y --purge install im-switch

#Hotel OS default settings
#apt-get download hotelos-default-settings
dpkg -i --force-overwrite meilix-default-settings_1.0_all.deb
update-initramfs -u
dpkg -i --force-overwrite systemlock_0.1-1_all.deb
apt-get install -f
apt-get -q -y remove dconf-tools
# Clean up the chroot before
perl -i -nle 'print unless /^Package: language-(pack|support)/ .. /^$/;' /var/lib/apt/extended_states
apt-get clean
rm -rf /tmp/*
#rm /etc/resolv.conf
rm meilix-default-settings_1.0_all.deb
rm systemlock_0.1-1_all.deb plymouth-meilix-logo_1.0-1_all.deb plymouth-meilix-text_1.0-1_all.deb skype-ubuntu_4.1.0.20-1_i386.deb
rm meilix-imclient_*_all.deb

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

exit
EOF

###############################################################
# Continue work outside the chroot, preparing image

# Unmount pseudo-filesystems
sudo umount -lfr chroot/proc
sudo umount -lfr chroot/sys
sudo umount -lfr chroot/dev

echo $0: Preparing image...

[ -d image ] && sudo /bin/rm -r image
tar xf image-${arch}.tar.lzma

# Copy the kernel from the chroot into the image for the LiveCD
sudo cp chroot/boot/vmlinuz-**-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-**-generic image/casper/initrd.lz

# Extract initrd and update uuid configuration
7z e image/casper/initrd.lz && \
  mkdir initrd_FILES/ && \
  mv initrd initrd_FILES/ && \
  cd initrd_FILES/ && \
  cpio -id < initrd && \
  cd .. && \
  cp initrd_FILES/conf/uuid.conf image/.disk/casper-uuid-generic && \
  rm -R initrd_FILES/

# Fix old version and date info in .hlp files
newversion="12.10"		# Should be derived from releasename $4 FIXME
for oldversion in 10.04 10.10 11.04 11.10 12.04
do
  sed -i -e "s/${oldversion}/${newversion}/g" image/isolinux/*.hlp image/isolinux/f1.txt
done
newdate=$(date -u +%Y%m%d)
for olddate in 20100113 20100928
do
  sed -i -e "s/${olddate}/${newdate}/g" image/isolinux/*.hlp image/isolinux/f1.txt
done

# Create filesystem manifests
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' >/tmp/manifest.$$
sudo cp -v /tmp/manifest.$$ image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
rm /tmp/manifest.$$

# Remove packages from filesystem.manifest-desktop
#  (language and extra for more hardware support)
REMOVE='gparted ubiquity ubiquity-frontend-gtk casper live-initramfs user-setup discover1
 xresprobe libdebian-installer4 pptp-linux ndiswrapper-utils-1.9
 ndisgtk linux-wlan-ng libatm1 setserial b43-fwcutter uterm
 linux-headers-generic indicator-session indicator-application
 language-pack-*'
for i in $REMOVE
do
    sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

# Now squash the live filesystem
echo "$0: Starting mksquashfs at $(date -u) ..."
sudo mksquashfs chroot image/casper/filesystem.squashfs -noappend -no-progress
echo "$0: Finished mksquashfs at $(date -u )"

# Generate md5sum.txt checksum file
cd image && sudo find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt

# Generate a small temporary ISO so we get an updated boot.cat
IMAGE_NAME=${IMAGE_NAME:-"Meilix ${release} $(date -u +%Y%m%d) - ${arch}"}
ISOFILE=meilix-${release}-$(date -u +%Y%m%d)-${arch}.iso
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --publisher "Meilix Packaging Team" \
  --volset "Ubuntu Linux http://www.ubuntu.com" \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -m filesystem.squashfs \
  -o ../$ISOFILE.tmp .

# Mount the temp ISO and copy boot.cat out of it
tempmount=/tmp/$0.tempmount.$$
mkdir $tempmount
loopdev=$(sudo losetup -f)
sudo losetup $loopdev ../$ISOFILE.tmp
sudo mount -r -t iso9660 $loopdev $tempmount
sudo cp -vp $tempmount/isolinux/boot.cat isolinux/
sudo umount $loopdev
sudo losetup -d $loopdev
rmdir $tempmount

# Generate md5sum.txt checksum file (now with new improved boot.cat)
sudo find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt

# Remove temp ISO file
sudo rm ../$ISOFILE.tmp

# Create an Meilix ISO from the image directory tree
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -allow-limited-size -udf \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --publisher "Meilix Packaging Team" \
  --volset "Ubuntu Linux http://www.ubuntu.com" \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -o ../$ISOFILE .

# Fix up ownership and permissions on newly created ISO file
sudo chown $USER:$USER ../$ISOFILE
chmod 0444 ../$ISOFILE

# Create the associated md5sum file
cd ..
md5sum $ISOFILE >${ISOFILE}.md5
