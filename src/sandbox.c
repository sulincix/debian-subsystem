#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <sys/mount.h>

extern uid_t cur_uid;
static char child_stack[1024*1024];

static char* command;
static char** args;
static int execsnd(){
    (void)sethostname("sandbox", 7);
    mount("proc", "/proc", "proc", 0, NULL);
    (void)setuid(cur_uid);
    execvp(command, args);
    return -1;
}

void execute_sandbox(char* cmd, char** argv){
    if(getenv("LSL_NOSANDBOX") != NULL){
        (void)setuid(cur_uid);
        execvp(cmd, argv);
    }
    size_t i=0;
    for(i=0;argv[i] != NULL; i++);
    command = strdup(cmd);
    args = calloc(i,sizeof(char*));
    for(i=0;argv[i] != NULL; i++){
        args[i] = strdup(argv[i]);
    }
    pid_t pid = clone(execsnd, 
        child_stack+1024*1024, CLONE_NEWPID | CLONE_NEWUTS | CLONE_NEWNS |
             CLONE_NEWIPC | CLONE_VM | CLONE_VFORK | SIGCHLD , NULL
     );
    waitpid(pid, NULL, 0);
}
