require 'rails_helper'

RSpec.describe "voucher_requests/index", type: :view do
  before(:each) do
    assign(:voucher_requests, [
      VoucherRequest.create!(),
      VoucherRequest.create!()
    ])
  end

  it "renders a list of voucher_requests" do
    render
  end
end
