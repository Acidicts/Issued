class AddThreadsToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :threads, :integer
  end
end
