class RemoveVerifiedFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :verified, :integer
  end
end
