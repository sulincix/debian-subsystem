#include <dlfcn.h>
#include <stddef.h>
#include <stdlib.h>

static int (*debrun_main)(int, char**);
int main(int argc, char** argv) {
    void* handle = dlopen(NULL, RTLD_LAZY);
    debrun_main = dlsym(handle, "debrun_main");
    return debrun_main(argc, argv);
}
