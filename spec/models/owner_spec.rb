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

    it "should have a nname" do
      o1 = owners(:owner1)
      expect(o1.name).to_not be_nil
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

  describe "finding" do
    it "should look up an owner by public key" do
      o2 = Owner.find_by_base64_certificate("MIIBkTCCARegAwIBAgIEWY2RTzAKBggqhkjOPQQDAjAyMQ8wDQYDVQQGEwZDYW5hZGExHzAdBgNVBAsMFlNtYXJ0UGxlZGdlLTE1MDI0NDk5OTkwHhcNMTkwMjI2MjI1NjU4WhcNMjEwMjI1MjI1NjU4WjAyMQ8wDQYDVQQGEwZDYW5hZGExHzAdBgNVBAsMFlNtYXJ0UGxlZGdlLTE1MDI0NDk5OTkwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAASVk-3g44k4GX8MK7la8dais01j3KDxUEXIQ8RW44OfP_VLjfNoBwEIiO3SPXnIyw4wDcDavcpTs6W10Q87xtN1c2ZkPfkDyogNGy0nmxPLpUkoUCvgrMZ1C89LGs6g9LowCgYIKoZIzj0EAwIDaAAwZQIwFjWxibqz0-eVlVbfIvEfK3VbTiGKb-eWyYaalE_yLNplaCL0EWBRqDiLEzoqy7_EAjEAiO-72GN2AJbb0aRPzZcld-SelEkPRamCdWU81f_IjHiZ84_A9XkYVVzIZ-3DcKq2")
      expect(o2).to_not be_nil
    end
  end

end
