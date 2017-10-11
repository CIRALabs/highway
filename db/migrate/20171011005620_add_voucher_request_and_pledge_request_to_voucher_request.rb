class AddVoucherRequestAndPledgeRequestToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :voucher_request, :binary
    add_column :voucher_requests, :pledge_request, :binary
  end
end
