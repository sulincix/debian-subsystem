#!/bin/bash
set -e
CURDIR=$(pwd)
cd /tmp
if [[ $UID -ne 0 ]] ; then
    echo "You must be root !!"
    exit 1
fi
rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy || true
if [[ -d /var/lib/dpkg/info ]] ; then
    apt install git wget make gcc -yq
elif [[ -d /var/lib/dnf ]] ; then
    dnf install glibc-static make gcc wget git -y
fi
# Install dummy selinux
git clone https://gitlab.com/sulinos/devel/libselinux-dummy
git clone https://gitlab.com/sulincix/debian-subsystem

cd /tmp/libselinux-dummy
make && make install

cd /tmp/debian-subsystem
make && make build-extra && make install && make install-extra
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "make fix-debian"
fi

rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy
cd ${CURDIR}
