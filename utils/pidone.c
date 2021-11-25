#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>

char cmd[4096];
uid_t uid;
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
  setuid(uid);
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
  uid = getuid();
  uid_t i = setuid(0);
  if(getuid()!=0 || i != 0){
    fputs("Suid permissions are missing. Enter root password to set permission.\n",stderr);
    if(0 != system("su -c \"chown root $(which pidone); chmod u+s $(which pidone);\"")) {
      fputs("setuid() failing - operation not permitted\n",stderr);
      return 7;
    }else{
      execvp(argv[0],argv);
    }
  }  
  pid_t pid = clone(child_fn, child_stack+1024*1024, CLONE_NEWPID | CLONE_NEWUTS | CLONE_NEWNS | CLONE_NEWIPC | CLONE_NEWCGROUP | CLONE_VM | CLONE_VFORK | SIGCHLD , NULL);
  setuid(0);
 
  waitpid(pid, NULL, 0);
  return 0;
}
