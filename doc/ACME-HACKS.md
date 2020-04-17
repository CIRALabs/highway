# LetsEncrypt for MASA server certificate

The highway:h4\_masa\_letsencrypt task can be used to generate a server
certificate for the MASA's HTTPS end point.
The MASA generally needs a certificate which can be easily trusted common end
points, although not strictly necessary with some kinds of sales-channel integration.

The example contains "resign.sh", which further sets RESIGN=true to renew the
certificate if it has expired.  It runs:

    docker run --rm --link staging_db:postgres $MOUNT shg_comet:eeylops bundle exec rake highway:h4_masa_letsencrypt RESIGN=true


# DNS-01 challenges for zones without DNS Update

In the sandelman.ca test environment, the servers are under sandelman.ca, but
there is no DNS update for sandelman.ca.
There are a number of issues with DNS Update, particularly with DNSSEC that
make mixing zones that have updates with those that are static a problem.
This is a problem with the way that bind9 stores the updates on disk, and
that fact that editing the static zone can invalidate the journal file that
the updates are stored on.

So it is better to keep the updates in a different file via a zone cut, or
even in a different domain.  Then, what one does is arrange a CNAME for
the *\_acme-challenge* name that is used.

    tilapia-[/etc/domain/sandelman.ca] mcr 10011 %dig +short _acme-challenge.eeylops.sandelman.ca cname
    _acme-challenge.eeylops.sandelman.ca.dasblinkenled.org.

The highway:h4\_masa\_letsencrypt expects this.
It just appends the provided SHG\_ZONE to the name given and goes ahead.
The update is authorized in the bind.conf as:

       update-policy {
                  ...
                  grant highway. subdomain sandelman.ca.dasblinkenled.org. ANY;
        };



