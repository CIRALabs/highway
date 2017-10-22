require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  describe "relations" do
    it { should belong_to(:voucher) }
    it { should belong_to(:owner) }
    it { should belong_to(:device) }

  end



  describe "voucher input request" do
    it "should read a voucher request from disk" do
      token = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr2 = VoucherRequest.from_pkcs7(token)
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

      expect(voucher.owner.pubkey).to eq(vr2.signing_key)
    end

    it "should not duplicate a byte4byte identical request" do
      token = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr2 = VoucherRequest.from_pkcs7(token)
      expect(vr2.id).to_not be_nil

      tok2 = Base64.decode64(IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs"))
      vr3 = VoucherRequest.from_pkcs7(token)
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

  end

end
