#include <dlfcn.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#include <sys/ptrace.h>

#include <lsl.h>

int main(int argc, char** argv) {
    return debrun_main(argc, argv);
}
