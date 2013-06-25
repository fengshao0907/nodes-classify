class CreateServers < ActiveRecord::Migration
  def change
    create_table :servers do |t|
      t.string :name, :null => false
      t.string :status, :null => false
	  t.references :project, :null => false

      t.timestamps
    end

	add_index :servers, :name, unique: true
  end
end
