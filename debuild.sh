#!/bin/bash
rm meilix-default-settings_*                                    #removes the older meilix-default-settings packages
cd meilix-default-settings                                      #cd into the metapackage directory
debuild -uc -us                                                 #debuild the meilix-default-settings metapackage
