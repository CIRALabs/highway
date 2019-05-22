require 'rails_helper'

RSpec.describe AcmeKeys do

  before(:each) do
    HighwayKeys.ca.certdir = Rails.root.join('spec','files','cert')
    MasaKeys.ca.certdir = Rails.root.join('spec','files','cert')
    AcmeKeys.acme.certdir=Rails.root.join('spec','files','cert')
  end

  it "should reuse an ACME key already generated" do
    unless ENV["ACME_TESTING"]
      tmp_device_dir(true) {
        # something wrong with authenticating the SSL key for staging server.
        # OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
        AcmeKeys.acme.acme_maybe_make_keys
        client = Acme::Client.new(private_key: AcmeKeys.acme.acmeprivkey,
                                  directory: AcmeKeys.acme.server,
                                  connection_options: {
                                    :ssl => {
                                      :ca_file => '/usr/lib/ssl/certs/ca-certificates.crt',
                                      :ca_path => "/usr/lib/ssl/certs"
                                    }
                                  })

        expect(client).to_not be_nil
        account = client.new_account(contact: 'mailto:minerva@sandelman.ca',
                                     terms_of_service_agreed: true)
        expect(account.kid).to_not be_nil
      }
    end
  end

  it "should enroll a SHG from a CSR provided" do
    unless ENV["ACME_TESTING"]
      # something wrong with authenticating the SSL key for staging server.
      #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

      # AcmeKeys is a local class that collects stuff including the key pair for
      # authenticating and options, and which server to talk to.
      #puts "Server at: #{AcmeKeys.acme.server}"

      qname = "ne34db3.r.dasblinkenled.org"
      zone  = "dasblinkenled.org"

      csr = OpenSSL::X509::Request.new(IO::binread("spec/files/hera.csr"))
      certpem = AcmeKeys.acme.cert_for(qname, zone, csr, Logger.new(STDOUT))

      File.open("tmp/hera.pem", "w") do |f|
        f.write certpem       # => PEM-formatted certificate
      end
    end
  end


end
