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

#define c_mkdir(A, B) \
    if (mkdir(A, B) < 0) { \
        fprintf(stderr, "Error: %s %s\n", "failed to create directory.", A); \
}

void create_dir(char *dir) {
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
    if(!isdir(subsystem_path)){
        int status = system("/usr/bin/env bash /usr/libexec/debian-init.sh");
        if(status != 0){
            exit(status);
        }
    }

    char exports_path[1024];
    snprintf(exports_path, sizeof(exports_path), "%s/var/lib/lsl/exports/", subsystem_path);
    if(!isdir(exports_path)){
        create_dir(exports_path);
        create_dir(strcat(exports_path, "applications"));
        create_dir(strcat(exports_path, "xsessions"));
    }

    char imports_path[1024];
    snprintf(imports_path, sizeof(imports_path), "%s/var/lib/lsl/imports/", subsystem_path);
    if(!isdir(imports_path)){
        create_dir(imports_path);
    }

    char themes_path[1024];
    snprintf(themes_path, sizeof(themes_path), "%s/var/lib/lsl/exports/themes", subsystem_path);
    if(access(themes_path, F_OK) == -1){
        symlink("../../../../usr/share/themes", themes_path);
    }

    char icons_path[1024];
    snprintf(icons_path, sizeof(icons_path), "%s/var/lib/lsl/exports/icons", subsystem_path);
    if(access(icons_path, F_OK) == -1){
        symlink("../../../../usr/share/icons", icons_path);
    }

    char fonts_path[1024];
    snprintf(fonts_path, sizeof(fonts_path), "%s/var/lib/lsl/exports/fonts", subsystem_path);
    if(access(fonts_path, F_OK) == -1){
        symlink("../../../../usr/share/fonts", fonts_path);
    }

    char imports_themes_path[1024];
    snprintf(imports_themes_path, sizeof(imports_themes_path), "%s/var/lib/lsl/imports/themes", subsystem_path);
    if(access(imports_themes_path, F_OK) == -1){
        symlink("../system/usr/share/themes/", imports_themes_path);
    }

    char imports_icons_path[1024];
    snprintf(imports_icons_path, sizeof(imports_icons_path), "%s/var/lib/lsl/imports/icons", subsystem_path);
    if(access(imports_icons_path, F_OK) == -1){
        symlink("../system/usr/share/icons/", imports_icons_path);
    }

    char imports_fonts_path[1024];
    snprintf(imports_fonts_path, sizeof(imports_fonts_path), "%s/var/lib/lsl/imports/fonts", subsystem_path);
    if(access(imports_fonts_path, F_OK) == -1){
        symlink("../system/usr/share/fonts/", imports_fonts_path);
    }

    char system_path[1024];
    snprintf(system_path, sizeof(system_path), "%s/var/lib/lsl/system/", subsystem_path);
    if(!isdir(system_path)){
        create_dir(system_path);
    }
}

void cgroup_init(char* subsystem_path){
    if(getenv("LSL_NOCGROUP") != NULL){
        return;
    }
    char cgroup_path[1024];
    snprintf(cgroup_path, sizeof(cgroup_path), "%s/sys/fs/cgroup/debian", subsystem_path);
    create_dir(cgroup_path);

    char cgroup_procs_path[1024];
    snprintf(cgroup_procs_path, sizeof(cgroup_procs_path), "%s/sys/fs/cgroup/debian/cgroup.procs", subsystem_path);
    FILE* cg = fopen(cgroup_procs_path, "w");
    if(cg == NULL){
       return;
    }
    fprintf(cg,"%d", getpid());
    fclose(cg);
}

void cgroup_kill(char* subsystem_path){
    if(getenv("LSL_NOCGROUP") != NULL){
        return;
    }
    char cgroup_path[1024];
    snprintf(cgroup_path, sizeof(cgroup_path), "%s/sys/fs/cgroup/debian/", subsystem_path);
    if(!isdir(cgroup_path)){
        return;
    }

    char cgroup_kill_path[1024];
    snprintf(cgroup_kill_path, sizeof(cgroup_kill_path), "%s/sys/fs/cgroup/debian/cgroup.kill", subsystem_path);
    FILE* cg = fopen(cgroup_kill_path, "w");
    if(cg == NULL){
       return;
    }
    fprintf(cg,"%d", 1);
    fclose(cg);
    remove(cgroup_path);
}

