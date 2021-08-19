#!/bin/bash
CURDIR=$(pwd)
cd /tmp
if [[ -f /var/lib/dpkg/info ]] ; then
    su -c "apt install git wget -yq"
fi
git clone https://gitlab.com/sulincix/debian-subsystem
cd debian-subsystem
make && su -c "make install"
if [[ -f /var/lib/dpkg/info ]] ; then
    su -c "make fix-debian"
fi
cd ${CURDIR}
rm -rf /tmp/debian-subsystem
