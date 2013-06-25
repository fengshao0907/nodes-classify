class CreateAuthKeys < ActiveRecord::Migration
  def change
    create_table :auth_keys do |t|

      t.timestamps
    end
  end
end
