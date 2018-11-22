class MasaKeys < HighwayKeys
  def masakey
    @masakey ||= load_masa_pub_key
  end

  def masaprivkey
    @masaprivkey ||= load_masa_priv_key
  end

  def curve
    'prime256v1'
  end
  def algorithm
    'ES256'
  end

  def self.masa
    @masa ||= self.new
  end

  # return the PublicKeyInfo structure for the issuer
  def masa_pki
    masakey.public_key.to_der
  end

  def jwt_encode(jv)
    JWT.encode jv, masaprivkey, algorithm
  end

  def masa_pubkey
    certdir.join("masa_#{curve}.crt")
  end

  protected
  def load_masa_priv_key
    masaprivkey_file=certdir.join("masa_#{curve}.key")

    File.open(masaprivkey_file) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_masa_pub_key
    File.open(masa_pubkey,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

end
