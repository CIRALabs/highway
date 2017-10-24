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
      expect(o1.certder.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=localhost")
    end

    it "should generate a pubkey from a certificate" do
      o1 = owners(:owner1)
      expect(o1.certificate).to_not be_nil
      expect(o1.pubkey).to_not be_nil
      expect(o1.pubkey_from_cert).to_not be_nil
    end

    it "should have a registarID" do
      o1 = owners(:owner1)
      expect(o1.registrarID).to_not be_nil
      expect(o1.registrarID.unpack("H*").first).to eq("cbaf9dfca611bc967d15252f54d90fad116d7a0c")
    end

    it "should generate a pubkey from a public key only owner" do
      o1 = owners(:owner446739022)
       expect(o1.certificate).to be_nil
      expect(o1.pubkey_object).to_not be_nil
    end
  end
end
