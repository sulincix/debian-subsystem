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
get_shell(){
    if [[ $UID -eq 0 ]] ; then
        echo "su --preserve-environment debian"
    else
        echo "sh"
    fi
}
if which dbus-launch &>/dev/null ; then 
    exec $(get_shell) -c "exec dbus-launch -- $*"
else
    exec $(get_shell) -c "exec $*"
fi
