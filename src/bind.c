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

void mount_all(const char* subsystem_dir){
    if(unshare(CLONE_NEWNS)) {
        perror("unshare");
        exit(EXIT_FAILURE);
    }
    if(mount("none", "/", NULL, MS_REC|MS_PRIVATE, NULL)) {
        perror("mount");
        exit(EXIT_FAILURE);
    }
    char curdir[1024];
    getcwd(curdir, sizeof(curdir));
    const char* debian_dirs[] = {"/dev", "/sys", "/run", "/tmp",curdir,
        getenv("XDG_RUNTIME_DIR"), getenv("HOME"), NULL};
    if(getenv("LSL_NOSANDBOX") != NULL){
        char debian_dir[1024];
        strcpy(debian_dir, subsystem_dir);
        strcat(debian_dir, "/proc");
        if(!is_mount(debian_dir)){
            (void)debug(debian_dir);
            if (mount("/proc", debian_dir, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }
    for (size_t i = 0; debian_dirs[i]; ++i) {
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
    char lsl_resolvconf[1024];
    strcpy(lsl_resolvconf, subsystem_dir);
    strcat(lsl_resolvconf, "/etc/resolv.conf");
    FILE *resolvconf = fopen(lsl_resolvconf, "r");
    if (!resolvconf){
        resolvconf = fopen(lsl_resolvconf, "w");
    }
    fclose(resolvconf);
    if (mount("/etc/resolv.conf", lsl_resolvconf, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_RDONLY, NULL) != 0) {
        perror("mount");
        exit(EXIT_FAILURE);
    }
}

