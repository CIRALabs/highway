class AddNameAndEssidToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :fqdn,  :text
    add_column :devices, :essid, :text
    add_column :devices, :ula,   :text
  end
end
