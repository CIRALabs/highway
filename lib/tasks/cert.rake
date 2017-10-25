# -*- ruby -*-

namespace :highway do

  desc "Create initial self-signed CA certificate"
  task :bootstrap_ca => :environment do

    # X25519 is for key-agreement only.
    #curve='X25519'
    #curve='secp384r1'
    curve = HighwayKeys.ca.curve

    certdir = Rails.root.join('db').join('cert')
    FileUtils.mkpath(certdir)

    vendorprivkey=certdir.join("vendor_#{curve}.key")
    if File.exists?(vendorprivkey)
      root_key = OpenSSL::PKey.read(File.open(vendorprivkey))
    else
      # the CA's public/private key - 3*1024 + 8
      root_key = OpenSSL::PKey::EC.new(curve)
      root_key.generate_key
      File.open(vendorprivkey, "w") do |f| f.write root_key.to_pem end
    end

    root_ca  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    root_ca.version = 2
    root_ca.serial = 1
    root_ca.subject = OpenSSL::X509::Name.parse "/DC=ca/DC=sandelman/CN=Unstrung Highway CA"

    # root CA's are "self-signed"
    root_ca.issuer = root_ca.subject
    #root_ca.public_key = root_key.public_key
    root_ca.public_key = root_key
    root_ca.not_before = Time.now

    # 2 years validity
    root_ca.not_after = root_ca.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = root_ca
    ef.issuer_certificate  = root_ca
    root_ca.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
    root_ca.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
    root_ca.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
    root_ca.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)

    File.open(certdir.join("vendor_#{curve}.crt"),'w') do |f|
      f.write root_ca.to_pem
    end
  end

  desc "Create a certificate for the MASA to sign vouchers with"
  task :bootstrap_masa => :environment do

    curve = HighwayKeys.ca.curve

    certdir = Rails.root.join('db').join('cert')
    FileUtils.mkpath(certdir)

    masaprivkey=certdir.join("masa_#{curve}.key")
    if File.exists?(masaprivkey)
      masa_key = OpenSSL::PKey.read(File.open(masaprivkey))
    else
      # the MASA's public/private key - 3*1024 + 8
      masa_key = OpenSSL::PKey::EC.new(curve)
      masa_key.generate_key
      File.open(masaprivkey, "w") do |f| f.write masa_key.to_pem end
    end

    masa_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    masa_crt.version = 2
    masa_crt.serial = 1
    masa_crt.subject = OpenSSL::X509::Name.parse "/DC=ca/DC=sandelman/CN=Unstrung MASA"

    root_ca = HighwayKeys.ca.rootkey
    # masa is signed by root_ca
    masa_crt.issuer = root_ca.subject
    #root_ca.public_key = root_key.public_key
    masa_crt.public_key = masa_key
    masa_crt.not_before = Time.now

    # 2 years validity
    masa_crt.not_after = masa_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = masa_crt
    ef.issuer_certificate  = root_ca
    masa_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    masa_crt.sign(HighwayKeys.ca.rootprivkey, OpenSSL::Digest::SHA256.new)

    File.open(certdir.join("masa_#{curve}.crt"),'w') do |f|
      f.write masa_crt.to_pem
    end
  end

  desc "Create a certificate for the MASA web interface (EST) to answer requests"
  task :masa_server_cert => :environment do

    curve = HighwayKeys.ca.client_curve

    certdir = Rails.root.join('db').join('cert')
    FileUtils.mkpath(certdir)

    serverprivkey=certdir.join("server_#{curve}.key")
    if File.exists?(serverprivkey)
      server_key = OpenSSL::PKey.read(File.open(serverprivkey))
    else
      # the MASA's public/private key - 3*1024 + 8
      server_key = OpenSSL::PKey::EC.new(curve)
      server_key.generate_key
      File.open(serverprivkey, "w") do |f| f.write server_key.to_pem end
    end

    server_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    server_crt.version = 2
    server_crt.serial  = HighwayKeys.ca.serial
    server_crt.subject = OpenSSL::X509::Name.parse "/DC=ca/DC=sandelman/CN=localhost"

    root_ca = HighwayKeys.ca.rootkey
    # masa is signed by root_ca
    server_crt.issuer = root_ca.subject
    #root_ca.public_key = root_key.public_key
    server_crt.public_key = server_key
    server_crt.not_before = Time.now

    # 2 years validity
    server_crt.not_after = server_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = server_crt
    ef.issuer_certificate  = root_ca
    server_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    server_crt.sign(HighwayKeys.ca.rootprivkey, HighwayKeys.ca.digest)

    File.open(certdir.join("server_#{curve}.crt"),'w') do |f|
      f.write server_crt.to_pem
    end
  end

  desc "Sign a IDevID certificate for a new device, EUI64=xx"
  task :signmic => :environment do

    eui64 = ENV['EUI64']

    unless eui64
      puts "must set EUI64= to a valid MAC address"
      exit
    end

    dev = Device.create_by_number(eui64)
    dev.gen_and_store_key
  end

  desc "Sign voucher for device EUI64= to OWNER_ID=xx, with optional NONCE=xx, EXPIRES=yy"
  task :signvoucher => :environment do
    eui64 = ENV['EUI64']
    ownerid = ENV['OWNER_ID']
    nonce = ENV['NONCE']
    expires=ENV['EXPIRES'].try(:to_date)

    unless eui64
      puts "must set EUI64= to a valid MAC address"
      exit
    end

    device = Device.find_by_number(eui64)
    unless device
      puts "no device found with EUI64=#{eui64}"
      exit
    end

    unless ownerid
      puts "must set OWNER_ID= to a valid database ID"
      exit
    end
    owner = Owner.find(ownerid)

    voucher = Voucher.create_voucher(owner, device, Time.now, nonce, expires)

    puts "Voucher created and saved, #{voucher.id}, and fixture written to tmp"
    fw = FixtureWriter.new('tmp')
    voucher.savefixturefw(fw)
    fw.closefiles
  end


  def foo_one
    key = OpenSSL::PKey::RSA.new 2048
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 2
    cert.subject = OpenSSL::X509::Name.parse "/DC=org/DC=ruby-lang/CN=Ruby certificate"
    cert.issuer = root_ca.subject # root CA is the issuer
    cert.public_key = key.public_key
    cert.not_before = Time.now
    cert.not_after = cert.not_before + 1 * 365 * 24 * 60 * 60 # 1 years validity
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = root_ca
    cert.add_extension(ef.create_extension("keyUsage","digitalSignature", true))
    cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
    cert.sign(root_key, OpenSSL::Digest::SHA256.new)
  end

end
