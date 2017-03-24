class CreateVouchers < ActiveRecord::Migration
  def change
    create_table :vouchers do |t|
      t.text :issuer
      t.integer :device_id
      t.datetime :expires_on
      t.integer :owner_id
      t.text :requesting_ip

      t.timestamps null: false
    end
  end
end
