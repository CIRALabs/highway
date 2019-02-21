class AddNonceAsIssuedToVoucher < ActiveRecord::Migration[4.2]
  def change
    add_column :vouchers, :nonce, :text
    add_column :vouchers, :as_issued, :text
  end
end
