require 'rails_helper'

RSpec.describe "VoucherRequests", type: :request do
  describe "GET /voucher_requests" do
    it "works! (now write some real specs)" do
      get voucher_requests_path
      expect(response).to have_http_status(200)
    end
  end
end
