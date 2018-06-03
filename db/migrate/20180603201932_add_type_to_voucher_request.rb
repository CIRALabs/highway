class AddTypeToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :type, :text
  end
end
