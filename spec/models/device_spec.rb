require 'rails_helper'

RSpec.describe Device, type: :model do
  fixtures :all

  before(:each) do
    HighwayKeys.ca.certdir = Rails.root.join('spec','files','cert')
    MasaKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

  describe "canonical eui" do
    it "should turn colons into dashes" do
      expect(Device.canonicalize_eui64("aa:bb:cc:dd:ee:ff")).to eq("aa-bb-cc-dd-ee-ff")
    end

    it "should handle 6 byte eui" do
      expect(Device.canonicalize_eui64("aa-bb-cc-dd-ee-ff")).to eq("aa-bb-cc-dd-ee-ff")
    end

    it "should handle 7 byte eui" do
      expect(Device.canonicalize_eui64("00-11-aa-bb-cc-dd-ee-ff")).to eq("00-11-aa-bb-cc-dd-ee-ff")
    end

    it "should downcase hex digits" do
      expect(Device.canonicalize_eui64("AA-Bb-cc-dD-eE-ff")).to eq("aa-bb-cc-dd-ee-ff")
    end

    it "should insert dashes if missing" do
      expect(Device.canonicalize_eui64("aabbccddeeff")).to eq("aa-bb-cc-dd-ee-ff")
    end

  end

  describe "relations" do
    it "should have many vouchers" do
      almec = devices(:almec)
      expect(almec.vouchers.count).to be >= 0
    end
    it "should belong to an owner" do
      expect(devices(:device11).owner).to_not be_nil
    end
  end

  def mk_empty_dir
    newdir = Rails.root.join("tmp").join("devices")
    FileUtils.remove_entry_secure(newdir) if Dir.exists?(newdir)
    FileUtils.mkdir_p(newdir)
    newdir
  end

  def tmp_device_dir(copied=false)
    olddir = HighwayKeys.ca.devicedir
    newdir = mk_empty_dir
    HighwayKeys.ca.devdir = newdir
    if copied
      system("cp -r #{olddir}/. #{newdir}/.")
    end
    yield
    HighwayKeys.ca.devdir = olddir
  end

  describe "key generation" do
    it "should generate a new public/private key pair, and sign it" do
      almec = devices(:almec)

      tmp_device_dir {
        almec.gen_and_store_key
        expect(almec.idevid_cert).to_not be_nil
        expect(File.exists?(File.join(HighwayKeys.ca.devicedir, "#{almec.sanitized_eui64}/device.crt"))).to be true
      }
      # expect almec public key to verify with root key
    end

    it "should generate a new private key, and store it" do
      almec = devices(:almec)

      tmp_device_dir {
        almec.gen_or_load_priv_key(HighwayKeys.ca.devicedir, 'prime256v1', false)
      }

      expect(almec.dev_key).to_not be_nil

      # weirdly, PKey::EC is not actually subclass of PKey.
      # expect(almec.public_key).to be_kind_of(OpenSSL::PKey)
      expect(almec.public_key).to be_kind_of(OpenSSL::PKey::EC)
    end

    it "should preserve public key in pub_key field" do
      almec = devices(:almec)
      tmp_device_dir(true) {
        almec.gen_or_load_priv_key(HighwayKeys.ca.devicedir, 'prime256v1', false)
      }
      expect(almec.dev_key).to_not be_nil

      gen_pubkey = almec.public_key

      # get fresh copy
      almec = Device.find(almec.id)
      # use to_pem to get deep comparison of contents
      expect(almec.public_key.to_pem).to eq(gen_pubkey.to_pem)
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

  describe "certificate signing request" do
    it "should accept a CSR in a file, generating an IDevID" do
      input = Rails.root.join("spec", "files", "csr", "sample1.csr")
      csr = OpenSSL::X509::Request.new(File.read(input))

      expect(csr.subject.to_s).to eq("/CN=www.iotrus.com/O=IOT-R-US, Inc./C=US/ST=NC/L=RTP/serialNumber=IOTRUS-0123456789")

      dev = Device.create_from_csr(csr)
      expect(dev).to be_present
      expect(dev.serial_number).to     eq("IOTRUS-0123456789")
      expect(dev.idevid_cert).to_not   be_nil
      expect(dev.certificate.subject.to_s).to eq("/serialNumber=IOTRUS-0123456789")
    end
  end

  describe "certificate creation" do
    it "should create a certificate with a new issue " do
      almec = devices(:almec)

      dd = mk_empty_dir
      almec.gen_or_load_priv_key(dd)
      almec.sign_eui64
      expect(almec.idevid.serial).to be > 1
      almec.save!
      expect(almec.pub_key).to_not be_nil

      vizsla = devices(:vizsla)

      vizsla.gen_or_load_priv_key(dd)
      vizsla.sign_eui64
      expect(vizsla.idevid.serial).to_not eq(almec.idevid.serial)

      keyUsage = false
      eku      = false
      vizsla.idevid.extensions.each { |ext|
        case ext.oid
        when "basicConstraints"
          expect(ext.value).to eq("CA:FALSE")
        when "keyUsage"
          keyUsage=(ext.value == "Digital Signature")

        when "extendedKeyUsage"
          eku=(ext.value == "TLS Web Client Authentication")
        end
      }
      expect(vizsla.store_certificate).to be_truthy
      expect(eku).to      be false
      expect(keyUsage).to be false
    end

    it "should create a certificate with an interesting MASA url" do
      SystemVariable.setvalue(:masa_iauthority, "masa.example.com:1234")

      ndev = Device.new
      ndev.eui64 = '00-16-3e-ff-fe-d0-55-aa'
      tmp_device_dir {
        ndev.gen_and_store_key
        expect(system("openssl x509 -noout -text -in #{ndev.certificate_filename} | grep masa.example.com:1234 >/dev/null")).to be true
      }
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

    it "should ignore obsolete devices when looking for unowned" do
      expect(Device.active.unowned.count).to eq(3)
      expect(Device.active.owned.count).to   eq(3)
      expect(Device.obsolete.count).to eq(1)
    end
  end

  describe "signed voucher requests" do
    it "should load a constrained prior-signed (pledge) voucher request, and validate it" do
      # this file created with reach.
      token  = open("spec/files/vr_00-D0-E5-F2-10-03.vch")

      pvch = Chariwt::VoucherRequest.from_cose_withoutkey_io(token)

      # validate that the registry was nearby
      ownercert = pvch.attributes["proximity-registrar-cert"]
      expect(ownercert).to_not be_nil
      owner = Owner.find_by_public_key(ownercert)
      expect(owner).to                 be_present

      # validate that the voucher was signed by a device
      serialnumber = pvch.attributes["serial-number"]
      expect(serialnumber).to_not be_nil

      device = Device.find_by_number(serialnumber)
      expect(device).to                be_present

      expect(pvch.verify_with_key(device.certificate)).to be_truthy
    end
  end

  describe "SmartPledge/DPP encoding" do
    it "should default essid and fqdn from ULA" do
      zeb = devices(:zeb)

      zeb.extrapolate_from_ula

      zeb.reload
      expect(zeb.essid).to eq("SHG3CE618")
      expect(zeb.fqdn).to  eq("n3CE618.router.securehomegateway.ca")
    end

    it "should generate a tagged set of values" do
      zeb = devices(:zeb)

      dpphash = zeb.dpphash

      expect(zeb.fqdn).to eq("n3CE618.router.securehomegateway.ca")

      # URL to this MASA
      expect(dpphash["S"]).to eq("highway-test.example.com")
      expect(dpphash["M"]).to eq("00163E8D519B")    # MAC address
      expect(dpphash["K"]).to_not be_nil

      key = OpenSSL::PKey.read(Base64.decode64(dpphash["K"]))
      expect(key.class).to be OpenSSL::PKey::EC
      key = OpenSSL::PKey.read(Base64.decode64(dpphash["K"]))
      expect(key).to_not be_nil

      expect(dpphash["L"]).to eq("02163EFEFF8D519B")
      expect(dpphash["E"]).to eq("SHG3CE618")

    end
  end

end
