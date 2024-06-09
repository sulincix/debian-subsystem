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
        perror("fopen");
        exit(EXIT_FAILURE);
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

void visible umount_all(){
    umount_path("/var/lib/subsystem");
}

void visible umount_run_user(){
    umount_path("/var/lib/subsystem/run");
}

void visible mount_all(){
    const char* debian_dirs[] = {"/dev", "/proc", "/sys", "/run", "/tmp",
        getenv("XDG_RUNTIME_DIR"), getenv("HOME")};

    for (size_t i = 0; i < sizeof(debian_dirs) / sizeof(debian_dirs[0]); ++i) {
        if(debian_dirs[i] == NULL){
            continue;
        }
        char debian_dir[1024];
        strcpy(debian_dir, "/var/lib/subsystem");
        strcat(debian_dir,debian_dirs[i]);
        if(!isdir(debian_dir)){
            create_dir(debian_dir);
        }
        if (!is_mount(debian_dir)) {
            if (mount(debian_dirs[i], debian_dir, NULL, MS_SILENT | MS_BIND | MS_PRIVATE | MS_REC, NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
            }
        }
    }

    if (!is_mount("/var/lib/subsystem/var/lib/lsl/system")) {
        if (mount("/", "/var/lib/subsystem/var/lib/lsl/system", NULL, MS_SILENT | MS_BIND | MS_PRIVATE |MS_RDONLY , NULL) != 0) {
                perror("mount");
                exit(EXIT_FAILURE);
        }
    }

}
