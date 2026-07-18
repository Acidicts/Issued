class AddGuideToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :guide, :boolean
  end
end
