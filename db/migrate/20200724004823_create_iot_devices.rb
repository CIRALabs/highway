class CreateIotDevices < ActiveRecord::Migration[5.2]
  def change
    create_table :iot_devices do |t|
      t.integer  :security_gateway_id
      t.text     :mac_address

      t.timestamps
    end
  end
end
