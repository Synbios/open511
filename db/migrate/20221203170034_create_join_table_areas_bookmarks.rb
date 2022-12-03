class CreateJoinTableAreasBookmarks < ActiveRecord::Migration[7.0]
  def change
    create_join_table :areas, :bookmarks do |t|
      t.index [:area_id, :bookmark_id]
      t.index [:bookmark_id, :area_id]
    end
  end
end
