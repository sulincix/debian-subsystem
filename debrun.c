#define _GNU_SOURCE
#include <string.h>
#include <aio.h>
#include <stdio.h>
#include <sched.h>
#include <sys/mount.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/statfs.h>

#define MOUNTS_FILE "/proc/mounts"

int is_mount(const char *path) {
    FILE *fp;
    char line[512];
    char mount_point[256], mount_type[256], device[256];
    int bind_mount = 0;

    fp = fopen(MOUNTS_FILE, "r");
    if (fp == NULL) {
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    while (fgets(line, sizeof(line), fp) != NULL) {
        if (sscanf(line, "%255s %255s %255s", mount_point, device, mount_type) == 3) {
            if (strcmp(path, device) == 0) {
                bind_mount = 1;
                break;
            }
        }
    }

    fclose(fp);
    return bind_mount;
}

int main(int argc, char** argv) {
    uid_t cur = getuid();
    char* pwd = getcwd(NULL, 0);
    setuid(0);
    // unshare(CLONE_NEWNS | CLONE_FILES);
    
    if (!is_mount("/debian/home")) {
        // Mount /home if /debian/home doesn't exist
        if (mount("/home", "/debian/home", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /home");
            exit(EXIT_FAILURE);
        }
    }
    
    // Check if /debian/etc/passwd is already mounted
    if (!is_mount("/debian/etc/passwd")) {
        // Mount /etc/passwd if /debian/etc/passwd doesn't exist
        if (mount("/etc/passwd", "/debian/etc/passwd", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /etc/passwd");
            exit(EXIT_FAILURE);
        }
    }

    // Check if /debian/dev is already mounted
    if (!is_mount("/debian/dev")) {
        // Mount /etc/passwd if /debian/etc/passwd doesn't exist
        if (mount("/dev", "/debian/dev", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /dev");
            exit(EXIT_FAILURE);
        }
    }

    // Check if /debian/sys is already mounted
    if (!is_mount("/debian/sys")) {
        // Mount /etc/passwd if /debian/etc/passwd doesn't exist
        if (mount("/sys", "/debian/sys", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /sys");
            exit(EXIT_FAILURE);
        }
    }

    // Check if /debian/proc is already mounted
    if (!is_mount("/debian/proc")) {
        // Mount /etc/passwd if /debian/etc/passwd doesn't exist
        if (mount("/proc", "/debian/proc", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /proc");
            exit(EXIT_FAILURE);
        }
    }

    // Check if /debian/run is already mounted
    if (!is_mount("/debian/run")) {
        // Mount /etc/passwd if /debian/etc/passwd doesn't exist
        if (mount("/run", "/debian/run", NULL, MS_SILENT | MS_BIND | MS_REC, NULL) != 0) {
            perror("mount /run");
            exit(EXIT_FAILURE);
        }
    }

    
    chroot("/debian");
    setuid(cur);
    printf("%s\n", argv[1]);
    char** args = argv + 1;
    pid_t pid = fork();
    if (pid == 0) {
        execvp(args[0], args);
        // If execvp fails, exit with an error
        perror("execvp");
        exit(EXIT_FAILURE);
    } else if (pid < 0) {
        // Fork failed
        perror("fork");
        exit(EXIT_FAILURE);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    
    return status;
}

