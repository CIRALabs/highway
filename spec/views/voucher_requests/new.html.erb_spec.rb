require 'rails_helper'

RSpec.describe "voucher_requests/new", type: :view do
  before(:each) do
    assign(:voucher_request, VoucherRequest.new())
  end

  it "renders new voucher_request form" do
    render

    assert_select "form[action=?][method=?]", voucher_requests_path, "post" do
    end
  end
end
