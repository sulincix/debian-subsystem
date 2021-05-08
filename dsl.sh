#!/bin/bash
set -e
cd /usr/lib/sulin/dsl
export SHELL=/bin/bash
[[ "$DIST" == "" ]] && DIST="stable"
[[ "$REPO" == "" ]] && REPO="https://deb.debian.org/debian"
[[ "$DESTDIR" == "" ]] && DESTDIR="/var/debian"
if [[ "$HOMEDIR" == "" ]] ; then
   HOMEDIR="$(cat /etc/passwd | grep 1000 | cut -d ":" -f 6)"
fi
[[ -f /etc/debian.conf ]] && source /etc/debian-subsystem.conf
source functions.sh
debian_check
run $@
