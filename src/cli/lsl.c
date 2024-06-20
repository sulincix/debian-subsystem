#include <dlfcn.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#include <sys/ptrace.h>

static int (*debrun_main)(int, char**);
static char* error;
int main(int argc, char** argv) {
    void* handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) {
        fputs (dlerror(), stderr);
        exit(1);
    }
    debrun_main = dlsym(handle, "debrun_main");
    if ((error = dlerror()) != NULL)  {
        fputs(error, stderr);
        exit(1);
    }
    return debrun_main(argc, argv);
}
