#Meilix
[![Build Status](https://travis-ci.org/fossasia/meilix.svg?branch=master)](https://travis-ci.org/fossasia/meilix)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/06b894182dda4c8fb85f0025b11d6e72)](https://www.codacy.com/app/mb/meilix?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=fossasia/meilix&amp;utm_campaign=Badge_Grade)

Beautiful [lubuntu](http://lubuntu.net) based Linux OS for Hotels and Public Spaces with a system lock.
Features:
* Based on lubuntu
* Light weight
* Fast
* Contains neccessary packages
* PPA synced with github

##Customizing Distribution

- After cloning open build.sh to change. Read comment in build.sh to understand how to change.
(Note: Please not change anything at # Install core packages and do not delete any in hotelos folder).

##Adding a Metapackage
- Create a metapackage and place it in the root directory of the project
- Add it to the build.sh file
- Install `reprepro` if you don't have it:
  `sudo apt-get install reprepro`
- cd into the sources directory:
   `cd sources`
- Run the following command for the meta-package you create (Run it once for each meta-package)
   `reprepro includedeb trusty ../nameOfYourMeta-package.deb`
**Note: Remember to replace nameOfYourMeta-package with the name of the meta-package**

##Communication
Chat: [Pocket Science Slack Channel](http://fossasia.slack.com/messages/pocketscience/) | [Get an Invite](http://fossasia-slack.herokuapp.com/)
