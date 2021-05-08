#!/bin/bash
set -e
umask 022
cd /usr/lib/sulin/dsl
setenforce 0 &>/dev/null || true
source variable.sh
[[ -f /etc/debian.conf ]] && source /etc/debian-subsystem.conf
source functions.sh
debian_check
run $@
