class AddNamedetailLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :detail, :string
  end
end
