AcmeKeys.acme.dns_update_options = {
    :master     => '209.87.249.18',
    :key_name   => 'hmac-sha256:highway',
    :secret     => ENV['COMET_ACME_TSIG_SECRET'],
    :print_only => false
}