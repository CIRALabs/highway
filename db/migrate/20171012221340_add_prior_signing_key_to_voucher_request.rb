class AddPriorSigningKeyToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :prior_signing_key, :text
  end
end
