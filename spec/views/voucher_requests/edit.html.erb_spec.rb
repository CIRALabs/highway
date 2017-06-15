require 'rails_helper'

RSpec.describe "voucher_requests/edit", type: :view do
  before(:each) do
    @voucher_request = assign(:voucher_request, VoucherRequest.create!())
  end

  it "renders the edit voucher_request form" do
    render

    assert_select "form[action=?][method=?]", voucher_request_path(@voucher_request), "post" do
    end
  end
end
