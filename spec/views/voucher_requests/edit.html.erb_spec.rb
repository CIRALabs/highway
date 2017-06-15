require 'rails_helper'

RSpec.describe "voucher_requests/edit", type: :view do
  before(:each) do
    @voucher_request = assign(:voucher_request, VoucherRequest.create!(
      :details => "",
      :owner_id => 1,
      :voucher_id => 1,
      :originating_ip => "MyText"
    ))
  end

  it "renders the edit voucher_request form" do
    render

    assert_select "form[action=?][method=?]", voucher_request_path(@voucher_request), "post" do

      assert_select "input#voucher_request_details[name=?]", "voucher_request[details]"

      assert_select "input#voucher_request_owner_id[name=?]", "voucher_request[owner_id]"

      assert_select "input#voucher_request_voucher_id[name=?]", "voucher_request[voucher_id]"

      assert_select "textarea#voucher_request_originating_ip[name=?]", "voucher_request[originating_ip]"
    end
  end
end
