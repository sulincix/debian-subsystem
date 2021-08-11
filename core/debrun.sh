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
    if [[ ! -d /run/dbus ]] ; then
        mkdir -p /run/dbus
    fi
fi
export PULSE_SERVER=127.0.0.1
if [[ "$ROOTMODE" == "1" ]] ; then
    export USER=root
    export HOME=/root
else
    export USER=debian
    export HOME=/home/debian
fi
export XDG_RUNTIME_DIR=/tmp/runtime-${USER}
chown ${USER} ${HOME} 
cd ${HOME}
source /etc/profile || true
get_shell(){
    if [[ $UID -eq 0 && "$ROOTMODE" != "1" ]] ; then
        echo "su -p $USER"
    else
        echo "sh"
    fi
}
if which dbus-launch &>/dev/null && [[ "$ROOTMODE" != "1" ]]  ; then 
    exec $(get_shell) -c "exec dbus-launch -- $*"
else
    exec $(get_shell) -c "exec $*"
fi
