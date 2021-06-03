#!/bin/bash
set -e
if [[ $UID -eq 0 ]] ; then
    if [[ ! -f /run/debian ]] ; then
        which systemd-tmpfiles &>/dev/null && systemd-tmpfiles --create
        which tmpfiles &>/dev/null && tmpfiles --create
        touch /run/debian
        chown debian /home/debian
        chmod +rw /dev/snd/*
        chmod +rw /dev/dri/*
    fi
fi
export USER=debian
export HOME=/home/debian
export PULSE_SERVER=127.0.0.1
cd /home/debian
source /etc/profile || true
get_shell(){
    if [[ $UID -eq 0 ]] ; then
        echo "su -p debian"
    else
        echo "sh"
    fi
}
# su command blocked non-terminal. So we need login for sulin.
# This feature provide that sulin is safer then others :)
[[ -d /data/user ]] && exec login
if which dbus-launch &>/dev/null ; then 
    exec $(get_shell) -c "exec dbus-launch -- $*"
else
    exec $(get_shell) -c "exec $*"
fi
