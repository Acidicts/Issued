class RemoveTrustFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :trust, :integer
  end
end
