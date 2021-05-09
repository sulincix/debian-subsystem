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
