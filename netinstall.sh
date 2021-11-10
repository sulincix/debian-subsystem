#!/bin/bash
CURDIR=$(pwd)
cd /tmp
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "apt install git wget make gcc -yq"
fi
# Install dummy selinux
git clone https://gitlab.com/sulinos/devel/libselinux-dummy
cd libselinux-dummy
su -c "make && make install"
cd /tmp
# Install debian-subsystem
git clone https://gitlab.com/sulincix/debian-subsystem
cd debian-subsystem
su -c "make && make build-extra && make install && make install-extra"
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "make fix-debian"
fi
cd ${CURDIR}
rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy
