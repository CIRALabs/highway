require "rails_helper"

RSpec.describe EstController, type: :routing do
  describe "est routing" do

    it "long routes to #smarkaklink" do
      expect(:post => "/.well-known/est/smarkaklink").to route_to("smarkaklink#enroll")
    end

    it "routes to #smarkaklink" do
      expect(:post => "/smarkaklink/enroll").to route_to("smarkaklink#enroll")
    end
  end
end
