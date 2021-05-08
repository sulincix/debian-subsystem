#!/bin/bash
set -e
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs ${DESTDIR}/run
which systemd-tmpfiles &>/dev/null && systemd-tmpfiles --create
which tmpfiles &>/dev/null && tmpfiles --create
if which dbus-launch &>/dev/null ; then
    mkdir -p /run/dbus
    [[ -f /run/dbus/pid ]] && rm -f /run/dbus/pid
    dbus-daemon --system --fork
    chmod 755 /run/dbus
    exec su --preserve-environment debian -c "dbus-launch -- $*"
else
    exec su --preserve-environment debian -c "$*"
fi
