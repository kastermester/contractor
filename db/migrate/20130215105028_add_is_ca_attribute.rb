class AddIsCaAttribute < ActiveRecord::Migration
  def up
  	add_column :certificates, :is_ca, :boolean, :default => false
  end

  def down
  	drop_column :certificates, :is_ca
  end
end
