#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <string.h>

#define MOUNTS_FILE "/proc/mounts"

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

int main(int argc, char** argv) {
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

    const char* debian_dirs[] = {"/debian/home", "/debian/etc/passwd", "/debian/dev", "/debian/sys", "/debian/proc", "/debian/run"};

    for (int i = 0; i < sizeof(debian_dirs) / sizeof(debian_dirs[0]); ++i) {
        if (!is_mount(debian_dirs[i])) {
            if (mount(debian_dirs[i] + 8, debian_dirs[i], NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
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

    pid_t pid = fork();
    if (pid == 0) {
        execvp(argv[1], &argv[1]);
        perror("execvp");
        exit(EXIT_FAILURE);
    } else if (pid < 0) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    int status;
    waitpid(pid, &status, 0);
    
    return status;
}

