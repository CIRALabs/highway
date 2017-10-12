class AddSigningKeyToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :signing_key, :text
  end
end
