#!/usr/bin/env bash
mkdir initrd-tmp
cd initrd-tmp
gzip -dc -S .lz ../initrd.lz | cpio -id
#after modifications
#add a way to add latest plymouth here
find . | cpio --quiet --dereference -o -H newc | lzma -7 > ../new-initrd.lz
cd ..
#rm -rf initrd-tmp
