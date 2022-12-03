class AddUserIdToUsages < ActiveRecord::Migration[7.0]
  def change
    add_column :usages, :user_id, :integer
    add_index :usages, :user_id
  end
end
