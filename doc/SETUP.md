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
