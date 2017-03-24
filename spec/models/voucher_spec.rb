require 'rails_helper'

RSpec.describe Voucher, type: :model do
  fixtures :all

  describe "relations" do
    it "should refer to a device" do
      v1 = vouchers(:almec_v1)

      expect(v1.device).to eq(devices(:almec))
    end
  end

end
