#!/bin/bash
rm meilix-default-settings_*
rm -rf meilix-default-settings/debian/meilix-default-settings
cd meilix-default-settings
debuild -uc -us

