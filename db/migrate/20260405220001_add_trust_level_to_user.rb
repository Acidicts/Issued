class AddTrustLevelToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :trust, :integer, default: 0, null: false
  end
end
