#!/bin/bash
set -e
[[ $UID -ne 0 ]] && echo "You must be root!" && exit 1
umask 022
cd /usr/lib/sulin/dsl
setenforce 0 &>/dev/null || true
source variable.sh
[[ -f /etc/debian.conf ]] && source /etc/debian-subsystem.conf
source functions.sh
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
run $@
