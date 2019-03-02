class IDevIDKeys < HighwayKeys
  def idevidkey
    @idevidkey ||= load_idevid_pub_key
  end

  def idevidprivkey
    @idevidprivkey ||= load_idevid_priv_key
  end

  def curve
    'prime256v1'
  end
  def algorithm
    'ES256'
  end

  def self.idevid
    @idevid ||= self.new
  end

  # return the PublicKeyInfo structure for the issuer
  def idevid_pki
    idevidkey.public_key.to_der
  end

  def idevid_pub_keyfile
    certdir.join("idevid_#{curve}.crt")
  end

  def idevid_priv_keyfile
    certdir.join("idevid_#{curve}.key")
  end

  protected
  def load_idevid_priv_key
    File.open(idevid_priv_keyfile) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_idevid_pub_key
    File.open(idevid_pub_keyfile,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

end
