class CreateUsages < ActiveRecord::Migration[7.0]
  def change
    create_table :usages do |t|
      t.string :request_type
      t.string :ip
      t.string :status

      t.timestamps
    end
  end
end
