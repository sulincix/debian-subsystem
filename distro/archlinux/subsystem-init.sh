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
_ "Initial Setup Required. The Archlinux base will be downloaded."
_ "Do you want to continue? [Y/n]"
read -n 1 c

if ! [[ "$c" == "Y" || "$c" == "y" ]] ; then
    exit 1
fi

mkdir -p /var/lib/subsystem/
cd /var/lib/subsystem/
wget https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst -O - | zstdcat | \
tar -xvf -
ls /var/lib/subsystem/ | while read line ; do
    rm -rf /var/lib/subsystem/root.x86_64/$line || true
done
mv root.x86_64/* ./
rm -rf pkglist.x86_64.txt root.x86_64
cat /etc/resolv.conf > /var/lib/subsystem/etc/resolv.conf
sed -i "s|#Server = https://geo.mirror.pkgbuild.com|Server = https://geo.mirror.pkgbuild.com|g" /var/lib/subsystem/etc/pacman.d/mirrorlist
sed -i "s/^CheckSpace/#CheckSpace/g" /var/lib/subsystem/etc/pacman.conf
sed -i "s/#ParallelDownloads/ParallelDownloads/g" /var/lib/subsystem/etc/pacman.conf
for dir in dev sys proc run ; do
    mount --bind /$dir /var/lib/subsystem/$dir
done
cat /etc/machine-id > /var/lib/subsystem/etc/machine-id
chroot /var/lib/subsystem/ pacman-key --init
chroot /var/lib/subsystem/ pacman-key --populate
for dir in dev sys proc run ; do
    umount -lf /var/lib/subsystem/$dir
done
if [ -f /etc/locale.gen ] ; then
    cat /etc/locale.gen > /var/lib/subsystem/etc/locale.gen
    chroot /var/lib/subsystem locale-gen
fi
mkdir -p /var/lib/subsystem/etc/pacman.d/hooks/
cat > /var/lib/subsystem/etc/pacman.d/hooks/subsystem.hook <<EOF
[Trigger]
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Updating subsystem
When = PostTransaction
Exec = /usr/bin/chroot /var/lib/lsl/system lsl true || true
EOF