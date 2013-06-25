class CreateTagSegments < ActiveRecord::Migration
  def change
    create_table :tag_segments do |t|
      t.string :name, :limit => 16, :null => false
      t.text :description

      t.timestamps
    end

	add_index :tag_segments, :name, unique: true
  end
end
