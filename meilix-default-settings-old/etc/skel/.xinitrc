# systemd fix see https://github.com/lxqt/lxqt/wiki/ConfigLaunch
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

exec startlxqt
