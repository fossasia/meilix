grep -v "sudo rsync -a --delete /etc/" /etc/rc.local > ofris_tmp_b
sudo rm /etc/rc.local
sudo cp ofris_tmp_b /etc/rc.local
sudo rm ofris_tmp_b
if [ -d /etc/.ofris ]; then
sudo rm -r /etc/.ofris
fi
sudo reboot
