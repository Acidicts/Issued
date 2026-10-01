require_relative "../migrate_helpers"

class RemoveVerifiedFromUsers < ActiveRecord::Migration[8.1]
  include MigrationHelpers

  def up
    remove_column :users, :verified, :integer, if_exists: true
  end

  def down
    add_column :users, :verified, :integer, if_not_exists: true
  end
end