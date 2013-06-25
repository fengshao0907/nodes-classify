class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, :null => false, :limit => 20
      t.text :description
	  t.references :project, :null => false
	  t.references :tag_segment, :null => false

      t.timestamps
    end
  end
end
