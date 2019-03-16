require 'rails_helper'

RSpec.describe AcmeKeys do

  before(:each) do
    HighwayKeys.ca.certdir = Rails.root.join('spec','files','cert')
    MasaKeys.ca.certdir = Rails.root.join('spec','files','cert')
    AcmeKeys.acme.certdir=Rails.root.join('spec','files','cert')
  end

  it "should reuse an ACME key already generated" do
    tmp_device_dir(true) {
      # something wrong with authenticating the SSL key for staging server.
      OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
      AcmeKeys.acme.acme_maybe_make_keys
      client = Acme::Client.new(private_key: AcmeKeys.acme.acmeprivkey,
                                directory: AcmeKeys.acme.server)
      expect(client).to_not be_nil
      account = client.new_account(contact: 'mailto:minerva@sandelman.ca',
                                   terms_of_service_agreed: true)
      expect(account.kid).to_not be_nil
    }
  end

  it "should enroll a SHG from a CSR provided" do
    # something wrong with authenticating the SSL key for staging server.
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

    # AcmeKeys is a local class that collects stuff including the key pair for
    # authenticating and options, and which server to talk to.
    puts "Server at: #{AcmeKeys.acme.server}"

    client = Acme::Client.new(private_key: AcmeKeys.acme.acmeprivkey,
                              directory: AcmeKeys.acme.server)
    account = client.new_account(contact: 'mailto:minerva@sandelman.ca',
                                 terms_of_service_agreed: true)

    zone = "ne34db3.r.dasblinkenled.org"
    order = client.new_order(identifiers: [zone])
    authorization = order.authorizations.first
    challenge = authorization.dns
    expect(challenge.record_name).to eq("_acme-challenge")

    dns = DnsUpdate::load AcmeKeys.acme.update_options
    target = challenge.record_name + "." + zone
    puts "Removing  old challenge from #{target}"
    dns.remove { |m|
      m.type = :txt
      m.zone = "dasblinkenled.org"
      m.hostname = target
    }
    sleep(1)
    puts "Adding #{challenge.token} challenge to #{target}"
    dns.update { |m|
      m.type = :txt
      m.zone = "dasblinkenled.org"
      m.hostname = target
      m.data     = challenge.record_content
    }
    sleep(30)
    puts "NIC"
    system("dig +short @nic.sandelman.ca #{target} txt")
    puts "SNS"
    system("dig +short @sns.cooperix.net #{target} txt")
    challenge.request_validation

    while challenge.status == 'pending'
      puts "Challenge waiting"
      sleep(2)
      challenge.reload
    end
    puts "Status: #{challenge.status} "
    if challenge.status != "valid"
      byebug
      puts "Error #{challenge.error["detail"]}"
    end
    expect(challenge.status).to eq('valid')

    csr = OpenSSL::X509::Request.new(IO::binread("spec/files/hera.csr"))
    order.finalize(csr: csr)
    while order.status == 'processing'
      puts "Order waiting"
      sleep(1)
    end

    File.open("tmp/hera.pem", "w") do |f|
      f.write order.certificate # => PEM-formatted certificate
    end
  end


end
