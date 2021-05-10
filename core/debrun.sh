#!/bin/bash
set -e
if [[ ! -f /run/debian ]] ; then
    which systemd-tmpfiles &>/dev/null && systemd-tmpfiles --create
    which tmpfiles &>/dev/null && tmpfiles --create
    touch /run/debian
fi
export USER=debian
export HOME=/home/debian
export PULSE_SERVER=127.0.0.1
chown debian /home/debian
source /etc/profile
cd /home/debian
if [[ $(mount | grep "^proc" | wc -l ) -lt 2 ]] ; then
    mount -t proc proc /proc
fi
if which dbus-launch &>/dev/null ; then 
    exec su --preserve-environment debian -c "dbus-launch -- $*"
else
    exec su --preserve-environment debian -c "$*"
fi
