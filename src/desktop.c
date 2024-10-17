#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int startswith(char* line, char* msg) {
    if (strlen(line) < strlen(msg)) {
        return 0;
    }
    return 0 == strncmp(line, msg, strlen(msg));
}

#define MAX_LINE_LENGTH 1024*1024
char* generate_desktop(char* path) {
    char* ctx = malloc(1024*1024*1024*sizeof(char));
    strcpy(ctx,"");
    char line[MAX_LINE_LENGTH];
    if(access(path, F_OK) == 0){
        return NULL;
    }
    FILE *source_file = fopen(path, "r");
    if (source_file == NULL) {
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
    return strdup(ctx);
}
