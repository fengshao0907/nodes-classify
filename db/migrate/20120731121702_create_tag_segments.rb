class CreateTagSegments < ActiveRecord::Migration
  def change
    create_table :tag_segments do |t|

      t.timestamps
    end
  end
end
