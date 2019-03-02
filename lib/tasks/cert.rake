# -*- ruby -*-

namespace :highway do

  desc "Create initial self-signed CA certificate, or resign existing one"
  task :h1_bootstrap_ca => :environment do

    curve = HighwayKeys.ca.curve
    vendorprivkey = HighwayKeys.ca.certdir.join("vendor_#{curve}.key")
    outfile       = HighwayKeys.ca.certdir.join("vendor_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s CA", dnprefix, SystemVariable.string(:hostname))
    puts "issuer is now: #{dn}"
    dnobj = OpenSSL::X509::Name.parse dn

    root_ca = HighwayKeys.ca.sign_certificate(vendorprivkey, outfile, dnobj) {|cert, ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    }
    puts "CA Certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the MASA to sign vouchers with"
  task :h2_bootstrap_masa => :environment do

    curve = MasaKeys.ca.curve

    certdir = HighwayKeys.ca.certdir
    FileUtils.mkpath(certdir)

    masaprivkey=certdir.join("masa_#{curve}.key")
    if File.exists?(masaprivkey)
      puts "MASA using existing key at: #{masaprivkey}"
      masa_key = OpenSSL::PKey.read(File.open(masaprivkey))
    else
      # the MASA's public/private key - 3*1024 + 8
      masa_key = OpenSSL::PKey::EC.new(curve)
      masa_key.generate_key
      File.open(masaprivkey, "w", 0600) do |f| f.write masa_key.to_pem end
    end

    masa_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    masa_crt.version = 2

    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s MASA", dnprefix, SystemVariable.string(:hostname))
    masa_crt.subject = OpenSSL::X509::Name.parse dn

    root_ca = HighwayKeys.ca.rootkey

    # masa is signed by root_ca
    masa_crt.issuer = root_ca.subject
    masa_crt.serial     = HighwayKeys.ca.serial
    masa_crt.public_key = masa_key
    masa_crt.not_before = Time.now

    # 2 years validity
    masa_crt.not_after = masa_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = masa_crt
    ef.issuer_certificate  = root_ca
    masa_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    puts "Signing with CA key at #{HighwayKeys.ca.root_priv_key_file}"
    masa_crt.sign(HighwayKeys.ca.rootprivkey, OpenSSL::Digest::SHA256.new)

    outfile=certdir.join("masa_#{curve}.crt")
    File.open(outfile,'w') do |f|
      f.write masa_crt.to_pem
    end
    puts "MASA voucher signing certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the MASA to sign MUD objects"
  task :h3_bootstrap_mud => :environment do

    curve = MudKeys.ca.curve

    certdir = HighwayKeys.ca.certdir
    FileUtils.mkpath(certdir)

    mudprivkey=certdir.join("mud_#{curve}.key")
    if File.exists?(mudprivkey)
      puts "MUD using existing key at: #{mudprivkey}"
      mud_key = OpenSSL::PKey.read(File.open(mudprivkey))
    else
      # the MUD's public/private key - 3*1024 + 8
      mud_key = OpenSSL::PKey::EC.new(curve)
      mud_key.generate_key
      File.open(mudprivkey, "w", 0600) do |f| f.write mud_key.to_pem end
    end

    mud_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    mud_crt.version = 2

    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s MUD", dnprefix, SystemVariable.string(:hostname))
    mud_crt.subject = OpenSSL::X509::Name.parse dn

    root_ca = HighwayKeys.ca.rootkey

    mud_crt.serial     = HighwayKeys.ca.serial
    # masa is signed by root_ca
    mud_crt.issuer = root_ca.subject
    mud_crt.public_key = mud_key
    mud_crt.not_before = Time.now

    # 2 years validity
    mud_crt.not_after = mud_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = mud_crt
    ef.issuer_certificate  = root_ca
    mud_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    puts "Signing with CA key at #{HighwayKeys.ca.root_priv_key_file}"
    mud_crt.sign(HighwayKeys.ca.rootprivkey, OpenSSL::Digest::SHA256.new)

    outfile=certdir.join("mud_#{curve}.crt")
    File.open(outfile,'w') do |f|
      f.write mud_crt.to_pem
    end
    puts "MUD file signing certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the MASA web interface (EST) to answer requests"
  task :h4_masa_server_cert => :environment do

    curve = HighwayKeys.ca.client_curve

    certdir = HighwayKeys.ca.certdir
    FileUtils.mkpath(certdir)

    serverprivkey=certdir.join("server_#{curve}.key")
    if File.exists?(serverprivkey)
      puts "Server using existing key at: #{serverprivkey}"
      server_key = OpenSSL::PKey.read(File.open(serverprivkey))
    else
      # the MASA's public/private key - 3*1024 + 8
      server_key = OpenSSL::PKey::EC.new(curve)
      server_key.generate_key
      File.open(serverprivkey, "w", 0600) do |f| f.write server_key.to_pem end
    end

    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s", dnprefix, SystemVariable.string(:hostname))

    server_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    server_crt.version = 2
    server_crt.serial  = HighwayKeys.ca.serial
    server_crt.subject = OpenSSL::X509::Name.parse dn

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
    puts "Signing with CA key at #{HighwayKeys.ca.root_priv_key_file}"
    server_crt.sign(HighwayKeys.ca.rootprivkey, HighwayKeys.ca.digest)

    outfile=certdir.join("server_#{curve}.crt")
    File.open(outfile,'w') do |f|
      f.write server_crt.to_pem
    end
    puts "MASA server certificate writtten to: #{outfile}"
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

  desc "Create an IDevID certificate based upon a Certificate Signing Request (CSR=). Output to CERT="
  task :signcsr => :environment do

    input = ENV['CSR']
    output= ENV['CERT']

    dev = Device.create_from_csr_io(File.read(input))
    File.open(output, "w") do |f| f.write dev.certificate.to_pem; end
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

end
