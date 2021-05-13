#!/bin/bash
CURDIR=$(pwd)
cd /tmp
git clone https://gitlab.com/sulincix/debian-subsystem
cd debian-subsystem
make && su -c "make install"
cd ${CURDIR}
rm -rf /tmp/debian-subsystem
