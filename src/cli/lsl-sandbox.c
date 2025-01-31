#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <lsl.h>

int main(int argc, char** argv){
    if(argc < 2){
        return 1;
    }
    execute_sandbox(argv[1], argv+1);
    return 1;
}