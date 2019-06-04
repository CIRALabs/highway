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

KEY="/etc/shg/shg.key"
CERTIF="/etc/shg/idevid_cert.pem"
INTERMEDIATE="/etc/shg/intermediate_certs.pem"
OUTPUT="/etc/shg/lighttpd.pem"

cat ${KEY} ${CERTIF} > ${OUTPUT}
cp ${KEY}    /srv/lxc/mud-supervisor/rootfs/app/certificates/jrc_prime256v1.key
cat ${CERTIF} ${INTERMEDIATE} >/srv/lxc/mud-supervisor/rootfs/app/certificates/jrc_prime256v1.crt
check_error "Failed to create certificate for lighttpd"
chmod 600 ${OUTPUT}
