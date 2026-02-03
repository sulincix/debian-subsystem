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

int cur_uid = -1;
char *subsystem_path = "/var/lib/subsystem"; // Define the subsystem path

int visible debrun_main(int argc, char **argv) {

    mode_t u = umask(0022);
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        fprintf(stderr, "    -u        : kill all subsystem processes\n");
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
        cur_uid = getuid();
        setuid(0);
        cgroup_kill("subsystem");
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
    cgroup_init("subsystem");
    sync_uid(subsystem_path);
    sync_gid(subsystem_path);
    sync_desktop(subsystem_path);
    mount_all(subsystem_path);
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
    execute_sandbox(argv[1], argv+1);
    return 1;
}

