#!/bin/bash
# File includes some legacy hints on dealing with the compressed init ramdisk formats
# Debian provides some useful documentation on this.

# General info.

# 7z l image/casper/initrd.lz
# file image/casper/initrd.lz 
# lzcat -dS .lz image/casper/initrd.lz | cpio -iv
# which zcat
# which uncompress
# which cpio

# Legacy method:
# Extract initrd for case 1 (lz archive) and update uuid configuration
# file initrd.lz outputs gzip compressed data, last modified XYZ, from Unix
# see also 7z l image/casper/initrd.lz which displays initrd
# 7z e image/casper/initrd.lz && \
#  mkdir initrd_FILES/ && \
#  mv initrd initrd_FILES/ && \
#  cd initrd_FILES/ && \
#  cpio -id < initrd && \
#  cd .. && \
#  cp initrd_FILES/conf/uuid.conf image/.disk/casper-uuid-generic && \
#  rm -R initrd_FILES/

# For complex initrd case 2 (handled in build.sh)
# file initrd.lz outputs ASCII cpio archive (SVR4 with no CRC)
# when you extract ordinary you get a directory kernel and microcode image
# see also 7z l image/casper/initrd.lz which displays the block on top.
# (cpio -idvm; zcat | cpio -idvm) < initrd.lz
# should get you the actual initramdisc
# in the build.sh we use another method with a bitwalk dependency.
