#!/bin/bash
export PATH=/usr/bin:/usr/sbin:/bin:/sbin
set -e
set -o pipefail
if ! command -v gettext &>/dev/null; then
    _(){
        echo "$@"
    }
else
    _(){
        "gettext" "lsl" "$@" ; echo
    }
fi
_ "Initial Setup Required. The Voidlinux base will be downloaded."
_ "Do you want to continue? [Y/n]"
read -n 1 c

if ! [[ "$c" == "Y" || "$c" == "y" ]] ; then
    exit 1
fi

mkdir -p /var/lib/subsystem/
cd /var/lib/subsystem/
fname=$(wget -O - https://repo-default.voidlinux.org/live/current/ \
    | grep x86_64 | grep ROOTFS | grep musl | head -n 1 | cut -f2 -d "\"")
wget https://repo-default.voidlinux.org/live/current/$fname -O - | xzcat | \
tar -xvf -
cat /etc/resolv.conf > /var/lib/subsystem/etc/resolv.conf
cat /etc/machine-id > /var/lib/subsystem/etc/machine-id
chroot /var/lib/subsystem/ xbps-pkgdb -ua
chroot /var/lib/subsystem/ xbps-install -Syu