class HighwayKeys
  attr_accessor :devdir, :certdir

  def rootkey
    @rootkey ||= load_root_pub_key
  end
  def cacert
    rootkey
  end

  def rootprivkey
    @rootprivkey ||= load_root_priv_key
  end
  def ca_signing_key
    rootprivkey
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

  def devicedir
    @devdir  ||= if ENV['DEVICEDIR']
                   Pathname.new(ENV['DEVICEDIR'])
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

  def sign_end_certificate(certname, privkeyfile, pubkeyfile, dnstr)
    dnobj = OpenSSL::X509::Name.parse dnstr

    sign_certificate(certname, nil, privkeyfile,
                     pubkeyfile, dnobj, 2*365*60*60) { |cert,ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    }
  end

  def sign_pubkey(issuer, dnobj, pubkey, duration=(2*365*60*60), efblock = nil)
    # note, root CA's are "self-signed", so pass dnobj.
    issuer ||= cacert.subject

    ncert  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    ncert.version = 2
    ncert.serial  = SystemVariable.randomseq(:serialnumber)
    ncert.subject = dnobj

    ncert.issuer = issuer
    ncert.public_key = pubkey
    ncert.not_before = Time.now

    # 2 years validity
    ncert.not_after = ncert.not_before + duration

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = ncert
    ef.issuer_certificate  = ncert

    if efblock
      efblock.call(ncert, ef)
    end
    ncert.sign(ca_signing_key, OpenSSL::Digest::SHA256.new)
  end

  def generate_privkey_if_needed(privkeyfile, curve, certname)
    if File.exists?(privkeyfile)
      puts "#{certname} using existing key at: #{privkeyfile}"
      OpenSSL::PKey.read(File.open(privkeyfile))
    else
      # the CA's public/private key - 3*1024 + 8
      key = OpenSSL::PKey::EC.new(curve)
      key.generate_key
      File.open(privkeyfile, "w", 0600) do |f| f.write key.to_pem end
      key
    end
  end

  def sign_certificate(certname, issuer, privkeyfile, pubkeyfile, dnobj, duration=(2*365*60*60), &efblock)
    FileUtils.mkpath(certdir)

    key = generate_privkey_if_needed(privkeyfile, curve, certname)
    ncert = sign_pubkey(issuer, dnobj, key, duration, efblock)

    File.open(pubkeyfile,'w') do |f|
      f.write ncert.to_pem
    end
    ncert
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
