#!/bin/bash
set -e
CURDIR=$(pwd)
cd /tmp
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "apt install git wget make gcc -yq"
fi
# Install dummy selinux
git clone https://gitlab.com/sulinos/devel/libselinux-dummy
git clone https://gitlab.com/sulincix/debian-subsystem

cd /tmp/libselinux-dummy
su -c "make && make install" &

cd /tmp/debian-subsystem
su -c "make && make build-extra && make install && make install-extra" 
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "make fix-debian"
fi

rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy
cd ${CURDIR}
