class HighwayKeys

  def rootkey
    @rootkey ||= load_pub_key
  end

  def sign
    rootkey.sign
  end

  def curve
    'secp384r1'
  end

  def certdir
    @certdir ||= Rails.root.join('db').join('cert')
  end

  def self.ca
    @ca ||= self.new
  end

  protected
  def load_priv_key
    vendorprivkey=certdir.join("vendor_#{curve}.key")
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_pub_key
    File.open(certdir.join("vendor_#{curve}.crt"),'w') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
