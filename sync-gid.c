#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 1024

void msg(const char *action, const char *info) {
    printf("%s: %s\n", action, info);
}

void sync_gid(const char *DESTDIR) {
    char line[MAX_LINE_LENGTH];
    char line_orig[MAX_LINE_LENGTH];
    FILE *source_file = fopen("/etc/group", "r");
    char dest_path[1024];
    strcpy(dest_path, DESTDIR);
    strcat(dest_path, "/etc/group");
    char** ctx = malloc(1024*1024*1024*sizeof(char));
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
        sscanf(line, "%[^:]:x:%[^:]:%[^:]:%s", group, gid, users);
        users[strlen(users)-1] = '\0';
        int found = 0;
        if(strlen(line_orig) < 4) {
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
            sscanf(line, "%[^:]:x:%[^:]:%[^:]:%s", group, gid, users);
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

int main() {
    const char *DESTDIR = "/debian";
    sync_gid(DESTDIR);
    return 0;
}

