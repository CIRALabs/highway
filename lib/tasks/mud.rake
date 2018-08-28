# -*- ruby -*-

namespace :highway do

  desc "Create a certificate for the MASA to sign MUD objects"
  task :bootstrap_mud => :environment do

    curve = MudKeys.ca.curve

    certdir = Rails.root.join('db').join('cert')
    FileUtils.mkpath(certdir)

    mudprivkey=certdir.join("mud_#{curve}.key")
    if File.exists?(mudprivkey)
      mud_key = OpenSSL::PKey.read(File.open(mudprivkey))
    else
      # the MUD's public/private key - 3*1024 + 8
      mud_key = OpenSSL::PKey::EC.new(curve)
      mud_key.generate_key
      File.open(mudprivkey, "w") do |f| f.write mud_key.to_pem end
    end

    mud_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    mud_crt.version = 2

    dn = sprintf("/DC=ca/DC=sandelman/CN=%s MUD authority", SystemVariable.string(:hostname))
    mud_crt.subject = OpenSSL::X509::Name.parse dn

    root_ca = HighwayKeys.ca.rootkey
    root_ca.serial  = rand(104857600)
    # mud is signed by root_ca
    mud_crt.issuer = root_ca.subject
    #root_ca.public_key = root_key.public_key
    mud_crt.public_key = mud_key
    mud_crt.not_before = Time.now

    # 2 years validity
    mud_crt.not_after = mud_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = mud_crt
    ef.issuer_certificate  = root_ca
    mud_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    mud_crt.sign(HighwayKeys.ca.rootprivkey, OpenSSL::Digest::SHA256.new)

    File.open(certdir.join("mud_#{curve}.crt"),'w') do |f|
      f.write mud_crt.to_pem
    end
  end

  desc "Sign a MUD json file"
  task :mud_json_sign => :environment do
    file    = ENV['FILE']
    sigfilename = File.join(file, ".sig")
    if ENV['SIGFILE']
      sigfilename = ENV['SIGFILE']
    end
    outfilename = File.join(file, ".json")
    if ENV['OUTFILE']
      outfilename = ENV['OUTFILE']
    end

    rawjson = File.read(file)

    sigurl      = File.basename(sigfilename)

    # the mudjson must have the mud-signature URL inserted into it.
    muddata = JSON::parse(rawjson)

    muddata["ietf-mud:mud"]["mud-signature"] = sigurl

    cookedjson = muddata.to_json

    privkey = MudKeys.mud.mudprivkey
    signing_cert = MudKeys.mud.mudkey

    flags  = OpenSSL::PKCS7::DETACHED
    flags |= OpenSSL::PKCS7::BINARY | OpenSSL::PKCS7::NOSMIMECAP
    signature= OpenSSL::PKCS7.sign(signing_cert, privkey, cookedjson, [], flags )
    File.open(sigfilename, "wb") do |sigfile| sigfile.write signature.to_der  end
    File.open(outfilename, "wb") do |outfile| outfile.write cookedjson end

  end

end
