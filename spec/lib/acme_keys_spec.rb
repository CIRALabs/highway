require 'rails_helper'

RSpec.describe AcmeKeys do

  before(:each) do
    HighwayKeys.ca.certdir = Rails.root.join('spec','files','cert')
    MasaKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

  it "should reuse an ACME key already generated" do
    tmp_device_dir(true) {
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




end
