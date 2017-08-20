#!/bin/bash
rm meilix-default-settings_*                                    #removes the older meilix-default-settings packages
cd meilix-default-settings                                      #cd into the metapackage directory
debuild -uc -us                                                 #debuild the meilix-default-settings metapackage
cd ..
#buildind plymouth
sudo apt-get -qq install libfile-fcntllock-perl  #installing files required by meilix artwork to build plymouth
cd meilix-artwork                                      #cd into the metapackage directory
echo y | debuild -uc -us                                                 #debuild the plymouth
