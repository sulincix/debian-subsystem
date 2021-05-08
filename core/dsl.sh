#!/bin/bash
set -e
cd /usr/lib/sulin/dsl
source variable.sh
[[ -f /etc/debian.conf ]] && source /etc/debian-subsystem.conf
source functions.sh
debian_check
run $@
