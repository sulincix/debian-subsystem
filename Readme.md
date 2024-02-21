# Debian subsystem for Linux
Debian subsystem integration for host distribution.

It uses chroot environment and You can run chrooted cli/gui applications on debian.

## How to build
```
# build project
make
# install project
make install
# set suid bit
chmod u+s /bin/lsl
# copy rootfs into /var/lib/subsystem directory
```

## How to use
For creating shell:
```
lsl /bin/bash
```
Or directly run a command
```
sudo lsl apt install nano
```

### Features
* Written pure C without any dependencies
* Open files with subsystem applications
* Home directory is common
* Doesn't need a service

### Bug report:
https://gitlab.com/sulincix/debian-subsystem/-/issues

### Mirrors:
* https://gitlab.com/sulincix/debian-subsystem (main)
* https://github.com/sulincix/debian-subsystem
