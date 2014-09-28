#!/bin/bash

# =============================================
#  Dafturn Ofris Erdana - Locking your Systems
# =============================================
# Version       : 1.9.05-en
# Created by    : Dafturn Group Software
#                 The Mad Transition
# Author        : Muhammad Faruq Nuruddinsyah
# E-Mail        : faruq_dafturn@yahoo.co.id
# Date Creating : October, 12th 2008
# =============================================
# An Open Source from Indonesia
# =============================================



#----- Script utama -----------------------------
is_success=true
ofris_user=""

grep -v "sudo rsync -a --delete /etc/" /etc/rc.local > ofris_tmp
set $(wc -l ofris_tmp)
ofris_orig=$1
set $(wc -l /etc/rc.local)
ofris_recnt=$1
ofris_rst=$[$ofris_recnt-$ofris_orig]
rm ofris_tmp


#----- Mengunci sistem -----
echo 
echo "===== Freeze the System ====="
echo 
echo "Please wait..."
echo 

if [ $ofris_rst = 1 ]; then 
echo "Error : The system has been locked, please select the fourth choice to unfreeze the system..."
echo 
is_success=false
else
grep -v "exit 0" /etc/rc.local > ofris_tmp
echo "sudo rsync -a --delete /etc/.ofris/$ofris_user/ /home/$ofris_user/" >> ofris_tmp
echo "exit 0" >> ofris_tmp
sudo rm /etc/rc.local
sudo cp ofris_tmp /etc/rc.local
rm ofris_tmp
fi

if [ $is_success = true ]; then
if [ -d /etc/.ofris ]; then
sudo rm -r /etc/.ofris
fi
if [ -d /etc/.ofris ]; then
sudo rsync -a --delete /home/$ofris_user /etc/.ofris/
else
sudo mkdir /etc/.ofris/
if [ $ofris_user != "" ]; then
sudo mkdir /etc/.ofris/$ofris_user
fi
sudo rsync -a --delete /home/$ofris_user /etc/.ofris/
fi
sudo chmod +x /etc/rc.local
fi

if [ $is_success = true ]; then
sudo reboot
fi

