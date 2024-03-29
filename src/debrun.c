#define _GNU_SOURCE
#include <stdio.h>
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


static int argc;
static char** argv;

int debrun_main(int argc, char **argv) {
    umask(0022);
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    if(strcmp(argv[1], "-u") == 0){
        umount_all();
        return 0;
    }
    char cur_dir[1024];
    getcwd(cur_dir, sizeof(cur_dir));
    uid_t cur_uid = getuid();
    setuid(0);
    if (getuid() != 0) {
        fprintf(stderr, "Root privileges required.\n");
        exit(EXIT_FAILURE);
    }
    directory_init();
    mount_all();
    sync_uid("/var/lib/subsystem/");
    sync_gid("/var/lib/subsystem/");
    sync_desktop();
    if (chroot("/var/lib/subsystem") != 0) {
        perror("chroot");
        exit(EXIT_FAILURE);
    }

    setuid(cur_uid);
    chdir(cur_dir);
    // noninteractive mode
    setenv("DEBIAN_FRONTEND", "noninteractive",1);
    setenv("DEBCONF_NONINTERACTIVE_SEEN", "true",1);
    execvp(argv[1], &argv[1]);
    return 1;
}

