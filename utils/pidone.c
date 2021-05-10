#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>

char cmd[4096];
static char child_stack[1024*1024];

int run(const char *name) {
  char *cmd = "sh";
  char *argv[4];
  argv[0] = "sh";
  argv[1] = "-c";
  argv[2] = (char*) name;
  argv[3] = NULL;
  execvp(cmd, argv);
}
static int child_fn() {
  run(cmd);
  return 0;
}
 
int main(int argc,char *argv[]) {
  char buf[255]; 
  strcpy(cmd,"");
  for(int i=1;i<argc;i++){
      strcat(cmd,"\"");
      strcat(cmd,argv[i]);
      strcat(cmd,"\" ");
  }
  pid_t pid = clone(child_fn, child_stack+1024*1024, CLONE_NEWPID | CLONE_NEWUTS | SIGCHLD , NULL);
  
  waitpid(pid, NULL, 0);
  return 0;
}