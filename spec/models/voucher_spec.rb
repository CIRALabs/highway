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

    it "should delegate device_identifier to device" do
      v1 = vouchers(:almec_v1)
      expect(v1.device_identifier).to eq("JADA_f2-00-01")
    end
  end

  describe "json creation" do
    it "should create signed json representation" do
      v1 = vouchers(:almec_v1)

      today  = '2017-01-01'.to_date

      v1.pkcs_sign!(today)

      expect(Chariwt.cmp_pkcs_file(v1.as_issued, "almec_voucher")).to be true
    end
  end

end
