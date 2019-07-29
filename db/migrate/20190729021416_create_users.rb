class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.int :user_id
      t.int :location_id

      t.timestamps
    end
  end
end
