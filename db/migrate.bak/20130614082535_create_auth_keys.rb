class CreateAuthKeys < ActiveRecord::Migration
  def change
    create_table :auth_keys do |t|
      t.string :usergroup, :null => false, :limit => 20
	  t.string :keytype, :null => false, :limit => 3
      t.string :md5, :null => false, :limit => 32
      t.text :keydata, :null => false

      t.timestamps
    end

	add_index :auth_keys, :md5, unique: true
  end
end
