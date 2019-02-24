class Device < ActiveRecord::Base
  include FixtureSave
  has_many :vouchers
  belongs_to :owner
  # will add device_type for multi-product vendors
  #belongs_to :device_type

  has_many :owners, -> { order("vouchers.created_at DESC") }, through: :vouchers

  attr_accessor :idevid, :dev_key

  class CSRNotverified < Exception; end
  class CSRSerialNumberDuplicated < Exception; end

  before_save :fill_in_pub_key
  before_save :serial_number_from_eui64

  scope :active,  -> { where.not(obsolete: true) }
  scope :obsolete,-> { where(obsolete: true) }
  scope :owned,   -> { where.not(owner: nil) }
  scope :unowned, -> { where(owner: nil) }

  def self.canonicalize_eui64(str)
    return '' unless str
    nocolondash = str.downcase.gsub(/[\-\:]/,'')
    result=''
    filler=''
    toggle=false
    nocolondash.split('').each { |letter|
      result = result + filler + letter
      filler = '-' if toggle
      filler = ''  unless toggle
      toggle = !toggle
    }
    result
  end

  def self.find_by_number(number)
    active.where(serial_number: number).take || active.where(eui64: canonicalize_eui64(number)).take
  end
  def self.create_by_number(number)
    find_by_number(number) || create(eui64: canonicalize_eui64(number))
  end

  def self.create_from_csr_io(csrio)
    create_from_csr(OpenSSL::X509::Request.new(csrio))
  end

  # call-seq:
  #   Device.create_by_csr(csr) => device
  #
  # creates a new device identity using the public key found in the CSR.
  # the public key will be used to lookup a device object by public key, creating one
  # if necessary.
  #
  # Any serialNumber attribute found in the CSR will be used, provided it is already
  # unique (or matches the existing device), otherwise, the creation fails.
  # The rest of the proposed DN will be ignored, and any subjectAltName proposed will
  # also be ignored.
  def self.create_from_csr(csr)
    unless csr.verify(csr.public_key)
      raise CSRNotVerified;
    end

    dev = self.find_by_PKey(csr.public_key)

    # if no existing device, then look for one with the same serial number, and
    # reject if it exists.
    unless dev
      attributes = Hash.new
      items = csr.subject.to_a
      items.each { |attr|
        case attr[2]
        when 12       # UTF8STRING
          attributes[attr[0]] = attr[1]
        when 19       # PRINTABLESTRING
          attributes[attr[0]] = attr[1]
        else
          # not sure what to do with other types now.
        end
      }

      if attributes["serialNumber"]
        odev = active.find_by_serial_number(attributes["serialNumber"])
        if odev
          raise CSRSerialNumberDuplicated.new("#{attributes["serialNumber"]} duplicated by #{odev.id}");
        end
      end

      # so, not found, create a device with the same serial number.
      dev = create(:serial_number => attributes["serialNumber"])
      dev.eui64 = dev.serial_number
      dev.set_public_key(csr.public_key)
    end

    # found a suitable dev, now write a certificate for it, and store it.
    # will allocate an EUI-64 for it along the way.
    # The caller can set the model if desired.
    dev.sign_eui64

    dev
  end

  def self.find_by_PKey(pkey)
    b64 = Base64::encode64(pkey.to_der)
    find_by_pub_key(b64)
  end

  def set_public_key(key)
    if key.kind_of?(OpenSSL::PKey::EC::Point)
      pub = OpenSSL::PKey::EC.new(key.group)
      pub.public_key = key
      key = pub
    end
    self.pub_key = Base64::encode64(key.to_der)
  end

  def public_key
    @public_key ||= OpenSSL::PKey.read(Base64::decode64(pub_key))
  end

  def obsoleted!
    self.obsolete = true
    save!
  end

  def fill_in_pub_key
    if idevid_cert and !pub_key
      self.pub_key = Base64::encode64(certificate.public_key.to_der)
    end
    true
  end

  def serial_number_from_eui64
    serial_number ||= eui64
    true
  end
  def serial_number
    self[:serial_number] ||= eui64
  end

  # JWT wants prime256v1 (aka secp256r1), so default to that.
  def gen_priv_key(curve = 'prime256v1')
    @dev_key = OpenSSL::PKey::EC.new(curve)
    @dev_key.generate_key
  end

  def sanitized_eui64
    @sanitized_eui64 ||= eui64.upcase.gsub(/[^0-9A-F-]/,"")
  end

  # no dash or :
  def compact_eui64
    @compact_eui64 ||= eui64.upcase.gsub(/[^0-9A-F]/,"")
  end

  def device_dir(dir = HighwayKeys.ca.devicedir)
    @devdir ||= dir.join(sanitized_eui64)
  end

  def zipfilename
    sprintf("product_%s.zip", sanitized_eui64)
  end

  def vendorprivkey(dir = HighwayKeys.ca.devicedir)
    @vendorprivkey ||= device_dir(dir).join("key.pem")
  end

  def store_priv_key(dir = HighwayKeys.ca.devicedir)
    FileUtils.mkpath(device_dir(dir))

    File.open(vendorprivkey(dir), "w", 0600) do |f| f.write @dev_key.to_pem end
    File.chmod(0400, vendorprivkey(dir))
  end

  def gen_or_load_priv_key(dir, curve = 'prime256v1', verbose=true)
    if File.exists?(vendorprivkey(dir))
      puts "Reused private key from #{vendorprivkey(dir)}" if verbose
      @dev_key = OpenSSL::PKey.read(IO::read(vendorprivkey(dir)))
    else
      gen_priv_key       # sets @dev_key
      store_priv_key(dir)
    end

    if pub_key.blank?
      set_public_key(@dev_key.public_key)
      save!
    end
    @dev_key
  end

  def certificate_filename(dir = HighwayKeys.ca.devicedir)
    devdir = device_dir(dir)
    FileUtils.mkpath(devdir)
    pubkeyfile = devdir.join("device.crt")
  end

  def store_certificate(dir = HighwayKeys.ca.devicedir)
    File.open(certificate_filename(dir), "w") do |f| f.write self.idevid_cert end
  end

  def certificate
    @certificate ||= OpenSSL::X509::Certificate.new(self.idevid_cert)
  end

  def pubkey
    self[:pub_key]
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
    gen_or_load_priv_key(dir)
    sign_eui64
    store_certificate(dir)
  end

  def masa_url
    SystemVariable.string(:masa_iauthority) || "highway.sandelman.ca"
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
    @idevid.serial = SystemVariable.randomseq(:serialnumber)
    @idevid.issuer = HighwayKeys.ca.rootkey.issuer
    @idevid.public_key = self.public_key
    @idevid.subject = OpenSSL::X509::Name.new([["serialNumber", serial_number,12]])
    @idevid.not_before = Time.now
    @idevid.not_after  = Time.gm(2999,12,31)

    extension_factory.subject_certificate = @idevid
    extension_factory.issuer_certificate  = HighwayKeys.ca.rootkey
    @idevid.add_extension(extension_factory.create_extension("subjectKeyIdentifier","hash",false))
    @idevid.add_extension(extension_factory.create_extension("basicConstraints","CA:FALSE",false))

    # keyUsage and extendedKeyUsage (EKU) were tried, but shoud be avoided according to brski-20
    # @idevid.add_extension(extension_factory.create_extension("keyUsage","digitalSignature",false))
    # @idevid.add_extension(extension_factory.create_extension("extendedKeyUsage","clientAuth",false))

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

    self.idevid_cert   = @idevid.to_pem
    self.serial_number ||= sanitized_eui64
    save!
  end

  def audit_events
    vouchers.creation_order.collect {|vr|
      { 'date' => vr.created_at,
        'registrarID' => vr.owner.registrarID_base64,
        'nonce'       => vr.nonce
      }
    }
  end

  def audit_log
    al = Hash.new
    al['version'] = '1'
    al['events']  = audit_events
    al
  end

  # returns true if this device has ever been own owned by the given
  # owner, which is done by looking at the audit log.
  def device_owned_by?(owner)
    owners.include?(owner)
  end

  # for building fixtures, etc.
  def simplename
    "device_#{self.id}"
  end

  # for human consumption
  def name
    "Device #{sanitized_eui64}"
  end

  def savefixturefw(fw)
    return if save_self_tofixture(fw)
    vouchers.each { |voucher| voucher.savefixturefw(fw)}
  end

  # for SmartPledge QR code creation
  def dpphash_calc
    dc = Hash.new
    dc["S"] = SystemVariable.masa_iauthority
    dc["M"] = compact_eui64
    dc
  end

  def dpphash
    @dpphash ||= dpphash_calc
  end

end
