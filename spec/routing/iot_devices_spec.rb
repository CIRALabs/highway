require "rails_helper"

RSpec.describe IotDevicesController, type: :routing do
  describe "sshg notification" do
    it "routes new device" do
      expect(:post => "/send_new_device_notification").to route_to("iot_devices#new")
    end

    it "routes analysis complete" do
      expect(:post => "/send_done_analyzing_notification").to route_to("iot_devices#analysis_complete")
    end
  end

end
