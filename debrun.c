#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sched.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <string.h>

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

int debrun_main() {
    if (!is_mount("/debian/proc")) {
        if (mount("proc", "/debian/proc", "proc", 0, NULL) == -1) {
            perror("Failed to mount /proc");
            exit(EXIT_FAILURE);
        }
    }
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

    const char* debian_dirs[] = {"/debian/home", "/debian/etc/passwd", "/debian/dev", "/debian/sys", "/debian/run"};

    for (int i = 0; i < sizeof(debian_dirs) / sizeof(debian_dirs[0]); ++i) {
        if (!is_mount(debian_dirs[i])) {
            if (mount(debian_dirs[i] + 7, debian_dirs[i], NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }

    if (chroot("/debian") != 0) {
        perror("chroot");
        exit(EXIT_FAILURE);
    }

    setuid(cur_uid);

    execvp(argv[1], &argv[1]);
    return 1;
}

#define STACK_SIZE (1024 * 1024) // 1MB stack size for cloned process

static char child_stack[STACK_SIZE];

int main(int argc_main, char **argv_main) {
    argc = argc_main;
    argv = argv_main;
    // Clone the child process
    pid_t child_pid = clone(debrun_main, child_stack + STACK_SIZE,
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
