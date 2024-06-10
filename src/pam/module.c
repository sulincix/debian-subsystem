#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <sys/stat.h>
#include <stdbool.h>

#include <lsl.h>


PAM_EXTERN int pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    (void) pamh; (void) flags; (void) argc; (void) argv;
    pam_begin();
    return PAM_SUCCESS;
}

PAM_EXTERN int pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    (void) pamh; (void) flags; (void) argc; (void) argv;
    pam_exit();
    return PAM_SUCCESS;
}
