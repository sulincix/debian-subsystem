![Debian logo](https://gitlab.com/sulincix/debian-subsystem/-/raw/master/core/debian.svg)
# Debian subsystem for linux
Debian subsystem integration for host distribution.

It uses chroot environment and You can run chrooted cli/gui applications on debian.

### Supported distributions
* Debian
* Devuan
* Ubuntu
* Parrot
* Pardus
* Kali
* Gentoo
* Sulin
* Archlinux
* Manjaro
* Voidlinux

***

### Features
* Written pure bash and C
* Open files with subsystem applications
* Open subsystem session
* Open subsystem terminal
* Home directory is common
* Don't need service

***

### Parts
* Debian session
* Debian terminal
* Debian cli

***
## Installation

### Dependencies:

#### Core:
* make (for self update)
* busybox

#### Extra:
* polkit (only need if droot not exists)
* vte-2.91 (for d-term)
* gtk+-3.0 (for d-term)
* pygobject (for d-term/python)
* vala (for d-term/vala)

### Debian/Ubuntu:
```shell
# busybox-static recommended for better compability
apt install -y busybox-static make polkit-1 libvte-common libvte2.91-common valac gcc
```

### Fedora:
```shell
dnf install -y busybox make polkit-gnome vte gtk3 vala glibc-static gcc
```
- Note: Fedora requires selinux disabled.

### Arch:

```shell
pacman -Sy make vte3 vte-common gtk3 vala gcc
```

#### clone:

```shell
git clone https://gitlab.com/sulincix/debian-subsystem
cd debian-subsystem
make
make install DESTDIR=/
```
*Debian based distribution users must run this*:

```
 make fix-debian DESTDIR=/
```

if you don't need terminal and session component you can run `make build-core` and `make install-core`


### Install from single command:
`bash <(curl https://gitlab.com/sulincix/debian-subsystem/-/raw/master/netinstall.sh)`

***

## Uninstallation

```rm -rf /var/debian/``` or ```debian-umount --remove```

**Always double check to make sure home directory is umounted! **

**you can umount with `debian-umount` command!**

***


### Components:
`pidone`           : pid namespace isolator.

`iniparser`        : ini config file parser.

`debian`           : run command in subsystem

`hostctl`          : send command from subsystem to host

`debian-session`   : run Xsession on subsystem

`debian-terminal`  : open a subsystem terminal

`debian-umount`    : umount all binding os subsystem

`debian-xdg-open`  : Open file with xdg-open from debian

`droot`            : get a subsystem shell

`pkexec-fake`      : polkit authentication with hosts pkexec

***

### Usage:
You can use `debian` command to run debian subsystem shell. Subsystem shell **pid** value is **1** but **/proc** directory is common. So you can see host process in debian.

If you need full **/proc** isolation, you must run `mount -t proc proc /proc` command in debian subsystem with root.

If you want to run command on host system from debian subsystem, you should use `hostctl command` command.


If you want to remove debian installation, you must run first `debian-umount` then `rm -rf /var/debian/`.

Distribution configs defined by `/etc/debian.conf` file. if you want to run another distribution, you can set **system** variable.

You can send command to subsystem shell. 

```shell
# type 1
echo "ls -la /" | debian
# type 2
debian <<< "ls -la /"
# type 3
debian -c "ls -la /"
```

**d-term** is subsystem terminal application. If you install any terminal application d-term replaced with it. (x-terminal-emulator)

Subsystem applications installed your application menu. You can open files with subsystem application. Menu will sync after next subsystem shell creation.

**debian-session** create subsystem Xsession. If **x-session-manager** exists run. If not exists, run d-term.

You can disable common_home and bind_system features in **/etc/debian.conf** file. If you disable common_home, /home directory will isolated. If you disable bind_system, subsystem cannot access hosts filesystem. (/system)

Fedora users can install dummy selinux for completely remove selinux from system.
https://gitlab.com/sulinos/devel/libselinux-dummy

Polkit authentication message is wrong. Because pkexec-fake component use fifo bridge and run `echo true` command as root and return status. so You will see **/bin/echo** command instead of original command.

***

### Bug report:
https://gitlab.com/sulincix/debian-subsystem/-/issues

### Mirrors:
* https://gitlab.com/sulincix/debian-subsystem (main)
* https://github.com/sulincix/debian-subsystem
* https://kod.pardus.org.tr/sulincix/debian-subsystem

***

### Known bugs:
* gnome-session not working as subsystem session
* shell job control not available (if chroot command is symlink of busybox)
* selinux enforcing mode not supported. (subsystem will set permissive mode automatically)
