#define _XOPEN_SOURCE 700
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

#include <lsl.h>

#define MAX_LINE_LENGTH 1024

void msg(const char *action, const char *info) {
    printf("%s: %s\n", action, info);
}

void sync_gid(char* subsystem_path) {
    char line[MAX_LINE_LENGTH];
    char line_orig[MAX_LINE_LENGTH];
    FILE *source_file = fopen("/etc/group", "r");
    char dest_path[1024];
    strcpy(dest_path, subsystem_path);
    strcat(dest_path, "/etc/group");
    char* ctx = malloc(1024*1024*1024*sizeof(char));
    strcpy(ctx,"");
    FILE *dest_file = fopen(dest_path, "r");

    if (source_file == NULL || dest_file == NULL) {
        perror("Error opening files");
        exit(EXIT_FAILURE);
    }

        char group[MAX_LINE_LENGTH];
        char gid[MAX_LINE_LENGTH];
        char ogid[MAX_LINE_LENGTH];
        char ogroup[MAX_LINE_LENGTH];
        char users[MAX_LINE_LENGTH];

    while (fgets(line, sizeof(line), source_file)) {
        sscanf(line, "%[^:]:x:%[^:]:%[^:]", group, gid, users);
        users[strlen(users)-1] = '\0';
        int found = 0;
        if(strlen(line) < 4) {
            continue;
        }
        while (fgets(line_orig, sizeof(line_orig), dest_file)) {
            sscanf(line_orig, "%[^:]:x:%[^:]:", ogroup, ogid);
            if (strcmp(ogroup, group) == 0) {
                found = 1;
                strcat(ctx,group);
                strcat(ctx,":x:");
                strcat(ctx,gid);
                strcat(ctx,":");
                strcat(ctx,users);
                strcat(ctx,"\n");
                break;
            }
        }
        if(found == 0) {
            strcat(ctx, line);
        }
    }
    fseek(source_file, 0 , SEEK_SET);
    fseek(dest_file, 0 , SEEK_SET);
    while (fgets(line_orig, sizeof(line_orig), dest_file)) {
        if(strlen(line_orig) < 4) {
            continue;
        }
        sscanf(line_orig, "%[^:]:x:%[^:]:", ogroup, ogid);
        int found = 0;
        while (fgets(line, sizeof(line), source_file)) {
            sscanf(line, "%[^:]:x:%[^:]:%[^:]", group, gid, users);
            if (strcmp(ogroup, group) == 0) {
                found = 1;
                break;
            }
        }
        if(found == 0) {
            strcat(ctx, line_orig);
        }
    }
    fclose(dest_file);
    dest_file = fopen(dest_path, "w");
    fprintf(dest_file,"%s", ctx);
    fflush(dest_file);
    fclose(source_file);
    fclose(dest_file);
}

int sync_desktop(char* subsystem_path) {
    DIR *dp;
    struct dirent *ep;
    char path[1024];
    char path2[1024];
    char* dirs[] = {"applications/", "xsessions/"};
    
    for(size_t i = 0; i < (sizeof(dirs) / sizeof(char*)); i++) {
        snprintf(path, sizeof(path), "%s/var/lib/lsl/exports/%s", subsystem_path, dirs[i]);
        dp = opendir(path);
        if (dp != NULL) {
            while ((ep = readdir(dp)) != NULL) {
                if ((ep->d_name)[0] == '.') {
                    continue;
                }
                snprintf(path, sizeof(path), "%s/var/lib/lsl/exports/%s%s", subsystem_path, dirs[i], ep->d_name);
                remove(path);
            }
            closedir(dp);
        }

        snprintf(path, sizeof(path), "%s/usr/share/%s", subsystem_path, dirs[i]);
        dp = opendir(path);
        if (dp != NULL) {
            while ((ep = readdir(dp)) != NULL) {
                if ((ep->d_name)[0] == '.') {
                    continue;
                }
                snprintf(path, sizeof(path), "%s/usr/share/%s%s", subsystem_path, dirs[i], ep->d_name);
                snprintf(path2, sizeof(path2), "%s/var/lib/lsl/exports/%ssubsystem-%s", subsystem_path, dirs[i], ep->d_name);
                FILE *out = fopen(path2, "w");
                char* ctx = generate_desktop(path);
                if (out != NULL && ctx != NULL) {
                    fprintf(out, "%s", ctx); // Assuming generate_desktop function exists
                    fflush(out);
                    fclose(out);
                }
            }
            closedir(dp);
        }
    }
    return 0;
}

void sync_uid(char* subsystem_path) {
    char line[MAX_LINE_LENGTH];
    char line_orig[MAX_LINE_LENGTH];
    FILE *source_file = fopen("/etc/passwd", "r");
    char dest_path[1024];
    strcpy(dest_path, subsystem_path);
    strcat(dest_path, "/etc/passwd");
    char* ctx = malloc(1024*1024*1024*sizeof(char));
    strcpy(ctx,"");
    FILE *dest_file = fopen(dest_path, "r");

    if (source_file == NULL || dest_file == NULL) {
        perror("Error opening files");
        exit(EXIT_FAILURE);
    }

    char name[MAX_LINE_LENGTH];
    char uid[MAX_LINE_LENGTH];
    char gid[MAX_LINE_LENGTH];
    char realname[MAX_LINE_LENGTH];
    char home[MAX_LINE_LENGTH];
    char shell[MAX_LINE_LENGTH];
    char oname[MAX_LINE_LENGTH];
    char ouid[MAX_LINE_LENGTH];

    fseek(source_file, 0 , SEEK_SET);

    int found = 0;
    while (fgets(line, sizeof(line), source_file)) {
        sscanf(line, "%[^:]:x:%[^:]:%[^:]:%[^:]:%[^:]:%s", name, uid, gid, realname, home, shell);
        fseek(dest_file, 0 , SEEK_SET);
        found = 0;
        while (fgets(line_orig, sizeof(line_orig), dest_file)) {
            sscanf(line_orig, "%[^:]:x:%[^:]:*", oname, ouid);
            if(strcmp(name, oname) == 0) {
                found = 1;
                strcat(ctx,name);
                strcat(ctx,":x:");
                strcat(ctx,uid);
                strcat(ctx,":");
                strcat(ctx,gid);
                strcat(ctx,":");
                strcat(ctx,realname);
                strcat(ctx,":");
                strcat(ctx,home);
                strcat(ctx,":");
                strcat(ctx,shell);
                strcat(ctx,"\n");
                break;
                //printf("%s %s %s %s %s %s %s %s\n", name, uid, gid, realname, home, shell, oname, ouid);
            }
        }
        if(found == 0){
            strcat(ctx, line);
        }
    }
    fseek(source_file, 0 , SEEK_SET);
    fseek(dest_file, 0 , SEEK_SET);
    while (fgets(line_orig, sizeof(line_orig), dest_file)) {
        if(strlen(line_orig) < 4) {
            continue;
        }
        sscanf(line_orig, "%[^:]:x:%[^:]:", oname, ouid);
        int found = 0;
        while (fgets(line, sizeof(line), source_file)) {
            sscanf(line, "%[^:]:x:%[^:]:*", name, uid);
            if (strcmp(oname, name) == 0) {
                found = 1;
                break;
            }
        }
        if(found == 0) {
            strcat(ctx, line_orig);
        }
    }
    fclose(dest_file);
    dest_file = fopen(dest_path, "w");
    fprintf(dest_file,"%s", ctx);
    fflush(dest_file);
    fclose(source_file);
    fclose(dest_file);
}

