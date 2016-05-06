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

end
