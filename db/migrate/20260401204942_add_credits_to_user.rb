class AddCreditsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :credits, :integer
  end
end
