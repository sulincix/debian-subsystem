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
char *subsystem_path = "/var/lib/subsystem"; // Define the subsystem path

int visible debrun_main(int argc, char **argv) {

    mode_t u = umask(0022);
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        fprintf(stderr, "    -u        : unbind subsystem\n");
        fprintf(stderr, "    -c <path> : subsystem path\n");
        exit(EXIT_FAILURE);
    }
    if (getenv("LSLPREFIX") != NULL){
        subsystem_path = getenv("LSLPREFIX");
    } else {
        if (strcmp(argv[1], "-c") == 0 && argc > 2) {
            subsystem_path = argv[2];
            argc -=2;
            argv+=2;
        }
    }
    if(strcmp(argv[1], "-u") == 0){
        cgroup_kill(subsystem_path);
        umount_all(subsystem_path);
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
    directory_init(subsystem_path);
    cgroup_init(subsystem_path);
    mount_all(subsystem_path);
    sync_uid(subsystem_path);
    sync_gid(subsystem_path);
    sync_desktop(subsystem_path);
    if (chroot(subsystem_path) != 0) {
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
     char cgroup_procs_path[1024];
     snprintf(cgroup_procs_path, sizeof(cgroup_procs_path), "%s/sys/fs/cgroup/debian/cgroup.procs", subsystem_path);
     stat(cgroup_procs_path, &st);
     return st.st_size != 0;
}

void visible pam_begin(){
    mode_t u = umask(0022);
    sync_uid(subsystem_path);
    sync_gid(subsystem_path);
    sync_desktop(subsystem_path);
    mount_all(subsystem_path);
    umask(u);
}

void visible pam_exit(){
    create_dir(subsystem_path);
    if(!is_running()){
        umount_all(subsystem_path);
    }
}

