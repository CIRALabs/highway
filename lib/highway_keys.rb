class HighwayKeys

  def rootkey
    @rootkey ||= load_root_pub_key
  end

  def rootprivkey
    @rootprivkey ||= load_root_priv_key
  end

  def curve
    'secp384r1'
  end

  def devicedir
    @devdir  ||= Rails.root.join('db').join('devices')
  end

  def certdir
    @certdir ||= Rails.root.join('db').join('cert')
  end

  def self.ca
    @ca ||= self.new
  end

  protected
  def load_root_priv_key
    vendorprivkey=certdir.join("vendor_#{curve}.key")
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_root_pub_key
    File.open(certdir.join("vendor_#{curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
