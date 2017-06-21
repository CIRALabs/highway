class AddSerialNumberToDevice < ActiveRecord::Migration[5.0]
  def change
    add_column :devices, :serial_number, :text
  end
end
