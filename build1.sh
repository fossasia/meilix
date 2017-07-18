#!/usr/bin/env bash
#packages required to edit
sudo apt-get install -qq squashfs-tools genisoimage
#downloading the ISO to edit
wget -q https://github.com/fossasia/meilix/releases/download/untagged-c9f68d2fa6b3d1cdbd99/meilix-zesty-20170611-i386.iso
#exit on any error
set -e

mkdir mnt
#Mount the ISO 
sudo mount -o loop meilix-zesty-20170611-i386.iso mnt/
#Extract .iso contents into dir 'extract-cd' 
mkdir extract-cd
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd
#Extract the SquashFS filesystem 
sudo unsquashfs -n mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit

#test value of env variable
echo $TRAVIS_SCRIPT

export $TRAVIS_SCRIPT
sudo su <<EOF
echo "$TRAVIS_SCRIPT" > edit/meilix-generator.sh
EOF

#prepare chroot
sudo mount -o bind /run/ edit/run
sudo cp /etc/hosts edit/etc/
sudo mount --bind /dev/ edit/dev

sudo chroot edit <<EOF

# execute environment variable
ls # to test the files if any new file is added
chmod +x meilix-generator.sh
echo "$(<meilix-generator.sh)" #to test the file
./meilix-generator.sh
rm meilix-generator.sh
#delete temporary files 
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
