class AcmeKeys < HighwayKeys
  attr_accessor :server, :dns_update_options

  def acmekey
    @acmekey ||= load_acme_pub_key
  end

  def acmeprivkey
    @acmeprivkey ||= load_acme_priv_key
  end

  def acme_gen_key
    dn = sprintf("/CN=%s", SystemVariable.hostname)
    cert = HighwayKeys.ca.sign_end_certificate("acme_#{curve}",
                                               acme_privkey_file,
                                               acme_pubkey, dn)
  end

  def acme_maybe_make_keys
    unless File.exist?(acme_privkey_file)
      acme_gen_key
    end
  end

  def curve
    'prime256v1'
  end

  def self.acme
    @acme ||= self.new
  end

  # return the PublicKeyInfo structure for the issuer
  def acme_pki
    acmekey.public_key.to_der
  end

  def acme_pubkey
    certdir.join("acme_#{curve}.crt")
  end

  def acme_privkey_file
    @acmeprivkeyfile ||= if ENV['CERTDIR']
                           File.join(ENV['CERTDIR'], "acme_#{curve}.key")
                         else
                           certdir.join("acme_#{curve}.key")
                         end
  end

  def acme_client
    if dns_update_options
      @acme_client ||= Acme::Client.new(private_key: acmeprivkey,
                                        directory: server,
                                        connection_options: {
                                          :ssl => {
                                            :ca_file => '/usr/lib/ssl/certs/ca-certificates.crt',
                                            :ca_path => "/usr/lib/ssl/certs"
                                          }
                                        })

    end
    @acme_client
  end

  def acme_contact
    SystemVariable.string(:operator_contact)
  end

  def acme_account
    if acme_client
      @acme_account ||= acme_client.new_account(contact: acme_contact,
                                                terms_of_service_agreed: true)
      #puts "New account setup: #{@acme_account}"
    end
    @acme_account
  end

  def acme_dns_updater
    if dns_update_options
      @dns ||= DnsUpdate::load dns_update_options
    end
  end

  def acme_logger
    @acme_logger ||= Log4r::Logger.new("acme.log")
  end

  # specify the qname to update, and the parent "zone" that it is in.
  # the zone is needed to be able to tell nsupdate what it is trying to
  # update.
  def cert_for(baseqname, zone, csr, logger = nil, sleeptime = 30)
    logger ||= acme_logger

    mudqname = "mud." + baseqname
    qnames = [baseqname, mudqname]

    cert_for_names(qnames: qnames, zone: zone, csr: csr, logger: logger, sleeptime: sleeptime)
  end

  def cert_for_names(qnames:, zone:, csr:, logger: nil, sleeptime: 30, extrazone: '')
    logger ||= acme_logger

    return nil unless dns_update_options

    # make sure acme_account has been setup.
    return nil unless acme_account

    order = acme_client.new_order(identifiers: qnames)

    order.authorizations.each { |authorization|
      qname = authorization.domain

      challenge     = authorization.dns
      dns_target = challenge.record_name + "." + qname + extrazone
      logger.info "Removing  old challenge from #{dns_target}"
      acme_dns_updater.remove { |m|
        m.type = :txt
        m.zone = zone
        m.hostname = dns_target
      }
      logger.info "Adding #{challenge.record_content} challenge to #{dns_target}"
      acme_dns_updater.update { |m|
        m.type = :txt
        m.zone = zone
        m.hostname = dns_target
        m.data     = challenge.record_content
      }
    }

    # this should be replaced with a cycle of DNS queries to the
    # appropriate publically facing DNS servers to verify that the
    # update is now in place.
    sleep(sleeptime)
    if false
      qnames.each { |name|
        system("dig +short @nic.sandelman.ca #{name}")
        system("dig +short @sns.cooperix.net #{name}")
      }
    end

    order.authorizations.each { |authorization|
      # go through the list in order
      qname = authorization.domain

      challenge     = authorization.dns
      logger.info "validating for #{qname}"

      # okay, do it!
      challenge.request_validation
      while challenge.status == 'pending'
        logger.debug "Challenge waiting"
        sleep(2)
        challenge.reload
      end
      logger.info "Status: #{challenge.status} "
      if challenge.status != "valid"
        logger.fatal "ACME error on #{qname}: #{challenge.error["detail"]}"
        return nil
      end
    }

    begin
      order.finalize(csr: csr)
      while order.status == 'processing'
        logger.info "Order waiting"
        sleep(1)
      end
      if order.status != "valid"
        # seems to raise exception instead
        byebug # not sure what to log!
        logger.fatal "ACME error on #{baseqname}: #{order.error}"
        return nil
      end
    rescue Acme::Client::Error::Unauthorized
      logger.fatal "CSR problems: #{$!.message}"
      return nil
    end

    # returns the *PEM*
    return order.certificate
  end

  protected
  def load_acme_priv_key
    acme_maybe_make_keys
    File.open(acme_privkey_file) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_acme_pub_key
    File.open(acme_pubkey,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

end
