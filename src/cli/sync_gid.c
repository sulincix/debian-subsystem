#include <lsl.h>
int main() {
    const char *DESTDIR = "/debian";
    sync_gid(DESTDIR);
    return 0;
}