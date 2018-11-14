class AddCertificateToDevice < ActiveRecord::Migration[5.0]
  def change
    add_column :devices, :idevid_cert, :text
  end
end
