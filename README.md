
<p align="center">
    <img src="logo.png" width="160">
</p><br><br>

# Meilix

[![Join the chat at https://gitter.im/fossasia/meilix](https://badges.gitter.im/fossasia/meilix.svg)](https://gitter.im/fossasia/meilix?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/fossasia/meilix.svg?branch=master)](https://travis-ci.org/fossasia/meilix)

 
A beautiful and customizabsle Linux build for out of the box features for any event. You can use the Meilix Generator (Web app) to make a Linux for your own brand/event, also add apps and features you need pre-installed, it will create an ISO Image of your Linux, which you can use for live boot or as you want. 

`Meilix is under heavy development`

# Index

1. [Introduction](#introduction)
    1. [Features](#feature)
    2. [Architecture](#architecture)
    3. [Ecosystem](#ecosystem)
2. [Usage](#usage)
3. [Pre Requisites](#pre-requisites)
4. [Development](#development) 
    1. [File Structure](#file-structure)
    2. [Build](#build)
    3. [Metapackages](#metapackages)
5. [Contribution](#contribution)
    1. [Community](#community)
    2. [Guideline](#guideline) 
    3. [Workflow](#workflow)
    4. [Best Practice](#best-practice)
6. [Resource](#resource) 
7. [Gallery](#gallery)
8. [License](#license)

## Introduction

This project serves as a solution for those who wish to have a pre-configured custom Linux, with all the needed apps/features already installed. An example of its use case is events. Every event organizer needs to have all their systems configured equally, and need some specific apps to run the event. Configuring each system one by one can be a time taking and difficult task, but using Meilix, they can create their own custom Linux ISO and run/live boot on as many systems as they want. It will not just save countless hours, but also make the process more cost-efficient. 

### Feature

Meilix is a really beautifull, light weight and fast Linux with all the features of Ubunte/Debian Distro, following are some more features Meilix have:

- You can brand your Linux as you want, your company name and logo can be your:
    - Linux name
    - Linux logo
    - Wallpaper
    - Screensaver

- Switch on/off various features of your linux, you can switch: 
    - 64 Bit support (32 Bit is default)
    - Notifications
    - Screensaver
    - Sleep Modes 
    - System Sounds
    - Bookmarks
    - Screen Dimming
    - Power Management Saving 
    - Taskbar Autohide

- Following apps can be pre-installed in your linux: 
    - Chromium
	  - Firefox
	  - Hangout
	  - VLC
	  - GIMP
	  - Inkscape
	  - LibreOffice
	  - Git
	  - NextCloud
	  - Dropbox

- Add all the documents and files your need in your linux.
- System Lock: it allows you to freeze all the systems your are hosting using Meilix. 


### Architecture

Meilix is based on Ubuntu/Debian architecture, using LXQT as the standard DE(Desktop Environment).

### Ecosystem

Following are the other projects/dependency part of Meilix ecosystem.

Name | About | 
-------------|-------|
[Meilix-generator](https://github.com/fossasia/meilix-generator) | A webapp which generates an ISO Image of Meilix Linux
[Meilix-systemlock](https://github.com/fossasia/meilix-systemlock/) | A program to freeze the system 
[Meilix-artwork](https://github.com/fossasia/meilix-artwork/) | Repository to store all assets of Meilix

## Usage

To create your own Linux for an event or just for trying it out, you can use [Meilix-generator](https://github.com/fossasia/meilix-generator). A web app, which has all the options to customize and generate an ISO. 

## Pre Requisites

`More will be updated soon`

Here are some pre-requisites to develop Meilix. 

- Exposure to the terminal and basic commands. 
- Experience in working with a UNIX or GNU/Linux based system. 
- Basic understanding of Operating System and Package managers. 
- Programming/Scripting experience. Python, Shell Scripting etc.

## Development 

Meilix fetch ubuntu source, customize it to add features and then build the distro. It use shell scripts to perform all the tasks, build can be made on local machine, Trvis CI or Circle CI.

### File Structure

Basic understanding of the file structure is required to do development, here is a level 2 file structure of this project

```console
.
├── build.sh
├── LICENSE.md
├── logo.png
├── sources.list
├── README.md
├── meilix-metapackage_1.0-1_amd64.changes
├── plymouth-meilix-logo_1.0-1_all.deb
├── plymouth-meilix-text_1.0-1_all.deb
├── meilix-metapackage_1.0-1_all.deb
├── meilix-metapackages_1.0_all.deb
├── meilix-metapackage_1.0-1.tar.gz
├── meilix-metapackage_1.0-1.dsc
├── systemlock_0.1-1_all.deb
├── image-amd64.tar.lzma
├── image-i386.tar.lzma
├── amd64.tar.lzma
├── meilix-metapackages_1.0_all
│   └── control/...
├── ubiquity-slideshow
|   └── slides/...
├── metapackage
│   └── debian/...
├── polkit-1
│   └── actions/...
├── dists
│   └── trusty/...
├── conf
│   └── distributions/...
├── pool
│   └── main/...
├── mail-scripts
│   ├── mail-fail.py
│   └── mail.py
├── meilix-artwork
│   ├── debian/...
│   ├── Makefile/...
│   └── usr/...
├── systemlock-0.1
│   ├── debian/...
│   ├── etc/...
│   ├── Makefile/...
│   └── usr/...
├── meilix-default-settings
│   ├── debian/...
│   ├── etc/...
│   ├── Makefile/...
│   └── usr/...
├── db
│   ├── checksums.db
│   ├── contents.cache.db
│   ├── packages.db
│   ├── references.db
│   ├── release.caches.db
│   └── version
├── image
│   ├── boot/...
│   ├── casper/...
│   ├── dists/...
│   ├── EFI/...
│   ├── install/...
│   ├── isolinux/...
│   ├── pics/...
│   ├── pool/...
│   └── preseed/...
├── scripts
│   ├── aptRepoUpdater.sh
│   ├── arch.sh
│   ├── browser_uri.sh
│   ├── chroot.sh
│   ├── debuild.sh
│   ├── legacy_initrdext.sh
│   ├── mail-fail.py
│   ├── mail.py
│   ├── meilix_check.sh
│   ├── mew.sh
│   ├── packages
│   └── releases_maintainer.sh
└──chroot
    ├── bin/...
    ├── boot/...
    ├── dev/...
    ├── etc/...
    ├── home/...
    ├── lib/...
    ├── lib64/...
    ├── media/...
    ├── mnt/...
    ├── opt/...
    ├── proc/...
    ├── root/...
    ├── run/...
    ├── sbin/...
    ├── srv/...
    ├── sys/...
    ├── tmp/...
    ├── usr/...
    └── var/...
```


### Build

**Building Locally**

1. Make the build script executable.

```console
$ chmod +x ./build.sh
```

2. Execute the script.

```console
$ ./build.sh
```

**Build Using Travis***

1. Update `.travis.yml` according to your API. [Ream More](https://blog.fossasia.org/setting-environment-variables-up-in-travis-and-heroku-for-meilix-and-meilix-generator/)
2. Push changes to your repo, it will start the build process.

### Metapackages

**Creating a metapackage**

Creating a metapackage is really easy, we will make use of [equivs](http://apt.ubuntu.com/p/equivs) to make our metapackage.
- First, install equivs: `sudo apt-get install equivs`
- Now run equivs: `equivs-control ns-control`
- It will create a file called ns-control, open this file with your text editor.
- Modify the file to your needs modifying the needy information.
- Then run: `equivs-build ns-control` to build your metapackage, thats all simple and easy.
- To add it to meilix follow adding a metapackage to meilix section.

**List of basic items included while creating a metapackage**

- Changes will be made in the ns-control file which was created earlier.
- Change the name of the ns-control file to control.
- There are several lines of which required one are mention below:
- Source and package is the name of the metapackage that we want to give.
- Depends line consists of the packages that we want the metapackage should consistes of.
- Description line consists a short description of the metapackages.
- There are lots of other line which also matters depending upon the need of the metapackage. Go through [here](https://www.debian.org/doc/manuals/maint-guide/dreq) for more info.

**Adding a Metapackage to meilix**
- Create a metapackage and place it in the root directory of the project
- Add it to the build.sh file like `sudo cp -v nameOfYourMeta-package.deb chroot` in the 'copy source.list' line and `dpkg -i nameOfYourMeta-package.deb` lastly `apt-get install -f`.
- Follow the syntax (writing style) used in the build.sh
- Install `reprepro` if you don't have it, run: `sudo apt-get install reprepro`
- Make sure you are on the meilix repository.
- Run the following command for each meta-package you create: `reprepro includedeb trusty ./nameOfYourMeta-package.deb`

**Personalizing it**
Updating the OS/metapackage to the latest version
- For this, we need to update sources.list file to the version we desire.

## Contribution


### Community 

Show people how to join other people in this community and add learn.

### Guideline

Guide line for people who are involved in this project 

### Workflow

Write here how to do the development here, what are the important branches, how to work on them, how the comment message should look like

### Best Practice 

Add Best Practice here

## Resource 

Link to all the resource need for people to learn more about it

## Gallery 

Add pictures of this project here

## License 

This project is currently licensed under GNU Lesser General Public License v3.0 (LGPL-3.0). A copy of LICENSE.md should be present along with the source code. To obtain the software under a different license, please contact FOSSASIA.
