class AddExtraCertificateFields < ActiveRecord::Migration
  def up
  	add_column :certificates, :common_name, :string, :nullable => false
  	add_column :certificates, :email, :string, :nullable => false
  	add_column :certificates, :serial, :integer, :nullable => false
  	add_column :certificates, :child_last_serial, :integer, :nullable => true
  	add_column :certificates, :expires, :timestamp, :nullable => false
  end

  def down
  	remove_column :certificates, :expires
  	remove_column :certificates, :child_last_serial
  	remove_column :certificates, :serial
  	remove_column :certificates, :email
  	remove_column :certificates, :common_name
  end
end
