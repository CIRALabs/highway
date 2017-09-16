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
      token = Base64.decode64(IO::read("spec/files/vr_JADA123456789.pkcs"))
      vr2 = VoucherRequest.from_pkcs7(token)
      expect(vr2.device_identifier).to eq("JADA123456789")
      expect(vr2.nonce).to eq("abcd1234")
      expect(vr2.owner).to_not be_nil

      voucher = vr2.issue_voucher
      expect(voucher.nonce).to eq(vr2.nonce)
      expect(voucher.device_identifier).to eq(vr2.device_identifier)

      voucher.jose_sign!('2017-09-15'.to_date)
      expect(voucher.as_issued).to_not be_nil

      # save it for examination elsewhere (and use by Registrar tests)
      File.open(File.join("tmp", "voucher_#{voucher.device_identifier}.pkcs"), "w") do |f|
        f.puts voucher.as_issued
      end

      system("bin/pkcs2json tmp/voucher_#{voucher.device_identifier}.pkcs tmp/voucher_#{voucher.device_identifier}.txt")

      cmd = "diff tmp/voucher_#{voucher.device_identifier}.txt spec/files/voucher_#{voucher.device_identifier}.txt"
      puts cmd
      expect(system(cmd)).to be true
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
