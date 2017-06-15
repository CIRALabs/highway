require 'rails_helper'

RSpec.describe "voucher_requests/show", type: :view do
  before(:each) do
    @voucher_request = assign(:voucher_request, VoucherRequest.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
