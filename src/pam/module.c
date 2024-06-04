#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <sys/stat.h>
#include <stdbool.h>

#include <lsl.h>

static bool is_running(){
     struct stat st;
     stat("/sys/fs/cgroup/debian/cgroup.procs", &st);
     return st.st_size != 0;
}

PAM_EXTERN int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    mode_t u = umask(0022);
    sync_uid("/var/lib/subsystem/");
    sync_gid("/var/lib/subsystem/");
    sync_desktop();
    mount_all();
    umask(u);
    return PAM_SUCCESS;
}

PAM_EXTERN int pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    create_dir("/sys/fs/cgroup/debian");
    if(!is_running()){
        umount_all();
    }
    return PAM_SUCCESS;
}
