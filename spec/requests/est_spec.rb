# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'BRSKI EST API', type: :request do

  describe "voucher request" do
    it "POST /.well-known/est/requestvoucher" do
      # make an HTTPS request for a new voucher
      # this is section 3.3 of RFCXXXX/draft-ietf-anima-dtbootstrap-anima-keyinfra
      token = File.read("spec/files/vr_JADA123456789.pkcs")
      post "/.well-known/est/requestvoucher", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }

      expect(response).to have_http_status(200)
      expect(assigns(:voucherreq).device_identifier).to eq('JADA123456789')
      expect(assigns(:voucher).owner).to_not be_nil
    end

  end

end
