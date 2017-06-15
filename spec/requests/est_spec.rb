# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'BRSKI EST API', type: :request do

  describe "voucher request" do
    it "POST /requestvoucher" do
      # make an HTTPS request for a new voucher
      # this is section 3.3 of RFCXXXX/draft-ietf-anima-dtbootstrap-anima-keyinfra

      voucherreq =  { "ietf-voucher:voucher" =>
                      {
                        "nonce" => "62a2e7693d82fcda2624de58fb6722e5",
                        "created-on" => "2017-01-01T00:00:00.000Z",
                        "assertion"  => "proximity",
                        "device-identifier-aki" => "",
                        "device-identifier" => "JADA123456789"
                      }
                    }

      post '/requestvoucher', params: voucherreq.to_json, headers: {
             'CONTENT_TYPE' => 'application/voucherrequest+cms',
             'ACCEPT'       => 'application/json'
           }

      expect(response).to have_http_status(200)

      jsonreply = JSON.parse(response.body)
      expect(jsonreply['ietf-voucher:voucher']).to_not be_nil
    end

  end

end
