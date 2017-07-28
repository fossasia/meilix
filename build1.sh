#!/usr/bin/env bash
#packages required to edit
sudo apt-get install -qq squashfs-tools genisoimage
#downloading the ISO to edit
wget -q https://github.com/fossasia/meilix/releases/download/untagged-ef2fd636a53f4d0268cb/meilix-zesty-20170721-i386.iso
mv *.iso meilix-original.iso
#exit on any error
set -e

mkdir mnt
#Mount the ISO 
sudo mount -o loop meilix-original.iso mnt/
#Extract .iso contents into dir 'extract-cd' 
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
#Extract the SquashFS filesystem 
sudo unsquashfs -n mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit

#test value of env variable
echo $TRAVIS_SCRIPT

sudo su <<EOF
echo "$TRAVIS_SCRIPT" > edit/meilix-generator.sh
mv browser.sh edit/browser.sh
EOF

#moving browser script to edit

#prepare chroot
sudo mount -o bind /run/ edit/run
sudo cp /etc/hosts edit/etc/
sudo mount --bind /dev/ edit/dev

#moving the script to chroot
sudo mv set-wallpaper.sh edit/set-wallpaper.sh

sudo chroot edit <<EOF

# execute environment variable
ls # to test the files if any new file is added
chmod +x meilix-generator.sh browser.sh
echo "$(<meilix-generator.sh)" #to test the file
./meilix-generator.sh
rm meilix-generator.sh
./browser.sh
rm browser.sh

chmod +x set-wallpaper.sh && ./set-wallpaper.sh
#delete temporary files 
rm meilix-generator.sh
rm -rf /tmp/* ~/.bash_history
exit
EOF
sudo umount edit/dev
#repacking
sudo chmod +w extract-cd/casper/filesystem.manifest
sudo su <<HERE
chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest <<EOF
exit
EOF
HERE
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop
#sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs -noappend
echo ">>> Recomputing MD5 sums"
sudo su <<HERE
( cd extract-cd/ && find . -type f -not -name md5sum.txt -not -path '*/isolinux/*' -print0 | xargs -0 -- md5sum > md5sum.txt )
exit
HERE
cd extract-cd 	

sudo mkisofs \
    -V "Custom Meilix" \
    -r -cache-inodes -J -l \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
	-o ../meilix-i386-custom.iso .
