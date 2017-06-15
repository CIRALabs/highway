require 'rails_helper'

RSpec.describe "voucher_requests/show", type: :view do
  before(:each) do
    @voucher_request = assign(:voucher_request, VoucherRequest.create!(
      :details => "",
      :owner_id => 2,
      :voucher_id => 3,
      :originating_ip => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/MyText/)
  end
end
