# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# author - Harsh Lathwal aka xeon zolt (xeon.harsh@gmail.com)

# adding susi to firefox by adding the extension to the Meilix default settings
git clone https://github.com/fossasia/susi_firefoxbot
cd susi_firefoxbot/src
zip -r susi-firefox.xpi *
cd ..
cd ..
mkdir meilix-default-settings/usr/lib/mozilla-firefox/extensions/
mv susi-firefox.xpi meilix-default-settings/usr/lib/mozilla-firefox/extensions/

# adding susi to chromium by adding the extension to the Meilix default settings 

# add susi package
