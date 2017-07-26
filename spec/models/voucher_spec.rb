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
      expect(json1["assertion"]).to                 eq("logged")

      owner_base64 = json1["owner"]
      owner_der    = Base64.urlsafe_decode64(owner_base64)
      owner = OpenSSL::X509::Certificate.new(owner_der)
      expect(owner.subject.to_s).to eq("/C=CA/ST=Ontario/L=Ottawa/O=Owner Example One/OU=Not Very/CN=owner1.example.com/emailAddress=owner1@example.com")
    end

    it "should create signed json representation" do
      v1 = vouchers(:almec_v1)

      today  = '2017-01-01'.to_date

      pkcs7 = v1.pkcs7_signed_voucher(today)
      expect(pkcs7.class).to be(OpenSSL::PKCS7)
      expect(pkcs7.to_pem).to_not be_nil

      tmpdir=Rails.root.join('tmp')
      FileUtils::mkdir_p(tmpdir)
      File.open(File.join(tmpdir, 'almec_voucher.smime'), 'wb') do |f| f.write OpenSSL::PKCS7.write_smime(pkcs7); end
    end
  end

end
