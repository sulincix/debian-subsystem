msg(){
    echo -e "\033[32;1m$1\033[;0m$2"
}

debian_init(){
    [[ -d ${DESTDIR} ]] && echo "Debian already installed" && exit 0
    if ! which debootstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        busybox wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip
        unzip debootstrap.zip  &>/dev/null
        cd debootstrap-master
        make &>/dev/null
        make install  &>/dev/null
        rm -rf /tmp/debootstrap-master
    fi
    [[ $(uname -m) == "x86_64" ]] && arch=amd64
    [[ $(uname -m) == "aarch64" ]] && arch=arm64
    [[ $(uname -m) == "i686" ]] && arch=i386
    [[ "$arch" == "" ]] && echo "Unsupported arch $(uname -m)" && exit 1
    debootstrap --arch=$arch --extractor=ar --no-merged-usr ${DIST} ${DESTDIR} ${REPO}
    msg "Creating user:" "debian"
    chroot ${DESTDIR} useradd debian -d /home/debian -s /bin/bash
    mkdir ${DESTDIR}/home/debian
    msg "Settings password for:" "root"
    chroot ${DESTDIR} passwd
    chmod +x ${DESTDIR}/bin/debrun
}
debian_check(){
    if [[ ! -d ${DESTDIR} ]] ; then
        echo "Debian installation not found."
        debian_init
    fi
    umount_all
    for i in dev sys proc tmp ; do
        mount --make-private --bind /$i ${DESTDIR}/$i
    done
    mkdir -p "${DESTDIR}/home" || true
    mount --bind "/${HOMEDIR}" "${DESTDIR}/home/debian"
}
umount_all(){
    for i in dev/pts dev sys proc run tmp home/debian ; do
        while umount -lf -R ${DESTDIR}/$i/ &>/dev/null ; do
           true
        done
    done
}
run(){
    p=${PATH}
    d=${DISPLAY}
    s=${SHELL}
    cp -prf debrun.sh ${DESTDIR}/bin/debrun
    xhost + &>/dev/null || true
    for e in $(env | sed "s/=.*//g") ; do
        unset "$e" &>/dev/null
    done
    export PATH=${p}
    export DISPLAY=${d}
    export SHELL=${s}
    export TERM=linux
    if [[ $# -eq 0 ]] ; then
        chroot ${DESTDIR} debrun /bin/bash
    else
        chroot ${DESTDIR} debrun "$*"
    fi
    xhost - &>/dev/null || true
    umount_all
}
