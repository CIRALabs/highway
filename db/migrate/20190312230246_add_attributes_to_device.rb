class AddAttributesToDevice < ActiveRecord::Migration[5.2]
  def change
    add_column :devices, :extra_attrs, :json
    add_column :devices, :second_eui64, :text
  end
end
