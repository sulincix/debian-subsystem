# Debian subsystem for linux
Debian subsystem integration for host distribution.

It uses chroot environment and You can run chrooted cli/gui appilcations on debian.
### Parts
* Debian session
* Debian terminal
* Debian cli

### Dependencies:
* debootstrap (if does not exists will install from source)
* wget (for install debootstrap from source)
* polkit (for rootles chroot)
* busybox
* vte-2.91 (for d-term)
* gtk+-3.0 (for d-term)
* pygobject (for d-term)

### Install:
`make install DESTDIR=/`

### Components:

`debian`           : run command in subsystem

`debian-sudo`      : run command in subsystem as root

`debian-session`   : run Xsession on subsystem

`debian-terminal`  : open a subsystem terminal

`debian-umount`    : umount all binding os subsystem

`debian-xdg-open`  : Open file with xdg-open from debian

### Bugs:
* pavucontrol not working (however alsamixer working)
* polkit authentication not working
* shell job control not available (if chroot command is symlink of busybox)