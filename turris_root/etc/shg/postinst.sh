#!/bin/sh
#
# Post-installation script for SHG onboarding

info() { logger -t shg-post-provisioning -p info $@; }
error() { logger -t shg-post-provisioning -p err $@; }
check_error() {
    if [ $? -ne 0 ]; then
        error $@
        exit 1
    fi
}

# does nothing right now.
