#!/bin/bash
set -e
set -o pipefail
echo "Initial Setup Required. The Debian base will be downloaded. Do you want to continue? [Y/n]"
read -n 1 c

if ! [[ "$c" == "Y" || "$c" == "y" ]] ; then
    exit 1
fi

fail_exit(){
    echo "$@"
    echo "press any key to exit"
    read -n 1
    exit 1
}
command_check(){
    cmds=(which ls make wget unzip perl)
    for cmd in ${cmds[@]} ; do
        command -v "$cmd" >/dev/null || fail_exit "$cmd not found"
    done
}
tool_init(){
    echo "Installing debootstrap"
    which debootstrap &>/dev/null && return 0
    command_check
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
    debootstrap --variant=minbase --arch=$arch --extractor=ar --no-check-gpg --extractor=ar stable /var/lib/subsystem
cat > /var/lib/subsystem/etc/apt/apt.conf.d/01norecommend <<EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
cat > /var/lib/subsystem/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
    chmod +x /var/lib/subsystem/usr/sbin/policy-rc.d
}

if [[ -d /var/lib/subsystem/usr/share/ ]]; then
    exit 0
fi

tool_init
system_init