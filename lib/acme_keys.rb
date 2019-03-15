class AcmeKeys < HighwayKeys
  attr_accessor :server

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

  protected
  def load_acme_priv_key

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
