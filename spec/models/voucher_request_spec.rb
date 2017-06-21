require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do

  describe "relations" do
    it { should belong_to(:voucher) }
    it { should belong_to(:owner) }
    it { should belong_to(:device) }
  end

  describe "voucher signed" do
    it "should validate a signed voucher request" do
      v1 = voucher_requests(:sample_request1)

    end
  end

  describe "voucher input request" do
    it "should read a voucher request from disk" do
      token = nil
      File.open("spec/files/jada_abcd.jwt","r") do |f|
        token = f.read

        decoded_token = JWT.decode token, nil, false

        json = decoded_token[0]
        vr2 = VoucherRequest.create(details: json)
        vr2.populate_explicit_fields
        expect(vr2.device_identifier).to eq("JADA123456789")
        expect(vr2.nonce).to eq("abcd12345")
      end
    end
  end

end
