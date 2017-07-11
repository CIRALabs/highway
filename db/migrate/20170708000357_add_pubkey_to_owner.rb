class AddPubkeyToOwner < ActiveRecord::Migration[5.0]
  def change
    add_column :owners, :pubkey, :text
  end
end
