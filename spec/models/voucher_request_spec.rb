require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  before(:each) do
    HighwayKeys.ca.certdir = Rails.root.join('spec','files','cert')
    MasaKeys.masa.certdir = Rails.root.join('spec','files','cert')
  end

  describe "relations" do
    it { should belong_to(:voucher) }
    it { should belong_to(:owner) }
    it { should belong_to(:device) }
  end

  describe "voucher input request" do
    it "should read a voucher request from disk" do
      token = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr2 = CmsVoucherRequest.from_pkcs7(token)
      expect(vr2.device_identifier).to eq("00-D0-E5-F2-00-02")
      expect(vr2.nonce).to eq("Dss99sBr3pNMOACe-LYY7w")
      expect(vr2.owner).to_not be_nil

      voucher,reason = vr2.issue_voucher('2017-09-15'.to_date)
      expect(voucher).to_not be_nil
      expect(voucher.nonce).to eq(vr2.nonce)
      expect(voucher.device_identifier).to eq(vr2.device_identifier)
      expect(voucher.as_issued).to_not be_nil

      # save it for examination elsewhere (and use by Registrar tests)
      expect(Chariwt.cmp_pkcs_file(voucher.as_issued, "voucher_#{voucher.device_identifier}")).to be true
    end

    it "should not duplicate a byte4byte identical request" do
      token = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr2 = CmsVoucherRequest.from_pkcs7(token)
      expect(vr2.id).to_not be_nil

      tok2 = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr3 = CmsVoucherRequest.from_pkcs7(token)
      expect(vr3.id).to eq(vr2.id)
      expect(vr3.device).to eq(devices(:vizsla))
    end

    it "should process a voucher request into a voucher for a valid device" do
      req13 = voucher_requests(:voucher13)
      voucher,reason = req13.issue_voucher
      expect(reason).to eq(:ok)
      expect(voucher).to_not be_nil
      expect(voucher.nonce).to   eq(req13.nonce)
      expect(voucher.device).to  eq(req13.device)
      expect(voucher.owner).to   eq(req13.owner)
    end

    it "should validate a voucher request" do
      req14 = voucher_requests(:voucher14)
      expect(req14.prior_voucher_request).to_not be_nil
      expect(req14.prior_voucher_request.proximityRegistrarCert).to_not be_nil
      owner = req14.lookup_owner
      expect(owner).to eq(owners(:owner4))
      expect(owner.pubkey).to eq(req14.signing_key)
    end

    it "should load a constrained voucher request into database" do
      token  = open("spec/files/parboiled_vr_00-D0-E5-F2-10-03.vch")
      regfile= File.join("spec","files","jrc_prime256v1.crt")
      pubkey = OpenSSL::X509::Certificate.new(IO::read(regfile))

      vch = CoseVoucherRequest.from_cbor_cose_io(token, pubkey)
      expect(vch).to    be_proximity
      expect(vch.owner).to be_present
    end


  end

end
