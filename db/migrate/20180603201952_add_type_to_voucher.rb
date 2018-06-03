class AddTypeToVoucher < ActiveRecord::Migration[5.0]
  def change
    add_column :vouchers, :type, :text
  end
end
