![Debian logo](https://gitlab.com/sulincix/debian-subsystem/-/raw/master/core/debian.svg)
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
* make (for self update)
* busybox
* vte-2.91 (for d-term)
* gtk+-3.0 (for d-term)
* pygobject (for d-term)

### Install:
```shell
git clone https://gitlab.com/sulincix/debian-subsystem
cd debian-subsystem
make
make install DESTDIR=/
```

### Install from single command:
`bash <(curl https://gitlab.com/sulincix/debian-subsystem/-/raw/master/netinstall.sh)`

### Components:
`pidone`           : pid namespace isolator.

`debian`           : run command in subsystem

`debian-session`   : run Xsession on subsystem

`debian-terminal`  : open a subsystem terminal

`debian-umount`    : umount all binding os subsystem

`debian-xdg-open`  : Open file with xdg-open from debian

### Simple usage:
You can use `debian` command to run debian subsystem shell. Subsystem shell **pid** value is **1** but **/proc** directory is common. So you can see host process in debian.

If you need full **/proc** isolation, you must run `mount -t proc proc /proc` command in debian subsystem with root.

If you want to run command on debian subsystem shell, you should use `debian <<< command` or `echo "command" | debian`. 

If you want to run command on host system from debian subsystem, you should use `hostctl command` command. This command cannot generate any output and input.

You should open `~/.local/hostctl.log` file to see hostctl-daemon logs.

If you want to remove debian installation, you must run first `debian-umount` then `rm -rf /var/debian/`.

### Bug report:
https://gitlab.com/sulincix/debian-subsystem

### Bugs:
* pavucontrol not working (however alsamixer working)
* polkit authentication not working
* shell job control not available (if chroot command is symlink of busybox)
