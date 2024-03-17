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


void directory_init(){
    // install and run debootstrap if does not exists
    if(!isdir("/var/lib/subsystem/usr/share")){
        int status = system("/usr/bin/env bash /usr/libexec/debian-init.sh");
        if(status != 0){
            exit(status);
        }
    }

    if(!isdir("/var/lib/subsystem/var/lib/lsl/exports/")){
        create_dir("/var/lib/subsystem/var/lib/lsl/exports/");
        create_dir("/var/lib/subsystem/var/lib/lsl/exports/applications");
        create_dir("/var/lib/subsystem/var/lib/lsl/exports/xsessions");
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
}
