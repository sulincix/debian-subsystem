#!/bin/bash
set -e
[[ $UID -ne 0 ]] && echo "You must be root! $UID" && exit 1
umask 022
source /usr/lib/sulin/dsl/variable.sh
source /usr/lib/sulin/dsl/functions.sh
echo -n "$SYSTEM" > /proc/$$/comm
wsl_block || {
    msg "FUCK" "Fucking WSL environment is not allowed!"
    echo -e "\033[?25l"
    trap '' 2
    while true ; do
        read -s -n 1
    done
}
debian_check || {
    msg "Error" "Debian installation failed."
    msg "Info" "Press any key to exit"
    read -s -n 1 && exit 1
}

if ! ls ${DESTDIR}/run/hostctl&>/dev/null ; then
    msg "Starting" "hostctl"
    mkfifo ${DESTDIR}/run/hostctl&>/dev/null || true
    chmod 700 ${DESTDIR}/run/hostctl&>/dev/null || true
    chown ${USERNAME} ${DESTDIR}/run/hostctl
    while read line < ${DESTDIR}/run/hostctl; do
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

