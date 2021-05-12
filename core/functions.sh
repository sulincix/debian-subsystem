msg(){
    echo -e "\033[32;1m$1\033[;0m $2"
}
wsl_block(){
    var=$(uname -r)
    [[ ! -f /proc/cpuinfo ]] && return 1
    if [[ "$var" == "*Microsoft*" || "$var" == "*microsoft*" || "$var" == "*WSL*" ]] \
    || cat /proc/cpuinfo | grep "microcode" | grep "0xffffffff" &>/dev/null
    then
        return 1
    fi
}
trim(){
    while read line ; do
        echo $line
    done
}
check_update(){
    cd /tmp
    CHECK_URL="https://gitlab.com/sulincix/debian-subsystem"
    timeout 3 wget -c "${CHECK_URL}/-/raw/master/core/version" -O ver &>/dev/null || return 0
    if  [[ "$(md5sum ver | cut -f 1 -d ' ')" != "$(md5sum /usr/lib/sulin/dsl/version  | cut -f 1 -d ' ')" ]] ; then
        msg "Info" "new version available."
        msg "Info" "unmounting debian and stop hostctl"
        umount_all
        ps ax  | grep -v grep | grep hostctl-daemon | trim | cut  -d " " -f 1 | xargs kill -9 &>/dev/null || true
        msg "Info" "downloading"
        wget -c "${CHECK_URL}/-/archive/master/debian-subsystem-master.zip" &>/dev/null || return 0
        unzip debian-subsystem-master.zip >/dev/null
        cd debian-subsystem-master
        msg "Info" "installing"
        make >/dev/null || return 0
        make install  >/dev/null || return 0
        msg "Info" "clearing"
        rm -rf /tmp/debian-subsystem-master /tmp/ver
        msg "Info" "Installation finished."
        cd /usr/lib/sulin/dsl
        msg "Info" "Restarting"
        exec $0 $@
    fi
}
debian_init(){
    ls ${DESTDIR}/etc/os-release &>/dev/null && echo "Debian already installed" && exit 0
    if ! which debootstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip || fail_exit "Failed to fetch debootstrap source"
        unzip debootstrap.zip  >/dev/null
        cd debootstrap-master
        make >/dev/null || fail_exit "Failed to install debootstrap"
        make install  >/dev/null || fail_exit "Failed to install debootstrap"
        cd /tmp
        rm -rf /tmp/debootstrap-master
    fi
    [[ $(uname -m) == "x86_64" ]] && arch=amd64
    [[ $(uname -m) == "aarch64" ]] && arch=arm64
    [[ $(uname -m) == "i686" ]] && arch=i386
    [[ "$arch" == "" ]] && echo "Unsupported arch $(uname -m)" && exit 1
    debootstrap --arch=$arch --extractor=ar --no-merged-usr "${DIST}" "${DESTDIR}" "${REPO}" || fail_exit "Failed to install debian chroot"
    msg "Creating user:" "debian"
    chroot ${DESTDIR} useradd debian -d /home/debian -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir ${DESTDIR}/home/debian
    msg "Settings password for:" "root"
    chroot ${DESTDIR} passwd || fail_exit "Failed to set password."
}
arch_init(){
    ls ${DESTDIR}/etc/os-release &>/dev/null && echo "Archlinux already installed" && exit 0
    if ! which arch-bootstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        wget -c "https://raw.githubusercontent.com/tokland/arch-bootstrap/master/arch-bootstrap.sh" -O arch-bootstrap.sh || fail_exit "Failed to fetch arch-bootstrap"
        cp -fp arch-bootstrap.sh /usr/bin/arch-bootstrap
        chmod 755 /usr/bin/arch-bootstrap
    fi
    arch="$(uname -m)"
    arch-bootstrap -a "$arch" -r "${REPO}" -d "${DESTDIR}/pkgs" "${DESTDIR}" || fail_exit "Failed to install archlinux chroot"
    msg "Creating user:" "debian"
    chroot ${DESTDIR} useradd debian -d /home/debian -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir ${DESTDIR}/home/debian
    msg "Settings password for:" "root"
    chroot ${DESTDIR} passwd || fail_exit "Failed to set password."
}
debian_check(){
    if [[ $(iniparser /etc/debian.conf "default" "updates") != "false" ]] ; then
        check_update
    fi
    if [[ ! -f ${DESTDIR}/etc/os-release ]] ; then
        echo "Debian installation not found."
        if [[ "${DIST}" == "arch" ]] ; then
            arch_init
        else
            debian_init
        fi
    fi
    #umount_all
    for i in proc root run dev sys tmp dev/pts ; do
        if ! mount | grep "${DESTDIR}/$i" &>/dev/null ; then
            pidone mount --make-private --bind /$i "${DESTDIR}/$i"
        fi
    done
    if ! mount | grep "${DESTDIR}/dev/shm" &>/dev/null ; then
        mount -t tmpfs tmpfs "${DESTDIR}/dev/shm"
    fi
    mkdir -p "${DESTDIR}/home" || true
    if ! mount | grep "${DESTDIR}/home" &>/dev/null ; then
        mount --bind "/${HOMEDIR}" "${DESTDIR}/home/debian"
    fi
    if ! mount | grep "${DESTDIR}/run" &>/dev/null ; then
        mount -t tmpfs tmpfs ${DESTDIR}/run
    fi
    if [[ ! -d ${DESTDIR}/usr/share/applications/ ]] ; then
        mkdir -p ${DESTDIR}/usr/share/applications/ &>/dev/null || true
        cp -pf /usr/lib/sulin/dsl/d-term.desktop ${DESTDIR}/usr/share/applications/
    fi
    if [[ ! -d ${DESTDIR}/system ]] ; then
        mkdir -p ${DESTDIR}/system || true
    fi
    if ! mount | grep "${DESTDIR}/system" &>/dev/null ; then
        mount --make-private --bind / "${DESTDIR}/system"
    fi
    
}
umount_all(){
    for i in system dev/pts dev/shm dev sys proc run tmp home/debian ; do
        while umount -lf -R ${DESTDIR}/$i/ &>/dev/null ; do
           true
        done
    done
}

sync_gid(){
    cat /etc/group | while read line ; do
        group=$(echo $line | cut -f 1 -d ":") &>/dev/null
        gid=$(echo $line | cut -f 3 -d ":") &>/dev/null
        if grep "$group" "${DESTDIR}/etc/group" &>/dev/null ; then
            ogid=$(grep "$group" "${DESTDIR}/etc/group" | cut -f 3 -d ":")
            sed -i "s/$group:x:$ogid:/$group:x:$gid:/g" "${DESTDIR}/etc/group" &>/dev/null || true
        fi
    done
}

run(){
    p=${PATH}
    d=${DISPLAY}
    s=${SHELL}
    b=${SYSTEM}
    cp -prf /usr/lib/sulin/dsl/debrun.sh ${DESTDIR}/bin/debrun
    cp -prf /usr/lib/sulin/dsl/hostctl ${DESTDIR}/bin/hostctl
    sync_gid
    xhost +localhost &>/dev/null || true
    for e in $(env | sed "s/=.*//g") ; do
        unset "$e" &>/dev/null
    done
    export PATH=${p}
    export DISPLAY=${d}
    export SYSTEM=${b}
    if [[ -f ${DESTDIR}/${SHELL} ]] ; then
        export SHELL=${s}
    else
        export SHELL=/bin/bash
    fi
    export TERM=linux
    busybox chroot ${DESTDIR} debrun true || exit 1
    use_pidone=$(iniparser /etc/debian.conf "default" "pidone")
    if [[ ! -n $nopidone && ${use_pidone} != "false" ]] ; then
        exec pidone $(get_chroot) ${DESTDIR} debrun "$@"
    else
        echo "Running without PID isolation"
        exec $(get_chroot) ${DESTDIR} debrun "$@"
    fi
}
get_chroot(){
    if chroot --help |& head -n 1 | grep -i busybox ; then
        echo "busybox chroot"
    else
        echo "chroot --userspec debian:debian"
    fi
}
fail_exit(){
    echo -e "\033[31;1mError: \033[;0m$*"
    echo -n "    => Press any key to exit"
    read -s -n 1 && exit 1
}
