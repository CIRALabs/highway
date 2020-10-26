require 'rails_helper'

VCR.configure do |config|
  allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.describe "IotDevices", type: :request do
  fixtures :all

  describe "sshg notification" do
    it "should fail when no certificate has been provided to /send_new_device_notification" do
      # /send_new_device_notification maps to IotDevicesController#new
      post "/send_new_device_notification"

      expect(response).to have_http_status(403)
    end

    it "should fail when the certificate does not belong to any valid device" do
      # /send_new_device_notification maps to IotDevicesController#new
      # use a certificate from the borgin (hostile) MASA
      pubkey_pem = File.read("spec/files/borgin/00-D0-E5-F3-00-02/device.crt")
      token = {}
      post "/send_new_device_notification", params: token, headers: {
             'SSL_CLIENT_CERT'=> pubkey_pem
           }

      expect(response).to have_http_status(404)
    end

    it "POST /send_new_device_notification" do
      # /send_new_device_notification maps to IotDevicesController#new
      # use a certificate from our internal test devices
      pubkey_pem = devices(:zeb).certificate.to_pem
      token = { registrationTokens: [ "ezvwEVC9gO0:APA91bF_8SEkPYHY1fy0Ul-e61bWjrkp9KxnRSTiUJJBGp4Owwm67ryqBffXmqounNCNE3QlH0Y0PMuXcjY6eu0Cdu7RvnRFQzJdxGjUTx1UUGYEmIMdPEN5irn2L9LpFCXSiY509ynv" ] }

      stub_request(:post, "https://fcm.googleapis.com/fcm/send").
         with(
           headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'key=46aea237fce7f504209c4bd51bab360fbe3cf2adf6cb0c4a24db45f0cfd6412d7068810772f1e84a8607d0250e36f7f9189a8eb706a1d8614689c3cb05dd378d',
          'Content-Type'=>'application/json',
           }).
         to_return(status: 200, body: "", headers: {})

      post "/send_new_device_notification", params: token, headers: {
             'SSL_CLIENT_CERT'=> pubkey_pem
           }
      expect(response).to have_http_status(200)
    end

    it "should fail to POST /send_new_device_notification without tokens" do
      # /send_new_device_notification maps to IotDevicesController#new
      # use a certificate from our internal test devices
      pubkey_pem = devices(:zeb).certificate.to_pem
      token = { }

      post "/send_new_device_notification", params: token, headers: {
             'SSL_CLIENT_CERT'=> pubkey_pem
           }
      expect(response).to have_http_status(403)
    end

    it "should fail to POST /send_new_device_notification with empty set of tokens" do
      # /send_new_device_notification maps to IotDevicesController#new
      # use a certificate from our internal test devices
      pubkey_pem = devices(:zeb).certificate.to_pem
      token = { registrationTokens: [] }

      post "/send_new_device_notification", params: token, headers: {
             'SSL_CLIENT_CERT'=> pubkey_pem
           }
      expect(response).to have_http_status(403)
    end

    it "POST /send_done_analyzing_notification" do
      post "/send_done_analyzing_notification"

      expect(response).to have_http_status(200)
    end
  end
end
