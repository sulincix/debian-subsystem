# Debian subsystem for Linux
The Debian subsystem integration enhances host distributions by enabling the execution of chrooted command-line and graphical applications from Debian. This integration relies on a chroot environment to facilitate seamless operation of Debian applications within the host environment.

## How to build
```
# build project
make
# install project
make install
# set suid bit
chmod u+s /bin/lsl
# copy rootfs into /var/lib/subsystem directory (or use debootstrap)
debootstrap --arch=amd64 stable /var/lib/subsystem
```

### Optional: Building PAM Module

A PAM module is available to automatically synchronize the subsystem during login, though it's disabled by default.
To build and enable the PAM module, use the following commands:

```
# build pam module
make pam
# install pam module
make install_pam
# enable module
echo -e "auth\toptional\tpam_lsl.so" >> /etc/pam.d/system-auth
# Note: The file name may vary on your system.
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
* Simple cgroup controller
* Simple sandbox environment

### Notes:
* To enable polkit, you need to disable the cgroup controller. Use the following command:
```sh
LSL_NOCGROUP=1 lsl ...
```

* If you want to disable the sandbox feature, you can do so with this command:

```sh
LSL_NOSANDBOX=1 lsl ...
```

### Bug report:
https://gitlab.com/sulincix/debian-subsystem/-/issues

### Mirrors:
* https://gitlab.com/sulincix/debian-subsystem (main)
* https://github.com/sulincix/debian-subsystem
