require 'rails_helper'

RSpec.describe Owner, type: :model do
  fixtures :all

  describe "relations" do
    it { should have_many(:vouchers) }
  end

  describe "certificates" do
    it "should have a certificate" do
      o1 = owners(:owner1)
      expect(o1.certificate).to_not be_nil

      expect(o1.certder).to_not be_nil
      expect(o1.certder.subject.to_s).to eq("/C=CA/ST=Ontario/L=Ottawa/O=Owner Example One/OU=Not Very/CN=owner1.example.com/emailAddress=owner1@example.com")
    end
  end
end
