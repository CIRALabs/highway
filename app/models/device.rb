class Device < ActiveRecord::Base

  def gen_priv_key(curve = 'secp256k1')
    @dev_key = OpenSSL::PKey::EC.new(curve)
    @dev_key.generate_key
  end

  def sanitized_eui64
    @sanitized_eui64 ||= eui64.upcase.gsub(/[^0-9A-F-]/,"")
  end

  def store_priv_key(dir)
    devdir = dir.join(sanitized_eui64)
    FileUtils.mkpath(devdir)

    vendorprivkey = devdir.join("key.pem")
    File.open(vendorprivkey, "w") do |f| f.write @dev_key.to_pem end
  end

  def gen_and_store_key(dir = HighwayKeys.ca.devicedir)
    gen_priv_key
    store_priv_key(dir)
  end

  def sign_eui64
    idevid  = OpenSSL::X509::Certificate.new
    idevid.version = 2
    idevid.serial = 1
    idevid.issuer = HighwayKeys.ca.rootkey.issuer
    #idevid.public_key = @dev_key.public_key
    idevid.public_key = @dev_key

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = idevid
    ef.issuer_certificate  = HighwayKeys.ca.rootkey
    idevid.add_extension(ef.create_extension("basicConstraints","CA:FALSE",false))
    #idevid.add_extension(ef.create_extension("", true))

    HighwayKeys.ca.rootkey.sign(idevid, OpenSSL::Digest::SHA256.new)

    self.pub_key = idevid.to_pem
    save!
  end

end
