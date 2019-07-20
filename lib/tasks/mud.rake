# -*- ruby -*-

namespace :highway do

  desc "Sign a MUD json FILE=in.json [OUTFILE=out.json SIGFILE=out.sig]"
  task :mud_json_sign => :environment do
    file    = ENV['FILE']
    sigfilename = File.join(File.dirname(file), File.basename(file, ".*") + ".sig")
    if ENV['SIGFILE']
      sigfilename = ENV['SIGFILE']
    end
    outfilename = File.join(File.dirname(file), File.basename(file, ".*") + ".ojson")
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
