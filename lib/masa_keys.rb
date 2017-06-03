class MasaKeys < HighwayKeys

  def masakey
    @masakey ||= load_masa_pub_key
  end

  def masaprivkey
    @masaprivkey ||= load_masa_priv_key
  end

  def self.masa
    @masa ||= self.new
  end

  protected
  def load_masa_priv_key
    masaprivkey=certdir.join("masa_#{curve}.key")
    File.open(masaprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_masa_pub_key
    File.open(certdir.join("masa_#{curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

end
