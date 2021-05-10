msg(){
    echo -e "\033[32;1m$1\033[;0m$2"
}
wsl_block(){
    var=$(uname -r)
    if [[ "$var" == "*Microsoft*" || "$var" == "*WSL*" ]]
    then
        exit 1
    fi
}
debian_init(){
    [[ -f ${DESTDIR}/etc/os-release ]] && echo "Debian already installed" && exit 0
    if ! which debootstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip || fail_exit "Failed to fetch debootstrap source"
        unzip debootstrap.zip  >/dev/null
        cd debootstrap-master
        make >/dev/null || fail_exit "Failed to install debootstrap"
        make install  >/dev/null || fail_exit "Failed to install debootstrap"
        rm -rf /tmp/debootstrap-master
    fi
    [[ $(uname -m) == "x86_64" ]] && arch=amd64
    [[ $(uname -m) == "aarch64" ]] && arch=arm64
    [[ $(uname -m) == "i686" ]] && arch=i386
    [[ "$arch" == "" ]] && echo "Unsupported arch $(uname -m)" && exit 1
    debootstrap --arch=$arch --extractor=ar --no-merged-usr ${DIST} ${DESTDIR} ${REPO} || fail_exit "Failed to install debian chroot"
    msg "Creating user:" "debian"
    chroot ${DESTDIR} useradd debian -d /home/debian -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir ${DESTDIR}/home/debian
    msg "Settings password for:" "root"
    chroot ${DESTDIR} passwd || fail_exit "Failed to set password."
}
debian_check(){
    if [[ ! -f ${DESTDIR}/etc/os-release ]] ; then
        echo "Debian installation not found."
        debian_init
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
    cp -prf /usr/lib/sulin/dsl/debrun.sh ${DESTDIR}/bin/debrun
    cp -prf /usr/lib/sulin/dsl/hostctl ${DESTDIR}/bin/hostctl
    sync_gid
    xhost +localhost &>/dev/null || true
    for e in $(env | sed "s/=.*//g") ; do
        unset "$e" &>/dev/null
    done
    export PATH=${p}
    export DISPLAY=${d}
    if [[ -f ${DESTDIR}/${SHELL} ]] ; then
        export SHELL=${s}
    else
        export SHELL=/bin/bash
    fi
    export TERM=linux
    if [[ $# -eq 0 ]] ; then
        exec pidone busybox chroot ${DESTDIR} debrun /bin/bash
    else
        exec pidone busybox chroot ${DESTDIR} debrun "$*"
    fi
}

fail_exit(){
    echo -e "\033[31;1mError: \033[;0m$*"
    echo -n "    => Press any key to exit"
    read -s -n 1 && exit 1
}
