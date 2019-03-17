== README

Highway is a service that manages a Manufacturer Installed
Certificate (MICs) subsystem.

Highway is a MASA == Manufacturer Assigned Signing Authority.

MICs are created by a vendor to be installed in a device during manufacturer.

=== Bootstrap the MASA

In order to start two things are needed:

1) A CA to sign things.

    rake highway:bootstrap_ca

This will create a CA into db/cert/vendor_*

2) A MASA certificate to sign vouchers.

    rake highway:bootstrap_masa

This will create a signed certificate in db/cert/masa_*

This is necessary for rake spec as well.  A future effort will generate
all certificates needed for the tests.

There are some setup instructions in [[doc/SETUP.md]]
