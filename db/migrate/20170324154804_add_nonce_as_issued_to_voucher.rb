class AddNonceAsIssuedToVoucher < ActiveRecord::Migration
  def change
    add_column :vouchers, :nonce, :text
    add_column :vouchers, :as_issued, :text
  end
end
