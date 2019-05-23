class AddOtherCertsToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :othercerts, :text
  end
end
