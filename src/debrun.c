#define _GNU_SOURCE
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <sched.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <string.h>
#include <dirent.h>

#include <lsl.h>

uid_t cur_uid;

int visible debrun_main(int argc, char **argv) {

    mode_t u = umask(0022);
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    if(strcmp(argv[1], "-u") == 0){
        cgroup_kill();
        umount_all();
        return 0;
    }
    char cur_dir[1024];
    getcwd(cur_dir, sizeof(cur_dir));
    cur_uid = getuid();
    setuid(0);
    if (getuid() != 0) {
        fprintf(stderr, "Root privileges required.\n");
        exit(EXIT_FAILURE);
    }
    disable_selinux();
    directory_init();
    cgroup_init();
    mount_all();
    sync_uid("/var/lib/subsystem/");
    sync_gid("/var/lib/subsystem/");
    sync_desktop();
    if (chroot("/var/lib/subsystem") != 0) {
        perror("chroot");
        exit(EXIT_FAILURE);
    }
    chdir(cur_dir);
    // noninteractive mode
    setenv("DEBIAN_FRONTEND", "noninteractive",1);
    setenv("DEBCONF_NONINTERACTIVE_SEEN", "true",1);
    setenv("TERM", "linux",1);
    umask(u);
    execute_sandbox(argv[1], &argv[1]);
    return 1;
}


static bool is_running(){
     struct stat st;
     stat("/sys/fs/cgroup/debian/cgroup.procs", &st);
     return st.st_size != 0;
}

void visible pam_begin(){
    mode_t u = umask(0022);
    sync_uid("/var/lib/subsystem/");
    sync_gid("/var/lib/subsystem/");
    sync_desktop();
    mount_all();
    umask(u);
}

void visible pam_exit(){
    create_dir("/sys/fs/cgroup/debian");
    if(!is_running()){
        umount_all();
    }
}
