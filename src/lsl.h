#ifndef _debian_h
#define _debian_h

#ifdef DEBUG
#define debug puts
#else
#define debug
#endif

#define visible __attribute__((visibility("default")))
void sync_gid(char* subsystem_path);
void sync_uid(char* subsystem_path);
int sync_desktop(char* subsystem_path);
int debrun_main(int argc_main, char **argv_main);
char* generate_desktop(char* path);
void mount_all(char* subsystem_dir);
void umount_all(char* subsystem_dir);
void umount_run_user(char* subsystem_dir);
int isdir(const char* path);
void create_dir(char* path);
void directory_init(char* subsystem_dir);
void cgroup_init(char* subsystem_dir);
void cgroup_kill(char* subsystem_dir);
void disable_selinux();
void execute_sandbox(char* cmd, char** argv);
void sandbox_init();
void pam_begin();
void pam_exit();
int is_mount(const char* path);
#endif
