#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
int main(int argc, char* argv[]){
    setuid(0);
    setenv("USER","root",1);
    setenv("ROOTMODE","0",1);
    execvp("/usr/lib/sulin/dsl/dsl.sh",NULL);
}
