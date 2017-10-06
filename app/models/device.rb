class Device < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers

  attr_accessor :idevid

  def self.find_by_number(number)
    where(serial_number: number).take || where(eui64: number).take
  end

  # JWT wants prime256v1 (aka secp256r1), so default to that.
  def gen_priv_key(curve = 'prime256v1')
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

  def store_certificate(dir)
    devdir = dir.join(sanitized_eui64)
    FileUtils.mkpath(devdir)

    pubkeyfile = devdir.join("device.crt")
    File.open(pubkeyfile, "w") do |f| f.write self.pub_key end
  end

  def gen_and_store_key(dir = HighwayKeys.ca.devicedir)
    gen_priv_key
    sign_eui64
    store_priv_key(dir)
    store_certificate(dir)
  end

  def sign_eui64
    @idevid  = OpenSSL::X509::Certificate.new
    @idevid.version = 2
    @idevid.serial = SystemVariable.nextval(:serialnumber)
    @idevid.issuer = HighwayKeys.ca.rootkey.issuer
    #idevid.public_key = @dev_key.public_key
    @idevid.public_key = @dev_key
    @idevid.subject = OpenSSL::X509::Name.parse "/DC=ca/DC=sandelman/CN=#{sanitized_eui64}"
    @idevid.not_before = Time.now
    @idevid.not_after  = Time.gm(2999,12,31)

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = @idevid
    ef.issuer_certificate  = HighwayKeys.ca.rootkey
    @idevid.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
    @idevid.add_extension(ef.create_extension("basicConstraints","CA:FALSE",false))

    # the OID: 1.3.6.1.4.1.46930.1 is a Private Enterprise Number OID:
    #    iso.org.dod.internet.private.enterprise . SANDELMAN=46930 . 1
    # subjectAltName=otherName:1.2.3.4;UTF8:some other identifier
    @idevid.add_extension(ef.create_extension(
                           "subjectAltName",
                           sprintf("otherName:1.3.6.1.4.1.46930.1;UTF8:%s",
                                   self.sanitized_eui64),
                           false))

    # the OID: 1.3.6.1.4.1.46930.2 is a Private Enterprise Number OID:
    #    iso.org.dod.internet.private.enterprise . SANDELMAN=46930 . 2
    # this is used for the BRSKI MASAURLExtnModule-2016 until allocated
    # depends upon a patch to ruby-openssl, at:
    #  https://github.com/mcr/openssl/commit/a59c5e049b8b4b7313c6532692fa67ba84d1707c
    @idevid.add_extension(ef.create_extension(
                           "1.3.6.1.4.1.46930.2",
                           "ASN1:UTF8String:http://www.sandelman.ca",
                           false))

    # include the official HardwareModule OID:  1.3.6.1.5.5.7.8.4
    @idevid.sign(HighwayKeys.ca.rootprivkey, OpenSSL::Digest::SHA256.new)

    self.pub_key = idevid.to_pem
    self.serial_number = sanitized_eui64
    save!
  end

  def name
    "device_#{self.id}"
  end
  def savefixturefw(fw)
    device.savefixturefw(fw) if device
    vouchers.each { |voucher| voucher.savefixturefw(fw)}
    save_self_tofixture(fw)
  end

end
