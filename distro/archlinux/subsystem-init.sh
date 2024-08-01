#!/bin/bash
set -e
set -o pipefail
mkdir -p /var/lib/subsystem/
cd /var/lib/subsystem/
wget https://geo.mirror.pkgbuild.com/iso/latest/archlinux-bootstrap-x86_64.tar.zst -O - | zstdcat | \
tar -xvf -
mv root.x86_64/* ./
rm -rf pkglist.x86_64.txt
sed -i "s|#Server = https://geo.mirror.pkgbuild.com|Server = https://geo.mirror.pkgbuild.com|g" /var/lib/subsystem/etc/pacman.d/mirrorlist
sed -i "s/^CheckSpace/#CheckSpace/g" /var/lib/subsystem/etc/pacman.conf
sed -i "s/#ParallelDownloads/ParallelDownloads/g" /var/lib/subsystem/etc/pacman.conf
chroot /var/lib/subsystem/ pacman-key --init