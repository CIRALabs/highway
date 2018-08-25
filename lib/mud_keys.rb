class MudKeys < HighwayKeys
  def mudkey
    @mudkey ||= load_mud_pub_key
  end

  def mudprivkey
    @mudprivkey ||= load_mud_priv_key
  end

  def curve
    'prime256v1'
  end

  def self.mud
    @mud ||= self.new
  end

  # return the PublicKeyInfo structure for the issuer
  def mud_pki
    mudkey.public_key.to_der
  end

  def mud_pubkey
    certdir.join("mud_#{curve}.crt")
  end

  protected
  def load_mud_priv_key
    if ENV['CERTDIR']
      mudprivkey_file=File.join(ENV['CERTDIR'], "mud_#{curve}.key")
    else
      mudprivkey_file=certdir.join("mud_#{curve}.key")
    end

    File.open(mudprivkey_file) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_mud_pub_key
    File.open(mud_pubkey,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

end
