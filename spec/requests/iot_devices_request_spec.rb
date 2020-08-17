require 'rails_helper'

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
      token = {}
      post "/send_new_device_notification", params: token, headers: {
             'SSL_CLIENT_CERT'=> pubkey_pem
           }
      expect(response).to have_http_status(200)
    end

    it "POST /send_done_analyzing_notification" do
      post "/send_done_analyzing_notification"

      expect(response).to have_http_status(200)
    end
  end
end
