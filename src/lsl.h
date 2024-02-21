#ifndef _debian_h
#define _debian_h
void sync_gid(const char *DESTDIR);
void sync_uid(const char *DESTDIR);
int sync_desktop();
int debrun_main(int argc_main, char **argv_main);
char* generate_desktop(char* path);
#endif