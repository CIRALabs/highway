require 'rails_helper'

RSpec.describe "IotDevices", type: :request do

  describe "sshg notification" do
    it "POST /send_new_device_notification" do
      post "/send_new_device_notification"

      expect(response).to have_http_status(200)
    end

    it "POST /send_done_analyzing_notification" do
      post "/send_done_analyzing_notification"

      expect(response).to have_http_status(200)
    end
  end
end
