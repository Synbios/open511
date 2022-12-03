class CreateAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :areas do |t|
      t.string :name
      t.string :api_id

      t.timestamps
    end

    add_index :areas, :api_id, unique: true
  end
end
