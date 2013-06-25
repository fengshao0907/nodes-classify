class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name, :limit => 20, :null => false
      t.text :description

	  t.timestamps
    end

	add_index :projects, :name, unique: true
  end
end
