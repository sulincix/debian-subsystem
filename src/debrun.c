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

#define MOUNTS_FILE "/proc/mounts"

static int argc;
static char** argv;

int is_mount(const char *path) {
    FILE *fp = fopen(MOUNTS_FILE, "r");
    if (fp == NULL) {
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    char line[512];
    char mount_point[256], device[256], mount_type[256];

    while (fgets(line, sizeof(line), fp) != NULL) {
        if (sscanf(line, "%255s %255s %255s", mount_point, device, mount_type) == 3) {
            if (strcmp(path, device) == 0) {
                fclose(fp);
                return 1;
            }
        }
    }

    fclose(fp);
    return 0;
}

int isdir(char *path){
    if(path == NULL){
        return 0;
    }
    DIR* dir = opendir(path);
    if(dir){
        closedir(dir);
        return 1;
    }else{
        return 0;
    }
}


#define c_mkdir(A, B) \
    if (mkdir(A, B) < 0) { \
        fprintf(stderr, "Error: %s %s\n", "failed to create directory.", A); \
}

void create_dir(const char *dir) {
    char tmp[1024];
    char *p = NULL;
    size_t len;

    snprintf(tmp, sizeof(tmp),"%s",dir);
    len = strlen(tmp);
    if (tmp[len - 1] == '/')
        tmp[len - 1] = 0;
    for (p = tmp + 1; *p; p++)
        if (*p == '/') {
            *p = 0;
            if(!isdir(tmp))
                c_mkdir(tmp, 0755);
            *p = '/';
        }
    if(!isdir(tmp))
        c_mkdir(tmp, 0755);
}



static int debrun_process() {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <command> [args...]\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    uid_t cur_uid = getuid();
    setuid(0);
    if (getuid() != 0) {
        fprintf(stderr, "Root privileges required.\n");
        exit(EXIT_FAILURE);
    }

    sync_uid("/var/lib/subsystem/");
    sync_gid("/var/lib/subsystem/");
    sync_desktop();
    if(!isdir("/var/lib/subsystem/var/lib/lsl/exports/")){
        create_dir("/var/lib/subsystem/var/lib/lsl/exports/");
        create_dir("/var/lib/subsystem/var/lib/lsl/exports/applications");
        create_dir("/var/lib/subsystem/var/lib/lsl/imports/");
        symlink("../../../../usr/share/themes", "/var/lib/subsystem/var/lib/lsl/exports/themes");
        symlink("../../../../usr/share/icons", "/var/lib/subsystem/var/lib/lsl/exports/icons");
        symlink("../../../../usr/share/fonts", "/var/lib/subsystem/var/lib/lsl/exports/fonts");
        symlink("../system/usr/share/themes/", "/var/lib/subsystem/var/lib/lsl/imports/themes");
        symlink("../system/usr/share/icons/", "/var/lib/subsystem/var/lib/lsl/imports/icons");
        symlink("../system/usr/share/fonts/", "/var/lib/subsystem/var/lib/lsl/imports/fonts");
    }
    if(!isdir("/var/lib/subsystem/var/lib/lsl/system/")){
        create_dir("/var/lib/subsystem/var/lib/lsl/system/");

    }
    const char* debian_dirs[] = {"/var/lib/subsystem/home", "/var/lib/subsystem/dev", "/var/lib/subsystem/proc", "/var/lib/subsystem/sys", "/var/lib/subsystem/run"};

    for (int i = 0; i < sizeof(debian_dirs) / sizeof(debian_dirs[0]); ++i) {
        if (!is_mount(debian_dirs[i])) {
            if (mount(debian_dirs[i] + 7, debian_dirs[i], NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }

    if (!is_mount("/var/lib/subsystem/var/lib/lsl/system")) {
        if (mount("/", "/var/lib/subsystem/var/lib/lsl/system", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
        }
    }
    if (chroot("/var/lib/subsystem") != 0) {
        perror("chroot");
        exit(EXIT_FAILURE);
    }

    setuid(cur_uid);

    execvp(argv[1], &argv[1]);
    return 1;
}

#define STACK_SIZE (1024 * 1024) // 1MB stack size for cloned process

static char child_stack[STACK_SIZE];

int debrun_main(int argc_main, char **argv_main) {
    argc = argc_main;
    argv = argv_main;
    // Clone the child process
    pid_t child_pid = clone(debrun_process, child_stack + STACK_SIZE,
                             CLONE_NEWPID | CLONE_NEWNS | SIGCHLD, NULL);
    if (child_pid == -1) {
        perror("Failed to clone");
        exit(EXIT_FAILURE);
    }

    // Wait for the child process to terminate
    if (waitpid(child_pid, NULL, 0) == -1) {
        perror("Failed to wait for child");
        exit(EXIT_FAILURE);
    }

    exit(EXIT_SUCCESS);
}
