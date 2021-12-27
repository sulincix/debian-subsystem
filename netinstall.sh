#!/bin/bash
set -e
CURDIR=$(pwd)
cd /tmp
setenforce 0 &>/dev/null || true
if [[ $UID -ne 0 ]] ; then
    echo "You must be root !!"
    exit 1
fi
rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy || true
if [[ -d /var/lib/dpkg/info ]] ; then
    apt install git busybox make polkit-1 libvte-common libvte2.91-common valac gcc -yq
elif [[ -d /var/lib/dnf ]] ; then
    dnf install busybox make polkit-gnome vte gtk3 vala glibc-static make wget git -y
elif [[ -f /etc/pacman.conf ]] ; then
    pacman -Sy make vte3 vte-common gtk3 vala gcc wget git
fi
# Install dummy selinux
git clone https://gitlab.com/sulinos/devel/libselinux-dummy
git clone https://gitlab.com/sulincix/debian-subsystem

cd /tmp/libselinux-dummy
make && make install
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/sysconfig/selinux &>/dev/null || true

cd /tmp/debian-subsystem
make && make build-extra && make install && make install-extra
if [[ -d /var/lib/dpkg/info ]] ; then
    su -c "make fix-debian"
fi

rm -rf /tmp/debian-subsystem /tmp/libselinux-dummy
cd ${CURDIR}
