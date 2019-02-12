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
    SystemVariable.randomseq(:serialnumber)
  end

  def digest
    OpenSSL::Digest::SHA384.new
  end

  def device_prefix
    @deviceprefix ||= ""
  end

  def devicedir
    @devdir  ||= if ENV['DEVICEDIR']
                   Pathname.new(ENV['DEVICEDIR'])
                   @deviceprefix="product_"
                 else
                   Rails.root.join('db').join('devices')
                 end
  end

  def certdir
    @certdir ||= if ENV['CERTDIR']
                   Pathname.new(ENV['CERTDIR'])
                 else
                   Rails.root.join('db').join('cert')
                 end
  end

  def vendor_pubkey
    certdir.join("vendor_#{curve}.crt")
  end

  def self.ca
    @ca ||= self.new
  end

  def root_priv_key_file
    @vendorprivkey ||= File.join(certdir, "vendor_#{curve}.key")
  end

  protected
  def load_root_priv_key
    File.open(root_priv_key_file) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_root_pub_key
    File.open(vendor_pubkey,'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
