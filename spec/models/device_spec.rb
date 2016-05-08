require 'rails_helper'

RSpec.describe Device, type: :model do
  fixtures :all

  describe "key generation" do
    it "should generate a new public/private key pair, and sign it" do
      almec = devices(:almec)

      almec.gen_and_store_key
      expect(almec.pub_key).to_not be_nil
      # expect almec public key to verify with root key
    end

    it "should generate a new private key, and store it" do
      almec = devices(:almec)

      almec.gen_priv_key
      almec.store_priv_key(HighwayKeys.ca.devicedir)
    end

    it "should generate a new private key, and sign it" do
      almec = devices(:almec)

      almec.gen_and_store_key
      almec.sign_eui64
    end
  end

  describe "eui64 strings" do
    it "should sanitize non-hex out of eui64" do
      t1 = Device.new(eui64: '../;bobby/11-22-44-55-22-55-88-22/')
      expect(t1.sanitized_eui64).to eq("BBB11-22-44-55-22-55-88-22")
    end
  end
end
