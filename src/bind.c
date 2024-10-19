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


void disable_selinux(){
    FILE *f = fopen("/sys/fs/selinux/enforce", "w");
    if (f != NULL){
        fprintf(f, "0");
        fclose(f);
    }
}

int is_mount(const char *path) {
    FILE *fp = fopen(MOUNTS_FILE, "r");
    if (fp == NULL) {
        return 0;
    }

    char line[512];
    char mount_point[256], device[256], mount_type[256];

    while (fgets(line, sizeof(line), fp) != NULL) {
        if (sscanf(line, "%255s %255s %255s", device, mount_point, mount_type) == 3) {
            if (strcmp(path, mount_point) == 0) {
                fclose(fp);
                return 1;
            }
        }
    }

    fclose(fp);
    return 0;
}

#define startswith(A,B) strncmp(A, B, strlen(A))
static void umount_path(char* path){
    FILE *fp = fopen(MOUNTS_FILE, "r");
    if (fp == NULL) {
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    char line[512];
    char mount_point[256], device[256], mount_type[256];

    while (fgets(line, sizeof(line), fp) != NULL) {
        if (sscanf(line, "%255s %255s %255s", device, mount_point, mount_type) == 3) {
            if (startswith(path, mount_point) == 0) {
                umount2(mount_point, MNT_DETACH);
            }
        }
    }

    fclose(fp);
}

void umount_all(char* subsystem_dir){
    char path[1024];
    strcpy(path, subsystem_dir);
    umount_path(path);
}

void umount_run_user(char* subsystem_dir){
    char path[1024];
    strcpy(path, subsystem_dir);
    strcat(path, "/run");
    umount_path(path);
}

void mount_all(char* subsystem_dir){
    if (unshare(CLONE_NEWNS) == -1) {
        perror("unshare");
        exit(EXIT_FAILURE);
    }

    const char* debian_dirs[] = {"/dev", "/sys", "/run", "/tmp",
#ifndef NOUNBIND
        "/proc",
#endif
        getenv("XDG_RUNTIME_DIR"), getenv("HOME")};
#ifndef NOUNBIND
    if(getenv("LSL_NOSANDBOX") != NULL){
        char debian_dir[1024];
        strcpy(debian_dir, subsystem_dir);
        strcat(debian_dir, "/proc");
        if(!is_mount(subsystem_dir)){
            (void)debug(debian_dir);
            if (mount("/proc", debian_dir, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }
#endif
    for (size_t i = 0; i < sizeof(debian_dirs) / sizeof(debian_dirs[0]); ++i) {
        if(debian_dirs[i] == NULL){
            continue;
        }
        char debian_dir[1024];
        strcpy(debian_dir, subsystem_dir);
        strcat(debian_dir, debian_dirs[i]);
        if(!isdir(debian_dir)){
            create_dir(debian_dir);
        }
        if (!is_mount(debian_dir)) {
            (void)debug(debian_dir);
            if (mount(debian_dirs[i], debian_dir, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }

    char lsl_system_dir[1024];
    strcpy(lsl_system_dir, subsystem_dir);
    strcat(lsl_system_dir, "/var/lib/lsl/system");
    if (!is_mount(lsl_system_dir)) {
        if (mount("/", lsl_system_dir, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_RDONLY, NULL) != 0) {
            perror("mount");
            exit(EXIT_FAILURE);
        }
    }
}

