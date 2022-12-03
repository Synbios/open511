class AddIndexToUsages < ActiveRecord::Migration[7.0]
  def change
    add_index :usages, :request_type
    add_index :usages, :status
  end
end
