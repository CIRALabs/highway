class AddRfc1918ToDevices < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :rfc1918, :text
  end
end
