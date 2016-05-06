class CreateDevices < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.text 'eui64'
      t.text 'pub_key'
      t.integer 'owner_id'
      t.integer 'model_id'

      t.timestamps null: false
    end
  end
end
