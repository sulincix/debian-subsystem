#ifndef _debian_h
#define _debian_h

#ifdef DEBUG
#define debug puts
#else
#define debug
#endif

#define visible __attribute__((visibility("default")))
void sync_gid(const char* subsystem_path);
void sync_uid(const char* subsystem_path);
int sync_desktop(const char* subsystem_path);
int debrun_main(int argc_main, char **argv_main);
char* generate_desktop(const char* path, const char* subsystem_path);
void mount_all(const char* subsystem_dir);
void umount_all(const char* subsystem_dir);
void umount_run_user(const char* subsystem_dir);
int isdir(const char* path);
int isfile(const char* path);
void create_dir(const char* path);
void directory_init(const char* subsystem_dir);
void cgroup_init(const char* subsystem_dir);
void cgroup_kill(const char* subsystem_dir);
void disable_selinux();
void execute_sandbox(const char* cmd, char* argv[]);
void sandbox_init();
void pam_begin();
void pam_exit();
int is_mount(const char* path);
#endif
