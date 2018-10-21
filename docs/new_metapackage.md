
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
