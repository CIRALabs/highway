# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'SmartPledge MASA API', type: :request do

  before(:each) do
    FileUtils::mkdir_p("tmp")
    MasaKeys.masa.certdir = Rails.root.join('spec','files','cert')
  end

  describe "smartpledge IDevID enrollment" do
    it "POST a smartpledge voucher request, with an invalid content_type" do
      token = IO::read("spec/files/enroll1.json")

      post "/.well-known/est/smartpledge", params: token, headers: {
             'CONTENT_TYPE' => 'application/json',
             'ACCEPT'       => 'application/pkcs7',
           }

      expect(response).to have_http_status(406)
    end
  end

end
