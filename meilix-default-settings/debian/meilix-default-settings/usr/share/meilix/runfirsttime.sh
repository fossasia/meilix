file="$HOME/.runfirst"
mozilla="$HOME/.mozilla"
input="[m17n:km:yannis,pinyin,m17n:fr:azerty,anthy,m17n:lo:kbd,m17n:ru:kbd,m17n:sd:inscript,m17n:sv:post,m17n:th:kesmanee,Unikey]"
desktop="$HOME/Desktop"
if [ ! -f $file ]; then
	touch "$HOME/.runfirst"
	im-switch -s ibus
	gconftool --set /desktop/ibus/general/preload_engine_mode --type int 0
	#gconftool --set /desktop/ibus/general/use_global_engine --type bool true
	gconftool --set /desktop/ibus/general/use_system_keyboard_layout --type bool true
	gconftool --set /desktop/ibus/panel/show_im_name --type bool true
	gconftool --set /desktop/ibus/general/preload_engines --type list --list-type string "$input"
	#if [ ! -d $mozilla ]; then
	#	mkdir $HOME/.mozilla
	#fi	
	#cp -r /usr/share/hotelos/firefox $HOME/.mozilla/firefox
	if [ ! -d $desktop ]; then
		mkdir $HOME/Desktop
	fi
	cp --preserve=timestamps /usr/share/meilix/Desktop/computer.desktop $HOME/Desktop
	cp --preserve=timestamps /usr/share/meilix/Desktop/trash.desktop $HOME/Desktop
	cp --preserve=timestamps /usr/share/meilix/Desktop/chromium-browser.desktop  $HOME/Desktop	
	cp --preserve=timestamps /usr/share/meilix/Desktop/libreoffice-writer.desktop $HOME/Desktop
	cp --preserve=timestamps /usr/share/meilix/Desktop/libreoffice-impress.desktop $HOME/Desktop
	cp --preserve=timestamps /usr/share/meilix/Desktop/libreoffice-calc.desktop $HOME/Desktop	
	cp --preserve=timestamps /usr/share/meilix/Desktop/pidgin.desktop  $HOME/Desktop/
	cp --preserve=timestamps /usr/share/meilix/Desktop/skype.desktop  $HOME/Desktop
	cp --preserve=timestamps /usr/share/meilix/Desktop/vlc.desktop $HOME/Desktop
fi
