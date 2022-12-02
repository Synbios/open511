class CreateBookmarks < ActiveRecord::Migration[7.0]
  def change
    create_table :bookmarks do |t|
      t.integer :user_id
      t.string :event_id
      t.text :data

      t.timestamps
    end
    add_index :bookmarks, :user_id
    add_index :bookmarks, [:user_id, :event_id], unique: true
  end
end
