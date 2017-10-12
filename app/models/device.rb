class Device < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers
  belongs_to :owner

  attr_accessor :idevid

  def self.find_by_number(number)
    where(serial_number: number).take || where(eui64: number).take
  end
  def self.create_by_number(number)
    find_by_number(number) || create(eui64: number)
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

  def certificate_filename(dir = HighwayKeys.ca.devicedir)
    devdir = dir.join(sanitized_eui64)
    FileUtils.mkpath(devdir)
    pubkeyfile = devdir.join("device.crt")
  end

  def store_certificate(dir = HighwayKeys.ca.devicedir)
    File.open(certificate_filename(dir), "w") do |f| f.write self.pub_key end
  end

  def certificate
    @certificate ||= OpenSSL::X509::Certificate.new(self.pub_key)
  end

  # compare a given key to the key that has been given to this device.
  def signing_key?(othercert)
    case
    when othercert.is_a?(OpenSSL::X509::Certificate)
      (certificate.to_der == othercert.to_der)
    when (othercert.is_a?(OpenSSL::PKey) or othercert.is_a?(OpenSSL::PKey::EC))
      (certificate.public_key.to_der == othercert.to_der)
    else
      false
    end
  end

  def gen_and_store_key(dir = HighwayKeys.ca.devicedir)
    gen_priv_key
    sign_eui64
    store_priv_key(dir)
    store_certificate(dir)
  end

  def masa_url
    SystemVariable.string(:masa_url) || "https://highway.sandelman.ca"
  end

  def masa_extension
    @mext ||= extension_factory.create_extension(
      "1.3.6.1.4.1.46930.2",
      sprintf("ASN1:UTF8String:%s", masa_url),
      false)
  end

  def extension_factory
    @ef ||= OpenSSL::X509::ExtensionFactory.new
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

    extension_factory.subject_certificate = @idevid
    extension_factory.issuer_certificate  = HighwayKeys.ca.rootkey
    @idevid.add_extension(extension_factory.create_extension("subjectKeyIdentifier","hash",false))
    @idevid.add_extension(extension_factory.create_extension("basicConstraints","CA:FALSE",false))

    # the OID: 1.3.6.1.4.1.46930.1 is a Private Enterprise Number OID:
    #    iso.org.dod.internet.private.enterprise . SANDELMAN=46930 . 1
    # subjectAltName=otherName:1.2.3.4;UTF8:some other identifier
    @idevid.add_extension(extension_factory.create_extension(
                           "subjectAltName",
                           sprintf("otherName:1.3.6.1.4.1.46930.1;UTF8:%s",
                                   self.sanitized_eui64),
                           false))

    # the OID: 1.3.6.1.4.1.46930.2 is a Private Enterprise Number OID:
    #    iso.org.dod.internet.private.enterprise . SANDELMAN=46930 . 2
    # this is used for the BRSKI MASAURLExtnModule-2016 until allocated
    # depends upon a patch to ruby-openssl, at:
    #  https://github.com/mcr/openssl/commit/a59c5e049b8b4b7313c6532692fa67ba84d1707c
    @idevid.add_extension(masa_extension)

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
    return if save_self_tofixture(fw)
    vouchers.each { |voucher| voucher.savefixturefw(fw)}
  end

end
