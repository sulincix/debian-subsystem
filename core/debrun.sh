#!/bin/bash
set -e
if [[ ! -f /run/debian ]] ; then
    which systemd-tmpfiles &>/dev/null && systemd-tmpfiles --create
    which tmpfiles &>/dev/null && tmpfiles --create
    touch /run/debian
fi
export USER=debian
export HOME=/home/debian
chown debian /home/debian
source /etc/profile
cd /home/debian
chgrp audio -R /dev/audio
chgrp video -R /dev/snd
if which dbus-launch &>/dev/null ; then
    if [[ ! -f /run/debian ]] ; then
        mkdir -p /run/dbus
        if [[ ! -f /run/dbus/pid ]] ; then
            dbus-daemon --system --fork
            chmod 755 /run/dbus
        fi
    fi
    exec su --preserve-environment debian -c "dbus-launch -- $*"
else
    exec su --preserve-environment debian -c "$*"
fi
