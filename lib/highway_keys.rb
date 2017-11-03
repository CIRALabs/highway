class HighwayKeys
  attr_accessor :devdir, :certdir

  def rootkey
    @rootkey ||= load_root_pub_key
  end

  def rootprivkey
    @rootprivkey ||= load_root_priv_key
  end

  def curve
    'secp384r1'
  end

  def client_curve
    'prime256v1'
  end

  def serial
    @serial ||= 2
    @serial += 1
    @serial
  end

  def digest
    OpenSSL::Digest::SHA384.new
  end

  def devicedir
    @devdir  ||= Rails.root.join('db').join('devices')
  end

  def certdir
    @certdir ||= Rails.root.join('db').join('cert')
  end

  def vendor_pubkey
    certdir.join("vendor_#{curve}.crt")
  end

  def self.ca
    @ca ||= self.new
  end

  protected
  def load_root_priv_key
    if ENV['CERTDIR']
      vendorprivkey=File.join(ENV['CERTDIR'], "vendor_#{curve}.key")
    else
      vendorprivkey=certdir.join("vendor_#{curve}.key")
    end
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_root_pub_key
    File.open(vendor_pubkey,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
