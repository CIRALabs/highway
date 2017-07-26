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
      token = File.read("spec/files/jada_abcd.jwt")
      vr2 = VoucherRequest.from_json_jose(token)
      expect(vr2.device_identifier).to eq("JADA123456789")
      expect(vr2.nonce).to eq("abcd12345")
      expect(vr2.owner).to_not be_nil
    end

    it "should process a voucher request into a voucher for a valid device" do
      req13 = voucher_requests(:voucher13)
      voucher = req13.issue_voucher
      expect(voucher.nonce).to   eq(req13.nonce)
      expect(voucher.device).to  eq(req13.device)
      expect(voucher.owner).to   eq(req13.owner)
    end
  end

end
