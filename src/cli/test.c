#include <lsl.h>
int main(){
    sync_desktop();
    char* ctx = generate_desktop("/usr/share/applications/gimp.desktop");
    return 0;
}
