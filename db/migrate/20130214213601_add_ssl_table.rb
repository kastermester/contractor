class AddSslTable < ActiveRecord::Migration
  def up
  	create_table :certificates do |t|
  		t.string :name, :null => false
  		t.text :pem_certificate, :null => false
  		t.text :pem_private_key, :null => false
  		t.integer :issuer_certificate_id, :null => true
  		t.foreign_key :certificates, :column => :issuer_certificate_id
  		t.timestamps
  	end 
  end

  def down
  	drop_table :certificates
  end
end
