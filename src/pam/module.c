#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <sys/stat.h>


#include <lsl.h>

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
    umount_run_user();
    return PAM_SUCCESS;
}
