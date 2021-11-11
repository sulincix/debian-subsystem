set -e
if [[ "$NO_COLOR" == "" ]] ; then
    msg(){
        col="32"
        [[ "$1" == "Error" ]] && col=31
        echo -e "\033[$col;1m$1\033[;0m $2"
    }
else
    msg(){
        echo "$1 $2"
    }
fi
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
    timeout 3 $wget -c "${CHECK_URL}/-/raw/master/core/version" -O ver &>/dev/null || return 1
    if  [[ "$(md5sum ver | cut -f 1 -d ' ')" != "$(md5sum /usr/lib/sulin/dsl/version  | cut -f 1 -d ' ')" ]] ; then
        msg "Info" "new version available."
        msg "Info" "unmounting debian and stop hostctl"
        umount_all
        ps ax  | grep -v grep | grep hostctl-daemon | trim | cut  -d " " -f 1 | xargs kill -9 &>/dev/null || true
        msg "Info" "downloading"
        $wget -c "${CHECK_URL}/-/archive/master/debian-subsystem-master.zip" &>/dev/null || return 0
        unzip debian-subsystem-master.zip >/dev/null
        cd debian-subsystem-master
        msg "Info" "installing"
        make >/dev/null || return 0
        make install  >/dev/null || return 0
        msg "Info" "clearing"
        rm -rf /tmp/debian-subsystem-master
        msg "Info" "Installation finished."
        cd /usr/lib/sulin/dsl
        msg "Info" "Restarting"
        exec $0 $@
    fi
    rm -f /tmp/ver &>/dev/null
}
debian_init(){
    ls ${DESTDIR}/etc/os-release &>/dev/null && return 0
    if ! which debootstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        $wget -c "https://salsa.debian.org/installer-team/debootstrap/-/archive/master/debootstrap-master.zip" -O debootstrap.zip || fail_exit "Failed to fetch debootstrap source"
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
    [[ "$arch" == "" ]] && msg "Error" "Unsupported arch $(uname -m)" && exit 1
    if [[ "$DIST" == "ubuntu-latest" ]] ; then
        DIST=$($wget -O - https://cdimage.ubuntu.com/daily-live/current/  | grep "desktop-amd64.iso" | head -n 1 | sed "s/.*href=\"//g;s/-.*//g")
    fi
    
    ls /usr/share/debootstrap/scripts/${DIST} &>/dev/null || ln -s stable /usr/share/debootstrap/scripts/${DIST}
    debootstrap --arch=$arch --extractor=ar --no-merged-usr --no-check-gpg --extractor=ar "${DIST}" "${DESTDIR}" "${REPO}" || fail_exit "Failed to install debian chroot"
    cp -pf /usr/lib/sulin/dsl/data/99hostctl ${DESTDIR}/etc/apt/apt.conf.d/99hostctl
    msg "Creating user:" "debian"
    chroot "${DESTDIR}" useradd "${USERNAME}" -d "/home/${USERNAME}" -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/home/${USERNAME}"
}
arch_init(){
    ls ${DESTDIR}/usr/lib/os-release &>/dev/null && return 0
    if ! which archstrap &>/dev/null; then
        msg "Installing:" "debootstrap"
        cd /tmp
        $wget -c "https://gitlab.com/tearch-linux/applications-and-tools/archstrap/-/raw/master/archstrap.sh" -O archstrap.sh || fail_exit "Failed to fetch arch-bootstrap"
        cp -fp archstrap.sh /usr/bin/archstrap
        chmod 755 /usr/bin/archstrap
    fi
    arch="$(uname -m)"
    archstrap "${DESTDIR}" -r "${REPO}" || fail_exit "Failed to install archlinux chroot"
    sync
    cp -pf /usr/lib/sulin/dsl/data/hostctl-alpm.hook ${DESTDIR}/usr/share/libalpm/hooks/hostctl-alpm.hook
    msg "Creating user:" "debian"
    chroot "${DESTDIR}" useradd "${USERNAME}" -d "/home/${USERNAME}" -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/home/${USERNAME}"
}
alpine_init(){
ls ${DESTDIR}/etc/alpine-release &>/dev/null && return 0
    if ! which apk &>/dev/null; then
        msg "Installing:" "apk-tools"
        mkdir -p /tmp/apk
        cd /tmp/apk
        arch="$(uname -m)"
        apktools=$($wget -O - https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$arch/ | grep "apk-tools-static" | sed "s/^.*=\"//g;s/\".*//g")
        $wget -c "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/$arch/$apktools" -O apk-tools-static.apk || fail_exit "Failed to fetch apt-tools"
        tar -zxf apk-tools-static.apk
        cp -pf sbin/apk.static /bin/apk
        chmod +x /bin/apk
    fi
    arch="$(uname -m)"
    apk --arch $arch -X "${REPO}/main/" -U --allow-untrusted --root ${DESTDIR} --initdb add alpine-base bash || fail_exit "Failed to install archlinux chroot"
    sync
    echo "${REPO}/main/" > ${DESTDIR}/etc/apk/repositories
    echo "${REPO}/community/" >> ${DESTDIR}/etc/apk/repositories
    msg "Creating user:" "debian"
    chroot "${DESTDIR}" adduser "${USERNAME}" -D -H -h "/home/${USERNAME}" -s /bin/ash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/home/"${USERNAME}""
}
sulin_init(){
    ls ${DESTDIR}/data/user &>/dev/null && return 0
    if ! which sulinstrapt &>/dev/null ; then
        msg "Installing:" "sulinstrapt"
        cd /tmp
        $wget -c "https://gitlab.com/sulinos/devel/inary/-/raw/develop/scripts/sulinstrapt" -O sulinstrapt.sh || fail_exit "Failed to fetch arch-bootstrap"
        cp -fp sulinstrapt.sh /usr/bin/sulinstrapt
        chmod 755 /usr/bin/sulinstrapt
    fi
    sulinstrapt "${DESTDIR}" -r "${REPO}"
    chroot "${DESTDIR}" useradd d"${USERNAME}" -d "/data/user/${USERNAME}" -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/data/user/${USERNAME}" || true
}
void_init(){
    ls ${DESTDIR}/etc/os-release &>/dev/null && return 0
    if ! which xbps-static &>/dev/null ; then
        msg "Installing:" "xbps-static"
        cd /tmp
        arch="$(uname -m)"
        $wget -c "https://alpha.de.repo.voidlinux.org/static/xbps-static-latest.$arch-musl.tar.xz" -O xbps-static-latest.x86_64-musl.tar.xz
        tar -xf xbps-static-latest.x86_64-musl.tar.xz
        cp -pf ./usr/bin/xbps-install.static /bin/xbps-install
    fi
    yes | SSL_NO_VERIFY_PEER=1 XBPS_ARCH=$arch xbps-install -f -S -r ${DESTDIR} -R "$REPO" base-system -y
    chroot "${DESTDIR}" useradd "${USERNAME}" -d "/home/${USERNAME}" -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/home/${USERNAME}"
}
gentoo_init(){
    ls ${DESTDIR}/etc/make.conf &>/dev/null && return 0
    stage3=$($wget -O - https://www.gentoo.org/downloads/ | sed "s/.*href=\"//g" | sed "s/\".*//g" | grep "tar\." | grep -v "systemd" | \
             grep -v "nomultilib" | grep -v "musl" | grep "amd64-" | grep -v "hardened" | sort -V | head -n 1)
    curdir="$(pwd)"
    mkdir -p ${DESTDIR} || true
    cd ${DESTDIR} ; $wget -c "$stage3" -O gentoo.tar.xz ; tar -xvf /tmp/gentoo.tar.xz
    rm -f gentoo.tar.xz
    echo -e "GENTOO_MIRRORS=\"${REPO}\"" >> ${DESTDIR}/etc/make.conf
    chroot "${DESTDIR}" useradd "${USERNAME}" -d "/home/${USERNAME}" -s /bin/bash || fail_exit "Failed to create debian user"
    mkdir -p "${DESTDIR}/home/${USERNAME}"
}

common_init(){
    force_permissive=$(iniparser /etc/debian.conf "default" "force_permissive")
    if [[ ${force_permissive} != "false" ]] ; then
        setenforce 0 &>/dev/null || true
    fi
    chmod +x /usr/lib/sulin/dsl/* 
    cp -prf /usr/lib/sulin/dsl/debrun.sh ${DESTDIR}/bin/debrun
    cp -prf /usr/lib/sulin/dsl/hostctl ${DESTDIR}/bin/hostctl
    cp -prf /usr/lib/sulin/dsl/debxdg ${DESTDIR}/bin/debxdg
    cp -prf /usr/lib/sulin/dsl/debxdg.conf ${DESTDIR}/etc/debxdg.conf
    [[ -f ${DESTDIR}/bin/iniparser ]] || cp -prf $(which iniparser) ${DESTDIR}/bin/iniparser
    if [[ -f /usr/lib/sulin/dsl/pkexec-fake ]] ; then
        cp -prf /usr/lib/sulin/dsl/pkexec-fake ${DESTDIR}/usr/bin/pkexec
    fi
    if [[ ! -d ${DESTDIR}/var/share ]] ; then
        mkdir -p ${DESTDIR}/var/share
        ln -s ../../usr/share/icons  ${DESTDIR}/var/share/icons
        ln -s ../../usr/share/themes  ${DESTDIR}/var/share/themes
    fi
    if [[ ! -d /usr/lib/sulin/dsl/share ]] ; then
        mkdir -p /usr/lib/sulin/dsl/share
        ln -s ../../../../share/icons /usr/lib/sulin/dsl/share/icons
        ln -s ../../../../share/themes /usr/lib/sulin/dsl/share/themes
    fi
    cat /etc/machine-id > ${DESTDIR}/etc/machine-id
    rm -f ${DESTDIR}/etc/resolv.conf &>/dev/null|| true
    cat /etc/resolv.conf > ${DESTDIR}/etc/resolv.conf
    if [[ "$(readlink /bin/sh)" != "bash" ]] ; then
        rm -f /bin/sh
        ln -s bash /bin/sh
    fi
    chmod 777 "${DESTDIR}/tmp"
    local username="$(grep '1000' /etc/passwd | cut -f 1 -d ':')"
    if which pactl &>/dev/null; then
        if  su "$username" -c "pactl list short modules" |& grep "module-native-protocol-tcp" &>/dev/null; then
            true
        else
            su "$username" -c "pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1  &>/dev/null" || true
        fi
    fi
}

debian_check(){
    set -e
    if [[ "$(iniparser /etc/debian.conf default updates)" != "true" ]] ; then
        check_update
    fi
    if [[ "${DIST}" == "arch" ]] ; then
        arch_init
    elif [[ "${DIST}" == "alpine" ]] ; then
        alpine_init
    elif [[ "${DIST}" == "sulin" ]] ; then
        sulin_init
    elif [[ "${DIST}" == "void" ]] ; then
        void_init
    elif [[ "${DIST}" == "gentoo" ]] ; then
        gentoo_init
    else
        debian_init
    fi
    common_init
    sync_gid
    sync_desktop
    for i in proc root tmp; do
        if ! mount | grep "${DESTDIR}/$i" &>/dev/null ; then
            mount --make-private --bind /$i "${DESTDIR}/$i"
        fi
    done
    for i in  dev sys dev/pts ; do
        if ! mount | grep "${DESTDIR}/$i" &>/dev/null ; then
            mount -o ro --make-private --bind /$i "${DESTDIR}/$i"
        fi
    done
    if ! mount | grep "${DESTDIR}/run" &>/dev/null ; then
        mount --make-private -t tmpfs tmpfs "${DESTDIR}/run"
    fi
    if ! mount | grep "${DESTDIR}/dev/shm" &>/dev/null ; then
        mount --make-private -t tmpfs tmpfs "${DESTDIR}/dev/shm"
    fi
    mkdir -p "${DESTDIR}/home" || true
    if ! mount | grep "${DESTDIR}/home" &>/dev/null ; then
        common_home=$(iniparser /etc/debian.conf "default" "common_home")
        if [[ ${common_home} != "false" ]] ; then
            mount --make-private --bind "/${HOMEDIR}" "${DESTDIR}/home/${USERNAME}"
        fi
    fi
    if [[ -d ${DESTDIR}/usr/share/applications/ ]] ; then
        cp -pf /usr/lib/sulin/dsl/d-term.desktop ${DESTDIR}/usr/share/applications/
    fi
    if [[ ! -d ${DESTDIR}/system ]] ; then
        mkdir -p ${DESTDIR}/system || true
    fi
    if ! mount | grep "${DESTDIR}/system" &>/dev/null ; then
        bind_system=$(iniparser /etc/debian.conf "default" "bind_system")
        if [[ ${bind_system} != "false" ]] ; then
            mount --make-private -o ro --bind / "${DESTDIR}/system"
        else
            rmdir "${DESTDIR}/system" &>/dev/null || true
        fi
    fi
    common_flatpak=$(iniparser /etc/debian.conf "default" "common_flatpak")
    if [[ ${common_flatpak} != "false" && -d /var/lib/flatpak ]] ; then
        if ! mount | grep "${DESTDIR}/var/lib/flatpak" &>/dev/null ; then
            mkdir -p "${DESTDIR}/var/lib/flatpak" || true
            mount --make-private --bind "/var/lib/flatpak" "${DESTDIR}/var/lib/flatpak"
        fi
    fi
    block_camera=$(iniparser /etc/debian.conf "default" "block_camera")
    if [[ ${block_camera} != "false" ]] ; then
        for dev in $(ls ${DESTDIR}/dev/video* 2>/dev/null) ; do
            rm -f $dev || true        
        done
        
    fi
    
}
umount_all(){
    for i in system dev/pts root dev/shm dev sys proc run tmp home/"${USERNAME}" var/lib/flatpak ; do
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

sync_desktop(){
    [[ ! -d "${DESTDIR}"/usr/share/applications ]] && return 0
    touch "${DESTDIR}/var/cache/app-ltime"
    mtime=$(stat "${DESTDIR}"/usr/share/applications | grep Modify)
    ltime=$(cat "${DESTDIR}/var/cache/app-ltime")
    if [[ "$mtime" == "$ltime" ]] ; then
        return
    fi
    rm -rf /usr/share/applications/debian
    mkdir -p /usr/share/applications/debian
    for file in $(ls "${DESTDIR}"/usr/share/applications); do
        if [[ "$file" == "d-term.desktop" || "$file" == "mimeinfo.cache" ]] ; then
            continue
        fi
        path="${DESTDIR}/usr/share/applications/$file"
        echo -e "[Desktop Entry]" > /usr/share/applications/debian/$file
        echo -e "Name="$(iniparser "$path" "Desktop Entry" "Name")" (on $(iniparser /etc/debian.conf default system))" >> /usr/share/applications/debian/$file
        echo -e "Comment="$(iniparser "$path" "Desktop Entry" "Comment") >> /usr/share/applications/debian/$file
        echo -e "Icon="$(iniparser "$path" "Desktop Entry" "Icon") >> /usr/share/applications/debian/$file
        echo -e "Exec=debian --hostctl -c \"$(iniparser "$path" "Desktop Entry" "Exec")\"" >> /usr/share/applications/debian/$file
        echo -e "Categories=Debian;$(iniparser "$path" "Desktop Entry" "Categories")" >> /usr/share/applications/debian/$file
        echo -e "Type=Application" >> /usr/share/applications/debian/$file
        for var in NoDisplay NotShowIn OnlyShowIn Terminal MimeType ; do
            
            if [[ -n $(iniparser "$path" "Desktop Entry" "$var") ]] ; then
                echo -e "$var="$(iniparser "$path" "Desktop Entry" "$var") >> /usr/share/applications/debian/$file
            fi
        done
    done
    if [[ -d ${DESTDIR}/usr/share/applications/ ]] ; then
        stat "${DESTDIR}"/usr/share/applications | grep Modify > "${DESTDIR}/var/cache/app-ltime"
    fi
}

run(){
    p=${PATH}
    d=${DISPLAY}
    s=${SHELL}
    b=${SYSTEM}
    r=${ROOTMODE}
    u=${USERNAME}
    xhost +localhost &>/dev/null || true
    for e in $(env | sed "s/=.*//g") ; do
        unset "$e" &>/dev/null || true
    done
    export PATH="/bin:/sbin:"${p}
    export DISPLAY=${d}
    export SYSTEM=${b}
    export ROOTMODE=${r}
    export USERNAME=${u}
    if [[ -f ${DESTDIR}/${SHELL} ]] ; then
        export SHELL=${s}
    else
        export SHELL=/bin/bash
    fi
    export TERM=linux
    chroot ${DESTDIR} debrun true || exit 1
    use_pidone=$(iniparser /etc/debian.conf "default" "pidone")
    if [[ ! -n $nopidone && ${use_pidone} != "false" ]] ; then
        exec pidone $(get_chroot) ${DESTDIR} debrun "$@"
    else
        msg "Info" "Running without PID isolation"
        exec $(get_chroot) ${DESTDIR} debrun "$@"
    fi
}
get_chroot(){
    if chroot --help |& head -n 1 | grep -i busybox &>/dev/null ; then
        echo "busybox chroot"
    elif [[ "$ROOTMODE" == 1 ]] ; then
        echo "chroot"
    else
        echo "chroot --userspec ${USERNAME}:${USERNAME}"
    fi
}

fail_exit(){
    msg "Error" "$*"
    echo -n "    => Press any key to exit"
    read -s -n 1 && exit 1
}
