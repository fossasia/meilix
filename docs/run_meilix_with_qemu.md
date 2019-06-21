### Development

Want to contribute? Great!

# How to run/tests Meilix ISO locally with Qemu/KVM

## Installing KVM on Ubuntu 

* **Step 1:** Update your ubuntu repositories ```sudo apt-get update```
* **Step 2:** Install the kvm packages, execute ```sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager```
* **Step 3:** Add user to the groups, execute ```sudo adduser <your-username> libvirt``` and ```sudo adduser <your-username> libvirt-qemu```
* **Step 4:** Restart your system
* **Step 5:** Execute ```virt-manager``` to open Virtual Machine Manager

![Virtual-Manager](/docs/screenshots/virtual-manager.png)

## Testing the Latest Release on Qemu/KVM

* **Step 1:** Download the "Latest Release" here, search (CTRL-f) for "Latest" https://github.com/fossasia/meilix/releases
* **Step 2:** Open Virtual Machine Manager
* **Step 3:** Click on Create A New Virtual Machine

![New-Virtual-Machine](/docs/screenshots/New-Virtual-Manager.png)
* **Step 3:** Select Local Install Image, then click Forward 

![Local-ISO](/docs/screenshots/Local-ISO.png)
* **Step 4:** Choose the downloaded ISO Image using Browse, then click Forward

![Choose-ISO](/docs/screenshots/Choose-ISO.png)
* **Step 5:** Allocate memory and cpu cores to the VM and click Forward

![Allocate-Memory](/docs/screenshots/memory.png)
* **Step 5:** Determine hard drive size and click Forward

![Hard-Drive](/docs/screenshots/Hard-Drive.png)
* **Step 6:** Check the Overview of the VM and choose Virtual Network for Network Selection, then click Finish

![Overview](/docs/screenshots/Overview.png)

![Meilix-Xenial](/docs/screenshots/Meilix.gif)

## Video link to test meilix ISO locally
![meilix](https://www.youtube.com/watch?v=UglXvy0TS9I)


*If you like the project, don't forget to **star** it.*
