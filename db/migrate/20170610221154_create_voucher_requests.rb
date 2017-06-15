class CreateVoucherRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :voucher_requests do |t|
      t.json :details
      t.integer :owner_id
      t.integer :voucher_id
      t.integer :device_id
      t.text :originating_ip
      t.text :nonce
      t.text :device_identifier

      t.timestamps
    end
  end
end
