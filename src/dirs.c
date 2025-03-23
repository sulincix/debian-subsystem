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
extern char* subsystem_path;


int isdir(const char *path){
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

int isfile(const char *path){
    if(path == NULL){
        return 0;
    }
    FILE* file = fopen(path,"r");
    if(file){
        fclose(file);
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

void directory_init(char* subsystem_path){
    // install and run debootstrap if does not exist
    char subsystem_etc_path[1024];
    snprintf(subsystem_etc_path, sizeof(subsystem_etc_path), "%s/etc/", subsystem_path);
    if(!isdir(subsystem_etc_path)){
        int status = system("/usr/bin/env bash /usr/libexec/subsystem-init.sh");
        if(status != 0){
            exit(status);
        }
    }

    char exports_path[1024];
    snprintf(exports_path, sizeof(exports_path), "%s/var/lib/lsl/exports/", subsystem_path);
    if(!isdir(exports_path)){
        create_dir(exports_path);
        create_dir(strcat(exports_path, "applications/"));
        create_dir(strcat(exports_path, "../xsessions"));
    }

    char imports_path[1024];
    snprintf(imports_path, sizeof(imports_path), "%s/var/lib/lsl/imports/", subsystem_path);
    if(!isdir(imports_path)){
        create_dir(imports_path);
    }

    char* dirs[] = {"themes", "icons", "fonts", "pixmaps"};
    for(size_t i=0; i<sizeof(dirs)/sizeof(char*) ;i++){
        char path[1024];
        snprintf(path, sizeof(path), "%s/var/lib/lsl/exports/%s", subsystem_path, dirs[i]);
        if(access(path, F_OK) == -1){
            char link[1024];
            strcpy(link, "../../../../usr/share/");
            strcat(link, dirs[i]);
            symlink(link, path);
        }
        snprintf(path, sizeof(path), "%s/var/lib/lsl/imports/%s", subsystem_path, dirs[i]);
        if(access(path, F_OK) == -1){
            char link[1024];
            strcpy(link, "../system/usr/share/");
            strcat(link, dirs[i]);
            symlink(link, path);
        }

    }

    char system_path[1024];
    snprintf(system_path, sizeof(system_path), "%s/var/lib/lsl/system/", subsystem_path);
    if(!isdir(system_path)){
        create_dir(system_path);
    }
}

void cgroup_init(char* subsystem_name){
    if(getenv("LSL_NOCGROUP") != NULL){
        return;
    }
    char cgroup_path[1024];
    snprintf(cgroup_path, sizeof(cgroup_path), "/sys/fs/cgroup/%s", subsystem_name);
    create_dir(cgroup_path);

    char cgroup_procs_path[1024];
    snprintf(cgroup_procs_path, sizeof(cgroup_procs_path), "/sys/fs/cgroup/%s/cgroup.procs", subsystem_name);
    FILE* cg = fopen(cgroup_procs_path, "w");
    if(cg == NULL){
       return;
    }
    fprintf(cg,"%d", getpid());
    fclose(cg);
}

void cgroup_kill(char* subsystem_name){
    if(getenv("LSL_NOCGROUP") != NULL){
        return;
    }
    char cgroup_path[1024];
    snprintf(cgroup_path, sizeof(cgroup_path), "/sys/fs/cgroup/%s/", subsystem_name);
    if(!isdir(cgroup_path)){
        return;
    }

    char cgroup_kill_path[1024];
    snprintf(cgroup_kill_path, sizeof(cgroup_kill_path), "/sys/fs/cgroup/%s/cgroup.kill", subsystem_name);
    FILE* cg = fopen(cgroup_kill_path, "w");
    if(cg == NULL){
       return;
    }
    fprintf(cg,"%d", 1);
    fclose(cg);
    remove(cgroup_path);
}

