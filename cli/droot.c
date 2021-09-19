#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
int main(int argc, char* argv[]){
    if(getuid()!=0){
        setenv("ROOTMODE","0",1);
    }else{
        setenv("ROOTMODE","1",1);
    }
    setuid(0);
    if(getuid()!=0){
        fputs("setuid() failing - operation not permitted\n",stderr);
        return 7;
    }  
    setenv("USER","root",1);
    execvp("/usr/lib/sulin/dsl/dsl.sh",argv);
}
