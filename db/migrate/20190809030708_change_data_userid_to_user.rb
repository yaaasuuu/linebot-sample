class ChangeDataUseridToUser < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :user_id, :string
  end
end
