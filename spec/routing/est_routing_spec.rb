require "rails_helper"

RSpec.describe EstController, type: :routing do
  describe "est routing" do

    it "long routes to #smartpledge" do
      expect(:post => "/.well-known/est/smartpledge").to route_to("smartpledge#enroll")
    end

    it "routes to #smartpledge" do
      expect(:post => "/smartpledge/enroll").to route_to("smartpledge#enroll")
    end
  end
end
