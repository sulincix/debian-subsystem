#!/bin/bash
SYSTEM=$(iniparser /etc/debian.conf "default" "system")
get_var(){
    iniparser /etc/debian.conf "${SYSTEM}" "$1"
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
