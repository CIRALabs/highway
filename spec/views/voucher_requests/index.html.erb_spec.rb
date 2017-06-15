require 'rails_helper'

RSpec.describe "voucher_requests/index", type: :view do
  before(:each) do
    assign(:voucher_requests, [
      VoucherRequest.create!(
        :details => "",
        :owner_id => 2,
        :voucher_id => 3,
        :originating_ip => "MyText"
      ),
      VoucherRequest.create!(
        :details => "",
        :owner_id => 2,
        :voucher_id => 3,
        :originating_ip => "MyText"
      )
    ])
  end

  it "renders a list of voucher_requests" do
    render
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
