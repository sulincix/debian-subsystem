#!/bin/bash
set -e
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs ${DESTDIR}/run
which systemd-tmpfiles &>/dev/null && systemd-tmpfiles --create
which tmpfiles &>/dev/null && tmpfiles --create
#export SHELL=/bin/bash
export USER=debian
export HOME=/home/debian
chown debian /home/debian
source /etc/profile
cd /home/debian
if which dbus-launch &>/dev/null ; then
    mkdir -p /run/dbus
    if [[ ! -f /run/dbus/pid ]] ; then
        dbus-daemon --system --fork
        chmod 755 /run/dbus
    fi
    exec su --preserve-environment debian -c "dbus-launch -- $*"
else
    exec su --preserve-environment debian -c "$*"
fi
