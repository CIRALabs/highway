require "rails_helper"

RSpec.describe DeviceNotifierMailer, type: :mailer do
  fixtures :all

  before(:each) do
    FileUtils::mkdir_p("tmp")
    MasaKeys.masa.certdir = Rails.root.join('spec','files','cert')
  end

  describe "emails to administrator" do
    it "should send an email when a voucher is issued" do
      v1 = vouchers(:almec_v1)
      today  = '2017-01-01'.to_date
      v1.pkcs_sign!(today)

      expect { v1.pkcs_sign!(today) }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "should send a test email against a voucher" do
      v1 = vouchers(:almec_v1)

      expect { v1.notify_voucher! }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end

  end
end
