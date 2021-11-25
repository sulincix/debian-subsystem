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
    uid_t i = setuid(0);
    if(getuid()!=0 || i != 0){
        fputs("Suid permissions are missing. Enter root password to set permission.\n",stderr);
        if(0 != system("su -c \"chown root $(which droot); chmod u+s $(which droot);\"")) {
            fputs("setuid() failing - operation not permitted\n",stderr);
            return 7;
        }else{
            execvp(argv[0],argv);
        }
    }  
    setenv("USER","root",1);
    execvp("/usr/lib/sulin/dsl/dsl.sh",argv);
}
