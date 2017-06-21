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
        byebug

        part1js = JSON.parse(Base64.urlsafe_decode64(part1))
        part2js = JSON.parse(Base64.urlsafe_decode64(part2))
        part3bin = Base64.urlsafe_decode64(part3)
      end
    end
  end

end
