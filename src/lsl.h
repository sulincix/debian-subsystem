#ifndef _debian_h
#define _debian_h
void sync_gid(const char *DESTDIR);
void sync_uid(const char *DESTDIR);
int sync_desktop();
int debrun_main(int argc_main, char **argv_main);
char* generate_desktop(char* path);
void mount_all();
void umount_all();
void umount_run_user();
int isdir(char* path);
void create_dir(char* path);
void directory_init();
void cgroup_init();
void cgroup_kill();
void disable_selinux();
void execute_sandbox(char* cmd, char** argv);
void pam_begin();
void pam_exit();
#define visible __attribute__((visibility("default")))
#endif
