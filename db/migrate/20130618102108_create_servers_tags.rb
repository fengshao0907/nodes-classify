class CreateServersTags < ActiveRecord::Migration
  def change
    create_table :servers_tags, :id => false do |t|
      t.references :server
      t.references :tag

      t.timestamps
    end
    add_index :servers_tags, :server_id
    add_index :servers_tags, :tag_id
  end
end
