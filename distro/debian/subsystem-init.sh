#!/bin/bash
set -e
set -o pipefail
if ! command -v gettext &>/dev/null; then
    _(){
        echo "$@"
    }
else
    _(){
        "gettext" "lsl" "$@" ; echo
    }
fi
_ "Initial Setup Required. The Debian base will be downloaded."
_ "Do you want to continue? [Y/n]"
read -n 1 c

if ! [[ "$c" == "Y" || "$c" == "y" ]] ; then
    exit 1
fi

fail_exit(){
    echo "$@"
    _ "press any key to exit"
    read -n 1
    exit 1
}
command_check(){
    cmds=(which ls make wget unzip perl)
    for cmd in ${cmds[@]} ; do
        command -v "$cmd" >/dev/null || fail_exit "$cmd "$(_ "not found")
    done
}
tool_init(){
    _ "Installing debootstrap"
    which debootstrap &>/dev/null && return 0
    command_check
    cd /tmp
    wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip || fail_exit "Failed to fetch debootstrap source"
    unzip debootstrap.zip  >/dev/null
    cd debootstrap-master
    make >/dev/null || fail_exit $(_ "Failed to install debootstrap")
    make install  >/dev/null || fail_exit $(_ "Failed to install debootstrap")
    cd /tmp
    rm -rf /tmp/debootstrap-master
}

system_init(){
    [[ $(uname -m) == "x86_64" ]] && arch=amd64
    [[ $(uname -m) == "aarch64" ]] && arch=arm64
    [[ $(uname -m) == "i686" ]] && arch=i386
    [[ "$arch" == "" ]] && fail_exit $(_ "Unsupported arch")" $(uname -m)"
    /usr/sbin/debootstrap --variant=minbase --arch=$arch --extractor=ar --no-check-gpg --extractor=ar stable /var/lib/subsystem/rootfs
    ls /var/lib/subsystem/ | while read line ; do
        rm -rf /var/lib/subsystem/$line || true
    done
    mv /var/lib/subsystem/rootfs/* /var/lib/subsystem/
    cat /etc/machine-id > /var/lib/subsystem/etc/machine-id
cat > /var/lib/subsystem/etc/apt/apt.conf.d/01norecommend <<EOF
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF
cat > /var/lib/subsystem/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
    chmod +x /var/lib/subsystem/usr/sbin/policy-rc.d
    if [ -f /etc/locale.gen ] ; then
        cat /etc/locale.gen > /var/lib/subsystem/etc/locale.gen
        chroot /var/lib/subsystem locale-gen
    fi
    # convert to nosystemd
    chroot /var/lib/subsystem/ apt install libpam-elogind -yq
    chroot /var/lib/subsystem/ apt-mark hold systemd
    ln -s true /bin/systemctl
}

if [[ -d /var/lib/subsystem/usr/share/ ]]; then
    exit 0
fi

tool_init
system_init

