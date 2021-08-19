#!/bin/bash
set -e
[[ "${SYSTEM}" == "" ]] && SYSTEM=$(iniparser /etc/debian.conf "default" "system")
get_var(){
    iniparser /etc/debian.conf "${SYSTEM}" "$1"
}
get(){
    [[ -f ~/.config/debxdg.conf ]] || cp -pf /usr/lib/sulin/dsl/debxdg.conf ~/.config/debxdg.conf
    iniparser ~/.config/debxdg.conf "Main" "$1"
}
if [[ -f /etc/debian.conf ]] ; then
    DIST=$(get_var DIST)
    REPO=$(get_var REPO)
    DESTDIR=$(get_var DESTDIR)
else
    DIST="stable"
    REPO="https://deb.debian.org/debian"
    DESTDIR="/var/debian"
fi
[[ "$DIST" == "" ]] && exit 1
[[ "$REPO" == "" ]] &&  exit 1
[[ "$DESTDIR" == "" ]] &&  exit 1
if [[ "$HOMEDIR" == "" ]] ; then
   HOMEDIR="$(cat /etc/passwd | grep 1000 | cut -d ":" -f 6)"
fi
USERNAME=$(grep "1000" /etc/passwd | cut -f 1 -d ":")
