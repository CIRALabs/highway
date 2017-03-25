require 'rails_helper'

RSpec.describe Voucher, type: :model do
  fixtures :all

  def generate_random_nonce
    "hello1"
  end

  describe "relations" do
    it { should belong_to(:device) }
    it { should belong_to(:owner)  }

    it "should refer to a device" do
      v1 = vouchers(:almec_v1)

      expect(v1.device).to eq(devices(:almec))
    end
  end

  describe "json creation" do
    it "should create json representation in ietf-anima-voucher format" do
      v1 = vouchers(:almec_v1)

      today  = '2017-01-01'.to_date

      json = v1.jsonhash(today)
      expect(json["ietf-voucher:voucher"].class).to be Hash
      json1 = json["ietf-voucher:voucher"]
      expect(json1["nonce"]).to                     eq(v1.nonce)
      expect(json1["created-on"].to_datetime).to    eq(today)
      expect(json1["device-identifier"]).to         eq(v1.device.eui64)
      expect(json1["assertion"]).to                  eq("logged")
      expect(json1["owner"]).to_not be_nil
    end
  end

end
