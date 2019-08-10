class AddPrefIdToLocation < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :prefid, :integer
  end
end
