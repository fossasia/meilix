#!/bin/bash
rm meilix-default-settings_*                                    #removes the older meilix-default-settings packages
rm -rf meilix-default-settings/debian/meilix-default-settings   #remove the meilix-default-settings metapackges
cd meilix-default-settings                                      #cd into the metapackage directory
debuild -uc -us                                                 #debuild the meilix-default-settings metapackage

