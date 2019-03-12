class AddAttributesToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :attributes, :json
    add_column :devices, :second_eui64, :text
  end
end
