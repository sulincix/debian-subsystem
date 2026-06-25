#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

int startswith(const char* line, const char* msg) {
    if (strlen(line) < strlen(msg)) {
        return 0;
    }
    return 0 == strncmp(line, msg, strlen(msg));
}

int is_symlink(const char* path){
    struct stat fileStat;
    if (lstat(path, &fileStat) < 0) {
        perror("lstat");
        return 0;
    }
    return S_ISLNK(fileStat.st_mode);
}

#define INIT_BUF_SIZE 4096
#define LINE_BUF_SIZE 4096

#define APPEND_BUF(buf, len, cap, src) do { \
    size_t _add = strlen(src); \
    size_t _need = (len) + _add + 1; \
    if (_need > (cap)) { \
        (cap) = _need + 4096; \
        char* _new = realloc((buf), (cap)); \
        if (!_new) { free(buf); return NULL; } \
        (buf) = _new; \
    } \
    memcpy((buf) + (len), (src), _add + 1); \
    (len) += _add; \
} while(0)

char* generate_desktop(const char* path, const char* subsystem_path) {
    size_t ctx_len = 0;
    size_t ctx_cap = INIT_BUF_SIZE;
    char* ctx = malloc(ctx_cap);
    if(!ctx){
        return NULL;
    }
    ctx[0] = '\0';
    char line[LINE_BUF_SIZE];
    char fpath[1024];
    if (is_symlink(path)){
        char link[1024];
        ssize_t link_len = readlink(path, link, sizeof(link) - 1);
        if (link_len == -1) {
            free(ctx);
            return NULL;
        }
        link[link_len] = '\0';
        if(link[0] == '/'){
            strcpy(fpath, subsystem_path);
            strcat(fpath, link);
            path = fpath;
        }
    }
    FILE *source_file = fopen(path, "r");
    if (source_file == NULL) {
        fprintf(stderr, "Failed to open file: %s\n", path);
        free(ctx);
        return NULL;
    }
    while (fgets(line, sizeof(line), source_file)) {
        if(line[0] == '[') {
            APPEND_BUF(ctx, ctx_len, ctx_cap, line);
        }
        char* areas[] = {"Name=", "Version=", "Type=",
            "GenericName=","Comment=", "Keywords=","NoDisplay=",
            "Icon=", "Terminal=", "MimeType=", "Exec=", "Categories=", NULL};
        for(size_t i=0; areas[i]; i++){
            if(startswith(line, areas[i])){
                line[strlen(line)-1] = '\0';
                if(startswith(line, "Exec=")){
                    APPEND_BUF(ctx, ctx_len, ctx_cap, areas[i]);
                    APPEND_BUF(ctx, ctx_len, ctx_cap, "lsl ");
                    APPEND_BUF(ctx, ctx_len, ctx_cap, line+strlen(areas[i]));
                }else if(startswith(line, "Categories=")) {
                    APPEND_BUF(ctx, ctx_len, ctx_cap, areas[i]);
                    APPEND_BUF(ctx, ctx_len, ctx_cap, "subsystem;");
                    APPEND_BUF(ctx, ctx_len, ctx_cap, line+strlen(areas[i]));
                } else {
                    APPEND_BUF(ctx, ctx_len, ctx_cap, areas[i]);
                    APPEND_BUF(ctx, ctx_len, ctx_cap, line+strlen(areas[i]));
                }
                if(startswith(line, "Name=") || startswith(line, "GenericName=") ) {
                    APPEND_BUF(ctx, ctx_len, ctx_cap, " (on subsystem)\n");
                } else {
                    APPEND_BUF(ctx, ctx_len, ctx_cap, "\n");
                }
            }
        }
    }
    fclose(source_file);
    char* ret = strdup(ctx);
    free(ctx);
    return ret;
}
