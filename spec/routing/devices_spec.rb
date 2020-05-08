require "rails_helper"

RSpec.describe DevicesController, type: :routing do
  describe "devices routing" do

    it "get details on a device by public key" do
      expect(:get => "/devices").to route_to("devices#index")
    end
  end
end
