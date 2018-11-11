#!/bin/bash
# In which directory is this script started? It is supposed to be in the project folder.
# on travis that means in /home/travis/build/fossasia/meilix

# [-f meilix-default-settings_1.0_all.deb] && rm meilix-default-settings_1.0_all.deb  #remove older package if exist
cd meilix-default-settings  #cd into the metapackage directory
echo y | debuild -uc -us    #debuild the meilix-default-settings metapackage
cd ..

# Building Meilix-Artwork moved to the repository of meilix-artwork,
# so this is obsolete:
#building plymouth
#sudo apt-get -qq install libfile-fcntllock-perl  #installing files required by meilix artwork to build plymouth
#cd meilix-artwork                   #cd into the metapackage directory
#echo y | debuild -uc -us            #debuild the plymouth theme
