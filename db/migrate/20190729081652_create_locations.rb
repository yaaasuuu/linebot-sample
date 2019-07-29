class CreateLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :locations do |t|
      t.string :name
      t.numeric :latitude
      t.numeric :longitude

      t.timestamps
    end
  end
end
