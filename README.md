# Meilix
<p>
    <img align= "left" src="./docs/logo_readme.png" width="160">
    A beautiful and customizable Linux build for out of the box features for an Internet Kiosk. You can use the Meilix Generator (Web app) to make a Linux for your own brand/event, also add apps and features you need pre-installed, it will create an ISO Image of your Linux, which you can use as a live boot or install on PCs. 
</p><br>

[![Join the chat at https://gitter.im/fossasia/meilix](https://badges.gitter.im/fossasia/meilix.svg)](https://gitter.im/fossasia/meilix?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://travis-ci.org/fossasia/meilix.svg?branch=master)](https://travis-ci.org/fossasia/meilix)
 

`Meilix is under heavy development. It is in alpha stage and not yet recommended for productive use.`

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
    4. [Testing](#test)
5. [Contribution](#contribution)
    1. [Community](#community)
    2. [Guideline](#guideline) 
    3. [Branches](#branches)
    4. [Best Practice](#best-practice)
6. [Resource](#resource) 
7. [Gallery](#gallery)
8. [License](#license)

## Introduction

This project serves as a solution for those who wish to have a pre-configured custom Linux, with all the needed apps/features already installed. An example of its use case is events. Every event organizer needs to have all their systems configured equally, and need some specific apps to run the event. Configuring each system one by one can be a time taking and difficult task, but using Meilix, they can create their own custom Linux ISO and run/live boot on as many systems as they want. It will not just save countless hours, but also make the process more cost-efficient. 

### Feature

Meilix is a light weight, beautiful and fast Linux with all the features of Ubuntu/Debian distro. Custom Meilix builds are commissioned by the Meilix-generator web app.

### Architecture

Meilix is based on Ubuntu/Debian architecture. Meilix uses LXQT as the standard Desktop Environment.

### Ecosystem

Following are the other projects/dependency part of Meilix ecosystem.

Name | About | 
-------------|-------|
[Meilix](https://github.com/fossasia/meilix) | This repo for standalone build or as a backend for the webapp 
[Meilix-generator](https://github.com/fossasia/meilix-generator) | A webapp which generates an ISO Image of Meilix Linux
[Meilix-systemlock](https://github.com/fossasia/meilix-systemlock/) | A program to freeze the system 
[Meilix-artwork](https://github.com/fossasia/meilix-artwork/) | Boot screen splash themes for Meilix

## Usage

To create your own Linux for an event kiosk or just for trying it out, you can use [Meilix-generator](https://github.com/fossasia/meilix-generator). A web app, which has all the options to customize and generate an ISO. 

## Pre Requisites

Here are some pre-requisites to develop Meilix. 

- Exposure to the terminal and basic commands and basic comprehension of shell scripts
- Experience in working with a Debian system. 
- [LPIC1](https://en.wikipedia.org/wiki/Linux_Professional_Institute_Certification_Programs#LPIC-1) is a huge plus

## Development 

Meilix fetches ubuntu source, customizes it to add features and then builds the distro. It uses shell scripts to perform all the tasks, build can be made on local machine or via Travis CI.

### File Structure

Basic understanding of the file structure is required to do development, here is a level 2 file structure of this project

```console
.
├── build.sh
├── LICENSE.md
├── sources.xenial.list
├── sources.bionic.list
├── README.md
├── systemlock_0.1-1_all.deb
├── image-amd64.tar.lzma
├── image-i386.tar.lzma
├── ubiquity-slideshow
|   └── slides/...
├── polkit-1
│   └── actions/...
├── conf
│   └── distributions/...
├── pool
│   └── main/...
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
### Testing the ISOs
1. [Local Installation with Qemu/KVM](/docs/run_meilix_with_qemu.md)
2. [Run as a live CD in Virtualbox by Oracle](/docs/run_meilix_with_virtualbox.md)

**Build Using Travis***

1. Update `.travis.yml` according to your API key [as explained here](https://blog.fossasia.org/setting-environment-variables-up-in-travis-and-heroku-for-meilix-and-meilix-generator/)
2. Push changes to your repo, it will start the build process.

## Contribution

Your code contributions are always appreciated. To keep your experience good, we suggest you read all the guidelines thoroughly, also take some time to understand the workflow for this project. Each contribution is expected to follow best practices and community guidelines. Following are the things you can do to contribute to Meilix

1. **Report a bug** <br>
If you think you have encountered a bug, and we should know about it, feel free to report it [here](https://github.com/fossasia/meilix/issues/new) and our community will take care of it.

2. **Request a feature** <br>
You can also request for a feature [here](https://github.com/fossasia/meilix/issues/new), and if the community feels it's viable, it will be picked for development.  

3. **Create a pull request** <br>
It can't get better then this, your pull request will be really appreciated by the community. You can get started by picking up any open issues from [here](https://github.com/fossasia/meilix/issues) and make a pull request.

### Community 

Meilix has contributors around the world,  constantly improving Meilix and helping others as well to do so. To get in touch with the community, you can use the following communication channels. 

**Gitter**: [https://gitter.im/fossasia/meilix](https://gitter.im/fossasia/meilix) <br>
**Slack**: [http://fossasia-slack.herokuapp.com/](http://fossasia-slack.herokuapp.com/) <br>
**Mailing List**: [https://groups.google.com/forum/#!forum/meilix](https://groups.google.com/forum/#!forum/meilix)<br>
**Scrum Mail**: meilix@googlegroups.com <br>
**Twitter**: [https://twitter.com/meilix_](https://twitter.com/meilix_)


### Guideline

FOSSASIA Open Source Guidelines can be found [here](https://blog.fossasia.org/open-source-developer-guide-and-best-practices-at-fossasia/)

### Branches

Meilix uses an agile continuous integration methodology, so the version is frequently updated and development is really fast. 

1. **`Master`** is the development branch. It should always built.

2. **`Generator`** is a legacy branch we keep for reference for the time being. It chrooted a master branch ISO release and made changes as requested by the meilix-generator app and repackaged the customized ISO.

3. No further branches should be created in the main repository.

**Steps to create a pull request**

1. Make a PR to `master` branch. 
2. Comply with the best practices and guidelines e.g. where the PR concerns visual elements it should have an image showing the effect.
3. It must pass all continuous integration checks and get positive reviews.

After this, changes will be merged.

### Best Practice 

**Commits**

- Each commit should have proper documentation and comments in code, which will make it easy for others to understand it.
- Make sure your commit message is crisp and clear, read more about it [here](https://chris.beams.io/posts/git-commit/)
- When refering to a issue in a Pull Request, use [special words](https://help.github.com/articles/closing-issues-using-keywords/) to automatically close the related issue like "Fixes #234"
- Keep each PR limited in scope, which will make it easy to review and correct. Squash your commits.

## Resource 

- [Lubuntu Linux Operating System](https://lubuntu.net/about/)
- [LXDE/LXQT](https://lxde.org/)
- [Meilix Blogs](https://blog.fossasia.org/tag/meilix/page/5/)
- [André Talk](https://www.youtube.com/watch?v=PaGtdc1EFRw)
- [Tarun Talk](https://www.youtube.com/watch?v=iG4fgZlmdb4)

## License 

This project is currently licensed under GNU Lesser General Public License v3.0 (LGPL-3.0). A copy of LICENSE.md should be present along with the source code. To obtain the software under a different license, please contact FOSSASIA.
