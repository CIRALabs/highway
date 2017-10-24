require 'rails_helper'

RSpec.describe Device, type: :model do
  fixtures :all

  describe "relations" do
    it "should have many vouchers" do
      almec = devices(:almec)
      expect(almec.vouchers.count).to be >= 0
    end
    it "should belong to an owner" do
      expect(devices(:device11).owner).to_not be_nil
    end
  end

  describe "key generation" do
    it "should generate a new public/private key pair, and sign it" do
      almec = devices(:almec)

      almec.gen_and_store_key

      expect(almec.pub_key).to_not be_nil
      expect(File.exists?("db/devices/#{almec.sanitized_eui64}/device.crt")).to be true
      # expect almec public key to verify with root key
    end

    it "should generate a new private key, and store it" do
      almec = devices(:almec)

      almec.gen_or_load_priv_key(HighwayKeys.ca.devicedir)
      expect(almec.dev_key).to_not be_nil
    end

    it "should recognize a voucher request containing the same public key" do
      vr11 = voucher_requests(:voucherreq54)
      d11 = vr11.device
      expect(d11).to eq(devices(:device11))
      expect(d11.signing_key?(vr11.signing_public_key)).to be_truthy
    end

    it "should recognize a voucher request containing the wrong public key" do
      vr11 = voucher_requests(:voucher14)
      d11 = vr11.device
      expect(d11).to eq(devices(:device11))
      expect(d11.signing_key?(vr11.signing_public_key)).to be_falsey
    end
  end

  describe "certificate creation" do
    it "should create a certificate with a new issue " do
      almec = devices(:almec)

      almec.gen_or_load_priv_key(HighwayKeys.ca.devicedir)
      almec.sign_eui64
      expect(almec.idevid.serial).to eq(1)

      vizsla = devices(:vizsla)

      vizsla.gen_or_load_priv_key(HighwayKeys.ca.devicedir)
      vizsla.sign_eui64
      expect(vizsla.idevid.serial).to eq(2)

    end

    it "should create a certificate with a interesting MASA url" do
      SystemVariable.setvalue(:masa_url, "https://masa.example.com")

      ndev = Device.new
      ndev.eui64 = '00-16-3e-ff-fe-d0-55-aa'
      ndev.gen_and_store_key

      expect(system("openssl x509 -noout -text -in #{ndev.certificate_filename} | grep masa.example.com")).to be true
    end
  end

  describe "eui64 strings" do
    it "should sanitize non-hex out of eui64" do
      t1 = Device.new(eui64: '../;bobby/11-22-44-55-22-55-88-22/')
      expect(t1.sanitized_eui64).to eq("BBB11-22-44-55-22-55-88-22")
    end
  end

  describe "audit log" do
    it "should have three vouchers" do
      d14 = devices(:device14)
      expect(d14.vouchers.count).to eq(3)
    end

    it "should have three owners via three vouchers" do
      d14 = devices(:device14)
      expect(d14.owners.count).to eq(3)
      expect(d14.owners[0]).to eq owners(:owner4)
      expect(d14.owners[1]).to eq owners(:owner2)
      expect(d14.owners[2]).to eq owners(:owner1)
    end

    it "should produce a hash representing the audit log for a device" do
      d14 = devices(:device14)

      log = d14.audit_log
      expect(log['version']).to eq('1')
      expect(log['events'].count).to eq(3)
      expect(log['events'][0]['registrarID']).to eq(owners(:owner4).registrarID_base64)
      expect(log['events'][1]['registrarID']).to eq(owners(:owner2).registrarID_base64)

    end
  end

  describe "searching" do
    it "should find a device by eui64 or serialnumber" do
      b1 = Device.find_by_number('00-D0-E5-F2-00-02')
      expect(b1).to_not be_nil
    end
  end
end
