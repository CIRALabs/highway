class AddObsoletedToDevices < ActiveRecord::Migration[5.0]
  def change
    add_column :devices, :obsolete, :bool, default: false
  end
end
