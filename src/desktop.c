#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

int startswith(char* line, char* msg) {
    if (strlen(line) < strlen(msg)) {
        return 0;
    }
    return 0 == strncmp(line, msg, strlen(msg));
}

int is_symlink(char* path){
    struct stat fileStat;
    if (lstat(path, &fileStat) < 0) {
        perror("lstat");
        return 0;
    }
    return S_ISLNK(fileStat.st_mode);
    
}

#define MAX_LINE_LENGTH 1024*1024
char* generate_desktop(char* path, char* subsystem_path) {
    char* ctx = malloc(11024*1024*sizeof(char));
    strcpy(ctx,"");
    char line[MAX_LINE_LENGTH];
    if (is_symlink(path)){
        char link[1024];
        (void)readlink(path, link, sizeof(link) - 1);
        if(link[0] == '/'){
            char fpath[1024];
            strcpy(fpath, subsystem_path);
            strcat(fpath, link);
            path = fpath;
        }
    }
    FILE *source_file = fopen(path, "r");
    if (source_file == NULL) {
        fprintf(stderr, "Failed to open file: %s\n", path);
        return NULL;
    }
    while (fgets(line, sizeof(line), source_file)) {
        if(line[0] == '[') {
            strcat(ctx,line);
        }
        char* areas[] = {"Name=", "Version=", "Type=",
            "GenericName=","Comment=", "Keywords=","NoDisplay=",
            "Icon=", "Terminal=", "MimeType=", "Exec=", "Categories="};
        for(size_t i=0; i<sizeof(areas)/sizeof(char*); i++){
            if(startswith(line, areas[i])){
                line[strlen(line)-1] = '\0';
                if(startswith(line, "Exec=")){
                    strcat(ctx, areas[i]);
                    strcat(ctx, "lsl ");
                    strcat(ctx, line+strlen(areas[i]));
                }else if(startswith(line, "Categories=")) {
                    strcat(ctx, areas[i]);
                    strcat(ctx, "subsystem;");
                    strcat(ctx, line+strlen(areas[i]));
                } else {
                    strcat(ctx, areas[i]);
                    strcat(ctx, line+strlen(areas[i]));
                }
                if(startswith(line, "Name=") || startswith(line, "GenericName=") ) {
                    strcat(ctx, " (on subsystem)\n");
                } else {
                    strcat(ctx, "\n");
                }
            }
        }
    }
    char* ret = strdup(ctx);
    free(ctx);
    return ret;
}
