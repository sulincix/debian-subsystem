_chroot()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(command ls /var/lib/subsystem/{sbin,bin,usr/sbin,usr/bin})
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
}
complete -F _chroot lsl

