#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <lsl.h>


uid_t cur_uid;

int main(int argc, char** argv){
    if(argc < 2){
        return 1;
    }
    sandbox_init();
    execute_sandbox(argv[1], argv+1);
    return 1;
}