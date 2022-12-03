class AddSeverityLevelToBookmarks < ActiveRecord::Migration[7.0]
  def change
    add_column :bookmarks, :severity_level, :integer
  end
end
