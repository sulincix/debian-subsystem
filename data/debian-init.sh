#!/bin/bash
set -e
fail_exit(){
    echo "$@"
    exit 1
}
command_check(){
    cmds=(which ls make wget unzip perl)
    for cmd in ${cmds[@]} ; do
        command which >/dev/null
    done
}
tool_init(){
    which debootstrap &>/dev/null && return 0
    cd /tmp
    wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip || fail_exit "Failed to fetch debootstrap source"
    unzip debootstrap.zip  >/dev/null
    cd debootstrap-master
    make >/dev/null || fail_exit "Failed to install debootstrap"
    make install  >/dev/null || fail_exit "Failed to install debootstrap"
    cd /tmp
    rm -rf /tmp/debootstrap-master

}
system_init(){
    [[ $(uname -m) == "x86_64" ]] && arch=amd64
    [[ $(uname -m) == "aarch64" ]] && arch=arm64
    [[ $(uname -m) == "i686" ]] && arch=i386
    [[ "$arch" == "" ]] && fail_exit "Unsupported arch $(uname -m)"
    debootstrap --arch=$arch --extractor=ar --no-check-gpg --extractor=ar stable /var/lib/subsystem
}

if [[ -f /var/lib/subsystem/etc/os-release ]]; then
    exit 0
fi

command_check
tool_init
system_init