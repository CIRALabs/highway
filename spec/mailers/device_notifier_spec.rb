require "rails_helper"

RSpec.describe DeviceNotifierMailer, type: :mailer do
  fixtures :all

  describe "emails to administrator" do
    it "should send an email when a voucher is issued" do
      v1 = vouchers(:almec_v1)
      today  = '2017-01-01'.to_date
      v1.pkcs_sign!(today)



    end
  end
end
