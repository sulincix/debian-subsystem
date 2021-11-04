#!/bin/bash
set -e
[[ $UID -ne 0 ]] && echo "You must be root! $UID" && exit 1
umask 022
source /usr/lib/sulin/dsl/variable.sh
source /usr/lib/sulin/dsl/functions.sh
wsl_block || {
    echo "Fucking WSL environment is not allowed!"
    echo -e "\033[?25l"
    trap '' 2
    while true ; do
        read -s -n 1
    done
}
debian_check || {
    echo "Debian installation failed."
    echo "Press any key to exit"
    read -s -n 1 && exit 1
}

if ! ls ${DESTDIR}/tmp/hostctl &>/dev/null ; then
    echo "Starting hostctl"
    mkfifo ${DESTDIR}/tmp/hostctl &>/dev/null || true
    chmod 700 ${DESTDIR}/tmp/hostctl &>/dev/null || true
    chown ${USERNAME} ${DESTDIR}/tmp/hostctl
    while read line < ${DESTDIR}/tmp/hostctl ; do
        su "${USERNAME}" -c "$line" &
        sleep 0.3
    done &
fi
if [[ "$1" == "--root" ]] ; then
    run su
elif [[ "$1" == "--xdg" ]] ; then
    shift
    nopidone=true
    run debxdg "$@"
else
    run /bin/bash
fi

