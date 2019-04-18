# Switching off screen dimming
echo -ne "\033[9;0]" >> /etc/issue
setterm -blank 0 >> /etc/issue
