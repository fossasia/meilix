# This switch offs system sounds
sed -i 's\# set bell-style none\set bell-style none\g' /etc/inputrc
sed -i '$ a xset -b' /etc/X11/Xsession