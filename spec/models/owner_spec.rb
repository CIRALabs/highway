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
      expect(o1.certder.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=fountain-test.example.com domain authority")
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
      expect(o1.registrarID.unpack("H*").first).to eq("a4bec67ef05266502b3da130e78e0badf7291286")
    end

    it "should generate a pubkey from a public key only owner" do
      o1 = owners(:owner446739022)
       expect(o1.certificate).to be_nil
      expect(o1.pubkey_object).to_not be_nil
    end
  end

  describe "finding" do
    it "should create a new owner by public key" do
      o2 = Owner.find_or_create_by_base64_certificate("MIIBkTCCARegAwIBAgIEWY2RTzAKBggqhkjOPQQDAjAyMQ8wDQYDVQQGEwZDYW5hZGExHzAdBgNVBAsMFlNtYXJ0UGxlZGdlLTE1MDI0NDk5OTkwHhcNMTkwMjI2MjI1NjU4WhcNMjEwMjI1MjI1NjU4WjAyMQ8wDQYDVQQGEwZDYW5hZGExHzAdBgNVBAsMFlNtYXJ0UGxlZGdlLTE1MDI0NDk5OTkwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAASVk-3g44k4GX8MK7la8dais01j3KDxUEXIQ8RW44OfP_VLjfNoBwEIiO3SPXnIyw4wDcDavcpTs6W10Q87xtN1c2ZkPfkDyogNGy0nmxPLpUkoUCvgrMZ1C89LGs6g9LowCgYIKoZIzj0EAwIDaAAwZQIwFjWxibqz0-eVlVbfIvEfK3VbTiGKb-eWyYaalE_yLNplaCL0EWBRqDiLEzoqy7_EAjEAiO-72GN2AJbb0aRPzZcld-SelEkPRamCdWU81f_IjHiZ84_A9XkYVVzIZ-3DcKq2")
      expect(o2).to_not be_nil
      expect(o2.name).to eq("/C=Canada/OU=SmartPledge-1502449999")
      expect(o2.fqdn).to be_nil
    end

    it "should find an existing owner by public key" do
      o4 = Owner.find_by_base64_certificate("MIIBrjCCATOgAwIBAgIBAzAKBggqhkjOPQQDAzBOMRIwEAYKCZImiZPyLGQBGRYC
    Y2ExGTAXBgoJkiaJk/IsZAEZFglzYW5kZWxtYW4xHTAbBgNVBAMMFFVuc3RydW5n
    IEZvdW50YWluIENBMB4XDTE3MDkwNTAxMTI0NVoXDTE5MDkwNTAxMTI0NVowQzES
    MBAGCgmSJomT8ixkARkWAmNhMRkwFwYKCZImiZPyLGQBGRYJc2FuZGVsbWFuMRIw
    EAYDVQQDDAlsb2NhbGhvc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQ1ZA7N
    w0xSM/Q2u194FzQMktZ94waAIV0i/oVTPgOJ8zW6MwF5z+Dpb8/puhObJMZ0U6H/
    wfApR6svlumd4ryyow0wCzAJBgNVHRMEAjAAMAoGCCqGSM49BAMDA2kAMGYCMQC3
    /iTQJ3evYYcgbXhbmzrp64t3QC6qjIeY2jkDx062nuNifVKtyaara3F30AIkKSEC
    MQDi29efbTLbdtDk3tecY/rD7V77XaJ6nYCmdDCR54TrSFNLgxvt1lyFM+0fYpYR
    c3o=")
      expect(o4).to_not be_nil
      expect(o4.name).to eq("owner4")
    end
  end

  describe "signing" do
    it "should generate an IDevID from a self-signed certificate" do
      IDevIDKeys.ca.certdir = Rails.root.join('spec','files','cert')
      o0 = owners(:owner4)
      orig_issuer = o0.cert.issuer.to_s
      o0.sign_with_idevid_ca
      new_issuer = o0.cert.issuer.to_s
      expect(new_issuer).to eq(IDevIDKeys.ca.cacert.subject.to_s)
      expect(new_issuer).to_not eq(orig_issuer)
    end
  end

end
