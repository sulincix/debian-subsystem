#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#define _GNU_SOURCE
uid_t getuid();
uid_t setuid(uid_t uid);
int execvp(const char *, char * const*);

char* which(char* cmd);

int main(int argc, char *argv[]){
    int i=0;
    uid_t uid = getuid();
    if(uid != 0){
        char *path = getenv("PATH");
        i =  system("mkfifo /tmp/pkexec");
        if(i != 0){
            fprintf(stderr,"Authentication failure\n");
            return 1;
        }
        setenv("PATH","/bin:/usr/bin",1);
        system("hostctl pkexec \"echo true > /tmp/pkexec\"");
        setenv("PATH",path,1);
        i = system("cat /tmp/pkexec | grep true >/dev/null");
        setuid(0);
        system("rm -f /tmp/pkexec");
    }
    if(i == 0){
        char *cmd[argc];
        for(int i=0;i<argc-1;i++){
            cmd[i] = argv[i+1];
        }
        cmd[argc-1] = NULL;
        char* program = which(argv[1]);
        setenv("PATH","/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin",1);
        execvp(program,cmd);
    }else{
        fprintf(stderr,"Authentication failure\n");
        return 1;
    }
}
char* which(char* cmd){
    char* fullPath = getenv("PATH");
    struct stat buffer;
    int exists;
    char* fileOrDirectory = cmd;
    char *fullfilename = malloc(1024*sizeof(char));

    char *token = strtok(fullPath, ":");

    /* walk through other tokens */
    while( token != NULL )
    {
        sprintf(fullfilename, "%s/%s", token, fileOrDirectory);
        exists = stat( fullfilename, &buffer );
        if ( exists == 0 && ( S_IFREG & buffer.st_mode ) ) {
            char ret[strlen(fullfilename)];
            strcpy(ret,fullfilename);
            return (char*)fullfilename;
        }

        token = strtok(NULL, ":"); /* next token */
    }
    return cmd;
}
