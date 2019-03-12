# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'SmarKaKlink MASA API', type: :request do

  before(:each) do
    FileUtils::mkdir_p("tmp")
    MasaKeys.masa.certdir = Rails.root.join('spec','files','cert')
    IDevIDKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

  describe "smarkaklink IDevID enrollment" do
    it "POST a smartpledge voucher request, using correct content_type" do
      token = IO::read("spec/files/enroll1.json")

      post "/.well-known/est/smarkaklink", params: token, headers: {
             'CONTENT_TYPE' => 'application/json',
             'ACCEPT'       => 'application/pkcs7',
           }

      expect(response).to have_http_status(200)
      owner=assigns(:owner)
      expect(owner).to_not be_nil

      cert = OpenSSL::X509::Certificate.new(response.body)
      expect(cert.issuer.to_s).to eq("/DC=ca/DC=sandelman/CN=highway-test.example.com IDevID CA")
      expect(cert.subject.to_s).to include(owner.simplename)
    end

    it "POST a smarkaklink voucher request, with an invalid content_type" do
      token = IO::read("spec/files/enroll1.json")

      post "/.well-known/est/smarkaklink", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs10',
             'ACCEPT'       => 'application/pkcs7',
           }

      expect(response).to have_http_status(406)
      expect(assigns(:owner)).to be_nil
    end
  end

end
