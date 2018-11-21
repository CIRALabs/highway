class AddOwnerCountToDevice < ActiveRecord::Migration[5.0]
  def change
    add_column :devices, :owners_count, :integer, default: 0
    reversible do |direction|
      direction.up {
        Device.reset_column_information
        Device.all.find_each do |p|
          Device.reset_counters p.id, :owners
        end
      }
    end
  end
end
