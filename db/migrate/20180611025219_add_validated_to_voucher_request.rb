class AddValidatedToVoucherRequest < ActiveRecord::Migration[5.0]
  def change
    add_column :voucher_requests, :validated, :boolean, default: false
  end
end
