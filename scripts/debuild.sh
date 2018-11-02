#!/bin/bash
# In which directory is this script started? It is supposed to be in the project folder.
# on travis in /home/travis/build/fossasia/meilix

rm meilix-default-settings_*                                    #removes the older meilix-default-settings packages if exist
cd meilix-default-settings                                      #cd into the metapackage directory
echo y | debuild -uc -us                                                 #debuild the meilix-default-settings metapackage
cd ..

# Building Meilix-Artwork bow happens in the repository of Meilix-Artwork
#building plymouth
#sudo apt-get -qq install libfile-fcntllock-perl  #installing files required by meilix artwork to build plymouth
#cd meilix-artwork                                      #cd into the metapackage directory
#echo y | debuild -uc -us                                                 #debuild the plymouth
