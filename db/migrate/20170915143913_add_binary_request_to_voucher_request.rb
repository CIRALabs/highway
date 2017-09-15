class AddBinaryRequestToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :raw_request, :binary
  end
end
