# -*- ruby -*-

namespace :highway do

  desc "Create initial self-signed CA certificate, or resign existing one"
  task :h1_bootstrap_ca => :environment do

    curve = HighwayKeys.ca.curve
    vendorprivkeyfile = HighwayKeys.ca.certdir.join("vendor_#{curve}.key")
    outfile       = HighwayKeys.ca.certdir.join("vendor_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s CA", dnprefix, SystemVariable.string(:hostname))
    puts "issuer is now: #{dn}"
    dnobj = OpenSSL::X509::Name.parse dn

    HighwayKeys.ca.sign_certificate("CA", dnobj,
                                    vendorprivkeyfile,
                                    outfile, dnobj) { |cert, ef|
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
    certdir = MasaKeys.ca.certdir
    masaprivkeyfile= certdir.join("masa_#{curve}.key")
    outfile        = certdir.join("masa_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s MASA", dnprefix, SystemVariable.string(:hostname))

    HighwayKeys.ca.sign_end_certificate("MASA",
                                        masaprivkeyfile,
                                        outfile, dn)
    puts "MASA voucher signing certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the MASA to sign MUD objects"
  task :h3_bootstrap_mud => :environment do

    curve   = MudKeys.ca.curve
    certdir = HighwayKeys.ca.certdir
    mudprivkeyfile = certdir.join("mud_#{curve}.key")
    outfile=certdir.join("mud_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s MUD", dnprefix, SystemVariable.string(:hostname))

    HighwayKeys.ca.sign_end_certificate("MUD",
                                        mudprivkeyfile,
                                        outfile, dn)
    puts "MUD file signing certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the MASA web interface (EST) to answer requests"
  task :h4_masa_server_cert => :environment do

    curve   = HighwayKeys.ca.client_curve
    certdir = HighwayKeys.ca.certdir
    serverprivkeyfile = certdir.join("server_#{curve}.key")
    outfile=certdir.join("server_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s", dnprefix, SystemVariable.string(:hostname))
    dnobj = OpenSSL::X509::Name.parse dn

    mud_cert = HighwayKeys.ca.sign_certificate("SERVER", nil,
                                               serverprivkeyfile,
                                               outfile, dnobj) { |cert,ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    }
    puts "MASA SERVER certificate writtten to: #{outfile}"
  end

  desc "Create an intermediate CA for signing SmartPledge IDevID devices"
  task :h5_idevid_ca => :environment do

    curve             = IDevIDKeys.ca.curve
    dnprefix          = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s IDevID CA", dnprefix, SystemVariable.string(:hostname))
    puts "issuer is now: #{dn}"
    dnobj = OpenSSL::X509::Name.parse dn
    outfile=IDevIDKeys.ca.idevid_pub_keyfile

    HighwayKeys.ca.sign_certificate("IDevID", nil,
                                    IDevIDKeys.ca.idevid_priv_keyfile,
                                    IDevIDKeys.ca.idevid_pub_keyfile,
                                    dnobj) { |cert, ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    }
    puts "IDevID Certificate writtten to: #{outfile}"
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
