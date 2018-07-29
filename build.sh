#!/bin/bash
# build.sh -- creates an Meilix LiveCD ISO
# Author: Team
# Based on HOWTO information by Julien Lavergne <gilir@ubuntu.com>

set -eu				# Be strict

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Script parameters: arch mirror gnomelanguage release
# Arch to build ISO for, i386 or amd64
arch=${1:-i386}
# let's play 64bit
# arch=${1:-amd64}
# Ubuntu mirror to use
mirror=${2:-"http://archive.ubuntu.com/ubuntu/"}
# Set of GNOME language packs to install.
#   Use '\*' for all langs, 'en' for English.
# Install language with the most popcontt
gnomelanguage=${3:-'{en}'}	
# Release name, used by debootstrap.  Examples: lucid, maverick, natty.
release=${4:-xenial}

# Necessary data files
datafiles="image-${arch}.tar.lzma sources.list"
# Necessary development tool packages to be installed on build host
devtools="debootstrap genisoimage p7zip-full squashfs-tools ubuntu-dev-tools"

#url_wallpaper="https://meilix-generator.herokuapp.com/uploads/wallpaper" # url heroku wallpaper
#wget $url_wallpaper -P meilix-default-settings/usr/lxqt/themes/meilix/

# Make sure we have the data files we need
for i in $datafiles
do
  if [ ! -f $i ]; then
    echo "$0: ERROR: data file `pwd`/$i not found"
    exit 1
  fi
done

# Make sure we have the tools we need installed
sudo apt-get -qq update
sudo apt-get -qq install $devtools -y --no-install-recommends
sudo apt-get -qq install dpkg-dev debhelper fakeroot
sudo apt-get -qq install devscripts
sudo apt-get -qq install tree # for debugging

# Adding Mew to the Meilix
# chmod +x ./scripts/mew.sh
#./scripts/mew.sh
# create package of mew and use the package only instead of creating package here

# Debuilding the metapackages
chmod +x ./scripts/debuild.sh
./scripts/debuild.sh

# For debugging, just look what files are there
#tree -f

# Section end Metapackages debuild 
# Create and populate the chroot using debootstrap
echo Section Chroot

#TODO: document the line that follows
[ -d chroot ] && sudo rm -R chroot/
# Debootstrap installs a Linux in the chroot.
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

# Debug: show us what files are around in chroot
#ls -a chroot

# Mount needed pseudo-filesystems
sudo mount --rbind /sys chroot/sys
sudo mount --rbind /dev chroot/dev
sudo mount -t proc none chroot/proc

# Work *inside* the chroot
chmod +x ./scripts/chroot.sh
./scripts/chroot.sh
# Section chroot finished
###############################################################
# Continue work outside the chroot, preparing image

# ubiquity-slideshow slides, replace the installed ones
sudo cp -vr ubiquity-slideshow chroot/usr/share/

# Unmount pseudo-filesystems
sudo umount -lfr chroot/proc
sudo umount -lfr chroot/sys
sudo umount -lfr chroot/dev

echo $0: Preparing image...

#TODO: document the line that follows
[ -d image ] && sudo /bin/rm -r image
tar xvvf image-${arch}.tar.lzma

ls -a chroot/boot

# Copy the kernel from the chroot into the image for the LiveCD
sudo \cp --verbose -rf chroot/boot/vmlinuz-**-generic image/casper/vmlinuz
sudo \cp --verbose -rf chroot/boot/initrd.img-**-generic image/casper/initrd.lz

#echo debug, Check the contents
#7z l image/casper/initrd.lz#
file image/casper/initrd.lz 

# Extract initrd for complex for case 2 and update uuid configuration
# file initrd.lz outputs ASCII cpio archive (SVR4 with no CRC)
# see also 7z l image/casper/initrd.lz which displays a block on top.
  mkdir initrd_FILES
  cp image/casper/initrd.lz initrd_FILES/initrd.lz
  cd initrd_FILES
  ls
  (cpio -id; zcat | cpio -id) < initrd.lz 
  ls
  cd .. && \ 
  cp initrd_FILES/conf/uuid.conf image/.disk/casper-uuid-generic && \
  rm -R initrd_FILES/

# Extract initrd for case 1 (lz archive) and update uuid configuration
# file initrd.lz outputs gzip compressed data, last modified XYZ, from Unix
# see also 7z l image/casper/initrd.lz which displays initrd
#7z e image/casper/initrd.lz && \
#  mkdir initrd_FILES/ && \
#  mv initrd initrd_FILES/ && \
#  cd initrd_FILES/ && \
#  cpio -id < initrd && \
#  cd .. && \
#  cp initrd_FILES/conf/uuid.conf image/.disk/casper-uuid-generic && \
#  rm -R initrd_FILES/

# Fix old version and date info in .hlp files
newversion=$(date -u +%y.%m) 		# Should be derived from releasename $4 FIXME
for oldversion in 17.08
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

#This does not work instead. Why?
#sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' > image/casper/filesystem.manifest
#sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop

# Remove packages from filesystem.manifest-desktop
#  (language and extra for more hardware support)
REMOVE='gparted ubiquity ubiquity-frontend-gtk casper live-initramfs user-setup discover1
 xresprobe libdebian-installer4 pptp-linux ndiswrapper-utils-1.9
 ndisgtk linux-wlan-ng libatm1 setserial b43-fwcutter uterm
 linux-headers-generic indicator-session indicator-application' 
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

# USER debug
whoami
id -un
echo $USER


# Fix up ownership and permissions on newly created ISO file
sudo chown $USER:$USER ../$ISOFILE
chmod 0444 ../$ISOFILE

# Create the associated md5sum file
cd ..
md5sum $ISOFILE >${ISOFILE}.md5
