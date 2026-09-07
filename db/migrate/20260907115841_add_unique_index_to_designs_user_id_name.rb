class AddUniqueIndexToDesignsUserIdName < ActiveRecord::Migration[8.1]
  def change
    add_index :designs, [ :user_id, :name ], unique: true
  end
end
