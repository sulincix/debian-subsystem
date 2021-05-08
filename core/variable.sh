[[ "$DIST" == "" ]] && DIST="stable"
[[ "$REPO" == "" ]] && REPO="https://deb.debian.org/debian"
[[ "$DESTDIR" == "" ]] && DESTDIR="/var/debian"
if [[ "$HOMEDIR" == "" ]] ; then
   HOMEDIR="$(cat /etc/passwd | grep 1000 | cut -d ":" -f 6)"
fi
