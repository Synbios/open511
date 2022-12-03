class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :url
      t.string :jurisdiction_url
      t.string :headline
      t.string :status
      t.string :description
      t.string :ivr_message
      t.string :schedule
      t.string :event_type
      t.string :event_subtypes
      t.string :severity
      t.string :geography
      t.string :roads
      t.string :areas

      t.timestamps
    end
  end
end
