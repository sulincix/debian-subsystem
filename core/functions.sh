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
isroot(){
    if [[ $UID -ne 0 ]] ; then
        echo "You must be root! $UID" 
        exit 1
    fi
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
check_update(){
    cd /tmp
    if [[ "$(iniparser /etc/debian.conf default updates)" != "false" ]] ; then
        msg "Info" "updates disabled by config"
        return
    fi
    CHECK_URL="https://gitlab.com/sulincix/debian-subsystem"
    timeout 3 $wget -c "${CHECK_URL}/-/raw/master/debian/changelog" -O ver &>/dev/null || return 1
    if  [[ "$(md5sum ver | cut -f 1 -d ' ')" != "$(md5sum /usr/lib/sulin/dsl/changelog  | cut -f 1 -d ' ')" ]] ; then
        msg "Info" "new version available."
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
        msg "Info" "Done"
    fi
    rm -f /tmp/ver &>/dev/null
}

common_init(){
    if [[ -f ${DESTDIR}/run/debian ]] ; then
        return
    fi
    mkdir -p ${DESTDIR}/usr/share/applications/
    cp -prf /usr/lib/sulin/dsl/debrun ${DESTDIR}/bin/debrun
    cp -prf /usr/lib/sulin/dsl/hostctl ${DESTDIR}/bin/hostctl
    cp -prf /usr/lib/sulin/dsl/debxdg ${DESTDIR}/bin/debxdg
    cp -prf /usr/lib/sulin/dsl/debxdg.conf ${DESTDIR}/etc/debxdg.conf
    cp -pf /usr/lib/sulin/dsl/d-term.desktop ${DESTDIR}/usr/share/applications/
    cp -prf $(which iniparser) ${DESTDIR}/bin/iniparser
    chown root ${DESTDIR}/bin/debrun
    chmod u+s ${DESTDIR}/bin/debrun
    if [[ -f /usr/lib/sulin/dsl/pkexec-fake ]] ; then
        cp -prf /usr/lib/sulin/dsl/pkexec-fake ${DESTDIR}/usr/bin/pkexec
        chown root ${DESTDIR}/usr/bin/pkexec
        chmod u+s ${DESTDIR}/usr/bin/pkexec
    fi
    mkdir -p /usr/lib/sulin/dsl/share ${DESTDIR}/var/share
    for dir in icons themes fonts ; do
        ln -s ../../usr/share/$dir  ${DESTDIR}/var/share/$dir 2>/dev/null || true
        ln -s ../../../../share/$dir /usr/lib/sulin/dsl/share/$dir 2>/dev/null || true
    done
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

system_check(){
    set -e
    force_permissive=$(iniparser /etc/debian.conf "default" "force_permissive")
    if [[ ${force_permissive} != "false" ]] ; then
        setenforce 0 &>/dev/null || true
        sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/sysconfig/selinux &>/dev/null || true
    fi
    if [[ -f /usr/lib/sulin/dsl/distro/${DIST} ]] ; then
        source /usr/lib/sulin/dsl/distro/${DIST}
    else
        source /usr/lib/sulin/dsl/distro/debian
    fi
    tool_init
    system_init
    if [[ ! -d "${DESTDIR}/home/${USERNAME}" ]] ; then
        create_user
    fi
    common_init
    sync_gid
    sync_desktop
    bind_system
    bind_extra
}

bind_system(){
    for i in proc root; do
        if ! mount | grep "${DESTDIR}/$i" &>/dev/null ; then
            mount --make-private --bind /$i "${DESTDIR}/$i"
        fi
    done
    if ! mount | grep "${DESTDIR}/tmp" &>/dev/null ; then
        mount --make-private --bind /tmp "${DESTDIR}/tmp"
    fi
    if ! mount | grep "${DESTDIR}/dev" &>/dev/null ; then
        isolate_dev=$(iniparser /etc/debian.conf "default" "isolate_dev")
        if [[ "${isolate_dev}" != "false" ]] ; then
            mount --make-private -t tmpfs tmpfs "${DESTDIR}/dev"
            mkdir -p "${DESTDIR}/dev/pts" "${DESTDIR}/dev/shm"
            mknod -m 666 "${DESTDIR}"/dev/full c 1 7
            mknod -m 666 "${DESTDIR}"/dev/ptmx c 5 2
            mknod -m 644 "${DESTDIR}"/dev/random c 1 8
            mknod -m 644 "${DESTDIR}"/dev/urandom c 1 9
            mknod -m 777 "${DESTDIR}"/dev/null c 1 3
            mknod -m 666 "${DESTDIR}"/dev/zero c 1 5
            mknod -m 666 "${DESTDIR}"/dev/tty c 5 0
        else
            mount -o ro --make-private --bind /dev "${DESTDIR}/dev"
        fi
        mount -o ro --make-private -t devpts devpts "${DESTDIR}/dev/pts"
        mount --make-private -t tmpfs tmpfs "${DESTDIR}/dev/shm"
    fi
    if ! mount | grep "${DESTDIR}/sys" &>/dev/null ; then
        mount -o ro --make-private -t sysfs sysfs "${DESTDIR}/sys"
    fi
    if ! mount | grep "${DESTDIR}/run" &>/dev/null ; then
        mount --make-private -t tmpfs tmpfs "${DESTDIR}/run"
        mkdir -p "${DESTDIR}/run/user/1000/cache"
        chroot "${DESTDIR}"  chown ${USERNAME} -R "/run/user/1000"
    fi
}

bind_extra(){
    mkdir -p "${DESTDIR}/home" || true
    if ! mount | grep "${DESTDIR}/home" &>/dev/null ; then
        common_home=$(iniparser /etc/debian.conf "default" "common_home")
        if [[ ${common_home} != "false" ]] ; then
            mount --make-private -o rw,nodev,nosuid --bind "/${HOMEDIR}" "${DESTDIR}/home/${USERNAME}"
        fi
    fi
    if ! mount | grep "${DESTDIR}/system" &>/dev/null ; then
        bind_system=$(iniparser /etc/debian.conf "default" "bind_system")
        if [[ ${bind_system} != "false" ]] ; then
            mkdir -p ${DESTDIR}/system
            mount --make-private -o ro,nodev,nosuid,noexec --bind / "${DESTDIR}/system"
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
            mount --bind /dev/null $dev || true        
        done
    fi
    
}
umount_all(){
    for i in system dev/pts root dev/shm dev sys proc run tmp home/"${USERNAME}" var/lib/flatpak ; do
        msg "Umount" "${DESTDIR}/$i"
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
    rm -rf /usr/share/applications/$SYSTEM
    mkdir -p /usr/share/applications/$SYSTEM
    for file in $(ls "${DESTDIR}"/usr/share/applications); do
        if [[ "$file" == "d-term.desktop" || "$file" == "mimeinfo.cache" ]] ; then
            continue
        fi
        path="${DESTDIR}/usr/share/applications/$file"
        echo -e "[Desktop Entry]" > /usr/share/applications/$SYSTEM/$file
        echo -e "Name="$(iniparser "$path" "Desktop Entry" "Name")" (on $SYSTEM)" >> /usr/share/applications/$SYSTEM/$file
        echo -e "Comment="$(iniparser "$path" "Desktop Entry" "Comment") >> /usr/share/applications/$SYSTEM/$file
        echo -e "Icon="$(iniparser "$path" "Desktop Entry" "Icon") >> /usr/share/applications/$SYSTEM/$file
        echo -e "Exec=debian --hostctl --system \"$SYSTEM\" -c \"$(iniparser "$path" "Desktop Entry" "Exec")\"" >> /usr/share/applications/$SYSTEM/$file
        echo -e "Categories=Debian;$(iniparser "$path" "Desktop Entry" "Categories")" >> /usr/share/applications/$SYSTEM/$file
        echo -e "Type=Application" >> /usr/share/applications/$SYSTEM/$file
        for var in NoDisplay NotShowIn OnlyShowIn Terminal MimeType ; do
            
            if [[ -n $(iniparser "$path" "Desktop Entry" "$var") ]] ; then
                echo -e "$var="$(iniparser "$path" "Desktop Entry" "$var") >> /usr/share/applications/$SYSTEM/$file
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
        exec pidone $(get_chroot) /bin/debrun "$@"
    else
        msg "Info" "Running without PID isolation"
        exec $(get_chroot) /bin/debrun "$@"
    fi
}
get_chroot(){
    use_bwrap=$(iniparser /etc/debian.conf "default" "use_bwrap")
    if which bwrap &>/dev/null && [[ "${use_bwrap}" != "false" ]]; then
        echo "bwrap --bind ${DESTDIR} / --dev /dev "
    elif chroot --help |& head -n 1 | grep -i busybox &>/dev/null ; then
        echo "busybox chroot ${DESTDIR}"
    elif [[ "$ROOTMODE" == 1 ]] ; then
        echo "chroot ${DESTDIR}"
    else
        echo "chroot --userspec ${USERNAME}:${USERNAME} ${DESTDIR}"
    fi
}

fail_exit(){
    msg "Error" "$*"
    echo -n "    => Press any key to exit"
    read -s -n 1 && exit 1
}
