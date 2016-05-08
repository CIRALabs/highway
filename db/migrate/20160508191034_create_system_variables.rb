class CreateSystemVariables < ActiveRecord::Migration
  def self.up
    create_table :system_variables do |t|
      t.column :variable, :string
      t.column :value,    :string
    end
  end

  def self.down
    drop_table :system_variables
  end
end
