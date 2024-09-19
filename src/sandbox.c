#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>
#include <sys/mount.h>

#include <lsl.h>

extern uid_t cur_uid;
static char child_stack[1024*1024];

static char* command;
static char** args;
static int execsnd() {
    if (sethostname("sandbox", 7) != 0) {
        perror("sethostname");
        return -1;
    }
    if (mount("proc", "/proc", "proc", MS_NOSUID | MS_NODEV | MS_NOEXEC | MS_RELATIME, NULL) != 0) {
        perror("mount");
        return -1;
    }
    if (setuid(cur_uid) != 0) {
        perror("setuid");
        return -1;
    }
    execvp(command, args);
    perror("execvp");
    return -1;
}

void visible sandbox_init(){
    cur_uid = getuid();
}

void visible execute_sandbox(char* cmd, char** argv){
    if(cur_uid == 0){
        cur_uid = getuid();
        setuid(0);
        if (getuid() != 0) {
            fprintf(stderr, "You must be root.\n");
            exit(EXIT_FAILURE);
        }
    }
    if(getenv("LSL_NOSANDBOX") != NULL){
        (void)setuid(cur_uid);
        execvp(cmd, argv);
        perror("execvp");
    }
    size_t len=0;
    for(len=0;argv[len] != NULL; len++);
    command = strdup(cmd);
    args = calloc(len+1,sizeof(char*));
    for(size_t i=0;i<len; i++){
        args[i] = strdup(argv[i]);
    }
    args[len] = NULL;
    pid_t pid = clone(execsnd,
        child_stack+1024*1024, CLONE_NEWPID | CLONE_NEWUTS | CLONE_NEWNS |
             CLONE_NEWIPC | CLONE_VM | CLONE_VFORK | SIGCHLD , NULL
    );
    if (pid == -1) {
        perror("clone");
        exit(EXIT_FAILURE);
    }
    int status;
    waitpid(pid, &status, 0);
    for (size_t j = 0; j < len; j++) {
        free(args[j]);
    }
    free(args);
    exit(status / 256);
}
