#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <pwd.h>

int exists(char* fname);
int cmd_exists(char* cmd);
char* which(char* cmd);
char* get_username(uid_t uid);
int iseq(char* str1, char* str2);
char* get_shell();
char* arg2cmd(int argc, char** argv);

int main(int argc, char argv[]){
    char* username = get_username(1000);
    if (getuid() == 0){
        if (!exists("/run/debian")){
            if (cmd_exists("systemd-tmpfiles") && exists("/run/systemd")){
                system("systemd-tmpfiles --create");
            }else if (cmd_exists("tmpfiles")){
                system("tmpfiles --create");
            }
            system("touch /run/debian");
        }
        if (!exists("/run/dbus")){
            system("mkdir -p /run/dbus");
        }
        if (!exists("/run/dbus/system_bus_socket") && cmd_exists("dbus-daemon")){
            system("dbus-daemon --system &>/dev/null");
        }
    }
    setenv("PULSE_SERVER","127.0.0.1",1);
    char home[1024];
    char runtime[1024];
    if (iseq(getenv("ROOTMODE"),"1")){
        setenv("USER","root",1);
        setenv("HOME","/root",1);
        strcpy(home,"/root");
    }else{
        setenv("USER",username,1);
        strcpy(home,"/home/");
        strcat(home,username);
        setenv("HOME",home,1);
        char cmd[1024];
        strcpy(cmd,"mkdir -p ");
        strcat(cmd,home);
        system(cmd);
    }
    chdir(home);
    strcpy(runtime,"/tmp/runtime-");
    strcat(runtime,username);
    setenv("XDG_RUNTIME_DIR",runtime,1);
    if(!exists(runtime)){
        char cmd[1024];
        strcpy(cmd,"mkdir -p ");
        strcat(cmd,runtime);
        system(cmd);
    }
    if (iseq(getenv("ROOTMODE"),"1")){
        chown(runtime,0,0);
        chown(home,0,0);
    }else{
        chown(runtime,1000,1000);
        chown(home,1000,1000);
    }
    char line[1024];
    strcpy(line,"/usr/share:");
    if (getenv("XDG_DATA_DIRS")!= NULL){
       strcat(line,getenv("XDG_DATA_DIRS"));
       }
    strcat(line,":/system/usr/lib/sulin/dsl/share");
    setenv("XDG_DATA_DIRS",line,1); 
    char cmd[1024];
    strcpy(cmd,get_shell());
    if(cmd_exists("dbus-launch") && !iseq(getenv("ROOTMODE"),"1")){
        strcat(cmd," 'exec dbus-launch -- ");
    }else{
        strcat(cmd," 'exec ");
    }
    strcat(cmd,arg2cmd(argc,argv));
            strcat(cmd,"'");
    char *args[] = { "bash", "-c", cmd, NULL };
    execvp("bash", args);

}

char* arg2cmd(int argc, char** argv){
    char* ret = malloc(1024*sizeof(char));
    strcpy(ret,"");
    for(int i=1;i<argc;i++){
        strcat(ret,argv[i]);
        strcat(ret," ");    
    }
    return ret;
}

char* get_shell(){
    if(getuid() == 0 && !iseq(getenv("ROOTMODE"),"1")){
        char *ret = malloc(1024*sizeof(char));
        strcpy(ret,"exec su -p ");
        strcat(ret,get_username(1000));
        strcat(ret," -c");
        return ret;
    }
    return "exec sh -c";
}

char* get_username(uid_t uid){
    char line[1024];
    char *item;
    char *user = malloc(1024*sizeof(char));
    FILE *f = fopen("/etc/passwd","r");
    while (fscanf(f,"%[^\n] ",line) != EOF) {
        item = strtok(line,":");
        strcpy(user,item);
        item = strtok(NULL,":");
        item = strtok(NULL,":");
        if (item != NULL){
            if(uid == atoi(item)){
                return user;
            }
        }
        strcpy(line,"");
    }
    return "";
}

int exists(char* fname){
    return access( fname, F_OK ) == 0 ;
}
int cmd_exists(char* cmd){
    int i = strcmp(which(cmd),cmd);
    setenv("PATH","/sbin:/bin:/usr/sbin:/usr/bin",1);
    return i != 0;
}

int iseq(char* str1, char* str2){
    if( str1 == NULL || str2 == NULL)
        return 0;
    return 0 == strcmp(str1,str2);
}

char* which(char* cmd){
    char* fullPath = getenv("PATH");
    
    struct stat buffer;
    int exists;
    char* fileOrDirectory = cmd;
    char *fullfilename = malloc(1024*sizeof(char));

    char *token = strtok(fullPath, ":");

    /* walk through other tokens */
    while( token != NULL ){
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

