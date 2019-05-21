Most of the configuration of the Highway MASA is done through database
variables in the system_variables table.  A note that these are sometimes
cached.

Here is a list of variables and their meanings/uses.

operator_contact
----------------

An email address to which reports should be sent.
This includes reports from other modules (such as LetsEncrypt) that might be
relevant.

shg_suffix
----------

This is the suffix (the "r" in "r.example.net") which will be appended to the
name generated from the ULA derived name.

shg_zone
--------

This is the zone which the shg_suffix is a part of.
The full SHG name will be made up of shg\_suffix . shg\_zone.

Configuration Variables
=======================

$INTERNAL_CA_SHG_DEVICE=             true
$LETENCRYPT_CA_SHG_DEVICE=           false

Determines if an internal CA is used for SHG-provisioning, or if an external
DNS-01 challenge with LetsEncrypt will be done.

To set the ACME server, set the variable AcmeKeys.acme.server:

For staging:

    AcmeKeys.acme.server="https://acme-staging-v02.api.letsencrypt.org/directory"

For production:

    AcmeKeys.acme.server="https://acme-v02.api.letsencrypt.org/directory"

This uses the dns-01 challenge method, so it needs to be able to do
DNS-Update to a zone under your control.  This the zone setup as shg\_zone above, plus
shg\_suffix.

    AcmeKeys.acme.dns_update_options = {
      :master     => 'ip.of.primary.dnsserver',
      :key_name   => 'hmac-sha256:nameofkey',
      :secret     => 'therandomkeyyougenerated',
      :print_only => false
    }

The MASA will need a TLS server certificate which can be validated via the
WebPKI.  The one produced by rake highway:h4\_masa\_server\_cert is anchored
to the bootstrap_ca, and will not be appropriate for general purpose use.

The hostname for the service *MUST* be the same as that which was setup by
h0\_set\_hostname.  In a Docker setup, this is setup by the staging.sh script.
Typically this name is *not* under the shg\_suffix, and so having a
LetsEncrypt certificate generated for this can not be done transparently.

There is a hack which can be used to automate the process.  If the name
for the MASA is MASA.example.com, then deploy a CNAME:

    _acme-challenge.masa.example.com IN CNAME   _acme-challenge.masa.example.com.shg_zone.example.net.

Then "rake highway:h4\_masa\_letsencrypt RESIGN=true" can be used to get a
production (or staging) certificate for the MASA.




