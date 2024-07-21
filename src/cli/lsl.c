#include <dlfcn.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#include <sys/ptrace.h>

#ifndef NODLOPEN
static int (*debrun_main)(int, char**);
static char* error;
#else
#include <lsl.h>
#endif
int main(int argc, char** argv) {
    #ifndef NODLOPEN
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
    #endif
    return debrun_main(argc, argv);
}
